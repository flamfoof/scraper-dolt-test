import * as fs from "fs";
import path from "path";
import fetch from "node-fetch";
import logbuffer from "console-buffer";
import {exec} from "child_process";
import _ from "lodash.get";
import isElevated from "is-elevated";
import * as JSRuntime from "./JSRuntime.js";

var optsHeaderDefault = {
	method: "GET",
	headers: {
		"User-Agent": "Webb",
	},
};

/**
 * Asynchronous function for querying the API with retry logic and error handling.
 *
 * @param {string} api - The API endpoint to query
 * @param {Object} opts - The options for the API query
 * @param {number} [mRetry=process.env.MAX_RETRY] - The maximum number of retry attempts
 * @param {string} [type="json"] - The type of response expected, default is "json"
 * @return {Object} The response data from the API query, or null if unsuccessful
 */
export async function APISearchQuery(api, opts, mRetry = process.env.MAX_RETRY, type = "json") {
	var getDetail;

	if (opts == {}) {
		opts = optsHeaderDefault;
	}

	for (var k = 0; k < mRetry; k++) {
		var fetchLogger = "";
		try {
			var APIQuery = api;
			// console.log("Querying: " + APIQuery);
			getDetail = await fetch(APIQuery, opts);
			fetchLogger = await getDetail.text();
            if(type == "json")
            {
                getDetail = JSON.parse(fetchLogger);
            } else {
                getDetail = fetchLogger;
            }

			//Error properties for TMDB scraping
			if (getDetail.status_code == 34) {
				return (getDetail = null);
			} else if (getDetail.hasOwnProperty("status_code")) {
				throw "Fetch returned 401/404 status code: " + getDetail.status_message + "\nQuery: " + APIQuery;
			}
		} catch (e) {
			console.log("Node fetch crashed because Error: " + e);
			// console.log("Fetch results: " + fetchLogger);
			console.log("Retrying.....");

			logbuffer.flush();

			if (fetchLogger && fetchLogger.match(/(network request)/)) {
				await JSRuntime.Sleep(process.env.RETRY_SLEEP_TIMER);
			}

            if (fetchLogger && fetchLogger.match(/(client)/) && await isElevated()) {
                exec(process.env.RESTART_NET_BAT, function(err, stdout) {
                    if(err)
                        console.log(err);
                    
                    console.log(stdout);
                })

				await JSRuntime.Sleep(process.env.RETRY_SLEEP_TIMER);
			}

			getDetail = null;

			await JSRuntime.Sleep(process.env.BASIC_SLEEP_TIMER);
		}

		if (getDetail && getDetail.hasOwnProperty("errors")) {
			getDetail = null;
		}

		if (getDetail) {
			k = mRetry;
		}

		logbuffer.flush();
	}

	if (!getDetail || getDetail.length == 0) {
		return null;
	}

	var keys = Object.keys(getDetail);

	if (keys.length == 0) {
		return null;
	}

	await JSRuntime.Sleep(process.env.RAPID_SLEEP_TIMER);

	return getDetail;
}

/**
 * Asynchronous function to query a web API with retry logic and error handling.
 *
 * @param {Object} api - the API endpoint to query
 * @param {Object} opts - options for the web query
 * @param {number} [mRetry=process.env.MAX_RETRY] - maximum number of retries
 * @param {string} [type="json"] - the type of response expected
 * @return {Promise} the response from the API query
 */
export async function WebQuery(api, opts, mRetry = process.env.MAX_RETRY, type = "json") {
	var getDetail;

	if (opts == {}) {
		opts = optsHeaderDefault;
	}

	for (var k = 0; k < mRetry; k++) {
		var fetchLogger = "";
		try {
			var APIQuery = api;
			// console.log("Web Querying: " + APIQuery);
			getDetail = await fetch(APIQuery, opts);
            getDetail = await getDetail.text();
			// fetchLogger = await getDetail.text();

			if (getDetail.status_code == 34 && k > 2) {
				return (getDetail = null);
			} else if (getDetail.hasOwnProperty("status_code")) {
				throw "Fetch returned 401/404 status code: " + getDetail.status_message;
			} else if (!getDetail.substring(0, 50).includes("<!doctype html>"))
            {
                throw "Amazon no likey scraping" + getDetail.substring(0, 50);
            }
		} catch (e) {
			console.log("Node fetch crashed because Error: " + e);
			// console.log("Fetch results: " + fetchLogger);
			console.log("Retrying.....");

			logbuffer.flush();

			if (fetchLogger && fetchLogger.match(/(network request)/)) {
				await JSRuntime.Sleep(process.env.RETRY_SLEEP_TIMER);
			}

            if (fetchLogger && fetchLogger.match(/(client)/) && await isElevated()) {
                exec(process.env.RESTART_NET_BAT, function(err, stdout) {
                    if(err)
                        console.log(err);
                    
                    console.log(stdout);
                })

				await JSRuntime.Sleep(process.env.RETRY_SLEEP_TIMER);
			}

			getDetail = null;

			await JSRuntime.Sleep(process.env.RETRY_SLEEP_TIMER);
		}

		if (getDetail && getDetail.hasOwnProperty("errors")) {
			getDetail = null;
		}

		if (getDetail) {
			k = mRetry;
		}

		logbuffer.flush();
	}

	await JSRuntime.Sleep(process.env.RAPID_SLEEP_TIMER);

	return getDetail;
}

/**
 * Asynchronous function to sleep for a specified amount of time.
 *
 * @param {number} ms - The number of milliseconds to sleep
 * @return {Promise<void>} A promise that resolves after sleeping
 */
export async function Sleep(ms) 
{
	await JSRuntime.Sleep(ms);
}

export function isEmpty(obj)
{
    for(var i in obj)
    {
        return false;
    }

    return true;
}