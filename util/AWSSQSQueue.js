import { Upload } from "@aws-sdk/lib-storage";
import { SQS } from "@aws-sdk/client-sqs";
import * as path from "path";
import * as fs from "fs";
import * as scraperLib from "../src/ScraperLib.js";
import logbuffer from "console-buffer";

export async function Init(input, opts, output = process.env.DEFAULT_OUTPUT_DIR) {
	console.log("Start aws");
	var qUrl;
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
		qUrl = opts.sqsUrl;
	} else {
		qUrl = opts.sqsUrl;
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
				await SQSQueue(files[i], opts, qUrl, outputWithDate);
				if (i < files.length - 1) {
					logbuffer.flush();
					await scraperLib.Sleep(3000);
				}
			}
			break;
		default:
			await SQSQueue(undefined, opts, qUrl, outputWithDate);
			break;
	}
}

async function SQSQueue(file = process.env.INPUT_DIR, opts, qUrl, outputWithDate) {
	let count = 0;
	const sqs = new SQS({
		credentials: {
			accessKeyId: process.env.AWS_ACCESS_KEY,
			secretAccessKey: process.env.AWS_SECRET_KEY,
		},
		region: process.env.AWS_REGION,
	});
	let fileRead = null;
	
	try {
		fileRead = Bun.file(file)
	} catch (err) {
		console.log(err)
		fileRead = fs.readFileSync(file);
	}
	
	// Replace with your queue URL and JSON data
	const queueUrl = qUrl;
	const jsonData = (await fileRead.text()).split("\n")
	
	// let payload = ""
	let payload = []
	
	// This SQS Process only accepts one message at a time
	for(let i = 0; i < jsonData.length; i++) {
		// payload += i !== jsonData.length - 1 ? jsonData[i] : jsonData[i]
		// payload.push(jsonData[i])
		SendSQSData(jsonData[i], queueUrl, sqs);
		count++
		if(count % 100 == 0) {
			console.log(count)
			logbuffer.flush()
		}
		// console.log(params)
		// const text = payload;

		// // Get the character encoding (optional)
		// const encoding = text.encoding;

		// // Get the number of bytes using TextEncoder
		// const encoder = new TextEncoder(encoding);
		// const byteUsage = encoder.encode(text).length;

		// if(byteUsage > 250000) {
		// 	payload = SendSQSData(payload, queueUrl, sqs);
		// 	count++
		// } else {
		// 	// payload += "\n"
		// }
	}

	// if(payload) {
	// 	SendSQSData(payload, queueUrl, sqs);
	// 	count++
	// }

	console.log(`Exported ${count} items to SQS`);
	
}
let sqsCount = 0
function SendSQSData(payload, queueUrl, sqs) {
	const messageBody = payload;

	// Send message to SQS queue
	const params = {
		MessageBody: messageBody,
		QueueUrl: queueUrl
	};

	// console.log(params)
	const text = payload;

	// Get the character encoding (optional)
	const encoding = text.encoding;

	// Get the number of bytes using TextEncoder
	const encoder = new TextEncoder(encoding);
	const byteUsage = encoder.encode(text).length;
	// console.log(`Total byte usage of the text variable: ${byteUsage} bytes`);

	sqs.sendMessage(params, (err, data) => {
		if (err) {
			console.error('Error sending message to SQS:', err);
		} else {
			let consoleMessage = "Message sent to SQS: " + data.MessageId + 
			"\nTotal byte usage of ${data.MessageId}: " + byteUsage + " bytes" +
			"\nTotal message sent: " + ++sqsCount;

			console.log(consoleMessage)
			logbuffer.flush()
		}
	});

	
	
	return payload;
}

