import mysql from 'mysql2/promise';
import PQueue from 'p-queue';
import { z } from 'zod';

const dbConfigSchema = z.object({
  host: z.string(),
  port: z.number().default(3306),
  user: z.string(),
  password: z.string(),
  database: z.string().optional(),
  connectionLimit: z.number().default(10),
});

export class DatabaseManager {
  constructor(config) {
    this.config = dbConfigSchema.parse(config);
    this.pool = mysql.createPool({
      ...this.config,
      waitForConnections: true,
      queueLimit: 0,
      enableKeepAlive: true,
      keepAliveInitialDelay: 0,
    });
    
    this.queue = new PQueue({
      concurrency: this.config.connectionLimit,
      autoStart: true,
    });
  }

  async connect() {
    try {
      await this.pool.getConnection();
      return true;
    } catch (error) {
      throw new Error(`Failed to connect to database: ${error.message}`);
    }
  }

  async disconnect() {
    await this.pool.end();
  }

  async executeQuery(query, params = []) {
    return this.queue.add(async () => {
      const [rows] = await this.pool.execute(query, params);
      return rows;
    });
  }

  async getDatabases() {
    const rows = await this.executeQuery('SHOW DATABASES');
    return rows.map(row => row.Database);
  }

  async getTables(database) {
    const rows = await this.executeQuery(
      'SELECT table_name FROM information_schema.tables WHERE table_schema = ?',
      [database]
    );
    return rows.map(row => row.table_name);
  }

  async getTableCreateStatement(database, table) {
    const [row] = await this.executeQuery(
      'SHOW CREATE TABLE ??.??',
      [database, table]
    );
    return row['Create Table'];
  }

  async getTableColumns(database, table) {
    const rows = await this.executeQuery(
      'SHOW COLUMNS FROM ??.??',
      [database, table]
    );
    return rows.map(row => row.Field);
  }

  async createDatabase(database) {
    await this.executeQuery('CREATE DATABASE IF NOT EXISTS ??', [database]);
  }

  async dropDatabase(database) {
    await this.executeQuery('DROP DATABASE IF EXISTS ??', [database]);
  }

  async cloneTable(sourceDb, destDb, table, batchSize = 10000) {
    // Get create table statement and recreate in destination
    const createStmt = await this.getTableCreateStatement(sourceDb, table);
    await this.executeQuery(`DROP TABLE IF EXISTS ??.??`, [destDb, table]);
    await this.executeQuery(createStmt.replace(sourceDb, destDb));

    // Get total count for batching
    const [countRow] = await this.executeQuery(
      'SELECT COUNT(*) as count FROM ??.??',
      [sourceDb, table]
    );
    const totalRows = countRow.count;

    // Clone data in batches
    for (let offset = 0; offset < totalRows; offset += batchSize) {
      const rows = await this.executeQuery(
        `SELECT * FROM ??.?? LIMIT ? OFFSET ?`,
        [sourceDb, table, batchSize, offset]
      );

      if (rows.length > 0) {
        const columns = await this.getTableColumns(sourceDb, table);
        const placeholders = Array(columns.length).fill('?').join(',');
        const values = rows.map(row => columns.map(col => row[col]));

        await this.executeQuery(
          `INSERT INTO ??.?? (${columns.join(',')}) VALUES (${placeholders})`,
          [destDb, table, ...values.flat()]
        );
      }
    }
  }

  async getDatabaseSize(database) {
    const [row] = await this.executeQuery(
      `SELECT 
        SUM(data_length + index_length) as size,
        COUNT(DISTINCT table_name) as tables
       FROM information_schema.tables
       WHERE table_schema = ?
       GROUP BY table_schema`,
      [database]
    );
    return {
      size: row?.size || 0,
      tables: row?.tables || 0,
    };
  }

  async compareSchemas(sourceDb, destDb) {
    const differences = [];
    const sourceTables = await this.getTables(sourceDb);
    const destTables = await this.getTables(destDb);

    // Check for missing tables
    const missingTables = sourceTables.filter(table => !destTables.includes(table));
    const extraTables = destTables.filter(table => !sourceTables.includes(table));

    differences.push(...missingTables.map(table => ({
      type: 'missing_table',
      table,
      message: `Table exists in source but not in destination`,
    })));

    differences.push(...extraTables.map(table => ({
      type: 'extra_table',
      table,
      message: `Table exists in destination but not in source`,
    })));

    // Compare table structures for common tables
    const commonTables = sourceTables.filter(table => destTables.includes(table));
    for (const table of commonTables) {
      const sourceCreate = await this.getTableCreateStatement(sourceDb, table);
      const destCreate = await this.getTableCreateStatement(destDb, table);

      if (sourceCreate !== destCreate) {
        differences.push({
          type: 'schema_mismatch',
          table,
          message: 'Table schemas do not match',
          source: sourceCreate,
          destination: destCreate,
        });
      }
    }

    return differences;
  }
}
