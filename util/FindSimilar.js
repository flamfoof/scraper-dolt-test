import * as fs from "fs";
import logbuffer from "console-buffer";
import _ from "lodash.get";
import * as libUtil from "./API/NetCall.js";
import * as FileManagementJs from "./API/FileManagement.js";

const maxPackSize = process.env.MAX_PACK_ITEM;

export async function Init(opts, output = process.env.DEFAULT_OUTPUT_DIR) {
	var out = [];
	var percentage = 0;
	var mediaFilePath = output + "/pack/";
	var currentPackSize = 0;
	var listLength = 500;
	// listLength = 500;

	if (fs.existsSync(mediaFilePath)) {
		currentPackSize = fs.readdirSync(mediaFilePath).length;
		console.log("pack size: " + currentPackSize);
		logbuffer.flush();
	}

	var api = process.env.TMDB_API;

	if (opts) {
		opts = JSON.parse(opts);
	} else {
		opts = JSON.parse({});
	}

	if (opts.media == "movies") {
		for (var i = currentPackSize != 0 ? currentPackSize * maxPackSize + 1 : 1; i < listLength + 1; i++) {
			var query = 338953;
			var getDetail;
			var moviesDetail;

			console.log("Finding |" + i + "| of |" + listLength + "|");

			getDetail = await libUtil.APISearchQuery("https://api.themoviedb.org/3/movie/" + query + "/similar?api_key=" + api + "&language=en-US&page=" + i);

			moviesDetail = getDetail;

			try {
				if (moviesDetail) out.push(moviesDetail);
			} catch (e) {
				console.log(e);
			}

			if (Math.floor((i / listLength) * 100) > percentage) {
				percentage = Math.floor((i / listLength) * 100);
				console.log(percentage + "%");
				logbuffer.flush();
			}

			if (i % maxPackSize == 0 && i > 0 && i > currentPackSize * maxPackSize) {
				console.log(i + " of " + listLength);
				await FileManagementJs.WriteToJSON(out, mediaFilePath, "pack_" + (i / maxPackSize - 1));
				out.length = 0;
				logbuffer.flush();
			}
		}
	} else if (opts.media == "series") {
	}

	console.log("Done");

	logbuffer.flush();

	await FileManagementJs.PackAllToJSON(out, output, listLength + 1, opts.media, maxPackSize);
	return out;
}