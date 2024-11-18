import { Command } from 'commander';
import ora from 'ora';
import chalk from 'chalk';
import { config } from 'dotenv';
import { DatabaseManager } from '../lib/db-manager.js';

config({ path: './proj.env' });

const program = new Command();

program
  .name('clone-diff')
  .description('Compare database schemas between source and destination')
  .option('-d, --database <name>', 'Specific database to compare')
  .action(async (options) => {
    const spinner = ora('Initializing database connections').start();

    try {
      // Initialize database managers
      const sourceDb = new DatabaseManager({
        host: process.env.MASTER_DB_HOST,
        port: parseInt(process.env.MASTER_DB_PORT || '3306'),
        user: process.env.MASTER_DB_USER,
        password: process.env.MASTER_DB_PASS,
        connectionLimit: 5,
      });

      const destDb = new DatabaseManager({
        host: process.env.LOCAL_DB_HOST || 'localhost',
        port: parseInt(process.env.LOCAL_DB_PORT || '3306'),
        user: process.env.LOCAL_DB_USER,
        password: process.env.LOCAL_DB_PASS,
        connectionLimit: 5,
      });

      // Test connections
      await sourceDb.connect();
      await destDb.connect();
      spinner.succeed('Database connections established');

      // Get databases to compare
      const databasesToCompare = options.database
        ? [options.database]
        : process.env.CLONE_DATABASES?.split(',').map(db => db.trim()) || [];

      if (databasesToCompare.length === 0) {
        throw new Error('No databases specified for comparison');
      }

      // Compare each database
      for (const database of databasesToCompare) {
        console.log(chalk.cyan(`\nComparing database: ${database}`));
        
        // Check if databases exist
        const sourceDbs = await sourceDb.getDatabases();
        const destDbs = await destDb.getDatabases();

        if (!sourceDbs.includes(database)) {
          console.log(chalk.red(`Database ${database} does not exist in source`));
          continue;
        }

        if (!destDbs.includes(database)) {
          console.log(chalk.red(`Database ${database} does not exist in destination`));
          continue;
        }

        // Get database sizes
        const sourceSize = await sourceDb.getDatabaseSize(database);
        const destSize = await destDb.getDatabaseSize(database);

        console.log('\nDatabase Statistics:');
        console.log(`Source: ${(sourceSize.size / 1024 / 1024).toFixed(2)} MB, ${sourceSize.tables} tables`);
        console.log(`Destination: ${(destSize.size / 1024 / 1024).toFixed(2)} MB, ${destSize.tables} tables`);

        // Compare schemas
        const differences = await sourceDb.compareSchemas(database, database);

        if (differences.length === 0) {
          console.log(chalk.green('\nSchemas match perfectly!'));
        } else {
          console.log(chalk.yellow('\nSchema differences found:'));
          
          // Group differences by type
          const grouped = differences.reduce((acc, diff) => {
            acc[diff.type] = acc[diff.type] || [];
            acc[diff.type].push(diff);
            return acc;
          }, {});

          // Display missing tables
          if (grouped.missing_table) {
            console.log(chalk.red('\nMissing Tables:'));
            grouped.missing_table.forEach(diff => {
              console.log(`- ${diff.table}`);
            });
          }

          // Display extra tables
          if (grouped.extra_table) {
            console.log(chalk.yellow('\nExtra Tables:'));
            grouped.extra_table.forEach(diff => {
              console.log(`- ${diff.table}`);
            });
          }

          // Display schema mismatches
          if (grouped.schema_mismatch) {
            console.log(chalk.red('\nSchema Mismatches:'));
            grouped.schema_mismatch.forEach(diff => {
              console.log(`\nTable: ${diff.table}`);
              console.log('Source Schema:');
              console.log(diff.source);
              console.log('\nDestination Schema:');
              console.log(diff.destination);
            });
          }
        }
      }

      spinner.succeed('Comparison completed');

    } catch (error) {
      spinner.fail(`Error: ${error.message}`);
      process.exit(1);
    } finally {
      if (sourceDb) await sourceDb.disconnect();
      if (destDb) await destDb.disconnect();
    }
  });

program.parse();
