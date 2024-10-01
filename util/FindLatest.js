import logbuffer from "console-buffer";
import _ from "lodash.get";
import * as libUtil from "./API/NetCall.js";
import * as FileManagementJs from "./API/FileManagement.js";
import * as scraperLib from "../src/ScraperLib.js";

export async function Init(input, opts, output = process.env.DEFAULT_OUTPUT_DIR) {
	var out = [];
	var changeList;
	let currentTotalPages = 3;
	await scraperLib.Sleep(1);
	var api = process.env.TMDB_API;

	if (opts) {
		opts = JSON.parse(opts);
	} else {
		opts = JSON.parse({});
	}

	if (opts.media == "movies" || opts.media == "series") {
		var mediaType = opts.media == "movies" ? "movie" : "tv";
		let limit = process.env.TMDB_NEW_SEARCH * 1 + 1;
		//pages starts at 1
		for (let i = 1; i < limit; i++) {
			changeList = await libUtil.APISearchQuery(
				`https://api.themoviedb.org/3/${mediaType}/changes?api_key=${api}&page=${i}`
			);
			if (limit > changeList.total_pages+1) limit = changeList.total_pages+1;

			if (!changeList) {
				throw "Unable to retreive fetch data";
			}

			for (var j = 0; j < changeList.results.length; j++) {
				if(!changeList.results[j].adult)
					out.push({ tmdbId: changeList.results[j].id });
			}
		}

		out.sort(function (a, b) {
			return a.tmdbId - b.tmdbId;
		});

		out = out.filter((item) => !item.adult);
	}

	logbuffer.flush();

	await FileManagementJs.WriteToJSON(out, output);
	return out;
}
