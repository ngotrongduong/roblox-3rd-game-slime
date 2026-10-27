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

## Bringing a built map into the game

- 2026-10-23. A map went into the game as files, no Studio at build time: in Studio, `CopyRegion` in 128-cell blocks
  full height into a folder, a `Base` CFrame, save; then Lune writes TerrainRegions (with a `Corner` attribute) and
  models into `assets/`. Rojo keeps a TerrainRegion's `SmoothGrid`; the server pastes it with `PasteRegion` (corner in
  CELLS). 16 regions + 7,650 instances = 1.4 MB. Lune can set `Model.WorldPivot`.
- A map that goes under its own ground must be LIFTED in the game: parts below `FallenPartsDestroyHeight` (-120 in the
  previous game) are destroyed.
- In Lune, `folder.Terrain` on an instance named like a service member fails: use `FindFirstChild`.
