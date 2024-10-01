import logbuffer from "console-buffer";
import * as libUtil from "./API/NetCall.js";
import * as JSRuntimeJs from "./API/JSRuntime.js";
import * as FileManagementJs from "./API/FileManagement.js";
import * as findDetail from "./FindDetail.js";

const maxPackSize = process.env.MAX_PACK_ITEM;

export async function Init(oldJSON, newJSON, opts, output = process.env.DEFAULT_OUTPUT_DIR) {
	var out = [];
	var listLength = 10;
	var previousMarker = 0;

	var api = process.env.TMDB_API;
	oldJSON = JSON.parse(oldJSON);
	newJSON = JSON.parse(newJSON);

	listLength = newJSON.length;

	if (opts) {
		opts = JSON.parse(opts);
	} else {
		opts = JSON.parse({});
	}

	if (opts.media == "movies" || opts.media == "series") {
		var mediaType = opts.media == "movies" ? "movie" : "tv";

		if (mediaType == "movie") {
			for (var i = 0; i < listLength; i++) {
				JSRuntimeJs.AddToPrintConsole(`Finding |${i + 1}| of |${listLength}|`);

				for (var j = previousMarker; j < oldJSON.length; j++) {
                    var changes = {};

					if (newJSON[i].tmdbId < oldJSON[j].tmdbId || newJSON[i].tmdbId > oldJSON[oldJSON.length - 1].tmdbId) {
						if (newJSON[i].tmdbId > oldJSON[oldJSON.length - 1].tmdbId) {
							j--;
						}

						JSRuntimeJs.AddToPrintConsole("New |" + newJSON[i].tmdbId + "| id vs |" + oldJSON[j].tmdbId + "|");

						var getDetail = await findDetail.Init(JSON.stringify([newJSON[i]]), JSON.stringify({media: opts.media}));

						changes = getDetail[0];

						if (changes && Object.keys(changes).length > 0) {
							changes.id = i;
							out.push(changes);
						}

						break;
					}

					if (newJSON[i].tmdbId == oldJSON[j].tmdbId) {
						previousMarker = j;
						console.log([newJSON[i]]);
						var getDetail = await findDetail.Init(JSON.stringify([newJSON[i]]), JSON.stringify({media: opts.media}));
                        getDetail = getDetail[0];
						var keyList;

						if (getDetail && getDetail.length != 0) {
							keyList = Object.keys(getDetail);
						} else {
							break;
						}

						var changed = false;
						JSRuntimeJs.AddToPrintConsole("|" + newJSON[i].tmdbId + "| id vs |" + oldJSON[j].tmdbId + "|");

						for (var keys in keyList) {
							if (getDetail[keyList[keys]] != oldJSON[j][keyList[keys]] && keyList[keys] != "id" && keyList[keys] != "adult") {
                                changes = getDetail;
                                changes.id = i;
								changes.tmdbId = newJSON[i].tmdbId;
								JSRuntimeJs.AddToPrintConsole("Key for: " + keyList[keys] + " - |" + getDetail[keyList[keys]] + "| vs |" + oldJSON[j][keyList[keys]] + "|");
								changes[keyList[keys]] = getDetail[keyList[keys]];
								changes["old_" + keyList[keys]] = oldJSON[j][keyList[keys]] ? oldJSON[j][keyList[keys]] : "";

								changed = true;
							}
						}

						if (changed && Object.keys(changes).length > 0) {
							out.push(changes);
						}

						break;
					}

					previousMarker = j;
				}

				JSRuntimeJs.PrintAllConsole();
			}
		} else if (mediaType == "tv") {
			for (var i = 0; i < listLength; i++) {
				var changes = {};
				changes.title = newJSON[i].title;
				changes.tmdbId = newJSON[i].tmdbId;
				for (var j = 0; j < oldJSON.length; j++) {
					if (newJSON[i].tmdbId == oldJSON[j].tmdbId) {
						var keyList = Object.keys(newJSON[i]);
						var changed = false;
						JSRuntimeJs.AddToPrintConsole("|" + newJSON[i].tmdbId + "| id vs |" + oldJSON[j].tmdbId + "|");
						for (var keys in keyList) {
							if (keyList[keys] == "seasons") {
								for (var k = 0; k < newJSON[i].seasons.length; k++) {
									var seasonKeyList = Object.keys(newJSON[i].seasons[k]);

									for (var keys in seasonKeyList) {
										if (newJSON[i].seasons[k][seasonKeyList[keys]] != oldJSON[j].seasons[k][seasonKeyList[keys]] && seasonKeyList[keys] != "id" && seasonKeyList[keys] != "episodes") {
											var seasonChanges = {};
											seasonChanges.id = newJSON[i].seasons[k].id;
											seasonChanges.tmdbId = newJSON[i].seasons[k].tmdbId;
											seasonChanges.seasonNumber = newJSON[i].seasons[k].seasonNumber;
											JSRuntimeJs.AddToPrintConsole("Season: " + newJSON[i].seasons[k].seasonNumber);
											JSRuntimeJs.AddToPrintConsole("Key for: " + seasonKeyList[keys] + " - |" + newJSON[i].seasons[k][seasonKeyList[keys]] + "| vs |" + oldJSON[j].seasons[k][seasonKeyList[keys]] + "|");
											seasonChanges[seasonKeyList[keys]] = newJSON[i].seasons[k][seasonKeyList[keys]];
											seasonChanges["old_" + seasonKeyList[keys]] = oldJSON[j].seasons[k][seasonKeyList[keys]] ? oldJSON[j].seasons[k][seasonKeyList[keys]] : "";

											if (!changes.seasons) {
												changes.tmdbId = newJSON[i].tmdbId;
												changes.title = newJSON[i].title;
												changes.seasons = [];
												changes.seasons.push(seasonChanges);
											}

											changed = true;
										}
									}

									for (var l = 0; l < newJSON[i].seasons[k].episodes.length; l++) {
										var episodeKeyList = Object.keys(newJSON[i].seasons[k].episodes[l]);

										for (var keys in episodeKeyList) {
											if (newJSON[i].seasons[k].episodes[l][episodeKeyList[keys]] != oldJSON[j].seasons[k].episodes[l][episodeKeyList[keys]] && episodeKeyList[keys] != "id" && episodeKeyList[keys] != "imdbId") {
												var episodeChanges = {};
												var seasonIndexTarget = 0;
												episodeChanges.id = newJSON[i].seasons[k].episodes[l].id;
												episodeChanges.tmdbId = newJSON[i].seasons[k].episodes[l].tmdbId;
												episodeChanges.episodeNumber = newJSON[i].seasons[k].episodes[l].episodeNumber;
												JSRuntimeJs.AddToPrintConsole("Episode: " + newJSON[i].seasons[k].episodes[l].episodeNumber);
												JSRuntimeJs.AddToPrintConsole("Key for: " + episodeKeyList[keys] + " - |" + newJSON[i].seasons[k].episodes[l][episodeKeyList[keys]] + "| vs |" + oldJSON[j].seasons[k].episodes[l][episodeKeyList[keys]] + "|");
												episodeChanges[episodeKeyList[keys]] = newJSON[i].seasons[k].episodes[l][episodeKeyList[keys]];
												episodeChanges["old_" + episodeKeyList[keys]] = oldJSON[j].seasons[k].episodes[l][episodeKeyList[keys]] ? oldJSON[j].seasons[k].episodes[l][episodeKeyList[keys]] : "";

												if (!changes.seasons) {
													changes.seasons = [];
													changes.seasons[seasonIndexTarget] = {};
												}

												for (var m = 0; m < changes.seasons.length; m++) {
													if (changes.seasons.seasonNumber == newJSON[i].seasons[k].seasonNumber) {
														seasonIndexTarget = m;
														break;
													}
												}

												if (!changes.seasons[seasonIndexTarget].episodes) {
													changes.seasons[seasonIndexTarget].episodes = [];
												}

												JSRuntimeJs.AddToPrintConsole("push episode");
												changes.seasons[seasonIndexTarget].episodes.push(episodeChanges);

												changed = true;
											}
										}
									}
								}

								continue;
							}

							if (newJSON[i][keyList[keys]] != oldJSON[j][keyList[keys]] && keyList[keys] != "id" && keyList[keys] != "adult" && keyList[keys] != "country") {
								changes.id = newJSON[i].id;
								changes.tmdbId = newJSON[i].tmdbId;
								JSRuntimeJs.AddToPrintConsole("Key for: " + keyList[keys] + "- |" + newJSON[i][keyList[keys]] + "| vs |" + oldJSON[i][keyList[keys]] + "|");
								changes[keyList[keys]] = newJSON[i][keyList[keys]];
								changes["old_" + keyList[keys]] = oldJSON[j][keyList[keys]] ? oldJSON[j][keyList[keys]] : "";

								changed = true;
							}
						}

						// libUtil.AddToPrintConsole(keyList)
						if (changed) out.push(changes);

						break;
					}
				}
				JSRuntimeJs.PrintAllConsole();
			}
		}
	} else {
		console.log('Did not set the media type to movies or series. \nSample: node main.js -i [file] --findLatest "{\\"media\\": \\"series\\"}" -o process.env.DEFAULT_OUTPUT_DIR');
	}

	console.log("Done");

	logbuffer.flush();

    for(var i = 0; i < out.length; i++)
    {
        out[i].id = i;
    }

	await FileManagementJs.WriteToJSON(out, output);

	return out; 
}