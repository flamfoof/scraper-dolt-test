import * as fs from "fs";
import logbuffer from "console-buffer";
import _ from "lodash.get";
import { url } from "inspector";
import * as JSRuntimeJs from "./API/JSRuntime.js";
import * as FileManagementJs from "./API/FileManagement.js";
import * as scraperLib from "../src/ScraperLib.js";
import { XMLParser } from "fast-xml-parser";
import find from "lodash.find";
import JSONStream from "JSONStream";

const maxPackSize = process.env.MAX_PACK_ITEM;
const fileAssetPackName = process.env.PACK_NAME;

let readStateValue = {
	NotStarted: "not_started",
	Reading: "reading",
	Finished: "finished",
	Completed: "completed",
};
let filterList = [];

export async function Init(opts, input, output = "./temp/") {
	//Input is most likely a very large file - >2 GB.
	// if (!opts) {
	// 	opts = JSON.parse(opts);
	// } else {
	// 	opts = JSON.parse({});
	// }

	if (opts.function == "count") {
		await GracenoteCount(input, opts, output);
		return [];
	} else if (opts.function == "ingestion") {
		await GracenoteIngestion(input, opts, output);
		return [];
	} else if (opts.function == "merge") {
		await GracenoteMergeTMDB(input, opts.tmdbInput, opts, output);
		return [];
	}

	let out = [];
	let mediaFilePath = output + "/pack/";
	let currentPackSize = 0;
	let counter = 0;
	let lineStore = "";
	let lineCount = 0;
	let readState = readStateValue.NotStarted;
	let captureTags = {
		start: opts.media == "movies" ? "<movie>" : "<series>",
		end: opts.media == "movies" ? "</movie>" : "</series>",
		closing: opts.media == "movies" ? "</onlineMovies>" : "</onlineTv>",
	};
	let videoQuality = {
		SD: "SD",
		HD: "HD",
		UHD: "UHD",
	};
	let licenseValues = {
		rental: "rental",
		free: "free",
		purchase: "purchase",
		subscription: "subscription",
		authentication: "authentication",
	};
	let platformValues = {
		android: "A", // Android
		fire_tv: "F", // Fire TV
		ios: "I", // iOS
		lg: "L", // LG/webOS
		android_tv: "N", // Android TV
		samsung: "S", // Samsung/Tizen
		tvos: "T", // tvOS
		web: "W", // Web
	};

	// let readStream = fs.createReadStream(input, "utf8");

	// let xmlStreamRead = new XmlStream(readStream);

	if (fs.existsSync(mediaFilePath)) {
		currentPackSize = fs.readdirSync(mediaFilePath).length;
		console.log("pack size: " + currentPackSize);
		logbuffer.flush();
	}

	// This will wait until we know the readable stream is actually valid before piping
	console.log("General Kenobi...");

	await readFileLineByLine(
		process.env.INPUT_DIR,
		(line) => {
			if (++lineCount % 1000000 == 0) {
				console.log(`Total lines read: ${lineCount}`);
			}

			if (line.includes(captureTags.start)) {
				if (++counter % (maxPackSize * 10) == 0) {
					console.log(`Current Index: ${counter}`);
				}
			}
			logbuffer.flush();

			switch (line.trim()) {
				case captureTags.start:
					readState = readStateValue.Reading;
					break;
				case captureTags.end:
					readState = readStateValue.Finished;
					break;
				case captureTags.closing:
					readState = readStateValue.Completed;
					break;
			}

			switch (readState) {
				case readStateValue.Reading:
					lineStore += line + "\n";
					break;
				case readStateValue.Finished:
					lineStore += line + "\n";
					let outDataObj = handleXmlObject(lineStore);
					let outData = outDataObj.movie ? outDataObj.movie : outDataObj.series;
					let gnData =
						opts.media == "movies"
							? new scraperLib.ContentTemplates().GetMoviesTemplate()
							: new scraperLib.ContentTemplates().GetSeriesTemplate();
					let propDelete = [
						"rental_cost_sd",
						"rental_cost_hd",
						"purchase_cost_sd",
						"purchase_cost_hd",
						"contentId",
					];
					propDelete.forEach((prop) => {
						delete gnData[prop];
					});
					gnData.id = counter - 1;
					if (opts.media == "movies") {
						gnData.tmsId = outData.tmsId;
						gnData.title = outData.title.toString();
						gnData.rootId = outData.rootId;
						gnData.releaseDate = outData.year;
						gnData.desc = outData.description;
						gnData.tags = outData.genre;
						gnData.duration = Math.ceil(outData.runtime / 60);

						//deeplinks
						if (outData.videos) {
							if (!Array.isArray(outData.videos.video)) {
								let tempView = outData.videos.video;
								outData.videos.video = [];
								outData.videos.video.push(tempView);
							}
							outData.videos.video.forEach((video) => {
								gnData.providerDetail.push(GetViewingOptions(video));
							});
						}
					} else if (opts.media == "series") {
						gnData.tmsId = outData.tmsId;
						gnData.title = outData.title.toString();
						gnData.rootId = outData.rootId;
						gnData.releaseDate = outData.airDate;
						gnData.desc = outData.description;
						gnData.tags = outData.genre;

						let seasonData = {
							seasons: [],
						};

						if (
							outData?.episodes?.episode &&
							!Array.isArray(outData.episodes.episode)
						) {
							let tempView = outData.episodes.episode;
							outData.episodes.episode = [];
							outData.episodes.episode.push(tempView);
						}

						outData?.episodes?.episode &&
							outData.episodes.episode.forEach((episode) => {
								let seasonIndex = -1;
								let seasonMatch = find(seasonData.seasons, {
									seasonNumber: episode.seasonNumber,
								});
								if (!seasonMatch) {
									seasonData.seasons.push({
										seasonNumber: episode.seasonNumber,
										episodeCount: 1,
										releaseDate: null,
										episodes: [],
									});
									gnData.seasonCount++;
									seasonData.seasons.seasonCount++;
									seasonIndex = 0;
								} else {
									seasonIndex = seasonData.seasons.indexOf(seasonMatch);
								}

								let episodeData =
									new scraperLib.ContentTemplates().GetEpisodesTemplate();
								if (!seasonData.seasons[seasonIndex]?.releaseDate)
									seasonData.seasons[seasonIndex].releaseDate = episode.airDate;

								episodeData.rootId = episode.rootId;
								episodeData.tmsId = episode.tmsId;
								try {
									episodeData.title = episode.title.toString();
								} catch (e) {
									console.log(episodeData);
									console.log(
										"This episode doesn't have at title... don't worry about it"
									);
									return;
								}
								episodeData.releaseDate = episode.airDate;
								episodeData.episodeNumber = episode.episodeNumber;
								episodeData.desc = episode.description;
								episodeData.providerDetail = [];
								delete episodeData["contentId"];

								//deeplinks
								if (!Array.isArray(episode.videos.video)) {
									let tempView = episode.videos.video;
									episode.videos.video = [];
									episode.videos.video.push(tempView);
								}
								episode?.videos?.video &&
									episode.videos.video.forEach((video) => {
										episodeData.providerDetail.push(GetViewingOptions(video));
									});

								seasonData.seasons[seasonIndex].episodeCount++;
								gnData.episodeCount++;

								seasonData.seasons[seasonIndex].episodes.push(episodeData);
							});

						seasonData.seasons.sort((a, b) => a.seasonNumber - b.seasonNumber);
						seasonData.seasons.forEach((season) => {
							season.episodes.sort((a, b) => a.episodeNumber - b.episodeNumber);
						});

						gnData.seasons = seasonData.seasons;
					}

					out.push(gnData);

					readState = readStateValue.NotStarted;
					logbuffer.flush();
					lineStore = "";
					break;
				case readStateValue.NotStarted:
					if (line == captureTags.start) {
						readState = readStateValue.Reading;
						lineStore += line + "\n";
					}
					break;
				case readStateValue.Completed:
					return readStateValue.Completed;
					break;
			}
		},
		() => {
			console.log("File read successfully!");
		}
	);

	await scraperLib.fm.WriteToJSON(out, output);

	return out;

	function GetViewingOptions(video) {
		let videoData = new scraperLib.ContentTemplates().GetProvidersTemplate();
		videoData.hostId = video.host["@_id"];
		videoData.host = video.host["#text"];
		videoData.availability = video.availableFromDateTime;
		videoData.expiration = video.expiresAtDateTime;
		videoData.updated = video.updatedAt;

		if (!Array.isArray(video.urls.url)) {
			let tempView = video.urls.url;
			video.urls.url = [];
			video.urls.url.push(tempView);
		}
		video.urls.url.forEach((url) => {
			let linkShort = platformValues[url["@_type"]];
			videoData.links[linkShort] = url["#text"];
		});

		if (!Array.isArray(video.viewingOptions.viewingOption)) {
			let tempData = video.viewingOptions.viewingOption;
			video.viewingOptions.viewingOption = [];
			video.viewingOptions.viewingOption.push(tempData);
		}

		let viewData = video.viewingOptions.viewingOption;
		for (let i = 0; i < viewData.length; i++) {
			let viewDataRef = viewData[i];
			let existingViewData = find(videoData.viewingOptions, {
				license: viewDataRef.license,
			});
			let contentViewData = existingViewData ? existingViewData : { license: "", video: [] };
			let videoContent = {};

			switch (viewDataRef.license) {
				case licenseValues.rental:
					if (viewDataRef.price) {
						videoContent.cost = viewDataRef?.price["#text"];
						videoContent.currency = viewDataRef?.price["@_currency"];
					}
					contentViewData.license = licenseValues.rental;
					if (viewDataRef?.video?.quality)
						videoContent.quality = videoQuality[viewDataRef.video.quality];
					break;
				case licenseValues.free:
					contentViewData.license = licenseValues.free;
					if (viewDataRef?.video?.quality)
						videoContent.quality = videoQuality[viewDataRef.video.quality];
					break;
				case licenseValues.purchase:
					if (viewDataRef.price) {
						videoContent.cost = viewDataRef?.price["#text"];
						videoContent.currency = viewDataRef?.price["@_currency"];
					}
					contentViewData.license = licenseValues.purchase;
					if (viewDataRef?.video?.quality)
						videoContent.quality = videoQuality[viewDataRef.video.quality];
					break;
				case licenseValues.subscription:
					contentViewData.license = licenseValues.subscription;
					if (viewDataRef?.video?.quality)
						videoContent.quality = videoQuality[viewDataRef.video.quality];
					break;
				default:
					break;
			}
			contentViewData.video.push(videoContent);

			if (existingViewData) {
				videoData.viewingOptions.forEach((view) => {
					if (view.license === videoQuality[viewDataRef.video.quality]) {
						view.video.push(contentViewData);
					}
				});
			} else {
				videoData.viewingOptions.push(contentViewData);
			}
		}

		return videoData;
	}
}

async function readFileLineByLine(filePath, onLineRead, onFinish) {
	try {
		let file;
		let stream;
		// Open the file as a stream
		if (scraperLib.rt != scraperLib.RuntimeValue.Bun) {
			stream = fs.createReadStream(filePath);
		} else {
			file = Bun.file(filePath);
			stream = await file.stream();
		}

		const decoder = new TextDecoder();
		let stringHolder = "";

		// Loop through each chunk of data from the stream
		for await (const chunk of stream) {
			const str = stringHolder + decoder.decode(chunk);
			let streamState = false;
			// Split the chunk into lines
			const lines = str.split(/\n/g); // Handles both LF and CRLF line endings
			stringHolder = lines[lines.length - 1];

			// Process each line except the last one (might be incomplete)
			for (let i = 0; i < lines.length - 1; i++) {
				streamState = onLineRead(lines[i]);
			}

			if (streamState == readStateValue.Completed) {
				console.log("Completed current data set");
				break;
			}
		}

		// Handle the last incomplete line (if any)
		if (stringHolder.length > 0) {
			onLineRead(stringHolder[stringHolder.length - 1]);
		}

		onFinish();
	} catch (error) {
		console.error("Error reading file:", error);
	}
}

function handleXmlObject(xml) {
	let options = {
		ignoreAttributes: false,
		attributeNamePrefix: "@_",
	};
	let parser = new XMLParser(options);
	let data = parser.parse(xml);

	return data;
}

async function GracenoteCount(input, opts, output = "./temp/", print = true) {
	let inputList;
	let listLength;
	let counter = 0;
	let out = [];
	let tempOutName = {};

	console.log("Starting Counting");

	await readFileLineByLine(
		process.env.INPUT_DIR,
		(line) => {
			if (++counter % (maxPackSize * 10) == 0) {
				console.log(`Current Index: ${counter}`);
				logbuffer.flush();
			}
			let data;
			let lineData = line.replace(/\s/g, "").slice(0, -1);

			try {
				data = JSON.parse(lineData);
			} catch (e) {
				return;
			}

			if (opts.media == "movies") {
				for (let j = 0; j < data.providerDetail.length; j++) {
					let providerItem = data.providerDetail[j];
					let template = {
						name: "",
						ref: "",
						count: 1,
					};
					providerItem.host = providerItem.host.replace(" US", "");
					template.name = providerItem.host;
					template.ref = providerItem.hostId;

					if (!tempOutName[providerItem.host]) {
						tempOutName[providerItem.host] = {};
						tempOutName[providerItem.host].count = 1;
						tempOutName[providerItem.host].list = [];
						tempOutName[providerItem.host].list.push(providerItem.links.W);
					} else {
						tempOutName[providerItem.host].count++;
						tempOutName[providerItem.host].list.push(providerItem.links.W);
					}
				}
			} else if (opts.media == "series") {
				let seasonList = [];

				Object.keys(data.seasons).forEach((key) => {
					seasonList.push(data.seasons[key]);
				});

				// gracenote
				for (let j = 0; j < seasonList.length; j++) {
					let eps = seasonList[j].episodes;

					for (let k = 0; k < eps.length; k++) {
						let providers = eps[k].providerDetail;

						for (let l = 0; l < providers.length; l++) {
							// providers[l] = providers[l].host
							//.replace(" US", "");

							if (tempOutName[providers[l].host] == undefined) {
								tempOutName[providers[l].host] = {};
								tempOutName[providers[l].host].count = 1;
								tempOutName[providers[l].host].list = [];
								tempOutName[providers[l].host].list.push(providers[l].links.W);
							} else {
								tempOutName[providers[l].host].count++;
								tempOutName[providers[l].host].list.push(providers[l].links.W);
							}
						}
					}
				}
			}
		},
		() => {
			console.log("Finished Counting");
			logbuffer.flush();
		}
	);

	out.push(tempOutName);

	console.log("Done");

	let sorted = [];
	sorted.push({});

	Object.keys(out[0])
		.sort()
		.forEach((key) => {
			sorted[0][key] = out[0][key];
		});

	logbuffer.flush();
	if (print) await scraperLib.fm.WriteToJSON(sorted, output);

	return out;
}

async function GracenoteIngestion(input, opts, output = "./temp/") {
	let inputList;
	let listLength;
	let counter = 0;

	let out = [];
	let tempOutName = {};

	console.log("Starting Counting");

	try {
		inputList = JSON.parse(input);
		listLength = inputList.length;
		inputList.forEach((item) => {
			item.credits = {};
		});
	} catch (e) {
		if (input instanceof fs.ReadStream) {
			inputList = [];
			isPiping = true;
			input
				.pipe(JSONStream.parse("*"))
				.on("data", (chunk) => {
					let bareNecessities = chunk;
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
	}

	inputList.forEach((item) => {});

	out.push(tempOutName);

	console.log("Done");

	let sorted = [];
	sorted.push({});

	Object.keys(out[0])
		.sort()
		.forEach((key) => {
			sorted[0][key] = out[0][key];
		});

	logbuffer.flush();
	if (print) await scraperLib.fm.WriteToJSON(sorted, output);

	return out;
}

async function GracenoteMergeTMDB(input, tmdb, opts, output = "./temp/") {
	let inputList;
	let tmdbList = [];
	let counter = 0;
	let inputSize = 0;
	let tmdbCounter = 0;
	let isPiping = false;
	let out = [];
	let tempOutName = {};
	// let alphabetOptimizer = {};
	let matchedCounter = 0;

	console.log("Starting Merging");

	try {
		inputList = JSON.parse(input);
		listLength = inputList.length;
		inputList.forEach((item) => {
			item.credits = {};
		});
		inputSize = inputList.length;
		tmdbList = JSON.parse(tmdb);
		console.log("Parsed JSON");
		logbuffer.flush();
	} catch (e) {
		logbuffer.flush();
		isPiping = true;
		let isPiping2 = true;
		try {
			input = fs.createReadStream(input);
			inputList = [];
			console.log("File streaming");
			logbuffer.flush();
			input
				.pipe(JSONStream.parse("*"))
				.on("data", (chunk) => {
					let bareNecessities = chunk;

					if (++counter % 10000 == 0) {
						console.log("input counter: " + counter);
						logbuffer.flush();
					}
					inputList.push(bareNecessities);
				})
				.on("end", () => {
					inputSize = inputList.length;
					if (isPiping2) {
						isPiping2 = false;
					} else {
						isPiping = false;
					}
					console.log("Completed input stream");
				});
		} catch (e) {
			console.log(e);
			logbuffer.flush();
		}

		try {
			let tmdbStream = fs.createReadStream(tmdb);
			tmdbStream
				.pipe(JSONStream.parse("*"))
				.on("data", (chunk) => {
					//already min'd
					let bareNecessities = chunk;

					if (++tmdbCounter % 10000 == 0) {
						console.log("tmdbCounter: " + tmdbCounter);
						// if(tmdbCounter > 70000)
						// //stop tmdbStream
						// {
						// 	tmdbStream.destroy();
						// 	isPiping = false;
						// }
						logbuffer.flush();
					}
					tmdbList.push(bareNecessities);
				})
				.on("end", () => {
					if (isPiping2) {
						isPiping2 = false;
					} else {
						isPiping = false;
					}
					console.log("Completed TMDB stream");
				});
		} catch (e) {
			console.log(e);
			logbuffer.flush();
		}
	}

	while (isPiping) {
		console.log("Piping");
		await scraperLib.Sleep(3000);
		logbuffer.flush();
	}

	console.log("Done with TMDB");
	logbuffer.flush();
	counter = 0;
	const startTime = Date.now();
	//sort by alphabetical in tmdb.title
	// Sort tmdbList by title
	tmdbList.sort((a, b) => a.title.localeCompare(b.title));

	// Create alphabet optimizer
	const alphabetOptimizer = {};
	tmdbList.forEach((item, index) => {
		const charFirst = item.title.charAt(0);
		if (!alphabetOptimizer[charFirst]) {
			alphabetOptimizer[charFirst] = { index: index, count: 0 };
		}
		alphabetOptimizer[charFirst].count++;
	});

	// Loop through inputList
	for (let i = 0; i < inputList.length; i++) {
		const item = inputList[i];
		if ((i + 1) % 1000 === 0) {
			console.log(`input counter: ${i + 1} of ${inputList.length}`);
			logbuffer.flush();
		}

		const charFirst = item.title.charAt(0);
		if (!alphabetOptimizer[charFirst]) {
			continue;
		}

		const index = alphabetOptimizer[charFirst].index;
		const count = alphabetOptimizer[charFirst].count;
		let matchedIndex = -1;
		let matchedListIndexes = [];
		let isMatched = false;
		let matchedContiguous = false;

		// Find matches in tmdbList
		for (let j = index; j < index + count; j++) {
			const tmdbElement = tmdbList[j];

			if (tmdbElement.title == item.title) {
				matchedListIndexes.push(j);
				matchedContiguous = true;
			} else if (matchedContiguous) {
				//no longer matches title
				break;
			}
		}

		if (matchedListIndexes.length > 0) {
			if (matchedListIndexes.length === 1) {
				matchedIndex = 0;
			} else {
				let yearDict = {};
				for (let j = 0; j < matchedListIndexes.length; j++) {
					const tmdbElement = tmdbList[matchedListIndexes[j]];
					tmdbElement.index = j;
					if (yearDict[tmdbElement.releaseDate]) {
						yearDict[tmdbElement.releaseDate].push(tmdbElement);
					} else {
						yearDict[tmdbElement.releaseDate] = [tmdbElement];
					}
				}
				//need to match by actors
				if (yearDict[item.releaseDate] && yearDict[item.releaseDate].length == 1) {
					const tmdbElement = yearDict[item.releaseDate][0];
					if (tmdbElement.releaseDate == item.releaseDate) {
						matchedIndex = tmdbElement.index;
					}
				} else {
					item.error = "Multiple matches with same release date";
				}
			}
		}

		// If match found, assign tmdbId and imdbId
		if (matchedIndex !== -1) {
			const matchedElement = tmdbList[matchedListIndexes[matchedIndex]];
			item.tmdbId = matchedElement.tmdbId;
			item.imdbId = matchedElement.imdbId;
			matchedCounter++;
		}
	}

	out = inputList;
	console.log(`Matched count: ${matchedCounter}\t|\ttotal: ${inputList.length}`);
	console.log("Done");
	// Record end time
	const endTime = Date.now();

	// Calculate runtime
	const runtime = endTime - startTime;
	console.log(`Runtime: ${runtime / 1000} seconds`);
	logbuffer.flush();
	await scraperLib.fm.WriteToJSON(out, output);

	return out;
}

function copyMatchingProperties(targetObj, sourceObj) {
	for (const key in sourceObj) {
		if (targetObj.hasOwnProperty(key)) {
			// Check if key exists in target object
			targetObj[key] = sourceObj[key];
		}
	}

	return targetObj;
}
