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
	var out = [];
	var tempOutName = [];
	var listLength;
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

    // For Reelgood
    if (opts.csv == true)
    {
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
                
                out = ExtractXML(streamOut, 4);

                if (print) 
                    FileManagementJs.PackAllToJSON(out, output, listLength + 1, opts.media, maxPackSize);
            })

            inputList = streamOut;
        } else {
            inputList = input.split("\n");

            for(var i = 0; i < inputList.length; i++)
            {
                inputList[i] = inputList[i].replaceAll(",,", "");
                inputList[i] = inputList[i].split("\",\"");
            }
            out = ExtractXML(inputList, 2);
        }

        
    }

	if (opts.media == "movies") {
		for (var i = 0; i < listLength; i++) {
			for (var j = 0; j < inputList[i].providers.length; j++) {
				var template = {
					name: "",
					ref: "",
                    count: 1
				};
				template.name = inputList[i].providers[j].providerName;
				template.ref = inputList[i].providers[j]?.referenceTag;
				template.link = inputList[i].providers[j]?.link;

                if(tempOutName.includes(template.name))
                {
                    out[tempOutName.indexOf(template.name)].count++;
                }

				if (!tempOutName.includes(template.name)) {
					tempOutName.push(template.name);
					out.push(template);
				}
			}
		}
	} else if (opts.media == "series") {
        for (var i = 0; i < listLength; i++) {
			for (var j = 0; j < inputList[i].providers.length; j++) {
				var template = {
					name: "",
					ref: "",
                    count: 1
				};
				template.name = inputList[i].providers[j].providerName;
				template.ref = inputList[i].providers[j]?.referenceTag;
				template.link = inputList[i].providers[j]?.link;

                if(tempOutName.includes(template.name))
                {
                    out[tempOutName.indexOf(template.name)].count++;
                }

				if (!tempOutName.includes(template.name)) {
					tempOutName.push(template.name);
					out.push(template);
				}
			}
		}
	}

	console.log("Done");

	logbuffer.flush();

	if (print) await FileManagementJs.PackAllToJSON(out, output, listLength + 1, opts.media, maxPackSize);

	return out;
}

function ExtractXML(input, targetColumn)
{
    var tempOutName = [];
    var out = [];

    for(var i = 1; i < input.length; i++)
    {
        if(!input[i][targetColumn])
        {
            continue;
        }
        var provider = input[i][targetColumn].replaceAll("\"", "");
        var template = {
            name: provider,
            count: 1
        };

        // This is to remove all duplicates of a source of different variations. 
        // i.e. amazon-buy and amazon_subscription
        // provider = provider.replace(/(-|_)[a-zA-Z]+/gm, "");

        if(tempOutName.includes(template.name))
        {
            out[tempOutName.indexOf(template.name)].count++;
        }

        if (!tempOutName.includes(template.name)) {
            tempOutName.push(template.name);
            out.push(template);
        }
    }

    out.sort(function(a, b) {
        return a.name < b.name ? -1 : a.name > b.name ? 1 : 0;
    })

    return out;
}