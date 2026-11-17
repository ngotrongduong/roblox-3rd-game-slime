--!strict
-- The owner's Meshy pieces, read as part of Config.LibraryKit (its Textures and Props). He sends them as sheet models,
-- many props in one file; tools/blender/meshy_sheet_split.py cuts each sheet into its pieces (tools/blender/meshy_sheets.json
-- names them) and prints these lines into the sheet's pieces.json. Every piece is painted by its sheet's own picture, has
-- its front to -Z and is held by the middle of its foot, of its back (what hangs on a wall) or of its top (what hangs from
-- a beam). `mesh = 0` and an empty picture until he imports the sheet's <key>_pieces.glb: until then whoever asks for the
-- piece builds its stand-in. The list grows with every sheet, which is why it has a file of its own.
return {
	Textures = {
		MeshyGranary = "rbxassetid://90548806658369", -- art/models/granary/meshy
		MeshyKitchen = "rbxassetid://80581701858895", -- art/models/kitchen/meshy
		-- art/models/props/meshy/<village, stall, stallitems, kitchenkit, flowerpots, environment, restaurant>
		MeshyVillage = "rbxassetid://112456004124087",
		MeshyStall = "rbxassetid://85643328564965",
		MeshyStallItems = "rbxassetid://76236683987791",
		MeshyKitchenKit = "rbxassetid://138673981222555",
		MeshyFlowerPots = "rbxassetid://120822580306566",
		MeshyEnvironment = "rbxassetid://74604300726824",
		MeshyRestaurant = "rbxassetid://101810638561973",
	},
	Props = {
		-- granary (2026-11-16)
		SlimeStatue_Gold = {
			{ mesh = 104265732980655, tex = "MeshyGranary", size = { 2, 2.202, 1.967 }, at = { 0, 1.101, 0 } },
		},
		Crest_Gold = {
			{ mesh = 107860058069548, tex = "MeshyGranary", size = { 2.03, 2, 0.269 }, at = { 0, 0, -0.135 } },
		},
		ThatchRoof_Gable = {
			{ mesh = 119978609850134, tex = "MeshyGranary", size = { 2, 1.387, 2.13 }, at = { 0, 0.693, 0 } },
		},
		ThatchCap_Tower = {
			{ mesh = 133260008399407, tex = "MeshyGranary", size = { 2, 1.772, 1.962 }, at = { 0, 0.886, 0 } },
		},
		ThatchCap_Silo = {
			{ mesh = 112869686444086, tex = "MeshyGranary", size = { 2, 1.389, 2 }, at = { 0, 0.695, 0 } },
		},
		WallLantern_Iron = {
			{ mesh = 101141764729404, tex = "MeshyGranary", size = { 1.053, 2.2, 1.916 }, at = { 0, 0, -0.958 } },
		},
		HangingSack_Beam = {
			{ mesh = 98247736016515, tex = "MeshyGranary", size = { 1.607, 3.4, 2.591 }, at = { 0, 0, -1.295 } },
		},
		Ivy_Corner = {
			{ mesh = 118368205630333, tex = "MeshyGranary", size = { 5.824, 6, 2.723 }, at = { 0, 0, -1.361 } },
		},
		-- kitchen (2026-11-16)
		ChefEmblem_Plaque = {
			{ mesh = 118970894093128, tex = "MeshyKitchen", size = { 4.605, 4.8, 1.621 }, at = { 0, 0, -0.811 } },
		},
		ChefHat_White = {
			{ mesh = 131099791206267, tex = "MeshyKitchen", size = { 2.067, 1.9, 0.944 }, at = { 0, 0.95, 0 } },
		},
		Laurel_Gold = {
			{ mesh = 73472089506854, tex = "MeshyKitchen", size = { 5.273, 4.4, 0.684 }, at = { 0, 0, -0.342 } },
		},
		PotRack_Iron = {
			{ mesh = 111990820052564, tex = "MeshyKitchen", size = { 4.543, 3, 1.011 }, at = { 0, -1.5, 0 } },
		},
		-- village (the second delivery, 2026-11-16; its wall lantern, hoist sack and ivy corner lost to the granary's)
		CrateStack_Wood = {
			{
				mesh = 101790021457331,
				tex = "MeshyVillage",
				size = { 4.483, 4.200, 3.007 },
				at = { 0.000, 2.100, 0.000 },
			},
		},
		Barrel_Oak = {
			{
				mesh = 105934255568869,
				tex = "MeshyVillage",
				size = { 2.965, 3.200, 2.999 },
				at = { 0.000, 1.600, 0.000 },
			},
		},
		HayBales_Stack = {
			{
				mesh = 109788055060467,
				tex = "MeshyVillage",
				size = { 3.917, 3.600, 3.516 },
				at = { 0.000, 1.800, 0.000 },
			},
		},
		GrainSacks_Pair = {
			{
				mesh = 124285007536478,
				tex = "MeshyVillage",
				size = { 3.691, 3.000, 3.110 },
				at = { 0.000, 1.500, 0.000 },
			},
		},
		Banner_SlimeBlue = {
			{
				mesh = 103113095973790,
				tex = "MeshyVillage",
				size = { 3.618, 5.000, 1.326 },
				at = { 0.000, 0.000, -0.663 },
			},
		},
		FlowerBox_Trough = {
			{
				mesh = 104139036562981,
				tex = "MeshyVillage",
				size = { 4.000, 2.785, 2.131 },
				at = { 0.000, 1.393, 0.000 },
			},
		},
		RopeHook_Coil = {
			{
				mesh = 100059307546459,
				tex = "MeshyVillage",
				size = { 1.681, 3.000, 2.194 },
				at = { 0.000, 0.000, -1.097 },
			},
		},
		HangingSign_Blank = {
			{
				mesh = 80167563067091,
				tex = "MeshyVillage",
				size = { 0.774, 3.600, 3.536 },
				at = { 0.000, 0.000, -1.768 },
			},
		},
		Topiary_StonePlanter = {
			{
				mesh = 91700417008598,
				tex = "MeshyVillage",
				size = { 2.620, 5.000, 2.692 },
				at = { 0.000, 2.500, 0.000 },
			},
		},
		GooTank_Glass = {
			{
				mesh = 87582617413262,
				tex = "MeshyVillage",
				size = { 2.770, 4.500, 2.815 },
				at = { 0.000, 2.250, 0.000 },
			},
		},
		PipeValve_Copper = {
			{
				mesh = 82361216314241,
				tex = "MeshyVillage",
				size = { 3.513, 3.500, 1.534 },
				at = { 0.000, 0.000, -0.767 },
			},
		},
		FlowerUrn_Gold = {
			{
				mesh = 123008958876878,
				tex = "MeshyVillage",
				size = { 3.097, 3.600, 2.916 },
				at = { 0.000, 1.800, 0.000 },
			},
		},
		SlimeCrest_Laurel = {
			{
				mesh = 136478769072337,
				tex = "MeshyVillage",
				size = { 3.404, 4.000, 1.192 },
				at = { 0.000, 0.000, -0.596 },
			},
		},
		-- stall
		Stall_Thatch = {
			{
				mesh = 113023670430756,
				tex = "MeshyStall",
				size = { 9.177, 7.000, 6.738 },
				at = { 0.000, 3.500, 0.000 },
			},
		},
		Stall_RedStripe = {
			{
				mesh = 125860524054664,
				tex = "MeshyStall",
				size = { 9.808, 6.500, 6.158 },
				at = { 0.000, 3.250, 0.000 },
			},
		},
		Stall_BlueStripe = {
			{ mesh = 96440877791766, tex = "MeshyStall", size = { 8.497, 6.500, 6.141 }, at = { 0.000, 3.250, 0.000 } },
		},
		Canopy_Glass = {
			{
				mesh = 129504988230657,
				tex = "MeshyStall",
				size = { 8.305, 6.500, 5.493 },
				at = { 0.000, 3.250, 0.000 },
			},
		},
		ParasolTable_Red = {
			{ mesh = 80855009195407, tex = "MeshyStall", size = { 6.676, 8.000, 6.464 }, at = { 0.000, 4.000, 0.000 } },
		},
		ParasolTable_Blue = {
			{
				mesh = 128632583534805,
				tex = "MeshyStall",
				size = { 6.520, 8.000, 6.876 },
				at = { 0.000, 4.000, 0.000 },
			},
		},
		ParasolTable_Cream = {
			{
				mesh = 134478945124420,
				tex = "MeshyStall",
				size = { 6.707, 8.000, 6.928 },
				at = { 0.000, 4.000, 0.000 },
			},
		},
		RoseArch_Garden = {
			{
				mesh = 133359804541139,
				tex = "MeshyStall",
				size = { 8.701, 8.000, 3.352 },
				at = { 0.000, 4.000, 0.000 },
			},
		},
		Trellis_Ivy = {
			{
				mesh = 72933604383811,
				tex = "MeshyStall",
				size = { 4.473, 6.000, 2.107 },
				at = { 0.000, 0.000, -1.054 },
			},
		},
		-- stallitems
		Shelf_Jars = {
			{
				mesh = 128169712919989,
				tex = "MeshyStallItems",
				size = { 4.517, 4.500, 2.554 },
				at = { 0.000, 2.250, 0.000 },
			},
		},
		Shelf_Vegetables = {
			{
				mesh = 93855170251453,
				tex = "MeshyStallItems",
				size = { 4.837, 4.500, 4.013 },
				at = { 0.000, 2.250, 0.000 },
			},
		},
		PicnicTable_Checked = {
			{
				mesh = 75938715684428,
				tex = "MeshyStallItems",
				size = { 5.971, 4.200, 6.911 },
				at = { 0.000, 2.100, 0.000 },
			},
		},
		RoundTable_Lantern = {
			{
				mesh = 82045052193354,
				tex = "MeshyStallItems",
				size = { 5.537, 4.400, 4.694 },
				at = { 0.000, 2.200, 0.000 },
			},
		},
		BarrelStack_Three = {
			{
				mesh = 121491708206172,
				tex = "MeshyStallItems",
				size = { 5.269, 4.600, 7.552 },
				at = { 0.000, 2.300, 0.000 },
			},
		},
		GrainSacks_Open = {
			{
				mesh = 90551102085632,
				tex = "MeshyStallItems",
				size = { 4.574, 3.000, 3.480 },
				at = { 0.000, 1.500, 0.000 },
			},
		},
		AppleCrate_Full = {
			{
				mesh = 85633537847460,
				tex = "MeshyStallItems",
				size = { 2.051, 2.200, 2.099 },
				at = { 0.000, 1.100, 0.000 },
			},
		},
		SausageRack_Wood = {
			{
				mesh = 104069984086473,
				tex = "MeshyStallItems",
				size = { 5.116, 4.500, 1.485 },
				at = { 0.000, 2.250, 0.000 },
			},
		},
		FishRack_Wood = {
			{
				mesh = 109664546886587,
				tex = "MeshyStallItems",
				size = { 3.992, 4.500, 1.280 },
				at = { 0.000, 2.250, 0.000 },
			},
		},
		-- kitchenkit
		Oven_Stone = {
			{
				mesh = 118161059657906,
				tex = "MeshyKitchenKit",
				size = { 6.570, 8.000, 5.122 },
				at = { 0.000, 4.000, 0.000 },
			},
		},
		Oven_Brick = {
			{
				mesh = 93825525272178,
				tex = "MeshyKitchenKit",
				size = { 4.532, 7.000, 4.396 },
				at = { 0.000, 3.500, 0.000 },
			},
		},
		CauldronFrame_Fire = {
			{
				mesh = 94344830490065,
				tex = "MeshyKitchenKit",
				size = { 6.555, 5.500, 2.686 },
				at = { 0.000, 2.750, 0.000 },
			},
		},
		Stove_IronRack = {
			{
				mesh = 100429478048668,
				tex = "MeshyKitchenKit",
				size = { 7.524, 7.000, 3.667 },
				at = { 0.000, 3.500, 0.000 },
			},
		},
		Counter_Bottles = {
			{
				mesh = 86223747265210,
				tex = "MeshyKitchenKit",
				size = { 7.000, 5.148, 4.739 },
				at = { 0.000, 2.574, 0.000 },
			},
		},
		PanRack_Copper = {
			{
				mesh = 140626198871973,
				tex = "MeshyKitchenKit",
				size = { 5.000, 2.457, 1.523 },
				at = { 0.000, -1.229, 0.000 },
			},
		},
		PlateTable_Wood = {
			{
				mesh = 125459949167047,
				tex = "MeshyKitchenKit",
				size = { 6.000, 2.143, 4.238 },
				at = { 0.000, 1.072, 0.000 },
			},
		},
		-- flowerpots
		FlowerBox_Pink = {
			{
				mesh = 118280081785885,
				tex = "MeshyFlowerPots",
				size = { 3.600, 2.357, 3.011 },
				at = { 0.000, 1.178, 0.000 },
			},
		},
		FlowerBox_Yellow = {
			{
				mesh = 88477411418307,
				tex = "MeshyFlowerPots",
				size = { 3.600, 2.639, 3.028 },
				at = { 0.000, 1.319, 0.000 },
			},
		},
		PlanterBox_Vines = {
			{
				mesh = 136912029331155,
				tex = "MeshyFlowerPots",
				size = { 3.600, 2.911, 4.141 },
				at = { 0.000, 1.456, 0.000 },
			},
		},
		HangingBasket_Pink = {
			{
				mesh = 98559679922309,
				tex = "MeshyFlowerPots",
				size = { 3.137, 4.000, 3.235 },
				at = { 0.000, -2.000, 0.000 },
			},
		},
		BushPot_Round = {
			{
				mesh = 97333315098635,
				tex = "MeshyFlowerPots",
				size = { 2.556, 3.200, 2.546 },
				at = { 0.000, 1.600, 0.000 },
			},
		},
		ConePot_Topiary = {
			{
				mesh = 88020327370899,
				tex = "MeshyFlowerPots",
				size = { 2.252, 4.400, 2.252 },
				at = { 0.000, 2.200, 0.000 },
			},
		},
		Urn_WhiteFlowers = {
			{
				mesh = 136390377066723,
				tex = "MeshyFlowerPots",
				size = { 2.936, 3.200, 3.164 },
				at = { 0.000, 1.600, 0.000 },
			},
		},
		Urn_BlueFlowers = {
			{
				mesh = 133186333693186,
				tex = "MeshyFlowerPots",
				size = { 3.230, 3.200, 3.220 },
				at = { 0.000, 1.600, 0.000 },
			},
		},
		Urn_PinkFlowers = {
			{
				mesh = 107164202633551,
				tex = "MeshyFlowerPots",
				size = { 2.895, 3.600, 2.958 },
				at = { 0.000, 1.800, 0.000 },
			},
		},
		Urn_MixedFlowers = {
			{
				mesh = 77829193061944,
				tex = "MeshyFlowerPots",
				size = { 3.725, 3.200, 3.735 },
				at = { 0.000, 1.600, 0.000 },
			},
		},
		-- environment
		LampPost_Single = {
			{
				mesh = 125886228764779,
				tex = "MeshyEnvironment",
				size = { 5.430, 9.000, 2.604 },
				at = { 0.000, 4.500, 0.000 },
			},
		},
		Fence_WoodX = {
			{
				mesh = 74922221897615,
				tex = "MeshyEnvironment",
				size = { 5.470, 3.200, 0.903 },
				at = { 0.000, 1.600, 0.000 },
			},
		},
		LampPost_Triple = {
			{
				mesh = 103321161270152,
				tex = "MeshyEnvironment",
				size = { 6.909, 9.500, 2.217 },
				at = { 0.000, 4.750, 0.000 },
			},
		},
		Pillar_Lantern = {
			{
				mesh = 96982758101075,
				tex = "MeshyEnvironment",
				size = { 1.973, 5.400, 2.044 },
				at = { 0.000, 2.700, 0.000 },
			},
		},
		Pillar_GoldCap = {
			{
				mesh = 115869448833066,
				tex = "MeshyEnvironment",
				size = { 1.728, 4.500, 1.737 },
				at = { 0.000, 2.250, 0.000 },
			},
		},
		Wall_StonePosts = {
			{
				mesh = 79995891286630,
				tex = "MeshyEnvironment",
				size = { 6.782, 3.600, 1.598 },
				at = { 0.000, 1.800, 0.000 },
			},
		},
		Brazier_Fire = {
			{
				mesh = 122676103087072,
				tex = "MeshyEnvironment",
				size = { 2.819, 4.000, 2.819 },
				at = { 0.000, 2.000, 0.000 },
			},
		},
		Fountain_Tiered = {
			{
				mesh = 125339876375496,
				tex = "MeshyEnvironment",
				size = { 7.606, 6.500, 7.629 },
				at = { 0.000, 3.250, 0.000 },
			},
		},
		Bunting_Posts = {
			{
				mesh = 77618588309324,
				tex = "MeshyEnvironment",
				size = { 8.075, 4.600, 1.318 },
				at = { 0.000, 2.300, 0.000 },
			},
		},
		-- restaurant (the two signs lie flat: their board faces -Z and their post stands at one side)
		Sign_ChefShield = {
			{
				mesh = 79777727626921,
				tex = "MeshyRestaurant",
				size = { 6.639, 5.000, 0.941 },
				at = { 0.000, 0.000, -0.470 },
			},
		},
		Sign_OvalBlank = {
			{
				mesh = 102943997284469,
				tex = "MeshyRestaurant",
				size = { 5.370, 5.000, 0.883 },
				at = { 0.000, 0.000, -0.441 },
			},
		},
		Banner_ChefRed = {
			{
				mesh = 99095473831240,
				tex = "MeshyRestaurant",
				size = { 3.273, 5.000, 0.818 },
				at = { 0.000, 0.000, -0.409 },
			},
		},
		Banner_Blue = {
			{
				mesh = 134338934051779,
				tex = "MeshyRestaurant",
				size = { 3.198, 5.000, 0.775 },
				at = { 0.000, 0.000, -0.387 },
			},
		},
		ChefCrest_Slime = {
			{
				mesh = 124990619891752,
				tex = "MeshyRestaurant",
				size = { 5.189, 4.400, 1.411 },
				at = { 0.000, 0.000, -0.706 },
			},
		},
		ChefCrest_Ribbon = {
			{
				mesh = 72334803128436,
				tex = "MeshyRestaurant",
				size = { 5.891, 3.400, 1.638 },
				at = { 0.000, 0.000, -0.819 },
			},
		},
		Finial_GoldStone = {
			{
				mesh = 139502653787484,
				tex = "MeshyRestaurant",
				size = { 1.889, 2.600, 1.889 },
				at = { 0.000, 1.300, 0.000 },
			},
		},
		Dormer_RedRoof = {
			{
				mesh = 79618188809926,
				tex = "MeshyRestaurant",
				size = { 5.357, 5.000, 5.619 },
				at = { 0.000, 0.000, -2.810 },
			},
		},
		Window_Arched = {
			{
				mesh = 87381471674360,
				tex = "MeshyRestaurant",
				size = { 3.969, 4.400, 3.335 },
				at = { 0.000, 0.000, -1.668 },
			},
		},
		Window_Shutters = {
			{
				mesh = 108904435396619,
				tex = "MeshyRestaurant",
				size = { 4.229, 4.200, 2.929 },
				at = { 0.000, 0.000, -1.464 },
			},
		},
		Window_Plain = {
			{
				mesh = 82017221291558,
				tex = "MeshyRestaurant",
				size = { 3.095, 3.600, 1.283 },
				at = { 0.000, 0.000, -0.642 },
			},
		},
		-- THE LANDMARKS' BODIES FROM BLENDER (the owner, 2026-11-17: every building rebuilt in Blender): an era's whole
		-- shell, one mesh a material, painted by the game. tools/blender/landmark_bodies.py prints these rows; they are
		-- here because this list, not Config's, is the one with room to grow. Held by the middle of the front wall's foot.
		GranaryBody1_Stone = {
			{ mesh = 112948646468915, tex = "", size = { 23.7, 1.2, 19.04 }, at = { -3.05, 0.6, 3.98 } },
		},
		GranaryBody1_Plaster = { { mesh = 105235623739664, tex = "", size = { 17, 20.64, 12 }, at = { 0, 11.52, 6 } } },
		GranaryBody1_Timber = {
			{ mesh = 134692605030446, tex = "", size = { 24.692, 21.94, 16.936 }, at = { -2.58, 11.67, 4.752 } },
		},
		GranaryBody1_Thatch = {
			{ mesh = 75296677600544, tex = "", size = { 27.219, 11.278, 16.428 }, at = { -2.647, 11.771, 5.786 } },
		},
		GranaryBody1_Planks = {
			{ mesh = 109960499207116, tex = "", size = { 9.15, 11.37, 16.151 }, at = { 0, 6.915, 4.185 } },
		},
		GranaryBody1_Iron = {
			{ mesh = 88620871192380, tex = "", size = { 9.295, 3.732, 15.925 }, at = { 0, 3.666, 4.247 } },
		},
		GranaryBody1_Pane = { { mesh = 76295309709634, tex = "", size = { 16.16, 2, 12.12 }, at = { 0.48, 4.6, 6 } } },
	},
}
