import { Command } from 'commander';
import ora from 'ora';
import chalk from 'chalk';
import { config } from 'dotenv';
import { promises as fs } from 'fs';
import { join, resolve } from 'path';
import { execSync } from 'child_process';

config({ path: './proj.env' });

const program = new Command();

program
  .name('init')
  .description('Initialize a new MariaDB instance')
  .option('--force', 'Force reinitialization even if directory exists')
  .action(async (options) => {
    const spinner = ora('Initializing MariaDB').start();
    
    try {
      const currDir = process.cwd().replace(/\\/g, '/');
      const userDir = process.env.USERPROFILE.replace(/\\/g, '/');
      
      // Stop and remove existing service
      try {
        execSync('sc.exe stop mariadb', { stdio: 'ignore' });
        execSync('sc.exe delete mariadb', { stdio: 'ignore' });
      } catch (error) {
        // Ignore errors if service doesn't exist
      }

      // Setup SSH key
      const sshFile = process.env.SSH_FILE;
      const sshPath = join(userDir, '.ssh', sshFile);
      try {
        execSync(`ssh-add "${sshPath}"`, { stdio: 'ignore' });
      } catch (error) {
        spinner.warn('SSH key addition failed, continuing...');
      }

      // Create directory structure
      spinner.text = 'Creating directory structure';
      await fs.rm('./mysql', { recursive: true, force: true });
      await fs.mkdir('./mysql', { recursive: true });
      await fs.mkdir('./mysql/logs', { recursive: true });
      await fs.mkdir('./mysql/data', { recursive: true });

      // Create MariaDB configuration
      spinner.text = 'Creating MariaDB configuration';
      const mariadbConfig = {
        mysqld: {
          'log-bin': 'mysql-bin',
          'server-id': '2',
          'port': '3307',
          'datadir': `${currDir}/mysql/data`,
          'socket': `${currDir}/mysql/mysql.sock`,
          'log-error': `${currDir}/mysql/logs/error.log`,
          'pid-file': `${currDir}/mysql/mysql.pid`,
          'general_log_file': `${currDir}/mysql/logs/mysql.log`,
          'general_log': '1',
          'max_connections': '151',
          'table_open_cache': '2000',
          'tmp_table_size': '35M',
          'thread_cache_size': '151',
          'myisam_max_sort_file_size': '100G',
          'myisam_sort_buffer_size': '70M',
          'key_buffer_size': '25M',
          'read_buffer_size': '64K',
          'read_rnd_buffer_size': '256K',
          'innodb_flush_log_at_trx_commit': '1',
          'innodb_log_buffer_size': '1M',
          'innodb_buffer_pool_size': '46M',
          'innodb_log_file_size': '10M',
          'innodb_thread_concurrency': '9',
          'ssl': 'false',
          'character-set-server': 'utf8mb4',
          'collation-server': 'utf8mb4_general_ci',
        }
      };

      // Write config to file
      await fs.writeFile(
        'mariadb_local.ini',
        Object.entries(mariadbConfig).map(([section, values]) => (
          `[${section}]\n${Object.entries(values)
            .map(([key, value]) => `${key.padEnd(30)} = ${value}`)
            .join('\n')}`
        )).join('\n\n')
      );

      spinner.succeed('MariaDB initialization completed');
      console.log(chalk.green('\nNext steps:'));
      console.log('1. Run "bun run start" to start the MariaDB server');
      console.log('2. Run "bun run setup" to create necessary databases and users');

    } catch (error) {
      spinner.fail(`Error: ${error.message}`);
      process.exit(1);
    }
  });

program.parse();
