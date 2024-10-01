import logbuffer from "console-buffer";
import * as libUtil from "./API/NetCall.js";
import * as FileManagementJs from "./API/FileManagement.js";

const filterAcceptedSources = [
	{name: "Prime Video", ref: "pvt_aiv", media: []},
	{name: "Pluto TV", ref: "pluto", media: []},
	{name: "HBO Max", ref: "hbomax", media: []},
	{name: "Tubi", ref: "tubi", media: []},
	{name: "CONtv", ref: "pvc_contv", media: []},
	{name: "Fandor", ref: "pvc_fandor", media: []},
	{name: "TBS", ref: "tbs", media: []},
	{name: "TNT", ref: "tnt", media: []},
	{name: "STARZ", ref: "starz", media: []},
	{name: "Netflix", ref: "netflix", media: []},
	{name: "FXNOW", ref: "fx_now", media: []},
	{name: "Peacock", ref: "peacock", media: []},
	{name: "SHOWTIME", ref: "pvc_showtimeSub", media: []},
	{name: "Showtime Anytime", ref: "showtime", media: []},
	{name: "Paramount+", ref: "pvc_paramount+", media: []},
	{name: "Bravo Now", ref: "bravo", media: []},
	{name: "NBC", ref: "nbc", media: []},
	{name: "Hulu", ref: "hulu", media: []},
	{name: "ABC", ref: "abc", media: []},
	{name: "Freeform", ref: "freeform", media: []},
	{name: "AMC+", ref: "pvc_amcplus", media: []},
	{name: "BBC America", ref: "bbc_usa", media: []},
	{name: "EPIX", ref: "pvc_epix", media: []},
	{name: "Epix", ref: "epix", media: []},
	{name: "Cinemax", ref: "pvc_cinemax", media: []},
	{name: "Freevee", ref: "fdv", media: []},
	{name: "Plex", ref: "_plex", media: []},
	{name: "BritBox", ref: "pvc_britbox", media: []},
	{name: "Filmbox", ref: "pvc_filmbox", media: []},
	{name: "Crackle", ref: "crackle", media: []},
	{name: "MUBI", ref: "pvc_mubi", media: []},
	{name: "Screambox", ref: "pvc_screambox", media: []},
	{name: "Shout! Factory TV", ref: "pvc_shoutfactory", media: []},
	{name: "Hallmark Movies Now", ref: "pvc_hallmark", media: []},
	{name: "Sundance Now", ref: "pvc_sundancenow", media: []},
	{name: "Indie Club", ref: "pvc_indieclub", media: []},
	{name: "FMTV", ref: "pvc_foodmatters", media: []},
	{name: "Acorn TV", ref: "pvc_acorn", media: []},
	{name: "CuriosityStream", ref: "pvc_curiositystreamstandard", media: []},
	{name: "Amazon Kids+", ref: "pvc_A4K", media: []},
	{name: "Apple TV+", ref: "appletv", media: []},
	{name: "PBS Masterpiece", ref: "pvc_masterpiece", media: []},
	{name: "IndieFlix Shorts", ref: "pvc_indieflix", media: []},
	{name: "Funimation", ref: "fun_ca", media: []},
	{name: "PBS KIDS", ref: "pvc_pbskids", media: []},
	{name: "BET+", ref: "betplus", media: []},
	{name: "MTV", ref: "mtv", media: []},
	{name: "Discovery Go", ref: "discovery", media: []},
	{name: "HISTORY Vault", ref: "pvc_historyvault", media: []},
	{name: "AMC", ref: "amc", media: []},
	{name: "NickHits", ref: "pvc_nickhits", media: []},
	{name: "PBS", ref: "pbs", media: []},
	{name: "Animal Planet", ref: "an_pl", media: []},
    {name: "Disney Plus", ref: "disney_plus", media: []},
	{name: "DisneyNow", ref: "disney_now", media: []},
	{name: "History", ref: "history", media: []},
	{name: "PBS Living", ref: "pvc_pbsliving", media: []},
	{name: "Cartoon Network", ref: "cartoon", media: []},
	{name: "adultswim", ref: "ad_sw", media: []},
	{name: "HGTV", ref: "hgtv", media: []},
	{name: "Comedy Central", ref: "com_cen", media: []},
	{name: "A&E", ref: "ae", media: []},
	{name: "FOX NOW", ref: "fox", media: []},
	{name: "BET", ref: "bet", media: []},
	{name: "HooplaKidz Plus", ref: "pvc_hooplakidzplus", media: []},
];

export async function Init(input, opts, output = process.env.DEFAULT_OUTPUT_DIR) {
	var inputList = JSON.parse(input);
	var out = [];

	if (opts) {
		opts = JSON.parse(opts);
	} else {
		opts = JSON.parse({});
	}

	if (opts.filtered) {
		// Get selected unique providers
		var uniqueProviderList = [];

		filterAcceptedSources.forEach((element) => {
			uniqueProviderList.push(element.name);
		});
	} else {
		// Get ALL unique providers
		var uniqueProviderList = [];
        filterAcceptedSources.length = 0;
	}

	if (opts.media == "movies" || opts.media == "series") {
		for (var i = 0; i < inputList.length; i++) {
			for (var j = 0; j < inputList[i].providers.length; j++) {
				if (uniqueProviderList.includes(inputList[i].providers[j].name)) {
					var indexProvider = uniqueProviderList.indexOf(inputList[i].providers[j].name);
					var inputData = JSON.parse(JSON.stringify(inputList[i]));
                    inputData.purchaseType = inputList[i].providers[j]?.type;
					delete inputData["providers"];
					delete inputData["directors"];
					delete inputData["desc"];
					delete inputData["voteCount"];
					delete inputData["voteAverage"];
					delete inputData["language"];
					try {
                        if(filterAcceptedSources[indexProvider]?.total)
                        {
                            filterAcceptedSources[indexProvider].total++;
                        } else {
                            filterAcceptedSources[indexProvider].total = 1;
                        }

						filterAcceptedSources[indexProvider].media.push(inputData);
					} catch (e) {
						console.log(e);
						console.log("Failed at: " + inputList[i].providers[j].name);
						process.exit(1);
					}
				} else if (!opts.filtered) {
					//depends on if we have all unique options
					var filteredTemplate = {
						name: "",
						ref: "",
                        total: 0,
						media: [],
					};

					uniqueProviderList.push(inputList[i].providers[j].name);
					filteredTemplate.name = inputList[i].providers[j].name;
					filteredTemplate.ref = inputList[i].providers[j].ref;
					filterAcceptedSources.push(filteredTemplate);

					--j;
				}
			}
		}
    }

	for (var i = 0; i < uniqueProviderList.length; i++) {
		await FileManagementJs.WriteToJSON([filterAcceptedSources[i]], output, filterAcceptedSources[i].name + ".json");
	}

	console.log("Done");

	logbuffer.flush();

	return out;
}
