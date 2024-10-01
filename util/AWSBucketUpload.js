import { Upload } from "@aws-sdk/lib-storage";
import { S3Client, S3, ListBucketsCommand } from "@aws-sdk/client-s3";
import * as path from "path";
import * as fs from "fs";
import * as scraperLib from "../src/ScraperLib.js";
import logbuffer from "console-buffer";

export async function Init(input, opts, output = process.env.DEFAULT_OUTPUT_DIR) {
	console.log("Start aws");
	var destination;
	let dateObj = new Date();
	var fileObj = path.parse(process.env.INPUT_DIR);
	var fileName = fileObj.name;
	var extension = fileObj.ext;
	let action;
	var outputWithDate = `${fileName}_${dateObj.getFullYear()}_${(
		"0" +
		(dateObj.getMonth() + 1)
	).slice(-2)}_${("0" + dateObj.getDate()).slice(-2)}${extension}`;

	if (opts) {
		opts = JSON.parse(opts);
	} else {
		opts = JSON.parse({});
	}

	action = opts.actions;

	if (opts.media == "movies") {
		destination = opts.s3Folder;
	} else {
		destination = opts.s3Folder;
	}

	switch (action) {
		case "batch":
			let files = [];
			let inputDir = process.env.INPUT_DIR;
			fs.readdirSync(inputDir).forEach((file) => {
				files.push(path.join(inputDir, file));
			});
			for (let i = 0; i < files.length; i++) {
                fileObj = path.parse(files[i]);
                fileName = fileObj.name;
                extension = fileObj.ext;
                outputWithDate = `${fileName}_${dateObj.getFullYear()}_${(
                    "0" +
                    (dateObj.getMonth() + 1)
                ).slice(-2)}_${("0" + dateObj.getDate()).slice(-2)}${extension}`;
				await S3FileUpload(files[i], opts, destination, outputWithDate);
				if (i < files.length - 1) {
					logbuffer.flush();
					await scraperLib.Sleep(3000);
				}
			}
			break;
		default:
			await S3FileUpload(undefined, opts, destination, outputWithDate);
			break;
	}
}

async function S3FileUpload(file = process.env.INPUT_DIR, opts, destination, outputWithDate) {
	var s3 = new S3({
		credentials: {
			accessKeyId: process.env.AWS_ACCESS_KEY,
			secretAccessKey: process.env.AWS_SECRET_KEY,
		},
		region: process.env.AWS_REGION,
	});

	var fileStream = fs.createReadStream(file);
	fileStream.on("error", function (err) {
		console.log("File Error", err);
	});

	var uploadParams = {};
	uploadParams.Bucket = opts.s3Bucket;
	uploadParams.Body = fileStream;

	uploadParams.Key = destination + "/" + outputWithDate;

	await s3.putObject(uploadParams, function (err, data) {
		if (err) {
			console.log("Error", err);
		}
		if (data) {
			console.log("Upload Success", data);
			console.log(`Uploaded to: ${uploadParams.Bucket}/${uploadParams.Key}`);
		}
	});
}
