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
		-- (eras 2 to 5: a mesh is one colour field of the module's Look; two fields of one colour share a mesh)
		GranaryBody2_Stone = {
			{ mesh = 101712107919374, tex = "", size = { 34.7, 1.2, 21.54 }, at = { 0.95, 0.6, 4.73 } },
		},
		GranaryBody2_Wall = { { mesh = 100916398130861, tex = "", size = { 28, 23.72, 14 }, at = { 4, 13.06, 7 } } },
		GranaryBody2_Beam = {
			{ mesh = 81570287878251, tex = "", size = { 28.48, 16.672, 14.8 }, at = { 4, 9.536, 6.9 } },
		},
		GranaryBody2_Board = {
			{ mesh = 135005136304354, tex = "", size = { 35.496, 25.02, 16.94 }, at = { 1.322, 13.21, 7 } },
		},
		GranaryBody2_Frame = {
			{ mesh = 78847741330620, tex = "", size = { 27.44, 11.79, 14.88 }, at = { 4.7, 8.525, 7 } },
		},
		GranaryBody2_Roof = {
			{ mesh = 80887973137061, tex = "", size = { 35.978, 14.38, 16.9 }, at = { 1.011, 12.21, 7 } },
		},
		GranaryBody2_Door = {
			{ mesh = 131372337031862, tex = "", size = { 10.323, 6.85, 18.483 }, at = { 0, 4.655, 4.858 } },
		},
		GranaryBody2_Band = {
			{ mesh = 117205355448029, tex = "", size = { 10.469, 2.721, 18.417 }, at = { 0, 3.161, 5 } },
		},
		GranaryBody2_Glass = {
			{ mesh = 81821379143746, tex = "", size = { 26.8, 11.23, 14.68 }, at = { 4.8, 8.505, 7 } },
		},
		GranaryBody2_TowerCap = {
			{ mesh = 115788684950585, tex = "", size = { 8.4, 6.62, 8.4 }, at = { 0, 29.03, 7.7 } },
		},
		GranaryBody3_Stone = {
			{ mesh = 112322058758276, tex = "", size = { 37.2, 1.2, 24.04 }, at = { 1.2, 0.6, 5.48 } },
		},
		GranaryBody3_Wall = {
			{ mesh = 90736667379072, tex = "", size = { 30.8, 13.999, 16.6 }, at = { 4.1, 13.999, 8 } },
		},
		GranaryBody3_Lower = { { mesh = 89452095793826, tex = "", size = { 30.5, 8.4, 16 }, at = { 4.25, 5.4, 8 } } },
		GranaryBody3_Beam = {
			{ mesh = 103893432097760, tex = "", size = { 37.996, 28.6, 19.54 }, at = { 1.572, 15, 8 } },
		},
		GranaryBody3_Surround = {
			{ mesh = 73565798473251, tex = "", size = { 22.24, 8.725, 16.62 }, at = { 0, 5.562, 7.81 } },
		},
		GranaryBody3_Roof = {
			{ mesh = 81543849695245, tex = "", size = { 38.478, 30.941, 19.5 }, at = { 1.261, 21.45, 8 } },
		},
		GranaryBody3_Door = {
			{ mesh = 101782892513598, tex = "", size = { 11.497, 7.85, 20.976 }, at = { 0, 5.155, 5.612 } },
		},
		GranaryBody3_Band = {
			{ mesh = 96759337569961, tex = "", size = { 11.643, 3.22, 20.91 }, at = { 0, 3.41, 5.754 } },
		},
		GranaryBody3_Glass = {
			{ mesh = 86324408503560, tex = "", size = { 31.06, 13.46, 17.28 }, at = { 4.17, 10.12, 8 } },
		},
		GranaryBody3_TowerWall = {
			{ mesh = 95320896779159, tex = "", size = { 7.5, 10.819, 7.5 }, at = { 0, 23.091, 8.8 } },
		},
		GranaryBody4_Stone = {
			{ mesh = 120262379712752, tex = "", size = { 38.2, 6.35, 25.24 }, at = { 1.2, 3.175, 5.88 } },
		},
		GranaryBody4_Lower = {
			{ mesh = 140348793787737, tex = "", size = { 12.6, 4.62, 1.1 }, at = { 0, 3.51, 0.15 } },
		},
		GranaryBody4_Beam = {
			{ mesh = 137598987718735, tex = "", size = { 38.526, 27.84, 23.168 }, at = { 1.337, 14.62, 6.686 } },
		},
		GranaryBody4_Roof = {
			{ mesh = 117401893745823, tex = "", size = { 31.176, 15.251, 19.5 }, at = { -2.89, 13.874, 8.5 } },
		},
		GranaryBody4_Door = {
			{ mesh = 89338145041140, tex = "", size = { 11.966, 8.05, 22.173 }, at = { 0, 5.255, 6.014 } },
		},
		GranaryBody4_Glass = { { mesh = 80065286351182, tex = "", size = { 19.5, 2, 17.12 }, at = { 0, 3.6, 8.5 } } },
		GranaryBody5_Stone = {
			{ mesh = 138247988475325, tex = "", size = { 39.7, 1.2, 24.3 }, at = { 1.45, 0.6, 7.35 } },
		},
		GranaryBody5_Wall = { { mesh = 126018844219259, tex = "", size = { 33, 25.48, 18 }, at = { 4.5, 13.94, 9 } } },
		GranaryBody5_Beam = { { mesh = 88032145048563, tex = "", size = { 30.8, 12.1, 18.8 }, at = { -3, 6.75, 9 } } },
		GranaryBody5_Board = {
			{ mesh = 99085353941991, tex = "", size = { 40.496, 25.98, 20.54 }, at = { 1.822, 14.19, 9 } },
		},
		GranaryBody5_Roof = {
			{ mesh = 77296476146988, tex = "", size = { 40.978, 13.551, 20.5 }, at = { 1.511, 13.024, 9 } },
		},
		GranaryBody5_Door = {
			{ mesh = 77004123819082, tex = "", size = { 11.966, 8.25, 17.308 }, at = { 0, 5.355, 9.446 } },
		},
		GranaryBody5_Glass = {
			{ mesh = 77888356830769, tex = "", size = { 33.26, 8.5, 18.12 }, at = { 4.57, 7.65, 9 } },
		},
		-- The Kitchen's five era bodies (tools/blender/landmark_bodies.py, `kitchen`), and era 1's three parts a level
		-- switches: the open truss of its first levels, the plaster gable that closes it, the chimney's upper stack.
		KitchenBody1_Stone = {
			{ mesh = 102675995116310, tex = "", size = { 29.3, 0.77, 1.6 }, at = { 0, 0.635, -4.55 } },
		},
		KitchenBody1_Wall = {
			{ mesh = 126333132721655, tex = "", size = { 28.6, 16.416, 0.6 }, at = { 0, 8.508, 12 } },
		},
		KitchenBody1_Lower = {
			{ mesh = 73898764296554, tex = "", size = { 28.64, 4.7, 17.14 }, at = { 0, 2.65, 3.87 } },
		},
		KitchenBody1_Beam = {
			{ mesh = 103437715635038, tex = "", size = { 28.94, 16.313, 17.75 }, at = { 0, 8.457, 3.705 } },
		},
		KitchenBody1_Board = {
			{ mesh = 82311912213877, tex = "", size = { 33.097, 11.913, 21.44 }, at = { 0, 11.82, 3.65 } },
		},
		KitchenBody1_Roof = {
			{ mesh = 91142475020140, tex = "", size = { 34.221, 12.456, 21.4 }, at = { 0, 12.372, 3.65 } },
		},
		KitchenBody1_Frame = {
			{ mesh = 124686710723449, tex = "", size = { 14.84, 6.54, 1.22 }, at = { 0, 3.67, 12.11 } },
		},
		KitchenBody1_Glass = { { mesh = 128003266720938, tex = "", size = { 14, 2.2, 0.72 }, at = { 0, 5.6, 12 } } },
		KitchenBody1_Chimney = {
			{ mesh = 140082063739248, tex = "", size = { 4.5, 19.3, 4.5 }, at = { 16.5, 9.65, 6.2 } },
		},
		KitchenBody1_Cap = { { mesh = 76485253829815, tex = "", size = { 4.1, 9.7, 4.1 }, at = { 16.5, 9.85, 6.2 } } },
		KitchenBody2_Stone = {
			{ mesh = 102675995116310, tex = "", size = { 29.3, 0.77, 1.6 }, at = { 0, 0.635, -4.55 } },
		},
		KitchenBody2_Wall = {
			{ mesh = 128654530337223, tex = "", size = { 28.6, 17.177, 17.3 }, at = { 0, 8.889, 3.65 } },
		},
		KitchenBody2_Beam = {
			{ mesh = 72215121226722, tex = "", size = { 29.08, 16.911, 17.84 }, at = { 0, 8.855, 3.66 } },
		},
		KitchenBody2_Board = {
			{ mesh = 138089990218854, tex = "", size = { 32.33, 11.463, 20.84 }, at = { 0, 12.502, 3.65 } },
		},
		KitchenBody2_Roof = {
			{ mesh = 139471803211401, tex = "", size = { 31.994, 11.689, 20.8 }, at = { 0, 12.856, 3.65 } },
		},
		KitchenBody2_Frame = {
			{ mesh = 125851542120437, tex = "", size = { 29.44, 6.54, 16.67 }, at = { 0, 3.67, 4.385 } },
		},
		KitchenBody2_Glass = {
			{ mesh = 132462971021287, tex = "", size = { 28.72, 3.8, 15.89 }, at = { 0, 4.8, 4.415 } },
		},
		KitchenBody2_Shutters = {
			{ mesh = 76568756998852, tex = "", size = { 29.4, 4.7, 17.12 }, at = { 0, 2.75, 3.88 } },
		},
		KitchenBody2_Chimney = {
			{ mesh = 94931681059537, tex = "", size = { 4.5, 24.7, 4.5 }, at = { 16.5, 12.35, 6.2 } },
		},
		KitchenBody2_Cap = { { mesh = 95947220346284, tex = "", size = { 4.1, 20.4, 4.1 }, at = { 16.5, 15.2, 6.2 } } },
		KitchenBody3_Stone = {
			{ mesh = 105722127772277, tex = "", size = { 29, 9.001, 17.77 }, at = { 0, 4.501, 3.615 } },
		},
		KitchenBody3_Wall = {
			{ mesh = 83939593640139, tex = "", size = { 26.56, 9.658, 17.3 }, at = { 0, 14.429, 3.65 } },
		},
		KitchenBody3_Lower = { { mesh = 87489902451561, tex = "", size = { 28.6, 9.6, 17.3 }, at = { 0, 4.8, 3.65 } } },
		KitchenBody3_Beam = {
			{ mesh = 83389442732538, tex = "", size = { 29.2, 18.705, 18.23 }, at = { 0, 9.753, 3.465 } },
		},
		KitchenBody3_Board = {
			{ mesh = 95837056550430, tex = "", size = { 32.159, 12.259, 20.64 }, at = { 0, 13.884, 3.65 } },
		},
		KitchenBody3_Roof = {
			{ mesh = 84511424839528, tex = "", size = { 31.796, 12.492, 20.6 }, at = { 0, 14.254, 3.65 } },
		},
		KitchenBody3_Frame = {
			{ mesh = 139846476957622, tex = "", size = { 32.795, 19.6, 18.18 }, at = { 1.678, 10.2, 3.63 } },
		},
		KitchenBody3_Glass = {
			{ mesh = 79124283248606, tex = "", size = { 28.72, 4.8, 15.89 }, at = { 0, 5.3, 4.415 } },
		},
		KitchenBody3_Chimney = {
			{ mesh = 109736821254950, tex = "", size = { 4.5, 26.5, 4.5 }, at = { 16.5, 13.25, 6.2 } },
		},
		KitchenBody3_Cap = { { mesh = 130974388041369, tex = "", size = { 4.1, 22.2, 4.1 }, at = { 16.5, 16.1, 6.2 } } },
		KitchenBody4_Stone = { { mesh = 92118390732206, tex = "", size = { 29, 1, 17.7 }, at = { 0, 0.5, 3.65 } } },
		KitchenBody4_Lower = { { mesh = 110666637373296, tex = "", size = { 28.6, 9.6, 17.3 }, at = { 0, 4.8, 3.65 } } },
		KitchenBody4_Beam = {
			{ mesh = 109735001469695, tex = "", size = { 29.7, 15.193, 19.1 }, at = { 0, 11.977, 3.65 } },
		},
		KitchenBody4_Board = {
			{ mesh = 108732556187827, tex = "", size = { 2.56, 4.6, 0.16 }, at = { 0, 2.7, 12.36 } },
		},
		KitchenBody4_Roof = {
			{ mesh = 114075015717354, tex = "", size = { 29.2, 9.57, 18.9 }, at = { 0, 14.385, 3.65 } },
		},
		KitchenBody4_Frame = {
			{ mesh = 71433031884288, tex = "", size = { 21.6, 7.54, 17.94 }, at = { 0, 4.17, 3.75 } },
		},
		KitchenBody4_Glass = { { mesh = 129199597521292, tex = "", size = { 14, 3.2, 0.72 }, at = { 0, 6.1, 12 } } },
		KitchenBody4_Chimney = {
			{ mesh = 138793878837633, tex = "", size = { 4.5, 25, 4.5 }, at = { 16.5, 12.5, 6.2 } },
		},
		KitchenBody4_Cap = { { mesh = 80402546685109, tex = "", size = { 4.1, 20.7, 4.1 }, at = { 16.5, 15.35, 6.2 } } },
		KitchenBody4_Gold = {
			{ mesh = 112920755765848, tex = "", size = { 19.543, 16.08, 13.8 }, at = { 8.628, 16.24, 1.2 } },
		},
		KitchenBody5_Stone = {
			{ mesh = 79338205898858, tex = "", size = { 29.52, 12.22, 17.7 }, at = { 0, 6.11, 3.65 } },
		},
		KitchenBody5_Wall = {
			{ mesh = 70639084760845, tex = "", size = { 30.04, 17.915, 19.07 }, at = { 0, 8.957, 2.815 } },
		},
		KitchenBody5_Board = {
			{ mesh = 107910209590004, tex = "", size = { 33.595, 28.17, 19.88 }, at = { 1.838, 14.485, 3.13 } },
		},
		KitchenBody5_Roof = {
			{ mesh = 140584923816353, tex = "", size = { 22.791, 7.809, 18.8 }, at = { 0, 15.096, 3.65 } },
		},
		KitchenBody5_Glass = {
			{ mesh = 79124283248606, tex = "", size = { 28.72, 4.8, 15.89 }, at = { 0, 5.3, 4.415 } },
		},
		KitchenBody5_Chimney = {
			{ mesh = 81051565736204, tex = "", size = { 5.04, 29.5, 5.04 }, at = { 16.5, 14.75, 6.2 } },
		},
		KitchenBody5_Cap = {
			{ mesh = 82830590885940, tex = "", size = { 20.08, 29.8, 8.54 }, at = { 8.76, 15.3, 8.17 } },
		},
		KitchenTruss1_Beam = {
			{ mesh = 74053122388694, tex = "", size = { 26.516, 8.618, 0.6 }, at = { 0, 12.346, -4.55 } },
		},
		KitchenGable1_Wall = {
			{ mesh = 112957816765331, tex = "", size = { 25.371, 8.516, 0.6 }, at = { 0, 12.458, -4.7 } },
		},
		KitchenGable1_Beam = {
			{ mesh = 118999105062106, tex = "", size = { 26.072, 8.165, 0.31 }, at = { 0, 12.283, -5.105 } },
		},
		KitchenStack1_Chimney = {
			{ mesh = 86384801249965, tex = "", size = { 2.9, 5, 2.9 }, at = { 16.5, 21.8, 6.2 } },
		},
		KitchenStack1_Cap = {
			{ mesh = 133891675567109, tex = "", size = { 3.7, 0.7, 3.7 }, at = { 16.5, 24.65, 6.2 } },
		},
		-- The Garden's house as Blender bodies (tools/blender/landmark_bodies.py): one body an era, and the pieces a
		-- level switches (era 1's open truss, closed gable and lean-to; era 3's roof, or its upper storey under it).
		GardenBody1_Stone = {
			{ mesh = 74389604545504, tex = "", size = { 11.36, 0.52, 1.36 }, at = { 0, 0.46, 18.9 } },
		},
		GardenBody1_Wall = {
			{ mesh = 100736655495207, tex = "", size = { 10.8, 9.64, 9.2 }, at = { 0, 5.02, 23.9 } },
		},
		GardenBody1_Lower = {
			{ mesh = 83836526818951, tex = "", size = { 10.9, 2.42, 9.25 }, at = { 0, 1.41, 23.925 } },
		},
		GardenBody1_Beam = {
			{ mesh = 75205063542886, tex = "", size = { 11.32, 9.498, 10.35 }, at = { 0, 4.949, 23.625 } },
		},
		GardenBody1_Board = {
			{ mesh = 85411929124796, tex = "", size = { 13.583, 7.816, 12.54 }, at = { 0, 6.687, 23.5 } },
		},
		GardenBody1_Roof = {
			{ mesh = 107055616725051, tex = "", size = { 14.649, 6.212, 12.5 }, at = { 0, 8.144, 23.5 } },
		},
		GardenBody1_Frame = {
			{ mesh = 75222172643391, tex = "", size = { 1.22, 1.96, 2.14 }, at = { 5.21, 4.57, 23.9 } },
		},
		GardenBody1_Glass = {
			{ mesh = 120713753230689, tex = "", size = { 0.72, 1.5, 1.3 }, at = { 5.1, 4.6, 23.9 } },
		},
		GardenBody1_Shutters = {
			{ mesh = 115239808209648, tex = "", size = { 2.4, 3.4, 0.18 }, at = { 0, 1.9, 28.57 } },
		},
		GardenBody2_Wall = {
			{ mesh = 115752695567212, tex = "", size = { 13, 11.115, 10 }, at = { 0, 5.757, 23.5 } },
		},
		GardenBody2_Beam = {
			{ mesh = 117518801821260, tex = "", size = { 13.48, 10.959, 10.6 }, at = { 0, 5.68, 23.5 } },
		},
		GardenBody2_Board = {
			{ mesh = 113165017045944, tex = "", size = { 15.3, 6.265, 12.485 }, at = { 0, 8.677, 23.5 } },
		},
		GardenBody2_Roof = {
			{ mesh = 108363320977600, tex = "", size = { 15.1, 6.296, 11.98 }, at = { 0, 9.032, 23.5 } },
		},
		GardenBody2_Frame = {
			{ mesh = 114916288470626, tex = "", size = { 10.54, 2.38, 1.22 }, at = { 0, 3.88, 28.31 } },
		},
		GardenBody2_Glass = {
			{ mesh = 135675393500068, tex = "", size = { 9.7, 1.9, 0.72 }, at = { 0, 3.9, 28.2 } },
		},
		GardenBody2_Shutters = {
			{ mesh = 79543534178639, tex = "", size = { 1.8, 3.4, 0.18 }, at = { 0, 1.9, 28.57 } },
		},
		GardenBody3_Stone = {
			{ mesh = 100258497194113, tex = "", size = { 18.14, 6.677, 10.36 }, at = { -1.69, 3.539, 23.5 } },
		},
		GardenBody3_Lower = {
			{ mesh = 138407623041045, tex = "", size = { 17.8, 6.8, 10 }, at = { -1.7, 3.6, 23.5 } },
		},
		GardenBody3_Roof = {
			{ mesh = 95395004337872, tex = "", size = { 4.323, 2.289, 8.7 }, at = { -9.193, 5.002, 23.9 } },
		},
		GardenBody3_Frame = {
			{ mesh = 108117943981742, tex = "", size = { 15, 6.715, 10.84 }, at = { 0, 3.557, 23.5 } },
		},
		GardenBody3_Glass = {
			{ mesh = 137370820471416, tex = "", size = { 10.1, 2.9, 0.72 }, at = { 0, 4, 28.2 } },
		},
		GardenBody3_Shutters = {
			{ mesh = 105431716633948, tex = "", size = { 2, 3.6, 0.18 }, at = { 0, 2, 28.57 } },
		},
		GardenBody4_Lower = {
			{ mesh = 106917024323738, tex = "", size = { 18, 1.3, 9.1 }, at = { 0, 0.85, 23.95 } },
		},
		GardenBody4_Beam = {
			{ mesh = 133160732620682, tex = "", size = { 18.73, 16.53, 10.74 }, at = { 0, 8.465, 23.46 } },
		},
		GardenBody4_Gold = {
			{ mesh = 134751628633975, tex = "", size = { 0.892, 7.452, 9.3 }, at = { 0, 13.18, 22.45 } },
		},
		GardenBody4_Roof = {
			{ mesh = 75460222071413, tex = "", size = { 18.674, 11.774, 10.05 }, at = { 0, 10.678, 23.525 } },
		},
		GardenBody4_Frame = {
			{ mesh = 139971063054883, tex = "", size = { 18.2, 0.2, 9.3 }, at = { 0, 1.6, 23.95 } },
		},
		GardenBody5_Stone = {
			{ mesh = 135178785954180, tex = "", size = { 20.6, 6.8, 12.8 }, at = { 0, 3.6, 22 } },
		},
		GardenBody5_Wall = {
			{ mesh = 134326055838864, tex = "", size = { 20, 12.318, 12.55 }, at = { 0, 6.359, 22.375 } },
		},
		GardenBody5_Beam = {
			{ mesh = 139481083427214, tex = "", size = { 20.2, 7.75, 10.6 }, at = { 0, 4.075, 23.5 } },
		},
		GardenBody5_Gold = {
			{ mesh = 135580260810596, tex = "", size = { 20.84, 12.881, 13.44 }, at = { 0, 6.64, 22.55 } },
		},
		GardenBody5_Roof = {
			{ mesh = 93604227840945, tex = "", size = { 13.321, 3.868, 13 }, at = { 0, 11.093, 22.55 } },
		},
		GardenBody5_Glass = {
			{ mesh = 121084331684782, tex = "", size = { 20.12, 3.2, 5.21 }, at = { 0, 3.9, 25.555 } },
		},
		GardenTruss1_Beam = {
			{ mesh = 87714472500708, tex = "", size = { 8.098, 3.677, 0.6 }, at = { 0, 8.091, 18.8 } },
		},
		GardenGable1_Wall = {
			{ mesh = 72471070398859, tex = "", size = { 8.845, 3.44, 0.6 }, at = { 0, 8.12, 18.8 } },
		},
		GardenGable1_Beam = {
			{ mesh = 97887906597706, tex = "", size = { 9, 3.318, 0.31 }, at = { 0, 8.039, 18.395 } },
		},
		GardenLean1_Beam = {
			{ mesh = 72762501398499, tex = "", size = { 0.58, 3.75, 9.2 }, at = { -9, 2.075, 23.8 } },
		},
		GardenLean1_Roof = {
			{ mesh = 133640407438048, tex = "", size = { 5.403, 2.026, 9.7 }, at = { -7.892, 4.362, 23.8 } },
		},
		GardenRoof3_Wall = {
			{ mesh = 86590292865342, tex = "", size = { 14.4, 4.124, 9.483 }, at = { 0, 9.062, 23.242 } },
		},
		GardenRoof3_Beam = {
			{ mesh = 138547936907626, tex = "", size = { 14.92, 4.142, 9.64 }, at = { 0, 8.901, 23.08 } },
		},
		GardenRoof3_Board = {
			{ mesh = 71633359302010, tex = "", size = { 16.7, 6.035, 12.474 }, at = { 0, 8.602, 23.5 } },
		},
		GardenRoof3_Roof = {
			{ mesh = 95203597009899, tex = "", size = { 16.5, 6.066, 11.976 }, at = { 0, 8.947, 23.5 } },
		},
		GardenStorey3_Wall = {
			{ mesh = 87699328211914, tex = "", size = { 15, 7.785, 10.8 }, at = { 0, 11.392, 23.3 } },
		},
		GardenStorey3_Beam = {
			{ mesh = 103602975627762, tex = "", size = { 15.48, 8.162, 11.28 }, at = { 0, 11.051, 23.3 } },
		},
		GardenStorey3_Board = {
			{ mesh = 123030168915077, tex = "", size = { 17.3, 9.968, 13.295 }, at = { 0, 10.826, 23.3 } },
		},
		GardenStorey3_Roof = {
			{ mesh = 96901842143312, tex = "", size = { 17.1, 6.491, 12.777 }, at = { 0, 12.935, 23.3 } },
		},
		-- The Breeding House's hall as Blender bodies (tools/blender/landmark_bodies.py): a body an era with its side
		-- rooms, and the pieces a level switches (era 1's truss, gable, lean-to and chimney; era 2's right wing; era
		-- 3's roof or its storey).
		BreedingBody1_Stone = {
			{ mesh = 139002923546090, tex = "", size = { 14.96, 0.52, 1.46 }, at = { 0, 0.66, 20.45 } },
		},
		BreedingBody1_Wall = {
			{ mesh = 82301667209695, tex = "", size = { 14.4, 10.87, 10.2 }, at = { 0, 5.835, 25.9 } },
		},
		BreedingBody1_Lower = {
			{ mesh = 130613333933210, tex = "", size = { 14.5, 2.62, 10.25 }, at = { 0, 1.71, 25.925 } },
		},
		BreedingBody1_Beam = {
			{ mesh = 122079320520634, tex = "", size = { 14.92, 10.734, 11.33 }, at = { 0, 5.767, 25.635 } },
		},
		BreedingBody1_Board = {
			{ mesh = 80773579587113, tex = "", size = { 17.142, 7.88, 13.54 }, at = { 0, 8.085, 25.5 } },
		},
		BreedingBody1_Roof = {
			{ mesh = 98386522678120, tex = "", size = { 18.275, 6.94, 13.5 }, at = { 0, 9.18, 25.5 } },
		},
		BreedingBody1_Frame = {
			{ mesh = 136485058367626, tex = "", size = { 13.878, 2.23, 9.86 }, at = { -0.681, 4.955, 26.49 } },
		},
		BreedingBody1_Glass = {
			{ mesh = 101370855658546, tex = "", size = { 13.098, 1.75, 9.08 }, at = { -0.711, 4.975, 26.52 } },
		},
		BreedingBody1_Shutters = {
			{ mesh = 105621482028490, tex = "", size = { 2.4, 3.6, 0.18 }, at = { 0, 2.2, 31.07 } },
		},
		BreedingBody2_Stone = {
			{ mesh = 96054382219114, tex = "", size = { 22.48, 0.62, 10.98 }, at = { 2.76, 0.71, 25.21 } },
		},
		BreedingBody2_Wall = {
			{ mesh = 74540903208191, tex = "", size = { 16.4, 11.913, 11 }, at = { 0, 6.356, 25.5 } },
		},
		BreedingBody2_Lower = {
			{ mesh = 135596471061953, tex = "", size = { 5.6, 12.5, 9.3 }, at = { 11, 6.65, 25.85 } },
		},
		BreedingBody2_Beam = {
			{ mesh = 90707065249458, tex = "", size = { 16.92, 11.78, 11.52 }, at = { 0, 6.29, 25.5 } },
		},
		BreedingBody2_Board = {
			{ mesh = 91311168472428, tex = "", size = { 24.148, 12.642, 13.54 }, at = { 2.52, 6.721, 25.5 } },
		},
		BreedingBody2_Roof = {
			{ mesh = 98406367046904, tex = "", size = { 23.656, 8.415, 13.5 }, at = { 2.556, 9.192, 25.5 } },
		},
		BreedingBody2_Frame = {
			{ mesh = 129435002187674, tex = "", size = { 21.02, 9.43, 3.44 }, at = { 3.11, 8.605, 29.7 } },
		},
		BreedingBody2_Glass = {
			{ mesh = 129493776889817, tex = "", size = { 13.96, 1.7, 0.72 }, at = { 0, 5, 30.7 } },
		},
		BreedingBody2_Shutters = {
			{ mesh = 105621482028490, tex = "", size = { 2.4, 3.6, 0.18 }, at = { 0, 2.2, 31.07 } },
		},
		BreedingBody3_Stone = {
			{ mesh = 114444464157053, tex = "", size = { 29.7, 15.5, 11.58 }, at = { 0.47, 8.15, 25.39 } },
		},
		BreedingBody3_Wall = {
			{ mesh = 130504197872617, tex = "", size = { 5.6, 5.252, 9.3 }, at = { -11.4, 6.226, 25.85 } },
		},
		BreedingBody3_Lower = {
			{ mesh = 105733832758816, tex = "", size = { 29.24, 12, 11 }, at = { 0.42, 6.4, 25.5 } },
		},
		BreedingBody3_Beam = {
			{ mesh = 80745899679467, tex = "", size = { 5.74, 5.104, 9.78 }, at = { -11.57, 6.152, 25.85 } },
		},
		BreedingBody3_Board = {
			{ mesh = 72739831530188, tex = "", size = { 7.189, 3.347, 10.84 }, at = { -11.4, 7.571, 25.85 } },
		},
		BreedingBody3_Roof = {
			{ mesh = 73726849131740, tex = "", size = { 6.768, 3.395, 10.8 }, at = { -11.4, 7.882, 25.85 } },
		},
		BreedingBody3_Frame = {
			{ mesh = 131880283036382, tex = "", size = { 30.04, 15.92, 12.14 }, at = { 0.4, 8.36, 25.35 } },
		},
		BreedingBody3_Glass = {
			{ mesh = 83854423549986, tex = "", size = { 19.61, 2.9, 5.86 }, at = { -4.455, 4.8, 28.13 } },
		},
		BreedingBody3_Shutters = {
			{ mesh = 127303669356147, tex = "", size = { 2, 3.6, 0.18 }, at = { 0, 2.2, 31.07 } },
		},
		BreedingBody4_Stone = {
			{ mesh = 132237864016650, tex = "", size = { 26.72, 0.7, 6.92 }, at = { 4.96, 0.75, 22.86 } },
		},
		BreedingBody4_Lower = {
			{ mesh = 92118266547692, tex = "", size = { 31.6, 17.216, 11.62 }, at = { 2.4, 9.008, 25.19 } },
		},
		BreedingBody4_Beam = {
			{ mesh = 127368987686746, tex = "", size = { 27, 14.954, 11.33 }, at = { 0, 9.977, 25.385 } },
		},
		BreedingBody4_Gold = {
			{ mesh = 103844438467493, tex = "", size = { 26.685, 12.012, 7.166 }, at = { 4.968, 11.256, 22.727 } },
		},
		BreedingBody4_Board = {
			{ mesh = 72551178320228, tex = "", size = { 2.16, 13.1, 2.16 }, at = { 17.35, 10.55, 25.35 } },
		},
		BreedingBody4_Roof = {
			{ mesh = 128878012127430, tex = "", size = { 26.68, 12.31, 11 }, at = { 0, 10.955, 25.5 } },
		},
		BreedingBody4_Frame = {
			{ mesh = 126315511006363, tex = "", size = { 31.95, 15.474, 11.87 }, at = { 2.425, 9.937, 25.215 } },
		},
		BreedingBody5_Stone = {
			{ mesh = 122335954051646, tex = "", size = { 35.64, 7.4, 11.6 }, at = { 2.52, 4.1, 25.5 } },
		},
		BreedingBody5_Wall = {
			{ mesh = 127339976695914, tex = "", size = { 35.04, 15.5, 13 }, at = { 2.52, 8.15, 24.5 } },
		},
		BreedingBody5_Beam = {
			{ mesh = 71790837186107, tex = "", size = { 30.28, 8.03, 10.62 }, at = { 0, 5.135, 25.19 } },
		},
		BreedingBody5_Gold = {
			{ mesh = 133290138772178, tex = "", size = { 35.66, 15.52, 14.74 }, at = { 2.41, 8.16, 24.5 } },
		},
		BreedingBody5_Roof = {
			{ mesh = 95249076100108, tex = "", size = { 20.89, 4.784, 14.7 }, at = { 0, 12.508, 24.5 } },
		},
		BreedingBody5_Glass = {
			{ mesh = 70394029696957, tex = "", size = { 30.12, 4.9, 6.01 }, at = { 0, 4.95, 28.055 } },
		},
		BreedingTruss1_Beam = {
			{ mesh = 106167394700945, tex = "", size = { 11.401, 4.485, 0.6 }, at = { 0, 9.087, 20.3 } },
		},
		BreedingGable1_Wall = {
			{ mesh = 72699612627525, tex = "", size = { 12.296, 4.27, 0.6 }, at = { 0, 9.135, 20.3 } },
		},
		BreedingGable1_Beam = {
			{ mesh = 105546422917987, tex = "", size = { 12.6, 4.154, 0.31 }, at = { 0, 9.057, 19.895 } },
		},
		BreedingLean1_Wall = {
			{ mesh = 140596956852360, tex = "", size = { 4.6, 1.85, 9.3 }, at = { 9.5, 4.625, 25.85 } },
		},
		BreedingLean1_Lower = {
			{ mesh = 81134388688008, tex = "", size = { 4.65, 3.32, 9.4 }, at = { 9.525, 2.06, 25.85 } },
		},
		BreedingLean1_Beam = {
			{ mesh = 121301074544412, tex = "", size = { 4.9, 3.52, 9.94 }, at = { 9.65, 2.16, 25.85 } },
		},
		BreedingLean1_Roof = {
			{ mesh = 107134252976410, tex = "", size = { 6.398, 2.704, 10.8 }, at = { 10.247, 4.894, 25.85 } },
		},
		BreedingChimney1_Stone = {
			{ mesh = 116953671638058, tex = "", size = { 1.9, 6.6, 1.9 }, at = { 10.4, 7.1, 29 } },
		},
		BreedingChimney1_Frame = {
			{ mesh = 110154066508723, tex = "", size = { 2.34, 0.44, 2.34 }, at = { 10.4, 10.6, 29 } },
		},
		BreedingWing2_Wall = {
			{ mesh = 92226855843258, tex = "", size = { 5.2, 6.882, 9.3 }, at = { -10.8, 3.841, 25.85 } },
		},
		BreedingWing2_Beam = {
			{ mesh = 138667088701719, tex = "", size = { 5.44, 6.734, 9.82 }, at = { -10.92, 3.767, 25.83 } },
		},
		BreedingWing2_Board = {
			{ mesh = 109649084132134, tex = "", size = { 6.789, 3.177, 10.84 }, at = { -10.8, 6.086, 25.85 } },
		},
		BreedingWing2_Roof = {
			{ mesh = 127571634727638, tex = "", size = { 6.368, 3.225, 10.8 }, at = { -10.8, 6.397, 25.85 } },
		},
		BreedingWing2_Frame = {
			{ mesh = 122136916965043, tex = "", size = { 1.22, 2.18, 2.24 }, at = { -13.21, 3.38, 25.85 } },
		},
		BreedingWing2_Glass = {
			{ mesh = 129882678896410, tex = "", size = { 0.72, 1.7, 1.4 }, at = { -13.1, 3.4, 25.85 } },
		},
		BreedingRoof3_Wall = {
			{ mesh = 74991042416643, tex = "", size = { 14.738, 4.113, 11 }, at = { 0, 10.456, 25.5 } },
		},
		BreedingRoof3_Beam = {
			{ mesh = 78963534846319, tex = "", size = { 15.4, 4.008, 11.52 }, at = { 0, 10.384, 25.5 } },
		},
		BreedingRoof3_Board = {
			{ mesh = 113887583957919, tex = "", size = { 19.663, 6.188, 13.34 }, at = { 0, 10.177, 25.5 } },
		},
		BreedingRoof3_Roof = {
			{ mesh = 79147685127080, tex = "", size = { 19.127, 6.226, 13.3 }, at = { 0, 10.487, 25.5 } },
		},
		BreedingStorey3_Wall = {
			{ mesh = 106759835972231, tex = "", size = { 17.8, 7.518, 11.8 }, at = { 0, 12.559, 25.3 } },
		},
		BreedingStorey3_Beam = {
			{ mesh = 134281042654461, tex = "", size = { 18.28, 7.824, 12.32 }, at = { 0, 12.282, 25.3 } },
		},
		BreedingStorey3_Board = {
			{ mesh = 93518881558589, tex = "", size = { 20.251, 9.893, 13.94 }, at = { 0, 12.131, 25.2 } },
		},
		BreedingStorey3_Roof = {
			{ mesh = 139087413268022, tex = "", size = { 19.723, 6.213, 13.9 }, at = { 0, 14.293, 25.2 } },
		},
		-- the Training Hall's Blender bodies (tools/blender/landmark_bodies.py): the hall of each era, the tower at its
		-- two heights, and the pieces a level switches
		TrainingBody1_Stone = {
			{ mesh = 116871946801379, tex = "", size = { 20.56, 0.52, 1.46 }, at = { 0, 0.66, 17.85 } },
		},
		TrainingBody1_Wall = {
			{ mesh = 99834094867260, tex = "", size = { 20.1, 11.5, 12.45 }, at = { 0, 6.15, 24.425 } },
		},
		TrainingBody1_Lower = {
			{ mesh = 90736079478376, tex = "", size = { 20.1, 2.62, 12.45 }, at = { 0, 1.71, 24.425 } },
		},
		TrainingBody1_Beam = {
			{ mesh = 83684988317603, tex = "", size = { 20.52, 11.372, 13.53 }, at = { 0, 6.086, 24.135 } },
		},
		TrainingBody1_Board = {
			{ mesh = 100399577543441, tex = "", size = { 22.689, 9.223, 15.74 }, at = { 0, 8.046, 24 } },
		},
		TrainingBody1_Roof = {
			{ mesh = 133988579948641, tex = "", size = { 23.899, 7.857, 15.7 }, at = { 0, 9.321, 24 } },
		},
		TrainingBody1_Frame = {
			{ mesh = 112136950299489, tex = "", size = { 20.84, 2.06, 9.19 }, at = { 0, 4.87, 26.425 } },
		},
		TrainingBody1_Glass = {
			{ mesh = 92664883119129, tex = "", size = { 20.12, 1.6, 8.41 }, at = { 0, 4.9, 26.455 } },
		},
		TrainingBody1_Shutters = {
			{ mesh = 115101683513326, tex = "", size = { 2.4, 3.6, 0.18 }, at = { 0, 2.2, 30.67 } },
		},
		TrainingBody2_Stone = {
			{ mesh = 91063657740464, tex = "", size = { 21.76, 0.52, 1.46 }, at = { 0, 0.66, 17.85 } },
		},
		TrainingBody2_Wall = {
			{ mesh = 75357246278726, tex = "", size = { 21.2, 12.499, 13.2 }, at = { 0, 6.65, 24 } },
		},
		TrainingBody2_Beam = {
			{ mesh = 131481405579382, tex = "", size = { 21.72, 12.37, 13.72 }, at = { 0, 6.585, 24 } },
		},
		TrainingBody2_Board = {
			{ mesh = 109727748799860, tex = "", size = { 23.891, 13.256, 15.74 }, at = { 0, 7.028, 24 } },
		},
		TrainingBody2_Roof = {
			{ mesh = 90580683309450, tex = "", size = { 23.334, 7.917, 15.7 }, at = { 0, 10.041, 24 } },
		},
		TrainingBody2_Frame = {
			{ mesh = 125037196312989, tex = "", size = { 22.04, 2.48, 12.19 }, at = { 0, 4.28, 24.925 } },
		},
		TrainingBody2_Glass = {
			{ mesh = 132971251501808, tex = "", size = { 21.32, 2, 11.41 }, at = { 0, 4.3, 24.955 } },
		},
		TrainingBody2_Shutters = {
			{ mesh = 115101683513326, tex = "", size = { 2.4, 3.6, 0.18 }, at = { 0, 2.2, 30.67 } },
		},
		TrainingBody3_Stone = {
			{ mesh = 97507536286480, tex = "", size = { 22.36, 7.366, 13.78 }, at = { 0, 4.083, 23.89 } },
		},
		TrainingBody3_Lower = { { mesh = 96969834392903, tex = "", size = { 22, 7.4, 13.2 }, at = { 0, 4.1, 24 } } },
		TrainingBody3_Frame = {
			{ mesh = 76173795716451, tex = "", size = { 22.84, 7.497, 14.34 }, at = { 0, 4.149, 23.85 } },
		},
		TrainingBody3_Glass = {
			{ mesh = 93589270316258, tex = "", size = { 22.12, 2.4, 10.66 }, at = { 0, 4.1, 25.33 } },
		},
		TrainingBody3_Shutters = {
			{ mesh = 90788353142637, tex = "", size = { 2, 3.6, 0.18 }, at = { 0, 2.2, 30.67 } },
		},
		TrainingBody4_Stone = {
			{ mesh = 78240380818300, tex = "", size = { 23.84, 0.72, 1.74 }, at = { 0, 0.76, 17.55 } },
		},
		TrainingBody4_Lower = {
			{ mesh = 140090268065769, tex = "", size = { 23.474, 15.015, 13.82 }, at = { 0, 7.908, 23.69 } },
		},
		TrainingBody4_Beam = {
			{ mesh = 84425974097687, tex = "", size = { 23.7, 12.154, 13.85 }, at = { 0, 9.177, 23.725 } },
		},
		TrainingBody4_Gold = {
			{ mesh = 133594385195893, tex = "", size = { 23.48, 13.546, 14.17 }, at = { -0.016, 8.25, 23.629 } },
		},
		TrainingBody4_Roof = {
			{ mesh = 128684037553814, tex = "", size = { 23.2, 8.51, 13.2 }, at = { 0, 10.655, 24 } },
		},
		TrainingBody4_Frame = {
			{ mesh = 117422003825057, tex = "", size = { 24.239, 12.662, 14.07 }, at = { 0, 9.131, 23.715 } },
		},
		TrainingBody5_Stone = {
			{ mesh = 73185451459027, tex = "", size = { 31.3, 6.72, 13.83 }, at = { -2.99, 3.76, 23.985 } },
		},
		TrainingBody5_Wall = {
			{ mesh = 83111030341305, tex = "", size = { 30.72, 17, 15.2 }, at = { -2.96, 8.9, 23 } },
		},
		TrainingBody5_Beam = {
			{ mesh = 80562515597746, tex = "", size = { 25.12, 6.9, 11.22 }, at = { 0, 4.7, 22.89 } },
		},
		TrainingBody5_Gold = {
			{ mesh = 80403530263838, tex = "", size = { 31.15, 16.7, 15.97 }, at = { -2.875, 8.75, 23.035 } },
		},
		TrainingBody5_Glass = { { mesh = 81909712033192, tex = "", size = { 14.9, 3.2, 0.72 }, at = { 0, 5.3, 30.3 } } },
		TrainingBody5_Shutters = {
			{ mesh = 103639335518654, tex = "", size = { 2.2, 4.2, 0.18 }, at = { 0, 2.5, 30.67 } },
		},
		TrainingTruss1_Beam = {
			{ mesh = 122023136878241, tex = "", size = { 16.558, 5.494, 0.6 }, at = { 0, 9.183, 17.7 } },
		},
		TrainingGable1_Wall = {
			{ mesh = 83048315896508, tex = "", size = { 17.668, 5.3, 0.6 }, at = { 0, 9.25, 17.7 } },
		},
		TrainingGable1_Beam = {
			{ mesh = 114140466824752, tex = "", size = { 18.2, 5.192, 0.31 }, at = { 0, 9.176, 17.295 } },
		},
		TrainingLookout1_Beam = {
			{ mesh = 94321099778341, tex = "", size = { 5.02, 7.925, 5.02 }, at = { -13.3, 4.362, 20.7 } },
		},
		TrainingLookout1_Board = {
			{ mesh = 72428267095197, tex = "", size = { 4.9, 7.216, 6.428 }, at = { -13.3, 3.992, 19.936 } },
		},
		TrainingLookout1_Shutters = {
			{ mesh = 94115702695656, tex = "", size = { 5.16, 0.44, 5.16 }, at = { -13.3, 6.6, 20.7 } },
		},
		TrainingCabin1_Wall = {
			{ mesh = 92325209403093, tex = "", size = { 3.6, 3.02, 3.6 }, at = { -13.3, 11.71, 20.7 } },
		},
		TrainingCabin1_Beam = {
			{ mesh = 105546132492387, tex = "", size = { 4.28, 6.42, 4.28 }, at = { -13.3, 10.01, 20.7 } },
		},
		TrainingCabin1_Board = {
			{ mesh = 116555740884517, tex = "", size = { 4.06, 1.448, 4.06 }, at = { -13.3, 9.1, 20.7 } },
		},
		TrainingCabin1_Shutters = {
			{ mesh = 135782061999876, tex = "", size = { 4.86, 0.44, 4.86 }, at = { -13.3, 10, 20.7 } },
		},
		TrainingTower2_Stone = {
			{ mesh = 85103607610119, tex = "", size = { 5.16, 0.93, 5.16 }, at = { -14.1, 0.865, 20.7 } },
		},
		TrainingTower2_Wall = {
			{ mesh = 83845840240441, tex = "", size = { 4.64, 10.35, 4.64 }, at = { -14.1, 6.425, 20.7 } },
		},
		TrainingTower2_Beam = {
			{ mesh = 104824906775427, tex = "", size = { 5.14, 10, 5.14 }, at = { -14.1, 6.3, 20.7 } },
		},
		TrainingTower2_Board = {
			{ mesh = 94956330478221, tex = "", size = { 5.54, 0.44, 5.54 }, at = { -14.1, 11.4, 20.7 } },
		},
		TrainingTall2_Stone = {
			{ mesh = 85103607610119, tex = "", size = { 5.16, 0.93, 5.16 }, at = { -14.1, 0.865, 20.7 } },
		},
		TrainingTall2_Wall = {
			{ mesh = 115946865423951, tex = "", size = { 4.64, 13.35, 4.64 }, at = { -14.1, 7.925, 20.7 } },
		},
		TrainingTall2_Beam = {
			{ mesh = 140395789857965, tex = "", size = { 5.14, 13, 5.14 }, at = { -14.1, 7.8, 20.7 } },
		},
		TrainingTall2_Board = {
			{ mesh = 94956330478221, tex = "", size = { 5.54, 0.44, 5.54 }, at = { -14.1, 14.4, 20.7 } },
		},
		TrainingTower3_Stone = {
			{ mesh = 83209612760320, tex = "", size = { 6.08, 1.12, 6.08 }, at = { -14.3, 0.96, 20.7 } },
		},
		TrainingTower3_Lower = {
			{ mesh = 122036641288399, tex = "", size = { 5.44, 13.42, 5.44 }, at = { -14.3, 8.01, 20.7 } },
		},
		TrainingTower3_Frame = {
			{ mesh = 70418966044280, tex = "", size = { 5.68, 4.36, 5.68 }, at = { -14.3, 7.4, 20.7 } },
		},
		TrainingTall3_Stone = {
			{ mesh = 83209612760320, tex = "", size = { 6.08, 1.12, 6.08 }, at = { -14.3, 0.96, 20.7 } },
		},
		TrainingTall3_Lower = {
			{ mesh = 126843206893301, tex = "", size = { 7.08, 17.02, 7.08 }, at = { -14.3, 9.81, 20.7 } },
		},
		TrainingTall3_Frame = {
			{ mesh = 110095325855893, tex = "", size = { 6.7, 10.63, 6.7 }, at = { -14.3, 10.535, 20.7 } },
		},
		TrainingTower4_Stone = {
			{ mesh = 103525950219326, tex = "", size = { 6.08, 1.12, 6.08 }, at = { -14.6, 0.96, 20.7 } },
		},
		TrainingTower4_Lower = {
			{ mesh = 115631462570347, tex = "", size = { 5.44, 15.3, 5.44 }, at = { -14.6, 8.95, 20.7 } },
		},
		TrainingTower4_Beam = {
			{ mesh = 131232025211306, tex = "", size = { 5.72, 13.2, 5.72 }, at = { -14.6, 10, 20.7 } },
		},
		TrainingTower4_Gold = {
			{ mesh = 97622250431934, tex = "", size = { 5.625, 13.047, 5.625 }, at = { -14.6, 10, 20.7 } },
		},
		TrainingTall4_Stone = {
			{ mesh = 103525950219326, tex = "", size = { 6.08, 1.12, 6.08 }, at = { -14.6, 0.96, 20.7 } },
		},
		TrainingTall4_Lower = {
			{ mesh = 90072828685909, tex = "", size = { 5.72, 15.33, 5.72 }, at = { -14.6, 8.965, 20.7 } },
		},
		TrainingTall4_Beam = {
			{ mesh = 138038601527567, tex = "", size = { 5.72, 12.22, 5.72 }, at = { -14.6, 9.51, 20.7 } },
		},
		TrainingTall4_Gold = {
			{ mesh = 128760072309758, tex = "", size = { 5.625, 6.647, 5.625 }, at = { -14.6, 6.8, 20.7 } },
		},
		TrainingRoof3_Stone = {
			{ mesh = 97586312782333, tex = "", size = { 23.44, 0.82, 1.64 }, at = { 0, 0.81, 16.5 } },
		},
		TrainingRoof3_Wall = {
			{ mesh = 126252867623244, tex = "", size = { 19.355, 4.927, 13 }, at = { 0, 10.263, 24.1 } },
		},
		TrainingRoof3_Lower = {
			{ mesh = 138406635204090, tex = "", size = { 23.06, 7.9, 1.54 }, at = { 0, 4.35, 16.65 } },
		},
		TrainingRoof3_Beam = {
			{ mesh = 103585244163691, tex = "", size = { 20.2, 4.825, 13.52 }, at = { 0, 10.192, 24.1 } },
		},
		TrainingRoof3_Board = {
			{ mesh = 87000167915391, tex = "", size = { 23.631, 6.752, 14.54 }, at = { 0, 10.111, 24.1 } },
		},
		TrainingRoof3_Roof = {
			{ mesh = 88378826666298, tex = "", size = { 23.118, 6.789, 14.5 }, at = { 0, 10.405, 24.1 } },
		},
		TrainingRoof3_Frame = {
			{ mesh = 101143769003167, tex = "", size = { 23.44, 1.24, 1.64 }, at = { 0, 8, 16.5 } },
		},
		TrainingStorey3_Stone = {
			{ mesh = 97586312782333, tex = "", size = { 23.44, 0.82, 1.64 }, at = { 0, 0.81, 16.5 } },
		},
		TrainingStorey3_Wall = {
			{ mesh = 98283419208301, tex = "", size = { 22, 7.927, 13 }, at = { 0, 12.163, 24.1 } },
		},
		TrainingStorey3_Lower = {
			{ mesh = 99494976129853, tex = "", size = { 23.06, 11.3, 1.54 }, at = { 0, 6.05, 16.65 } },
		},
		TrainingStorey3_Beam = {
			{ mesh = 85521614873553, tex = "", size = { 22.48, 8.235, 13.52 }, at = { 0, 11.887, 24.1 } },
		},
		TrainingStorey3_Board = {
			{ mesh = 132733024710713, tex = "", size = { 23.631, 6.752, 14.54 }, at = { 0, 13.511, 24.1 } },
		},
		TrainingStorey3_Roof = {
			{ mesh = 81332638468369, tex = "", size = { 23.118, 6.789, 14.5 }, at = { 0, 13.805, 24.1 } },
		},
		TrainingStorey3_Frame = {
			{ mesh = 96968738013460, tex = "", size = { 23.44, 4.64, 1.64 }, at = { 0, 9.7, 16.5 } },
		},
		TrainingRoof5_Wall = {
			{ mesh = 92410567546789, tex = "", size = { 15.669, 3.25, 15.2 }, at = { 0, 11.525, 23 } },
		},
		TrainingRoof5_Gold = {
			{ mesh = 117817968473605, tex = "", size = { 20.564, 5.068, 16.94 }, at = { 0, 11.38, 23 } },
		},
		TrainingRoof5_Roof = {
			{ mesh = 128353454688045, tex = "", size = { 20.1, 5.103, 16.9 }, at = { 0, 11.648, 23 } },
		},
		TrainingVault5_Stone = {
			{ mesh = 112008455491527, tex = "", size = { 18.46, 0.31, 11.86 }, at = { 0, 10.025, 24.7 } },
		},
		TrainingVault5_Wall = {
			{ mesh = 115752264773303, tex = "", size = { 15.669, 3.25, 3.4 }, at = { 0, 11.525, 17.1 } },
		},
		TrainingVault5_Gold = {
			{ mesh = 100517943520985, tex = "", size = { 20.564, 7.308, 16.02 }, at = { 0, 12.5, 22.54 } },
		},
		TrainingVault5_Roof = {
			{ mesh = 140406741628225, tex = "", size = { 20.1, 6.763, 15.95 }, at = { 0, 12.478, 22.525 } },
		},
		DockBody1_Stone = {
			{ mesh = 139056677369801, tex = "", size = { 15.64, 0.72, 10.62 }, at = { -2, 0.06, 33.91 } },
		},
		DockBody1_Wall = {
			{ mesh = 86581389982832, tex = "", size = { 15.3, 10.264, 10.45 }, at = { -2, 5.532, 33.825 } },
		},
		DockBody1_Lower = {
			{ mesh = 121760441279827, tex = "", size = { 15.3, 1.42, 10.45 }, at = { -2, 1.11, 33.825 } },
		},
		DockBody1_Beam = {
			{ mesh = 102500048906745, tex = "", size = { 15.72, 13.527, 10.87 }, at = { -2, 3.764, 33.865 } },
		},
		DockBody1_Board = {
			{ mesh = 80529029706238, tex = "", size = { 17.95, 7.599, 12.94 }, at = { -2, 7.62, 33.8 } },
		},
		DockBody1_Roof = {
			{ mesh = 103664422809610, tex = "", size = { 19.07, 7.354, 12.9 }, at = { -2, 8.373, 33.8 } },
		},
		DockBody1_Frame = {
			{ mesh = 84988286542364, tex = "", size = { 16.04, 2.06, 6.69 }, at = { -2, 4.27, 36.075 } },
		},
		DockBody1_Glass = {
			{ mesh = 108151202795190, tex = "", size = { 15.32, 1.6, 5.91 }, at = { -2, 4.3, 36.105 } },
		},
		DockBody1_Shutters = { { mesh = 116827104770758, tex = "", size = { 2, 3.4, 0.18 }, at = { -2, 2.1, 39.07 } } },
		DockBody2_Stone = {
			{ mesh = 78766630181472, tex = "", size = { 16.44, 0.72, 10.62 }, at = { -2, 0.06, 33.91 } },
		},
		DockBody2_Wall = { { mesh = 113997247544217, tex = "", size = { 16, 10.916, 10.4 }, at = { -2, 5.858, 33.8 } } },
		DockBody2_Beam = {
			{ mesh = 118674349098260, tex = "", size = { 16.48, 14.18, 10.92 }, at = { -2, 4.09, 33.8 } },
		},
		DockBody2_Gold = {
			{ mesh = 116340084795846, tex = "", size = { 14.906, 1.709, 0.26 }, at = { -2, 5.075, 28.85 } },
		},
		DockBody2_Board = {
			{ mesh = 81357870842951, tex = "", size = { 18.322, 11.631, 12.54 }, at = { -2, 6.215, 33.8 } },
		},
		DockBody2_Roof = {
			{ mesh = 71281774975643, tex = "", size = { 17.749, 7.019, 12.5 }, at = { -2, 8.891, 33.8 } },
		},
		DockBody2_Frame = {
			{ mesh = 134463878326611, tex = "", size = { 8.26, 2.48, 1.22 }, at = { -2, 4.28, 38.81 } },
		},
		DockBody2_Glass = { { mesh = 83451425143235, tex = "", size = { 7.42, 2, 0.72 }, at = { -2, 4.3, 38.7 } } },
		DockBody2_Shutters = { { mesh = 116827104770758, tex = "", size = { 2, 3.4, 0.18 }, at = { -2, 2.1, 39.07 } } },
		DockBody3_Stone = { { mesh = 73349144716625, tex = "", size = { 16.82, 8.6, 11.09 }, at = { -2, 4, 33.635 } } },
		DockBody3_Lower = { { mesh = 138530098024533, tex = "", size = { 16.4, 6.8, 10.4 }, at = { -2, 3.8, 33.8 } } },
		DockBody3_Frame = { { mesh = 127814262513812, tex = "", size = { 17, 6.78, 11.5 }, at = { -2, 3.79, 33.67 } } },
		DockBody3_Glass = { { mesh = 74317405103951, tex = "", size = { 10, 2.4, 0.72 }, at = { -2, 4.1, 38.7 } } },
		DockBody3_Shutters = { { mesh = 124661210707328, tex = "", size = { 2, 3.6, 0.18 }, at = { -2, 2.2, 39.07 } } },
		DockBody4_Stone = { { mesh = 74532824492941, tex = "", size = { 17.46, 1.4, 2.56 }, at = { -2, 0.4, 29.2 } } },
		DockBody4_Lower = { { mesh = 85119558231657, tex = "", size = { 16.8, 7, 10.4 }, at = { -2, 3.9, 33.8 } } },
		DockBody4_Gold = {
			{ mesh = 124596175075827, tex = "", size = { 17.435, 15.079, 11.266 }, at = { -2.015, 8.444, 33.603 } },
		},
		DockBody4_Board = {
			{ mesh = 97726520538443, tex = "", size = { 17.7, 16.395, 11.05 }, at = { -2, 8.198, 33.615 } },
		},
		DockBody4_Roof = { { mesh = 86717094914554, tex = "", size = { 17.2, 8.51, 10.4 }, at = { -2, 11.655, 33.8 } } },
		DockBody4_Frame = {
			{ mesh = 124229111162800, tex = "", size = { 18.199, 16.042, 11.3 }, at = { -2, 8.421, 33.65 } },
		},
		DockBody5_Stone = {
			{ mesh = 107466676719141, tex = "", size = { 17.4, 1.55, 10.87 }, at = { -2, 0.575, 33.865 } },
		},
		DockBody5_Wall = { { mesh = 112900456241832, tex = "", size = { 18.1, 11, 10.85 }, at = { -2, 5.9, 33.575 } } },
		DockBody5_Beam = {
			{ mesh = 81674476818471, tex = "", size = { 17.24, 9.47, 10.66 }, at = { -2, 6.085, 33.81 } },
		},
		DockBody5_Gold = {
			{ mesh = 113494114820213, tex = "", size = { 17.52, 10.97, 11.02 }, at = { -2, 5.885, 33.91 } },
		},
		DockBody5_Glass = { { mesh = 71586637881977, tex = "", size = { 13.9, 3.2, 0.72 }, at = { -2, 5.3, 38.7 } } },
		DockBody5_Shutters = {
			{ mesh = 109782581904315, tex = "", size = { 2.2, 4.2, 0.18 }, at = { -2, 2.5, 39.07 } },
		},
		DockTruss1_Board = {
			{ mesh = 83999974512289, tex = "", size = { 12.235, 4.863, 0.5 }, at = { -2, 8.298, 28.9 } },
		},
		DockGable1_Wall = {
			{ mesh = 129162315870957, tex = "", size = { 13.128, 4.664, 0.6 }, at = { -2, 8.332, 28.9 } },
		},
		DockGable1_Beam = {
			{ mesh = 134999700603361, tex = "", size = { 13.4, 4.547, 0.31 }, at = { -2, 8.254, 28.495 } },
		},
		DockRoof3_Wall = {
			{ mesh = 97558648535741, tex = "", size = { 14.313, 4.713, 10.4 }, at = { -2, 9.556, 33.8 } },
		},
		DockRoof3_Beam = { { mesh = 74775099986428, tex = "", size = { 14.6, 4.6, 10.92 }, at = { -2, 9.48, 33.8 } } },
		DockRoof3_Board = {
			{ mesh = 89727279549389, tex = "", size = { 18.708, 6.764, 12.54 }, at = { -2, 9.26, 33.8 } },
		},
		DockRoof3_Roof = {
			{ mesh = 97298109450488, tex = "", size = { 18.143, 6.806, 12.5 }, at = { -2, 9.597, 33.8 } },
		},
		DockStorey3_Wall = {
			{ mesh = 70906384354269, tex = "", size = { 16.4, 7.313, 10.8 }, at = { -2, 11.256, 33.6 } },
		},
		DockStorey3_Beam = {
			{ mesh = 118846574590090, tex = "", size = { 16.88, 7.61, 11.32 }, at = { -2, 10.975, 33.6 } },
		},
		DockStorey3_Board = {
			{ mesh = 121275647000318, tex = "", size = { 18.708, 6.764, 12.94 }, at = { -2, 12.26, 33.6 } },
		},
		DockStorey3_Roof = {
			{ mesh = 98070737751230, tex = "", size = { 18.143, 6.806, 12.9 }, at = { -2, 12.597, 33.6 } },
		},
		DockRoof5_Wall = {
			{ mesh = 96303292779701, tex = "", size = { 14.501, 4.316, 10.7 }, at = { -2, 13.558, 33.65 } },
		},
		DockRoof5_Gold = {
			{ mesh = 100911560045500, tex = "", size = { 18.68, 6.223, 12.44 }, at = { -2, 13.35, 33.65 } },
		},
		DockRoof5_Roof = {
			{ mesh = 139334617074336, tex = "", size = { 18.133, 6.262, 12.4 }, at = { -2, 13.669, 33.65 } },
		},
		DockVault5_Wall = {
			{ mesh = 129326257689039, tex = "", size = { 14.501, 4.316, 2.6 }, at = { -2, 13.558, 29.6 } },
		},
		DockVault5_Gold = {
			{ mesh = 116696464332672, tex = "", size = { 18.68, 7.366, 11.67 }, at = { -2, 13.921, 33.265 } },
		},
		DockVault5_Roof = {
			{ mesh = 136951782889707, tex = "", size = { 18.133, 6.772, 11.55 }, at = { -2, 13.924, 33.225 } },
		},
		DockLight1_Stone = { { mesh = 101383843333748, tex = "", size = { 6.6, 3.82, 6.6 }, at = { 12, -1.09, 32.5 } } },
		DockLight1_Frame = { { mesh = 94270040683109, tex = "", size = { 6.68, 0.3, 6.68 }, at = { 12, 0.95, 32.5 } } },
		DockLight1_White = { { mesh = 116611253694933, tex = "", size = { 5, 11.1, 5 }, at = { 12, 6.65, 32.5 } } },
		DockLight1_Red = { { mesh = 101396714478634, tex = "", size = { 4.28, 2.22, 4.28 }, at = { 12, 8.87, 32.5 } } },
		DockLight2_Stone = { { mesh = 101383843333748, tex = "", size = { 6.6, 3.82, 6.6 }, at = { 12, -1.09, 32.5 } } },
		DockLight2_Frame = { { mesh = 94270040683109, tex = "", size = { 6.68, 0.3, 6.68 }, at = { 12, 0.95, 32.5 } } },
		DockLight2_White = { { mesh = 116611253694933, tex = "", size = { 5, 11.1, 5 }, at = { 12, 6.65, 32.5 } } },
		DockLight2_Red = { { mesh = 101396714478634, tex = "", size = { 4.28, 2.22, 4.28 }, at = { 12, 8.87, 32.5 } } },
		DockLight3_Stone = { { mesh = 133885142229466, tex = "", size = { 6.6, 17.8, 6.6 }, at = { 12, 5.9, 32.5 } } },
		DockLight3_Frame = {
			{ mesh = 89109328311625, tex = "", size = { 6.68, 11.837, 6.68 }, at = { 12, 6.718, 32.5 } },
		},
		DockLight4_Stone = { { mesh = 138494918188003, tex = "", size = { 5, 16.3, 5 }, at = { 12, 9.25, 32.5 } } },
		DockLight4_Lower = { { mesh = 101383843333748, tex = "", size = { 6.6, 3.82, 6.6 }, at = { 12, -1.09, 32.5 } } },
		DockLight4_Gold = {
			{ mesh = 126730375881863, tex = "", size = { 6.68, 14.424, 6.68 }, at = { 12, 8.012, 32.5 } },
		},
		DockLight4_Board = {
			{ mesh = 116179569578434, tex = "", size = { 5.149, 16.315, 5.149 }, at = { 12, 9.25, 32.5 } },
		},
		DockLight5_Stone = { { mesh = 101383843333748, tex = "", size = { 6.6, 3.82, 6.6 }, at = { 12, -1.09, 32.5 } } },
		DockLight5_Wall = { { mesh = 117915644230163, tex = "", size = { 5, 18.9, 5 }, at = { 12, 10.55, 32.5 } } },
		DockLight5_Gold = {
			{ mesh = 96937875110711, tex = "", size = { 6.68, 16.957, 6.68 }, at = { 12, 9.279, 32.5 } },
		},
		DockTall2_Stone = { { mesh = 101383843333748, tex = "", size = { 6.6, 3.82, 6.6 }, at = { 12, -1.09, 32.5 } } },
		DockTall2_Frame = { { mesh = 94270040683109, tex = "", size = { 6.68, 0.3, 6.68 }, at = { 12, 0.95, 32.5 } } },
		DockTall2_White = { { mesh = 101558919991893, tex = "", size = { 5, 13.7, 5 }, at = { 12, 7.95, 32.5 } } },
		DockTall2_Red = { { mesh = 76628018186178, tex = "", size = { 4.6, 6.85, 4.6 }, at = { 12, 9.092, 32.5 } } },
		DockTall3_Stone = { { mesh = 117852549282518, tex = "", size = { 6.6, 20.4, 6.6 }, at = { 12, 7.2, 32.5 } } },
		DockTall3_Frame = {
			{ mesh = 116175260898607, tex = "", size = { 6.68, 14.391, 6.68 }, at = { 12, 7.996, 32.5 } },
		},
		DockTall4_Stone = { { mesh = 117915644230163, tex = "", size = { 5, 18.9, 5 }, at = { 12, 10.55, 32.5 } } },
		DockTall4_Lower = { { mesh = 101383843333748, tex = "", size = { 6.6, 3.82, 6.6 }, at = { 12, -1.09, 32.5 } } },
		DockTall4_Gold = {
			{ mesh = 109164046362275, tex = "", size = { 6.68, 16.99, 6.68 }, at = { 12, 9.295, 32.5 } },
		},
		DockTall4_Board = {
			{ mesh = 137966110430542, tex = "", size = { 5.17, 18.913, 5.17 }, at = { 12, 10.55, 32.5 } },
		},
		DockTall5_Stone = { { mesh = 101383843333748, tex = "", size = { 6.6, 3.82, 6.6 }, at = { 12, -1.09, 32.5 } } },
		DockTall5_Wall = { { mesh = 98770249181489, tex = "", size = { 5, 21.5, 5 }, at = { 12, 11.85, 32.5 } } },
		DockTall5_Gold = {
			{ mesh = 134345513952006, tex = "", size = { 6.68, 19.531, 6.68 }, at = { 12, 10.566, 32.5 } },
		},
	},
}
