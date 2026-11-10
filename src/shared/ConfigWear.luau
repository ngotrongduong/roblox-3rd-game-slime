--!strict
-- Config.Wear, in a file of its own: Studio refuses a script of 200000 characters or more, so Config's
-- biggest blocks live apart. Config.luau requires this file; the game reads it as Config.Wear.

-- Drawn by the client (client/SlimeWear): each piece is a mesh made for a body one unit tall (tools/blender/wear_kit.py,
-- which writes these numbers to art/models/accessories/<kit>/wear.json), in mesh units: feet at y 0, front -Z, the slime's
-- own left -X. `at` is the piece's middle where it rests, `size` its box; it rides the skin at `anchor` as the jelly
-- squashes, hops and leans. A `flap` swings it about its anchor along `axis` (a positive turn lifts it), `degrees` each
-- way, `hz` times a second (a tail wags with one about the up axis), about a middle `bias` degrees from rest (a
-- butterfly's wings beat back from open toward each other behind the back and open again). A `twitch` flicks it now and then (Twitch), a `lag`
-- makes it trail the hop (Lag). A kit whose meshes are not uploaded yet (mesh 0) is left off.
-- (the owner, 2026-11-10: "gắn thêm chuyển động cho phần đuôi và tai")
-- A tentacle bends: its `bones` (root to tip, each its rest point and X and Y axes in mesh units) are built on it by name
-- so its skin follows them, and its `wriggle` turns each about `axis` (a positive turn lifts the tip): a wave of
-- `degrees` running out to the tip `hz` times a second, each bone `lag` radians behind the one before, and a slow curl
-- of `curl` degrees and back `curlHz` times a second; both grow toward the tip. (the owner, 2026-11-10: "co duỗi, ngọ
-- nguậy như tay bạch tuộc")
-- A `turn` (degrees about X, Y, Z, CFrame.fromEulerAnglesXYZ) turns the piece about its middle: the owner set it by hand
-- in the ear editor (skill slime-wear, `ear_editor.luau`), and `at` and `anchor` came with it. (the owner, 2026-11-10:
-- "để tôi tự thao tác rồi bạn lưu lại thông số")
type WearMotion = { axis: { number }, degrees: number, hz: number?, every: number?, bias: number? }
type WearWriggle = { axis: { number }, degrees: number, hz: number, lag: number, curl: number, curlHz: number }
type WearPiece = {
	name: string,
	mesh: number,
	size: { number },
	at: { number },
	anchor: { number },
	flap: WearMotion?,
	twitch: WearMotion?,
	lag: WearMotion?,
	bones: { { number } }?,
	wriggle: WearWriggle?,
	turn: { number }?,
}
type WearKit = { texture: string, pieces: { WearPiece } }
local Wear = {
	-- An ear's `twitch`: once in each `every` seconds, at a moment of its own, it flicks `degrees` about `axis` ({1, 0, 0}
	-- tips it back) and comes home: Out the flick's seconds, Length the whole move's.
	Twitch = { Out = 0.07, Length = 0.4 },
	-- A `lag` bends a piece about `axis` ({1, 0, 0}: ears tip back, a tail drops) as the slime climbs, the other way as it
	-- falls: `degrees` at a climb of Rise bodies a second, eased by a spring that goes half way in HalfLife seconds; a
	-- pause longer than Gap (a far slime) starts it over.
	Lag = { Rise = 4, HalfLife = 0.07, Gap = 0.5 },
	-- Secret id -> its kit
	Secrets = {
		["secret-black-blue"] = "TempestDragon",
		["secret-blue-red"] = "SteamDragon",
		["secret-navy-red"] = "FireIceChimera",
		["secret-black-gray"] = "ShadowWolf",
		["secret-black-navy"] = "MidnightRaven",
		["secret-black-orange"] = "JackOSlime",
		["secret-black-pink"] = "GothicBat",
		["secret-blue-pink"] = "CottonCandySheep",
		["secret-blue-orange"] = "SunshowerFox",
		["secret-black-purple"] = "VoidKraken",
		["secret-blue-blue"] = "CloudPegasus",
		["secret-black-yellow"] = "HoneybeeSlime",
		["secret-black-red"] = "BloodMoonBat",
		["secret-gray-purple"] = "MoonstoneGargoyle",
		["secret-blue-white"] = "FrostSwan",
		["secret-green-green"] = "ForestDryad",
		["secret-gray-red"] = "IronBoar",
		["secret-pink-yellow"] = "PeachBlossom",
		["secret-purple-purple"] = "AmethystUnicorn",
		["secret-gray-orange"] = "CopperBeetle",
		["secret-pink-pink"] = "RoseFairy",
		["secret-pink-purple"] = "DreamButterfly",
		["secret-navy-pink"] = "TwilightMoth",
		["secret-orange-yellow"] = "SunPhoenix",
		["secret-purple-yellow"] = "RoyalGriffin",
		["secret-navy-white"] = "ArcticWolf",
		["secret-orange-orange"] = "EmberTiger",
		["secret-orange-purple"] = "WitchCat",
		["secret-orange-white"] = "CreamsicleFox",
	},
	Kits = {
		-- the owner's Meshy model art/models/accessories/tempest_dragon/neon_dragon_relics.glb, uploaded as model
		-- 137031942711781 (its five MeshParts give the mesh ids)
		TempestDragon = {
			texture = "rbxassetid://83202714233801",
			pieces = {
				{
					name = "HornL",
					mesh = 96314571205165,
					size = { 0.1553, 0.2796, 0.182 },
					at = { -0.239, 0.8957, 0.0251 },
					anchor = { -0.2306, 0.7906, 0.011 },
				},
				{
					name = "HornR",
					mesh = 127323584430638,
					size = { 0.1553, 0.2796, 0.182 },
					at = { 0.239, 0.8957, 0.0251 },
					anchor = { 0.2306, 0.7906, 0.011 },
				},
				{
					name = "WingL",
					mesh = 114769919864432,
					size = { 0.4211, 0.4311, 0.3377 },
					at = { -0.4875, 0.6246, 0.484 },
					anchor = { -0.3, 0.47, 0.34 },
					-- (the owner: "đôi cánh hơi vỗ nhẹ", a soft slow beat)
					flap = { axis = { -0.6157, 0, -0.788 }, degrees = 12, hz = 0.8 },
				},
				{
					name = "WingR",
					mesh = 78544047008425,
					size = { 0.4211, 0.4311, 0.3377 },
					at = { 0.4875, 0.6246, 0.484 },
					anchor = { 0.3, 0.47, 0.34 },
					flap = { axis = { -0.6157, 0, 0.788 }, degrees = 12, hz = 0.8 },
				},
				{
					name = "Tail",
					mesh = 137066152781922,
					size = { 0.1352, 0.2177, 0.3827 },
					at = { 0.0017, 0.1752, 0.6211 },
					anchor = { 0, 0.16, 0.44 },
					-- (a slow lazy wag)
					flap = { axis = { 0, 1, 0 }, degrees = 8, hz = 0.5 },
					lag = { axis = { 1, 0, 0 }, degrees = 10 },
				},
			},
		},
		-- the owner's Meshy model art/models/accessories/steam_dragon/patriotic_dragon_cost.glb, uploaded as model
		-- 88958587355820
		SteamDragon = {
			texture = "rbxassetid://79626976517509",
			pieces = {
				{
					name = "HornL",
					mesh = 72943524244004,
					size = { 0.2944, 0.3225, 0.203 },
					at = { -0.3388, 0.8715, 0.0507 },
					anchor = { -0.2746, 0.7584, 0.04 },
				},
				{
					name = "HornR",
					mesh = 105459137410678,
					size = { 0.2944, 0.3225, 0.203 },
					at = { 0.3388, 0.8715, 0.0507 },
					anchor = { 0.2746, 0.7584, 0.04 },
				},
				{
					name = "WingL",
					mesh = 102255726396265,
					size = { 0.5098, 0.4678, 0.4121 },
					at = { -0.5241, 0.6013, 0.5068 },
					anchor = { -0.3, 0.47, 0.34 },
					flap = { axis = { -0.6157, 0, -0.788 }, degrees = 12, hz = 0.8 },
				},
				{
					name = "WingR",
					mesh = 98472723970976,
					size = { 0.5098, 0.4678, 0.4121 },
					at = { 0.5241, 0.6013, 0.5068 },
					anchor = { 0.3, 0.47, 0.34 },
					flap = { axis = { -0.6157, 0, 0.788 }, degrees = 12, hz = 0.8 },
				},
				{
					name = "Tail",
					mesh = 106763278921249,
					size = { 0.1093, 0.2103, 0.365 },
					at = { 0.0024, 0.1512, 0.6229 },
					anchor = { 0, 0.21, 0.45 },
					flap = { axis = { 0, 1, 0 }, degrees = 8, hz = 0.5 },
					lag = { axis = { 1, 0, 0 }, degrees = 10 },
				},
			},
		},
		-- the owner's model art/models/accessories/fire_ice_chimera/navy_red.glb (a red horn on the red side, a blue one
		-- on the blue side, a red-to-blue tail), uploaded as model 119200639103906
		FireIceChimera = {
			texture = "rbxassetid://131498492296218",
			pieces = {
				{
					name = "HornL",
					mesh = 108500283271458,
					size = { 0.1807, 0.3802, 0.1652 },
					at = { -0.29, 0.9051, 0.035 },
					anchor = { -0.264, 0.7683, 0.04 },
				},
				{
					name = "HornR",
					mesh = 101066443649361,
					size = { 0.1838, 0.3785, 0.1652 },
					at = { 0.2869, 0.9094, 0.0324 },
					anchor = { 0.264, 0.7682, 0.04 },
				},
				{
					name = "Tail",
					mesh = 138892483345830,
					size = { 0.1082, 0.2751, 0.4989 },
					at = { 0.0073, 0.2827, 0.6657 },
					anchor = { 0, 0.1965, 0.4303 },
					flap = { axis = { 0, 1, 0 }, degrees = 10, hz = 0.6 },
					lag = { axis = { 1, 0, 0 }, degrees = 10 },
				},
			},
		},
		-- the owner's model art/models/accessories/shadow_wolf/black_gray.glb (two wolf ears, a bushy smoky tail), uploaded
		-- as model 117979860637781
		ShadowWolf = {
			texture = "rbxassetid://120486318461151",
			pieces = {
				{
					name = "EarL",
					mesh = 70636085288680,
					size = { 0.3834, 0.4831, 0.1856 },
					at = { -0.2704, 0.9018, 0.0312 },
					anchor = { -0.356, 0.7026, 0 },
					-- (a dog's ear: a quick flick back now and then, each ear on its own)
					twitch = { axis = { 1, 0, 0 }, degrees = 18, every = 3.5 },
					lag = { axis = { 1, 0, 0 }, degrees = 12 },
				},
				{
					name = "EarR",
					mesh = 96839745024511,
					size = { 0.3808, 0.4934, 0.185 },
					at = { 0.2738, 0.901, 0.0358 },
					anchor = { 0.3559, 0.7021, 0 },
					twitch = { axis = { 1, 0, 0 }, degrees = 18, every = 3.5 },
					lag = { axis = { 1, 0, 0 }, degrees = 12 },
				},
				{
					name = "Tail",
					mesh = 87072655348517,
					size = { 0.1708, 0.2537, 0.459 },
					at = { 0.0119, 0.1979, 0.6566 },
					anchor = { 0, 0.1983, 0.4402 },
					-- (a wolf's brisk wag)
					flap = { axis = { 0, 1, 0 }, degrees = 14, hz = 0.9 },
					lag = { axis = { 1, 0, 0 }, degrees = 12 },
				},
			},
		},
		-- the owner's model art/models/accessories/cotton_candy_sheep/blue_pink.glb (pink ram horns and a cotton-candy
		-- tuft worn as a crown; the owner kept only these, 2026-11-10), uploaded as model 109726191050235
		CottonCandySheep = {
			texture = "rbxassetid://132670767775971",
			pieces = {
				{
					name = "HornL",
					mesh = 90284009845471,
					size = { 0.2499, 0.2246, 0.0884 },
					at = { -0.3141, 0.8037, 0.0113 },
					anchor = { -0.2774, 0.7619, 0 },
				},
				{
					name = "HornR",
					mesh = 73095859444618,
					size = { 0.2531, 0.2205, 0.0887 },
					at = { 0.3053, 0.8096, 0.0184 },
					anchor = { 0.2774, 0.7618, 0 },
				},
				{
					name = "Garland",
					mesh = 74304308066268,
					size = { 0.438, 0.2276, 0.2008 },
					at = { 0.0243, 0.8499, -0.1075 },
					anchor = { 0.23, 0.8, -0.05 },
				},
			},
		},
		-- the owner's model art/models/accessories/sunshower_fox/blue_orange.glb (fox ears, blue fur, orange rim, white fluff
		-- inside; a bushy tail from a blue base to an orange curl), uploaded as model 111111432845594
		SunshowerFox = {
			texture = "rbxassetid://91317140780540",
			pieces = {
				{
					name = "EarL",
					mesh = 133352440958331,
					size = { 0.2333, 0.2844, 0.0912 },
					at = { -0.3269, 0.8388, 0.0151 },
					anchor = { -0.3479, 0.7127, 0 },
					-- (small perky ears flick often)
					twitch = { axis = { 1, 0, 0 }, degrees = 18, every = 3 },
					lag = { axis = { 1, 0, 0 }, degrees = 12 },
				},
				{
					name = "EarR",
					mesh = 81193564832508,
					size = { 0.2341, 0.2801, 0.0898 },
					at = { 0.3415, 0.8285, 0.0162 },
					anchor = { 0.3475, 0.712, 0 },
					twitch = { axis = { 1, 0, 0 }, degrees = 18, every = 3 },
					lag = { axis = { 1, 0, 0 }, degrees = 12 },
				},
				{
					name = "Tail",
					mesh = 70476181876410,
					size = { 0.23, 0.3657, 0.6189 },
					at = { 0.0154, 0.1952, 0.6984 },
					anchor = { 0, 0.2, 0.41 },
					-- (a brisk bushy wag, between the wolf's and the dragon's)
					flap = { axis = { 0, 1, 0 }, degrees = 12, hz = 0.8 },
					lag = { axis = { 1, 0, 0 }, degrees = 12 },
				},
			},
		},
		-- the owner's model art/models/accessories/void_kraken/black_purple.glb (eight cosmic tentacles with glowing
		-- suckers; the owner: they grow from under the body and curl and wriggle like an octopus's arms, none sunk into
		-- it, the suckers facing down or out), rigged by tools/blender/wear_kit.py (kind `tentacle`), uploaded as model
		-- 91899436585494
		VoidKraken = {
			texture = "rbxassetid://113029184257138",
			pieces = {
				{
					name = "Arm4",
					mesh = 128179148715784,
					size = { 0.3703, 0.2037, 0.3549 },
					at = { -0.2681, 0.0606, -0.3135 },
					anchor = { -0.1543, 0.0446, -0.1839 },
					bones = {
						{ -0.1471, 0.0309, -0.2027, -0.387, 0.3748, 0.8425, -0.8425, 0.2276, -0.4883 },
						{ -0.2075, 0.0472, -0.2377, -0.2187, 0.3154, 0.9234, -0.9234, 0.239, -0.3004 },
						{ -0.3088, 0.0734, -0.2706, -0.8276, 0.1219, 0.5479, -0.5479, 0.0365, -0.8357 },
						{ -0.3596, 0.0768, -0.3482, -0.8175, 0.3614, -0.4484, 0.4484, -0.0892, -0.8894 },
						{ -0.3236, 0.0696, -0.4195, 0.3522, 0.1943, -0.9155, 0.9155, -0.2746, 0.294 },
					},
					-- (each arm on its own beat)
					wriggle = {
						axis = { 0.2589, 0.9613, -0.0941 },
						degrees = 8,
						hz = 0.45,
						lag = 0.9,
						curl = 10,
						curlHz = 0.15,
					},
				},
				{
					name = "Arm5",
					mesh = 100349152536520,
					size = { 0.5428, 0.3832, 0.2794 },
					at = { -0.4878, 0.1433, -0.0815 },
					anchor = { -0.2364, 0.0429, -0.0417 },
					bones = {
						{ -0.2509, 0.0333, -0.0732, 0.0747, 0.3075, 0.9486, -0.9486, 0.3153, -0.0275 },
						{ -0.3413, 0.0633, -0.0758, 0.3549, 0.5715, 0.7399, -0.7399, 0.6555, -0.1515 },
						{ -0.4374, 0.1485, -0.0955, 0.0444, 0.4665, 0.8834, -0.8834, 0.4313, -0.1833 },
						{ -0.5499, 0.2034, -0.1188, 0.0376, -0.2932, 0.9553, -0.9553, -0.291, -0.0517 },
						{ -0.6678, 0.1675, -0.1252, 0.972, -0.1411, 0.1878, -0.1878, -0.9472, 0.2601 },
					},
					wriggle = {
						axis = { 0.1232, -0.2548, -0.9591 },
						degrees = 8,
						hz = 0.48,
						lag = 0.9,
						curl = 10,
						curlHz = 0.15,
					},
				},
				{
					name = "Arm1",
					mesh = 111664306738205,
					size = { 0.5876, 0.4751, 0.4069 },
					at = { -0.4228, 0.2234, 0.2321 },
					anchor = { -0.2078, 0.0417, 0.12 },
					bones = {
						{ -0.2198, 0.0591, 0.1316, 0.3774, 0.0616, 0.924, -0.924, 0.0914, 0.3713 },
						{ -0.3454, 0.0715, 0.1821, 0.7272, 0.2784, 0.6275, -0.6275, 0.6402, 0.4431 },
						{ -0.4418, 0.1698, 0.2502, 0.9293, 0.2081, 0.3051, -0.3051, 0.8981, 0.3166 },
						{ -0.4939, 0.3232, 0.3042, 0.4386, 0.1501, 0.886, -0.886, 0.237, 0.3985 },
						{ -0.6241, 0.358, 0.3628, 0.9775, -0.16, 0.1371, -0.1371, -0.9771, -0.163 },
					},
					wriggle = {
						axis = { -0.3719, 0.2248, -0.9006 },
						degrees = 8,
						hz = 0.51,
						lag = 0.9,
						curl = 10,
						curlHz = 0.15,
					},
				},
				{
					name = "Arm2",
					mesh = 128303848666777,
					size = { 0.3572, 0.4146, 0.6529 },
					at = { -0.1377, 0.1781, 0.4965 },
					anchor = { -0.0821, 0.045, 0.2255 },
					bones = {
						{ -0.0934, 0.0589, 0.243, 0.9379, 0.0515, 0.3429, -0.3429, 0.2844, 0.8953 },
						{ -0.1332, 0.0919, 0.3469, 0.8432, -0.0063, 0.5376, -0.5376, -0.0215, 0.8429 },
						{ -0.2195, 0.0884, 0.4822, 0.9967, -0.034, -0.0741, 0.0741, 0.7573, 0.6489 },
						{ -0.2074, 0.212, 0.5881, 0.9992, 0.017, 0.0369, -0.0369, 0.7602, 0.6486 },
						{ -0.2134, 0.3353, 0.6933, 0.7443, -0.0788, 0.6631, -0.6631, -0.2043, 0.7201 },
					},
					wriggle = {
						axis = { -0.7385, 0.4491, -0.503 },
						degrees = 8,
						hz = 0.54,
						lag = 0.9,
						curl = 10,
						curlHz = 0.15,
					},
				},
				{
					name = "Arm3",
					mesh = 129663097083190,
					size = { 0.3919, 0.3394, 0.6255 },
					at = { 0.1931, 0.1456, 0.5007 },
					anchor = { 0.0821, 0.0959, 0.2255 },
					bones = {
						{ 0.0815, 0.0924, 0.2408, 0.8159, 0.0326, -0.5773, 0.5773, -0.1023, 0.8101 },
						{ 0.1612, 0.0783, 0.3526, 0.9999, -0.0025, -0.0116, 0.0116, 0.4164, 0.9091 },
						{ 0.1628, 0.136, 0.4787, 0.9934, -0.0157, -0.1134, 0.1134, 0.2708, 0.9559 },
						{ 0.1806, 0.1784, 0.6285, 0.7589, 0.1208, -0.6399, 0.6399, -0.3206, 0.6984 },
						{ 0.2759, 0.1307, 0.7325, 0.4837, 0.7191, -0.4989, 0.4989, -0.6949, -0.5179 },
					},
					wriggle = {
						axis = { -0.6482, -0.7056, 0.2863 },
						degrees = 8,
						hz = 0.57,
						lag = 0.9,
						curl = 10,
						curlHz = 0.15,
					},
				},
				{
					name = "Arm6",
					mesh = 137475068722289,
					size = { 0.5879, 0.2692, 0.4013 },
					at = { 0.458, 0.0916, 0.2549 },
					anchor = { 0.2078, 0.04, 0.12 },
					bones = {
						{ 0.2213, 0.0315, 0.1416, 0.5818, -0.2132, -0.7849, 0.7849, 0.4001, 0.4731 },
						{ 0.3205, 0.0821, 0.2014, 0.4113, 0.0838, -0.9076, 0.9076, -0.1291, 0.3994 },
						{ 0.4443, 0.0645, 0.2559, 0.5396, -0.128, -0.8321, 0.8321, 0.2314, 0.504 },
						{ 0.5573, 0.0959, 0.3243, 0.6781, -0.2165, -0.7024, 0.7024, 0.4723, 0.5325 },
						{ 0.6664, 0.1692, 0.407, 0.8437, 0.3782, -0.3809, 0.3809, -0.9218, -0.0715 },
					},
					wriggle = {
						axis = { -0.4516, -0.2564, 0.8546 },
						degrees = 8,
						hz = 0.6,
						lag = 0.9,
						curl = 10,
						curlHz = 0.15,
					},
				},
				{
					name = "Arm8",
					mesh = 95919529910338,
					size = { 0.6429, 0.3186, 0.3197 },
					at = { 0.528, 0.1445, -0.104 },
					anchor = { 0.2364, 0.0747, -0.0417 },
					bones = {
						{ 0.2576, 0.0822, -0.0436, 0.0797, 0.0815, -0.9935, 0.9935, -0.0879, 0.0725 },
						{ 0.3821, 0.0711, -0.0345, -0.0935, -0.3782, -0.921, 0.921, 0.3185, -0.2243 },
						{ 0.5187, 0.1184, -0.0678, 0.111, -0.7771, -0.6195, 0.6195, 0.5416, -0.5683 },
						{ 0.6248, 0.2111, -0.1651, -0.0729, -0.0071, -0.9973, 0.9973, 0.0066, -0.073 },
						{ 0.7704, 0.212, -0.1757, 0.9957, 0.0361, -0.085, 0.085, -0.7177, 0.6912 },
					},
					wriggle = {
						axis = { 0.0184, 0.6992, 0.7147 },
						degrees = 8,
						hz = 0.63,
						lag = 0.9,
						curl = 10,
						curlHz = 0.15,
					},
				},
				{
					name = "Arm7",
					mesh = 78307173896949,
					size = { 0.4751, 0.2183, 0.402 },
					at = { 0.2745, 0.0734, -0.357 },
					anchor = { 0.1543, 0.043, -0.1839 },
					bones = {
						{ 0.1538, 0.0444, -0.2123, -0.3155, -0.856, -0.4097, 0.4097, 0.2666, -0.8724 },
						{ 0.1868, 0.0659, -0.2825, -0.4732, -0.2487, -0.8451, 0.8451, 0.1427, -0.5152 },
						{ 0.2772, 0.0811, -0.3376, -0.2876, 0.0307, -0.9573, 0.9573, -0.0228, -0.2883 },
						{ 0.4332, 0.0774, -0.3846, 0.3172, -0.926, -0.2048, 0.2048, 0.2777, -0.9386 },
						{ 0.4574, 0.1102, -0.4954, -0.1818, 0.2189, 0.9587, -0.9587, 0.1775, -0.2224 },
					},
					wriggle = {
						axis = { 0.0925, 0.9518, 0.2925 },
						degrees = 8,
						hz = 0.66,
						lag = 0.9,
						curl = 10,
						curlHz = 0.15,
					},
				},
			},
		},
		-- the owner's model art/models/accessories/midnight_raven/black_navy.glb (a pair of feathered wings; the owner: the
		-- painting's wings are wrong; raised they stood too high, folded they were not what he wants: so they grow from the
		-- middle of the back and spread wide, level, the long feathers curling up at the ends, as his sketch draws a
		-- bird's open wings), uploaded as model 105971591012484
		MidnightRaven = {
			texture = "rbxassetid://95556414402224",
			pieces = {
				{
					name = "WingL",
					mesh = 82359241334531,
					size = { 0.87, 0.5971, 0.2359 },
					at = { -0.5811, 0.5339, 0.5575 },
					anchor = { -0.17, 0.53, 0.45 },
					-- (the open wing beats slowly in its own plane, the tip rising and falling)
					flap = { axis = { -0.2437, -0.1181, -0.9626 }, degrees = 10, hz = 0.6 },
				},
				{
					name = "WingR",
					mesh = 71396339618517,
					size = { 0.8679, 0.6101, 0.2312 },
					at = { 0.5819, 0.5534, 0.558 },
					anchor = { 0.17, 0.53, 0.45 },
					flap = { axis = { -0.2437, 0.1181, 0.9626 }, degrees = 10, hz = 0.6 },
				},
			},
		},
		-- the owner's model art/models/accessories/cloud_pegasus/wing_trio.glb (one white feathered wing, mirrored into a
		-- pair; the Raven's pose and beat, the owner's standard for every bird wing pair, only smaller), uploaded as model
		-- 87390925158467
		CloudPegasus = {
			texture = "rbxassetid://89482836839649",
			pieces = {
				{
					name = "WingL",
					mesh = 106819395859519,
					size = { 0.7862, 0.3704, 0.1954 },
					at = { -0.5389, 0.6181, 0.5257 },
					anchor = { -0.17, 0.53, 0.45 },
					flap = { axis = { -0.2437, -0.1181, -0.9626 }, degrees = 10, hz = 0.6 },
				},
				{
					name = "WingR",
					mesh = 127232322331656,
					size = { 0.7862, 0.3704, 0.1954 },
					at = { 0.5389, 0.6181, 0.5257 },
					anchor = { 0.17, 0.53, 0.45 },
					flap = { axis = { -0.2437, 0.1181, 0.9626 }, degrees = 10, hz = 0.6 },
				},
			},
		},
		-- the owner's model art/models/accessories/honeybee_slime/wing_trio.glb (one bee wing, mirrored into a pair, rising
		-- up and out from the upper back), uploaded as model 71604348945099
		HoneybeeSlime = {
			texture = "rbxassetid://85451487466506",
			pieces = {
				{
					name = "WingL",
					mesh = 89838154835644,
					size = { 0.3991, 0.4405, 0.1866 },
					at = { -0.4292, 0.8807, 0.351 },
					anchor = { -0.24, 0.7, 0.27 },
					-- (a bee's wings buzz: small and quick; clear, as the painting's)
					flap = { axis = { -0.2567, 0.1694, -0.9515 }, degrees = 14, hz = 3 },
					clear = 0.35,
				},
				{
					name = "WingR",
					mesh = 86802540053816,
					size = { 0.3991, 0.4405, 0.1866 },
					at = { 0.4292, 0.8807, 0.351 },
					anchor = { 0.24, 0.7, 0.27 },
					flap = { axis = { -0.2567, -0.1694, 0.9515 }, degrees = 14, hz = 3 },
					clear = 0.35,
				},
			},
		},
		-- the owner's model art/models/accessories/blood_moon_bat/wing_trio.glb (one bat wing, its two torn holes mended,
		-- mirrored into a pair, up and out from the upper shoulders), uploaded as model 113673886578474
		BloodMoonBat = {
			texture = "rbxassetid://121139310661251",
			pieces = {
				{
					name = "WingL",
					mesh = 105030148439945,
					size = { 0.5243, 0.5736, 0.1981 },
					at = { -0.4365, 0.7854, 0.2705 },
					anchor = { -0.28, 0.66, 0.25 },
					flap = { axis = { -0.2756, 0, -0.9613 }, degrees = 12, hz = 0.8 },
				},
				{
					name = "WingR",
					mesh = 101786129418069,
					size = { 0.5243, 0.5736, 0.1981 },
					at = { 0.4365, 0.7854, 0.2705 },
					anchor = { 0.28, 0.66, 0.25 },
					flap = { axis = { -0.2756, 0, 0.9613 }, degrees = 12, hz = 0.8 },
				},
			},
		},
		-- the owner's model art/models/accessories/moonstone_gargoyle/gray_purple.glb (stone bat wings out behind the
		-- shoulders, two small horns on the front of the head's top corners, a scaly arrow-tipped tail), uploaded as model
		-- 128659610713284
		MoonstoneGargoyle = {
			texture = "rbxassetid://84499624132900",
			pieces = {
				{
					name = "HornL",
					mesh = 133666424166771,
					size = { 0.171, 0.2183, 0.1067 },
					at = { -0.2748, 0.8717, -0.0862 },
					anchor = { -0.2331, 0.7792, -0.1 },
				},
				{
					name = "HornR",
					mesh = 81409518149910,
					size = { 0.1678, 0.2227, 0.1064 },
					at = { 0.2832, 0.8667, -0.1022 },
					anchor = { 0.2331, 0.7792, -0.1 },
				},
				{
					name = "WingL",
					mesh = 82014703898286,
					size = { 0.65, 0.4992, 0.3888 },
					at = { -0.5931, 0.7108, 0.4556 },
					anchor = { -0.29, 0.67, 0.28 },
					flap = { axis = { -0.5, 0, -0.866 }, degrees = 12, hz = 0.8 },
				},
				{
					name = "WingR",
					mesh = 119158942649300,
					size = { 0.6594, 0.4984, 0.3867 },
					at = { 0.5982, 0.7152, 0.4537 },
					anchor = { 0.29, 0.67, 0.28 },
					flap = { axis = { -0.5, 0, 0.866 }, degrees = 12, hz = 0.8 },
				},
				{
					name = "Tail",
					mesh = 72949607917756,
					size = { 0.1329, 0.2124, 0.6239 },
					at = { -0.0066, 0.1987, 0.7766 },
					anchor = { 0, 0.2, 0.485 },
					-- (a stone creature's tail: a slow, heavy wag)
					flap = { axis = { 0, 1, 0 }, degrees = 8, hz = 0.5 },
					lag = { axis = { 1, 0, 0 }, degrees = 10 },
				},
			},
		},
		-- the owner's model art/models/accessories/jack_o_slime/black_orange.glb (pumpkin vines and leaves; the owner: as
		-- his painting has them, growing out past the body round its outline), uploaded as model 104420315090131
		JackOSlime = {
			texture = "rbxassetid://112513356176270",
			pieces = {
				{
					name = "VineTopL",
					mesh = 137899791141278,
					size = { 0.44, 0.382, 0.3043 },
					at = { -0.4402, 0.8, -0.0151 },
					anchor = { -0.2417, 0.8, 0 },
				},
				{
					name = "VineTopR",
					mesh = 101060743461314,
					size = { 0.4299, 0.466, 0.2477 },
					at = { 0.4386, 0.8, 0 },
					anchor = { 0.2417, 0.8, 0 },
				},
				{
					name = "VineSideL",
					mesh = 102760336778778,
					size = { 0.4963, 0.6921, 0.3002 },
					at = { -0.3924, 0.351, -0.0964 },
					anchor = { -0.5267, 0.34, 0 },
				},
				{
					name = "VineSideR",
					mesh = 109032431194606,
					size = { 0.4333, 0.6883, 0.2666 },
					at = { 0.402, 0.3491, -0.0955 },
					anchor = { 0.5267, 0.34, 0 },
				},
				{
					name = "VineFootL",
					mesh = 135231371777731,
					size = { 0.4182, 0.1209, 0.3688 },
					at = { -0.2769, 0.1288, -0.3114 },
					anchor = { -0.2966, 0.12, -0.3294 },
				},
				{
					name = "VineFootR",
					mesh = 131548259721098,
					size = { 0.5516, 0.1558, 0.439 },
					at = { 0.228, 0.1332, -0.2479 },
					anchor = { 0.2966, 0.12, -0.3294 },
				},
				{
					name = "VineBack",
					mesh = 95837274024134,
					size = { 0.6241, 0.6992, 0.3456 },
					at = { -0.0032, 0.4133, 0.3959 },
					anchor = { 0, 0.42, 0.5185 },
				},
				{
					name = "LeafTop",
					mesh = 78142670396585,
					size = { 0.2187, 0.1368, 0.1232 },
					at = { -0.2072, 0.6746, 0.3623 },
					anchor = { -0.1996, 0.68, 0.3458 },
				},
				{
					name = "LeafA",
					mesh = 139024666239614,
					size = { 0.128, 0.1487, 0.1502 },
					at = { 0.4166, 0.2055, 0.2926 },
					anchor = { 0.4092, 0.2, 0.2865 },
				},
				{
					name = "LeafB",
					mesh = 87898225951103,
					size = { 0.1076, 0.1549, 0.1119 },
					at = { -0.4234, 0.2239, 0.292 },
					anchor = { -0.4149, 0.22, 0.2905 },
				},
				{
					name = "LeafC",
					mesh = 83191436666121,
					size = { 0.1932, 0.1667, 0.1266 },
					at = { 0.1878, 0.6525, 0.3711 },
					anchor = { 0.2081, 0.66, 0.3605 },
				},
			},
		},
		-- the owner's model art/models/accessories/gothic_bat/black_pink.glb (bat ears and wings, a tail from a rose to a
		-- pink tip), uploaded as model 96930448698996
		GothicBat = {
			texture = "rbxassetid://111197209449835",
			pieces = {
				{
					name = "EarL",
					mesh = 111731956855345,
					size = { 0.3638, 0.3755, 0.1382 },
					at = { -0.3519, 0.8528, -0.0011 },
					anchor = { -0.3343, 0.7204, 0 },
					twitch = { axis = { 1, 0, 0 }, degrees = 16, every = 3 },
					lag = { axis = { 1, 0, 0 }, degrees = 10 },
				},
				{
					name = "EarR",
					mesh = 88489406212673,
					size = { 0.3664, 0.3795, 0.14 },
					at = { 0.3517, 0.8513, -0.002 },
					anchor = { 0.3344, 0.7208, 0 },
					twitch = { axis = { 1, 0, 0 }, degrees = 16, every = 3 },
					lag = { axis = { 1, 0, 0 }, degrees = 10 },
				},
				{
					name = "WingL",
					mesh = 137310084417243,
					size = { 0.7067, 0.4821, 0.2204 },
					at = { -0.6589, 0.6412, 0.3938 },
					anchor = { -0.32, 0.5, 0.3 },
					flap = { axis = { -0.2756, 0, -0.9613 }, degrees = 12, hz = 0.8 },
				},
				{
					name = "WingR",
					mesh = 88069061520671,
					size = { 0.7083, 0.4746, 0.2227 },
					at = { 0.6615, 0.6546, 0.3946 },
					anchor = { 0.32, 0.5, 0.3 },
					flap = { axis = { -0.2756, 0, 0.9613 }, degrees = 12, hz = 0.8 },
				},
				{
					name = "Tail",
					mesh = 84110834357638,
					size = { 0.1221, 0.2419, 0.5623 },
					at = { 0.0143, 0.2155, 0.7477 },
					anchor = { 0, 0.2, 0.485 },
					flap = { axis = { 0, 1, 0 }, degrees = 10, hz = 0.6 },
					lag = { axis = { 1, 0, 0 }, degrees = 10 },
				},
			},
		},
		-- the owner's model art/models/accessories/frost_swan/blue_white.glb (two crystal frills up the lower front sides,
		-- their feathers out past the outline, as the painting has them; the crest on the front under the top), uploaded
		-- as model 106684279429446
		FrostSwan = {
			texture = "rbxassetid://88808323037751",
			pieces = {
				{
					name = "FrillL",
					mesh = 85681272384829,
					size = { 0.4884, 0.6275, 0.529 },
					at = { -0.39, 0.41, -0.2457 },
					anchor = { -0.39, 0.41, -0.3444 },
				},
				{
					name = "FrillR",
					mesh = 133525621422716,
					size = { 0.4674, 0.6264, 0.5276 },
					at = { 0.39, 0.41, -0.2422 },
					anchor = { 0.39, 0.41, -0.3444 },
				},
				{
					name = "Crest",
					mesh = 74536228408578,
					size = { 0.348, 0.2149, 0.2976 },
					at = { -0.0015, 0.7416, -0.3234 },
					anchor = { 0, 0.76, -0.3086 },
				},
			},
		},
		-- the owner's model art/models/accessories/forest_dryad/green_green.glb (antlers at the top corners, the leafy
		-- hair over the top of the head, blossoms, a leaf and a vine on the back, all worn as the file shapes them),
		-- uploaded as model 73928175279860
		ForestDryad = {
			texture = "rbxassetid://110529232415796",
			pieces = {
				{
					name = "AntlerL",
					mesh = 96504268539154,
					size = { 0.4071, 0.4061, 0.0898 },
					at = { -0.4316, 0.9682, 0.0195 },
					anchor = { -0.254, 0.779, 0.02 },
				},
				{
					name = "AntlerR",
					mesh = 91618738893358,
					size = { 0.4341, 0.3802, 0.0955 },
					at = { 0.4478, 0.9524, 0.0328 },
					anchor = { 0.254, 0.7788, 0.02 },
				},
				{
					name = "Hair",
					mesh = 112673097426010,
					size = { 0.8501, 0.3885, 0.4201 },
					at = { 0, 0.7723, -0.2176 },
					anchor = { -0.0292, 0.9171, -0.0836 },
				},
				{
					name = "Blossoms",
					mesh = 125452105300017,
					size = { 0.3027, 0.2258, 0.1813 },
					at = { -0.0881, 0.6202, 0.4507 },
					anchor = { -0.1432, 0.5293, 0.4674 },
				},
				{
					name = "Leaf",
					mesh = 80237581752590,
					size = { 0.1996, 0.2761, 0.1407 },
					at = { 0.3112, 0.3257, 0.4209 },
					anchor = { 0.2686, 0.2537, 0.4426 },
				},
				{
					name = "Vine",
					mesh = 92960301550157,
					size = { 0.1666, 0.3496, 0.1471 },
					at = { -0.347, 0.3312, 0.4042 },
					anchor = { -0.3321, 0.286, 0.4045 },
				},
			},
		},
		-- the owner's model art/models/accessories/iron_boar/gray_red.glb (two metal tusks in red cuffs out of the lower
		-- front either side of the mouth, tips curling up, a spiked circlet round the head, an armoured tail), uploaded as
		-- model 122177229873839
		IronBoar = {
			texture = "rbxassetid://139006485220604",
			pieces = {
				{
					name = "TuskL",
					mesh = 96127316600360,
					size = { 0.2383, 0.3365, 0.3492 },
					at = { -0.2328, 0.3497, -0.5876 },
					anchor = { -0.2201, 0.2603, -0.4408 },
				},
				{
					name = "TuskR",
					mesh = 74982988821151,
					size = { 0.2172, 0.3419, 0.3622 },
					at = { 0.2375, 0.3522, -0.5811 },
					anchor = { 0.2199, 0.2596, -0.439 },
				},
				{
					name = "Circlet",
					mesh = 121095280713482,
					size = { 0.6416, 0.3253, 0.1363 },
					at = { -0.0151, 0.8103, -0.2528 },
					anchor = { -0.32, 0.7, -0.2 },
				},
				{
					name = "Tail",
					mesh = 129865375558409,
					size = { 0.1364, 0.1932, 0.5988 },
					at = { 0.0241, 0.2325, 0.7606 },
					anchor = { 0, 0.2, 0.485 },
					flap = { axis = { 0, 1, 0 }, degrees = 10, hz = 0.7 },
					lag = { axis = { 1, 0, 0 }, degrees = 10 },
				},
			},
		},
		-- the owner's model art/models/accessories/peach_blossom/pink_yellow.glb (the crown of blossoms over the top as
		-- the painting has it, two clusters behind it, a festoon across the back, all worn as the file shapes them),
		-- uploaded as model 136863691703075
		PeachBlossom = {
			texture = "rbxassetid://78105804155910",
			pieces = {
				{
					name = "Crown",
					mesh = 102806357229282,
					size = { 0.8964, 0.3678, 0.2748 },
					at = { 0, 0.7521, -0.3215 },
					anchor = { 0.0478, 0.7526, -0.3174 },
				},
				{
					name = "ClusterL",
					mesh = 96683455502940,
					size = { 0.1727, 0.2075, 0.1872 },
					at = { -0.3572, 0.6189, 0.2629 },
					-- (the pair's two meshes touch the skin 0.006 apart: both ride the mirrored middle of their touch points)
					anchor = { -0.31, 0.649, 0.291 },
				},
				{
					name = "ClusterR",
					mesh = 79653697859969,
					size = { 0.171, 0.206, 0.1841 },
					at = { 0.3595, 0.6209, 0.2627 },
					anchor = { 0.31, 0.649, 0.291 },
				},
				{
					name = "Festoon",
					mesh = 92357861924788,
					size = { 0.4922, 0.2031, 0.0518 },
					at = { 0, 0.3994, 0.5207 },
					anchor = { 0.0034, 0.4084, 0.5206 },
				},
			},
		},
		-- the owner's model art/models/accessories/amethyst_unicorn/purple_purple.glb (the crystal horn on the forehead,
		-- the mane from behind it over the head and down the back to the feet as a horse's runs, pressed onto the body
		-- with some of it in the jelly as the owner drew it, the file's row of crystals across the lower front),
		-- uploaded as model 122773918711003
		AmethystUnicorn = {
			texture = "rbxassetid://139531407970587",
			pieces = {
				{
					name = "Horn",
					mesh = 77613199042991,
					size = { 0.1291, 0.2906, 0.2241 },
					-- (the owner: on the forehead under the top of the head, the tip leaning out forward; and a little
					-- deeper in the body: 0.04 further in along the horn than the build seated it)
					at = { -0.008, 0.8331, -0.3548 },
					anchor = { 0, 0.723, -0.2689 },
				},
				{
					name = "Mane",
					mesh = 93976332296651,
					size = { 0.3149, 1.1232, 1.0655 },
					at = { 0, 0.5278, 0.3045 },
					anchor = { 0.0669, 0.8722, 0.1092 },
				},
				{
					name = "Big",
					mesh = 135211502049708,
					size = { 0.1154, 0.1745, 0.1064 },
					at = { 0, 0.1272, -0.4924 },
					anchor = { 0.0007, 0.1859, -0.4913 },
				},
				{
					name = "GemL",
					mesh = 89540710786744,
					size = { 0.0702, 0.1003, 0.0621 },
					at = { -0.203, 0.1453, -0.4357 },
					-- (each pair's two meshes touch the skin a little apart: both ride the mirrored middle)
					anchor = { -0.2126, 0.1802, -0.4393 },
				},
				{
					name = "GemR",
					mesh = 73370305104737,
					size = { 0.068, 0.1059, 0.0613 },
					at = { 0.2022, 0.1459, -0.4364 },
					anchor = { 0.2126, 0.1802, -0.4393 },
				},
				{
					name = "TipL",
					mesh = 112782629687020,
					size = { 0.0501, 0.0581, 0.0434 },
					at = { -0.3121, 0.1274, -0.3344 },
					anchor = { -0.3205, 0.1466, -0.3401 },
				},
				{
					name = "TipR",
					mesh = 125568595581789,
					size = { 0.053, 0.0606, 0.0429 },
					at = { 0.3113, 0.128, -0.3338 },
					anchor = { 0.3205, 0.1466, -0.3401 },
				},
			},
		},
		-- the owner's model art/models/accessories/copper_beetle/gray_orange.glb (the painting's beetle shell: the cap on
		-- the head, the shield down the back, shoulder and side plates on the back and again on the front either side of
		-- the face, four claws at the feet; every plate as the file shapes it, laid the closest it lies on the body),
		-- uploaded as model 136341424878040
		CopperBeetle = {
			texture = "rbxassetid://100727174096007",
			pieces = {
				{
					name = "Cap",
					mesh = 133988484165917,
					size = { 0.3773, 0.1937, 0.2553 },
					at = { 0, 0.8726, 0.1665 },
					anchor = { 0.051, 0.78, 0.2704 },
				},
				{
					name = "FrontShoulderL",
					mesh = 132632912342045,
					size = { 0.2333, 0.2357, 0.4037 },
					at = { -0.3528, 0.6543, -0.1292 },
					-- (each pair's two plates lie at different turns: both ride the mirrored middle of their touch points)
					anchor = { -0.36, 0.692, -0.065 },
				},
				{
					name = "FrontShoulderR",
					mesh = 76359391699420,
					size = { 0.2269, 0.2464, 0.4007 },
					at = { 0.3495, 0.6579, -0.1277 },
					anchor = { 0.36, 0.692, -0.065 },
				},
				{
					name = "FrontPlateL",
					mesh = 114206870457733,
					size = { 0.2296, 0.2683, 0.3163 },
					at = { -0.3996, 0.315, -0.2948 },
					anchor = { -0.4382, 0.21, -0.2313 },
				},
				{
					name = "FrontPlateR",
					mesh = 76338661736541,
					size = { 0.2281, 0.268, 0.3181 },
					at = { 0.3996, 0.3137, -0.2947 },
					anchor = { 0.4382, 0.21, -0.2313 },
				},
				{
					name = "Shield",
					mesh = 129923510274552,
					size = { 0.4789, 0.5622, 0.2809 },
					at = { 0, 0.5251, 0.4192 },
					anchor = { 0.0003, 0.6866, 0.3936 },
				},
				{
					name = "ShoulderL",
					mesh = 88394667092395,
					size = { 0.3092, 0.2464, 0.3673 },
					at = { -0.2678, 0.6579, 0.2523 },
					anchor = { -0.306, 0.692, 0.2009 },
				},
				{
					name = "ShoulderR",
					mesh = 84631516798908,
					size = { 0.3099, 0.2357, 0.3736 },
					at = { 0.2692, 0.6543, 0.2554 },
					anchor = { 0.306, 0.692, 0.2009 },
				},
				{
					name = "PlateL",
					mesh = 77973097409271,
					size = { 0.2649, 0.2693, 0.2875 },
					at = { -0.3512, 0.3317, 0.3452 },
					anchor = { -0.4269, 0.3084, 0.2816 },
				},
				{
					name = "PlateR",
					mesh = 128297768461772,
					size = { 0.2657, 0.2695, 0.2867 },
					at = { 0.35, 0.3325, 0.3454 },
					anchor = { 0.4269, 0.3084, 0.2816 },
				},
				{
					name = "ClawL1",
					mesh = 131046716552150,
					size = { 0.1035, 0.1612, 0.1307 },
					at = { -0.4586, 0.0912, -0.1762 },
					anchor = { -0.4266, 0.1394, -0.174 },
				},
				{
					name = "ClawL2",
					mesh = 81471571447498,
					size = { 0.1459, 0.1585, 0.1054 },
					at = { -0.4398, 0.0911, 0.2472 },
					anchor = { -0.3987, 0.1329, 0.219 },
				},
				{
					name = "ClawR2",
					mesh = 139627480141592,
					size = { 0.1444, 0.1614, 0.1062 },
					at = { 0.4397, 0.0914, 0.2479 },
					anchor = { 0.3987, 0.1329, 0.219 },
				},
				{
					name = "ClawR1",
					mesh = 98107534111052,
					size = { 0.1007, 0.1621, 0.1271 },
					at = { 0.4593, 0.0914, -0.1787 },
					anchor = { 0.4266, 0.1394, -0.174 },
				},
			},
		},
		-- the owner's model art/models/accessories/rose_fairy/fantasy_wings.glb (its fairy wing, mirrored into a pair, worn
		-- on its straight inner edge down the back either side of the spine, level with the body), uploaded as model
		-- 108083969083397
		RoseFairy = {
			texture = "rbxassetid://132123962648519",
			pieces = {
				{
					name = "WingL",
					mesh = 125453199792398,
					size = { 0.6331, 0.9312, 0.2378 },
					at = { -0.42, 0.6978, 0.4391 },
					anchor = { -0.12, 0.35, 0.52 },
					-- (a butterfly's beat: each wing turns on its edge back toward the other and opens again; a fairy's
					-- quicker)
					flap = { axis = { -0.2794, 0.9315, -0.2329 }, degrees = 30, hz = 1.2, bias = 30 },
				},
				{
					name = "WingR",
					mesh = 87256932928516,
					size = { 0.6331, 0.9312, 0.2378 },
					at = { 0.42, 0.6978, 0.4391 },
					anchor = { 0.12, 0.35, 0.52 },
					flap = { axis = { -0.2794, -0.9315, 0.2329 }, degrees = 30, hz = 1.2, bias = 30 },
				},
			},
		},
		-- the owner's model art/models/accessories/dream_butterfly/fantasy_wings.glb (its butterfly wing, mirrored into a
		-- pair, worn on its straight inner edge down the back), uploaded as model 85339505056556
		DreamButterfly = {
			texture = "rbxassetid://105140380877532",
			pieces = {
				{
					name = "WingL",
					mesh = 137320455283590,
					size = { 0.6613, 0.9444, 0.2663 },
					at = { -0.4304, 0.701, 0.4251 },
					anchor = { -0.12, 0.35, 0.52 },
					-- (a butterfly's slow, wide beat)
					flap = { axis = { -0.2794, 0.9315, -0.2329 }, degrees = 30, hz = 0.8, bias = 30 },
				},
				{
					name = "WingR",
					mesh = 125511363255335,
					size = { 0.6613, 0.9444, 0.2663 },
					at = { 0.4304, 0.701, 0.4251 },
					anchor = { 0.12, 0.35, 0.52 },
					flap = { axis = { -0.2794, -0.9315, 0.2329 }, degrees = 30, hz = 0.8, bias = 30 },
				},
			},
		},
		-- the owner's model art/models/accessories/twilight_moth/fantasy_wings.glb (its moth wing, mirrored into a pair,
		-- worn on its straight inner edge down the back), uploaded as model 79629704166256
		TwilightMoth = {
			texture = "rbxassetid://136009891707826",
			pieces = {
				{
					name = "WingL",
					mesh = 125840989954803,
					size = { 0.7241, 0.929, 0.2716 },
					at = { -0.4563, 0.6848, 0.4242 },
					anchor = { -0.12, 0.35, 0.52 },
					-- (a moth's softer, sleepier beat)
					flap = { axis = { -0.2794, 0.9315, -0.2329 }, degrees = 25, hz = 0.7, bias = 25 },
				},
				{
					name = "WingR",
					mesh = 118737329562859,
					size = { 0.7241, 0.929, 0.2716 },
					at = { 0.4563, 0.6848, 0.4242 },
					anchor = { 0.12, 0.35, 0.52 },
					flap = { axis = { -0.2794, -0.9315, 0.2329 }, degrees = 25, hz = 0.7, bias = 25 },
				},
			},
		},
		-- the owner's model art/models/accessories/sun_phoenix/fantasy_wings.glb (its flame-orange feathered wing, mirrored
		-- into a pair; the Raven's pose and beat, the owner's standard for every bird wing pair), uploaded as model
		-- 115786779767394
		SunPhoenix = {
			texture = "rbxassetid://72055305970075",
			pieces = {
				{
					name = "WingL",
					mesh = 90632312139034,
					size = { 0.8827, 0.4424, 0.2285 },
					at = { -0.5444, 0.5922, 0.5375 },
					anchor = { -0.17, 0.53, 0.45 },
					flap = { axis = { -0.2437, -0.1181, -0.9626 }, degrees = 10, hz = 0.6 },
				},
				{
					name = "WingR",
					mesh = 140444306653341,
					size = { 0.8827, 0.4424, 0.2285 },
					at = { 0.5444, 0.5922, 0.5375 },
					anchor = { 0.17, 0.53, 0.45 },
					flap = { axis = { -0.2437, 0.1181, 0.9626 }, degrees = 10, hz = 0.6 },
				},
			},
		},
		-- the owner's model art/models/accessories/royal_griffin/fantasy_wings.glb (its purple and gold feathered wing,
		-- mirrored into a pair; the Raven's pose and beat), uploaded as model 131481220667166
		RoyalGriffin = {
			texture = "rbxassetid://104673014318939",
			pieces = {
				{
					name = "WingL",
					mesh = 73512483710055,
					size = { 0.8372, 0.5287, 0.2452 },
					at = { -0.5626, 0.5782, 0.5256 },
					anchor = { -0.17, 0.53, 0.45 },
					flap = { axis = { -0.2437, -0.1181, -0.9626 }, degrees = 10, hz = 0.6 },
				},
				{
					name = "WingR",
					mesh = 114237378969296,
					size = { 0.8372, 0.5287, 0.2452 },
					at = { 0.5626, 0.5782, 0.5256 },
					anchor = { 0.17, 0.53, 0.45 },
					flap = { axis = { -0.2437, 0.1181, 0.9626 }, degrees = 10, hz = 0.6 },
				},
			},
		},
		-- the owner's model art/models/accessories/arctic_wolf/fox_tail.glb (its navy and white wolf ears and tail; the
		-- file holds four Secrets' sets), uploaded as model 82109696509668
		ArcticWolf = {
			texture = "rbxassetid://128430066123954",
			pieces = {
				{
					name = "EarL",
					mesh = 135207235802339,
					size = { 0.3066, 0.2875, 0.163 },
					at = { -0.3182, 0.7974, 0.0102 },
					anchor = { -0.3854, 0.6962, 0 },
					turn = { 0, 0, -19.241 },
					-- (a wolf's ear: a quick swivel now and then, each ear on its own)
					twitch = { axis = { 0, 1, 0 }, degrees = 18, every = 3.5 },
					lag = { axis = { 1, 0, 0 }, degrees = 5 },
				},
				{
					name = "EarR",
					mesh = 77879909334130,
					size = { 0.3072, 0.2873, 0.1606 },
					at = { 0.3123, 0.8061, 0.01 },
					anchor = { 0.3818, 0.7004, 0 },
					turn = { 0, 0, 19.6352 },
					twitch = { axis = { 0, 1, 0 }, degrees = 18, every = 3.5 },
					lag = { axis = { 1, 0, 0 }, degrees = 5 },
				},
				{
					name = "Tail",
					mesh = 127964631774296,
					size = { 0.3978, 0.6405, 0.6135 },
					at = { -0.0038, 0.3533, 0.7014 },
					anchor = { 0, 0.2, 0.41 },
					-- (a wolf's brisk wag)
					flap = { axis = { 0, 1, 0 }, degrees = 14, hz = 0.9 },
					lag = { axis = { 1, 0, 0 }, degrees = 12 },
				},
			},
		},
		-- the owner's model art/models/accessories/ember_tiger/fox_tail.glb (its striped ears and tail), uploaded as model
		-- 132888134187251
		EmberTiger = {
			texture = "rbxassetid://99281636509995",
			pieces = {
				{
					name = "EarL",
					mesh = 73941534531922,
					size = { 0.2926, 0.2662, 0.1609 },
					at = { -0.339, 0.816, 0.0071 },
					anchor = { -0.3784, 0.7034, 0 },
					turn = { 0, 0, -26.3884 },
					-- (a big cat's ear: a slower, rarer flick)
					twitch = { axis = { 0, 1, 0 }, degrees = 14, every = 4.5 },
					lag = { axis = { 1, 0, 0 }, degrees = 5 },
				},
				{
					name = "EarR",
					mesh = 136421325789516,
					size = { 0.2905, 0.2702, 0.1585 },
					at = { 0.3502, 0.8223, 0.016 },
					anchor = { 0.3738, 0.7074, 0 },
					turn = { 0, 0, 26.5056 },
					twitch = { axis = { 0, 1, 0 }, degrees = 14, every = 4.5 },
					lag = { axis = { 1, 0, 0 }, degrees = 5 },
				},
				{
					name = "Tail",
					mesh = 123441253891840,
					size = { 0.3267, 0.636, 0.6235 },
					at = { -0.0019, 0.3526, 0.7354 },
					anchor = { 0, 0.2, 0.435 },
					-- (a tiger's slow swish)
					flap = { axis = { 0, 1, 0 }, degrees = 12, hz = 0.5 },
					lag = { axis = { 1, 0, 0 }, degrees = 12 },
				},
			},
		},
		-- the owner's model art/models/accessories/witch_cat/fox_tail.glb (its purple starry cat ears and tail), uploaded
		-- as model 96540291984773
		WitchCat = {
			texture = "rbxassetid://128548880469265",
			pieces = {
				{
					name = "EarL",
					mesh = 125582493660919,
					size = { 0.3035, 0.2696, 0.1613 },
					at = { -0.3503, 0.8125, 0.002 },
					anchor = { -0.3809, 0.7011, 0 },
					turn = { 0, 0, -28.5113 },
					-- (a cat's ear flicks often)
					twitch = { axis = { 0, 1, 0 }, degrees = 20, every = 3 },
					lag = { axis = { 1, 0, 0 }, degrees = 5 },
				},
				{
					name = "EarR",
					mesh = 111901571764146,
					size = { 0.3067, 0.2741, 0.1599 },
					at = { 0.3641, 0.8187, 0.0068 },
					anchor = { 0.3727, 0.7084, 0 },
					turn = { 0, 0, 26.6927 },
					twitch = { axis = { 0, 1, 0 }, degrees = 20, every = 3 },
					lag = { axis = { 1, 0, 0 }, degrees = 5 },
				},
				{
					name = "Tail",
					mesh = 94785650018115,
					size = { 0.3679, 0.6346, 0.6607 },
					at = { -0.0041, 0.3513, 0.7026 },
					anchor = { 0, 0.2, 0.39 },
					-- (a cat's lazy curl from side to side)
					flap = { axis = { 0, 1, 0 }, degrees = 12, hz = 0.6 },
					lag = { axis = { 1, 0, 0 }, degrees = 12 },
				},
			},
		},
		-- the owner's model art/models/accessories/creamsicle_fox/fox_tail.glb (its orange fox ears and white-tipped tail),
		-- uploaded as model 70560044604872
		CreamsicleFox = {
			texture = "rbxassetid://103683143568775",
			pieces = {
				{
					name = "EarL",
					mesh = 128017434678007,
					size = { 0.2898, 0.2846, 0.1636 },
					at = { -0.3727, 0.8255, 0.006 },
					anchor = { -0.3752, 0.7062, 0 },
					turn = { 0, 0, -28.8076 },
					-- (a fox's ear: a quick swivel now and then)
					twitch = { axis = { 0, 1, 0 }, degrees = 18, every = 3.5 },
					lag = { axis = { 1, 0, 0 }, degrees = 5 },
				},
				{
					name = "EarR",
					mesh = 104537285412488,
					size = { 0.2931, 0.2895, 0.1624 },
					at = { 0.364, 0.8151, 0.0093 },
					anchor = { 0.3811, 0.701, 0 },
					turn = { 0, 0, 23.3513 },
					twitch = { axis = { 0, 1, 0 }, degrees = 18, every = 3.5 },
					lag = { axis = { 1, 0, 0 }, degrees = 5 },
				},
				{
					name = "Tail",
					mesh = 127785196556869,
					size = { 0.4515, 0.6926, 0.6611 },
					at = { -0.0038, 0.3451, 0.6777 },
					anchor = { 0, 0.2, 0.37 },
					-- (a fox's bushy wag)
					flap = { axis = { 0, 1, 0 }, degrees = 14, hz = 0.8 },
					lag = { axis = { 1, 0, 0 }, degrees = 12 },
				},
			},
		},
	} :: { [string]: WearKit },
}

return Wear
