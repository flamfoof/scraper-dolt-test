import * as fs from "fs";
import logbuffer from "console-buffer";
import _ from "lodash.get";
import * as libUtil from "./API/NetCall.js";
import * as FileManagementJs from "./API/FileManagement.js";

const maxPackSize = process.env.IGNORE_PACK_ITEM;

var resultTemplate = {
	tmdbId: 0,
	title: "",
};

export async function Init(input, opts, output = process.env.DEFAULT_OUTPUT_DIR) {
	var out = [];
	var inputList = [];
	var percentage = 0;
	var mediaFilePath = output + "/pack/";
	var currentPackSize = 0;
	var listLength;
	// var listLength = 10
	var resultsPerPage = 20;

	if (fs.existsSync(mediaFilePath)) {
		currentPackSize = fs.readdirSync(mediaFilePath).length;
		console.log("pack size: " + currentPackSize);
		logbuffer.flush();
	}

	var api = process.env.TMDB_API;
	console.log(api);
	if (opts) {
		opts = JSON.parse(opts);
	} else {
		opts = {};
	}

	if (opts.hasOwnProperty("filter")) {
		return await Filter(input, opts, output);
	}

	var inputArray = input.toString().split("\n");
	var uniqueSet = new Set();
	for (var i = 0; i < inputArray.length - 1; i++) {
		var inputItem = JSON.parse(inputArray[i]);
		inputArray[i] = inputItem;
		uniqueSet.add(opts.media == "movies" ? inputItem.original_title : inputItem.original_name);
	}

	var uniqueArray = [...uniqueSet];
	var counterDupe = 0;

	inputList = inputArray;
	if (!listLength) listLength = inputList.length;

	if (opts.media == "movies" || opts.media == "series") {
		var mediaType = opts.media == "movies" ? "movie" : "tv";

		for (var i = currentPackSize * maxPackSize; i < listLength; i++) {
			var inputItem = inputList[i];
			var matchedItems = [];

			var getDate;
			var results;
			var matched = false;

			var results = JSON.parse(JSON.stringify(resultTemplate));
			results.tmdbId = inputList[i].id;
			results.title =
				opts.media == "movies" ? inputList[i].original_title : inputList[i].original_name;
			matched = true;

			if (matched) {
				try {
					if (results.tmdbId) out.push(results);
				} catch (e) {
					console.log(e);
					console.log("Error on getting language for: " + results);
				}
			}

			if (Math.floor((i / listLength) * 100) > percentage) {
				percentage = Math.floor((i / listLength) * 100);
				console.log(percentage + "%");
				logbuffer.flush();
			}

			if (i % maxPackSize == 0 && i > 0 && i > currentPackSize * maxPackSize) {
				console.log(i + " of " + listLength);
				// await libUtil.WriteToJSON(out, mediaFilePath, "pack_" + (i / maxPackSize - 1));
				// out.length = 0;
				logbuffer.flush();
			}
		}
	} else {
		console.log(
			'Did not set the media type to movies or series. \nSample: node main.js -i [file] -findDate "{\\"media\\": \\"series\\"}" -o process.env.DEFAULT_OUTPUT_DIR' +
				'\nnode main.js -i [file] -findDate "{\\"filter\\": \\"true\\", \\"results\\": {\\"original_name\\": \\"true\\"}}" -o process.env.DEFAULT_OUTPUT_DIR' +
				'\nnode main.js -i "./tv_series_id_dates.json" -findDate "{\\"filter\\": true, \\"original_language\\": true, \\"overview\\": true, \\"first_air_date\\": true, \\"original_name\\": true, \\"id\\": true}" -o process.env.DEFAULT_OUTPUT_DIR' +
				'node main.js -i "./tv_series_id_dates.json" -findDate "{\\"filter\\": true, \\"original_language\\": true, \\"overview\\": true, \\"first_air_date\\": true, \\"original_name\\": \\"Battlestar Galactica\\", \\"id\\": true}" -o process.env.DEFAULT_OUTPUT_DIR'
		);
	}

	console.log("Done");

	logbuffer.flush();

	await FileManagementJs.WriteToJSON(out, output);
	return out;
}

export async function Filter(input, opts, output = process.env.DEFAULT_OUTPUT_DIR) {
	var out = [];
	var template = {
		contentId: 0,
		id: 0,
		title: "",
		releaseDate: "",
		desc: "",
		language: "",
		director: [],
		// "voteAverage": 0.0,
		// "voteCount": 0,
	};

	if (JSON.parse(input)) {
		input = JSON.parse(input);
	}

	var details = input.length;
	console.log("Deets: " + details);

	for (var i = 0; i < input.length; i++) {
		var filterCheck = 1;
		var item = JSON.parse(JSON.stringify(template));
		var keyList = Object.keys(opts);

		item.contentId = i;

		if (input[i]) {
			for (var key of keyList) {
				if (input[i][key]) {
					if (typeof opts[key] == "boolean") {
						//Wild-card catch-all - If input key exists, then add
						if (opts[key]) {
							FilterParseItem(key, input[i][key], item);
							filterCheck++;
						}
					} else {
						input[i][key] = ParseItemGeneral(input[i][key]);

						if (input[i][key] == opts[key]) {
							FilterParseItem(key, input[i][key], item);
							filterCheck++;
						}
					}

					logbuffer.flush();
				} else {
					if (typeof opts[key] == "boolean") {
						//If input key NOT exists, then add
						if (!opts[key]) {
							FilterParseItem(key, input[i][key], item);
							filterCheck++;
						}
					}
				}
			}
		} else {
			//input failed
			item.warning = "Failed in getting any info";
		}

		if (filterCheck == keyList.length) {
			out.push(item);
		}
	}

	WriteToJSON(out, process.env.DEFAULT_OUTPUT_DIR, "filterOut.json");

	return out;
}

function FilterParseItem(targetKey, targetValue, item) {
	if (!targetValue || targetValue == "") targetValue = "N/A";

	if (targetKey == "id") {
		item.id = targetValue;
		return item;
	} else if (targetKey == "original_name" || targetKey == "title") {
		item.title = targetValue;
		return item;
	} else if (targetKey == "first_air_date" || targetKey == "releaseDate") {
		item.releaseDate = targetValue.slice(0, 4);
		return item;
	} else if (targetKey == "overview") {
		item.desc = targetValue;
		return item;
	} else if (targetKey == "original_language") {
		item.language = targetValue;
		return item;
	} else if (targetKey == "vote_average") {
		item.voteAverage = targetValue;
		return item;
	} else if (targetKey == "vote_count") {
		item.voteCount = targetValue;
		return item;
	}

	return item;
}

function ParseItemGeneral(item) {
	if (Date.parse(item)) {
		item = item.slice(0, 4);
	}

	return item;
}
