import JSONStream from "JSONStream";
import logbuffer from "console-buffer";
import * as fs from "fs";
import { resolve } from "path";
import * as JSRuntime from "./JSRuntime.js";
import util from "util";
import { jsRuntime } from "../../src/ScraperLib.js";

export const fileAssetPackName = process.env.PACK_NAME;
export const readFileAsync = util.promisify(fs.readFile);

/**
 * Packs JSON when the output array is full into a single numbered pack file in the "./pack/" location.
 *
 * @param {Array} out - The output array to pack.
 * @param {number} index - The current index in the array.
 * @param {string} mediaFilePath - The file path for the media.
 */
export async function PackJSONWhenFull(out, index, mediaFilePath) {
	var maxPackSize = process.env.MAX_PACK_ITEM;
	if (maxPackSize < 1) {
		throw "Pack size must be greater than 0";
	}
	
	if (index % maxPackSize == maxPackSize - 1 && index > 0) {
		if (!fs.existsSync(mediaFilePath)) {
			fs.mkdirSync(mediaFilePath, {
				recursive: true,
			});
		}

		await WriteToJSON(
			out,
			resolve(mediaFilePath) + "/",
			fileAssetPackName + (index - (maxPackSize - 1)) / maxPackSize
		);

		out.length = 0;

		await JSRuntime.Sleep(1);
	}
}

/**
 * Writes the provided JSON data to a specified file path, with an optional name.
 *
 * @param {Object} json - The JSON data to be written.
 * @param {string} outputPath - The path where the JSON file will be written.
 * @param {string} name - Optional name for the JSON file.
 * @return {Promise<void>} A promise that resolves when the JSON has been written to the file.
 */
export async function WriteToJSON(json, outputPath, name = "out.json") {
	console.log(`Output location at: ${outputPath}\/${name}`);

	if (!fs.existsSync(outputPath)) {
		fs.mkdirSync(outputPath, {
			recursive: true,
		});
	}

	var destination = `${outputPath}/${name}`;
	let outputStream = null
	if(JSRuntime.rt == JSRuntime.RuntimeValue.Node) {
		outputStream = fs.createWriteStream(destination);
	} else if (jsRuntime.rt == JSRuntime.RuntimeValue.Bun) {
		const bunFile = Bun.file(destination)
		outputStream = bunFile.writer()
	}

	try {
		var packager = "";
		var transformStream = JSONStream.stringify("[\n\t", ",\n\t", "\n]");
		outputStream.write("[\n\t");

		for (var i = 0; i < json.length; ++i) {
			packager += JSON.stringify(json[i]) + (i < json.length - 1 ? ",\n\t" : "");
			if (i != 0 && i % 10000 == 0) {
				outputStream.write(packager);
				packager = "";
			}
		}
		outputStream.write(packager);
		outputStream.write("\n]");
		outputStream.end();
		transformStream.end();

		// JSON stream is not async, so this helps...
		await JSRuntime.Sleep(10);
	} catch (e) {
		console.log(e);
		logbuffer.flush();
		process.exit(1);
	}
}

/**
 * Writes the given JSON data to an XML file at the specified output path with the given name.
 *
 * @param {Array} json - the JSON data to be written to the XML file
 * @param {string} outputPath - the path where the XML file will be saved
 * @param {string} name - the name of the XML file (optional)
 * @return {void}
 */
export async function WriteToXML(json, outputPath, name) {
	if (!fs.existsSync(outputPath)) {
		fs.mkdirSync(outputPath, {
			recursive: true,
		});
	}
	var destination = name ? outputPath + "/" + name : outputPath + "/out.csv";

	var xmlData = json.map((el) => JSON.stringify(el)).join("\n");

	fs.writeFile(destination, xmlData, "utf8", function (err) {
		if (err) {
			console.log("An error occured while writing JSON Object to File.");
			console.log(err);
			return;
		}

		console.log("File has been saved at: " + destination);
	});
}

/**
 * Parses all the pack data to JSON file and write to XML if configured.
 *
 * @param {object} json - the input JSON data to pack
 * @param {string} outputPath - the directory path to write the JSON and XML files
 * @param {number} itemAmount - the total number of items to pack
 * @param {number} [maxPackSize=process.env.MAX_PACK_ITEM] - the maximum number of items to pack in each file
 * @return {Promise<void>} - a Promise that resolves when the operation is complete
 */
export async function PackAllToJSON(
	json,
	outputPath,
	itemAmount,
	maxPackSize = process.env.MAX_PACK_ITEM
) {
	var finalResult = [];
	var filePackLength = Math.floor(itemAmount / maxPackSize);
	var mediaFilePath = outputPath + "/pack/";

	console.log("Packing all");

	for (var i = 0; i < filePackLength; i++) {
		var fileChunk = JSON.parse(await readFileAsync(mediaFilePath + ("pack_" + i)));
		for (var j = 0; j < fileChunk.length; j++) {
			finalResult.push(fileChunk[j]);
		}
	}

	// Push the final remaining search items
	for (var i = 0; i < json.length; i++) {
		finalResult.push(json[i]);
	}
	console.log("Almost done packing");

	if (JSON.parse(process.env.WRITE_TO_XML)) await WriteToXML(finalResult, outputPath);

	await WriteToJSON(finalResult, outputPath);
}
