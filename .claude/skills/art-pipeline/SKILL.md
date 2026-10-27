---
name: art-pipeline
description: Bring art into Goo Lineage V2 - the owner's own 2D art from the original game, new pictures asked of ChatGPT (concept art, references, icons, textures), 3D models (Blender, the owner's image-to-3D, Studio's generate_mesh), effect packs and sounds - checking them, preparing them, uploading them, and naming them in the game. Use when a picture or model is needed, when the owner says pictures or models are ready, or when an asset is missing.
---

# Art: from the owner's paintings to the game

Adapted from the owner's previous game (Egg Heist, `C:\roblox 2nd game\.claude\skills\art-pipeline`). What is
different here: this game has a body of finished art already, the owner's own, from the web original
(`reference/goo-lineage-web/assets`, 600+ files, gitignored), and it is sacred.

## The rules that do not bend

- **The owner's art is never redrawn, recoloured, cropped, squashed or resized out of proportion**, and nothing is added
  to it (slimes have no legs). New art only where the owner allowed it, matching the existing style.
- **A missing asset goes to ChatGPT AT ONCE** (the owner's standing rule, said several times in his last game). When a
  look needs a picture that is not in the project (an icon, a texture, a reference for a model, a sprite sheet), do NOT
  fall back to a coloured dot, text glyphs or shapes drawn in code, and do not leave it for later: write the image
  prompt and send it to ChatGPT in the browser pane (its highest reasoning setting) in the same turn. Code may stand in
  only until the picture arrives, and the report says which picture is on its way. An agent that finds a missing asset
  says so in its report; the orchestrator sends it.
- Nothing from another developer's game: no models, names, images or sounds. Store models never keep their scripts.
- Uploading makes an asset of the owner's account and sends it through moderation: Claude never signs in for him.

## The style, in one breath

Hand-painted cozy cartoon (the owner's references, `art/chatgpt-refs/`): chunky rounded shapes, warm honey wood, cream
plaster, soft dark-brown outlines, soft cel shading, saturated harmonious colours, lush green grass with small white
flowers, royal blue and cream, green-and-cream striped awnings, small gold trims; slimes are glossy jelly drops with a
little peak, no arms, no legs. In 3D (`docs/DESIGN.md` §3): the same, as low-poly models. The full style lock for
ChatGPT is "Câu lệnh 0" of `docs/art/chatgpt-home-plot.md`: start every new ChatGPT conversation with it and the eight
reference pictures, then one subject a message. Simple and clean: few props, big readable shapes, no text in pictures.

## Kinds of art

| | 2D pictures | 3D models |
|---|---|---|
| What | UI icons and frames, buttons, slime faces (emotion art), item icons, avatar backgrounds, Dual / Secret body textures | slime body, plot areas at each level and remodel, Market stalls, scenery, monster slimes and enemies, gear, wings |
| Source | the owner's own files first; ChatGPT for what does not exist | built from the owner's painting or a ChatGPT turnaround |
| Arrives in | `art/inbox/` (the owner downloads ChatGPT pictures there) | `art/models/inbox/<key>.glb` (image-to-3D) or a Blender job's output |
| In the game | uploaded, the id written in one table of picture ids (`src/shared/Art.luau`, made with the first upload) | imported by the owner in Studio, then kept in `assets/` |

Nothing in the game waits for art: until it arrives the game shows a stand-in, and nothing in the rules changes when it
arrives.

## Pictures

1. Look at each one (Read shows images) against its prompt and the style. A picture that fails goes back to ChatGPT with
   one sentence on what is off; never repair the owner's art by hand.
2. Prepare: background keyed out, trimmed, padded, sized (256 for icons, 512 at most). The tool for this in the previous
   game, `tools\pictures.ps1` (keys out the flat corner colour with a soft edge, trims, pads, resizes, draws a
   `_sheet.png`), is ported with the first batch of icons. The owner's original UI art is used at its own proportions.
3. Upload: copy ONLY the prepared files into `art/upload_now/` (gitignored). With Studio's MCP: serve the folder
   (`node tools/serve_dir.js art/upload_now`) and call `upload_image` with the `http://localhost:8765/<file>.png` URLs; it
   returns `rbxassetid://` ids on the owner's account. Without it, the owner uploads through Studio (Window > Asset
   Manager > Import). Verify every id with `https://thumbnails.roblox.com/v1/assets?assetIds=<ids>&size=150x150&format=Png`
   ("Pending"/"Completed" = real, "Error" = misread) and LOOK at the thumbnail before the id goes into the game.
4. `check.ps1`, then a look in Studio at the screens that use them.

## Models

There are three routes; the choice is the orchestrator's.

1. **Blender** (the `model-artist` agent, skill `blender-image-to-3d`): for models that must match a painting closely
   (the slime body, the plot's buildings). From the painting plus a ChatGPT turnaround (front / side / back / top on a
   plain ground; `tools\split_views.ps1` of the previous game cuts a sheet into views of one scale and ground line, to
   be ported with the first turnaround).
2. **The owner's image-to-3D** (Meshy or similar, on his account): a reference picture in, a `.glb` out into
   `art/models/inbox/`. Then reduce it for phones (the previous game's `tools\models.ps1` + `tools/glb_rest.js` did:
   fewer triangles, a 1024 texture, the ground at 0, a skeleton's rest pose restored; port when the first file arrives).
3. **Studio's `generate_mesh`** for scenery and kit props (the `studio-build` skill).

Check every model before it goes anywhere: it opens, one textured mesh (or a few), under 20,000 triangles per mesh
(Roblox's limit; our budgets are far lower, see the `model-artist` agent), upright, facing the right way, and SIDE BY
SIDE with its painting. Importing uploads the mesh and texture to the owner's account: the owner opens the work place in
Studio, File > Import 3D, picks the ready files and saves the place (Studio signed in to the account that owns the
game). A model that came without a skeleton and must move gets one in Blender (skills `roblox-creature-rigging`,
`roblox-creature-animation`).

Glow: no rarity glow on slimes or gear in the world (the owner's veto). Parts that give light by nature (a lantern, a
glowing mushroom of the Mushroom Grove, a gem) may glow a little; never a whole body.

## Effects

Visible effects come from art (particle textures, the owner's effect packs in his Studio inventory, the original's effect
art in `reference/goo-lineage-web/assets`, or a picture asked of ChatGPT), never from code shapes; code places, scales,
tints and times them. Every rarity, element and Secret slime gets its own design: one asset recoloured is not a new
design (the owner's veto). Packs from his inventory come into a scratch place in Studio (`assets/raw/`), and only the
emitters, beams and trails are kept, no script (the previous game's `tools/import_vfx.luau` did this: port when the first
pack is used).

## Sounds

Only Roblox's licensed library (APMOfficial music, ProSoundEffects effects) or sounds the owner uploaded. Search without
signing in: `https://apis.roblox.com/toolbox-service/v2/assets:search?searchCategoryType=Audio&query=<term>&maxPageSize=60`
(keep only those two creators). The original's sounds under `assets/lib/bvker-foley/` come from a third-party library:
check its licence before uploading any of them.

## The game page

The icon and thumbnails are made from the owner's art and ChatGPT pictures without text; text is added afterwards. See
`store-page`.
