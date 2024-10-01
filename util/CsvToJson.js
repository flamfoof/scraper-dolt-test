import logbuffer from "console-buffer";
import _ from "lodash.get";
import * as libUtil from "./API/NetCall.js";
import * as FileManagementJs from "./API/FileManagement.js";
import util from "util";
import * as fs from "fs";
import { Stream } from "stream";
import readline from "readline";
const readFileAsync = util.promisify(fs.readFile);

const maxPackSize = process.env.IGNORE_PACK_ITEM;

export async function Init(input, opts, output = process.env.DEFAULT_OUTPUT_DIR, print = true) {
	var inputList;
	var out = [];
	var tempOutName = [];
	var listLength;
    var allowClones = true;
	// listLength = 10;

    try {
        inputList = JSON.parse(input);
        listLength = inputList.length;
    } catch(e)
    {
        inputList = input;
    }

	if (opts) {
		opts = JSON.parse(opts);
	} else {
		opts = JSON.parse({});
	}
    
    if(input instanceof Stream)
    {
        var streamOut = [];
        var rl = readline.createInterface({input: input});

        console.log("File is too large, so going to stream it");

        rl.on('line', (line) => {
            streamOut.push(line);
        })

        rl.on('close', () => {
            console.log("Done checking stream");

            for(var i = 0; i < streamOut.length; i++)
            {
                streamOut[i] = streamOut[i].replaceAll(",,", ",\"\",");
                streamOut[i] = streamOut[i].split("\",\"");
            }
            

            if (print) 
                FileManagementJs.PackAllToJSON(out, output, listLength + 1, opts.media, maxPackSize);
        })

        inputList = streamOut;
    } else {
        inputList = input.split("\n");
        inputList.shift();
        for(var i = 0; i < inputList.length; i++)
        {
            inputList[i] = inputList[i].replace("\"", "");
            inputList[i] = inputList[i].split("\",\"");
        }
    }

    console.log("checking movies/series")
    //Works under the assumption that the list is sorted by imdbId
    
	if (opts.media == "movies") {
        for (var i = 0; i < inputList.length; i++) {
            var movieTemplate = {
                title: "",
                imdbId: 0,
                releaseDate: ""
            };

            if(!inputList[i][0])
                continue;

            movieTemplate.title = inputList[i][0]
            movieTemplate.imdbId = inputList[i][1]
            movieTemplate.releaseDate =  inputList[i][2].slice(0, 4).replace("\"", "");

            if(movieTemplate.imdbId)
                out.push(movieTemplate);
		}
	} else if (opts.media == "series") {
        var prevImdb = 0;
        var prevTitle = "";
        var currIndex = 0;
        var currSeason = -1;
        var seasonIndex = -1;
        var previousChar = '';
        var sameShowCount = 0;

        //Alphabet index is to help optimize search
        out.push({alphabetIndex: {}});
        
        for (var i = 1; i < inputList.length; i++) {
            var showTemplate = {
                title: "",
                imdbId: 0,
                releaseDate: "",
                seasons: []
            };

            var seasonTemplate = {
                seasonNumber: 0,
                episodes: []
            }

            var epTemplate = {
                episodeNumber: 0,
                imdbId: 0
            };

            if(!inputList[i][0])
                continue;

            if(inputList[i][0][0] != previousChar) {
                previousChar = inputList[i][0][0];
                out[0].alphabetIndex[previousChar] = {
                    index: currIndex + 1,
                    count: 0
                }
            }

            showTemplate.title = inputList[i][0]
            showTemplate.imdbId = inputList[i][1]
            epTemplate.imdbId = inputList[i][5].replace("\"", "");
            showTemplate.releaseDate =  inputList[i][2].slice(0, 4).replace("\"", "");
            seasonTemplate.seasonNumber = Math.floor(inputList[i][3])
            epTemplate.episodeNumber = Math.floor(inputList[i][4])
            sameShowCount++;

            if(!epTemplate.imdbId || !showTemplate.imdbId)
                continue;

            //this comparison doesn't work because our data has multiple entries with different IMDB but the same show title...
            // if(prevImdb != showTemplate.showImdbId)
            if(prevTitle != showTemplate.title)
            {
                out.push(showTemplate);
                currIndex++;
                currSeason = -1;
                seasonIndex = -1;
                prevImdb = showTemplate.imdbId;
                prevTitle = showTemplate.title;
                out[0].alphabetIndex[previousChar].count++;
                sameShowCount = 1;
            }

            // Avoiding duplicate shows with multiple imdbIds
            if(prevTitle == showTemplate.title && prevImdb != showTemplate.imdbId && !allowClones) {
                while(sameShowCount > 0 && prevImdb != 0) {
                    out.pop();
                    sameShowCount--;
                    out[0].alphabetIndex[previousChar].count--;
                    currIndex--;
                }
                
                prevImdb = 0;
                continue;
            }

            if(currSeason != seasonTemplate.seasonNumber)
            {
                out[currIndex].seasons.push(seasonTemplate);
                currSeason = seasonTemplate.seasonNumber;
                seasonIndex++;
            }

            out[currIndex].seasons[seasonIndex].episodes.push(epTemplate);
        }
	}

	console.log("Done");

	logbuffer.flush();

	if (print) await FileManagementJs.PackAllToJSON(out, output, listLength + 1, opts.media, maxPackSize);

	return out;
}
