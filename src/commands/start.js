import { Command } from 'commander';
import ora from 'ora';
import chalk from 'chalk';
import { execSync, spawn } from 'child_process';
import { existsSync } from 'fs';
import { join } from 'path';
import { homedir, platform } from 'os';
import dotenv from 'dotenv';
import { sleep } from 'bun';

// Load environment variables from proj.env
dotenv.config({ path: './proj.env' });

const program = new Command();

const getSSHKeyPath = () => {
  const sshDir = join(homedir(), '.ssh');
  const keyFile = process.env.SSH_FILE || 'google_compute_engine';
  const keyPath = join(sshDir, keyFile);

  // Check if .ssh directory exists
  if (!existsSync(sshDir)) {
    throw new Error(`SSH directory not found at: ${sshDir}`);
  }

  console.log(chalk.blue(`Using SSH directory: ${sshDir}`));
  console.log(chalk.blue(`Looking for key file: ${keyFile}`));

  // Check if key file exists
  if (!existsSync(keyPath)) {
    throw new Error(`SSH key not found at: ${keyPath}`);
  }

  return keyPath;
};

program
  .name('start')
  .description('Start the MariaDB server and establish SSH tunnel')
  .action(async () => {
    const spinner = ora('Starting SSH tunnel and MariaDB server').start();
    
    try {
      const sshKeyPath = getSSHKeyPath();
      const sshHost = process.env.SSH_HOST;
      const sshUser = process.env.SSH_USER;
      const localPort = process.env.MASTER_DB_PORT;
      
      console.log(chalk.green(`SSH key found at: ${sshKeyPath}`));

      // Start SSH tunnel
      const sshArgs = [
        '-i', sshKeyPath,
        '-L', `${localPort}:localhost:${localPort}`,
        `${sshUser}@${sshHost}`,
        '-N'  // Don't execute remote command
      ];

      // On Windows, use 'start' to open a new window
      if (platform() === 'win32') {
        const sshProcess = spawn('start', ['ssh', ...sshArgs], {
          shell: true,
          windowsHide: false
        });
      } else {
        // For non-Windows platforms, use xterm or similar
        const sshProcess = spawn('ssh', sshArgs, {
          stdio: 'inherit',
          detached: true
        });
        sshProcess.unref();
      }
      console.log("ssh Processes:")
      // console.log(sshProcess)
      // console.log('start', ['ssh', ...sshArgs])
      // process.exit(1)

      spinner.succeed(chalk.green('SSH tunnel established'));
      console.log(chalk.blue(`SSH tunnel running on port ${localPort}`));
      
      // Check if data directory exists and is initialized
      if (!existsSync(join(process.cwd(), 'mysql', 'data', 'mysql'))) {
        spinner.text = 'Initializing database files';
        execSync('mysql_install_db -c mariadb_local.ini -p admin', {
          stdio: 'inherit'
        });
      }

      // Handle process termination
      process.on('SIGINT', () => {
        console.log(chalk.yellow('\nClosing SSH tunnel...'));
        sshProcess.kill();
        process.exit();
      });

      process.on('SIGTERM', () => {
        console.log(chalk.yellow('\nClosing SSH tunnel...'));
        sshProcess.kill();
        process.exit();
      });

    } catch (error) {
      spinner.fail(chalk.red('Failed to start services'));
      console.error(chalk.red(error.message));
      process.exit(1);
    }

    await sleep(1000);

    process.exit(0);
  });

program.parse();
