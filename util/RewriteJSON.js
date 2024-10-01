import * as fs from "fs";
import logbuffer from "console-buffer";
import _ from "lodash";
import * as FileManagementJs from "./API/FileManagement.js";
import JSONStream from "JSONStream";
import * as scraperLib from "../src/ScraperLib.js";

/* Usage Example
// This wil
node main.js -i "./sample/series_out_02_23_24.json" -m series --RewriteJSON '{\"desc\":\"\",\"credits\":{}}' -o "./temp2/rewrite/series/" 
*/

export async function Init(input, opts, output = process.env.DEFAULT_OUTPUT_DIR) {
	var out = [];
	var inputList;
    let isPiping = false
    let listLength = 0;
	try {
		inputList = JSON.parse(input);
	} catch (e) {
        if (input instanceof fs.ReadStream) {
			inputList = [];
			isPiping = true;
            console.log("Data is too large and needs to be piped");
            logbuffer.flush();

			input
				.pipe(JSONStream.parse("*"))
				.on("data", (chunk) => {
					inputList.push(chunk);
				})
				.on("end", () => {
					listLength = inputList.length;
					isPiping = false;
                    console.log("Done piping");
                    logbuffer.flush();
				});
		} else {
            inputList = [];
            input.split("\n").forEach((item) => {
                if (item != "") inputList.push(JSON.parse(item));
            });
        }
		
	}

    while(isPiping)
    {
        await scraperLib.Sleep(1000);
    }
    
	if (opts) {
		opts = JSON.parse(opts);
	} else {
		opts = JSON.parse({});
	}


    // Function to modify description properties
    function modifyDescriptions(obj, optKeys) {
        return _.transform(obj, (result, value, key) => {
        if (_.isObject(value)) {
            result[key] = modifyDescriptions(value, optKeys); // Recursively modify nested objects
        } else if (optKeys.includes(key)) {
            result[key] = opts[key];
        } else {
            result[key] = value; // Keep other properties unchanged
        }
        });
    }
    
    // Apply the modification function to the original data
    const modifiedData = modifyDescriptions(inputList, Object.keys(opts));

    
    // for(let i = 0; i < listLength; i++) {
    //     Object.keys(opts).forEach((key) => {
    //         inputList[i][key] = opts[key];
    //     })
    //     out.push(inputList[i]);
    // }

	console.log("Done");

	logbuffer.flush();

	await FileManagementJs.WriteToJSON(modifiedData, output);

	return out;
}