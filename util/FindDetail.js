import * as fs from "fs";
import logbuffer from "console-buffer";
import _ from "lodash.get";
import * as libUtil from "./API/NetCall.js";
import * as JSRuntimeJs from "./API/JSRuntime.js";
import * as FileManagementJs from "./API/FileManagement.js";
import * as scraperLib from "../src/ScraperLib.js";
import JSONStream from "JSONStream";

const maxPackSize = process.env.MAX_PACK_ITEM;
const appendResponses = "changes,external_ids,credits";

export async function Init(input, opts, output = process.env.DEFAULT_OUTPUT_DIR) {
	var out = [];
	var inputList;

	if (opts) {
		opts = JSON.parse(opts);
	} else {
		opts = JSON.parse({});
	}

	//outputs minimum data for merging

	if (opts.mergeReady) {
		return await MergeReadyFormat(input, opts, output);
	}

	try {
		inputList = JSON.parse(input);
	} catch (e) {
		inputList = [];
		input.split("\n").forEach((item) => {
			if (item != "") inputList.push(JSON.parse(item));
		});
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
			var query = inputList[i].tmdbId || inputList[i].id;
			var getDetail;
			var getDetailId;
			var item = JSON.parse(JSON.stringify(inputList[i]));
			var itemDetail =
				opts.media == "movies"
					? new scraperLib.ContentTemplates().GetMoviesTemplate()
					: new scraperLib.ContentTemplates().GetSeriesTemplate();
			var mediaType = opts.media == "movies" ? "movie" : "tv";

			console.log("Finding |" + (i + 1) + "| of |" + listLength + "|");

			itemDetail.id = i;
			itemDetail.tmdbId = item.tmdbId || item.id;
			itemDetail.title = item.title || item.name;

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
							// itemDetail.desc = getDetail.overview;
							itemDetail.duration = getDetail.runtime;
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
											crew.job.toLowerCase().includes("writer") ||
											crew.job.toLowerCase().includes("direct")
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

						itemDetail.tmdbId = getDetail.id;
						itemDetail.country = getDetail.origin_country;
						itemDetail.releaseDate = ParseItemGeneral(getDetail.first_air_date);
						// itemDetail.desc = getDetail.overview;
						itemDetail.credits = {
							cast: getDetail.credits.cast.map((cast) => {
								return {
									name: cast.name,
									job: cast.job || cast.department || cast.known_for_department,
								};
							}),
							crew: getDetail.credits.crew
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

							for (var j = 0; j < getDetail.seasons.length; j++) {
								var seasonDetail =
									new scraperLib.ContentTemplates().GetSeasonsTemplate();
								var seasonAPI = getDetail.seasons[j];
								var noImdbId = false;
								seasonDetail.id = j;
								seasonDetail.tmdbId = seasonAPI.id;

								seasonDetail.seasonNumber = seasonAPI.season_number;
								seasonDetail.releaseDate = ParseItemGeneral(seasonAPI.air_date);
								seasonDetail.title = seasonAPI.name;
								// seasonDetail.desc = seasonAPI.overview;
								seasonDetail.episodeCount = seasonAPI.episode_count;

								itemDetail.seasons.push(seasonDetail);

								var episodeAPIList = await libUtil.APISearchQuery(
									"https://api.themoviedb.org/3/tv/" +
										itemDetail.tmdbId +
										"/season/" +
										seasonDetail.seasonNumber +
										"?api_key=" +
										api +
										"&language=en-US&page=1&include_adult=false"
								);

								// console.log("at j: " + j)
								for (var k = 0; k < getDetail.seasons[j].episode_count; k++) {
									try {
										var episodeDetail =
											new scraperLib.ContentTemplates().GetEpisodesTemplate();
										var episodeAPI = episodeAPIList.episodes[k];
										var episodeAPIListExt;

										//ignoring episode IMDB ID
										if (!noImdbId)
											episodeAPIListExt = await libUtil.APISearchQuery(
												"https://api.themoviedb.org/3/tv/" +
													itemDetail.tmdbId +
													"/season/" +
													seasonDetail.seasonNumber +
													"/episode/" +
													episodeAPI.episode_number +
													"/external_ids?api_key=" +
													api +
													"&language=en-US&page=1&include_adult=false"
											);

										episodeDetail.id = k;
										episodeDetail.imdbId = episodeAPIListExt.imdb_id
											? episodeAPIListExt.imdb_id
											: 0;
										episodeDetail.tmdbId = episodeAPI.id;
										episodeDetail.episodeNumber = episodeAPI.episode_number;
										episodeDetail.releaseDate = ParseItemGeneral(
											episodeAPI.air_date
										);
										episodeDetail.title = episodeAPI.name;
										// episodeDetail.desc = episodeAPI.overview;
										episodeDetail.duration = episodeAPI.runtime;
										seasonDetail.episodes.push(episodeDetail);

										if (k == 0) {
											if (episodeDetail.imdbId == 0) noImdbId = true;
										}
									} catch (e) {
										console.log("Error: " + e);
										console.log(
											"Happened on id: " +
												seasonDetail.id +
												" of season: " +
												j +
												" on episode: " +
												k
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
		item.releaseDate = targetValue;
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
		item = item;
	}

	return item;
}

async function MergeReadyFormat(input, opts, output) {
	let out = [];
	let counter = 0;
	let isPiping = false;
	let inputList;
	let minTemplate =
		opts.media == "movies"
			? {
					title: null,
					tmdbId: null,
					imdbId: null,
					releaseDate: null,
					credits: {
						cast: [],
						crew: [],
					}
			  }
			: {
					title: null,
					tmdbId: null,
					imdbId: null,
					episodeCount: null,
					seasonCount: null,
					releaseDate: null,
					credits: {
						cast: [],
						crew: [],
					},
					seasons: [],
			  };

	let seasonsTemplate = {
		tmdbId: null,
		title: null,
		seasonNumber: null,
		episodeCount: null,
		releaseDate: null,
		episodes: [],
	};

	let episodesTemplate = {
		imdbId: null,
		tmdbId: null,
		title: null,
		episodeNumber: null,
		releaseDate: null,
	};

	try {
		isPiping = true;
		inputList = [];
		console.log("File streaming");
		logbuffer.flush();
		input
			.pipe(JSONStream.parse("*"))
			.on("data", (chunk) => {
				let bareNecessities = chunk;

				if (++counter % 10000 == 0) {
					console.log("input counter: " + counter);
					logbuffer.flush();
				}
				inputList.push(bareNecessities);
			})
			.on("end", () => {
				isPiping = false;
			});
	} catch (e) {
		console.log(e);
		inputList = JSON.parse(input);

		logbuffer.flush();
		isPiping = false;
	}

	while (isPiping) {
		console.log("Piping");
		await scraperLib.Sleep(3000);
		logbuffer.flush();
	}

	inputList.forEach((item) => {
		let creditsTemp = [];
		item.credits.cast && item.credits.cast.forEach((member) => {
			if (member.job && member.job.toLowerCase().includes("direct")) {
				creditsTemp.push(member);
			}
		});

		item.credits.crew && item.credits.crew.forEach((member) => {
			if (member.job && member.job.toLowerCase().includes("direct")) {
				creditsTemp.push(member);
			}
		});

		item.credits = creditsTemp;

		if (opts.media == "movies") {
			item = copyMatchingProperties(Object.assign({}, minTemplate), item);
		} else if (opts.media == "series") {
			item = copyMatchingProperties(Object.assign({}, minTemplate), item);
			let tempSeasons = Object.assign([], item.seasons);
			item.seasons.length = 0;
			if (tempSeasons) {
				tempSeasons.forEach((season) => {
					let tempEps = Object.assign([], season.episodes);
					for (let i = 0; i < tempEps.length; i++) {
						season.episodes[i] = copyMatchingProperties(
							Object.assign({}, episodesTemplate),
							tempEps[i]
						);
					}

					season = copyMatchingProperties(Object.assign({}, seasonsTemplate), season);

					item.seasons.push(season);
				});
			}
		}
		out.push(item);
	});

	await scraperLib.fm.WriteToJSON(out, output);

	console.log("completed");
	logbuffer.flush();
	return out;
}

function copyMatchingProperties(targetObj, sourceObj) {
	for (const key in sourceObj) {
		if (targetObj.hasOwnProperty(key)) {
			// Check if key exists in target object
			targetObj[key] = sourceObj[key];
		}
	}

	return targetObj;
}
