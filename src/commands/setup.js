import { Command } from 'commander';
import ora from 'ora';
import chalk from 'chalk';
import { config } from 'dotenv';
import { promises as fs } from 'fs';
import { join } from 'path';
import mysql from 'mysql2/promise';

config({ path: './proj.env' });

const program = new Command();

program
  .name('setup')
  .description('Set up the database schema and initial data')
  .option('--reset', 'Reset the database (WARNING: This will delete all data)')
  .option('--sample-data [count]', 'Generate sample data', '1000')
  .action(async (options) => {
    const spinner = ora('Setting up database').start();
    
    try {
      // Create connection
      const connection = await mysql.createConnection({
        host: process.env.LOCAL_DB_HOST,
        user: process.env.LOCAL_DB_USER,
        password: process.env.LOCAL_DB_PASS,
        port: process.env.LOCAL_DB_PORT,
        multipleStatements: true // Required for running multiple SQL statements
      });

      // Read and execute schema file
      spinner.text = 'Creating database schema';
      const schemaPath = join(process.cwd(), 'src', 'sql', 'schema.sql');
      const schema = await fs.readFile(schemaPath, 'utf8');
      await connection.query(schema);

      // Generate sample data if requested
      if (options.sampleData) {
        const count = parseInt(options.sampleData, 10);
        if (count > 0) {
          spinner.text = `Generating ${count} sample records`;
          await connection.query(`CALL InsertRandomData(${count})`);
        }
      }

      // Close connection
      await connection.end();

      spinner.succeed(chalk.green('Database setup completed successfully'));
      
      console.log(chalk.blue('\nDatabase structure:'));
      console.log('• Movies - Core movie information');
      console.log('• MoviesMetadata - Extended movie metadata');
      console.log('• Deeplinks - Streaming platform links');
      console.log('• Scrapers - Scraper configurations');
      console.log('• ScrapersActivity - Scraper run logs');
      console.log('• AuditLog - Change tracking\n');

      if (options.sampleData) {
        console.log(chalk.blue('Sample data:'));
        console.log(`• ${options.sampleData} sample movies created`);
        console.log('• Test scraper configuration added\n');
      }

      console.log(chalk.yellow('Next steps:'));
      console.log('1. Use "bun run clone" to clone data from source');
      console.log('2. Use "bun run diff" to compare schemas');
      console.log('3. Check logs in mysql/logs/ for detailed operation history');

    } catch (error) {
      spinner.fail(`Error: ${error.message}`);
      console.error(chalk.red('\nDetailed error:'));
      console.error(error);
      process.exit(1);
    }
  });

program.parse();
