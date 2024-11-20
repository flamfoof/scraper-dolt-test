import { execSync } from 'child_process';
import chalk from 'chalk';

/**
 * Checks if the current process has administrator privileges
 * @returns {boolean} True if running with admin privileges, false otherwise
 */
export const isAdmin = () => {
  try {
    execSync('net session', { stdio: 'ignore' });
    return true;
  } catch {
    return false;
  }
};

/**
 * Elevates the privileges of a command by running it in a new elevated PowerShell window
 * @param {string[]} args - Command line arguments to pass to the elevated process
 * @returns {Promise<boolean>} True if elevation succeeded, false otherwise
 */
export const elevatePrivileges = async (args) => {
  const scriptPath = process.argv[1];
  const processArgs = args.join(' ');
  
  // Create a PowerShell command that will keep the window open
  const powershellCommand = (`
    Start-Process powershell -ArgumentList '-Command','& \
    Set-Location \\"${process.cwd()}\\"; \
    bun run \\"${scriptPath}\\" ${processArgs} \
    ' -Verb RunAs
  `).trim();
  
  try {
    console.log(chalk.yellow('\nOpening elevated command prompt...'));
    console.log(chalk.cyan('Please check the new window for command output.'));
    let command = `powershell.exe -Command "${powershellCommand}"`;
    console.log(command);
    execSync(command, {
      stdio: 'inherit'
    });
    return true;
  } catch (error) {
    console.error('Elevation error:', error);
    return false;
  }
};

/**
 * Ensures a function runs with administrator privileges
 * @param {Function} fn - The function to run with elevated privileges
 * @param {string[]} args - Arguments to pass to the function
 * @returns {Promise<any>} The result of the function
 */
export const withPrivileges = async (fn, args = []) => {
  if (!isAdmin()) {
    console.log(chalk.yellow('This operation requires administrator privileges.'));
    return await elevatePrivileges(args);
  }
  return await fn(...args);
};


export async function adminChecker(spinner, options) {
  if (!isAdmin()) {
    spinner.info(chalk.yellow('Administrator privileges required'));

    if (!options.noElevate) {
      spinner.text = 'Requesting administrator privileges...';
      const elevated = await elevatePrivileges(process.argv.slice(2));

      if (!elevated) {
        spinner.fail(chalk.red('Failed to get administrator privileges'));
        console.log(chalk.yellow('Please run this command manually as administrator'));
        await sleep(3000);
        process.exit(1);
      }

      spinner.succeed('Elevated process completed');
      process.exit(0);
    } else {
      spinner.fail(chalk.red('This command must be run as Administrator'));
      console.log(chalk.yellow('\nPlease run this command again with administrator privileges.'));
      await sleep(3000);
      process.exit(1);
    }
  }
}