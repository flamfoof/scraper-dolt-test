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

//sample commands
//node main.js -i "./sample/movies_out_03_05_24.json" -trim '{\"media\":\"movies\"}' -o "./aout/trim/movies/"
//node main.js -i "./sample/series_out_03_05_24.json" -trim '{\"media\":\"series\"}' -o "./aout/trim/series/"

export async function Init(input, opts, output = process.env.DEFAULT_OUTPUT_DIR) {
	var out = [];
	var inputList = [];
	let isPiping = false;
    let counter = 0;
    input = fs.createReadStream(process.env.INPUT_DIR);

	if (opts) {
		opts = JSON.parse(opts);
	} else {
		opts = JSON.parse({});
	}

	if (input instanceof fs.ReadStream) {
		isPiping = true;
		input
			.pipe(JSONStream.parse("*"))
			.on("data", (chunk) => {
				let bareNecessities = {};
				bareNecessities.imdbId = chunk.imdbId
				bareNecessities.tmdbId = chunk.tmdbId;
				bareNecessities.title = chunk.title;
				bareNecessities.releaseDate = chunk.releaseDate;
				bareNecessities.duration = chunk.duration;

				bareNecessities.credits = {
					cast: [],
					crew: [],
				};

				chunk.credits?.cast && chunk.credits.cast.forEach((cast) => {
					if (cast?.job && cast.job.toLowerCase().includes("direct")) {
						bareNecessities.credits.cast.push(cast);
					}
				});

				chunk.credits?.crew && chunk.credits.crew.forEach((crew) => {
					if (crew?.job && crew.job.toLowerCase().includes("direct")) {
						bareNecessities.credits.crew.push(crew);
					}
				});

                

				if (opts.media == "series") {
					bareNecessities.seasons = []
                    chunk.seasons.forEach(season => {
                        let bareSeason = {}
                        bareSeason.id = season.id
                        bareSeason.tmdbId = season.tmdbId
                        bareSeason.title = season.title
                        bareSeason.seasonNumber = season.seasonNumber
                        bareSeason.episodeCount = season.episodeCount
                        bareSeason.releaseDate = season.releaseDate
						bareSeason.episodes = []

                        season.episodes.forEach(episode => {
							let bareEpisode = {}
                            bareEpisode.tmdbId = episode.tmdbId
                            bareEpisode.title = episode.title
                            bareEpisode.episodeNumber = episode.episodeNumber
                            bareEpisode.releaseDate = episode.releaseDate
							bareSeason.episodes.push(bareEpisode)
                        })
                        
                        bareNecessities.seasons.push(bareSeason)
                    })
				}

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

	while (isPiping) {
		await scraperLib.Sleep(500);
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

	if (opts.media == "movies" || opts.media == "series") {
		out = inputList;
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

	await FileManagementJs.WriteToJSON(out, output);

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
