--!strict
-- The owner's Meshy pieces, read as part of Config.LibraryKit (its Textures and Props). He sends them as sheet models,
-- many props in one file; tools/blender/meshy_sheet_split.py cuts each sheet into its pieces (tools/blender/meshy_sheets.json
-- names them) and prints these lines into the sheet's pieces.json. Every piece is painted by its sheet's own picture, has
-- its front to -Z and is held by the middle of its foot, of its back (what hangs on a wall) or of its top (what hangs from
-- a beam). `mesh = 0` and an empty picture until he imports the sheet's <key>_pieces.glb: until then whoever asks for the
-- piece builds its stand-in. The list grows with every sheet, which is why it has a file of its own.
return {
	Textures = {
		MeshyGranary = "", -- art/models/granary/meshy
		MeshyKitchen = "", -- art/models/kitchen/meshy
		-- art/models/props/meshy/<village, stall, stallitems, kitchenkit, flowerpots, environment, restaurant>
		MeshyVillage = "",
		MeshyStall = "",
		MeshyStallItems = "",
		MeshyKitchenKit = "",
		MeshyFlowerPots = "",
		MeshyEnvironment = "",
		MeshyRestaurant = "",
	},
	Props = {
		-- granary (2026-11-16)
		SlimeStatue_Gold = { { mesh = 0, tex = "MeshyGranary", size = { 2, 2.202, 1.967 }, at = { 0, 1.101, 0 } } },
		Crest_Gold = { { mesh = 0, tex = "MeshyGranary", size = { 2.03, 2, 0.269 }, at = { 0, 0, -0.135 } } },
		ThatchRoof_Gable = { { mesh = 0, tex = "MeshyGranary", size = { 2, 1.387, 2.13 }, at = { 0, 0.693, 0 } } },
		ThatchCap_Tower = { { mesh = 0, tex = "MeshyGranary", size = { 2, 1.772, 1.962 }, at = { 0, 0.886, 0 } } },
		ThatchCap_Silo = { { mesh = 0, tex = "MeshyGranary", size = { 2, 1.389, 2 }, at = { 0, 0.695, 0 } } },
		WallLantern_Iron = { { mesh = 0, tex = "MeshyGranary", size = { 1.053, 2.2, 1.916 }, at = { 0, 0, -0.958 } } },
		HangingSack_Beam = { { mesh = 0, tex = "MeshyGranary", size = { 1.607, 3.4, 2.591 }, at = { 0, 0, -1.295 } } },
		Ivy_Corner = { { mesh = 0, tex = "MeshyGranary", size = { 5.824, 6, 2.723 }, at = { 0, 0, -1.361 } } },
		-- kitchen (2026-11-16)
		ChefEmblem_Plaque = { { mesh = 0, tex = "MeshyKitchen", size = { 4.605, 4.8, 1.621 }, at = { 0, 0, -0.811 } } },
		ChefHat_White = { { mesh = 0, tex = "MeshyKitchen", size = { 2.067, 1.9, 0.944 }, at = { 0, 0.95, 0 } } },
		Laurel_Gold = { { mesh = 0, tex = "MeshyKitchen", size = { 5.273, 4.4, 0.684 }, at = { 0, 0, -0.342 } } },
		PotRack_Iron = { { mesh = 0, tex = "MeshyKitchen", size = { 4.543, 3, 1.011 }, at = { 0, -1.5, 0 } } },
		-- village (the second delivery, 2026-11-16; its wall lantern, hoist sack and ivy corner lost to the granary's)
		CrateStack_Wood = {
			{ mesh = 0, tex = "MeshyVillage", size = { 4.483, 4.200, 3.007 }, at = { 0.000, 2.100, 0.000 } },
		},
		Barrel_Oak = {
			{ mesh = 0, tex = "MeshyVillage", size = { 2.965, 3.200, 2.999 }, at = { 0.000, 1.600, 0.000 } },
		},
		HayBales_Stack = {
			{ mesh = 0, tex = "MeshyVillage", size = { 3.917, 3.600, 3.516 }, at = { 0.000, 1.800, 0.000 } },
		},
		GrainSacks_Pair = {
			{ mesh = 0, tex = "MeshyVillage", size = { 3.691, 3.000, 3.110 }, at = { 0.000, 1.500, 0.000 } },
		},
		Banner_SlimeBlue = {
			{ mesh = 0, tex = "MeshyVillage", size = { 3.618, 5.000, 1.326 }, at = { 0.000, 0.000, -0.663 } },
		},
		FlowerBox_Trough = {
			{ mesh = 0, tex = "MeshyVillage", size = { 4.000, 2.785, 2.131 }, at = { 0.000, 1.393, 0.000 } },
		},
		RopeHook_Coil = {
			{ mesh = 0, tex = "MeshyVillage", size = { 1.681, 3.000, 2.194 }, at = { 0.000, 0.000, -1.097 } },
		},
		HangingSign_Blank = {
			{ mesh = 0, tex = "MeshyVillage", size = { 0.774, 3.600, 3.536 }, at = { 0.000, 0.000, -1.768 } },
		},
		Topiary_StonePlanter = {
			{ mesh = 0, tex = "MeshyVillage", size = { 2.620, 5.000, 2.692 }, at = { 0.000, 2.500, 0.000 } },
		},
		GooTank_Glass = {
			{ mesh = 0, tex = "MeshyVillage", size = { 2.770, 4.500, 2.815 }, at = { 0.000, 2.250, 0.000 } },
		},
		PipeValve_Copper = {
			{ mesh = 0, tex = "MeshyVillage", size = { 3.513, 3.500, 1.534 }, at = { 0.000, 0.000, -0.767 } },
		},
		FlowerUrn_Gold = {
			{ mesh = 0, tex = "MeshyVillage", size = { 3.097, 3.600, 2.916 }, at = { 0.000, 1.800, 0.000 } },
		},
		SlimeCrest_Laurel = {
			{ mesh = 0, tex = "MeshyVillage", size = { 3.404, 4.000, 1.192 }, at = { 0.000, 0.000, -0.596 } },
		},
		-- stall
		Stall_Thatch = {
			{ mesh = 0, tex = "MeshyStall", size = { 9.177, 7.000, 6.738 }, at = { 0.000, 3.500, 0.000 } },
		},
		Stall_RedStripe = {
			{ mesh = 0, tex = "MeshyStall", size = { 9.808, 6.500, 6.158 }, at = { 0.000, 3.250, 0.000 } },
		},
		Stall_BlueStripe = {
			{ mesh = 0, tex = "MeshyStall", size = { 8.497, 6.500, 6.141 }, at = { 0.000, 3.250, 0.000 } },
		},
		Canopy_Glass = {
			{ mesh = 0, tex = "MeshyStall", size = { 8.305, 6.500, 5.493 }, at = { 0.000, 3.250, 0.000 } },
		},
		ParasolTable_Red = {
			{ mesh = 0, tex = "MeshyStall", size = { 6.676, 8.000, 6.464 }, at = { 0.000, 4.000, 0.000 } },
		},
		ParasolTable_Blue = {
			{ mesh = 0, tex = "MeshyStall", size = { 6.520, 8.000, 6.876 }, at = { 0.000, 4.000, 0.000 } },
		},
		ParasolTable_Cream = {
			{ mesh = 0, tex = "MeshyStall", size = { 6.707, 8.000, 6.928 }, at = { 0.000, 4.000, 0.000 } },
		},
		RoseArch_Garden = {
			{ mesh = 0, tex = "MeshyStall", size = { 8.701, 8.000, 3.352 }, at = { 0.000, 4.000, 0.000 } },
		},
		Trellis_Ivy = {
			{ mesh = 0, tex = "MeshyStall", size = { 4.473, 6.000, 2.107 }, at = { 0.000, 0.000, -1.054 } },
		},
		-- stallitems
		Shelf_Jars = {
			{ mesh = 0, tex = "MeshyStallItems", size = { 4.517, 4.500, 2.554 }, at = { 0.000, 2.250, 0.000 } },
		},
		Shelf_Vegetables = {
			{ mesh = 0, tex = "MeshyStallItems", size = { 4.837, 4.500, 4.013 }, at = { 0.000, 2.250, 0.000 } },
		},
		PicnicTable_Checked = {
			{ mesh = 0, tex = "MeshyStallItems", size = { 5.971, 4.200, 6.911 }, at = { 0.000, 2.100, 0.000 } },
		},
		RoundTable_Lantern = {
			{ mesh = 0, tex = "MeshyStallItems", size = { 5.537, 4.400, 4.694 }, at = { 0.000, 2.200, 0.000 } },
		},
		BarrelStack_Three = {
			{ mesh = 0, tex = "MeshyStallItems", size = { 5.269, 4.600, 7.552 }, at = { 0.000, 2.300, 0.000 } },
		},
		GrainSacks_Open = {
			{ mesh = 0, tex = "MeshyStallItems", size = { 4.574, 3.000, 3.480 }, at = { 0.000, 1.500, 0.000 } },
		},
		AppleCrate_Full = {
			{ mesh = 0, tex = "MeshyStallItems", size = { 2.051, 2.200, 2.099 }, at = { 0.000, 1.100, 0.000 } },
		},
		SausageRack_Wood = {
			{ mesh = 0, tex = "MeshyStallItems", size = { 5.116, 4.500, 1.485 }, at = { 0.000, 2.250, 0.000 } },
		},
		FishRack_Wood = {
			{ mesh = 0, tex = "MeshyStallItems", size = { 3.992, 4.500, 1.280 }, at = { 0.000, 2.250, 0.000 } },
		},
		-- kitchenkit
		Oven_Stone = {
			{ mesh = 0, tex = "MeshyKitchenKit", size = { 6.570, 8.000, 5.122 }, at = { 0.000, 4.000, 0.000 } },
		},
		Oven_Brick = {
			{ mesh = 0, tex = "MeshyKitchenKit", size = { 4.532, 7.000, 4.396 }, at = { 0.000, 3.500, 0.000 } },
		},
		CauldronFrame_Fire = {
			{ mesh = 0, tex = "MeshyKitchenKit", size = { 6.555, 5.500, 2.686 }, at = { 0.000, 2.750, 0.000 } },
		},
		Stove_IronRack = {
			{ mesh = 0, tex = "MeshyKitchenKit", size = { 7.524, 7.000, 3.667 }, at = { 0.000, 3.500, 0.000 } },
		},
		Counter_Bottles = {
			{ mesh = 0, tex = "MeshyKitchenKit", size = { 7.000, 5.148, 4.739 }, at = { 0.000, 2.574, 0.000 } },
		},
		PanRack_Copper = {
			{ mesh = 0, tex = "MeshyKitchenKit", size = { 5.000, 2.457, 1.523 }, at = { 0.000, -1.229, 0.000 } },
		},
		PlateTable_Wood = {
			{ mesh = 0, tex = "MeshyKitchenKit", size = { 6.000, 2.143, 4.238 }, at = { 0.000, 1.072, 0.000 } },
		},
		-- flowerpots
		FlowerBox_Pink = {
			{ mesh = 0, tex = "MeshyFlowerPots", size = { 3.600, 2.357, 3.011 }, at = { 0.000, 1.178, 0.000 } },
		},
		FlowerBox_Yellow = {
			{ mesh = 0, tex = "MeshyFlowerPots", size = { 3.600, 2.639, 3.028 }, at = { 0.000, 1.319, 0.000 } },
		},
		PlanterBox_Vines = {
			{ mesh = 0, tex = "MeshyFlowerPots", size = { 3.600, 2.911, 4.141 }, at = { 0.000, 1.456, 0.000 } },
		},
		HangingBasket_Pink = {
			{ mesh = 0, tex = "MeshyFlowerPots", size = { 3.137, 4.000, 3.235 }, at = { 0.000, -2.000, 0.000 } },
		},
		BushPot_Round = {
			{ mesh = 0, tex = "MeshyFlowerPots", size = { 2.556, 3.200, 2.546 }, at = { 0.000, 1.600, 0.000 } },
		},
		ConePot_Topiary = {
			{ mesh = 0, tex = "MeshyFlowerPots", size = { 2.252, 4.400, 2.252 }, at = { 0.000, 2.200, 0.000 } },
		},
		Urn_WhiteFlowers = {
			{ mesh = 0, tex = "MeshyFlowerPots", size = { 2.936, 3.200, 3.164 }, at = { 0.000, 1.600, 0.000 } },
		},
		Urn_BlueFlowers = {
			{ mesh = 0, tex = "MeshyFlowerPots", size = { 3.230, 3.200, 3.220 }, at = { 0.000, 1.600, 0.000 } },
		},
		Urn_PinkFlowers = {
			{ mesh = 0, tex = "MeshyFlowerPots", size = { 2.895, 3.600, 2.958 }, at = { 0.000, 1.800, 0.000 } },
		},
		Urn_MixedFlowers = {
			{ mesh = 0, tex = "MeshyFlowerPots", size = { 3.725, 3.200, 3.735 }, at = { 0.000, 1.600, 0.000 } },
		},
		-- environment
		LampPost_Single = {
			{ mesh = 0, tex = "MeshyEnvironment", size = { 5.430, 9.000, 2.604 }, at = { 0.000, 4.500, 0.000 } },
		},
		Fence_WoodX = {
			{ mesh = 0, tex = "MeshyEnvironment", size = { 5.470, 3.200, 0.903 }, at = { 0.000, 1.600, 0.000 } },
		},
		LampPost_Triple = {
			{ mesh = 0, tex = "MeshyEnvironment", size = { 6.909, 9.500, 2.217 }, at = { 0.000, 4.750, 0.000 } },
		},
		Pillar_Lantern = {
			{ mesh = 0, tex = "MeshyEnvironment", size = { 1.973, 5.400, 2.044 }, at = { 0.000, 2.700, 0.000 } },
		},
		Pillar_GoldCap = {
			{ mesh = 0, tex = "MeshyEnvironment", size = { 1.728, 4.500, 1.737 }, at = { 0.000, 2.250, 0.000 } },
		},
		Wall_StonePosts = {
			{ mesh = 0, tex = "MeshyEnvironment", size = { 6.782, 3.600, 1.598 }, at = { 0.000, 1.800, 0.000 } },
		},
		Brazier_Fire = {
			{ mesh = 0, tex = "MeshyEnvironment", size = { 2.819, 4.000, 2.819 }, at = { 0.000, 2.000, 0.000 } },
		},
		Fountain_Tiered = {
			{ mesh = 0, tex = "MeshyEnvironment", size = { 7.606, 6.500, 7.629 }, at = { 0.000, 3.250, 0.000 } },
		},
		Bunting_Posts = {
			{ mesh = 0, tex = "MeshyEnvironment", size = { 8.075, 4.600, 1.318 }, at = { 0.000, 2.300, 0.000 } },
		},
		-- restaurant (the two signs lie flat: their board faces -Z and their post stands at one side)
		Sign_ChefShield = {
			{ mesh = 0, tex = "MeshyRestaurant", size = { 6.639, 5.000, 0.941 }, at = { 0.000, 0.000, -0.470 } },
		},
		Sign_OvalBlank = {
			{ mesh = 0, tex = "MeshyRestaurant", size = { 5.370, 5.000, 0.883 }, at = { 0.000, 0.000, -0.441 } },
		},
		Banner_ChefRed = {
			{ mesh = 0, tex = "MeshyRestaurant", size = { 3.273, 5.000, 0.818 }, at = { 0.000, 0.000, -0.409 } },
		},
		Banner_Blue = {
			{ mesh = 0, tex = "MeshyRestaurant", size = { 3.198, 5.000, 0.775 }, at = { 0.000, 0.000, -0.387 } },
		},
		ChefCrest_Slime = {
			{ mesh = 0, tex = "MeshyRestaurant", size = { 5.189, 4.400, 1.411 }, at = { 0.000, 0.000, -0.706 } },
		},
		ChefCrest_Ribbon = {
			{ mesh = 0, tex = "MeshyRestaurant", size = { 5.891, 3.400, 1.638 }, at = { 0.000, 0.000, -0.819 } },
		},
		Finial_GoldStone = {
			{ mesh = 0, tex = "MeshyRestaurant", size = { 1.889, 2.600, 1.889 }, at = { 0.000, 1.300, 0.000 } },
		},
		Dormer_RedRoof = {
			{ mesh = 0, tex = "MeshyRestaurant", size = { 5.357, 5.000, 5.619 }, at = { 0.000, 0.000, -2.810 } },
		},
		Window_Arched = {
			{ mesh = 0, tex = "MeshyRestaurant", size = { 3.969, 4.400, 3.335 }, at = { 0.000, 0.000, -1.668 } },
		},
		Window_Shutters = {
			{ mesh = 0, tex = "MeshyRestaurant", size = { 4.229, 4.200, 2.929 }, at = { 0.000, 0.000, -1.464 } },
		},
		Window_Plain = {
			{ mesh = 0, tex = "MeshyRestaurant", size = { 3.095, 3.600, 1.283 }, at = { 0.000, 0.000, -0.642 } },
		},
	},
}
