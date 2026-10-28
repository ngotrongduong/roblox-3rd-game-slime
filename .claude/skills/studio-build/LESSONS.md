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
