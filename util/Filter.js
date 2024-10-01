import _ from "lodash.get";

export function Init(input, opts, boolSelection) {
	if (boolSelection == "count") {
		console.log("Total items: " + input.length);
		process.exit(1);
	}

	//default option for boolSelection
	if (typeof boolSelection != "boolean") {
		boolSelection = true;
	}

	console.log("deets: " + JSON.stringify(details));
	var out = [];
	try {
		opts = JSON.parse(opts);
		console.log("Filter options: " + JSON.stringify(opts));
		for (var i = 0; i < input.length; ++i) {
			var filterCheck = 0;
			var keyList = Object.keys(opts);
			for (var key of keyList) {
				if (input[i].hasOwnProperty(key)) {
					if (boolSelection) {
						if (opts[key] == input[i][key]) {
							filterCheck++;
						}
					} else {
						if (opts[key] != input[i][key]) {
							filterCheck++;
						}
					}
				}
			}

			if (filterCheck == keyList.length) {
				out.push(input[i]);
			}
		}
		console.log("Done");
	} catch (e) {
		console.log(e);
		console.log('Invalid input.\nSample: node main.js -i [File] -filter "{\\"date\\": \\"1980\\"}" -o "./temp"');
		process.exit(1);
	}

	return out;
}
