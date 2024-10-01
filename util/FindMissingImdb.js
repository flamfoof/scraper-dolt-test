import * as fs from "fs";
import util from "util";
import logbuffer from "console-buffer";
import _ from "lodash.get";
import * as libUtil from "./API/NetCall.js";
import * as FileManagementJs from "./API/FileManagement.js";
const readFileAsync = util.promisify(fs.readFile);

// const maxPackSize = process.env.MAX_PACK_ITEM;
const maxPackSize = 30;

export async function Init(input, opts, output = process.env.DEFAULT_OUTPUT_DIR) {
	var out = [];
	var percentage = 0;
	var inputList = JSON.parse(input);
	var mediaFilePath = output + "/pack/";
	var currentPackSize = 0;
    var listLength = inputList.length;
	// var listLength = 7000;
	//var api calls
	var apiCallLimit = 91;
	var apiCounter = 0;
	var canSavePack = true;

	var api = process.env.IMDB_API;

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

	if (opts.applyChanges && opts.applyChanges == true) {
		var changesAt = JSON.parse((await readFileAsync(output + "out.json")).toString());
		var name = opts.name != undefined ? opts.name : opts.media + "_changes_applied.json";
		var index = 0;
		console.log(changesAt.length);
		for (var i = 0; i < changesAt.length; i++) {
			for (var j = index; j < inputList.length; j++) {
				if (inputList[j].id == changesAt[i].id) {
					index = j;
					inputList[j] = changesAt[i];
					console.log("happened at: " + j);
					j = inputList.length + 1;
				}
				// console.log("still happening on: " + j)
				logbuffer.flush();
			}
		}
		console.log("start writing");
		logbuffer.flush();
		await FileManagementJs.WriteToJSON(inputList, output, name);

		return;
	}

	if (opts.media == "movies") {
		for (var i = currentPackSize * maxPackSize; i < listLength; i++) {
			if (apiCounter < apiCallLimit && (inputList[i].imdbId === null || inputList[i].imdbId === "")) {
				console.log(i);
				console.log(`Found the thing at: ${inputList[i].title}`);
				console.log(inputList[i].imdbId);
				console.log(apiCounter + " | " + apiCallLimit);
				apiCounter++;
				var query = encodeURIComponent(inputList[i].title);
				var getImdb;
				var moviesDetail;

				console.log("Finding |" + i + "| of |" + listLength + "|");

				getImdb = await libUtil.APISearchQuery(`https://imdb-api.com/en/API/SearchMovie/${api}/${query}`, {}, 1);

				moviesDetail = inputList[i];
				moviesDetail.imdbId = 0;

				if (getImdb && getImdb.results) {
					if (getImdb.results && getImdb.results.length == 0) {
						moviesDetail.imdbId = 0;
					} else {
						// console.log(getImdb.results[j].description.match(/\d{4}/))

						for (var j = 0; j < getImdb.results.length; j++) {
							if (getImdb.results[j].title == moviesDetail.title && getImdb.results[j].description.match(/\d{4}/) == moviesDetail.releaseDate) {
								moviesDetail.imdbId = getImdb.results[j].id;
							}
						}
					}

					try {
						if (moviesDetail) console.log("pushed");
						// console.log(JSON.stringify(moviesDetail));
						out.push(moviesDetail);
					} catch (e) {
						console.log(e);
					}
				}
			}

			if (Math.floor((i / inputList.length) * 100) > percentage) {
				percentage = Math.floor((i / inputList.length) * 100);
				// console.log(percentage + "%");
				logbuffer.flush();
			}

			if (i % maxPackSize == 0 && i > 0 && i > currentPackSize * maxPackSize) {
				if (canSavePack) {
					if (apiCounter >= apiCallLimit) {
						canSavePack = false;
						listLength = i;
						continue;
					}

					// console.log(i + " of " + inputList.length)
					await FileManagementJs.WriteToJSON(out, mediaFilePath, "pack_" + (i / maxPackSize - 1));
				}
				out.length = 0;
				logbuffer.flush();
			}
		}
	} else if (opts.media == "series") {
		for (var i = currentPackSize * maxPackSize; i < listLength; i++) {
			var query = inputList[i].tmdbId;
			var getImdb;
			var getDetailId;
			var item = JSON.parse(JSON.stringify(inputList[i]));
			var itemDetail = JSON.parse(JSON.stringify(itemsTemplate));

			console.log("Finding |" + i + "| of |" + listLength + "|");

			itemDetail.id = i;
			itemDetail.tmdbId = item.tmdbId;
			itemDetail.title = item.title;

			getImdb = await libUtil.APISearchQuery("https://api.themoviedb.org/3/tv/" + query + "?api_key=" + api + "&language=en-US&page=1&include_adult=false");

			try {
				getDetailId = await libUtil.APISearchQuery("https://api.themoviedb.org/3/tv/" + query + "/external_ids?api_key=" + api + "&language=en-US&page=1&include_adult=false");
				itemDetail.imdbId = getDetailId.imdb_id;
			} catch (e) {
				console.log("Unable to match imdb to tv series show");
			}

			if (getImdb) {
				console.log(getImdb.name);

				if (getImdb.hasOwnProperty("original_language")) {
					continue;
				}

				if (getImdb && getImdb.original_language == "en") {
					itemDetail.country = getImdb.origin_country;
					itemDetail.releaseDate = ParseItemGeneral(getImdb.first_air_date);
					itemDetail.desc = getImdb.overview;
					itemDetail.seasonTotal = getImdb.season_number;
					itemDetail.language = getImdb.original_language;
					// itemDetail.voteAverage = getDetail.vote_average;
					// itemDetail.voteCount = getDetail.vote_count;
					itemDetail.imdbId = getDetailId.imdb_id;

					if (!getImdb.hasOwnProperty("status_message")) {
						itemDetail.episodeTotal = getImdb.number_of_episodes;
						itemDetail.seasonTotal = getImdb.number_of_seasons;
						itemDetail.seasons = [];

						for (var j = 0; j < getImdb.seasons.length; j++) {
							var seasonDetail = JSON.parse(JSON.stringify(seasonsTemplate));
							var seasonAPI = getImdb.seasons[j];
							var noImdbId = false;
							seasonDetail.id = j;
							seasonDetail.tmdbId = seasonAPI.id;

							seasonDetail.seasonNumber = seasonAPI.season_number;
							seasonDetail.releaseDate = ParseItemGeneral(seasonAPI.air_date);
							seasonDetail.title = seasonAPI.name;
							seasonDetail.desc = seasonAPI.overview;
							seasonDetail.episodeCount = seasonAPI.episode_count;

							itemDetail.seasons.push(seasonDetail);

							var episodeAPIList = await libUtil.APISearchQuery("https://api.themoviedb.org/3/tv/" + itemDetail.tmdbId + "/season/" + seasonDetail.seasonNumber + "?api_key=" + api + "&language=en-US&page=1&include_adult=false");

							// console.log("at j: " + j)
							for (var k = 0; k < getImdb.seasons[j].episode_count; k++) {
								try {
									var episodeDetail = JSON.parse(JSON.stringify(episodeTemplate));
									var episodeAPI = episodeAPIList.episodes[k];
									var episodeAPIListExt;
									if (!noImdbId)
										episodeAPIListExt = await libUtil.APISearchQuery(
											"https://api.themoviedb.org/3/tv/" + itemDetail.tmdbId + "/season/" + seasonDetail.seasonNumber + "/episode/" + episodeAPI.episode_number + "/external_ids?api_key=" + api + "&language=en-US&page=1&include_adult=false"
										);

									episodeDetail.id = k;
									episodeDetail.imdbId = episodeAPIListExt.imdb_id ? episodeAPIListExt.imdb_id : 0;
									episodeDetail.tmdbId = episodeAPI.id;
									episodeDetail.episodeNumber = episodeAPI.episode_number;
									episodeDetail.releaseDate = ParseItemGeneral(episodeAPI.air_date);
									episodeDetail.title = episodeAPI.name;
									episodeDetail.desc = episodeAPI.overview;
									// episodeDetail.voteAverage = episodeAPI.vote_average;
									// episodeDetail.voteCount = episodeAPI.vote_count;
									seasonDetail.episodes.push(episodeDetail);

									if (k == 0) {
										if (episodeDetail.imdbId == 0) noImdbId = true;
									}
									// console.log("at k: " + k)
								} catch (e) {
									console.log("Error: " + e);
									console.log("Happened on id: " + seasonDetail.id + " of season: " + j + " on episode: " + k);
									console.log("Link: " + "https://api.themoviedb.org/3/tv/" + itemDetail.tmdbId + "/season/" + (itemDetail.seasonTotal == getImdb.seasons.length ? j + 1 : j) + "?api_key=" + api + "&language=en-US&page=1&include_adult=false");
								}
								logbuffer.flush();
							}
						}
					}
				}

				try {
					out.push(itemDetail);
				} catch (e) {
					console.log(e);
				}
			}

			if (Math.floor((i / inputList.length) * 100) > percentage) {
				percentage = Math.floor((i / inputList.length) * 100);
				console.log(percentage + "%");
				logbuffer.flush();
			}

			if (i % maxPackSize == 0 && i > 0) {
				console.log(i + " of " + inputList.length);
				if (i != currentPackSize * maxPackSize) {
					await FileManagementJs.WriteToJSON(out, mediaFilePath, "pack_" + (i / maxPackSize - 1));
					out.length = 0;
				}
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

	console.log("Done");

	logbuffer.flush();

	await FileManagementJs.PackAllToJSON(out, output, listLength);

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
	} else if (targetKey == "original_name" || targetKey == "original_title" || targetKey == "title") {
		item.title = targetValue;
		return item;
	} else if (targetKey == "first_air_date" || targetKey == "air_date" || targetKey == "release_date" || targetKey == "releaseDate") {
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