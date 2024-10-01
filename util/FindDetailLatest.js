import * as fs from "fs";
import logbuffer from "console-buffer";
import _ from "lodash.get";
import find from "lodash.find";
import * as libUtil from "./API/NetCall.js";
import * as JSRuntimeJs from "./API/JSRuntime.js";
import * as FileManagementJs from "./API/FileManagement.js";
import * as scraperLib from "../src/ScraperLib.js";

const maxPackSize = process.env.MAX_PACK_ITEM;
const appendResponses = "changes,external_ids,credits";

export async function Init(input, opts, output = process.env.DEFAULT_OUTPUT_DIR) {
	var out = [];
	var inputList;
	try {
		inputList = JSON.parse(input);
	} catch (e) {
		inputList = input;
	}
	var percentage = 0;
	var mediaFilePath = output + "/pack/";
	var currentPackSize = 0;
	var listLength = inputList.length;

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

	if (opts.hasOwnProperty("filter")) {
		return await Filter(input, opts, output);
	}

	if (opts.media == "movies" || opts.media == "series") {
		for (
			var i = JSRuntimeJs.PreventDuplicateFirstItem(
				currentPackSize * maxPackSize,
				currentPackSize
			);
			i < listLength;
			i++
		) {
			var query = inputList[i].tmdbId;
			var getDetail;
			var getDetailId;
			var item = JSON.parse(JSON.stringify(inputList[i]));
			var itemDetail =
				opts.media == "movies"
					? new scraperLib.ContentTemplates().GetMoviesTemplate()
					: new scraperLib.ContentTemplates().GetSeriesTemplate();

			//movies are still updated the same...
			var mediaType = opts.media == "movies" ? "movie" : "tv";

			console.log("Finding |" + (i + 1) + "| of |" + listLength + "|");

			itemDetail.id = i;
			itemDetail.tmdbId = item.tmdbId;
			itemDetail.title = item.title ? item.title : item.name;

			getDetail = await libUtil.APISearchQuery(
				`https://api.themoviedb.org/3/${mediaType}/${query}?append_to_response=${appendResponses}&api_key=${api}&language=en-US&page=1&include_adult=false`
			);

			if (getDetail) {
				console.log(getDetail.name || getDetail.title);

				try {
					getDetailId = getDetail.external_ids;
					itemDetail.imdbId = getDetailId.imdb_id;
				} catch (e) {
					console.log("Unable to match imdb to content");
				}

				if (opts.media == "movies") {
					if (getDetail) {
						if (!getDetail.hasOwnProperty("status_message")) {
							itemDetail.id = i;
							itemDetail.tmdbId = getDetail.id;
							itemDetail.imdbId = getDetail.imdb_id;
							itemDetail.releaseDate = ParseItemGeneral(getDetail.release_date);
							itemDetail.title = getDetail.title || getDetail.original_title;
							itemDetail.desc = getDetail.overview;
							itemDetail.credits = {
								cast: getDetail.credits?.cast.map((cast) => {
									return {
										name: cast.name,
										job:
											cast.job ||
											cast.department ||
											cast.known_for_department,
									};
								}),
								crew: getDetail.credits?.crew
									.filter((crew) => {
										if (
											crew.job.toLowerCase() == "director" ||
											crew.job.toLowerCase() == "directors" ||
											crew.job.toLowerCase().includes("writer")
										) {
											return true;
										}
									})
									.map((crew) => {
										return {
											name: crew.name,
											job: crew.job,
										};
									}),
							};
							itemDetail.language = getDetail.original_language;
							itemDetail.tags = getDetail.genres;
							itemDetail.popularity = getDetail.popularity;
							itemDetail.audienceRating = getDetail.vote_average;
							itemDetail.voteCount = getDetail.vote_count;
						}
					} else {
						getDetailId = null;
						// itemDetail.error = "Unable to match language: 'en'";
					}
				} else if (opts.media == "series") {
					if (getDetail) {
						//if title is not assigned yet, assign here
						if (!itemDetail.title) {
							itemDetail.title = getDetail.name;
						}

						itemDetail.country = getDetail.origin_country;
						itemDetail.releaseDate = ParseItemGeneral(getDetail.first_air_date);
						itemDetail.desc = getDetail.overview;
						itemDetail.credits = {
							cast: getDetail.credits?.cast.map((cast) => {
								return {
									name: cast.name,
									job: cast.job || cast.department || cast.known_for_department,
								};
							}),
							crew: getDetail.credits?.crew
								.filter((crew) => {
									if (
										crew.job.toLowerCase() == "director" ||
										crew.job.toLowerCase() == "directors" ||
										crew.job.toLowerCase().includes("writer")
									) {
										return true;
									}
								})
								.map((crew) => {
									return {
										name: crew.name,
										job: crew.job,
									};
								}),
						};
						itemDetail.tags = getDetail.genres;
						itemDetail.popularity = getDetail.popularity;
						itemDetail.seasonCount = getDetail.season_number;
						itemDetail.language = getDetail.original_language;
						itemDetail.audienceRating = getDetail.vote_average;
						itemDetail.voteCount = getDetail.vote_count;

						if (!getDetail.hasOwnProperty("status_message")) {
							itemDetail.episodeCount = getDetail.number_of_episodes;
							itemDetail.seasonCount = getDetail.number_of_seasons;
							itemDetail.seasons = [];

							//Changes remove after
							// itemDetail.changes = getDetail.changes.changes

							let changedTarget = [];

							for (var changes of getDetail.changes.changes) {
								if (changes.key == "season") {
									changedTarget = changes.items;
									break;
								}
							}

							for (var j = 0; j < changedTarget.length; j++) {
								var seasonDetail =
									new scraperLib.ContentTemplates().GetSeasonsTemplate();
								var seasonAPI = find(getDetail.seasons, {
									season_number: changedTarget[j].value.season_number,
								});
								// var seasonAPI = getDetail.seasons.find((element) => {
								// 	return element.season_number == changedTarget[j].value.season_number
								// });
								// for(var seasons in getDetail.seasons) {
								// 	if(seasons.season_number == changedTarget[j].value.season_number) {
								// 		seasonAPI = seasons;
								// 		break;
								// 	}
								// }
								seasonDetail.id = j;
								seasonDetail.tmdbId = seasonAPI.id;
								seasonDetail.seasonId = changedTarget[j].value.season_id;
								seasonDetail.seasonNumber = changedTarget[j].value.season_number;
								seasonDetail.releaseDate = ParseItemGeneral(seasonAPI.air_date);
								seasonDetail.title = seasonAPI.name;
								seasonDetail.desc = seasonAPI.overview;
								seasonDetail.episodeCount = seasonAPI.episode_count;

								itemDetail.seasons.push(seasonDetail);

								var episodeChangesAPIList = await libUtil.APISearchQuery(
									`https://api.themoviedb.org/3/tv/season/${seasonDetail.seasonId}/changes?api_key=${api}&language=en-US&include_adult=false`
								);

								var episodeAPIList = await libUtil.APISearchQuery(
									`https://api.themoviedb.org/3/tv/${itemDetail.tmdbId}/season/${seasonDetail.seasonNumber}?api_key=${api}&language=en-US&include_adult=false`
								);
								let episodeChangedTarget = [];

								//remove after for changes
								// seasonDetail.changes = episodeChangesAPIList.changes

								for (var changes of episodeChangesAPIList.changes) {
									if (changes.key == "episode") {
										episodeChangedTarget = changes.items;
										break;
									}
								}

								// console.log("at j: " + j)
								for (var k = 0; k < episodeChangedTarget.length; k++) {
									try {
										var episodeDetail =
											new scraperLib.ContentTemplates().GetEpisodesTemplate();

										var episodeAPI = find(episodeAPIList.episodes, {
											episode_number:
												episodeChangedTarget[k].value.episode_number,
										});

										episodeDetail.id = k;
										episodeDetail.episodeId =
											episodeChangedTarget[k].value.episode_id;
										episodeDetail.tmdbId = episodeAPI.id;
										episodeDetail.episodeNumber = episodeAPI.episode_number;
										episodeDetail.releaseDate = ParseItemGeneral(
											episodeAPI.air_date
										);
										episodeDetail.title = episodeAPI.name;
										episodeDetail.desc = episodeAPI.overview;
										seasonDetail.episodes.push(episodeDetail);
									} catch (e) {
										console.log("Error: " + e);
										console.log(
											"Happened on id: " +
												seasonDetail.id +
												" of season: " +
												seasonDetail.seasonNumber +
												" on episode: " +
												episodeDetail.episodeNumber
										);
										console.log(
											"Link: " +
												"https://api.themoviedb.org/3/tv/" +
												itemDetail.tmdbId +
												"/season/" +
												(itemDetail.seasonCount == getDetail.seasons.length
													? j + 1
													: j) +
												"?api_key=" +
												api +
												"&language=en-US&page=1&include_adult=false"
										);
									}
									logbuffer.flush();
								}
							}
						}
					}
				}

				try {
					!itemDetail.error ? out.push(itemDetail) : console.log(itemDetail.error);
				} catch (e) {
					console.log(e);
				}
			}

			if (Math.floor((i / inputList.length) * 100) > percentage) {
				percentage = Math.floor((i / inputList.length) * 100);
				console.log(percentage + "%");
				logbuffer.flush();
			}

			await FileManagementJs.PackJSONWhenFull(out, i, mediaFilePath);
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

	//re-sort IDs
	out.sort(function (a, b) {
		return a.tmdbId - b.tmdbId;
	});

	for (var i = 0; i < out.length; i++) {
		out[i].id = i;
	}

	await FileManagementJs.PackAllToJSON(out, output, listLength);

	return out;
}

export async function Filter(input, opts, output = process.env.DEFAULT_OUTPUT_DIR) {
	var out = [];
	var filterTemplate = {
		tmdbId: 0,
		id: 0,
		title: "",
		releaseDate: "",
		desc: "",
		language: "",
	};

	if (JSON.parse(input)) {
		input = JSON.parse(input);
	}

	var details = input.length;
	console.log("Deets: " + details);

	for (var i = 0; i < input.length; i++) {
		var filterCheck = 1;
		var item = JSON.parse(JSON.stringify(filterTemplate));
		var keyList = Object.keys(opts);

		item.tmdbId = i;

		if (input[i]) {
			for (var key of keyList) {
				if (input[i][key]) {
					// console.log("Has key for: |" + key + "| : |" + opts[key] + "|")
					// console.log("Input: " + input[i][key]);

					if (typeof opts[key] == "boolean") {
						//Wild-card catch-all - If input key exists, then add
						if (opts[key]) {
							FilterParseItem(key, input[i][key], item);
							filterCheck++;
						}
					} else {
						// console.log("Comparing |" + input[i][key] + "| with |" + opts[key] + "|")

						//Search for specifics

						input[i][key] = ParseItemGeneral(input[i][key]);

						if (input[i][key] == opts[key]) {
							// console.log(Date.parse(opts[key]))
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

	await FileManagementJs.WriteToJSON(out, process.env.DEFAULT_OUTPUT_DIR, "filterOut.json");

	return out;
}

function FilterParseItem(targetKey, targetValue, item) {
	if (!item) {
		item = {};
	}
	if (!targetValue || targetValue == "") targetValue = null;

	if (targetKey == "id") {
		item.id = targetValue;
		return item;
	} else if (
		targetKey == "original_name" ||
		targetKey == "title" ||
		targetKey == "original_title" 
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
