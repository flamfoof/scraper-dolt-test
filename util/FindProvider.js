import * as fs from "fs";
import logbuffer from "console-buffer";
import _ from "lodash.get";
import * as libUtil from "./API/NetCall.js";
import * as FileManagementJs from "./API/FileManagement.js";
import JSONStream from "JSONStream";
import * as scraperLib from "../src/ScraperLib.js";
const maxPackSize = process.env.MAX_PACK_ITEM;

export async function Init(input, opts, output = process.env.DEFAULT_OUTPUT_DIR) {
	var out = [];
	var percentage = 0;
	var inputList;
	var listLength;
	let isPiping = false;
	let counter = 0;
	try {
		inputList = JSON.parse(input);
		listLength = inputList.length;
		inputList.forEach((item) => {
			item.credits = {};
		});
	} catch (e) {
		if (input instanceof fs.ReadStream) {
			inputList = [];
			isPiping = true;
			input
				.pipe(JSONStream.parse("*"))
				.on("data", (chunk) => {
					let bareNecessities = {};
					bareNecessities.tmdbId = chunk.tmdbId;
					bareNecessities.title = chunk.title;
					if (++counter % 1000 == 0) {
						console.log(counter);
						logbuffer.flush();
					}
					inputList.push(bareNecessities);
				})
				.on("end", () => {
					listLength = inputList.length;
					isPiping = false;
				});
		}
	}

	while (isPiping) {
		await scraperLib.Sleep(500);
	}

	//dispose of input
	try {
		input.length = 0;
	} catch (e) {
		input = null;
	}

	var mediaFilePath = output + "/pack/";
	var currentPackSize = 0;
	var changeList;

	var canSavePack = true;
	var api = process.env.TMDB_API;

	if (opts) {
		opts = JSON.parse(opts);
	} else {
		opts = JSON.parse({});
	}

	if (fs.existsSync(mediaFilePath)) {
		currentPackSize = fs.readdirSync(mediaFilePath).length;
		console.log("pack size: " + currentPackSize);
		logbuffer.flush();
	}

	if (opts.media == "movies") {
		for (var i = currentPackSize * maxPackSize; i < listLength; i++) {
			var query = encodeURIComponent(inputList[i].title);
			var getProvider;
			var moviesDetail;

			console.log("Finding |" + i + "| of |" + listLength + "|");
			// https://api.themoviedb.org/3/movie/453395/watch/providers?api_key=
			// getProvider = await apiConnection.APISearchQuery(`https://imdb-api.com/en/API/SearchMovie/${api}/${query}`, {}, 1);
			var getProvider = await libUtil.APISearchQuery(
				"https://api.themoviedb.org/3/movie/" +
					inputList[i].tmdbId +
					"/watch/providers?api_key=" +
					api
			);

			moviesDetail = inputList[i];
			moviesDetail.providers = [];
			if (getProvider) {
				// Lists as Free, Rent, Buy, Flatrate(Subscription)
				var getUSProviders = getProvider.results["US"];
				var providerTypes = ["free", "rent", "buy", "flatrate", "ads"];
				// console.log(getUSProviders["buy"])
				if (getUSProviders) {
					let providerInfo = {};
					let providerTemplate = []
					for (var j = 0; j < providerTypes.length; j++) {
						if (getUSProviders.hasOwnProperty(providerTypes[j])) {
							for (var k = 0; k < getUSProviders[providerTypes[j]].length; k++) {
								let provId =
									getUSProviders[providerTypes[j]][k].provider_id.toString();
								if (!providerInfo[provId]) {
									providerInfo[provId] = {};
									providerInfo[provId].type = [];
									providerInfo[provId].name =
										getUSProviders[providerTypes[j]][k].provider_name;
								}

								providerInfo[provId].type.push(
									providerTypes[j] == "flatrate"
										? "subscription"
										: providerTypes[j]
								);
							}
						}
					}

					Object.keys(providerInfo).forEach(key => {
						providerTemplate.push({
							id: key,
							name: providerInfo[key].name,
							type: providerInfo[key].type
						})
					})

					moviesDetail.providers = providerTemplate;
				}
			}

			try {
				out.push(moviesDetail);
			} catch (e) {
				console.log(e);
			}

			if (Math.floor((i / inputList.length) * 100) > percentage) {
				percentage = Math.floor((i / inputList.length) * 100);
				// console.log(percentage + "%");
				logbuffer.flush();
			}

			await FileManagementJs.PackJSONWhenFull(out, i, mediaFilePath);
			logbuffer.flush();
		}
	} else if (opts.media == "series") {
		for (var i = currentPackSize * maxPackSize; i < listLength; i++) {
			var getProvider;
			var getUSProviders;
			var providerTypes = ["free", "rent", "buy", "flatrate", "ads"];
			var seriesDetail = {
				id: 0,
				imdbId: 0,
				tmdbId: 0,
				title: "",
				releaseDate: 1900,
				language: "en",
				seasonTotal: 0,
				providers: [],
			};

			console.log("Finding |" + i + "| of |" + (listLength - 1) + "|");

			seriesDetail.id = i;
			seriesDetail.imdbId = inputList[i].imdbId;
			seriesDetail.tmdbId = inputList[i].tmdbId;
			seriesDetail.title = inputList[i].title;
			seriesDetail.releaseDate = inputList[i].releaseDate;
			seriesDetail.language = inputList[i].language;

			var getProvider = await libUtil.APISearchQuery(
				"https://api.themoviedb.org/3/tv/" +
					inputList[i].tmdbId +
					"/watch/providers?api_key=" +
					api
			);

			if (getProvider) {
				getUSProviders = getProvider?.results["US"];
				if (getUSProviders) {
					for (var j = 0; j < providerTypes.length; j++) {
						if (getUSProviders.hasOwnProperty(providerTypes[j])) {
							for (var k = 0; k < getUSProviders[providerTypes[j]].length; k++) {
								var providerInfo = {};
								providerInfo.type =
									providerTypes[j] == "flatrate"
										? "subscription"
										: providerTypes[j];
								providerInfo.id = getUSProviders[providerTypes[j]][k].provider_id;
								providerInfo.name =
									getUSProviders[providerTypes[j]][k].provider_name;
								seriesDetail.providers.push(providerInfo);
							}
						}
					}
				}
			}

			try {
				out.push(seriesDetail);
			} catch (e) {
				console.log(e);
			}

			if (Math.floor((i / inputList.length) * 100) > percentage) {
				percentage = Math.floor((i / inputList.length) * 100);
				console.log(percentage + "%");
				logbuffer.flush();
			}

			scraperLib.fm.PackJSONWhenFull(out, i, mediaFilePath);
			if (i % maxPackSize == 0 && i > 0) {
				console.log(i + " of " + inputList.length);
				logbuffer.flush();
			}
		}
	} else {
		console.log(
			'Did not set the media type to movies or series. \nSample: node main.js -i [file] -findDetail "{\\"media\\": \\"series\\"}" -o process.env.DEFAULT_OUTPUT_DIR' +
				'\nnode main.js -i [file] -findDetail "{\\"filter\\": \\"true\\", \\"results\\": {\\"original_name\\": \\"true\\"}}" -o process.env.DEFAULT_OUTPUT_DIR' +
				'\nnode main.js -i "./tv_series_id_dates.json" -findDetail "{\\"filter\\": true, \\"original_language\\": true, \\"overview\\": true, \\"releaseDate\\": true, \\"title\\": true, \\"id\\": true}" -o process.env.DEFAULT_OUTPUT_DIR' +
				'node main.js -i "./tv_series_id_dates.json" -findDetail "{\\"filter\\": true, \\"original_language\\": true, \\"overview\\": true, \\"releaseDate\\": true, \\"title\\": \\"Battlestar Galactica\\", \\"id\\": true}" -o process.env.DEFAULT_OUTPUT_DIR'
		);
	}

	//Clean up the provider data with duplicate rent/buy properties
	for (let i = 0; i < out.length; i++) {
		// Map to store providers by id
		let providersMap = new Map();
		let data = out[i];

		// Iterate over providers array and merge types
		data.providers.forEach((provider) => {
			if (!providersMap.has(provider.id)) {
				providersMap.set(provider.id, { id: provider.id, name: provider.name, type: [] });
			}
			providersMap.get(provider.id).type.push(provider.type);
		});

		// Convert map values to array
		data.providers = Array.from(providersMap.values());
	}

	console.log("Done");

	logbuffer.flush();

	await FileManagementJs.PackAllToJSON(out, output, inputList.length);
	return out;
}

function FilterParseItem(targetKey, targetValue, item) {
	if (!item) {
		item = {};
	}
	if (!targetValue || targetValue == "") targetValue = "N/A";

	if (targetKey == "id") {
		item.id = targetValue;
		return item;
	} else if (
		targetKey == "original_name" ||
		targetKey == "original_title" ||
		targetKey == "title"
	) {
		item.title = targetValue;
		return item;
	} else if (
		targetKey == "first_air_date" ||
		targetKey == "air_date" ||
		targetKey == "release_date" ||
		targetKey == "releaseDate"
	) {
		item.releaseDate = targetValue.slice(0, 4);
		return item;
	} else if (targetKey == "overview") {
		item.desc = targetValue;
		return item;
	} else if (targetKey == "original_language" || targetKey == "language") {
		item.language = targetValue;
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
