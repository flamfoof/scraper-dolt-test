import logbuffer from "console-buffer";
import _ from "lodash.get";
import * as libUtil from "./API/NetCall.js";
import * as FileManagementJs from "./API/FileManagement.js";
import util from "util";
import * as fs from "fs";
import { Stream } from "stream";
import readline from "readline";
import { title } from "process";
const readFileAsync = util.promisify(fs.readFile);

const maxPackSize = process.env.iGNORE_PACK_ITEM;

export async function Init(oldJSON, newJSON, opts, output = process.env.DEFAULT_OUTPUT_DIR) {
	var inputList;
	var out = [];
	var tempOutName = [];
	var listLength;
    var name = opts.name != undefined ? opts.name : opts.media + "_changes_applied.json";
    var index = 0;

    oldJSON = JSON.parse(oldJSON);
	newJSON = JSON.parse(newJSON);
    listLength = newJSON.length;

	if (opts) {
		opts = JSON.parse(opts);
	} else {
		opts = JSON.parse({});
	}

    console.log("checking movies/series")
    //Works under the assumption that the list is sorted by imdbId
    
	if (opts.media == "movies") {
        for (var i = 0; i < inputList.length; i++) {
		}
	} else if (opts.media == "series") {
        for (var i = 0; i < listLength; i++) {
            var titleIndex = oldJSON[0].alphabetIndex[newJSON[i].title[0]] ? oldJSON[0].alphabetIndex[newJSON[i].title[0]].index : 0;
            var alphabetIndexCount = oldJSON[0].alphabetIndex[newJSON[i].title[0]] ? oldJSON[0].alphabetIndex[newJSON[i].title[0]].count : oldJSON.length;
            
            if(i % 10000 == 0) {
                console.log(i);
                logbuffer.flush();
            }

            for (var j = titleIndex; j < titleIndex + alphabetIndexCount; j++) {
                if(newJSON[i].title == oldJSON[j].title) {
                    for (var k = 0; k < oldJSON[j].seasons.length; k++) {
                        var targetSeasonIndex = null;
                        for (var l = 0; l < newJSON[i].seasons.length; l++) {
                            if(newJSON[i].seasons[l].seasonNumber == oldJSON[j].seasons[k].seasonNumber) {
                                targetSeasonIndex = l;
                                break;
                            }
                        }
                        if(targetSeasonIndex != null) { 
                            for (var m = 0; m < oldJSON[j].seasons[k].episodes.length; m++) {
                                var targetEpisodeIndex = null;
                                for (var n = 0; n < newJSON[i].seasons[targetSeasonIndex].episodes.length; n++) {
                                    if(newJSON[i].seasons[targetSeasonIndex].episodes[n].episodeNumber == oldJSON[j].seasons[k].episodes[m].episodeNumber) {
                                        targetEpisodeIndex = n;
                                        break;
                                    }
                                }

                                if(targetEpisodeIndex != null && oldJSON[j].seasons[k].episodes[m].imdbId) {
                                    newJSON[i].seasons[targetSeasonIndex].episodes[targetEpisodeIndex].imdbId = oldJSON[j].seasons[k].episodes[m].imdbId;
                                }
                            }
                        }
                    }
                }
			}

            out.push(newJSON[i]);
		}
	}

    console.log(`Out size: ${out.length} vs ${newJSON.length}`)
	console.log("Done");

	logbuffer.flush();

	await FileManagementJs.PackAllToJSON(out, output, listLength + 1, opts.media, maxPackSize);

	return out;
}
