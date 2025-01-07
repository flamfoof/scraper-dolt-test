import { Command } from "commander";
import ora from "ora";
import chalk from "chalk";
import { config } from "dotenv";
import { DatabaseManager } from "../lib/db-manager.js";
import { promisify } from "util";
import { exec as execCallback } from "child_process";
import { unlink } from "fs/promises";
import path from "path";

const exec = promisify(execCallback);
config({ path: "./proj.env" });

const program = new Command();
const MBSize = 1024 * 1024;

program
	.name("clone")
	.description("Clone databases from source to destination")
	.option("-d, --database <n>", "Specific database to clone")
	.option("--dry-run", "Show what would be cloned without actually cloning")
	.option("--direction <direction>", "Clone direction: local or master", "local")
	.option("--force", "Force push from local to master without confirmation")
	.action(async (options) => {
		const spinner = ora("Initializing database connections");

		try {
			if (options.direction !== "local" && options.direction !== "master") {
				throw new Error("Invalid direction. Use 'local' or 'master'");
			}

			spinner.start();

			// Source and destination configurations based on direction
			const masterConfig = {
				host: process.env.MASTER_DB_HOST,
				port: parseInt(process.env.MASTER_DB_PORT || "3306"),
				user: process.env.MASTER_DB_USER,
				password: process.env.MASTER_DB_PASS,
			};

			const localConfig = {
				host: process.env.LOCAL_DB_HOST || "localhost",
				port: parseInt(process.env.LOCAL_DB_PORT || "3306"),
				user: process.env.LOCAL_DB_USER,
				password: process.env.LOCAL_DB_PASS,
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
				totalSize += size / MBSize;
				totalTables += tables;
				console.log(chalk.cyan(`\n${db}:`));
				console.log(`  Size: ${(size / MBSize).toFixed(2)} MB`);
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
			console.log(`  Total Size: ${totalSize.toFixed(2)} MB`);
			console.log(`  Total Tables: ${totalTables}`);

			if (options.dryRun) {
				console.log(chalk.yellow("\n🔍 Dry run completed. No changes were made."));
				console.log(chalk.yellow("Run the command without --dry-run to perform the actual clone operation."));
				process.exit(0);
			}

			// Determine which executable to use (mysql/mariadb)
			const mysqlDumpExec = process.env.DB_EXEC === 'mariadb' ? 'mariadb-dump' : 'mysqldump';
			const mysqlExec = process.env.DB_EXEC === 'mariadb' ? 'mariadb' : 'mysql';

			// Clone each database using mysqldump
			for (const database of databasesToClone) {
				try {
					spinner.start(`Cloning database: ${database}`);
					const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
					const dumpFile = path.join(process.cwd(), `${database}_${timestamp}.sql`);

					// Create dump command
					const dumpCmd = `${mysqlDumpExec} -h ${sourceConfig.host} -u ${sourceConfig.user} ` +
						`-P ${sourceConfig.port} -p${sourceConfig.password} ` +
						`--single-transaction ${database} > "${dumpFile}"`;

					// Execute dump
					spinner.text = `Creating dump for ${database}`;
					await exec(dumpCmd);

					// Drop and recreate destination database
					spinner.text = `Preparing destination database ${database}`;
					const dropCmd = `${mysqlExec} -h ${destConfig.host} -u ${destConfig.user} ` +
						`-P ${destConfig.port} -p${destConfig.password} ` +
						`-e "DROP DATABASE IF EXISTS ${database}; CREATE DATABASE ${database};"`;
					await exec(dropCmd);

					// Import dump
					spinner.text = `Importing ${database}`;
					const importCmd = `${mysqlExec} -h ${destConfig.host} -u ${destConfig.user} ` +
						`-P ${destConfig.port} -p${destConfig.password} ` +
						`${database} < "${dumpFile}"`;
					await exec(importCmd);

					// Clean up dump file
					await unlink(dumpFile);

					spinner.succeed(`Successfully cloned database: ${database}`);
				} catch (error) {
					spinner.fail(`Failed to clone database: ${database}`);
					console.error(chalk.red(`Error: ${error.message}`));
					throw error;
				}
			}
			
			spinner.succeed("Clone operation completed successfully");
			
			// Clean up connections
			if (sourceDb) await sourceDb.disconnect();
			if (destDb) await destDb.disconnect();
		} catch (error) {
			spinner.fail("Clone operation failed");
			console.error(chalk.red(`Error: ${error.message}`));
			process.exit(1);
		}
	});

program.parse(process.argv);
