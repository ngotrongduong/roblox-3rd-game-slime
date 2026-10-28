# Material slimes: a rare mutation on hatching (2026-10-29)

The owner's direction (2026-10-29): the 19 materials he kept on the material stage
(`tools/slime/materials.luau`) are a rare mutation when an egg hatches, like the Dual slimes. Numbers below
are first values in `Config`; the owner tunes them by playing.

## Rules

- A new appearance kind next to Dual and Secret: `appearanceMutation = { type = "material", definitionId }`.
  One appearance per slime (Secret > Material > Dual > none); a material slime keeps its base colour genes.
- **Roll order per egg**: Secret, then Material, then Dual, then base-colour mutation (sequential, as today).
  `MaterialChance = 0.02`, multiplied by luck and capped like the others. Any pair can give a material,
  same colour included.
- **Which material**: a weighted pick by tier. Common (weight 6 each): Wood, Marble, Brick, Granite, Mud,
  Fabric, Sand, Grass, Clay Roof, Leather. Rare (weight 3): Glass, Ice, Jelly, Neon, Force Field, Lava.
  Precious (weight 1): Gold, Silver, Chrome. (Gold is about 1 egg in 4,000 at luck 1.)
- **Never inherited**: a material parent breeds as its base colour (as Duals and Secrets do).
- **Pity, Royal Jelly, Prism Serum**: unchanged (they give Duals and Secrets only). A material egg is not a
  plain egg, so it resets the pity counter like a Dual or a Secret.
- **Selling**: base value by tier, Common 150, Rare 300, Precious 800 (Dual 100, Secret 1000), times the
  usual level factor. Selling a material slime asks to confirm, as Duals and Secrets do.
- **Collection book**: a Material bucket with the 19 entries; a material hatch registers it and counts
  toward the rank like the other buckets. The egg details show "Material: 2%" next to Dual and Secret.

## Looks (for the client)

Each material is drawn on the shared slime body. "Own colour" materials ignore the slime's colour; "tinted"
ones take it. The outline hull is the drawn colour x 0.6, off for Neon, Force Field and Glass.

| Id | Name | Tier | Drawn as | Colour |
|---|---|---|---|---|
| gold | Gold | Precious | mirror metal: SurfaceAppearance, mirror map, metalness 1, roughness 0.03 | own #ffcf5a |
| silver | Silver | Precious | mirror metal | own #e9ecf0 |
| chrome | Chrome | Precious | mirror metal | own #ffffff |
| ice | Ice | Rare | SurfaceAppearance, roughness 0.03, transparency 0.35 | own #cfefff |
| jelly | Jelly | Rare | SurfaceAppearance, roughness 0.10, transparency 0.35 | tinted |
| glass | Glass | Rare | Roblox Glass, transparency 0.4 | tinted |
| neon | Neon | Rare | Roblox Neon | tinted |
| forcefield | Force Field | Rare | Roblox ForceField | tinted |
| lava | Lava | Rare | Roblox CrackedLava | own #d8402f |
| wood | Wood | Common | Roblox Wood | own #a0703f |
| marble | Marble | Common | Roblox Marble | own #e9e6df |
| brick | Brick | Common | Roblox Brick | own #a5523c |
| granite | Granite | Common | Roblox Granite | own #8d8780 |
| mud | Mud | Common | Roblox Mud | own #5a4532 |
| fabric | Fabric | Common | Roblox Fabric | tinted |
| sand | Sand | Common | Roblox Sand | own #e0c58f |
| grass | Grass | Common | Roblox Grass | own #5ea53e |
| clayroof | Clay Roof | Common | Roblox ClayRoofTiles | own #b5563a |
| leather | Leather | Common | Roblox Leather | own #6b4026 |
