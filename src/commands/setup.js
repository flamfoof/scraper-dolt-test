import { Command } from "commander";
import ora from "ora";
import chalk from "chalk";
import { config } from "dotenv";
import { promises as fs } from "fs";
import { join } from "path";
import mariadb from "mariadb";
import inquirer from "inquirer";

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
		let newLine = line
		// console.log(line)
		// Skip empty lines and comments
		if (!line || line.startsWith("--") || line == "" || line == delimiterChar) continue;
		
		if(delimiterChar !== ";"){
			if(line.startsWith(delimiterChar)){
				continue
			} else if (line.endsWith(delimiterChar)){
				newLine = line.slice(0, line.length - delimiterChar.length);
			}
		}

		// Start new section when creating a table
		if(currentSection.sql == ""){
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
				if(line.endsWith(delimiterChar)){
					finishSectionParse();
					debug.log("Parser", `Starting new ${callType.toLowerCase()} section: ${callName}`);
					currentSection = { name: `Call ${callName} ${callType}`, sql: "" };
				}
			}
		}}

		// Start new section for triggers
		if (line.match(/DELIMITER (.*)/)) {
			let delimiterCharMatch = line.match(/DELIMITER (.*)/);
			delimiterChar = delimiterCharMatch[1];

			finishSectionParse();

			currentSection = { name: "Start Delimiter " + delimiterChar, sql: line , delimiter:delimiterChar};

			debug.log("Parser", "Start Delimiter " + delimiterChar + " section");
			
			finishSectionParse();

			currentSection = { name: "Start new", sql: ""};

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
				`SQL length: ${currentSection.sql.length} chars` +
				`\nSQL: ${currentSection.sql}`
			);
			sections.push(Object.assign({}, currentSection));
			debug.log("Parser", "End Parsing section");
		}
	}
};

/**
 * Execute a single SQL section
 * @param {mariadb.Connection} connection Database connection
 * @param {string} name Section name
 * @param {string} sql SQL commands
 * @param {ora.Ora} spinner Progress spinner
 */
const executeSQLSection = async (connection, name, sql, spinner) => {
	try {
		debug.log("Executor", `Starting execution of section: ${name}`);
		debug.log("Executor", "SQL to execute:", sql);
		spinner.text = `Executing ${name}`;
		if(sql.startsWith("DELIMITER")){
			// await connection.execute("DELIMITER " + sql.delimiter);
		} else {
			await connection.query(sql);
		}

		spinner.succeed(`Completed ${name}`);
		// debug.log("Executor", `Successfully completed section: ${name}`);
	} catch (error) {
		spinner.fail(`Failed in ${name}`);
		debug.error("Executor", `Failed executing section: ${name}`, error);
		// console.error(chalk.red(`Error in ${name}:`));
		// console.error(chalk.yellow(error.message));
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
				connection: options.connection
			});

			// Check if using master connection
			if (options.connection.toLowerCase() === 'master') {
				spinner.stop();
				const { confirm } = await inquirer.prompt([
					{
						type: 'confirm',
						name: 'confirm',
						message: chalk.yellow('WARNING: You are about to run setup on the MASTER database. This is potentially dangerous. Are you sure you want to continue?'),
						default: false
					}
				]);

				if (!confirm) {
					console.log(chalk.blue('Setup cancelled by user'));
					process.exit(0);
				}
				spinner.start();
			}

			// Determine connection configuration based on type
			const connectionConfig = options.connection.toLowerCase() === 'master' ? {
				host: process.env.MASTER_DB_HOST,
				user: process.env.MASTER_DB_USER,
				password: process.env.MASTER_DB_PASS,
				port: parseInt(process.env.MASTER_DB_PORT, 10),
			} : {
				host: process.env.LOCAL_DB_HOST,
				user: process.env.LOCAL_DB_USER,
				password: process.env.LOCAL_DB_PASS,
				port: parseInt(process.env.LOCAL_DB_PORT, 10),
			};

			// Create connection
			debug.log("Setup", "Creating database connection", {
				host: connectionConfig.host,
				user: connectionConfig.user,
				port: connectionConfig.port,
			});
			const connection = await mariadb.createConnection(connectionConfig);

			debug.log("Setup", "Database connection established");

			// Read schema file
			const schemaPath = join(process.cwd(), "src", "sql", "schema.sql");
			debug.log("Setup", `Reading schema file: ${schemaPath}`);
			const schema = await fs.readFile(schemaPath, "utf8");
			debug.log("Setup", `Schema file read, size: ${schema.length} chars`);

			// Parse and execute schema sections
			const sections = parseSQLSections(schema);
			debug.log("Setup", `Parsed ${sections.length} sections to execute`);
			
			for (const section of sections) {
				await executeSQLSection(connection, section.name, section.sql, spinner);
			}

			// If sample-data option is enabled, run the tests.sql file
			if (options.sampleData) {
				debug.log("Setup", "Running tests.sql for sample data");
				const testsPath = join(process.cwd(), "src", "sql", "tests.sql");
				const tests = await fs.readFile(testsPath, "utf8");
				const testSections = parseSQLSections(tests);
				
				for (const section of testSections) {
					await executeSQLSection(connection, section.name, section.sql, spinner);
				}
			}

			// Close connection
			debug.log("Setup", "Closing database connection");
			await connection.end();

			spinner.succeed(chalk.green("Database setup completed successfully"));

			console.log(chalk.blue("\nDatabase structure:"));
			console.log("• Movies - Core movie information");
			console.log("• MoviesMetadata - Extended movie metadata");
			console.log("• Deeplinks - Streaming platform links");
			console.log("• Scrapers - Scraper configurations");
			console.log("• ScrapersActivity - Scraper run logs");
			console.log("• AuditLog - Change tracking\n");

			if (options.sampleData) {
				console.log(chalk.blue("Sample data:"));
				console.log("• Sample data generated from tests.sql\n");
			}

			console.log(chalk.yellow("Next steps:"));
			console.log('1. Use "bun run clone" to clone data from source');
			console.log('2. Use "bun run diff" to compare schemas');
			console.log("3. Check logs in mysql/logs/ for detailed operation history");
		} catch (error) {
			// spinner.fail(`Error: ${error.message}`);
			// debug.error("Setup", "Setup failed", error);
			// console.error(chalk.red("\nDetailed error:"));
			// console.error(error);
			process.exit(1);
		}
	});

program.parse();
