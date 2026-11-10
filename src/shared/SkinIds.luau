--!strict
-- Exact owner-uploaded Dual skin image assets, keyed by DualDesigns definition id.
-- The two-digit join keeps this in step with art/models/slime_body/skins/asset_ids.json.
local DualDesigns = if script then require(script.Parent.DualDesigns) else require("./DualDesigns")

local byNumber: { [string]: number } = {
	["01"] = 89952599143576,
	["02"] = 78911880301169,
	["03"] = 135602593178768,
	["04"] = 122329431100644,
	["05"] = 98681283390195,
	["06"] = 83169753905851,
	["07"] = 87842064303233,
	["08"] = 93058163770764,
	["09"] = 120307790880431,
	["10"] = 83942793414374,
	["11"] = 120768957608783,
	["12"] = 136014969272863,
	["13"] = 137382364771985,
	["14"] = 83409385187979,
	["15"] = 74522284829798,
	["16"] = 93998607563144,
	["17"] = 138083391003592,
	["18"] = 71315372895466,
	["19"] = 113287707481993,
	["20"] = 93989830474457,
	["21"] = 132460595399220,
	["22"] = 106495854459969,
	["23"] = 123335344714942,
	["24"] = 92739554649735,
	["25"] = 116536890329904,
	["26"] = 132243388481469,
	["27"] = 136574783335565,
	["28"] = 116419390796139,
	["29"] = 130912901670589,
	["30"] = 93444734673332,
	["31"] = 78624296327420,
	["32"] = 71460078306755,
	["33"] = 106735662034787,
	["34"] = 136884962087543,
	["35"] = 82709759548786,
	["36"] = 115370966662338,
	["37"] = 81654410845000,
	["38"] = 89055759958890,
	["39"] = 96722304481260,
	["40"] = 120471321624837,
	["41"] = 107469466269169,
	["42"] = 103958460706197,
	["43"] = 129886566891760,
	["44"] = 78077936913306,
	["45"] = 78124300533277,
	["46"] = 99976669173207,
	["47"] = 134950817122563,
	["48"] = 135887544093214,
	["49"] = 117446377654778,
	["50"] = 75084361754596,
	["51"] = 107541366868093,
	["52"] = 80563759483953,
	["53"] = 83241373341690,
	["54"] = 90956872420325,
	["55"] = 113397081813545,
}
local SkinIds = {}
SkinIds.ById = {} :: { [string]: number }
for _, design in DualDesigns.List do
	local image = byNumber[design.number]
	if image then
		SkinIds.ById[design.id] = image
	end
end

-- The zombie kinds' skins (art/models/slime_body/skins/z_*.png, made by ChatGPT); in ById so their looks are built too.
SkinIds.Zombies = {
	rotten = 73614635851841,
	toxic = 95175306419387,
	plague = 109323196465830,
} :: { [string]: number }
for kind, image in SkinIds.Zombies do
	SkinIds.ById["zombie-" .. kind] = image
end

-- The Secret slimes' body skins (art/models/slime_body/skins/s_<file pair>.png, ChatGPT, 2026-11-08), keyed by recipe
-- id; ears, wings, horns and tails come later as separate parts. tools/skins/map_secret_skins.py matches each picture
-- to its recipe by name (the original art's file pairs do not always match the recipe colours) and prints these rows.
SkinIds.Secrets = {
	["secret-black-black"] = 91206608987673,
	["secret-black-blue"] = 89884862489611,
	["secret-black-gray"] = 111675631440031,
	["secret-black-green"] = 128736684857681,
	["secret-black-navy"] = 87592901200719,
	["secret-black-orange"] = 77009648050923,
	["secret-black-pink"] = 73579978741183,
	["secret-black-purple"] = 103479170868887,
	["secret-black-red"] = 109427183764030,
	["secret-black-white"] = 136231808459841,
	["secret-black-yellow"] = 107131463443154,
	["secret-blue-blue"] = 79212561121957,
	["secret-blue-gray"] = 91701587531180,
	["secret-blue-green"] = 87023197915550,
	["secret-blue-navy"] = 129474913363694,
	["secret-blue-orange"] = 134088253960501,
	["secret-blue-pink"] = 75829277961759,
	["secret-blue-purple"] = 139688076253513,
	["secret-blue-red"] = 81783739433146,
	["secret-blue-white"] = 134646081211688,
	["secret-blue-yellow"] = 97190261051183,
	["secret-gray-gray"] = 79438925598393,
	["secret-gray-navy"] = 129937385407954,
	["secret-gray-orange"] = 114197395821720,
	-- (Rose Hedgehog's and Sun Lion's: the owner's own models' colours baked onto the shared body, tools/blender/secret_mane.py)
	["secret-gray-pink"] = 135866855135593,
	["secret-gray-purple"] = 87610306895982,
	["secret-gray-red"] = 121852914845200,
	["secret-gray-white"] = 108472135284309,
	["secret-gray-yellow"] = 131089297850326,
	["secret-green-green"] = 131782302709548,
	["secret-green-navy"] = 78504244199951,
	["secret-green-orange"] = 139835021216581,
	["secret-green-pink"] = 135961896608268,
	["secret-green-purple"] = 90937648048204,
	["secret-green-red"] = 134183598663463,
	["secret-green-white"] = 75001796606461,
	["secret-green-yellow"] = 90401582276458,
	["secret-navy-navy"] = 128956220130239,
	["secret-navy-orange"] = 100960791556974,
	["secret-navy-pink"] = 78939905986765,
	["secret-navy-purple"] = 96108303150764,
	["secret-navy-red"] = 127512335104425,
	["secret-navy-white"] = 140063601868674,
	["secret-navy-yellow"] = 111807714284968,
	["secret-orange-orange"] = 108835797540103,
	["secret-orange-pink"] = 97192950509509,
	["secret-orange-purple"] = 116298992652302,
	["secret-orange-red"] = 90726356271671,
	["secret-orange-white"] = 135893911275047,
	["secret-orange-yellow"] = 79735965460781,
	["secret-pink-pink"] = 127009364254975,
	["secret-pink-purple"] = 124657711020684,
	["secret-pink-red"] = 98576024057113,
	["secret-pink-white"] = 87100022105333,
	["secret-pink-yellow"] = 92747602476876,
	["secret-purple-purple"] = 121029917829951,
	["secret-purple-red"] = 92681468815074,
	["secret-purple-white"] = 126691717445039,
	["secret-purple-yellow"] = 115499515678179,
	["secret-red-red"] = 71562496788717,
	["secret-red-white"] = 107204997150772,
	["secret-red-yellow"] = 107912341409908,
	["secret-white-white"] = 112685052448784,
	["secret-white-yellow"] = 99024964036568,
	["secret-yellow-yellow"] = 71734327776774,
} :: { [string]: number }
for id, image in SkinIds.Secrets do
	SkinIds.ById[id] = image
end

function SkinIds.get(id: string): number?
	return SkinIds.ById[id]
end

return SkinIds
