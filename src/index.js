import { Command } from 'commander';
import chalk from 'chalk';

const program = new Command();

program
  .name('db-tools')
  .description('Database management and cloning tools')
  .version('1.2.0')
  .command('init', 'Initialize a new MariaDB instance', { executableFile: 'commands/init.js' })
  .command('start', 'Start the MariaDB server', { executableFile: 'commands/start.js' })
  .command('service', 'Install and manage MariaDB as a Windows service', { executableFile: 'commands/service.js' })
  .command('clone', 'Clone databases from source to destination', { executableFile: 'commands/clone.js' })
  .command('diff', 'Compare database schemas', { executableFile: 'commands/clone-diff.js' });

console.log(chalk.cyan('\nMariaDB Management Tools'));
console.log('========================\n');

// Display available commands
program.addHelpText('after', `
Examples:
  $ bun run init                    # Initialize a new MariaDB instance
  $ bun run start                   # Start MariaDB server directly
  $ bun run service                 # Install and start MariaDB as a service
  $ bun run clone -d database_name  # Clone a specific database
  $ bun run diff -d database_name   # Compare database schemas
`);

program.parse();
