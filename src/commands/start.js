import { Command } from 'commander';
import ora from 'ora';
import chalk from 'chalk';
import { execSync, spawn } from 'child_process';
import { existsSync } from 'fs';
import { join } from 'path';

const program = new Command();

program
  .name('start')
  .description('Start the MariaDB server')
  .action(async () => {
    const spinner = ora('Starting MariaDB server').start();
    
    try {
      // Check if data directory exists and is initialized
      if (!existsSync(join(process.cwd(), 'mysql', 'data', 'mysql'))) {
        spinner.text = 'Initializing database files';
        execSync('mysql_install_db -c mariadb_local.ini -p admin', {
          stdio: 'inherit'
        });
      }

      spinner.succeed('Starting MariaDB server...');
      
      // Start MariaDB server
      const mariadb = spawn('mysqld', [
        '--defaults-file=mariadb_local.ini',
        '--console'
      ], {
        stdio: 'inherit'
      });

      mariadb.on('error', (error) => {
        console.error(chalk.red(`Failed to start MariaDB: ${error.message}`));
        process.exit(1);
      });

      // Handle process termination
      process.on('SIGINT', () => {
        mariadb.kill('SIGINT');
        process.exit();
      });

      process.on('SIGTERM', () => {
        mariadb.kill('SIGTERM');
        process.exit();
      });

    } catch (error) {
      spinner.fail(`Error: ${error.message}`);
      process.exit(1);
    }
  });

program.parse();
