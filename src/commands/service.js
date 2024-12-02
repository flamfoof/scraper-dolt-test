import { Command } from "commander";
import chalk from "chalk";
import { execSync } from "child_process";
import { join } from "path";
import { sleep } from "bun";
import { isAdmin, adminChecker } from "../lib/privilege.js";
import ora from "ora";
import { config } from "dotenv";

config({ path: "./proj.env" });

const program = new Command();

/**
 * Stops and removes the MariaDB service if it exists
 */
const stopMariaDBService = async (spinner) => {
	try {
		// Check if MariaDB service exists
		spinner.text = "Checking MariaDB service status";
		const checkService = execSync("sc query mariadb");

		if (checkService.exitCode === 0) {
			spinner.text = "Stopping MariaDB service";
			console.log(chalk.blue("\nStopping MariaDB service..."));

			// Stop the service
			execSync("sc stop mariadb", { stdio: "inherit" });
			await sleep(1000);

			// Delete the service
			console.log(chalk.blue("Removing MariaDB service..."));
			execSync("sc delete mariadb", { stdio: "inherit" });
			await sleep(4000);

			spinner.succeed("MariaDB service stopped and removed");
		} else {
			spinner.info("MariaDB service not found");
		}
	} catch (error) {
		console.log(chalk.yellow("Service operation message:", error.message));
		spinner.info("No existing MariaDB service found or unable to remove");
	}
};

/**
 * Creates and starts the MariaDB service
 */
const createMariaDBService = async (spinner) => {
	try {
		spinner.text = "Installing MariaDB service";
		console.log(chalk.blue("\nInstalling MariaDB service..."));

		// Get the project root directory
		const projectRoot = process.cwd();
		const configPath = join(projectRoot, "mariadb_local.ini");

		// Install the service using mysql_install_db
		execSync(`mysql_install_db --service MariaDB -c "${configPath}" -p "${process.env.LOCAL_DB_PASS}"`, {
			stdio: "inherit",
		});
		await sleep(1000);

		// Start the service
		spinner.text = "Starting MariaDB service";
		console.log(chalk.blue("\nStarting MariaDB service..."));
		execSync("sc start MariaDB", { stdio: "inherit" });
		await sleep(3000);

		spinner.succeed("MariaDB service installed and started successfully");
	} catch (error) {
		spinner.fail("Error creating MariaDB service");
		await sleep(3000);
		throw error;
	}
};

/**
 * Main service management function
 */
const manageService = async (spinner, options) => {
	if (options.uninstall) {
		await stopMariaDBService(spinner);
	} else {
		if (options.reinstall) {
			await stopMariaDBService(spinner);
		}
		await createMariaDBService(spinner);
	}

	// Display next steps
	console.log(chalk.green("\nNext steps:"));
	if (options.uninstall) {
		console.log('1. Run "bun run service" to reinstall the service');
		console.log('2. Run "bun run setup" to recreate databases and users');
	} else {
		console.log('1. Run "bun run setup" to create necessary databases and users');
		console.log('2. Use "bun run clone" to start syncing data');
	}
};

program
	.name("service")
	.description("Manage MariaDB service")
	.option("--reinstall", "Reinstall the MariaDB service")
	.option("--uninstall", "Uninstall the MariaDB service")
	.option("--no-elevate", "Do not attempt to auto-elevate privileges")
	.action(async (options) => {
		const spinner = ora("Managing MariaDB service").start();

		try {
			// Check for admin privileges and handle elevation if needed
			await adminChecker(spinner, options);

			// At this point we have admin privileges
			console.log(chalk.green("\nRunning with administrator privileges"));

			// Run the main service management function
			await manageService(spinner, options);
			await sleep(3000);
			process.exit(0);
		} catch (error) {
			spinner.fail(`Error: ${error.message}`);
			console.error(chalk.red("\nDetailed error:"));
			console.error(error);
			await sleep(3000);
			process.exit(1);
		}
	});

program.parse();
