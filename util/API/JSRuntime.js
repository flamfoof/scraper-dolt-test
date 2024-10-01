import logbuffer from "console-buffer";
import {basename} from "path";

export const RuntimeValue = {
	Bun: "bun",
	Node: "node"
}

var runtime = basename(process.argv[0]);

console.log(`Runtime being called from: ${runtime}`)

export const rt = runtime.includes("node") ? RuntimeValue.Node : RuntimeValue.Bun;
export var consolePrint = [];

/**
 * Asynchronous function to pause the execution for a specified number of milliseconds.
 *
 * @param {number} ms - The number of milliseconds to pause the execution
 * @return {Promise} A Promise that resolves after the specified number of milliseconds
 */
export  async function Sleep(ms) {
	if(rt == RuntimeValue.Node) {
		return await new Promise((resolve) => setTimeout(resolve, ms));
	} else if (rt == RuntimeValue.Bun) {
		Bun.sleepSync(parseInt(ms))
	}
}
/**
 * Add a string to the console print array.
 *
 * @param {string} string - the string to be added to the console print array
 * @return {void} 
 */
export function AddToPrintConsole(string) {
	consolePrint.push(string);
}

/**
 * Prints all the elements of consolePrint array to the console and clears the array.
 *
 * @return {void} 
 */
export function PrintAllConsole() {
	var string = "";
	let constLength = 6 - consolePrint.length
	for (let i = 0; i < consolePrint.length; i++) {
		string += consolePrint[i] + "\n";
	}

	for(let i = 0; i < constLength; i++) {
		string += "|\n";
	}
	console.log(string);
	consolePrint.length = 0;
	logbuffer.flush();
}

/**
 * Calculate the hours and minutes from the given seconds and return the time in a string format.
 *
 * @param {number} seconds - The total number of seconds
 * @return {string} The time in the format "xh ym"
 */
export function CalculateRuntimeSeconds(seconds) {
	var time = "";
	var hours, minutes;

	minutes = Math.ceil((seconds / 60) % 60);
	hours = Math.floor(seconds / 3600);

	if (hours > 0) {
		time += hours + "h";
	}
	if (minutes > 0) {
		time += " " + minutes + "m";
	}

	return time;
}

export function PreventDuplicateFirstItem(indexx, currentPackSize) {
	return indexx;
}
