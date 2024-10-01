// import { Database } from 'bun:sqlite';
import dotenv from "dotenv";
import * as fs from "fs";
import * as path from "path";
import * as JSRuntime from "./JSRuntime.js"

export const Database = await import((JSRuntime.rt == JSRuntime.RuntimeValue.Node) ? "libsql" : "bun:sqlite");



// console.log("It is recommended to run the Database Library with Bun instead of Node");

export function Init() {
    console.log("ehehehe hello from DatabaseConnection library")
}

