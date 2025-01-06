import { Command } from "commander";
import ora from "ora";
import chalk from "chalk";
import { config } from "dotenv";
import { DatabaseManager } from "../lib/db-manager.js";
import inquirer from "inquirer";

config({ path: "./proj.env" });

const program = new Command();
const MBSize = 1024 * 1024;

async function getTableSchema(db, database, table) {
    const [schema] = await db.executeQuery(
        `SELECT GROUP_CONCAT(
            COLUMN_NAME, ' ',
            COLUMN_TYPE,
            IF(IS_NULLABLE = 'NO', ' NOT NULL', ''),
            IF(COLUMN_DEFAULT IS NOT NULL, CONCAT(' DEFAULT ', COLUMN_DEFAULT), ''),
            IF(EXTRA != '', CONCAT(' ', EXTRA), '')
            SEPARATOR ', '
        ) as schema
        FROM INFORMATION_SCHEMA.COLUMNS 
        WHERE TABLE_SCHEMA = ? AND TABLE_NAME = ?
        GROUP BY TABLE_NAME`,
        [database, table]
    );
    return schema?.schema || '';
}

async function getTableChecksum(db, database, table) {
    try {
        const [result] = await db.executeQuery(
            `CHECKSUM TABLE ${database}.${table}`,
            []
        );
        return result?.Checksum || 0;
    } catch (error) {
        console.error(`Error getting checksum for ${table}: ${error.message}`);
        return 0;
    }
}

async function analyzeTableDifferences(sourceDb, destDb, database, table) {
    const differences = {
        schemaChanged: false,
        dataChanged: false,
        details: {
            schema: null,
            rowCount: null,
            size: null,
            checksum: null
        }
    };

    // Compare schemas
    const sourceSchema = await getTableSchema(sourceDb, database, table);
    const destSchema = await getTableSchema(destDb, database, table);
    differences.schemaChanged = sourceSchema !== destSchema;
    if (differences.schemaChanged) {
        differences.details.schema = {
            source: sourceSchema,
            destination: destSchema
        };
    }

    // Compare data checksums
    const sourceChecksum = await getTableChecksum(sourceDb, database, table);
    const destChecksum = await getTableChecksum(destDb, database, table);
    differences.dataChanged = sourceChecksum !== destChecksum;
    if (differences.dataChanged) {
        differences.details.checksum = {
            source: sourceChecksum,
            destination: destChecksum
        };
    }

    // Get row counts and size if there are differences
    if (differences.schemaChanged || differences.dataChanged) {
        const [sourceCount] = await sourceDb.executeQuery(
            `SELECT COUNT(*) as count FROM \`${database}\`.\`${table}\``,
            []
        );
        const [destCount] = await destDb.executeQuery(
            `SELECT COUNT(*) as count FROM \`${database}\`.\`${table}\``,
            []
        );
        differences.details.rowCount = {
            source: sourceCount.count,
            destination: destCount.count,
            difference: sourceCount.count - destCount.count
        };

        const [sourceSize] = await sourceDb.executeQuery(
            `SELECT data_length + index_length as size 
            FROM information_schema.TABLES 
            WHERE table_schema = ? AND table_name = ?`,
            [database, table]
        );
        const [destSize] = await destDb.executeQuery(
            `SELECT data_length + index_length as size 
            FROM information_schema.TABLES 
            WHERE table_schema = ? AND table_name = ?`,
            [database, table]
        );
        differences.details.size = {
            source: sourceSize.size || 0,
            destination: destSize.size || 0,
            difference: (sourceSize.size || 0) - (destSize.size || 0)
        };
    }

    return differences;
}

async function compareAndCloneTable(sourceDb, destDb, database, table, batchSize) {
    const sourceSchema = await getTableSchema(sourceDb, database, table);
    const destSchema = await getTableSchema(destDb, database, table);
    
    // Compare schemas
    if (sourceSchema !== destSchema) {
        return true;
    }

    // Compare data checksums
    const sourceChecksum = await getTableChecksum(sourceDb, database, table);
    const destChecksum = await getTableChecksum(destDb, database, table);

    return sourceChecksum !== destChecksum;
}

program
    .name("cloneDiff")
    .description("Clone only changed tables from source to destination")
    .option("-d, --database <n>", "Specific database to clone")
    .option("-b, --batch-size <size>", "Batch size for data transfer", "1000")
    .option("--dry-run", "Show what would be cloned without actually cloning")
    .option("--direction <direction>", "Clone direction: local or master", "local")
    .option("--force", "Force push from local to master without confirmation")
    .action(async (options) => {
        const spinner = ora("Initializing database connections");

        try {
            if (options.direction !== "local" && options.direction !== "master") {
                throw new Error("Invalid direction. Use 'local' or 'master'");
            }

            if (options.direction === "master" && !options.force) {
                const { confirm } = await inquirer.prompt([{
                    type: 'confirm',
                    name: 'confirm',
                    message: 'Are you sure you want to clone from local to master? This will overwrite master data. (Dangerous) (y/n)',
                    default: false
                }]);

                if (!confirm) {
                    console.log(chalk.yellow("Operation cancelled by user."));
                    process.exit(0);
                }
            }

            spinner.start();

            // Source and destination configurations based on direction
            const masterConfig = {
                host: process.env.MASTER_DB_HOST,
                port: parseInt(process.env.MASTER_DB_PORT || "3306"),
                user: process.env.MASTER_DB_USER,
                password: process.env.MASTER_DB_PASS,
                connectionLimit: 5,
            };

            const localConfig = {
                host: process.env.LOCAL_DB_HOST || "localhost",
                port: parseInt(process.env.LOCAL_DB_PORT || "3306"),
                user: process.env.LOCAL_DB_USER,
                password: process.env.LOCAL_DB_PASS,
                connectionLimit: 5,
            };

            const sourceConfig = options.direction === "local" ? masterConfig : localConfig;
            const destConfig = options.direction === "local" ? localConfig : masterConfig;

            const sourceDb = new DatabaseManager(sourceConfig);
            const destDb = new DatabaseManager(destConfig);

            // Test connections
            await sourceDb.connect();
            await destDb.connect();
            spinner.succeed("Database connections established");

            // Get databases to clone
            const databasesToClone = options.database
                ? [options.database]
                : process.env.CLONE_DATABASES?.split(",").map((db) => db.trim()) || [];

            if (databasesToClone.length === 0) {
                throw new Error("No databases specified for cloning");
            }

            // Display cloning plan
            console.log("\nDifferential Cloning Plan:");
            console.log(chalk.cyan("\nDirection:"));
            console.log(`  ${options.direction === "local" ? "Master → Local" : "Local → Master"}${options.direction === "master" && options.force ? " (forced)" : ""}`);
            
            console.log(chalk.cyan("\nSource:"));
            console.log(`  Host: ${sourceConfig.host}`);
            console.log(`  Port: ${sourceConfig.port}`);
            
            console.log(chalk.cyan("\nDestination:"));
            console.log(`  Host: ${destConfig.host}`);
            console.log(`  Port: ${destConfig.port}`);
            
            console.log(chalk.cyan("\nDatabases to Clone:"));
            let totalSize = 0;
            let totalTables = 0;
            
            // Clone each database
            for (const database of databasesToClone) {
                spinner.start(`Analyzing database: ${database}`);

                try {
                    // Get tables in dependency order
                    const tables = await sourceDb.getTables(database);
                    const tableOrder = destDb.getTmdbTableDependencyOrder();
                    tables.sort((a, b) => tableOrder.indexOf(a) - tableOrder.indexOf(b));

                    let changedTables = [];
                    let totalChangedSize = 0n;

                    // Analyze which tables need to be synced
                    for (const table of tables) {
                        spinner.text = `Analyzing table: ${table}`;
                        
                        let differences;
                        if (options.dryRun) {
                            differences = await analyzeTableDifferences(sourceDb, destDb, database, table);
                            if (differences.schemaChanged || differences.dataChanged) {
                                const [{ size }] = await sourceDb.executeQuery(
                                    `SELECT data_length + index_length as size 
                                    FROM information_schema.TABLES 
                                    WHERE table_schema = ? AND table_name = ?`,
                                    [database, table]
                                );
                                changedTables.push({ table, size, differences });
                                totalChangedSize += size || 0;
                            }
                        } else {
                            const needsSync = await compareAndCloneTable(sourceDb, destDb, database, table, options.batchSize);
                            if (needsSync) {
                                const [{ size }] = await sourceDb.executeQuery(
                                    `SELECT data_length + index_length as size 
                                    FROM information_schema.TABLES 
                                    WHERE table_schema = ? AND table_name = ?`,
                                    [database, table]
                                );
                                changedTables.push({ table, size });
                                totalChangedSize += size || 0;
                            }
                        }
                    }

                    console.log(chalk.cyan(`\n${database}:`));
                    console.log(`  Changed Tables: ${changedTables.length}/${tables.length}`);
                    console.log(`  Total Changed Size: ${(Number(totalChangedSize) / MBSize).toFixed(2)} MB`);

                    if (changedTables.length > 0) {
                        console.log(chalk.cyan("\n  Tables to sync:"));
                        for (const { table, size, differences } of changedTables) {
                            const rowCount = await sourceDb.getTableRowCount(database, table);
                            console.log(chalk.yellow(`\n    ${table}:`));
                            console.log(`      Rows: ${rowCount.toLocaleString()}`);
                            console.log(`      Size: ${(Number(size) / MBSize).toFixed(2)} MB`);
                            
                            if (options.dryRun && differences) {
                                if (differences.schemaChanged) {
                                    console.log(chalk.red("\n      Schema differences detected:"));
                                    console.log("      Source schema:");
                                    console.log(`        ${differences.details.schema.source}`);
                                    console.log("      Destination schema:");
                                    console.log(`        ${differences.details.schema.destination}`);
                                }
                                
                                if (differences.dataChanged) {
                                    console.log(chalk.yellow("\n      Data differences:"));
                                    if (differences.details.rowCount) {
                                        const { source, destination, difference } = differences.details.rowCount;
                                        console.log(`      Row count: ${destination} → ${source} (${difference > 0 ? '+' : ''}${difference})`);
                                    }
                                    if (differences.details.size) {
                                        const { source, destination, difference } = differences.details.size;
                                        console.log(`      Size: ${(Number(destination) / MBSize).toFixed(2)}MB → ${(Number(source) / MBSize).toFixed(2)}MB (${difference > 0 ? '+' : ''}${(Number(difference) / MBSize).toFixed(2)}MB)`);
                                    }
                                }
                            }
                        }
                    }

                    totalSize += Number(totalChangedSize) / MBSize;
                    totalTables += changedTables.length;

                    if (!options.dryRun && changedTables.length > 0) {
                        // Perform the actual sync for changed tables
                        let completedTables = 0;
                        for (const { table } of changedTables) {
                            spinner.text = `Syncing ${database}: ${table} (${completedTables}/${changedTables.length})`;
                            
                            // Special handling for AuditLog
                            if (table === 'AuditLog') {
                                await destDb.truncateInOrder(database, ['AuditLog']);
                            }
                            
                            await sourceDb.cloneTable(
                                database,
                                table,
                                destDb,
                                parseInt(options.batchSize)
                            );
                            
                            completedTables++;
                        }

                        spinner.succeed(`Synced ${database}: ${changedTables.length} tables`);
                    } else if (changedTables.length === 0) {
                        spinner.succeed(`No changes needed for ${database}`);
                    }

                } catch (error) {
                    spinner.fail(`Error processing database ${database}: ${error.message}`);
                    throw error;
                }
            }

            console.log(chalk.cyan("\nSummary:"));
            console.log(`  Total Changed Size: ${(totalSize).toFixed(2)} MB`);
            console.log(`  Total Changed Tables: ${totalTables}`);
            console.log(`  Batch Size: ${options.batchSize} rows`);

            if (options.dryRun) {
                console.log(chalk.yellow("\n🔍 Dry run completed. No changes were made."));
                console.log(chalk.yellow("Run the command without --dry-run to perform the actual clone operation."));
            } else {
                console.log(chalk.green("\n✨ Differential clone completed successfully!"));
            }
            process.exit(0);

        } catch (error) {
            spinner.fail(`Error: ${error.message}`);
            process.exit(1);
        }
    });

program.parse();
