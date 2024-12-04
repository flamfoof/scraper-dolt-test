import { Command } from "commander";
import ora from "ora";
import chalk from "chalk";
import { config } from "dotenv";
import { DatabaseManager } from "../lib/db-manager.js";
import inquirer from "inquirer";

config({ path: "./proj.env" });

const program = new Command();

program
	.name("clone")
	.description("Clone databases from source to destination")
	.option("-d, --database <name>", "Specific database to clone")
	.option("-b, --batch-size <size>", "Batch size for data transfer", "10000")
	.option("--dry-run", "Show what would be cloned without actually cloning")
	.option("--direction <direction>", "Clone direction: local or master", "local")
	.option("--force", "Force push from local to master without confirmation")
	.action(async (options) => {
		const spinner = ora("Initializing database connections");

		try {
			if (options.direction !== "local" && options.direction !== "master") {
				throw new Error("Invalid direction. Use 'local' or 'master'");
			}

			if (options.direction === "master" && !options.force) {
				const { confirm } = await inquirer.prompt([{
					type: 'confirm',
					name: 'confirm',
					message: 'Are you sure you want to clone from local to master? This will overwrite master data. (Dangerous) (y/n)',
					default: false
				}]);

				if (!confirm) {
					console.log(chalk.yellow("Operation cancelled by user."));
					process.exit(0);
				}
			}

			spinner.start();

			// Source and destination configurations based on direction
			const masterConfig = {
				host: process.env.MASTER_DB_HOST,
				port: parseInt(process.env.MASTER_DB_PORT || "3306"),
				user: process.env.MASTER_DB_USER,
				password: process.env.MASTER_DB_PASS,
				connectionLimit: 5,
			};

			const localConfig = {
				host: process.env.LOCAL_DB_HOST || "localhost",
				port: parseInt(process.env.LOCAL_DB_PORT || "3306"),
				user: process.env.LOCAL_DB_USER,
				password: process.env.LOCAL_DB_PASS,
				connectionLimit: 5,
			};

			const sourceConfig = options.direction === "local" ? masterConfig : localConfig;
			const destConfig = options.direction === "local" ? localConfig : masterConfig;

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
			console.log(chalk.cyan("\nDirection:"));
			console.log(`  ${options.direction === "local" ? "Master → Local" : "Local → Master"}${options.direction === "master" && options.force ? " (forced)" : ""}`);
			
			console.log(chalk.cyan("\nSource:"));
			console.log(`  Host: ${sourceConfig.host}`);
			console.log(`  Port: ${sourceConfig.port}`);
			
			console.log(chalk.cyan("\nDestination:"));
			console.log(`  Host: ${destConfig.host}`);
			console.log(`  Port: ${destConfig.port}`);
			
			console.log(chalk.cyan("\nDatabases to Clone:"));
			let totalSize = 0;
			let totalTables = 0;
			
			for (const db of databasesToClone) {
				const { size, tables } = await sourceDb.getDatabaseSize(db);
				totalSize += size;
				totalTables += tables;
				console.log(chalk.cyan(`\n${db}:`));
				console.log(`  Size: ${(size / 1024 / 1024).toFixed(2)} MB`);
				console.log(`  Tables: ${tables}`);
				
				if (options.dryRun) {
					// Show table details in dry run
					const tableList = await sourceDb.getTables(db);
					console.log(chalk.cyan("  Tables to clone:"));
					for (const table of tableList) {
						const rowCount = await sourceDb.getTableRowCount(db, table);
						console.log(`    - ${table} (${rowCount.toLocaleString()} rows)`);
					}
				}
			}
			
			console.log(chalk.cyan("\nSummary:"));
			console.log(`  Total Size: ${(totalSize / 1024 / 1024).toFixed(2)} MB`);
			console.log(`  Total Tables: ${totalTables}`);
			console.log(`  Batch Size: ${options.batchSize} rows`);

			if (options.dryRun) {
				console.log(chalk.yellow("\n🔍 Dry run completed. No changes were made."));
				console.log(chalk.yellow("Run the command without --dry-run to perform the actual clone operation."));
				process.exit(0);
			}

			// Clone each database
			for (const database of databasesToClone) {
				spinner.start(`Cloning database: ${database}`);

				try {
					// Get and clone tables
					const tables = await sourceDb.getTables(database);
					
					// Get tables in dependency order and reverse for truncation
					const tableOrder = destDb.getTableDependencyOrder();
					
					// Truncate destination tables before cloning
					spinner.text = `Truncating tables in ${database}`;
					await destDb.truncateInOrder(database, tableOrder);
					
					let completedTables = 0;

					for (const table of tableOrder) {
						spinner.text = `Cloning ${database}: ${table} (${completedTables}/${tables.length})`;
						if(table === 'AuditLog') {
							await destDb.truncateInOrder(database, ['AuditLog']);
						}
						await sourceDb.cloneTable(database, destDb, table, parseInt(options.batchSize));
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
				} catch (error) {
					throw error;
				}
			}

			spinner.succeed("Clone operation completed successfully");

			
			// Clean up connections
			if (sourceDb) await sourceDb.disconnect();
			if (destDb) await destDb.disconnect();
		} catch (error) {
			spinner.fail(`Error: ${error.message}`);
			process.exit(1);
		}
	});

program.parse();
