import { Command } from 'commander';
import ora from 'ora';
import chalk from 'chalk';
import { execSync } from 'child_process';
import { config } from 'dotenv';
import { existsSync } from 'fs';
import { join } from 'path';

config({ path: './proj.env' });

const program = new Command();

program
  .name('service')
  .description('Manage MariaDB as a Windows service')
  .option('--uninstall', 'Uninstall the MariaDB service')
  .option('--restart', 'Restart the MariaDB service')
  .action(async (options) => {
    const spinner = ora('Managing MariaDB service').start();
    
    try {
      // Check if running as administrator
      try {
        execSync('net session', { stdio: 'ignore' });
      } catch (e) {
        spinner.fail(chalk.red('This command must be run as Administrator'));
        console.log(chalk.yellow('\nPlease run this command again with administrator privileges.'));
        process.exit(1);
      }

      // Handle uninstall if requested
      if (options.uninstall) {
        spinner.text = 'Uninstalling MariaDB service';
        try {
          execSync('sc.exe stop mariadb', { stdio: 'ignore' });
          execSync('sc.exe delete mariadb', { stdio: 'ignore' });
          spinner.succeed('MariaDB service uninstalled successfully');
        } catch (error) {
          spinner.info('MariaDB service was not installed or already removed');
        }
        process.exit(0);
      }

      // Stop existing service if it exists
      spinner.text = 'Checking for existing MariaDB service';
      try {
        execSync('sc.exe stop mariadb', { stdio: 'ignore' });
        execSync('sc.exe delete mariadb', { stdio: 'ignore' });
        spinner.succeed('Removed existing MariaDB service');
      } catch (error) {
        // Service doesn't exist, which is fine
        spinner.info('No existing MariaDB service found');
      }

      // Wait for service operations to complete
      await new Promise(resolve => setTimeout(resolve, 1000));

      // Check if database is initialized
      if (!existsSync(join(process.cwd(), 'mysql', 'data', 'mysql'))) {
        spinner.text = 'Initializing database files';
        execSync('mysql_install_db -c mariadb_local.ini -p admin', {
          stdio: 'inherit'
        });
      }

      // Install new service
      spinner.text = 'Installing MariaDB service';
      execSync('mysql_install_db --service MariaDB -c mariadb_local.ini -p admin', {
        stdio: 'inherit'
      });

      // Wait for service installation to complete
      await new Promise(resolve => setTimeout(resolve, 1000));

      // Start the service
      spinner.text = 'Starting MariaDB service';
      execSync('sc.exe start MariaDB', { stdio: 'inherit' });

      // Wait for service to start
      await new Promise(resolve => setTimeout(resolve, 1000));

      // Check service status
      try {
        execSync('sc.exe query MariaDB', { stdio: 'ignore' });
        spinner.succeed(chalk.green('MariaDB service installed and started successfully'));
        console.log(chalk.blue('\nThe MariaDB service is now running and will start automatically with Windows.'));
        console.log(chalk.blue('You can manage it using the following commands:'));
        console.log('  • net start MariaDB');
        console.log('  • net stop MariaDB');
        console.log('  • sc.exe query MariaDB');
      } catch (error) {
        spinner.fail('Failed to verify service status');
        throw error;
      }

    } catch (error) {
      spinner.fail(`Error: ${error.message}`);
      console.error(chalk.red('\nDetailed error:'));
      console.error(error);
      process.exit(1);
    }
  });

program.parse();
