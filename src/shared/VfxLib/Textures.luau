-- Every picture an effect of the library may wear, by KEY. An effect names keys, never ids, so that a game whose
-- creator account holds its own uploads can swap them in one place (`VfxLib.setup{ textures = { key = id } }`).
--
-- An entry:
--   id     the asset id (a number) as uploaded under the owner's account (Mue_you), or an engine path ("rbxasset://...")
--   owner  the owner's own art (Goo Lineage's battle pictures, its icons): never recoloured, never redrawn; an effect may
--          tint it only where `tint` says the game it came from does so
--   tint   (owner art) the source game tints this one (a silver star that is every glint): a role colour may be laid on it
--   black  drawn on a BLACK background, not a transparent one: it must be drawn additive (LightEmission 1, dimmed by its
--          Brightness instead), or the black shows as a dark square round every particle (Egg Heist, the owner saw it round
--          the auras, 2026-10-19; measured on all 335 pack textures: more than 30% of the pixels opaque black). Never in an
--          ImageLabel or a Decal, which cannot add.
--   from   where it came from (the licence is in textures/LICENCES.md)
--
-- Asset privacy: images stay Open Use while the creator's Asset Privacy is off, so any experience can use these ids.
-- If it is ever turned on, grant each experience or re-upload from textures/src and pass the new ids to setup.
local Textures = {}

local ENGINE = "engine (Roblox's own content folder)"
local GL_BATTLE = "Goo Lineage: the owner's battle art (reference/goo-lineage-web/assets/battlefx-*.png)"
local GL_ICON = "Goo Lineage: the owner's icons (Config.Ui.Icons)"
local EH_PACK = "Egg Heist assets/Vfx: a free Creator Store pack in the owner's inventory, rebuilt without scripts"
local FLOOR_ART = "ChatGPT picture drawn for the owner's library (textures/floor/)"
local WING_ART = "ChatGPT picture drawn for the owner's library (textures/wings/)"
local SKILL_ART = "ChatGPT picture drawn for the owner's library (textures/fx/, textures/wings/)"
local EC_ART = "rendered for the owner's library by EffectCraft from a recipe (textures/fx/, tools/effectcraft/)"
local SLIME_WING_ART =
	"ChatGPT picture drawn for the owner's library in the style of the owner's Goo Lineage slime art (textures/wings/)"

Textures.Images = {
	-- Roblox's own particles: always there, no upload
	engine_sparkle = { id = "rbxasset://textures/particles/sparkles_main.dds", from = ENGINE },
	engine_smoke = { id = "rbxasset://textures/particles/smoke_main.dds", from = ENGINE },

	-- Goo Lineage: the owner's battle art, uploaded 2026-11-03 (Config.Zombies.View.Fx.Textures)
	burstShock = { id = 133346055977942, owner = true, from = GL_BATTLE },
	moteShock = { id = 138447116339479, owner = true, from = GL_BATTLE },
	slashArc = { id = 95547681540742, owner = true, from = GL_BATTLE },
	sparkStar = { id = 106004463491821, owner = true, tint = true, from = GL_BATTLE }, -- silver: tinted in the hatch reveal
	holyHit = { id = 123273947779821, owner = true, from = GL_BATTLE },
	shockwave = { id = 94188471939456, owner = true, tint = true, from = GL_BATTLE }, -- the Material reveal tints it
	ring = { id = 91239577409299, owner = true, from = GL_BATTLE },
	ringShock = { id = 113076278171097, owner = true, from = GL_BATTLE },
	groundCrack = { id = 77360860823212, owner = true, from = GL_BATTLE },
	biteMarks = { id = 114773166164920, owner = true, from = GL_BATTLE },
	clawMarks = { id = 103284846741774, owner = true, from = GL_BATTLE },
	gooBlob = { id = 82520552927313, owner = true, from = GL_BATTLE },
	acidSplat = { id = 108936202345260, owner = true, from = GL_BATTLE },
	acidDrop = { id = 135178961338375, owner = true, from = GL_BATTLE },
	ringAcid = { id = 117408949400540, owner = true, from = GL_BATTLE },
	burstAcid = { id = 76291902623074, owner = true, from = GL_BATTLE },
	spore = { id = 76735351216148, owner = true, from = GL_BATTLE },
	burstArcane = { id = 75506448951291, owner = true, from = GL_BATTLE },
	ringArcane = { id = 70489654789239, owner = true, from = GL_BATTLE },
	moteArcane = { id = 118302010408844, owner = true, from = GL_BATTLE },
	healCross = { id = 110992077814805, owner = true, from = GL_BATTLE },
	-- (uploaded 2026-11-07 for the Secret slimes' wings, 256 px: textures/goo/)
	honey_drop = { id = 120943377828614, owner = true, from = GL_BATTLE }, -- battlefx-honey-drop.png
	rain_streak = { id = 118937264670762, owner = true, from = GL_BATTLE }, -- fx-rain-streak.png

	-- Goo Lineage: the owner's icons, drawn as particles untinted (the stat buffs, coins)
	icon_attack = { id = 99675585132127, owner = true, from = GL_ICON }, -- equip-sword.png
	icon_defence = { id = 74089620499791, owner = true, from = GL_ICON }, -- equip-shield.png
	icon_speed = { id = 96175650939419, owner = true, from = GL_ICON }, -- stat-speed.png (the bolt)
	icon_hp = { id = 113610467784918, owner = true, from = GL_ICON }, -- stat-hp.png (the heart)
	icon_coins = { id = 127025864156501, owner = true, from = GL_ICON }, -- mat-coins.png

	-- Egg Heist: ChatGPT's four snowflakes on black (Art.Images.fx_snowflakes), a 2 x 2 sheet
	fx_snowflakes = { id = 131500085377698, black = true, from = "Egg Heist: ChatGPT picture for the owner (Art)" },

	-- Egg Heist: the pictures of the trail bands (TrailLooks.STREAKS) and of its code-made particles (TrailLooks.TEXTURES)
	streak_mist = { id = 10365550877, black = true, from = EH_PACK .. " (Beams/Wind-01)" },
	streak_wisp = { id = 9541055154, black = true, from = EH_PACK .. " (Beams/Wind-01)" },
	streak_slash = { id = 15412407507, from = EH_PACK .. " (v_Model, its Trail)" },
	streak_crackle = { id = 12781800668, black = true, from = EH_PACK .. " (Auras/RNG-Aura-02)" },
	star4_drift = { id = 17087151546, from = EH_PACK .. " (Auras/RNG-Aura-02 Stars)" }, -- tiny 4-point stars
	fire_flipbook = { id = 16676455805, from = EH_PACK .. " (Auras/Fire-Aura-01, 4 x 4)" },
	smoke_soft = { id = 14595543880, from = EH_PACK .. " (Beams/Wind-01 Smoke1)" },

	-- The auras' floor art: ChatGPT's white glyph circles on black, drawn for the library 2026-11-07, one aura each
	-- (textures/floor/, tools/chatgpt/prepare_floor.py)
	floor_storm = { id = 76619451767562, black = true, from = FLOOR_ART }, -- lightning spokes, a crackling core
	floor_hellfire = { id = 94276349588941, black = true, from = FLOOR_ART }, -- flame tongues, horns, thorns
	floor_seraph = { id = 132509246080722, black = true, from = FLOOR_ART }, -- feather wreath, light rays, a starburst
	floor_frost = { id = 121052874628549, black = true, from = FLOOR_ART }, -- snowflake-crystal branches, a gem
	floor_sun = { id = 76293245597333, black = true, from = FLOOR_ART }, -- a corona of rays, sun discs, an eclipse
	floor_starfall = { id = 114926455086315, black = true, from = FLOOR_ART }, -- constellations, shooting stars, a star
	floor_inferno = { id = 98515243197047, black = true, from = FLOOR_ART }, -- a wheel of flame tongues, a fire sun
	floor_snow = { id = 105554355486394, black = true, from = FLOOR_ART }, -- a ring of snowflakes, wind curls
	floor_circuit = { id = 120509457131906, black = true, from = FLOOR_ART }, -- circuit traces, chips, a hex core
	floor_virus = { id = 80822659219182, black = true, from = FLOOR_ART }, -- hazard stripes, glitch blocks, germs
	floor_tide = { id = 128388524086939, black = true, from = FLOOR_ART }, -- curling waves, bubbles, a moon on ripples
	floor_gale = { id = 132718339327816, black = true, from = FLOOR_ART }, -- a whirlwind of streaks, leaves, clouds
	floor_sakura = { id = 134241700739354, black = true, from = FLOOR_ART }, -- a blossom wreath, drifting petals
	floor_nebula = { id = 101265158793025, black = true, from = FLOOR_ART }, -- a spiral galaxy, planets on an orbit
	floor_lunar = { id = 95823952979831, black = true, from = FLOOR_ART }, -- the moon's phases round a full moon
	floor_blood = { id = 107702465855979, black = true, from = FLOOR_ART }, -- bats, thorny roses, a bat across the moon
	floor_twilight = { id = 133180891691429, black = true, from = FLOOR_ART }, -- a fan of feathers, a moon facing a sun
	floor_aether = { id = 83019393544766, black = true, from = FLOOR_ART }, -- two hexagons, crystals, an orb
	floor_thunder = { id = 121808573489571, black = true, from = FLOOR_ART }, -- broken arc rings, sparks, a plasma ball
	floor_halo = { id = 91727967534464, black = true, from = FLOOR_ART }, -- a colonnade of light, rays, halo rings
	floor_nova = { id = 90581117069694, black = true, from = FLOOR_ART }, -- a supernova burst, rays, debris shards
	floor_prism = { id = 94709845938286, black = true, from = FLOOR_ART }, -- crystal prisms round a cut gem
	floor_atom = { id = 81850143878415, black = true, from = FLOOR_ART }, -- three electron orbits round a nucleus
	floor_violet = { id = 115144287571199, black = true, from = FLOOR_ART }, -- a spiral of iris petals, a blossom core

	-- The wings' pictures: ChatGPT's single RIGHT wing seen from behind, its root at the middle of the left edge, drawn
	-- for the library 2026-11-07, one wing effect each; stored TRANSPOSED for a flat Beam from root to tip
	-- (textures/wings/, tools/chatgpt/prepare_wing.py)
	wing_angel = { id = 72802240052539, black = true, from = WING_ART }, -- soft layered white feathers
	wing_seraph = { id = 134983143037017, black = true, from = WING_ART }, -- three tiers of long feathers, sparkles
	wing_phoenix = { id = 75723738134859, black = true, from = WING_ART }, -- feathers of curling flame tongues
	wing_frost = { id = 103260704184342, black = true, from = WING_ART }, -- ice shards and icicles, frost ferns
	wing_thunder = { id = 122324117391444, black = true, from = WING_ART }, -- branching lightning in a feather shape
	wing_fairy = { id = 88061897490534, black = true, from = WING_ART }, -- two veined see-through lobes
	wing_cherub = { id = 71385652161579, black = true, from = WING_ART }, -- a plump baby wing of 4 round feathers
	wing_ember = { id = 120112973298487, black = true, from = WING_ART }, -- a chubby wing of round flame licks
	wing_gem = { id = 130138188813664, black = true, from = WING_ART }, -- 3 faceted crystal gems, a star glint
	wing_spark = { id = 79281741924131, black = true, from = WING_ART }, -- 3 chunky zigzag bolts from a bright root
	-- (keyed from magenta, greyscale with alpha: solid wings drawn over the scene, not added)
	wing_bat = { id = 140315061588972, from = WING_ART }, -- finger bones, a scalloped leathery membrane, a claw
	-- (wing_bat cut at its wrist for the keyed rig, the seam slanting between its first two fingers:
	-- tools/chatgpt/split_wing.py wing_bat 0.45 0.37 0.04)
	wing_bat_arm = { id = 118473491842562, from = WING_ART }, -- the arm, the first finger, the inner membrane
	wing_bat_hand = { id = 95523101307312, from = WING_ART }, -- the wrist, the thumb claw, three fingers
	wing_leaf = { id = 117437671760662, from = WING_ART }, -- six long veined leaves fanning from the root
	wing_imp = { id = 101807439220681, from = WING_ART }, -- a chubby bat wing, 2 rounded bones, 2 scallops
	wing_imp_arm = { id = 100723044146049, from = WING_ART }, -- (split_wing.py wing_imp 0.47 0.37 0.03)
	wing_imp_hand = { id = 75563156110212, from = WING_ART },
	wing_butterfly = { id = 101266146963186, from = WING_ART }, -- two round lobes, spots and a pale band
	-- (a glow wing's solid body: its brightness made alpha, drawn normal under the added glow so a bright sky keeps it)
	wing_seraph_body = { id = 91830187796275, from = WING_ART }, -- wing_seraph as a solid body
	wing_phoenix_body = { id = 87556134822156, from = WING_ART }, -- wing_phoenix as a solid body
	wing_frost_body = { id = 121746763458180, from = WING_ART }, -- wing_frost as a solid body
	-- (Goo Lineage's winged Secret slimes: drawn in FULL COLOUR in the owner's slime art style, that slime's own picture
	-- as the style lock, keyed from green; worn untinted, role "keep": docs/vfx/plans/2026-11-07-slime-wings.md)
	wing_sun_phoenix = { id = 125204748532278, from = SLIME_WING_ART }, -- orange-gold layered flame feathers
	wing_gothic_bat = { id = 122549917968973, from = SLIME_WING_ART }, -- black bones, hot-pink membrane, rose vines
	wing_dream_butterfly = { id = 126844707518885, from = SLIME_WING_ART }, -- pink-lilac lobes, stars, dream swirls
	wing_rose_fairy = { id = 139766932741604, from = SLIME_WING_ART }, -- rose-petal lobes, gold filigree, a pink gem
	wing_lovebird = { id = 109513294434539, from = SLIME_WING_ART }, -- chubby red feathers, white-pink inner, a heart
	wing_twilight_moth = { id = 90828050100022, from = SLIME_WING_ART }, -- navy moth lobes, pink rims, crescent moons
	wing_royal_griffin = { id = 113556082774751, from = SLIME_WING_ART }, -- purple eagle feathers, gold tips and crest
	wing_star_owl = { id = 92820335705577, from = SLIME_WING_ART }, -- navy owl feathers, yellow stars, gold edge
	wing_honeybee = { id = 91549270646831, from = SLIME_WING_ART }, -- two pale honey-amber lobes, dark veins
	wing_fire_dragon = { id = 108695339438678, from = SLIME_WING_ART }, -- orange-red membrane, flame marks, a claw
	wing_rose_dragon = { id = 99271705132662, from = SLIME_WING_ART }, -- crimson petal membrane, thorny bones, roses
	wing_blood_moon_bat = { id = 83234994252942, from = SLIME_WING_ART }, -- deep crimson membrane, crescent moons
	wing_midnight_raven = { id = 71742131857925, from = SLIME_WING_ART }, -- blue-violet starry feathers
	wing_moonstone_gargoyle = { id = 73403857214768, from = SLIME_WING_ART }, -- stone bat wing, violet glowing cracks
	wing_cloud_pegasus = { id = 87002587421462, from = SLIME_WING_ART }, -- fluffy white feathers, cloud puff root
	wing_frost_swan = { id = 87110595868148, from = SLIME_WING_ART }, -- white crystal feathers, icy-blue tips
	wing_thunderbird = { id = 140158900770673, from = SLIME_WING_ART }, -- golden bolt feathers, electric-blue root
	wing_tempest_dragon = { id = 100436130534785, from = SLIME_WING_ART }, -- black-blue storm membrane, cyan bolts
	-- (the bat-type slime wings cut at their wrists for the keyed bat beat: split_wing.py <name> <seam top> <bottom>
	-- <band>, the seam between two fingers)
	wing_gothic_bat_arm = { id = 136433288161743, from = SLIME_WING_ART }, -- (0.33 0.40 0.03)
	wing_gothic_bat_hand = { id = 103682105613919, from = SLIME_WING_ART },
	wing_blood_moon_bat_arm = { id = 78481688260754, from = SLIME_WING_ART }, -- (0.30 0.30 0.03)
	wing_blood_moon_bat_hand = { id = 94250195415055, from = SLIME_WING_ART },
	wing_moonstone_gargoyle_arm = { id = 111878741812896, from = SLIME_WING_ART }, -- (0.67 0.40 0.025)
	wing_moonstone_gargoyle_hand = { id = 124950288069994, from = SLIME_WING_ART },
	wing_rose_dragon_arm = { id = 73042969592121, from = SLIME_WING_ART }, -- (0.24 0.44 0.03)
	wing_rose_dragon_hand = { id = 130346588313088, from = SLIME_WING_ART },
	wing_fire_dragon_arm = { id = 95688205527316, from = SLIME_WING_ART }, -- (0.26 0.44 0.03)
	wing_fire_dragon_hand = { id = 119425740701213, from = SLIME_WING_ART },
	wing_tempest_dragon_arm = { id = 96721618228755, from = SLIME_WING_ART }, -- (0.23 0.43 0.025)
	wing_tempest_dragon_hand = { id = 116159191061022, from = SLIME_WING_ART },
	-- (the machines' wings, 2026-11-07: steampunk game art in FULL COLOUR on green, keyed and worn untinted
	-- (prepare_wing.py --colour); the gears cut one each from a sheet (prepare_parts.py), turned flat on the wing)
	wing_jet = { id = 103804811099632, from = WING_ART }, -- riveted steel plates, copper trim, 2 thruster nozzles
	wing_clockwork = { id = 97061103161641, from = WING_ART }, -- a brass strut, 4 hub discs, brass feather blades
	wing_blade = { id = 132690163956133, from = WING_ART }, -- one slender steel blade, copper rim, a brass pivot hub
	gear_spoked = { id = 108580529908256, from = WING_ART }, -- a brass gear, 12 teeth, 6 spokes
	gear_holed = { id = 104239957557125, from = WING_ART }, -- a brass gear, 10 teeth, a copper face with holes
	gear_small = { id = 109635743775972, from = WING_ART }, -- a brass gear, 8 teeth, a copper face
	-- (the special wings, 2026-11-08: docs/vfx/plans/2026-11-08-special-wings.md. The sword in full colour on green,
	-- kept in a thin band (prepare_wing.py --colour --band 0.32); the rune and hologram wings white on black, tinted, each
	-- over its solid body copy)
	wing_sword = { id = 93273355596772, from = WING_ART }, -- a silver longsword, a gold winged guard, a blue gem
	wing_rune = { id = 134670599375467, black = true, from = WING_ART }, -- feathers of glyph line-art, a sigil root
	wing_rune_body = { id = 117395556933821, from = WING_ART }, -- wing_rune as a solid body
	wing_holo = { id = 98839948970497, black = true, from = WING_ART }, -- a wireframe of triangles and nodes
	wing_holo_body = { id = 134739251742214, from = WING_ART }, -- wing_holo as a solid body
	-- (the rune wing's circles, turned flat on it as gears: tools/chatgpt/prepare_rune.py; the lit glyph is the outer
	-- ring's top glyph cut out and made to glow, so it lies on the ring)
	rune_ring_outer = { id = 106289384881559, black = true, from = WING_ART }, -- two rings, eight glyphs between
	rune_ring_inner = { id = 140551633754717, black = true, from = WING_ART }, -- a ring, an eight-pointed star sigil
	rune_ring_lit = { id = 133489499771091, black = true, from = WING_ART }, -- rune_ring_outer's top glyph, glowing
	rune_flakes = { id = 86817255509072, black = true, from = WING_ART }, -- four single glyphs, a 2 x 2 sheet
	holo_bits = { id = 92802319996599, black = true, from = WING_ART }, -- pixels, a shard, a glitch bar, a hexagon (2 x 2)
	-- (the machines' particles: textures/fx/, prepare_glow.py)
	jet_plume = { id = 127150988081622, black = true, from = WING_ART }, -- a jet's exhaust, shock diamonds, licks
	steam_puff = { id = 109925013347705, from = WING_ART }, -- a billowing puff, its brightness made alpha

	-- The combat skills, wave 1 (2026-11-08: docs/vfx/plans/2026-11-08-skills-wave-1.md), on black, added. The fire
	-- pictures in FULL COLOUR (prepare_glow.py --colour: their yellow core and red tips are the look, worn untinted)
	skill_firebird = { id = 106666448251224, black = true, from = SKILL_ART }, -- a phoenix of flame seen from behind
	fire_flower = { id = 70995442250224, black = true, from = SKILL_ART }, -- eight petals of flame from above
	-- (an explosion drawn sharp at 1024: prepare_glow.py --big --colour; the packs' 4 x 4 fireball blurred at 12 studs)
	fire_blast = { id = 132208746845727, black = true, from = SKILL_ART }, -- a billowing fireball, a white-hot core
	fire_break = { id = 139009934958164, black = true, from = SKILL_ART }, -- the fireball breaking to a ring of tongues
	fire_shock = { id = 132543648248112, black = true, from = SKILL_ART }, -- a thin ring of flame from above
	-- (the packs' explosion_real_flip redrawn sharp by ChatGPT from the old sheet, the same 16 frames: four Grid2x2
	-- sheets of 512 px frames, played one after another; prepare_flip.py, keyed off magenta, full colour, not added)
	explosion_sharp_1 = { id = 129830265084395, from = SKILL_ART }, -- frames 1-4: a spark grows to a white-hot ball
	explosion_sharp_2 = { id = 85386062836353, from = SKILL_ART }, -- frames 5-8: the big ball, bits flying, golden
	explosion_sharp_3 = { id = 126267813442349, from = SKILL_ART }, -- frames 9-12: cooling to brown, smoke patches
	explosion_sharp_4 = { id = 84301493318306, from = SKILL_ART }, -- frames 13-16: dark smoke breaking to scraps
	-- (the packs' ring_fat_flip redrawn smooth by ChatGPT from the old sheet, the same 16 frames in one Grid4x4: its
	-- ring edges were jagged pixels; prepare_glow.py --big, white on black, tinted)
	ring_fat_sharp = { id = 116688253321871, black = true, from = SKILL_ART }, -- a fat ring thinning to a line, 4 x 4
	-- (one sword of light, white, stored transposed for a Beam from the hilt to the point: prepare_wing.py --band 0.30)
	light_sword = { id = 76155967329044, black = true, from = SKILL_ART }, -- a winged cross-guard, a long blade
	-- (floor art of its own, white on black, tinted: prepare_floor.py)
	floor_holy = { id = 105110376658675, black = true, from = SKILL_ART }, -- eight swords to a star, feathers, glyphs
	floor_void = { id = 115096348888339, black = true, from = SKILL_ART }, -- six smoky spiral arms, a black centre
	void_rim = { id = 105921695661976, black = true, from = SKILL_ART }, -- a black hole's bright rim, streams curling in

	-- The combat skills, wave 2 (2026-11-08: ice, earth, arcane), in FULL COLOUR, worn untinted. Spikes stored for a
	-- Beam from the base to the tip (prepare_beam.py --flip: the base is the top row)
	ice_spear = { id = 72666112748407, black = true, from = SKILL_ART }, -- a glowing ice spear, tip up (a particle)
	ice_spike = { id = 120518095597908, black = true, from = SKILL_ART }, -- a tall jagged ice spike, base on top
	stone_spike = { id = 97688961700042, from = SKILL_ART }, -- a rock spike split by lava veins, base on top (keyed)
	-- (a band of pink and violet ribbons wound round a white core, tiling along its length: a Beam that flows)
	arcane_band = { id = 81657266245577, black = true, from = SKILL_ART }, -- arcane energy, along the length
	-- (floor art in colour, 1024: prepare_glow.py --big --colour)
	floor_icelance = { id = 102342904294305, black = true, from = SKILL_ART }, -- a frost circle, snowflake, ice glyphs
	floor_arcane = { id = 135455192576039, black = true, from = SKILL_ART }, -- a pink hexagram, moons, a rune ring
	-- (wave 3, in full colour on black: the flying meteor, its top row behind)
	-- (the whole jade dragon seen from above, one picture cut in four slices top to bottom, its head first, each fading
	-- into the next over the rows they share: prepare_beam.py --slices=4)
	dragon_whole_1 = { id = 115889794677527, black = true, from = SKILL_ART }, -- its head, antlers, whiskers, mane
	dragon_whole_2 = { id = 88559866453092, black = true, from = SKILL_ART }, -- its front claws, scaled back, spine fin
	dragon_whole_3 = { id = 138621478578037, black = true, from = SKILL_ART }, -- its back, hind claws
	dragon_whole_4 = { id = 91342566566278, black = true, from = SKILL_ART }, -- its tail, a jade fin at the tip
	-- (the golden dragon of aura.golden_dragon, drawn from the side lying left to right, head on the right, its back up;
	-- one whole picture for a Trail, turned: prepare_beam.py --turn --length=1024, so its head is the top row and its
	-- back the left edge)
	dragon_side = { id = 80488500576338, black = true, from = SKILL_ART }, -- gold scales, cream belly, two clawed legs
	meteor_fall = { id = 128463314612190, black = true, from = SKILL_ART }, -- a burning rock, violet-fire tail on top
	-- (wave 4, 2026-11-08: tide, sanctuary, chains, time stop) a breaking wave drawn in full colour lying left to right,
	-- turned for a Beam (prepare_beam.py --turn --length=1024): its length the wave's width, its crest at one side
	wave_wall = { id = 91054925520908, black = true, from = SKILL_ART }, -- turquoise water, white foam crest, spray
	-- (white on black, tinted: prepare_glow.py; the floors prepare_floor.py)
	glass_sphere = { id = 110470050588728, black = true, from = SKILL_ART }, -- a glass bubble, bright rim, 12 ticks
	chain_loop = { id = 71352528460304, black = true, from = SKILL_ART }, -- a closed ring of 16 links from above
	leaves_glow = { id = 86175108378193, black = true, from = SKILL_ART }, -- four veined leaves (2 x 2)
	gears_silver = { id = 102734646647357, black = true, from = SKILL_ART }, -- four gears, one a toothed dial (2 x 2)
	floor_sanctuary = { id = 85580612294229, black = true, from = SKILL_ART }, -- a leaf wreath, a six-petal flower, a cross
	floor_judgement = { id = 70486604915504, black = true, from = SKILL_ART }, -- a chain ring, four padlocks, a keyhole
	-- The summoning skills (2026-11-09): the beasts called, seen from BEHIND as the player sees them from behind the
	-- caster. Spirits drawn in light on black, added; solid ones keyed off magenta, full colour. The standing ones are
	-- stored for a Beam from the feet (top row) up (prepare_beam.py --flip), so `emerge` brings the head out first.
	summon_wolf = { id = 127242025167802, black = true, from = SKILL_ART }, -- an ice-blue spirit wolf leaping away (a particle)
	summon_guardian = { id = 130276948979801, black = true, from = SKILL_ART }, -- a gold knight of light: tower shield, sword
	summon_golem = { id = 121447514135142, from = SKILL_ART }, -- a golem of rock slabs, amber rune cracks, moss
	-- (keyed by a plain key that keeps purple, prepare_beam.py --plain --flip: prepare_flip's fire key turns it green)
	summon_tentacle = { id = 70716005411734, from = SKILL_ART }, -- a purple-black tentacle, glowing violet suckers
	-- The Secret slimes' signatures (2026-11-10, Goo Lineage): keyed off magenta by unmixing it out of every pixel, so
	-- soft and see-through edges keep their colour; one scale for a sheet's four frames (tools/chatgpt/unmix_magenta.py).
	-- Solid, drawn normal: the glow leaves (leaves_glow) vanish on a bright sky or floor.
	leaves_solid = { id = 103435788705754, from = SKILL_ART }, -- four leaves, light grey: maple, oak, birch, holly (2 x 2)
	butterfly_flip = { id = 91112461922690, from = SKILL_ART }, -- a light-grey butterfly from above flapping, 2 x 2 loop
	-- (full colour, worn untinted)
	bee_flip = { id = 97180849526015, from = SKILL_ART }, -- a chubby honeybee from the side, wings beating, 2 x 2 loop
	-- The signatures' second round (2026-11-10, the owner: "small, not loud, but truly fitting and beautiful"): one
	-- picture each, 512, keyed the same way. White and light grey, tinted:
	heart_puffy = { id = 86067573132905, from = SKILL_ART }, -- a chubby glossy heart
	blossom_five = { id = 127785005425047, from = SKILL_ART }, -- a five-petal cherry blossom from above, notched petals
	rose_top = { id = 121999667549833, from = SKILL_ART }, -- a rose bloom from above, a spiral of petals
	koi_top = { id = 138089618563309, from = SKILL_ART }, -- a koi from above, head UP (VelocityParallel: it swims head first)
	bubble_gloss = { id = 138130484403547, from = SKILL_ART }, -- a see-through glass bubble, a bright shine
	droplet_gloss = { id = 107460170148223, from = SKILL_ART }, -- a glossy water drop, point UP (falling: rotation 0;
	-- a VelocityParallel spray: rotation 180, so the point trails)
	down_feather = { id = 114074618716227, from = SKILL_ART }, -- a fluffy little down feather
	gem_round = { id = 84274586076811, from = SKILL_ART }, -- a faceted round gem from above
	gust_curl = { id = 107418049747886, from = SKILL_ART }, -- a gust of wind: three soft curling strokes
	moth_flip = { id = 137535747251006, from = SKILL_ART }, -- a fuzzy moth from above flapping (open, half, shut, half), 2 x 2
	-- (full colour, worn untinted)
	daisy_colour = { id = 80302072044730, from = SKILL_ART }, -- a white daisy, a yellow middle
	lemon_slice = { id = 103054104053485, from = SKILL_ART }, -- a lemon slice
	peach_blossom = { id = 110052652170210, from = SKILL_ART }, -- a pink peach blossom, yellow stamens
	peppermint_candy = { id = 114832500049402, from = SKILL_ART }, -- a red-and-white peppermint swirl candy
	-- (2026-11-11, the owner: candies raining on the Peppermint Slime, none red or white)
	candy_rain_flip = { id = 87877814374887, from = SKILL_ART }, -- four candies: lemon, blue swirl, gumdrop, lollipop (2 x 2)

	-- Rendered by EffectCraft from a recipe (2026-11-09, tools/effectcraft/recipes/<key>.json, flipbook.ps1 -Black):
	-- white on black, tinted, 4 x 4
	ether_bloom = { id = 120063426779722, black = true, from = EC_ART }, -- a flash, energy strings opening to a ring
	-- The physical skills (2026-11-09): steel, dust and impact, not magic
	impact_burst = { id = 112419349280905, black = true, from = EC_ART }, -- a white pop, radial speed lines flying out
	-- (white, its brightness its alpha: flipbook.ps1 -Luma; drawn normal, tinted the colour of the ground's dust)
	dust_ring = { id = 117410698274537, from = EC_ART }, -- a puff of grainy dust hollowing into a ring, 4 x 4
	-- (a Beam's strip: rows along the length, a hot edge on the right, streaks fading to the left; -Grid 1 -Cell 512)
	slash_steel = { id = 124461862433137, black = true, from = EC_ART }, -- a blade's swept steel, one hard bright edge
	-- (full colour, worn untinted: a Beam from the nock (top row) to the point; drawn 1 : 4, stored square)
	arrow_steel = { id = 137131755131773, from = EC_ART }, -- an arrow: white vanes with a red band, wood, steel head
	-- (the same way: a Beam from the vanes (top row) to the head; drawn 1 : 4, stored square)
	bolt_steel = { id = 137919394637748, from = EC_ART }, -- a crossbow bolt: dark wood, iron vanes, brass bands, broad head
}

-- The pictures of the packs that the baker met (tools/bake.luau writes them here: `lune run tools/bake.luau`). Each is
-- named by what it shows, looked at in the packs' contact sheet.
Textures.Packs = require(if script then script.Parent.PackTextures else "./PackTextures")

for key, entry in Textures.Packs do
	if Textures.Images[key] == nil then
		Textures.Images[key] = entry
	end
end

-- (the black-backed ids of the packs, measured by Egg Heist: PetVfx.BlackBacked; any id here is drawn additive)
Textures.BlackIds = {
	[131500085377698] = true,
	[1053548563] = true,
	[1084975295] = true,
	[10365550877] = true,
	[10553903882] = true,
	[11037291253] = true,
	[11037538087] = true,
	[11183842680] = true,
	[11499447365] = true,
	[12390063093] = true,
	[12685367098] = true,
	[12761854004] = true,
	[12781800668] = true,
	[13621165663] = true,
	[13622785046] = true,
	[14111022442] = true,
	[14524175849] = true,
	[15020647902] = true,
	[16937144632] = true,
	[16951208736] = true,
	[17067057050] = true,
	[17087448166] = true,
	[17087712772] = true,
	[17087733793] = true,
	[17088300017] = true,
	[6280384227] = true,
	[7417144556] = true,
	[8068783649] = true,
	[8943878058] = true,
	[9035707329] = true,
	[9541055154] = true,
	[9572518235] = true,
}

local overrides = {}

-- A game's own uploads in place of the library's: { key = id }.
function Textures.override(map)
	for key, id in map or {} do
		overrides[key] = id
	end
end

function Textures.get(key)
	return Textures.Images[key]
end

-- A picture an effect brings with it (a packaged effect carries its own: `assets.textures`, packages/): kept only when
-- the key is new, so the library's own entry and a game's override always win.
function Textures.add(key, entry)
	if Textures.Images[key] == nil and type(entry) == "table" and entry.id ~= nil then
		Textures.Images[key] = entry
	end
end

local function idOf(key)
	local entry = Textures.Images[key]
	if overrides[key] ~= nil then
		return overrides[key]
	end
	return entry and entry.id
end

-- The content string of a key ("rbxassetid://123" or an engine path), "" when the key is unknown.
function Textures.url(key)
	local id = idOf(key)
	if type(id) == "number" then
		return "rbxassetid://" .. tostring(id)
	end
	return id or ""
end

-- Whether a key's picture is drawn on black (see `black` above).
function Textures.isBlack(key)
	local entry = Textures.Images[key]
	if not entry then
		return false
	end
	if entry.black then
		return true
	end
	return type(entry.id) == "number" and Textures.BlackIds[entry.id] == true
end

-- The floor art of auras (rune circles, sigils, an element's ground pattern): one aura wears each (the tests check it).
-- New ones are named `floor_<element>`; these are the packs' circles from before that rule.
Textures.FloorPacks =
	{ rune_circle = true, rune_circle_violet = true, rune_ring_ornate = true, rune_ring_broken = true }

function Textures.isFloor(key)
	return Textures.FloorPacks[key] == true or string.sub(key, 1, 6) == "floor_"
end

-- The key of an id, nil when no entry has it (the baker uses it).
function Textures.keyOf(id)
	for key, entry in Textures.Images do
		if entry.id == id then
			return key
		end
	end
	return nil
end

return Textures
