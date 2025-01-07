import { Command } from "commander";
import ora from "ora";
import chalk from "chalk";
import { config } from "dotenv";
import { promises as fs } from "fs";
import { join, resolve } from "path";
import { execSync } from "child_process";
import { sleep } from "bun";
import { isAdmin, elevatePrivileges, adminChecker } from "../lib/privilege.js";

config({ path: "./proj.env" });

const program = new Command();

/**
 * Main initialization function that sets up MariaDB
 */
const initializeMariaDB = async (spinner, options) => {
	const currDir = process.cwd().replace(/\\/g, "/");
	const userDir = process.env.USERPROFILE.replace(/\\/g, "/");

	// Stop and remove existing service
	spinner.text = "Checking for existing MariaDB service";
	try {
		console.log(chalk.blue("\nStopping MariaDB service..."));
		execSync("sc.exe stop mariadb", { stdio: "inherit" });
	} catch (error) {
		console.log(chalk.yellow("Service operation message:", error.message));
		spinner.info("No existing MariaDB service found or unable to stop");
	}
	await sleep(1000);
	try {
		console.log(chalk.blue("Removing MariaDB service..."));
		execSync("sc.exe delete mariadb", { stdio: "inherit" });
		spinner.succeed("Removed existing MariaDB service");
	} catch (error) {
		console.log(chalk.yellow("Service operation message:", error.message));
		spinner.info("No existing MariaDB service found or unable to remove");
	}

	// Setup SSH key
	const sshFile = process.env.SSH_FILE;
	const sshPath = join(userDir, ".ssh", sshFile);
	try {
		console.log(chalk.blue("\nAdding SSH key..."));
		execSync(`ssh-add "${sshPath}"`, { stdio: "inherit" });
	} catch (error) {
		console.log(chalk.yellow("SSH key error:", error.message));
		spinner.warn("SSH key addition failed, continuing...");
	}

	// Create directory structure
	spinner.text = "Creating directory structure";
	console.log(chalk.blue("\nSetting up directory structure..."));
	await fs.rm("./mysql", { recursive: true, force: true });
	await fs.mkdir("./mysql", { recursive: true });
	await fs.mkdir("./mysql/logs", { recursive: true });
	await fs.mkdir("./mysql/data", { recursive: true });
	console.log(chalk.green("Directory structure created successfully"));

	// Create MariaDB configuration
	spinner.text = "Creating MariaDB configuration";
	console.log(chalk.blue("\nGenerating MariaDB configuration..."));
	const mariadbConfig = {
		mysqld: {
			"log-bin": "mysql-bin",
			"server-id": "2",
			port: "3307",
			datadir: `${currDir}/mysql/data`,
			socket: `${currDir}/mysql/mysql.sock`,
			"log-error": `${currDir}/mysql/logs/error.log`,
			slow_query_log_file: `${currDir}/mysql/logs/slow_query.log`,
			slow_query_log: 1,
			innodb_buffer_pool_size: "256M",
			innodb_log_file_size: "50M",
			max_connections: 100,
			innodb_flush_log_at_trx_commit: 2,
			lower_case_table_names: 2,
			event_scheduler: 1,
			expire_logs_days: 7,

			//   'pid-file': `${currDir}/mysql/mysql.pid`,
			// 'general_log_file': `${currDir}/mysql/logs/mysql.log`,
			// 'general_log': null,
			// 'general_log_file' : `${currDir}/mysql/logs/mysql.log`,
			// 'max_connections': '100',
			//   'table_open_cache': '2000',
			//   'tmp_table_size': '35M',
			//   'thread_cache_size': '151',
			//   'myisam_max_sort_file_size': '100G',
			//   'myisam_sort_buffer_size': '70M',
			//   'key_buffer_size': '25M',
			//   'read_buffer_size': '64K',
			//   'read_rnd_buffer_size': '256K',
			//   'innodb_flush_log_at_trx_commit': '1',
			//   'innodb_log_buffer_size': '1M',
			//   'innodb_buffer_pool_size': '46M',
			//   'innodb_log_file_size': '10M',
			//   'innodb_thread_concurrency': '9',
			//   'ssl': 'false',
			//   'character-set-server': 'utf8mb4',
			//   'collation-server': 'utf8mb4_general_ci',
		},
	};

	// Write config to file
	await fs.writeFile(
		"mariadb_local.ini",
		Object.entries(mariadbConfig)
			.map(
				([section, values]) =>
					`[${section}]\n${Object.entries(values)
						.map(([key, value]) => {
							if(value === null) {
								return `${key}`
							}
							return `${key.padEnd(30)} = ${value}`
						})
						.join("\n")}`
			)
			.join("\n\n")
	);
	console.log(chalk.green("Configuration file created successfully"));
};

program
	.name("init")
	.description("Initialize a new MariaDB instance")
	.option("--force", "Force reinitialization even if directory exists")
	.option("--no-elevate", "Do not attempt to auto-elevate privileges")
	.action(async (options) => {
		const spinner = ora("Initializing MariaDB").start();

		try {
			// Check for admin privileges and handle elevation if needed
			await adminChecker(spinner, options);

			// At this point we have admin privileges
			console.log(chalk.green("\nRunning with administrator privileges"));

			// Run the main initialization function
			await initializeMariaDB(spinner, options);

			spinner.succeed("MariaDB initialization completed");
			console.log(chalk.green("\nNext steps:"));
			console.log('1. Run "bun run start" to start the MariaDB server');
			console.log('2. Run "bun run service" to start the MariaDB Server as an automatic service (recommended)');
			console.log('3. Run "bun run setup" to create necessary databases and users');
			await sleep(3000);
			process.exit(0);
		} catch (error) {
			spinner.fail(`Error: ${error.message}`);
			console.error(chalk.red("\nDetailed error:"), error);
			await sleep(3000);
			process.exit(1);
		}
	});

program.parse();
