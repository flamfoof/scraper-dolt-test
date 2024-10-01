import logbuffer from "console-buffer";
import _ from "lodash.get";
import * as libUtil from "./API/NetCall.js";
import * as FileManagementJs from "./API/FileManagement.js";
import util from "util";
import * as fs from "fs";
import { Stream } from "stream";
import readline from "readline";
const readFileAsync = util.promisify(fs.readFile);

const maxPackSize = process.env.iGNORE_PACK_ITEM;

export async function Init(input, opts, output = process.env.DEFAULT_OUTPUT_DIR, print = true) {
	var inputList;
    var numShowImdbReplaced = 0;
    var numEpImdbReplaced = 0;
	var out = [];
	var tempOutName = [];
	var listLength;
    var uniqueShows = [];
    var tempList = [];
    var alphabetIndex = {};
    var uniqueAlphabetIndex = {};
	// listLength = 10;

    try {
        inputList = JSON.parse(input);
        listLength = inputList.length;
    } catch(e)
    {
        inputList = input;
    }

	if (opts) {
        try {
            opts = JSON.parse(opts);
        } catch (e)
        {
            console.log(e)
        }
	} else {
		opts = JSON.parse({});
	}
    
    //import as csv
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
        var prevId = "";
        var prevFirstLetter = "";
        var prevShowFirstLetter = "";
        
        console.log("Consuming the dang file");
        inputList = input.split("\n");

        for(var i = 0; i < inputList.length; i++)
        {
            inputList[i] = inputList[i].replace("\"", "");
            inputList[i] = inputList[i].split("\",\"");
            if(inputList[i][1] != "")
            {
                tempList.push(inputList[i]);
            }
        }
        
        inputList = tempList;

        for(var j = 1; j < inputList.length; j++)
        {
            if(prevId != inputList[j][1])
            {
                inputList[j].index = j;

                if(opts.media == "series")
                    uniqueShows.push(inputList[j]);
                    
                prevId = inputList[j][1];
                if(prevFirstLetter != inputList[j][0].charAt(0))
                {
                    prevFirstLetter = inputList[j][0].charAt(0);
                    alphabetIndex[prevFirstLetter] = j;
                }
            }
        }

        if(opts.media == "series")
        {
            for(var j = 0; j < uniqueShows.length; j++)
            {
                if(prevShowFirstLetter != uniqueShows[j][0].charAt(0))
                {
                    prevShowFirstLetter = uniqueShows[j][0].charAt(0);
                    uniqueAlphabetIndex[prevShowFirstLetter] = j;
                }
            }
        }
    }

    console.log("checking movies/series")
    
    //Works under the assumption that the list is sorted by imdbId
	if (opts.media == "movies") {
        for (var j = 0; j < inputList.length; j++) {
            var firstChar = rokuFile[i].title.charAt(0);
            var indexSearch = inputList.length;
            var uniqueIndexSearch = uniqueAlphabetIndex[firstChar]
            var found = false;
            var csvTemplate = {
                title: "",
                movieImdb: "",
                releaseDate: ""
            }

            // console.time("search")
            for(var j = uniqueIndexSearch; j < uniqueShows.length; j++)
            {
                // console.log(`${rokuFile[i].title} vs ${uniqueShows[j][0]}`)
                // console.log(rokuFile[i].title.charAt(1) < uniqueShows[j][0].charAt(1))
                try {
                    if(uniqueShows[j][0] == rokuFile[i].title && uniqueShows[j][2].substring(0,4) == rokuFile[i].releaseDate)
                    {
                        indexSearch = uniqueShows[j].index;
                        break;
                    }

                    if(rokuFile[i].title.charAt(1) !== "" && rokuFile[i].title.charAt(1) < uniqueShows[j][0].charAt(1))
                    {
                        break;
                    }
                } catch (e)
                {
                    console.log("Error happened at index: " + j)
                    console.log(uniqueShows[j]);
                    console.log(e)
                }
                
            }
        }
	} else if (opts.media === "series") {
        var rokuFile  = await readFileAsync(opts.input);
        rokuFile = JSON.parse(rokuFile)
        
        for(var i = 0; i < rokuFile.length; i++)
        {
            var firstChar = rokuFile[i].title.charAt(0);
            var indexSearch = inputList.length;
            var uniqueIndexSearch = uniqueAlphabetIndex[firstChar]
            var found = false;
            var foundExit = false;
            var csvTemplate = {
                title: "",
                showImdb: 0,
                epImdb: 0,
                releaseDate: "",
                season: 0,
                episode: 0
            }

            // console.time("search")
            for(var j = uniqueIndexSearch; j < uniqueShows.length; j++)
            {
                // console.log(`${rokuFile[i].title} vs ${uniqueShows[j][0]}`)
                // console.log(rokuFile[i].title.charAt(1) < uniqueShows[j][0].charAt(1))
                try {
                    if(uniqueShows[j][0] == rokuFile[i].title && uniqueShows[j][2].substring(0,4) == rokuFile[i].releaseDate)
                    {
                        indexSearch = uniqueShows[j].index;
                        break;
                    }

                    if(rokuFile[i].title.charAt(1) !== "" && rokuFile[i].title.charAt(1) < uniqueShows[j][0].charAt(1))
                    {
                        break;
                    }
                } catch (e)
                {
                    console.log("Error happened at index: " + j)
                    console.log(uniqueShows[j]);
                    console.log(e)
                }
                
            }
            // console.timeEnd("search")
            // console.time("Roku")
            for(var j = indexSearch; j < inputList.length; j++)
            {
                // console.log(rokuFile[i].title + " vs " + inputList[j])
                if(rokuFile[i].title == inputList[j][0] && (rokuFile[i].releaseDate === inputList[j][2].substring(0,4) || found))
                {
                    found = true;
                    
                    if(rokuFile[i].imdbId == "" || rokuFile[i].imdbId == undefined || rokuFile[i].imdbId == null || rokuFile[i].imdbId == 0)
                    {
                        rokuFile[i].imdbId = inputList[j][1];
                        numShowImdbReplaced++;
                    }


                    csvTemplate.title = inputList[j][0]
                    csvTemplate.showImdb = inputList[j][1].replace("\"", "")
                    csvTemplate.releaseDate = inputList[j][2]
                    csvTemplate.season = Math.floor(inputList[j][3])
                    csvTemplate.episode = Math.floor(inputList[j][4])
                    csvTemplate.epImdb = inputList[j][5].replace("\"", "")
                    var currSeasonIndex = null;
                    
                    for(var k = 0; k < rokuFile[i].seasons.length; k++)
                    {
                        if(rokuFile[i].seasons[k].seasonNumber == csvTemplate.season)
                        {
                            currSeasonIndex = k;
                            break;
                        }
                    }

                    // rokuFile[i].desc = ""
                    if(currSeasonIndex)
                    {
                        for(var k = 0; k < rokuFile[i].seasons[currSeasonIndex].episodes.length; k++)
                        {
                            // rokuFile[i].seasons[currSeasonIndex].episodes[k].desc = "";
                            if(rokuFile[i].seasons[currSeasonIndex].episodes[k].episodeNumber == csvTemplate.episode)
                            {
                                if(rokuFile[i].seasons[currSeasonIndex].episodes[k].imdbId == "" || rokuFile[i].seasons[currSeasonIndex].episodes[k].imdbId == 0)
                                {
                                    rokuFile[i].seasons[currSeasonIndex].episodes[k].imdbId = csvTemplate.epImdb;
                                    numEpImdbReplaced++;
                                    // console.log(`Replaced ${rokuFile[i].title} ${csvTemplate.episode} with ${csvTemplate.epImdb}`)
                                }
                                break;
                            }
                        }
                    }
                } else if(found && !foundExit)
                {
                    foundExit = true;
                }
                
                //end loop
                if(inputList[j][0].charAt(0) !== firstChar || (found && foundExit)) 
                {
                    j = inputList.length;
                    break;
                }
            }
            // console.timeEnd("Roku")
            if(i % 10000 == 0)
                console.log(i + " of " + rokuFile.length + " done")
            
            logbuffer.flush();
            // console.log(rokuFile[i].title)
            // process.exit(1)
        }
        console.log(`Replaced ${numShowImdbReplaced} show imdb ids and ${numEpImdbReplaced} episode imdb ids`);

        out = rokuFile;
	}

	console.log("Done");

	logbuffer.flush();

	if (print) await FileManagementJs.PackAllToJSON(out, output, listLength + 1, opts.media, maxPackSize);

	return out;
}
