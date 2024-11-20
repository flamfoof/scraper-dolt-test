import { Command } from "commander";
import ora from "ora";
import chalk from "chalk";
import { config } from "dotenv";
import { promises as fs } from "fs";
import { join } from "path";
import mariadb from "mariadb";

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
		// Skip empty lines and comments
		if (!line || line.startsWith("--") || line == "") continue;
		
		if(delimiterChar !== ";"){
			if(line.startsWith(delimiterChar)){
				continue
			} else if (line.endsWith(delimiterChar)){
				line = line.slice(0, line.length - delimiterChar.length);
			}
		}

		// Start new section when creating a table
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

				finishSectionParse();

				debug.log("Parser", `Starting new ${callType.toLowerCase()} section: ${callName}`);

				currentSection = { name: `Call ${callName} ${callType}`, sql: "" };
			}
		}

		// Start new section for triggers
		if (line.match(/DELIMITER (.*)/)) {
			let delimiterCharMatch = line.match(/DELIMITER (.*)/);
			delimiterChar = delimiterCharMatch[1];

			finishSectionParse();

			currentSection = { name: "Start Delimiter " + delimiterChar, sql: "" , delimiter:delimiterChar};

			debug.log("Parser", "Start Delimiter " + delimiterChar + " section");
			continue;
		}


		// Add line to current section
		currentSection.sql += line + "\n";

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
		debug.log("Executor", `Successfully completed section: ${name}`);
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
	.option("--sample-data [count]", "Generate sample data", "1000")
	.option("--debug", "Enable debug logging")
	.action(async (options) => {
		const spinner = ora("Setting up database").start();

		try {
			debug.log("Setup", "Starting database setup", {
				reset: options.reset,
				sampleData: options.sampleData,
				debug: options.debug,
			});

			// Create connection
			debug.log("Setup", "Creating database connection", {
				host: process.env.LOCAL_DB_HOST,
				user: process.env.LOCAL_DB_USER,
				port: process.env.LOCAL_DB_PORT,
			});
			
			const connection = await mariadb.createConnection({
				host: process.env.LOCAL_DB_HOST,
				user: process.env.LOCAL_DB_USER,
				password: process.env.LOCAL_DB_PASS,
				port: parseInt(process.env.LOCAL_DB_PORT, 10),
				// multipleStatements: true,
			});

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
				console.log(`• ${options.sampleData} sample movies created`);
				console.log("• Test scraper configuration added\n");
			}

			console.log(chalk.yellow("Next steps:"));
			console.log('1. Use "bun run clone" to clone data from source');
			console.log('2. Use "bun run diff" to compare schemas');
			console.log("3. Check logs in mysql/logs/ for detailed operation history");
		} catch (error) {
			spinner.fail(`Error: ${error.message}`);
			// debug.error("Setup", "Setup failed", error);
			// console.error(chalk.red("\nDetailed error:"));
			// console.error(error);
			process.exit(1);
		}
	});

program.parse();
