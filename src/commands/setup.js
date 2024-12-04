import { Command } from "commander";
import ora from "ora";
import chalk from "chalk";
import { config } from "dotenv";
import { promises as fs } from "fs";
import { join } from "path";
import inquirer from "inquirer";
import { DatabaseManager } from "../lib/db-manager.js";

config({ path: "./proj.env" });
let delimiterChar = ";";

// Debug logging utility
const debug = {
	log: (section, message, data = null) => {
		const timestamp = new Date().toISOString();
		const prefix = chalk.blue(`[${timestamp}] [${section}]`);
		console.debug(prefix, message);
		if (data) {
			console.debug(chalk.gray("Data:"), typeof data === "string" ? data : JSON.stringify(data, null, 2));
		}
	},
	error: (section, message, error = null) => {
		const timestamp = new Date().toISOString();
		const prefix = chalk.red(`[${timestamp}] [${section}] ERROR:`);
		console.error(prefix, message);
		if (error?.stack) {
			console.error(chalk.gray("Stack trace:"), error.stack);
		}
	},
};

const program = new Command();

/**
 * Parse SQL content into sections based on meaningful boundaries
 * @param {string} sql SQL content
 * @returns {Array<{name: string, sql: string}>} Array of named SQL sections
 */
const parseSQLSections = (sql) => {
	debug.log("Parser", "Starting SQL parsing");
	const sections = [];
	let currentSection = { name: "Database Setup", sql: "" };
	const lines = sql.split("\n");

	debug.log("Parser", `Total lines to parse: ${lines.length}`);

	for (let i = 0; i < lines.length; i++) {
		let line = lines[i].trim();
		let newLine = line;

		// Skip empty lines and comments
		if (!line || line.startsWith("--") || line == "" || line == delimiterChar) continue;

		if (delimiterChar !== ";") {
			if (line.startsWith(delimiterChar)) {
				continue;
			} else if (line.endsWith(delimiterChar)) {
				newLine = line.slice(0, line.length - delimiterChar.length);
			}
		}

		// Start new section when creating a table
		if (currentSection.sql == "") {
			if (line.startsWith("CREATE")) {
				const createMatches = line.match(/CREATE (\w+) ?(?:`(.*)`|(\w+))/);
				if (createMatches) {
					const [_, createType, createName1, createName2] = createMatches;
					const createName = createName1 || createName2;

					finishSectionParse();

					debug.log("Parser", `Starting new ${createType.toLowerCase()} section: ${createName}`);

					currentSection = { name: `Create ${createName} ${createType}`, sql: "" };
				}
			} else if (line.startsWith("DROP")) {
				const dropMatches = line.match(/DROP (\w+) IF EXISTS ?(?:`(.*)`|(\w+))/);
				if (dropMatches) {
					const [_, dropType, dropName1, dropName2] = dropMatches;
					const dropName = dropName1 || dropName2;

					finishSectionParse();

					debug.log("Parser", `Starting new ${dropType.toLowerCase()} section: ${dropName}`);

					currentSection = { name: `Drop ${dropName} ${dropType}`, sql: "" };
				}
			} else if (line.startsWith("ALTER")) {
				const alterMatches = line.match(/ALTER (\w+) ?(?:`(.*)`|(\w+))/);
				if (alterMatches) {
					const [_, alterType, alterName1, alterName2] = alterMatches;
					const alterName = alterName1 || alterName2;

					finishSectionParse();

					debug.log("Parser", `Starting new ${alterType.toLowerCase()} section: ${alterName}`);

					currentSection = { name: `Alter ${alterName} ${alterType}`, sql: "" };
				}
			} else if (line.startsWith("CALL")) {
				const callMatches = line.match(/CALL (\w+) ?(?:`(.*)`|(\w+))/);
				if (callMatches) {
					const [_, callType, callName1, callName2] = callMatches;
					const callName = callName1 || callName2;
					if (line.endsWith(delimiterChar)) {
						finishSectionParse();
						debug.log("Parser", `Starting new ${callType.toLowerCase()} section: ${callName}`);
						currentSection = { name: `Call ${callName} ${callType}`, sql: "" };
					}
				}
			} else if (line.startsWith("SOURCE")) {
				const sourceMatches = line.match(/SOURCE (\w+)/);
				if (sourceMatches) {
					const [_, sourceType] = sourceMatches;
					if (line.endsWith(delimiterChar)) {
						finishSectionParse();
						debug.log("Parser", `Starting new ${sourceType.toLowerCase()} section: ${sourceType}`);
						currentSection = { name: `Source ${sourceType}`, sql: "" };
					}
				}
			}
		}

		// Start new section for triggers
		if (line.match(/DELIMITER (.*)/)) {
			let delimiterCharMatch = line.match(/DELIMITER (.*)/);
			delimiterChar = delimiterCharMatch[1];

			finishSectionParse();

			currentSection = { name: "Start Delimiter " + delimiterChar, sql: line, delimiter: delimiterChar };

			debug.log("Parser", "Start Delimiter " + delimiterChar + " section");

			finishSectionParse();

			currentSection = { name: "Start new", sql: "" };

			continue;
		}

		// Add line to current section
		currentSection.sql += newLine + "\n";

		if (line.endsWith(delimiterChar)) {
			finishSectionParse();
			currentSection = { name: currentSection.name, sql: "" };
		}
	}

	// Add last section if not empty
	if (currentSection.sql.trim()) {
		finishSectionParse();
	}

	debug.log("Parser", `Parsing complete. Total sections: ${sections.length}`);

	return sections;

	function finishSectionParse() {
		if (currentSection.sql) {
			debug.log(
				"Parser",
				`Completed section: ${currentSection.name}`,
				`SQL length: ${currentSection.sql.length} chars`
			);
			sections.push(Object.assign({}, currentSection));
			debug.log("Parser", "End Parsing section");
		}
	}
};

/**
 * Execute a single SQL section using DatabaseManager
 * @param {DatabaseManager} dbManager Database manager instance
 * @param {string} name Section name
 * @param {string} sql SQL commands
 * @param {ora.Ora} spinner Progress spinner
 */
const executeSQLSection = async (dbManager, name, sql, spinner) => {
	try {
		debug.log("Executor", `Starting execution of section: ${name}`);
		debug.log("Executor", "SQL to execute:", sql);
		spinner.text = `Executing ${name}`;

		if (sql.startsWith("DELIMITER")) {
			// Skip DELIMITER commands as they're handled by DatabaseManager
			spinner.succeed(`Skipped DELIMITER command in ${name}`);
		} else {
			await dbManager.executeQueryContinuously(sql);
			spinner.succeed(`Completed ${name}`);
		}
	} catch (error) {
		spinner.fail(`Failed in ${name}`);
		debug.error("Executor", `Failed executing section: ${name}`, error);
		throw error;
	}
};

program
	.name("setup")
	.description("Set up the database schema and initial data")
	.option("--reset", "Reset the database (WARNING: This will delete all data)")
	.option("--sample-data", "Run tests.sql to generate sample data")
	.option("--debug", "Enable debug logging")
	.option("--connection [type]", "Database connection type (local/master)", "local")
	.action(async (options) => {
		const spinner = ora("Setting up database").start();

		try {
			debug.log("Setup", "Starting database setup", {
				reset: options.reset,
				sampleData: options.sampleData,
				debug: options.debug,
				connection: options.connection,
			});

			// Check if using master connection
			if (options.connection.toLowerCase() === "master") {
				spinner.stop();
				const { confirm } = await inquirer.prompt([
					{
						type: "confirm",
						name: "confirm",
						message: chalk.yellow(
							"WARNING: You are about to run setup on the MASTER database. This is potentially dangerous. Are you sure you want to continue?"
						),
						default: false,
					},
				]);

				if (!confirm) {
					console.log(chalk.blue("Setup cancelled by user"));
					process.exit(0);
				}
				spinner.start();
			}

			// Determine connection configuration based on type
			const connectionConfig =
				options.connection.toLowerCase() === "master"
					? {
							host: process.env.MASTER_DB_HOST,
							user: process.env.MASTER_DB_USER,
							password: process.env.MASTER_DB_PASS,
							port: parseInt(process.env.MASTER_DB_PORT, 10),
					  }
					: {
							host: process.env.LOCAL_DB_HOST,
							user: process.env.LOCAL_DB_USER,
							password: process.env.LOCAL_DB_PASS,
							port: parseInt(process.env.LOCAL_DB_PORT, 10),
					  };

			// Create database manager instance
			debug.log("Setup", "Creating database connection", connectionConfig);
			const dbManager = new DatabaseManager(connectionConfig);
			await dbManager.connect();
			debug.log("Setup", "Database connection established");

			// Read schema files
			const schemaPath = join(process.cwd(), "src", "sql", "schema.sql");
			const scraperPath = join(process.cwd(), "src", "sql", "scraper.sql");
			debug.log("Setup", `Reading schema files: ${schemaPath}, ${scraperPath}`);
			let schema = await fs.readFile(schemaPath, "utf8");
			schema += await fs.readFile(scraperPath, "utf8");
			debug.log("Setup", `Schema files read, total size: ${schema.length} chars`);

			// Parse and execute schema sections
			const sections = parseSQLSections(schema);
			debug.log("Setup", `Parsed ${sections.length} sections to execute`);

			//set up initial data
			for (const section of sections) {
				await executeSQLSection(dbManager, section.name, section.sql, spinner);
			}

			// If sample-data option is enabled, run the tests.sql file
			if (options.sampleData) {
				debug.log("Setup", "Running tests.sql for sample data");
				const testsPath = join(process.cwd(), "src", "sql", "tests.sql");
				const tests = await fs.readFile(testsPath, "utf8");
				const testSections = parseSQLSections(tests);

				for (const section of testSections) {
					await executeSQLSection(dbManager, section.name, section.sql, spinner);
				}
			}

			// Close connection
			debug.log("Setup", "Closing database connection");
			await dbManager.disconnect();

			spinner.succeed(chalk.green("Database setup completed successfully"));

			console.log(chalk.blue("\nDatabase structure:"));
			console.log("• Movies - Core movie information");
			console.log("• MoviesMetadata - Extended movie metadata");
			console.log("• Deeplinks - Streaming platform links");
			console.log("• AuditLog - Change tracking for all tables");
			console.log("• ScraperLog - Logging for scraper operations");
		} catch (error) {
			spinner.fail("Database setup failed");
			// debug.error("Setup", "Setup failed with error", error);
			console.error(chalk.red("\nSetup failed with error:"));
			console.error(chalk.yellow(error.message));
			process.exit(1);
		}
	});

program.parse();
