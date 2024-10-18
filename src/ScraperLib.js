import module from "module";
import _ from "lodash.get";
export * as netCall from "../util/API/NetCall.js";
export * as fm from "../util/API/FileManagement.js";
export * as db from "../util/API/DatabaseConnection.js";
export * as jsRuntime from "../util/API/JSRuntime.js";
export { rt, RuntimeValue, Sleep } from "../util/API/JSRuntime.js";

//This library acts as a binder to our custom libraries

class ScraperLib {
  #instance = null;
  constructor() {
    if (this.#instance) {
      throw new Error("Only one instance of MyLibrary allowed!");
    }
    this.#instance = this;
  }
}

export class ContentTemplates {
	#moviesTemplate = {
		//GetMoviesTemplate()
		id: 0, //The index in which it is used by the scraper
		contentId: null,
		imdbId: null,
		tmdbId: null,
		tmsId: "",
		// rootId: 0,
		title: "",
		altTitle: undefined, // Matches with the TMDB title if it's not an exact match
		desc: "",
		region: null,
		audienceRating: null,
		tags: "",
		runtime: null, //Measured in seconds and parsed into '# h # m' format
		releaseDate: "YYYY-MM-DD or YYYY",
		credits: {
			cast: [],
			crew: [],
		},
		endDate: "",
		hasResults: false, //Defines if there are valid search results. Used for finding shows with results, but incorrect descriptions
		providerDetail: [],
		poster_url: null,
		backdrop_url: null,
		errorOnRetrieval: undefined, //Any errors that occurs on fetching the search API
	};

	#seriesTemplate = {
		// GetSeriesTemplate()
		id: 0, //The index in which it is used by the scraper
		contentId: null,
		imdbId: null,
		tmdbId: null,
		tmsId: "",
		// rootId: 0,
		title: "",
		altTitle: undefined, // Matches with the TMDB title if it's not an exact match
		episodeCount: 0,
		seasonCount: 0,
		desc: "",
		region: null,
		audienceRating: null,
		tags: "",
		releaseDate: "YYYY-MM-DD or YYYY",
		endDate: "",
		credits: {
			cast: [],
			crew: [],
		},
		hasResults: false, //Defines if there are valid search results. Used for finding shows with results, but incorrect descriptions
		providerDetail: [],
		seasons: [],
		poster_url: null,
		backdrop_url: null,
		errorOnRetrieval: undefined, //Any errors that occurs on fetching the search API
	};

	#seasonsTemplate = {
		// GetSeasonsTemplate()
		id: 0,
		tmdbId: null,
		tmsId: "",
		// rootId: 0,
		title: "",
		seasonNumber: 0,
		episodeCount: 0,
		releaseDate: "YYYY-MM-DD or YYYY",
		desc: "",
		episodes: [], //Defines each episode's data. Contained in episodeTemplate
		rental_cost_sd: undefined,
		rental_cost_hd: undefined,
		purchase_cost_sd: undefined,
		purchase_cost_hd: undefined,
	};

	#episodesTemplate = {
		// GetEpisodesTemplate()
		id: 0,
		contentId: null,
		imdbId: null,
		tmdbId: null,
		tmsId: "",
		// rootId: 0,
		title: "",
		episodeNumber: "",
		releaseDate: "YYYY-MM-DD or YYYY",
		runtime: null, //Measured in seconds and parsed into '# h # m' format
		desc: "",
		contentType: "",
		providerDetail: [],
		rental_cost_sd: undefined,
		rental_cost_hd: undefined,
		purchase_cost_sd: undefined,
		purchase_cost_hd: undefined,
	};

	#ingestorMoviesTemplate = {
		// GetIngestorMoviesTemplate()
		movie_id: null,
		tmdb_id: null,
		imdb: null,
		tmsId: undefined,
		// rootId: 0,
		title: "",
		releaseDate: undefined,
		// credits: {
		//   cast: [],
		//   crew: [],
		// },
		source_id: 0,
		source_type: "",
		origin_source: "freecast",
		region_id: "us",
		A: undefined, // Android
		F: undefined, // Fire TV
		I: undefined, // iOS
		L: undefined, // LG/webOS
		N: undefined, // Android TV
		R: undefined, // Roku
		S: undefined, // Samsung/Tizen
		T: undefined, // tvOS
		W: undefined, // Web
		rental_cost_sd: undefined,
		rental_cost_hd: undefined,
		purchase_cost_sd: undefined,
		purchase_cost_hd: undefined,
		expiration: undefined,
	};

	#ingestorSeriesTemplate = {
		// GetIngestorSeriesTemplate()
		show_id: null,
		episode_id: null,
		tv_show_tmdb_id: null,
		tmdb_id: null,
		imdb: null,
		tmsId: undefined,
		show_tmsId: undefined,
		season: 0,
		episode: 0,
		showTitle: "",
		episodeTitle: "",
		releaseDate: undefined,
		// credits: {
		//   cast: [],
		//   crew: [],
		// },
		source_id: 0,
		source_type: "",
		origin_source: "freecast",
		region_id: "us",
		A: undefined, // Android
		F: undefined, // Fire TV
		I: undefined, // iOS
		L: undefined, // LG/webOS
		N: undefined, // Android TV
		R: undefined, // Roku
		S: undefined, // Samsung/Tizen
		T: undefined, // tvOS
		W: undefined, // Web
		rental_cost_sd: undefined,
		rental_cost_hd: undefined,
		purchase_cost_sd: undefined,
		purchase_cost_hd: undefined,
		expiration: undefined,
	};

	#providersTemplate = {
		// GetProvidersTemplate()
		sourceId: 0,
		hostId: "",
		host: "",
		availability: "",
		expiration: "",
		updated: "",
		links: {
			A: undefined, // Android
			F: undefined, // Fire TV
			I: undefined, // iOS
			L: undefined, // LG/webOS
			N: undefined, // Android TV
			R: undefined, // Roku
			S: undefined, // Samsung/Tizen
			T: undefined, // tvOS
			W: undefined, // Web
		},
		viewingOptions: [],
	};

	#ingestorMoviesGNTemplate = {
		// GetIngestorMoviesTemplate()
		tmdb_id: null,
		imdb: null,
    	tmdb_id: null,
		tmsId: "",
		title: "",
		// releaseDate: "YYYY-MM-DD or YYYY",
		source_id: 0,
		source_type: "",
		source_name: "",
		origin_source: "gracenote",
		android_link: undefined, // Android
		fire_tv_link: undefined, // Fire TV
		ios_link: undefined, // iOS
		web_os_link: undefined, // LG/webOS
		android_tv_link: undefined, // Android TV
		tv_os_link: undefined, // tvOS
		web_link: undefined, // Web
		rental_cost_sd: undefined,
		rental_cost_hd: undefined,
		purchase_cost_sd: undefined,
		purchase_cost_hd: undefined,
		expiration: undefined,
	};

	#ingestorSeriesGNTemplate = {
		// GetIngestorSeriesTemplate()
		tv_show_tmdb_id: null,
		tmdb_id: null,
		imdb: null,
		tmsId: "",
		title: "",
		episodeTitle: "",
		season: 0,
		episode: 0,
		// releaseDate: "YYYY-MM-DD or YYYY",
		source_id: 0,
		source_type: "",
		source_name: "",
		origin_source: "gracenote",
		android_link: undefined, // Android
		fire_tv_link: undefined, // Fire TV
		ios_link: undefined, // iOS
		web_os_link: undefined, // LG/webOS
		android_tv_link: undefined, // Android TV
		tv_os_link: undefined, // tvOS
		web_link: undefined, // Web
		rental_cost_sd: undefined,
		rental_cost_hd: undefined,
		purchase_cost_sd: undefined,
		purchase_cost_hd: undefined,
		expiration: undefined,
	};

	#ingestorMoviesMetadataGNTemplate = {
		movie_id: null,
		imdb: null,
		tmsId: null,
		tmdbId: null,
		tmdb_id: undefined,
		title: null,
		released_on: "YYYY-MM-DD or YYYY",
		runtime: undefined,
		overview: undefined,
		classification: undefined,
		tags: undefined,
		poster_url: undefined,
		backdrop_url: undefined,
	};

	#ingestorSeriesMetadataGNTemplate = {
		show_id: null,
		imdb: null,
		tmsId: null,
		tmdbId: null,
		tmdb_id: undefined,
		title: null,
		released_on: "YYYY-MM-DD or YYYY",
		overview: undefined,
		runtime: undefined,
		// episodes: [],
		classification: undefined,
		tags: undefined,
		poster_url: undefined,
		backdrop_url: undefined,
	};

	#ingestorEpisodesMetadataGNTemplate = {
		show_id: null,
		episode_id: null,
		imdb: null,
		tmdbId: null,
		tmdb_id: undefined,
		show_tmsId: null,
		tmsId: null,
		title: null,
		releaseDate: "YYYY-MM-DDT08:00:00Z",
		sequence_number: null,
		episode_number: null,
		episode_number: null,
		episode_image_url: null,
	};

	#providersGNTemplate = {
		// GetProvidersTemplate()
		sourceId: 0,
		hostId: "",
		host: "",
		availability: "",
		expiration: "",
		updated: "",
		links: {
			android_link: undefined, 	// Android
			fire_tv_link: undefined, 	// Fire TV
			ios_link: undefined, 		// iOS
			web_os_link: undefined, 	// LG/webOS
			android_tv_link: undefined, // Android TV
			tv_os_link: undefined, 		// tvOS
			web_link: undefined, 		// Web
		},
		viewingOptions: [],
	};

	/**
	 * GetMovieTemplate function returns the movies template.
	 *
	 * @return {JSON} The Movies template
	 */
	GetMoviesTemplate() {
		return this.#moviesTemplate;
	}

	/**
	 * GetSeriesTemplate function returns the series template.
	 *
	 * @return {JSON} The Series template
	 */
	GetSeriesTemplate() {
		return this.#seriesTemplate;
	}

	/**
	 * GetSeasonsTemplate function returns the seasons template.
	 *
	 * @return {JSON} The Seasons template
	 */
	GetSeasonsTemplate() {
		return this.#seasonsTemplate;
	}

	/**
	 * GetEpisodeTemplate function returns the episodes template.
	 *
	 * @return {JSON} - The Episode template
	 */
	GetEpisodesTemplate() {
		return this.#episodesTemplate;
	}

	/**
	 * GetIngestorTemplate function returns the ingestor movies template.
	 * "A": Android
	 * "F": Fire TV
	 * "I": iOS
	 * "L": LG/webOS
	 * "N": Android TV
	 * "R": Roku
	 * "S": Samsung/Tizen
	 * "T": tvOS
	 * "W": Web
	 * @return {JSON} The Ingestor template
	 */
	GetIngestorMoviesTemplate() {
		return this.#ingestorMoviesTemplate;
	}

	/**
	 * GetIngestorTemplate function returns the ingestor series template.
	 * "A": Android
	 * "F": Fire TV
	 * "I": iOS
	 * "L": LG/webOS
	 * "N": Android TV
	 * "R": Roku
	 * "S": Samsung/Tizen
	 * "T": tvOS
	 * "W": Web
	 * @return {JSON} The Ingestor template
	 */
	GetIngestorSeriesTemplate() {
		return this.#ingestorSeriesTemplate;
	}

	/**
	 * GetProviderTemplate function returns the provider template for sources/links.
	 *
	 * @return {type} description of return value
	 */
	GetProvidersTemplate() {
		return this.#providersTemplate;
	}

	/**
	 * GetIngestorGNTemplate function returns the ingestor movies template.
	 * "android_link": Android
	 * "fire_tv_link": Fire TV
	 * "ios_link": iOS
	 * "web_os_link": LG/webOS
	 * "android_tv_link": Android TV
	 * "tv_os_link": tvOS
	 * "web_link": Web
	 * @return {JSON} The Ingestor template
	 */
	GetIngestorMoviesGNTemplate() {
		return this.#ingestorMoviesGNTemplate;
	}

	/**
	 * GetIngestorMoviesMetadataGNTemplate function returns the ingestor movies metadata GN template.
	 *
	 * @return {JSON} The ingestor movies metadata GN template.
	 */
	GetIngestorMoviesMetadataGNTemplate() {
		return this.#ingestorMoviesMetadataGNTemplate;
	}

	/**
	 * GetIngestorSeriesGNTemplate function returns the ingestor series GN template.
	 *
	 * @return {JSON} The ingestor series GN template.
	 */
	GetIngestorSeriesGNTemplate() {
		return this.#ingestorSeriesGNTemplate;
	}

	/**
	 * GetIngestorSeriesMetadataGNTemplate function returns the ingestor series metadata GN template.
	 *
	 * @return {JSON} The ingestor series metadata GN template.
	 */
	GetIngestorSeriesMetadataGNTemplate() {
		return this.#ingestorSeriesMetadataGNTemplate;
	}

	/**
	 * GetIngestorEpisodesMetadataGNTemplate function returns the ingestor episodes metadata GN template.
	 *
	 * @return {JSON} The ingestor episodes metadata GN template.
	 */
	GetIngestorEpisodesMetadataGNTemplate() {
		return this.#ingestorEpisodesMetadataGNTemplate;
	}

	/**
	 * GetProviderGNTemplate function returns the provider template for sources/links.
	 *
	 * @return {type} description of return value
	 */
	GetProvidersGNTemplate() {
		return this.#providersGNTemplate;
	}
}

export class MatchedPropertiesList {
  matchedItems = null;
  constructor() {
    this.matchedItems = [];
  }

  //create a function to clear matchedItems
  Clear() {
    this.matchedItems.length = 0;
  }
}

/**
 * GetScraperTarget retrieves the scraper for the specified scrapePlatform and mediaType.
 *
 * @param {string} scrapePlatform - the platform to scrape
 * @param {string} mediaType - the type of media to scrape
 * @return {Promise<object>} the scraper for the specified platform and media type
 */
export async function GetScraperTarget(scrapePlatform, mediaType) {
  let scraperScriptDir;
  let scraper;

  try {
    let ingestorScriptName = "ingestion";
    if (mediaType.includes("ingestion")) {
      scraperScriptDir = `./${scrapePlatform}/${scrapePlatform}_${ingestorScriptName}.js`;
    } else {
      scraperScriptDir = `./${scrapePlatform}/${scrapePlatform}_${mediaType}.js`;
    }

    scraper = await import(scraperScriptDir);

    return scraper;
  } catch (e) {
    if (e.name == "Error") {
      console.log(
        `There are no ${scrapePlatform} scrapers for this media of type: ${scraperScriptDir}`
      );
      process.exit(1);
    }

    console.error("Error loading scraper: " + e);
    return null;
  }
}

/**
 * Recursively searches for a nested property in a JSON object and returns its value if found.
 *
 * @param {object} obj - The JSON object to search
 * @param {string} targetKey - The key of the property to find
 * @return {any} The value of the found property, or null if not found
 */
export function NestedJSONPropertyFinder(obj, targetKey) {
  let result = null;
  if (!obj) return null;

  for (const [key, value] of Object.entries(obj)) {
    if (key === targetKey) {
      return value;
    }

    if (typeof value !== "object") continue;

    result = NestedJSONPropertyFinder(value, targetKey);

    if (result) return result;
  }

  return result;
}

/**
 * Recursively searches for a specific property within a nested JSON object and returns a list of matched properties.
 *
 * @param {object} obj - The nested JSON object to search
 * @param {string} targetKey - The key to search for within the JSON object
 * @param {object} MatchedPropertiesList - The list to store matched properties
 * @return {object} The list of matched properties
 */
export function NestedJSONPropertyFinderList(
  obj,
  targetKey,
  MPL = new MatchedPropertiesList()
) {
  if (!obj) return null;

  for (const [key, value] of Object.entries(obj)) {
    if (key === targetKey) {
      MPL.matchedItems.push(obj);
    }

    if (typeof value !== "object") continue;

    NestedJSONPropertyFinderList(value, targetKey, MPL);
  }

  return MPL;
}

module.exports = new ScraperLib();
