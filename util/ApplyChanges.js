import logbuffer from "console-buffer";
import * as libUtil from "./API/NetCall.js";
import * as FileManagementJs from "./API/FileManagement.js";

const maxPackSize = process.env.MAX_PACK_ITEM;

export async function Init(oldJSON, newJSON, opts, output = process.env.DEFAULT_OUTPUT_DIR) {
	var out = [];
	var listLength = 10;

	oldJSON = JSON.parse(oldJSON);
	newJSON = JSON.parse(newJSON);

	listLength = newJSON.length;

	if (opts) {
		opts = JSON.parse(opts);
	} else {
		opts = JSON.parse({});
	}

	//temporary sort checker
	oldJSON = oldJSON.sort(function (x, y) {
		return x.tmdbId - y.tmdbId;
	});
    

	if (opts.media == "movies" || opts.media == "series") {
		var mediaType = opts.media == "movies" ? "movie" : "tv";

		var name = opts.name != undefined ? opts.name : opts.media + "_changes_applied.json";
		var index = 0;

		for (var i = 0; i < listLength; i++) {
			for (var j = index; j < oldJSON.length; j++) {
				if (oldJSON[j].tmdbId == newJSON[i].tmdbId) {
                    if(j != oldJSON.length - 1)
                    {
					    index = j + 1;
                    }
					var keys = Object.keys(newJSON[i]);
                    
                    //cleaning up
					for (var k = 0; k < keys.length; k++) {
						if (keys[k].includes("old_")) {
							delete newJSON[i][keys[k]]
						}
					}
                    
                    out.push(newJSON[i]);

					break;
				}

				if (newJSON[i].tmdbId < oldJSON[j].tmdbId || newJSON[i].tmdbId > oldJSON[oldJSON.length - 1].tmdbId) {
					if (newJSON[i].tmdbId > oldJSON[oldJSON.length - 1].tmdbId) {
                        // index = oldJSON.length - 1;
					}

                    out.push(newJSON[i]);

					break;
                }
                
                out.push(oldJSON[j]);
			}
		}

		logbuffer.flush();

		for (var i = 0; i < out.length; i++) {
			out[i].id = i;
		}

		await FileManagementJs.WriteToJSON(out, output, name);
	} else {
		console.log('Did not set the media type to movies or series. \nSample: node main.js -i [file] --findLatest "{\\"media\\": \\"series\\"}" -o process.env.DEFAULT_OUTPUT_DIR');
	}

	console.log("Done");

	return out;
}
