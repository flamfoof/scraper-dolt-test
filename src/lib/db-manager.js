import mariadb from "mariadb";
import PQueue from "p-queue";
import { configDotenv } from "dotenv";
import { z } from "zod";

configDotenv();

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

		this.connection = null;
	}

	async connect() {
		try {
			const conn = await this.pool.getConnection();
			this.connection = await mariadb.createConnection({
				...this.config
			})
			
			await this.setUserConfigs();
			
			conn.release();
			return true;
		} catch (error) {
			throw new Error(`Failed to connect to database: ${error.message}`);
		}
	}

	async disconnect() {
		await this.connection.end();
		await this.pool.end();
	}

	async setUserConfigs() {
		await this.connection.query(`SET @username = '${process.env.MASTER_DB_USER}'`);
		await this.connection.query(`SET @appContext = 'user'`);
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

	async executeQueryContinuously(query, params = []) {
		return this.queue.add(async () => {
			let conn;
			try {
				conn = this.connection;
				const rows = await conn.query(query, params);
				return rows;
			} finally {
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
		const [result] = await this.executeQuery(`SELECT COUNT(*) as count FROM \`${database}\`.\`${table}\``);
		return result.count;
	}

	async getDatabases() {
		const rows = await this.executeQuery("SHOW DATABASES");
		return rows.map((row) => row.Database);
	}

	async getTables(database) {
		const rows = await this.executeQuery(
			`SELECT TABLE_NAME FROM information_schema.TABLES WHERE TABLE_SCHEMA = '${database}' AND TABLE_NAME != 'Users'`,
		);

		return rows.map((row) => row.TABLE_NAME);
	}

	getTmdbTableDependencyOrder() {
		// Define tables in order of dependencies
		return [
			// Independent tables first
			"Movies",
			"Series",
			"ContentTypes",

			// First level dependencies
			"Seasons",
			"MoviesDeeplinks",

			// Second level dependencies
			"Episodes",

			// Third level dependencies
			"SeriesDeeplinks",

			// Fourth level dependencies
			"MoviesPrices",
			"SeriesPrices",

			// Others
			"Graveyard",

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
}
