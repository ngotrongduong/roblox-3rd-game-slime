# Lessons from building in Studio

Read this before every build job; add to it at the end of every job (the owner's rule, 2026-10-21: "after building,
compare with the reference, list what is not met, fix, check again, a few rounds; then draw the lessons and keep them
for the next builds"). One lesson a line: what happened, what to do instead. Newest at the bottom of its section.

The lessons dated before 2026-10-27 were learnt in the owner's previous game, Egg Heist (its "realm" map: a valley,
lakes, a waterfall, a portal, caves), copied from `C:\roblox 2nd game\.claude\skills\studio-build\LESSONS.md`. The
scripts they name (`tools/realm/...`) live in that project: read them there, never edit them. The section on caves
was left there (this game has none); read it there if a cave is ever wanted.

## Generating models (generate_mesh)

- 2026-10-21. A label at the front of the prompt ("kit tree_oak_big: ...") and a long style tail after it gave odd
  shapes (a dead tree like coral, vines as flat tiles). Prompt only `stylized low poly cartoon <thing>, <what it looks
  like>, flat matte colours, game asset`.
- 2026-10-21. More than 3 jobs at a time: "Too Many Requests" and failures. 3 at a time.
- 2026-10-21. "Model generation should only be called from the server" = Studio was in Play mode (the owner testing).
  Check `get_studio_state`, wait, retry.
- 2026-10-21. Very small boxes (a bush of 6 studs) gave poor, tiny models: generate in a box whose longest side is about
  20, then scale to the real size.
- 2026-10-21. Say "trunk clearly visible" for trees; name the parts that must show.
- 2026-10-21. Vines were the weakest (a wall patch of ivy became a box, a garland a flat ring): describe a vine as a
  standalone object hanging from or lying on something ("thin green vines hanging straight down from a short brown
  branch", "a low flat mat of ivy leaves lying on the ground").
- 2026-10-21. Generated models come out paler than the reference: bring the whole scene up with a ColorCorrection
  (saturation) rather than regenerating for colour.
- 2026-10-21. Trees in the reference have trunks that BRANCH and hold separate clusters of leaves: "a branching brown
  trunk holding several round clusters of ..." gives that look; "a crown of ..." gives one blob.
- 2026-10-21. Scale a model to the spec by its LONGEST side, not its height: a flat ivy patch scaled by height grew
  enormous.
- 2026-10-21. A garland and a hanging liana (thin curves in the air) never came out as one mesh; the generator does
  well with things that sit on something (vines over a rock, a log wrapped in vines). Ask for those.
- 2026-10-21. The kit took 4 rounds; after round 3 only colour was left, and colour stubbornly stays (an "autumn yellow"
  bush comes out orange every time): stop there and correct colour in the scene.
- 2026-10-21. Shoot each category on its own floor, far apart, close enough that a model fills a fair part of the
  picture (a row of small flowers from 50 studs, trees in two halves): from far away every model looks fine.
- 2026-10-21. Count the REAL triangles (EditableMesh): most models sit at their ceiling, but some broke it (a hedge box
  4,728, a fallen log with vines 2,485). Never place those in a budgeted scene.
- 2026-10-27. Goo Lineage's first building (the level-1 breeding house): a generate_mesh prompt that lists what the
  ChatGPT picture shows, part by part (roof shape and shingles, ornament on top, wall frame, door, window, stone base,
  steps), gave a model close to the picture at the first try; two prompts in parallel, keep the better. The model's
  door faced its own -Z, so a plot area's frame (whose -Z faces the gate) places it right with PivotTo(areaFrame).
- 2026-10-27. generate_procedural_model with the reference image attached gave only a red error box in Edit mode:
  do not count on it for buildings.
- 2026-10-27. Every generation failed with "should only be called from the server" while the owner had pressed Play:
  check get_studio_state before starting jobs.
- 2026-10-27. A bare model on flat grass reads far weaker than the painting, which is a little diorama (bushes, pots,
  stepping stones, flowers around it): budget the dressing kit with every building, not after.
- 2026-10-27. Flat terrain filled up to y = 0 shows its surface at y = 2 (4-stud voxels, centres on multiples of 4):
  everything placed from y = 0 was buried 2 studs and looked "missing". Place from `Config.Map.GroundY` (2), and
  measure with a raycast against the terrain when in doubt.
- 2026-10-27. Terrain Grass grows decoration blades about 1.5 studs tall that hide low props (bed planks, fence
  rails, stepping stones): put bare earth (Sandstone here) under low built things, or raise them.
- 2026-10-27. Creator Store models: `InsertService:LoadAsset` from execute_luau fails ("not authorized") for other
  creators' assets; the MCP `insert_asset` tool works (it sandboxes their scripts; delete every LuaSourceContainer
  anyway). The Egg Heist kit (our own asset ids) loads with LoadAsset.
- 2026-10-27. The Egg Heist kit (very low poly, made to be scattered far away) reads badly up close (cattails as red
  shards, daisies as white slivers). For plots seen close, the free "Nature stylized Pack" (109637424937405, no
  scripts; library in ServerStorage.NatureKit of the work place) fits the owner's soft clay-like style: Bush,
  FloweringBush, BerryBush, Fern, GrassTuft, FlowerPatch, Sunflower, WaterLily, rocks, Stump, Log, OakTree,
  SteppingStones. Very small pieces (FlowerPatch, GrassTuft) break up when the camera is within a few studs.
- 2026-10-27. The storybook lighting preset (tools/map/lighting_storybook.luau) was the biggest single lift: real
  side shadows, lilac shade, no plastic shine.
- 2026-10-27. Cartoon pond = flat opaque water parts in 3 tones (shallow rim, mid, deep) over the terrain water
  (tools/map/pond_water_l1.luau). Terrain water waves rise ~0.8 studs above its raycast level: the paint must sit
  0.9 above it or the glints poke through.
- 2026-10-27. Grass MaterialVariant from generate_material ("cartoon hand-drawn grass ... grayscale") rendered as
  busy, dark brush strokes; the same variant with its maps cleared rendered neon green whatever the terrain colour.
  Dropped: no override, Grass colour 112,182,66.
- 2026-10-27. Blob shadow discs must be DARKER than the lit grass around them (70,128,46 under 112,182,66) and only
  under bushes, rocks, trees; under small flowers and tufts they read as pads.
- 2026-10-27. A Highlight outline on a group of plain parts (the dock) barely shows from the plot camera; it pays off
  only on meshes with clear silhouettes.
- 2026-10-27. THE OWNER CHOSE THE CLASSIC STUD LOOK ("players seem to prefer Roblox's stud texture"). Recipe that
  works (tools/map/stud_floor.luau): floors of Plastic tiles with TopSurface = Studs (the legacy surface still
  renders); an image Texture with a stud DECAL id renders nothing (decal id is not an image id). Terrain cannot carry
  studs: flatten it under the plot by whole voxels (air from -2 up, ground below) or its grass blades and bumpy
  surface come through. A pond becomes a sunken pool: 2x2 tiles stepping round the water, sand-coloured near it.
- 2026-10-27. GetBoundingBox of a model follows its pivot's rotation: for cylinders lying on their side its "height"
  is their width. Use absolute heights for flat water parts.
- 2026-10-21. `maxTriangles` 64 still gives good faceted trees (a tiny pine, a tiny round tree); the round one shrunk to
  a third and sunk is a good round bush. Cheap trees are what make dense woods fit a budget; a 5-pine cluster in one
  mesh (600) is no cheaper per tree.
- 2026-10-21. Snowy peaks came out right at the first try ("tall snowy mountain peak, steep faceted grey purple rock
  sides and a big white snow cap on the top, wide base"). A generated waterfall (a box with a blue strip) and a "flat
  topped plateau" (a small puck) did not: build waterfalls from beams on a carved terrain cliff, plateaus in terrain.
- 2026-10-21. A kit key can lie (a "round green" bush was the pale three-ball one): choose a model by its picture, not
  its name.

## Colour and tint

- 2026-10-21. A generated MeshPart carries its colour in its own SurfaceAppearance: tint THAT (`sa.Color`); adding a
  second SurfaceAppearance with `ColorMap = TextureID` turns it white. One tint per variant keeps every copy drawing
  together; a tint can only darken or shift a colour.
- 2026-10-21. On some generated textures a tint does NOT take (amber stayed blue): to recolour, PAINT (remove the
  SurfaceAppearance, TextureID "", SmoothPlastic + Color: still shaded by the lights, unlike Neon, which turns a mesh
  into a flat cut-out). Paint generated stones flat when their colour is wrong.

## Placing and showing

- 2026-10-21. A Model with a PrimaryPart pivots by `PrimaryPart.PivotOffset`; setting `WorldPivot` did nothing and every
  model stood half sunk into the floor: the trees looked like bushes and were wrongly judged as bad models. Set the
  pivot through `PivotOffset`, and PROBE positions before judging a model by its picture.
- 2026-10-21. Judge a model from a close camera at its own height, not from a wide shot where it is a few pixels.
- 2026-10-21. Lay a landmark on the PROBED ground (a raycast), never at the level of the plan: the paths' flattening
  lifted a clearing 2 studs and buried a landmark's slabs for two rounds.
- 2026-10-21. A mesh can be turned inside its kit model: size it non-uniformly on the MeshPart in its own axes, not
  through the model.
- 2026-10-21. Place bare MeshParts (a tree = MeshPart + its tint + an invisible trunk), not Model copies: about half the
  instances. Trunks (collision) only where players can reach.
- 2026-10-21. Keep a landmark's sightline free by rule: a corridor without trees from the spawn to the landmark (a single
  round tree hid it at eye level).
- 2026-10-21. Random caps thin everything alike: what makes the composition is kept outside the cap, and the budget is
  spent where the reference's eye goes.

## Terrain and the look of a map

- 2026-10-21. Noise of small amplitude on a 1600-stud map reads as flat: the main swell needs 25+ studs over 500 studs.
- 2026-10-21. LeafyGrass in noise blobs on open ground looks like camouflage stains: only under forests.
- 2026-10-21. Default Atmosphere is a thick haze: density about 0.2 for a bright day.
- 2026-10-21. Terrain grass blades (Decoration) are not scriptable: turn them off in the Properties panel; they are
  heavy on phones.
- 2026-10-21. The reference had what the first draft lacked (a waterfall, dirt paths, rocky outcrops, denser woods at
  the edges, a stone circle). Ask for the reference BEFORE the first draft.
- 2026-10-21. A MaterialVariant with NO texture at all, put over a terrain material with
  `MaterialService:SetBaseMaterialOverride`, draws it as flat colour: clean-edged tan paths (the textured Ground blurred
  4 studs wide and read greyish pink from afar) and the flat vivid grass of an illustration. Keep Rock textured: a flat
  cliff loses its read. A `generate_material` dirt came out orange with pebbles: the flat one was better.
- 2026-10-21. Distant peaks are kit meshes, not terrain (terrain peaks read as lumpy camouflage), in layers beyond the
  playable edge; invisible walls close the world. A first layer too close stood as a wall and hid the edge woods.
- 2026-10-21. Check the camera by the relative size of two landmarks in the reference and the shot: moving the camera
  (not the world) fixed the perspective.
- 2026-10-21. Atmosphere Density 0.28, Offset 0.38, Haze 0.85 lays far peaks back in layers; 0.32 / 1.3 washed the
  whole valley grey. Flat colours need less ColorCorrection saturation (0.2).
- 2026-10-21 (falls). A waterfall is CARVED, not placed: a straight line along which the terrain is drawn by hand (a
  channel as wide as the fall, a vertical wall across the axis, a basin, a lip, a plunge pool), with rock cheeks standing
  out past each wall. Sheets placed against a slanting generated cliff always stand apart from it (the owner saw it from
  above at once).
- 2026-10-21 (falls). Read the water levels for the sheets off the carved terrain (a raycast that hits Water), never from
  the plan; a vertical terrain wall between two 4-stud columns is drawn about 2 studs past the grid line.
- 2026-10-21 (falls). Falling water from beams only (a deep-blue plain beam behind, scrolling streak beams in front, a
  short lip beam): a beam has no top, so nothing reads as a box from above. Shoot every hero piece from above too.
- 2026-10-21. The whole 1920-stud map: the height field computed first into an array (480 x 480), paths and streams
  stamped into it as distance fields from Catmull-Rom samples, then WriteVoxels in 144 chunks: about 5 s.
- 2026-10-26 (ways up). The owner: "high places nobody can walk to need paths or stairs". A ramp per raised shape along
  its own rim, wide enough for everyone, starting only on open ground or on a shape already climbed. Smooth terrain draws
  its surface ~2 studs over the level its voxels are filled to: start a ramp 2 under the drawn ground, or every junction
  is a step. Proof is a WALK (a play test with `Humanoid:MoveTo` along the saved centre lines), not a picture.
- 2026-10-26. Studio MINIMISED gives white `screen_capture`s: bring its window up first. When the owner is using the
  screen (a game, Alt+Tab), do not take it: saves and shots wait.

- 2026-11-02 (the valley's middle, `tools/map/build_wild_slices.luau`). Painted ground that matches a picture: a MaterialVariant
  with NO map draws lime whatever the terrain colour (seen again), but one whose `ColorMap` is a soft mottled near-white tile
  (256 px, made by a script, `upload_image`, `StudsPerTile` 90) takes `SetMaterialColor` exactly and reads as paint. The
  biggest single lift of the job; a variant can only be built into the place, so it travels with the owner's save.
- 2026-11-02. Not every terrain material is flat at the same voxels. Brick (and Cobblestone) drew their surface 2 studs LOWER
  (0 for 2: only the ground check caught it, as a list of "0.00 Brick"); Slate, Ice and Sandstone have bumps that stand over a
  thin part, cutting a path into dashes; a variant does not remove them. Flat ones here: LeafyGrass, Mud, Ground, Concrete,
  Glacier, Asphalt, Snow, Salt, Pavement, Limestone. Probe a new material with a raycast before using it.
- 2026-11-02. Terrain Grass stands over thin parts too. A 6-stud path cannot be terrain at 4-stud voxels (it blurs or vanishes):
  use flat non-colliding, non-query slabs 0.2 over a material without blades; where it must cross grass or sand, sand under it
  and 0.6 over the ground. Round clearings as terrain come out as blurred diamonds: a thin cylinder part reads clean.
- 2026-11-02. `ReadVoxels` results hold a `.Size` key: loop with `Size.X/Y/Z` or `ipairs`, never `for k, v in mats`.
- 2026-11-02. Terrain takes a few seconds to mesh after a big write and the first shot shows old stripes: shoot twice before
  judging. Kit stands (`viewer.luau`, y 300) show as a bar in the sky from low cameras: destroy `KitViewer` when done.
- 2026-11-02. Keeping march lines free: a tree's crown may reach over a line (it does not collide and clears a slime's head),
  so test a trunk share of the spread against lines, the whole spread against homes and paths; with the full spread on lines
  almost no tree found room. Write the check as its own script from the same numbers; it caught what pictures did not.
- 2026-11-02 (the valley's middle, second try, after the owner rejected flat colour, cream slabs, discs and simple trees). This overturns
  the first try's lessons above on painted ground and slab paths for anything outdoors: real terrain textures blended by noise, and
  dirt paths painted in the terrain, are what the owner calls natural.
- 2026-11-02. A shot from a camera that moves only for the shot shows terrain's coarse far level, where 4-stud trails fall into dashes,
  and I lost three rounds "fixing" dashes that were not in the voxels (an ASCII dump of the top voxels showed them whole). Set the
  camera, wait about 7 s, then shoot; dump voxels before changing a trail.
- 2026-11-02. A terrain path is about 7 studs drawn to read as 6; cells within 3.9 of the centre line are always path, the noise only
  frays the rest. One material along a trail: two in turns read as sewn patches. Trails must ride the swells with the ground beside
  them, or a lower cell is buried by its neighbours.
- 2026-11-02. Occupancy of the voxel above the solid top raises terrain smoothly: surface = 2 + 4 x occupancy (measured). Swells need a mask
  of the distance to march lines and homes, or a checker finds steps.
- 2026-11-02. Terrain materials per zone: a material has one colour in the whole place, so give each zone its own material, and scan
  which materials the rest of the valley uses first (here only Grass, Rock, Sand). Materials are not what their names say: Sandstone looks
  like cracked dry earth, Ground like wood chips, Salt stays pale, Mud with an olive colour makes good moss; lay out swatches and look.
  A `SetMaterialColor` under the texture can make it read pink under the lilac ambient: (176,102,66) did; (158,98,50) did not.
- 2026-11-02. Look at every kit model at real size BEFORE writing the recipes. I went by names twice: FlatBoulder is a lamp post on a
  beam, rock_boulder_mossy a pancake, SnowyBush lime under its snow, MossyBoulder a tan stone with green goo on it.
- 2026-11-02. Measure triangles in the scene (`Stats.SceneTriangleCount` with one clone in an empty view): the owner's trees are 4,400-5,200,
  his rocks 1,700-2,900, NatureKit's small rocks 1,174. A pebble of 1,174 is a waste nobody sees; use the 140 ones for what is small.
- 2026-11-02. Free tree packs: the description names the real pack; search lists a dozen re-uploads of one pack under other names. Take
  the original creator's. A colourless canopy takes `SurfaceAppearance.Color`, which gives every mood from one set of trees, but one flat tint
  loses the crown's light and dark: seen from under it is a flat sheet. A root flare placed at the foot hides a thin stake-like trunk.
- 2026-11-02. `task.wait` is what lets a long `execute_luau` finish; 600 s is plenty for 2,800 parts and the whole terrain.
- 2026-11-02. Leaves cut out of a card: a MeshPart's `TextureID` ignores the picture's alpha (cards draw as dark opaque sheets); the same
  picture as a `SurfaceAppearance` ColorMap with `AlphaMode = Transparency` cuts them out and still takes `Color`. Look at every imported
  model in a showroom (stand at y = 3,300, rows, camera in front) before writing recipes: three of four Qt tree trunks were shredded.
- 2026-11-02. Decimating a mesh in Blender (`Decimate` collapse) tears it at hard UV seams: scattered triangles. Trunks and other solid
  parts need Planar/UV-delimited decimation, or no decimation. Always view the shrunk model in Studio before the owner's import is trusted.
- 2026-11-02. A tint (`SurfaceAppearance.Color`, `MeshPart.Color`) multiplies: it darkens and warms, never changes hue. A red crown cannot
  become purple or orange, a green one not red; choose which model by its own colour (red bush, golden wisp grass) and tint only for shade.
- 2026-11-02. Triangles: `AssetService:CreateEditableMeshAsync(part.MeshContent)` counts the owner's and imported meshes; for free packs of
  other creators it fails, then one clone alone in an empty sky view with `Stats.SceneTriangleCount` (minus the empty view) gives it.
  `SceneTriangleCount` in a camera view includes everything: take the view with and without the folder to know its share.
- 2026-11-02. Count cheap and dear pieces apart: the owner's hand-made pieces are 1,500-5,200 triangles, so a drift of three is 10,000.
  Sprinkle them by count (a `SPRINKLES` list with a cap), use the 100-500 triangle pieces for everything scattered.
- 2026-11-02. A camera sitting on a trail finds a mushroom in its face: shoot from a point a few studs off the trail's centre.
- 2026-11-02 (second round). A tint multiplies, so crowns of other colours need real recoloured textures: PIL with the leaf picture's alpha
  kept, a target colour at mid brightness times the original's light and dark with a soft blotch noise (so a crown is not one flat sheet);
  served on the local file server, uploaded with `upload_image`, set as the crown's SurfaceAppearance ColorMap in a kit variant. Result:
  purple, orange, gold and teal crowns read right.
- 2026-11-02. A terrain material can be given its own painted texture only if no Part uses it (`MaterialService` overrides every Part too):
  count Part materials first (here Asphalt was free), use that material for the earth, leave the common one (Ground) alone. Re-run the
  scrap list so old voxels of the material are cleared, and give the material colour white when the texture carries the colour.
- 2026-11-02. Flat painted-earth textures read orange-pink when saturated: make two ramps (a tan road, a dark brown earth) from the picture's
  light and dark, blend only 10-18 % of its own colour back. A large brown plaza still reads as a car park: break it with moss and grass.
- 2026-11-02. Budget: a recipe edit that changes one random draw changes every later tree (a 1,790-triangle twisted tree or a 5,000 one
  swings the total by 10 %). Count after every edit, cut the cheap lever (a tree fewer per cluster, spacing) rather than tune plants.
  The Quaternius trees cost 1,500-3,300 each against 400-2,000 for the first picks: spacing x1.3 and one tree fewer per cluster paid for it.
- 2026-11-02. A "zip" in a downloads folder can be a saved web page (18 KB, starts with <!DOCTYPE html>): look at the first bytes before
  unpacking, and say so in the report instead of searching for models.

## The village's trees and bushes against its upgrades (2026-11-02, tools/map/dress_village_trees.luau, check_village_trees.luau)

- Before dressing a place that upgrades, find out HOW it changes: here every area and the village are rebuilt from code (`*Stages.build(area,
  frame, level)`, levels 1-50) and the code itself removes (`PantryStages` service yard, `PondStages.grow`) or moves (`VillageStages`,
  `GardenStages`) scenery by name and position. The reliable footprint of "everything that ever appears" is to RUN those builders level by
  level on `template:Clone()` (unparented, in Edit mode: 350 builds take about 8 s) and rasterise every part; reading the code for
  coordinates would have missed the ivy, towers, lighthouse and the pond's grown lobes.
- A stage build mutates its area (skins it, takes scenery away): never run it on the template, only on a clone. Terrain-writing calls
  (`PondStages.grow`) must not run on a clone at all: pull their rule out as a pure function (`PondStages.clears`) and call that.
- Module state hides in load order: `PondStages.kitPlace` is handed over when `PantryStages` loads, so a build run before it lacks the
  shore's benches and racks, and a check that "passed" in the first call failed in the next. Require every stage module up front.
- Rasterising a polygon by "inside" needs its turn: a rectangle from `RightVector`/`LookVector` is clockwise, and the test accepted only
  its thin rim; large floors and yards were holes in the grid and the first "OK" was false. Always make a deliberate offender test: five
  trees and bushes put on a yard, a path, a pond, the market street and a pavilion must each come back as a clash.
- A height-band occupancy from the mesh's real vertices (`EditableMesh:GetVertices`, mapped through the part's size) tells a pine's low skirt
  and a trunk apart; fill the empty bands between a trunk's foot and its fork with the thinner neighbour.
- The upgrade code can take a small plant by a circle round a placed model (not by its parts) and slides pieces round trees and bushes
  (so they lie differently once the scenery stands): plant trees and bushes first, then run the village layer again with them in place
  and keep the small plants off THAT. Keep the old model names of what the code finds by name (FlowerPatch, GrassTuft, Fern).
- A kit model's colour can sit in a picture shared with another model: `QtBush_Common` wears the twisted tree's red leaves. Read the .glb's
  own image (`tools/map/extract_glb_image.py`: the GLB's JSON chunk, bufferViews) and recolour THAT with `recolour_leaves.py`; a green bush then came from one
  upload. Pick the target at mid brightness, yellower than first thought (the mint one read blue under the lilac ambient).
- Counting triangles of other creators' meshes: `Stats.SceneTriangleCount` needs a fixed camera, one clone, a 1.1 s wait before each reading
  and the mean of the empty view before and after (it drifts by 4 a second); moving the camera between readings gave negative numbers.
  The old Nature pack's bushes cost 790-2,730 triangles each, `QtBush_Common` 316: the village's template fell from 1.44 M to 0.90 M.
- `studio_mcp.js run <file> <id> Edit NAME=file` hands a file over as the string NAME: a library file shared by two tools is turned into
  a ModuleScript (`Source = LIB`, parented to ServerStorage, required, destroyed) so rules exist once. Port 8765 of `serve_dir.js` was
  taken by someone else: pick another.

## The Market square (2026-11-02, tools/map/build_market.luau, check_market.luau, market_raypreview.luau)

- A MINIMISED Studio shoots white. Check first with `IsIconic` on the Studio window (user32), not after a job of guessing. The orchestrator may take Studio (the owner, 2026-11-02, `CLAUDE.md`); a subagent still may not. Two things still work without it: the
  public thumbnails (`thumbnails.roblox.com/v1/assets`, a generated model's `publishedAssetId`, a minute or two after the job) judge a kit model from one side with its texture, and a picture by raycasts
  (`market_raypreview.luau`: a ray per pixel, the part's Color, kit meshes coloured by name; CanQuery on for the picture, then back) judges layout, shape, orientation, slits and framing, and caught all of
  the first draft's real faults. It says nothing on texture, light or water: those wait for a real shot, and a report says so.
- A real thumbnail of grey planes means the generator gave no colour or the mesh failed: throw it away. A lower `maxTriangles` is not a cheaper same model: wall at 280 became one painted slab, baskets at 180 shredded.
- Fixed spots may not suit the picture's camera. Things 55 studs apart seen from 48 studs away fall outside FOV 50: place foreground dressing where the camera sees it (test `atan(x / distance)` under 39 degrees) instead of along the square's edge, where it was never in view.
- Count by kit model, not by folder: a tally by name found 6,000 triangles of fences, 4,000 of two benches and 1,500 of one crate stack that nobody would miss. Generated meshes sit in a `body` model: walk up past it for the name.
- Two slopes of an awning that only meet leave a slit on the outside of the bend, seen as dark strokes: run each a little past the crease.
- A walk check with a body-sized box along the way points caught a lantern post put on the line from the Landing to a stall, which no picture showed.
- A thin road painted in noise falls into dashes: keep the core always earth and let noise fray only the edge (again). Rewrites of terrain re-run the same paint safely (0 cells changed proves it).
- Material Fabric turned cream to grey and blue to navy under this light: the raycast picture showed the right colours and the real shot did not. SmoothPlastic gave the painting's colours at once, but darken a saturated colour for it (purple went neon).
- Wide overlapping water beams read as a solid blue dome; separate streams, narrow (0.42 of the share of the ring), show the stone behind and cost fewer beams.
- Flowers spread over a radius of 9 read as lonely stalks on the grass, and scaling them up read as giant flat flowers. Same count, radius 5-6: clumps. Thin grass blades tinted pale read as white spikes: left out.
- SurfaceAppearance.Color barely moved the pebble flagstones (a much warmer tint looked the same): the stones stay grey.
- After a quick-travel move the camera keeps its old angle, so the player opens looking sideways: turn it behind the character on arrival.
- The builder's triangle tally is rough both ways: primitives count high, and the Doki flowers count 0 (their mesh cannot be read), so more of them does not show in the total.
- Shoot from the player's side: the frame's world z is -500 - local z, so the way in is at world z -425 and the board's back is at -584. A real pass that passes every check can still look wrong; see the Fabric line above.
- 2026-11-05 (the square made tidy: five places on one circle, ring paving). An MCP `run` could not require ANY shared module (Config,
  Layout: "Capabilities property: Network"), and a fresh ModuleScript made from their Source gets the same block (it cannot even be
  parented to ServerStorage). Keep the numbers in each tool, marked "EQUAL to src/shared/Config.luau", and `slotFrame` by hand.
- A tidy plaza from the valley's own pebble mesh: rings of equal stones (ring 4.2 wide, stones about 4.8 along, 0.4 joints, every other
  ring turned half a stone), stones squared to their ring (`Angles(0, -a, 0)` with X radial), a half-turn at random for variety, a kerb
  ring of Slate blocks open where each path leaves, paths as rows of 2-3 stones with a kerb along each side. It read as neat at once,
  where the scattered stones of the first build read as a mess; 412 meshes cost 24k triangles.
- Painting a round yard in 4-stud terrain: paint the plaza and the way in WITHOUT noise (only the pads round each place fray), and
  let the paving's kerb sit on the circle's edge so the blurred voxel rim is hidden.
- Places that face the fountain show their SIDES to the way in: accept it for stalls (the awning still reads), and dress for that view
  (a stall's sign on its end toward the way in, goods mirrored by a per-stall `entry` sign so the pair stays a mirror).
- Lamps at path mouths put on the side TOWARD the way in made a row of posts in the entrance view: put them on the far side.
- Bunting strung down to a lamp beside a building hung its pennants across that building's front at head height (seen only in a close
  ray picture from the side): string it high, from the banner post to the building's BACK post (16 up), and a matching mast for the
  mirror place that has no post of its own.
- A forge reads as a forge, not as a third stall, with a one-slope shingled roof in rust red (rows of Slate tiles over a dark deck), a
  stone back wall, low stone side walls and a square chimney stack behind the wall; the owner's crest board and banner stay.
- The game's portal is built at run time: `tools/map/preview_portal.luau` builds the same thing in the work place for pictures
  (`REMOVE=<any file>` takes it away); its platform reaches about 14 studs in front of its spot, so a walk check ends 16 short.
- Studio stayed minimised for the whole job: every round was judged by `market_raypreview.luau` pictures (layout, facing, clutter,
  the bunting fault), and the report names the real shots still owed. A ray picture of 480 x 270 runs out of time and comes back with
  its lower part black: 400 x 225 is the limit.

## Water and moving things

- 2026-10-21. The owner: a waterfall of parts (a blue block, white rectangles, white balls) "is not water". Falling
  water = a deep blue body with BEAMS in front whose tileable streak texture (from ChatGPT) scrolls by itself
  (`TextureSpeed` ~1.1-1.5, `TextureMode` Wrap, `TextureLength` ~15), a mist of particles where it lands, flat foam
  discs, no box over the edge. Cheap and no script.
- 2026-10-21. A beam spreads its width along its attachments' SECONDARY (Y) axis: turn the attachments so Y runs across
  the sheet, or the beam is seen edge-on as a thin line.
- 2026-10-21. Terrain water can spill down a cliff face beside parts-water: clear it with `ReplaceMaterial(Water ->
  Air)` in a box over the face.
- 2026-10-21. A picture for a texture must keep its alpha: a screenshot of ChatGPT loses it. Download the file, size it,
  then upload through Studio (`node tools/serve_dir.js <folder>` + MCP `upload_image` with the localhost URL).
- 2026-10-21. A blue frame showed behind the falls' streaks: make each strip ONE curved beam (Attachment0 Axis out over
  the edge, Attachment1 Axis down, `CurveSize0` 12, `CurveSize1` ~0.55 x the drop, 16 segments), the deep body the same
  curve a bit narrower just behind, and land the foot ~3 studs past the face so the pool's front face stays hidden. Find
  such a line by switching beams off one kind at a time, never by guessing.
- 2026-10-21. A stream bed 3.5 studs under the water level held NO water ("a dry channel"): terrain water sits in 4-stud
  voxels, so a bed must be at least ~6 studs under the level. Run a stream's line INTO the lake it feeds (past the
  shore), or a strip of grass is left between them. Shoot every water body from above.
- 2026-10-21. After many full terrain rewrites in a row, Studio drew flat GREY SQUARES over parts of the water; the voxels
  were fine and one more terrain rewrite re-meshed it. Before telling the owner a map is done, shoot it once more after
  the LAST rewrite.
- 2026-10-26. After the owner reshaped lakes by hand in Studio, a flood-fill script refilled them cell by cell from each
  body's seed. The owner's hand edits are lost if the place is closed unsaved: remind him to save.
- 2026-10-28. The village fountain (`VillageFountain.luau`): water curtains as Beams from a bowl's rim to the pool
  (Axis out from the rim so `CurveSize0` bows them outward, SecondaryAxis along the rim so the width lies along it);
  drop jets as ParticleEmitters held in a tiny invisible part (`EmissionDirection` Front, the part's front turned along
  the jet; an Attachment's emission is awkward to aim); ripples `VelocityPerpendicular` on a Disc emitter in a cylinder
  part; a pale ForceField film over the pool reads WHITE: use a mid blue. Rims built as rings of short blocks, never
  full discs (they hid the water). Count emitters, total Rate and beams after building; scale the rates down (60%).
- 2026-10-28. Free Creator Store decals give the texture through `game:GetObjects("rbxassetid://<decal>")[1].Texture`
  (the image id differs from the decal id); look at the thumbnails first (thumbnails.roblox.com in the browser pane).

## References

- 2026-10-21. THE OWNER CAUGHT ME SKIPPING THE REFERENCE: asked for "a huge, huge ancient tree", I generated two
  candidates from a text prompt alone; both came out as small trees scaled up ("you forgot the workflow"). EVERY new
  model, above all a hero piece, starts with a ChatGPT reference picture of exactly that thing, then the prompt is
  written from the picture and the result judged against it. No exception for "small" requests.
- 2026-10-21. generate_mesh takes TEXT only: for a complex HERO piece it cannot follow a reference (3 text candidates
  all gave a compact blob crown). Generated kit pieces are fine for scenery; a hero piece goes image-to-3D FROM THE
  REFERENCE (the owner's Meshy route, or Blender with the `model-artist` agent), then through the kit. Judge every model
  from 4 sides + above, never one.
- 2026-10-21. The hero tree done right: ChatGPT reference -> the owner's image-to-3D (9,929 triangles) -> reduced to
  4,000 -> the owner's File > Import 3D into the work place -> into the kit -> placed, shot from 4 sides: it matched at
  once. A hero piece needs a clear ring round it or the scenery hides it.
- 2026-10-21. A REGULAR shape (a ring of stones) assembles well from small generated pieces placed by rule; irregular
  organic heroes still go through image-to-3D. Build a ring of the SAME kind of stone as what looks right next to it:
  natural boulders of 2-3 shapes, each its own span and twist, never square blocks.
- 2026-10-21. Glowing marks = a ChatGPT glyph sheet on SurfaceGuis (LightInfluence 0, Brightness ~2.5) placed ON the
  stone's real surface (ray against a precise-collision copy). A part's Front face looks along -z:
  `CFrame.lookAt(at, at + outward)`. Uploaded images take seconds to appear: wait before the judging shots.
- 2026-10-21. A spinning surface with NO script: ParticleEmitters on an ATTACHMENT (on a part, particles are born
  anywhere in its box), `Orientation` VelocityPerpendicular, Speed ~0, Lifetime 4, Rate 0.75 with fade in/out, `RotSpeed`
  -55 and +35 on two layers, `Emit(2)` at start. Keep PointLights soft (Brightness 0.5, Range 10-14): strong ones dyed
  every stone their colour.
- 2026-10-21. Several references can be asked of ChatGPT in ONE message (it made three in one reply). They can be kept
  without the owner: in Claude in Chrome (signed in to ChatGPT) open the chat, click the picture, and `computer zoom` its
  region with `save_to_disk` (scale 1); copy the saved file into `docs/references/<job>/`. (In the Claude app's own
  browser pane downloads fail; the owner downloads.)

## Working with Studio

- 2026-10-21. Ctrl+S on a new place opens "Save Experience", which would create an experience on Roblox: cancel; use
  File > Save to File As. In the file dialog, clear the name field with Ctrl+A, Delete before typing the path.
- 2026-10-21. The MCP proxy answers "no Studio connected" for the first second or two of each connection: the client
  retries (`tools/studio_mcp_client.js`).
- 2026-10-21. One plan file read by every step, and one runner that sends the steps in one session: a whole rebuild is
  one command and takes about 15 s.

## Buildings that upgrade (the pantry's detail review with ChatGPT, 2026-10-28)

- Each level must read from its SILHOUETTE alone, from a distance: give each era its own roof shape (gable shed >
  gambrel barn > brick gable > low seamed steel > corniced marble), not the same house with better materials.
- A building's function leads its front: for a store, the loading door is the biggest, darkest-framed thing (wider each
  level, a dark recess behind it, thick jambs and header); windows are small and say what the floor is for (a top
  storey of a store is a vent, not another row of rooms). Bright windows and lamps turn any building into a home.
- Contrast beats ornament: dark wood doors in pale trim; sandstone against ivory (#C4AE88 on marble), not white on
  white; gold on a few edges only, never outlining every part; glowing cyan only on the slime-tech tier.
- Depth beats colour: a pilaster, cornice or frame that stands 0.2-0.5 proud of the wall reads; a flat strip does not.
  Doors sit back inside their frame.
- Check function: a hoist must not lower its crate through a canopy (from steel on: a sealed cargo hatch); canopy
  clearance above a player; a sliding-door rail needs room for the door to slide, else leave hinged doors.
- Two parts whose faces lie in one plane flicker as a streak (a gable fill under the roof): sink one 0.2.
- Spend the part budget on shapes that change the silhouette or cast deep shadows; a dozen roof parts beat 60 rivets.
  Few broad roof seams (4 a side), not many thin ones that shimmer on phones. Stop detailing when the level reads.
- Shoot every era from one fixed camera (`tools/chatgpt/shoot_setup.luau` + `shoot_camera.luau`) so rounds compare.
- ChatGPT's review (skill `chatgpt-review`) is worth it: round 1 found the silhouettes, round 2 the contrast and
  function. Weigh each point (it does not know the doors are props); 3 rounds were enough.

- 2026-10-28 (garden, then the owner corrected it). Props squeezed into a pad's paths shrank to toys, but
  moving EVERY prop out to the lawn was wrong too. Judge each prop on its own: does it belong here for
  what it does, is it at its real size against a 5-stud block, what would stand beside it. A prop that
  fits stays inside; only when the area is cramped, either the area grows or that prop moves out to a
  fitting spot. Keep a ring of life on all four sides that grows with the eras.
- An area may grow with an upgrade but NEVER shrinks at a later level (the owner, 2026-10-28). Pads
  that come and go with one era's prop break this: grow the yard once (the pantry's 14 x 20 service yard
  from L21, its old edge hidden, the scenery bushes inside it removed) and let later eras use it.
- Big lawn things (crane, silo, container, tank) stand on paving, never on grass, and show how they
  connect (a container's doors with room before them, a tank piped to the house). Keep a clear lane from
  the gate to the door at every level. Waiting goods stand on a pallet.
- The area's frame is the lawn's top; its own floor is 0.4 above it, so anything on the paving needs
  that 0.4 as lift or it sinks (a pallet disappears).
- 2026-10-28 (the owner's play test of the pantry). A generated kit model can carry parts glued in the wrong
  place (the jib hoist's crate floated beside its post, tied to nothing). If a prop has to DO something (a hook
  holding a load), build it from parts so rope, hook and load line up, and the load can change per level.
- Kit models come small: the owner asked for twice the size on a hoist, a small forklift and a robot arm. Size a
  working machine by its job against the 5-stud player (a forklift's guard above head height).
- When the owner names a level ("the forklift at L22-23"), map it to the slot and era in `SPOT` before editing;
  I enlarged the wrong forklift once (L32 instead of the L22 pallet-jack slot).
- Loads and hooks need clearance on every level they share: a crate 0.5+ above the cart's load, an empty hook a
  stud above the next era's forklift roof; a crane's boom swung in so its load hangs over the paving.
- A doorway needs room before it: keep 5-6 x 6-7 studs clear before a container's doors; a new hut goes along an
  edge with its door to the yard, never across another door. A walk-in door is 5.5 high.
- A thing with no weight should look it: a hover cart lifted 1.3 with a soft glow under it, tagged "Hover" so
  the client script `HoverBob` bobs it near the camera only.
- `GetBoundingBox` answers in the model's own axes; after turning a model, measure in the area's axes (the
  `extents` helper in PantryStages) before placing things against it.
- A kit model in another style (a red-roofed cabin in the slime-tech yard) breaks the era; build a small hut in
  the main building's own tiers instead.
- A landmark must win its silhouette against the building beside it (a windmill below a greenhouse
  ridge reads as an ornament); if the kit model's proportions are wrong (a barrel on scaffolding),
  generate a better one rather than scaling.
- Foliage from parts: flat thin leaves lying nearly level (tilt under 15 degrees) in three greens,
  on thin stems; round balls read as pom-poms, steep leaves as flying chips.
- A greenhouse reads when its ridge runs toward the camera (a glass gable at the front), with few
  slim bars and matte transparent glass (Reflectance 0).

## Bringing a built map into the game

- 2026-10-23. A map went into the game as files, no Studio at build time: in Studio, `CopyRegion` in 128-cell blocks
  full height into a folder, a `Base` CFrame, save; then Lune writes TerrainRegions (with a `Corner` attribute) and
  models into `assets/`. Rojo keeps a TerrainRegion's `SmoothGrid`; the server pastes it with `PasteRegion` (corner in
  CELLS). 16 regions + 7,650 instances = 1.4 MB. Lune can set `Model.WorldPivot`.
- A map that goes under its own ground must be LIFTED in the game: parts below `FallenPartsDestroyHeight` (-120 in the
  previous game) are destroyed.
- In Lune, `folder.Terrain` on an instance named like a service member fails: use `FindFirstChild`.
- Measure a kit model before trusting its name: the kit LanternPost is a 4-stud wall lantern, so placed as a street
  lamp it read as a garden stake. Street lamps stand 8-9 studs with a head 1.5-2 across; build them from parts.
- Flat green slabs on a wall read as holes or paint, not ivy: build vines as chains of leaf clumps climbing from the
  ground, thinning as they rise. Flowers on bare soil read as candy: sit each in a round leafy clump.
- A flat disc on the lawn looks unfinished: give a gathering spot an uneven worn edge, a few stones, something at its
  open side (a notice board, a stage) and its own edge each era, so the upgrade shows in its shape, not only colour.
- A prop the owner will look at closely is a generated model, not parts: parts read as plain boxes beside the
  greenhouse vegetables. Generate 2-3 at a time, lay them out on a stand away from the map and shoot each from the
  front and the side before using it; about a third come out wrong (a closed gazebo, a tilted lamp, a lamp like a
  table) and are generated again with plainer words ("straight vertical", "open on all sides", "no walls").
- A lamp that looks tilted in one shot may only be seen at an angle: check from a second side before turning it.
- Every bench needs a reason: facing a view (the fountain), a stage or a table, with its lamp and a pot beside it.
  A row of benches along every path reads as random. One of each garden piece, never two of a kind side by side.
- A level step's additions must stay in later eras (has(step) = era > 1 or s >= step), or a new era's first level
  loses the market and the benches the level before had.
- generate_mesh cannot make flat things (an ivy panel, a vine on a wall, stepping stones): it returns a lump, a bush or
  a tiny tree. Generate the small piece it does well (one ivy leaf) and compose the flat thing in code from clones of
  that one mesh (a wandering stem, leaves in pairs, smaller as it climbs).
- A shelter (gazebo) is a place of its own: the table goes on open lawn beside it, not inside (the owner).
- Spread props through the whole village, not in rows at the entrance; small plants on paving move to free lawn.
- Before placing a street of stalls, measure how far the green runs before the next area's box: the pantry yard cut
  the market short at the last era.
- generate_mesh failed every incubator base (a cone, a tilted barrel, a plain bowl): a round machine that must hold a
  glass dome over an egg is better built from parts with care (feet, ribbed body, a front panel with porthole, dial
  and buttons, a dome held by curved ribs, a lamp cap and handle), styled per tier; small icons (emblems) are what
  the generator does well.
- 2026-10-28. The owner's quality bar for props is the greenhouse vegetables; how to meet it, and where each prop may
  stand, is the skill `prop-craft`. In short: generated models for solid objects (a third fail: check two sides),
  flat things composed from one generated piece, machines and wall fixtures built from parts with care; every prop with
  a reason, spread over the area, one of a kind, mounted things centred and even; export the kit after his Ctrl+S.
- 2026-10-28. The owner often plays in the same Studio: generate_mesh fails in Play ("only from the server"), so stop
  Play only after watching his character stand still 20-40 s, and write code while he plays.
- 2026-11-05 (the Arena, `tools/map/build_arena.luau`, `check_arena.luau`). An MCP `run` script cannot always `require` the
  shared Config/Layout ("Capabilities property: Network"): wrap it in `pcall` and keep the few numbers (GroundY, the market
  frame) as fallbacks. `run` prints only what the script returns, never `print`. `shot` works on a Studio you open yourself
  with `Start-Process` on the .rbxlx.
- 2026-11-05. `generate_mesh` for a gold crown came back peach and jagged (two tries, one failed outright). A flat symbol
  that must be a clean gold is quicker and truer from parts: a block band, three wedge-pair points with ball tips, a ball
  gem. Take a bad generated model OUT of the kit again, and do not index it.
- 2026-11-05. The kit's `CrownCrest` is the VIP's purple shield: never reuse it as "a crown".
- 2026-11-05. A white sticker plaque round a transparent emblem decal looks pasted on: make the plaque the colour of what it
  hangs on (blue on a blue banner, cream on the cream lintel). `Config.Ui.Icons.arena` (shield, crown, swords) works as a
  Decal id for the Arena's emblem until the slime-face crest exists.
- 2026-11-05. Neon over-brightens: a (96,178,255) glow read cyan and (255,150,112) read yellow from far. Pick the glow
  colour 40-60 darker and more saturated than the painting ((36,96,255) blue, (255,84,60) orange).
- 2026-11-05. Lilac ambient greys cream: use a warmer cream ((255,238,196) / (244,224,178)) and a more saturated sand
  ((230,188,118)) than the painting's own values, and judge from a shot, not from the numbers.
- 2026-11-05. A round pit from studs: a stack of 2-stud-thick rows of one block each, clipped to the circle, keeps the
  Roblox stud look (a cylinder cannot take studs). Ring pieces (stands, rim) as blocks laid tangent with their length from
  `2*r*tan(dA/2)`.
- 2026-11-05. A check that walks a 3-wide body needs a margin: the free circle of a 30-stud pit is radius 28 for the body's
  centre, else it reports the rim. Measure "how far out" from the 8 corners of each part (a long fence rail's half-length
  added to its centre overshoots by tens of studs).
- 2026-11-05. The flat floor behind the Market is only 690 studs across and hills rise at once: a 110 x 130 stud site fits
  only in the lane between the Market and plot 1, and plot 1's edge (a rotated square) must be kept 25 studs from every item.
- 2026-11-05. The Edit tool fails on multi-line `old_string` in the .luau builders (CRLF line ends): replace one line at a time.
- 2026-11-05 (the Arena SCENE, `tools/map/build_arena_stage.luau` -> `assets/ArenaStage.rbxm`, 6 rounds). One Luau file that
  runs in BOTH Studio (`run ... Edit`: model into ReplicatedStorage + a preview at the game's Origin) and Lune (`lune run`
  from the repo root: writes the .rbxm with `roblox.serializeModel`) keeps the scene in git and the Rojo build; detect Lune
  with `pcall(require, "@lune/roblox")`, shadow the Studio globals, avoid `Random` (use an LCG) and `PivotTo`.
- The camera is composed FIRST, then the set: a gate that the camera looks over must be LOWER than the ray from the camera
  to the near edge of what is behind it (camera y 26, 22 studs behind a gate: gate + shield top <= about 13 to show the
  near team circle). Round 1 had a tall pedestal and shield (18 high) that hid the crest; round 4 cut it to 13.
- A foreground that is not in frame is wasted: at 22 degrees down and FOV 70 the bottom edge is 57 degrees down, so with the
  camera 26 up everything nearer than 17 studs is off screen. Put the front-row spectators and the player's stand-in at
  13-18 studs from the camera, not under it, and drop a raised deck that only hides the gate's tunnel.
- A Decal on a Top face reads with its top toward -Z of the part; turn the part half a turn (Angles(0, PI, 0)) when the
  picture must read from the +Z side. Check the plan shot for crest and circle direction (crown toward the far gate).
- A Decal draws on a part with Transparency 1, and `Decal.Color3` multiplies: it can darken or cool a picture, not turn
  orange into tan. Darken with a bluish tint (170,190,255) plus alpha 0.15 so the sand shows through.
- Spectators from two Balls (body, tip) and a face Decal beat a 2400-triangle skinned slime: 344 of them are about 1,000
  parts. Give each Model a PrimaryPart (the body) so the client can hop it.
- Plain cream walls with arch openings look empty without a trim: blue pilasters with caps at each bay, a blue band and a
  45-degree chamfer diamond (2.4 stud) at each opening corner read as an arch from the camera for 5 parts a bay.
- Flames (`ParticleEmitter`) do not show in an Edit-mode `shot`; judge them in Play or trust the village's known recipe, and
  keep a Neon disc in the bowl so the brazier still reads lit.
- The ground under a floating stage must be built into the stage (a big cylinder 46 below plus low Ball hills): at the
  game's Origin (y 500) there is nothing below. A saturated lime ground overexposes under Brightness 2.6: use (92,154,68).
- (rounds 7-8) The owner wants the game's REAL slimes as spectators, never a two-ball stand-in: the scene holds invisible
  `Spot` parts and the client clones SlimeLook bodies onto them a few a frame (139 seats -> 127 with bay posts). Fire
  (`fire_main`) against a bright sky: LightEmission 1 washes white, 0.35 reads as grey smoke, 0.55 with deep orange/red reads
  as flame. A client copy of a scene must `PreloadAsync` its Decals when it is made, or the pictures pop in after the fade.
  Gold caps on a foreground block at the frame's edge read as bare yellow boxes: give them the gate's own colour.
- 2026-11-05 (the Arena DETAIL pass, 5 rounds, 1,426 -> 3,743 parts). Stone that reads as built, cheaply: a core block in a dark
  mortar colour and, 0.15 proud of it, offset course blocks in three creams with a 0.14 gap between them, so the core shows
  as mortar lines (one `courses(F, x0, x1, y0, y1, rowH, blockW)` helper on a face frame whose -Z points at the viewer).
- A round arch from parts without unions: n voussoirs (blocks tangent at the middle radius, every other one 0.05 prouder so
  their overlapping ends do not flicker, the middle one a gold keystone) plus 4 stepped spandrel slices kept outside the
  ring's MIDDLE circle (outside the inner circle leaves slivers; inside it cuts the opening). Two rings (gold in orange) make
  the gate's layered frame; a portcullis follows the arch with bar tops at ys + sqrt(R^2 - x^2).
- An X lattice is one crossed pair of thin bars a cell (the pair 0.04 apart in depth); about 2.5-3.4 studs a cell reads
  from 100 studs. Light-blue panel + blue bars for rails, bare cream bars for a balustrade over a red back.
- Roblox Ball parts are ALWAYS spheres of the smallest size: a "6 x 1.9 x 0.7 swag ball" is a 0.7 dot. Swags = a disc (a
  Cylinder turned to face the viewer) behind the valance with only its lower curve showing; handles = discs; tassels = a
  thin cylinder and a ball.
- Under this game's bright sun creams read white: the sandstone that matched the paintings was (234,200,146) /
  (222,184,128) / (242,214,164) with mortar (168,126,82). Lantern Neon (255,150,50) read yellow; (232,92,22) reads lamp.
- Spend parts where the fixed camera looks: ring pieces within 50 degrees of the seat's side are never in frame and are
  built plain (`DETAIL_FROM`); towers lose their courses there too. Decide what is in frame from the FOV, not by eye.
- Seats lost to aisles, planters and banners: plan them (each aisle ~2 seats a tier, a planter 1-2, a riser banner 1)
  and recover the count with the cull angle, not by squeezing the spacing.
- A tall front (royal box) must fit under the camera's top edge: top y <= camY + dist * tan(FOV/2 - pitch); here the
  pediment and crown were lowered (floor 15.5, crown top ~33) instead of moving the camera.
- (Arena round 7, ChatGPT art-director review) A PointLight at a gate's mouth plus full lights on small torches washed a
  solid orange gate to fluorescent yellow: put the glow deep in the tunnel (0.9, range 11) and scale torch lights with
  the flame. Openings that show the land read as flat bright panels in full grass green or saturated blue: a hazy green
  (136,178,112) and a blue-grey back (112,128,172) set at the arch's far face read as depth. One unbroken lattice band
  reads as a busy zigzag: alternate lattice and stone courses. A gold bowl against the sky reads as a yellow disc:
  bronze bowl, gold rim. Anything poking into the frame's corners from under the camera reads as a stray block: cut it.

## Dungeon Sunny Meadow rebuild (2026-11-08, Goo Lineage V2)

- A flat-colour FBX pack (Quaternius Ultimate Nature) goes to the painting's palette by MATERIAL NAME: Blender script writes a
  vertex colour per corner from a name -> hex table (`tools/library/fbx_to_glb.py`), then a Decimate (collapse) to 500 triangles
  keeps blob-leaf trees and bushes chunky. Rocks need no more than ~130. Pines with thin spikes break under decimation
  (black spot): leave that file out. Flowers at 400 triangles each were too heavy: 200 is plenty.
- glTF COLOR_0 from Blender is a NORMALIZED integer accessor: dividing by 255 only when `normalized` is set, or the colours
  come out blue and magenta.
- `require` in the Edit VM keeps the first run's module and its cached template whatever `.Source` is set to afterwards:
  a preview script must clone fresh copies of the modules (renamed) each run, or every round looks identical.
- Without an upload, an imported mesh can be previewed with `AssetService:CreateEditableMesh` + `CreateMeshPartAsync`; it
  does not draw vertex colours, so the preview part wears the dominant colour (the greenest one for trees and bushes).
  Judge shape, density and silhouette from it, not final colour.
- Open Cloud asset upload refuses any file outside a directory the creator approved for uploads, and a local place (not
  saved to Roblox) cannot approve one: do not look for a way round it. What works: `tools/library/combine_glb.py` packs a
  set's GLBs into ONE file (each prop its own object), the owner does a single File > Import 3D, and the MeshParts'
  MeshIds and sizes are read back by script into `Config.LibraryKit.Props`. The vertex colours survive the import.
- The imported Quaternius leaves are much brighter than the grass in game light: tints of about #a8b49c on round trees and
  #7ca89c on pines make the woods read apart from the clearing (ChatGPT review r8 -> r9).
- A camera at the rim sees scenery 90-130 studs away: it must be drawn about 1.4 times the painting's scale, and a
  top-down shot misleads (it hides the gaps that the player's view shows). Judge from the player's camera first.
- Backdrop trees need a small trunk footprint so their crowns overlap into one wall of woods; two rows (tall behind low)
  plus a bush row at the foot closed every gap. Far trees get `CastShadow = false`.
- A ring of hills = Ball parts, flattened, sunk 40 percent, Material Plastic (matte): SmoothPlastic made them glossy balls.
- Place the items with a fixed claim order (pairs of rocks, logs, stumps, singles, bushes, then flower clumps); the last
  kind in line is the one that finds no room, so put the least important last.
- Count the whole arena before calling it done: 273 models and about 70-75 thousand triangles is the Meadow's top; a
  first draft of flowers alone was 22 thousand.
