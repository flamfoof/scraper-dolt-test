import { Command } from "commander";
import ora from "ora";
import chalk from "chalk";
import { config } from "dotenv";
import { DatabaseManager } from "../lib/db-manager.js";

config({ path: "./proj.env" });

const program = new Command();

program
	.name("clone")
	.description("Clone databases from source to destination")
	.option("-d, --database <name>", "Specific database to clone")
	.option("-b, --batch-size <size>", "Batch size for data transfer", "10000")
	.option("--dry-run", "Show what would be cloned without actually cloning")
	.action(async (options) => {
		const spinner = ora("Initializing database connections").start();

		try {
			// Source database configuration
			const sourceConfig = {
				host: process.env.MASTER_DB_HOST,
				port: parseInt(process.env.MASTER_DB_PORT || "3306"),
				user: process.env.MASTER_DB_USER,
				password: process.env.MASTER_DB_PASS,
				connectionLimit: 5,
			};

			// Destination database configuration
			const destConfig = {
				host: process.env.LOCAL_DB_HOST || "localhost",
				port: parseInt(process.env.LOCAL_DB_PORT || "3306"),
				user: process.env.LOCAL_DB_USER,
				password: process.env.LOCAL_DB_PASS,
				connectionLimit: 5,
			};

			const sourceDb = new DatabaseManager(sourceConfig);
			const destDb = new DatabaseManager(destConfig);

			// Test connections
			await sourceDb.connect();
			await destDb.connect();
			spinner.succeed("Database connections established");

			// Get databases to clone
			const databasesToClone = options.database
				? [options.database]
				: process.env.CLONE_DATABASES?.split(",").map((db) => db.trim()) || [];

			if (databasesToClone.length === 0) {
				throw new Error("No databases specified for cloning");
			}

			// Display cloning plan
			console.log("\nCloning Plan:");
			for (const db of databasesToClone) {
				const { size, tables } = await sourceDb.getDatabaseSize(db);
				console.log(chalk.cyan(`\n${db}:`));
				console.log(`  Size: ${(size / 1024 / 1024).toFixed(2)} MB`);
				console.log(`  Tables: ${tables}`);
			}

			if (options.dryRun) {
				console.log(chalk.yellow("\nDry run completed. No changes made."));
				process.exit(0);
			}

			// Clone each database
			for (const database of databasesToClone) {
				spinner.start(`Cloning database: ${database}`);

				// Create database if it doesn't exist
				await destDb.createDatabase(database);

				// Get and clone tables
				const tables = await sourceDb.getTables(database);
				let completedTables = 0;

				for (const table of tables) {
					spinner.text = `Cloning ${database}: ${table} (${completedTables}/${tables.length})`;
					await sourceDb.cloneTable(database, database, table, parseInt(options.batchSize));
					completedTables++;
				}

				spinner.succeed(`Cloned database: ${database}`);

				// Verify clone
				const differences = await sourceDb.compareSchemas(database, database);
				if (differences.length > 0) {
					console.log(chalk.yellow("\nWarning: Schema differences detected:"));
					differences.forEach((diff) => {
						console.log(`- ${diff.table}: ${diff.message}`);
					});
				}
			}

			spinner.succeed("Clone operation completed successfully");
		} catch (error) {
			spinner.fail(`Error: ${error.message}`);
			process.exit(1);
		} finally {
			// Clean up connections
			if (sourceDb) await sourceDb.disconnect();
			if (destDb) await destDb.disconnect();
		}
	});

program.parse();
