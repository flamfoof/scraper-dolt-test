import mariadb from "mariadb";
import PQueue from "p-queue";
import { z } from "zod";

const dbConfigSchema = z.object({
	host: z.string(),
	port: z.number().default(3306),
	user: z.string(),
	password: z.string(),
	database: z.string().optional(),
	connectionLimit: z.number().default(10),
});

export class DatabaseManager {
	constructor(config) {
		this.config = dbConfigSchema.parse(config);
		this.pool = mariadb.createPool({
			...this.config,
			connectTimeout: 30000,
			acquireTimeout: 30000,
			idleTimeout: 60000,
		});

		this.queue = new PQueue({
			concurrency: this.config.connectionLimit,
			autoStart: true,
		});
	}

	async connect() {
		try {
			const conn = await this.pool.getConnection();
			conn.release();
			return true;
		} catch (error) {
			throw new Error(`Failed to connect to database: ${error.message}`);
		}
	}

	async disconnect() {
		await this.pool.end();
	}

	async executeQuery(query, params = []) {
		return this.queue.add(async () => {
			let conn;
			try {
				conn = await this.pool.getConnection();
				const rows = await conn.query(query, params);
				return rows;
			} finally {
				if (conn) conn.release();
			}
		});
	}

	async executeBatch(commands, params = []) {
		return this.queue.add(async () => {
			let conn;
			try {
				conn = await this.pool.getConnection();
				await conn.beginTransaction();

				for (const command of commands.split(";")) {
					if (command.trim()) {
						await conn.query(command.trim(), params);
					}
				}

				await conn.commit();
			} catch (error) {
				if (conn) await conn.rollback();
				throw error;
			} finally {
				if (conn) conn.release();
			}
		});
	}

	async getTableRowCount(database, table) {
		const query = `SELECT COUNT(*) as count FROM \`${database}\`.\`${table}\``;
		const result = await this.executeQuery(query);
		return result[0].count;
	}

	async getDatabases() {
		const rows = await this.executeQuery("SHOW DATABASES");
		return rows.map((row) => row.Database);
	}

	async getTables(database) {
		const rows = await this.executeQuery(
			`SELECT TABLE_NAME FROM information_schema.TABLES WHERE TABLE_SCHEMA = '${database}'`
		);

		return rows.map((row) => row.TABLE_NAME);
	}

	getTableDependencyOrder() {
		// Define tables in order of dependencies
		return [
			// Independent tables first
			"Movies",
			"Series",
			"ContentTypes",
			"Scrapers",

			// First level dependencies
			"Seasons",
			"MoviesDeeplinks",
			"ScrapersActivity",

			// Second level dependencies
			"Episodes",

			// Third level dependencies
			"EpisodesDeeplinks",

			// Fourth level dependencies
			"Prices",

			// Audit table last (if needed)
			"AuditLog",
		];
	}

	async getDatabaseSize(database) {
		const tables = await this.getTables(database);
		const sizeQuery = `
      SELECT 
        SUM(data_length + index_length) as size
      FROM information_schema.TABLES
      WHERE table_schema = ?
    `;
		const [{ size }] = await this.executeQuery(sizeQuery, [database]);
		return { size: size || 0, tables: tables.length };
	}

	async createDatabase(database) {
		await this.executeQuery(`CREATE DATABASE IF NOT EXISTS \`${database}\``);
	}

	async dropDatabase(database) {
		await this.executeQuery(`DROP DATABASE IF EXISTS \`${database}\``);
	}

	async getTableSchema(database, table) {
		const rows = await this.executeQuery(`SHOW CREATE TABLE \`${database}\`.\`${table}\``);
		return rows[0]["Create Table"];
	}

	async compareSchemas(sourceDb, destDb) {
		const differences = [];
		const tables = await this.getTables(sourceDb);

		for (const table of tables) {
			const sourceSchema = await this.getTableSchema(sourceDb, table);
			try {
				const destSchema = await this.getTableSchema(destDb, table);
				if (sourceSchema !== destSchema) {
					differences.push({
						table,
						message: "Schema mismatch between source and destination",
					});
				}
			} catch (error) {
				differences.push({
					table,
					message: "Table does not exist in destination database",
				});
			}
		}

		return differences;
	}

	async truncateInOrder(destDb, tableOrder) {
		try {
			console.log(`Truncating tables in order: ${tableOrder.join(", ")}`);
			const truncateCommands = [
				"SET FOREIGN_KEY_CHECKS = 0;",
				...tableOrder.map((table) => `TRUNCATE TABLE \`${destDb}\`.\`${table}\`;`),
				"SET FOREIGN_KEY_CHECKS = 1;",
			].join("\n");

			await this.executeBatch(truncateCommands);
		} catch (error) {
			// In case of error, ensure foreign key checks are re-enabled
			await this.executeQuery("SET FOREIGN_KEY_CHECKS = 1");
			throw error;
		}
	}

	async cloneTable(sourceDb, destDb, table, batchSize = 10000) {
		// Get total rows for progress tracking
		const [{ count }] = await this.executeQuery(`SELECT COUNT(*) as count FROM \`${sourceDb}\`.\`${table}\``);
		const totalRows = BigInt(count);
		let offset = 0n;
		let totalCloned = 0n;

		while (offset < totalRows) {
			console.log(`Cloning \`${sourceDb}\`.\`${table}\` into \`${sourceDb}\`.\`${table}\` (${totalCloned}/${totalRows} rows)`);
			const rows = await this.executeQuery(`SELECT * FROM \`${sourceDb}\`.\`${table}\` LIMIT ? OFFSET ?`, [
				batchSize,
				offset,
			]);

			if (rows.length === 0) break;

			// Prepare batch insert
			if (rows.length > 0) {
				const columns = Object.keys(rows[0]);

				// Create value strings with actual values properly escaped
				const valueStrings = rows.map((row) => {
					const rowValues = columns.map((col) => {
						const value = row[col];
						if (value === null) return "NULL";
						if (typeof value === "number") return value;
						if (typeof value === "boolean") return value ? 1 : 0;
						// Escape strings and handle dates
						if (value && typeof value === 'object' && !Array.isArray(value) && !(value instanceof Date)) {
							return `'${JSON.stringify(value).replace(/'/g, "''")}'`;
						}
						if (value instanceof Date) return `'${value.toISOString().slice(0, 19).replace("T", " ")}'`;
						return `'${String(value).replace(/'/g, "''")}'`;
					});
					return `(${rowValues.join(",")})`;
				});
        
				const rowsToAdd = BigInt(rows.length);
				const percentage = Number((totalCloned + rowsToAdd) * 100n / totalRows);
				console.log(`Inserting/Updating ${rows.length} rows into \`${sourceDb}\`.\`${table}\` (${percentage.toFixed(2)}% complete)`);

				// Create the ON DUPLICATE KEY UPDATE part
				const updatePart = columns
					.filter((col) => col !== "id") // Exclude primary key from updates
					.map((col) => `\`${col}\`=VALUES(\`${col}\`)`)
					.join(",");

				const insertCommand = `INSERT INTO \`${sourceDb}\`.\`${table}\` 
          (${columns.map((col) => `\`${col}\``).join(",")}) 
          VALUES ${valueStrings.join(",")}
          ON DUPLICATE KEY UPDATE ${updatePart};`.replace(/\n/g, " ");
				
				await destDb.executeQuery(insertCommand);
				totalCloned += rowsToAdd;
			}

			offset += BigInt(batchSize);
		}
		
		console.log(`Completed cloning \`${sourceDb}\`.\`${table}\`: ${totalCloned}/${totalRows} rows`);
	}
}
