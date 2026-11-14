# Secret slimes: skins (now) and the earlier turnaround -> Meshy ledger

## The direction now (the owner, 2026-11-08, later the same day)

- Every special (Secret) slime gets a SKIN drawn by ChatGPT, put on the base slime body like the Dual and zombie
  skins (2048 x 1024 all-round wrap: top = tip, middle = front, left and right edges meet at the back). Ears, tails,
  horns, wings and other parts are built later as separate pieces, coloured, and attached to each slime.
- Meshy: the owner sends pictures to Meshy himself and checks the results; Claude does not. The one Meshy model
  made here (Storm Shark, multi-view, 30 credits) came out a paper-thin slab: a credit refund was asked of
  support@meshy.ai on 2026-11-08 (tasks 01a1b97d-1c8e-71c5-aea0-7352daec8a13 and 01a1b97c-cd43-703a-9b95-e77d93fcd31d).
- Tools: `tools/skins/make_secret_skin_prompts.py <batch.json> <first group> rich` (three slimes per chat, the
  slimes' own pictures attached), `tools/skins/prepare_secret_skins.py <group>` (2048 x 1024, empty top band cut,
  seam cross-faded; `--pick 2 5 6` names which gen_N is each slime's skin, `0` skips one) -> `art/models/slime_body/skins/s_<file
  pair>.png` and `art/upload_now/`. Batches: `art/turnaround/batch_wingless.json` (46), `batch_winged.json` (19, the
  body only: wings, ears, horns and tails are separate parts).

The first round (folders `skins-g1..g5`) used a flat-vector layout example and "flat colours": the owner found it
too simple. The current round (`rich-g<N>`) asks for the detail of each slime's own picture, no layout example; from
g10 on it also says "hand-painted with visible brushwork, never flat vector art", because about one chat in three
(g9, the Thunder Ram in g7) still came back as flat vector fills; those were asked again in the same chat.

| Group | Slimes | Chat | Skins |
|---|---|---|---|
| rich-g1 | gray-navy, black-black, black-gray | /c/6af0122e-d97c-83ec-b005-3504dde2d1e7 | prepared |
| rich-g2 | black-green, black-orange, black-purple | /c/6af0124a-2f64-83ec-a103-bf186b689d1e | prepared |
| rich-g3 | black-white, blue-green, blue-navy | /c/6af012bc-1dd0-83ec-ac00-f01734df1245 | prepared (`--pick 1 3 4`) |
| rich-g4 | blue-orange, blue-pink, blue-purple | /c/6af012d5-7080-83ec-8356-d6993a4efec3 | prepared |
| rich-g5 | blue-red, gray-gray, gray-orange | /c/6af012f0-2698-83ec-9cba-6c8d9d6ecdba | prepared |
| rich-g6 | gray-pink, gray-red, gray-white | /c/6af0133e-87a8-83ec-802e-0497cf8eedd6 | prepared |
| rich-g7 | gray-yellow, green-green, green-navy | /c/6af013c3-6b90-83ec-88d8-b541d02bac91 | prepared (gray-yellow redrawn) |
| rich-g8 | green-orange, green-pink, green-purple | /c/6af013df-6c74-83ec-90aa-020abf9a3e83 | prepared |
| rich-g9 | green-red, green-white, green-yellow | /c/6af0140e-b844-83ec-b34e-242aba1d9c58 | prepared (redrawn, `--pick 5 4 6`) |
| rich-g10 | navy-navy, navy-orange, navy-purple | /c/6af03e27-9f54-83ec-b084-0d835878d808 | prepared |
| rich-g11 | navy-red, navy-white, orange-orange | /c/6af03e4a-27cc-83ec-b927-7d163c3beb9e | prepared |
| rich-g12 | orange-pink, orange-purple, orange-white | /c/6af03ead-1f90-83ec-a1e7-d5ce30ba26c8 | prepared |
| rich-g13 | `batch_wingless.json`, next three | /c/6af03f78-9664-83ec-af72-0bafd9926de8 | prepared (`--pick 2 3 1`) |
| rich-g14 | `batch_wingless.json`, next three | /c/6af04298-f6e4-83ec-914a-4402abd1ef68 | prepared (`--pick 2 3 1`) |
| rich-g15 | `batch_wingless.json`, next three | /c/6af042bc-6094-83ec-a259-699a175a0dc9 | prepared (Snow Rabbit asked alone) |
| rich-g16 | `batch_wingless.json`, the last | /c/6af042df-9f00-83ec-ba48-4738daa6e919 | prepared |
| rich-g17 | `batch_winged.json`, first three | /c/6af04376-39f8-83ec-bcad-a8a4b30839b5 | prepared (`--pick 2 3 1`) |
| rich-g18 | `batch_winged.json`, next three | /c/6af043a0-84f4-83ec-834c-dc83b42f9d02 | prepared (`--pick 2 3 1`) |
| rich-g19 | `batch_winged.json`, next three | /c/6af043b8-be48-83ec-b4c2-17f27112b6a6 | prepared (`--pick 2 3 1`) |
| rich-g20 | `batch_winged.json`, next three | /c/6af05ac2-9848-83ec-97cf-f5a4ff0d31ca | prepared (`--pick 2 3 1`) |
| rich-g21 | `batch_winged.json`, next three | /c/6af05adb-9170-83ec-8ce0-cdfe845e32dc | prepared (`--pick 2 3 1`) |
| rich-g22 | `batch_winged.json`, next three | /c/6af05af0-42a0-83ec-8ebd-9cbeab44f763 | prepared (`--pick 2 3 1`) |
| rich-g23 | `batch_winged.json`, the last | /c/6af05cb4-0540-83ec-a6e0-3cc9c77a80a9 | prepared |

All 65 skins were uploaded on 2026-11-08 and are in `src/shared/SkinIds.luau` (`SkinIds.Secrets`), seen in a Studio
play test on the village slimes. Moss Golem (gray-green) has none: the owner made its 3D model himself. Clicking a
reply's thumbnails to load them turns the page order round (the last image comes first), hence the many `2 3 1`
picks: look at every group's sheet before picking. `tools/skins/map_secret_skins.py [upload results]` matches each
picture to its recipe by NAME (the original art's file pairs differ from the recipe colours for 7 recipes), merges the
upload ids into `asset_ids.json` and prints the `SkinIds.Secrets` rows.

## World scenery through Meshy Smart Topology (2026-11-14)

One picture each (`art/turnaround/<subject>/source.png`, cut from `docs/references/world/world_ref_3.webp`), Smart
Topology tab, poly count 3000, Texture on (Meshy N1, 2K), 15 credits each (718 -> 673). Files:
`art/models/world/gates/<subject>.glb`.

| Subject | Meshy model (owner's workspace) | Credits | Triangles | File | Roblox id |
|---|---|---|---|---|---|
| root_gate | Enchanted Mushroom Arch (2026-11-13) | 15 | 3,930 | root_gate.glb (4.6 MB) | 110858843893866 |
| ember_gate | Molten Crystal Gate (2026-11-13) | 15 | 3,110 | ember_gate.glb (3.8 MB) | 131059782610116 |
| frost_gate | Frostcrystal Gateway (2026-11-14) | 15 | 3,167 | frost_gate.glb (3.7 MB) | 83305165757925 |

The Heart's own scenery (2026-11-14, the owner's redesign of the central area): six sources cut from
`docs/references/heart/heart_ref_assets.webp` and `heart_ref_assets2.webp`, the same settings, 15 credits each
(673 -> 583). Files: `art/models/world/heart/<name>.glb`; taken into `ServerStorage.WorldKit` by
`tools/world/take_heart.luau`; every front faces -Z.

| Name | Triangles | Roblox id | Used as |
|---|---|---|---|
| CrownShrine | 4,738 | 129882405246422 | the shrine at the north of the island, 104 tall |
| HeartGuardian | 2,564 | 104753794485071 | crowned slime statues: 6 at the causeways (28), 2 by the shrine (40) |
| RuinColonnade | 3,028 | 74984591414162 | 6 ruins on the far shore, 24 tall |
| SlimeSpout | 3,097 | 127775916474282 | 4 slime heads pouring into the lake, 38 tall |
| RuneStone | 1,176 | 111689925366023 | 10 stones round the arena, 22 tall |
| CrystalLantern | 986 | 98344425380349 | 24 lanterns on the causeways' kerb posts, 11 tall |

## Earlier: turnaround -> Meshy (stopped)

The owner's request (2026-11-08): every Secret ("special") slime made into a 3D model this way: ChatGPT draws the
FRONT, LEFT, BACK and RIGHT views of the original picture in flat base colours (no light, no effects), the views go
into Meshy's Image to 3D Multi-view slots at Standard resolution, the model is reduced with Meshy's free Remesh to a
Roblox-sized triangle count, then uploaded to Roblox. The slimes WITHOUT wings first, the winged ones after; every
ChatGPT request names what the slime is.

- Work folders (gitignored): `art/turnaround/secret-<file pair>/` (source.png = `slime.secret.<file pair>.png`,
  raw_*.webp from ChatGPT, front/left/back/right.png lined up, views_sheet.jpg).
- The original's file names do not always match `SecretRecipes` colours (the file `white-yellow` is the Sakura Bunny):
  the descriptions below are written from the pictures.
- Meshy: Standard multi-view costs 30 credits; the account had 973 on 2026-11-08 (about 32 models). Never top up.
- Left/right: Meshy's "Left" slot is the subject's OWN left side (a profile facing the image's left edge).
- Background asked of ChatGPT: magenta, green (purple/pink/violet edges) or cyan (lime or green next to purple/pink).

## Without wings (first)

| # | File pair | What it is (told to ChatGPT) | BG | Chat | Views | Meshy | Tris | Roblox id |
|---|---|---|---|---|---|---|---|---|
| 1 | gray-navy | Storm Shark: smooth jelly body filled with storm clouds, rain and a lightning bolt; the curved pointed tip is the shark fin | magenta | /c/6aeffae2-c378-83ec-8668-29b192dd599d | asked | | | |
| 2 | black-black | Universe Slime: the whole body is a night sky of deep purple and blue space, pink nebulae, a spiral galaxy and stars | magenta | | | | | |
| 3 | black-gray | Shadow Wolf: smoky black jelly body with two pointed black wolf ears | magenta | | | | | |
| 4 | black-green | Swamp Basilisk: one half lime-green jelly, the other half dark scaly reptile skin, a spiky dark crest on top, green eye-spot markings | magenta | | | | | |
| 5 | black-orange | Jack-o'-Slime: orange pumpkin skin with dark ribs, a dark stem tip and curling green vines with leaves around it | magenta | | | | | |
| 6 | black-purple | Void Kraken: dark purple body with purple tentacles curling out of its sides and bottom, rune marks and a dark eye rune on the front | green | | | | | |
| 7 | black-white | Yin-Yang Koi: the body split into a white and black yin-yang pattern with its two dots | magenta | | | | | |
| 8 | blue-green | Sky Island Turtle: half blue sky with white clouds, half green grassy land with flowers and a tiny waterfall, a sprout on the tip, small green turtle flippers at the bottom | magenta | | | | | |
| 9 | blue-navy | Aurora Jellyfish: blue and violet swirling bell body, a frilly cap on top and short tentacles under the bottom edge | green | | | | | |
| 10 | blue-orange | Sunshower Fox: half sky-blue with white clouds and rainbow raindrops, half orange with a sun, two small fox ears on top | magenta | | | | | |
| 11 | blue-pink | Cotton Candy Sheep: pastel blue body with pink cotton-candy cloud patches, a ring of fluffy pink-and-blue cloud wool round the top and bottom, two small curled pink ram horns | green | | | | | |
| 12 | blue-purple | Celestial Manta: sky blue on one side, dark navy with white constellation lines on the other, wide manta fins on both sides and a thin tail | magenta | | | | | |
| 13 | blue-red | Raincloud Ram: half gray storm cloud with lightning marks, half blue with raindrops, curled gray cloud ram horns on top | magenta | | | | | |
| 14 | gray-gray | Stone Tortoise: dark gray stone body with a tortoise shell of stone plates on top and moss between them | magenta | | | | | |
| 15 | gray-orange | Copper Beetle: dark steel body with a copper-orange beetle shell split down the middle, rivets, small curved beetle legs at the bottom | magenta | | | | | |
| 16 | gray-pink | Rose Hedgehog: pink and gray marbled body, gray hedgehog spines over its back with tiny pink roses among them | green | | | | | |
| 17 | gray-red | Iron Boar: half gray riveted iron, half red armour with iron bands, two curved boar tusks at the bottom sides | magenta | | | | | |
| 18 | gray-white | Cloud Sheep: white and gray body full of curly cloud wool, small dark gray hooves at the bottom | magenta | | | | | |
| 19 | gray-yellow | Thunder Ram: golden yellow body with big curled brown ram horns and yellow lightning zigzags | magenta | | | | | |
| 20 | green-green | Forest Dryad: green body with leaf patterns, a crown of leaves and small flowers, brown deer antlers on top | magenta | | | | | |
| 21 | green-navy | Lagoon Turtle: top half dark blue with a water-ripple shell pattern, bottom half turquoise water with green seaweed | magenta | | | | | |
| 22 | green-orange | Autumn Fox: half green, half orange with maple leaves, two pointed orange fox ears with leaf tips | magenta | | | | | |
| 23 | green-pink | Watermelon Frog: green striped rind round the edge, pink flesh with dark seeds on the front, small green frog feet | cyan | | | | | |
| 24 | green-purple | Poison Frog: purple and lime-green body with purple spots, two bulging frog eyes on top, frog feet at the bottom | cyan | | | | | |
| 25 | green-red | Holly Deer: half green, half red, brown deer antlers decorated with holly leaves and red berries | magenta | | | | | |
| 26 | green-white | Lily Spirit: pale white-green body with green vines and white lily-of-the-valley flowers | magenta | | | | | |
| 27 | green-yellow | Lemon Gecko: lime-green and yellow body with lemon slices in its lower half | magenta | | | | | |
| 28 | navy-navy | Deep-Sea Leviathan: dark navy anglerfish body with scale texture, an anglerfish lure on a stalk from its top, small blue fins on its sides | magenta | | | | | |
| 29 | navy-orange | Sunset Koi: orange body with a sunset over navy Japanese-style waves on its lower half | magenta | | | | | |
| 30 | navy-purple | Galaxy Whale: deep purple-blue galaxy body with a swirl, small whale fins on its sides | green | | | | | |
| 31 | navy-red | Fire-Ice Chimera: one half red with flames and a red horn, the other half dark blue with snowflakes, ice crystals and an icy horn | magenta | | | | | |
| 32 | navy-white | Arctic Wolf: white body with navy lower half and white fur markings, two pointed navy-and-white wolf ears | magenta | | | | | |
| 33 | orange-orange | Ember Tiger: orange body with dark tiger stripes, round tiger ears and a flame mark on the front | magenta | | | | | |
| 34 | orange-pink | Coral Axolotl: peach-pink body with orange marbling, three feathery pink axolotl gills on each side | green | | | | | |
| 35 | orange-purple | Witch Cat: half orange, half purple with cat ears, a witch-hat marking and swirls | green | | | | | |
| 36 | orange-white | Daisy Chick: yellow and white body with a yellow feather tuft on top and big white daisies | magenta | | | | | |
| 37 | pink-white | Creamsicle Fox: orange and cream swirled body, two orange fox ears with cream insides | magenta | | | | | |
| 38 | pink-yellow | Peach Blossom: pink and peach marbled body, a crown of peach-pink blossoms with green leaves round the top | cyan | | | | | |
| 39 | purple-purple | Amethyst Unicorn: purple body, a spiral crystal unicorn horn, a crystal mane along the top, crystal gems at the bottom | green | | | | | |
| 40 | purple-red | Dragonfruit Slime: half magenta-red, half dark purple fruit skin with black seeds and green leafy scale tips | cyan | | | | | |
| 41 | purple-white | Moon Orchid: pale lavender body with white orchid flowers and a crescent moon | green | | | | | |
| 42 | red-white | Peppermint Slime: red and white peppermint-candy swirl | magenta | | | | | |
| 43 | red-yellow | Fire Salamander: red body with yellow-orange flame patterns along the bottom, a flame tail on one side and a flame crest on top | magenta | | | | | |
| 44 | white-white | Snow Rabbit: white fluffy fur-textured body, two long white rabbit ears with pink insides | magenta | | | | | |
| 45 | white-yellow | Sakura Bunny: pale pink body with cherry-blossom patterns, two pink bunny ears | green | | | | | |
| 46 | yellow-yellow | Sun Lion: golden body, a big mane of sun rays all round, a sun swirl mark | magenta | | | | | |

## With wings (after)

black-blue (Tempest Dragon), black-navy (Midnight Raven), black-pink (Gothic Bat), black-red (Blood Moon Bat),
black-yellow (Honeybee), blue-blue (Cloud Pegasus), blue-gray (Steam Dragon), blue-white (Frost Swan), blue-yellow
(Thunderbird), gray-purple (Moonstone Gargoyle), navy-pink (Twilight Moth), navy-yellow (Star Owl), orange-red (Fire
Dragon), orange-yellow (Sun Phoenix), pink-pink (Rose Fairy), pink-purple (Dream Butterfly), pink-red (Lovebird),
purple-yellow (Royal Griffin), red-red (Rose Dragon).

## Done by the owner

gray-green (Moss Golem): made and uploaded by the owner; its views here only proved the tools.

2026-11-11: the owner's own 3D models replace the skin-on-body look of Moss Golem (gray-green), Stone Tortoise
(gray-gray) and Dragonfruit Slime (purple-red). `tools/blender/secret_body.ps1 <folder>` sets each in the shared body's
box on the same bones (`art/models/secret_bodies/<folder>/`), `Config.Wear.Bodies` names the mesh and maps,
`client/SlimeLook` gives the shared body that mesh (`MeshPart:ApplyMesh`) so it squashes, hops and wears the face as
every slime; the maps are ClientKit.Looks `Body_<secret>` (`tools/kit/add_body_looks.luau`).
