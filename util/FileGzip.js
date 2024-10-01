import * as fs from "fs";
import { pipeline } from "stream";
import { createGzip, createGunzip, gunzip, gunzipSync } from "zlib";
import * as path from "path";
import logbuffer from "console-buffer";

export async function Init(input, opts, output = process.env.DEFAULT_OUTPUT_DIR) {
	let action;

	if (opts) {
		opts = JSON.parse(opts);
	} else {
		opts = JSON.parse({});
	}

	if (opts.actions) {
		action = opts.actions;
	}

	input = process.env.INPUT_DIR;

	if (!fs.existsSync(input)) {
		throw new Error(`Input file/folder does not exist: ${input}`);
	}

	if (!fs.existsSync(output)) {
		fs.mkdirSync(output, {
			recursive: true,
		});
	}

	if (opts.name) {
		output = output + opts.name;
	} else {
		output = output + path.basename(file) + ".gz";
	}

	if(fs.existsSync(output)) {
		fs.rmSync(output)
	}

	switch (action) {
		case "compress":
			return await CompressToGz(input, output, opts.name, createGzip());
			break;
		case "decompress":
			return await DecompressFromGz(input, output, opts.name);
			break;
		case "chunkBatchCompress":
			return await ChunkBatchCompressToGz(input, output, opts.name);
			break;
		default:
			console.log(
				'Requires the actions field parameter (compress or decompress). E.g. {actions: "compress"} \n' +
					'Can also include a name field parameter to specify the name of the output file. E.g. {actions: "compress", name: "test"}\n'
			);
			return;
	}
}

export async function CompressToGz(input, output = process.env.DEFAULT_OUTPUT_DIR, name, gzipFunc) {
	let file = input;
	const gzip = gzipFunc;
	let source = null;

	try {
		const bunFile = Bun.file(file);
		source = bunFile.stream();
		console.log("Bun streaming");
	} catch (e) {
		source = fs.createReadStream(file);
		// console.log(e);
		console.log("Not bun streaming, going to use node fs stream");
	}

	logbuffer.flush();

	const destination = fs.createWriteStream(output);

	console.log(file);

	//track how much data has been compressed
	let processedBytes = 0;
	let printed = false;
	gzip.on("data", (chunk) => {
		({ processedBytes, printed } = PrintProgress(processedBytes, chunk, printed));
	});

	pipeline(source, gzip, destination, (err) => {
		if (err) {
			console.error("An error occurred:", err);
			process.exitCode = 1;
		} else {
			console.log("File compressed successfully");
			console.log(`File saved to: ${path.dirname(output)} as ${name}`);
		}
	});
}

export async function DecompressFromGz(input, output = process.env.DEFAULT_OUTPUT_DIR, name) {
	const file = input;
	const gzip = createGunzip();
	let source = null;
	let bunFile = null
	let fileWriter = null
	try {
		bunFile = Bun.file(file);
		const bunOut = Bun.file(output)
		source = bunFile.stream();
		fileWriter = bunOut.writer();
	} catch (e) {
		source = fs.createReadStream(file, {highWaterMark: 1024 * 1024});
		fileWriter = fs.createWriteStream(path.dirname(output), {highWaterMark: 1024 * 1024});
		console.log(e);
	}

	console.log(file);
	
	logbuffer.flush();

	//track how much data has been uncompressed
	let processedBytes = 0;
	let printed = false;

	gzip.on("data", (chunk) => {
		try {
			const decoder = new TextDecoder();
			const decodedText = decoder.decode(chunk);
			fileWriter.write(decodedText);
		} catch (e) {
			console.log(e)
		}
		({ processedBytes, printed } = PrintProgress(processedBytes, chunk, printed));
	});
	gzip.on("end", () => {
		try {
			fileWriter.end()		
		} catch (e) {
			console.log(e)
		}
	})
	pipeline(source, gzip, (err) => {
		if (err) {
			console.error("An error occurred:", err);
			console.log("Trying to write to file from " + source);
			process.exitCode = 1;
		} else {
			console.log("File decompressed successfully");
			console.log(`File saved to: ${path.dirname(output)} as ${name}`);
		}
	});
}

export async function ChunkBatchCompressToGz(
	inputDir,
	output = process.env.DEFAULT_OUTPUT_DIR,
	name
) {
	inputDir = process.env.INPUT_DIR;

	if (name) {
		name.replace(".gz", "");
	}

	//get directory of all files in inputDir
	let files = [];

	fs.readdirSync(inputDir).forEach((file) => {
		files.push(path.join(inputDir, file));
	});
	
	for (let i = 0; i < files.length; i++) {
		await CompressToGz(files[i], output + "_" + i, name + "_" + i, createGzip());
	}
}

function PrintProgress(processedBytes, chunk, printed) {
	processedBytes += chunk.length;
	//print per 50 MB
	if ((processedBytes / 1024 / 1024) % 50 <= 1 && !printed) {
		console.log(processedBytes / 1024 / 1024 + " MB\r");
		printed = true;
	} else if ((processedBytes / 1024 / 1024) % 50 > 1) {
		printed = false;
	}
	logbuffer.flush();
	return { processedBytes, printed };
}
