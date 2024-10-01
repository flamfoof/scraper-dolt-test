// import Database from 'libsql';
// import Database from 'bun:sqlite';
import dotenv from "dotenv";
import * as fs from "node:fs";
import * as path from "path";
import * as scraperLib from "./src/ScraperLib.js";
import logbuffer from 'console-buffer';
Init()

// const Database = await import (scraperLib.rt == scraperLib.RuntimeValue.Node) ? "libsql" : "bun:sqlite";
async function Init() {
    dotenv.config();

    if(!fs.existsSync(process.env.DATABASE_LOCATION)){
        fs.mkdirSync(process.env.DATABASE_LOCATION, { recursive: true });
    }
    // const file = Bun.file("./sample/series_out_02_23_24.json")
    // console.log(file.size)
    // console.log((await file.json())[0])
    const file = fs.readFileSync("./sample/series_out_02_23_24.json")
    console.log(JSON.parse(file.toString())[0])
    console.log("wtawerawe")
    console.log(scraperLib.jsRuntime.rt)

    // const db = new scraperLib.db.Database(`${process.env.DATABASE_LOCATION}/${process.env.DATABASE_FILE}`, {create:true})
    // performance.mark('start')
    return;
    // const db = new Database(`${process.env.DATABASE_LOCATION}/${process.env.DATABASE_FILE}`);
    // const db = new Database(`${process.env.DATABASE_LOCATION}/${process.env.DATABASE_FILE}`, {create:true});
    var addParams = "";
    var addParamsArray = []
    var modParams = "";
    var addAmount = 50000;

    await db.exec("CREATE TABLE IF NOT EXISTS users (id INTEGER PRIMARY KEY, name TEXT CHECK (name NOT NULL), email TEXT, test1 TEXT, test2 TEXT, test3 TEXT, test4 TEXT)");

    const exists = await db.prepare('SELECT id FROM users WHERE EXISTS (SELECT id FROM users WHERE id = 1)');
    let count = await db.prepare('SELECT COUNT(id) AS count FROM users').get().count;
    
    console.log(count)
    // count = 1
    //add 500k worth of data as string
    for(var i = 0; i < addAmount; i++) {
        addParams += `(${++count}, 'garet${count}', 'great-${count}@email.org', 'test1-${count}', 'test2-${count}', 'test3-${count}')` +
            (i < addAmount-1 ? ',' : '');
        addParamsArray.push({
            $id: count,
            $name: `garet${count}`,
            $email: 'great-${count}@email.org',
            $test1: 'test1-${count}', 
            $test2: 'test2-${count}', 
            $test3: 'test3-${count}'
        })

        // let rando = Math.floor(Math.random() * count)
        // modParams += `'${rando}'` +
        // (i < addAmount-1 ? ',' : '');
    } 
    
    //add 500k table row data
    //nodejs
    // const insertData = db.exec(`INSERT INTO users (id, name, email, test1, test2, test3) VALUES ${addParams}`);

    
    
    const insertUser = db.prepare(`INSERT INTO users (id, name, email, test1, test2, test3) VALUES ($id, $name, $email, $test1, $test2, $test3)`);
    const insertUserData = db.transaction(users => {
        console.log(users.length)
        for (const user of users) {
            insertUser.run(user)
        }
        return users.length;
    })

    console.log("user addedd: " + insertUserData(addParamsArray))

    // db.exec(`UPDATE users SET name = "updooted" WHERE id IN (${modParams})`)
    // get the .exe at the end of the file location using fs
    var program = path.basename(process.argv.splice(0)[0])

    console.log("RAN: " + program);
    let stmt = db.prepare("SELECT * FROM users LIMIT 10");
    let row = stmt.get();
    console.log(row)
    // let deleto = db.prepare ("DELETE FROM users")
    // deleto.get();
    console.log(`Name: ${row.id}, email: ${row.name}`);

    performance.mark('end');
    performance.measure('loopTime', 'start', 'end');

    const measurement = performance.getEntriesByName('loopTime')[0];
    console.log('Loop execution time:', measurement.duration + ' milliseconds');
    // console.log(stmt.all())
}

export async function sleep(ms) {
	return new Promise((resolve) => setTimeout(resolve, ms));
}
