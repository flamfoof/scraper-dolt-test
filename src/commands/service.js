import { Command } from 'commander';
import chalk from 'chalk';
import { execSync, spawn } from 'child_process';
import { join } from 'path';
import { spawnSync } from 'bun';

const program = new Command();

const isAdmin = () => {
  try {
    execSync('net session', { stdio: 'ignore' });
    return true;
  } catch {
    return false;
  }
};

const elevatePrivileges = async () => {
  const scriptPath = process.argv[1];
  const args = process.argv.slice(2);
  
  const powershellCommand = `Start-Process -FilePath 'bun' -ArgumentList 'run ${scriptPath} ${args.join(' ')}' -Verb RunAs -Wait`
  
  try {
    console.log(chalk.yellow('\nElevating privileges for MariaDB service management...'));
    console.log(chalk.cyan('Please approve the elevation request in the new window.'));
    console.log(powershellCommand)
    //don't close spawn window
    execSync(`powershell.exe -Command "${powershellCommand}"`)
    console.log(`cmd /c start powershell.exe -Command "${powershellCommand}"`)
    return true;
  } catch (error) {
    console.error('Elevation error:', error);
    return false;
  }
};

const stopMariaDBService = async () => {
  try {
    // Check if MariaDB service exists
    const checkService = execSync(['sc', 'query', 'mariadb']);
    
    if (checkService.exitCode === 0) {
      console.log(chalk.yellow('Stopping MariaDB service...'));
      
      // Stop the service
      execSync('sc stop mariadb', { stdio: 'inherit' });
      await new Promise(resolve => setTimeout(resolve, 1000));
      
      // Delete the service
      execSync('sc delete mariadb', { stdio: 'inherit' });
      await new Promise(resolve => setTimeout(resolve, 1000));
      
      console.log(chalk.green('MariaDB service stopped and removed.'));
    } else {
      console.log(chalk.yellow('MariaDB service not found.'));
    }
  } catch (error) {
    console.error(chalk.red('Error managing MariaDB service:'), error);
    throw error;
  }
};

const createMariaDBService = async () => {
  try {
    console.log(chalk.yellow('Installing MariaDB service...'));
    
    // Get the project root directory
    const projectRoot = process.cwd();
    const configPath = join(projectRoot, 'mariadb_local.ini');
    
    // Install the service using mysql_install_db
    execSync(`mysql_install_db --service MariaDB -c "${configPath}" -p admin`, {
      stdio: 'inherit'
    });
    await new Promise(resolve => setTimeout(resolve, 1000));
    
    // Start the service
    execSync('sc start MariaDB', { stdio: 'inherit' });
    await new Promise(resolve => setTimeout(resolve, 1000));
    
    console.log(chalk.green('MariaDB service installed and started successfully.'));
  } catch (error) {
    console.error(chalk.red('Error creating MariaDB service:'), error);
    throw error;
  }
};

program
  .name('service')
  .description('Manage MariaDB service')
  .option('--reinstall', 'Reinstall the MariaDB service')
  .action(async (options) => {
    try {
      // Check for admin privileges
      if (!isAdmin()) {
        console.log(chalk.yellow('Requesting administrator privileges...'));
        const elevated = await elevatePrivileges();
        if (!elevated) {
          console.error(chalk.red('Failed to obtain administrator privileges.'));
          process.exit(1);
        }
        return;
      }

      if (options.reinstall) {
        await stopMariaDBService();
      }
      
      await createMariaDBService();
    } catch (error) {
      console.error(chalk.red('Service management failed:'), error);
      process.exit(1);
    }
  });

program.parse();