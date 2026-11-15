# Drops, gear and the Smithy

The owner (2026-11-04): few kinds of drops, so crafting recipes stay easy to read. The owner (2026-11-15), the rebalance:
four dungeons, each drops ONE group of materials; every recipe needs two groups; deeper levels drop the higher materials;
mini-bosses and bosses drop the important ones for rare gear and a trophy found only in their dungeon; monsters of the open
world drop some craft materials too, the Dungeon at a better rate; gear made from the Dungeon's trophies (Tempered) is a
little better than plain gear, but a rarer tier is always better; five tiers; a new player reaches Iron weapons easily before
village level 20. Gear is crafted at a Blacksmith in the Market. Numbers live in `Config.Dungeon` (drops, `ConfigDungeon.luau`),
`Config.World` (packs and zone guards) and `Config.Smithy` (gear, recipes, tempering); the original's §13–15
(`docs/reference/02-battle.md`) were the starting point, cut down on purpose.

## 1. The materials (eleven that count)

| id | Name | Kind | Where |
|---|---|---|---|
| `wood` | Hardwood | group material ("basic") | Sunny Meadow (`Config.Dungeon.Maps.meadow.basic`) |
| `silk` | Mushroom Silk | basic | Mushroom Grove (`Maps.mushroom.basic`) |
| `ore` | Iron Ore | basic | Ember Lava (`Maps.lava.basic`) |
| `crystal` | Frost Crystal | basic | Frozen Ice (`Maps.ice.basic`) |
| `rare_part` | Core Fragment | tier catalyst (Epic) | mini-bosses and bosses from level 21; a few monsters |
| `monster_core` | Monster Core | tier catalyst (Mythic) | from level 31, mostly from level 51 |
| `boss_essence` | Boss Essence | tier catalyst (Legendary) | bosses from level 81, always from level 100 |
| `boar_tusk` | Bramble Horn | trophy | Sunny Meadow's bosses (`Maps.meadow.trophy`) |
| `glow_spore` | Glow Spore | trophy | Mushroom Grove's (`Maps.mushroom.trophy`) |
| `ember_core` | Ember Core | trophy | Ember Lava's (`Maps.lava.trophy`) |
| `frost_fang` | Frost Fang | trophy | Frozen Ice's (`Maps.ice.trophy`) |

Coins and food (Slime Snacks) still drop, as before. `cloth` and `common_part` stay in `Config.Dungeon.Materials` (saves hold
them) but nothing drops them and no recipe asks for them. Ids never change (saves hold them); `boar_tusk` is only named
"Bramble Horn" on screen. A trophy is a trophy of ONE dungeon and drops only from mini-bosses and bosses there; no recipe asks
for one: trophies are the price of Tempering (§4). The basics are common and come from many places; the catalysts decide a
tier (Epic needs Core Fragments, Mythic Monster Cores, Legendary Monster Cores and Boss Essence).

## 2. Who drops what

### In the Dungeon

The player picks one of the four dungeons for a run (`Config.Dungeon.MapOrder`); each monster keeps its own coins and food
lines (`Maps.<id>.monsters[].drops`: a line rolled on its own, `chance`, an amount `min`..`max`; `docs/DUNGEON_MAPS.md` §1).
The materials come from one block, `Config.Dungeon.Loot.Lines`, rolled per fallen monster by its ROLE (regular = swarmer,
raider, spitter, shaman, armoured; or mini-boss, or boss) and by the run's dungeon level L. There is no luck: a chance is what
it says. A line's chance is a list of steps by level; the last step at or under L holds, and one step may rise evenly.

| Line (1 unit unless a range is shown) | Regular monster | Mini-boss | Boss |
|---|---|---|---|
| basic of the map | 20% L 1-20, 24% L 21-50, 30% L 51-90, 40% L 91+ | always, 2-3 | always, 3-5 |
| Core Fragment | 0 to L 20, 2% L 21-50, 1% L 51-90, 0 from L 91 | 3% L 1-20, 35% from L 21 | 3% L 1-20, 70% from L 21 |
| Monster Core | 0 to L 50, 2% L 51-90, 3% from L 91 | 0 to L 30, 3% L 31-50, 50% from L 51 | 0 to L 30, 3% L 31-50, 100% from L 51 |
| Boss Essence | none | 0 to L 99, 20% from L 100 | 0 to L 80, 10% at L 81 rising evenly to 25% at L 99, 100% from L 100 |
| trophy of the map | none | 30% | always |

- **Clear bonus** (`Loot.ClearBonus` 0.35): when wave `Config.Dungeon.Waves` (10) is cleared, the basics the run has collected
  (every wave paid so far and this one) grow by 35%, rounded, and are paid with wave 10. Never on a lost wave.
- A wave's drops are paid when it clears and lost on a defeat or a leave, as before (`Dungeon.commitWave`, `discardWave`).
- Drops are seeded by the monster's id and the run's seed (`Dungeon.rollDrops`): a line spends its two rolls hit or not, so one
  line never moves another's. `Dungeon.dropTable(mapId, level)` lists what a map may drop at a level, as a range for each item
  (items at chance 0 on that level are left out); the gate sheet shows it.
- The mini-boss of wave 5 and the boss of wave 10 stand above the main level by `MiniBossAbove` and `BossAbove`
  (`docs/GAMEPLAY.md` §14).

### In the open world (packs)

A pack in the world (`shared/WorldPacks`, `Config.World.Packs`) has ONE basic, the material of the Dungeon map its region
belongs to (`Packs.Maps`: meadow region and Home Vale to Meadow, mushroom to Grove, ember to Lava, frost to Ice). A Home Vale
pack takes one of `Packs.ValeBasics` (wood, silk, ore, crystal) in turn by its cell's column plus row, so a new player meets all
four near home. The server publishes the pack's material as the attribute `Material` on its folder, and the pack's marker shows
that material's picture beside its level. A won pack pays, once, from a stream fixed by the pack's roll (`WorldPacks.loot`):

| Pays | When |
|---|---|
| its basic, 1 unit | always |
| a second unit | 50% (`SecondBasicChance`) from pack level 60 (`SecondBasicFrom`) |
| a Core Fragment | 1 in 6 (`RarePartChance`) from pack level 25 (`RarePartFrom`) |
| a Monster Core | 1 in 10 (`MonsterCoreChance`) from pack level 65 (`MonsterCoreFrom`) |

Never a trophy, never Boss Essence. A pack still pays coins by the role of every monster that falls (`CoinBase`).

### Zone guards

A zone's guard pays by the zone's kind, in place of its own drops (`Config.World.Reward`): the mini guard coins 1000-1600, 1-2
Iron Ore, a Core Fragment 50%, a Monster Core 15%; the boss coins 3000-4500, 2-3 Core Fragments, a Monster Core, a Boss
Essence 50%; the mega guard coins 8000-12000, 2-3 Monster Cores and 2 Boss Essence. No trophy: trophies are the Dungeon's own
(the owner, 2026-11-15). Every other monster of a zone drops what its def says (coins and food only).

## 3. Gear

Three slots on every slime: **Weapon** (attack), **Head** (a helm: defence and health), **Charm** (speed). (Shown as Weapon and
Charm since the owner's word, 2026-11-04; the saved ids stay `hand`, `head`, `tail`.)
Gear adds flat points to the slime's stats in every fight (dungeon and zombies); it never changes the slime's own stats,
its level or its price. Five tiers, the rarity colour shown only on screens (the original's veto: no glow in the world).
The weapon also gives the slime its class (2026-11-12): six families, 30 weapons, in `docs/WEAPONS.md` §4; the swords
below are one of them. The Smithy's Weapon tab shows one family at a time (a row of their pictures under the tabs).
Weapons have a fifth tier, Legendary (the owner, 2026-11-12, his own 3D set; Head and Charm stop at Mythic); a weapon's looks
grow with its rarity (§9 there).

| Tier | Rarity | Colour |
|---|---|---|
| wood | Common | #8f97a0 |
| iron | Uncommon | #3a9b3a |
| core | Epic | #8a4fd0 |
| bramble | Mythic | #f08a24 |
| legend | Legendary (weapons only) | #f7c600 |

| id | Name | Slot | Tier | ATK | DEF | SPD | HP |
|---|---|---|---|---|---|---|---|
| `sword-wood` | Wooden Sword | hand | wood | 1 | | | |
| `helm-wood` | Wooden Helm | head | wood | | 1 | | |
| `charm-wood` | Twig Charm | tail | wood | | | 1 | |
| `sword-iron` | Iron Sword | hand | iron | 2 | | | |
| `helm-iron` | Iron Helm | head | iron | | 2 | | 10 |
| `charm-iron` | Iron Charm | tail | iron | | | 1 | 10 |
| `sword-core` | Runeblade | hand | core | 4 | | 1 | |
| `helm-core` | Core Helm | head | core | | 3 | | 30 |
| `charm-core` | Core Charm | tail | core | 1 | | 3 | |
| `sword-bramble` | Dawnbreaker | hand | bramble | 5 | | 1 | 20 |
| `helm-bramble` | Bramble Crown | head | bramble | 2 | 4 | | 40 |
| `charm-bramble` | Bramble Charm | tail | bramble | | 2 | 3 | 30 |

Every Iron, Epic, Mythic and Legendary piece also has a **tempered twin** (§4). The other families' pieces are in
`docs/WEAPONS.md` §4.

## 4. Recipes and Tempering

### Recipes

One recipe a piece (the recipe's id is the piece's id), all 40 built in `Config.Smithy` from one table, not written by hand.
Every family has a fixed pair of basics (`Config.Smithy.Pairs`, the larger share first): sword ore + wood, shield ore +
crystal, bow wood + silk, focus crystal + silk, staff wood + crystal, kit silk + ore, helm ore + silk, charm crystal + wood. So
every recipe needs two groups, and a family is tied to two dungeons. By tier (`Config.Smithy.Cost`: `a` of the first basic, `b`
of the second, the catalysts, the coins):

| Tier | A | B | Catalysts | Coins |
|---|---|---|---|---|
| wood | 3 | 2 | | 0 |
| iron | 6 | 4 | | 500 |
| core | 12 | 8 | 2 Core Fragment | 3000 |
| bramble | 20 | 12 | 3 Monster Core | 12000 |
| legend | 30 | 20 | 5 Monster Core, 2 Boss Essence | 30000 |

Head and Charm cost half of every amount, rounded up (`Config.Smithy.Half`): for instance an Iron Helm is 3 ore, 2 silk and
250 coins. No recipe asks for a trophy. Crafting is atomic (the original's rule): check the recipe, the materials and the
coins; take them once; add one piece to the player's gear bag; a failed craft takes nothing, and the craft counts in
`farm.lifetime.gearCrafted`. A recipe shows its materials as pictures with "have / need".

**The starter kit** (Guide step `smithy`, the owner, 2026-11-15): when the tutorial reaches the Smithy it pays
`Config.Guide.StarterKit` (3 each of Hardwood, Silk, Ore and Crystal) into the materials, once (a step opens once): enough for
the first Common weapon of any family.

### Tempering (the owner, 2026-11-15: dungeon-made gear is a little better)

A plain piece of tier Iron and up can be tempered into its twin: its own gear id with `-t` added (`sword-iron-t`), built in
`Config.Smithy` from the plain piece (`tempered = true`, `base = <plain id>`, its name with " +" added). It has the same card
and ONE more point in the piece's main stat: the stat with the most points, in the order attack, defence, speed, hp, and a
piece whose main stat is HP gets `Config.Smithy.TemperHp` (10) HP instead (an Iron Sword 2 ATK becomes 3 ATK; an Iron Helm
gets +10 HP). A tempered piece of a tier is still weaker than the plain piece of the next tier in every family (a test checks
it). Common pieces cannot be tempered.

What tempering takes (`Config.Smithy.Temper`), the trophies of the TWO dungeons whose basics are the family's pair (a sword:
Ember Core and Bramble Horn; a bow: Bramble Horn and Glow Spore; Head and Charm the same as their pair; the cost is NOT halved):

| Tier of the plain piece | Trophies | Extra |
|---|---|---|
| iron | 1 of EITHER (the one the bag holds more of) | |
| core | 1 of each | |
| bramble | 1 of each | 2 Monster Core |
| legend | 2 of each | 2 Boss Essence |

`Gear.temper(farm, plainId)` takes one plain piece from the bag, the cost, and adds one tempered piece: all or nothing (a
refusal changes nothing), and counts as a craft. A piece a slime wears is not in the bag, so it is taken off first
(refused with `NOT_IN_BAG`); `CANNOT_TEMPER` for a Common or an already tempered piece. Equip, unequip and the rest take a
tempered id like any other. Request `SmithyTemper { gearId }` through `VillageRequests` and the server, with the same range
check (`env.atSmithy`, else `FAR`) and rate limit as `SmithyCraft`.

## 5. Saving

Schema 10: `farm.gear = { [gearId] = count }` (the bag: pieces nobody wears, plain and tempered ids together) and on each slime
`gear = { hand, head, tail }` (gear ids, each optional). Equipping moves one piece from the bag to the slime (what it wore goes
back to the bag); unequipping moves it back. A slime that is sold or released gives its gear back to the bag. Repair drops
unknown ids and negative counts; the migration from 9 adds an empty bag. The materials are `farm.materials` (every id of
`Config.Dungeon.Materials`). The depth and the dungeons' records are `farm.dungeon` (schema 16, `docs/GAMEPLAY.md` §14).

## 6. The Blacksmith and the Smithy screen (Market)

A stall in the Market built after the owner's `blacksmith-01.png` (honey wood frame with rope lashings, blue and cream
awning with the money-bag emblem, a stone furnace with fire, an anvil, a weapon rack, an armour stand, a water barrel,
banners) with the blacksmith slime of `npc.blacksmith.png` (navy bandana, brass goggles, leather apron, hammer) at the
anvil. Prompt "Blacksmith" opens the **Smithy** sheet (`client/UiSmithy`, sizes in `Config.Ui.Gear`): tabs Weapon / Head /
Charm, the Weapon tab with a row of the six families under it; a card per plain piece of the tab (the family's five tiers, or
the slot's four), with its picture on the rarity colour, name, stats as +numbers, the count held ("x2") and the cost row:

- **Cost chips**: each material as its picture and "have/need" (red when short), then the coins. A tap on a material chip says
  in a toast where it drops (`UiSmithy.sourceText`): a basic "Hardwood: Sunny Meadow dungeon and monsters on the map"; a trophy
  "Bramble Horn: Sunny Meadow dungeon bosses"; a catalyst the first dungeon level at which a monster drops it with at least
  `Config.Ui.Gear.SourceChance` (0.1), plus, for Core Fragment and Monster Core, the pack level of the open world (Core
  Fragment "Dungeon Lv 21+, monsters on the map Lv 25+", Monster Core "Dungeon Lv 51+, monsters on the map Lv 65+", Boss Essence
  "Dungeon Lv 81+ bosses"). The Bag's material strip shows the same line, and a trophy reads "Used to temper gear".
- **Craft** (greyed with "Missing materials" or "Not enough coins"), then the forge scene (§7).
- **Temper row**, on the card of every plain piece of Iron and up (the card is `Config.Ui.Gear.TemperRow` taller): the tempered
  badge and how many tempered twins the bag holds, the cost chips of §4 (for "either", the trophy the bag holds more of) and
  a Temper button (`TemperWidth` wide): "Temper" when the plain piece is in the bag and the cost is met, else greyed "None in
  bag" or "Need more". A worn piece is not in the bag, so it shows "None in bag" until it is taken off.
- **Tempered badge**: a tempered piece's picture wears the badge (`Config.Ui.Icons.tempered`, a quarter of `BadgeShare` of the
  picture's width) in its top right corner wherever a piece is drawn; the Bag and the slot picker list a tempered twin right
  after its plain piece, and a slime wearing one shows the plain piece's model.

Gear is worn from the slime's card (three slots; tap one, pick a piece from the bag, or take it off).

## 7. The forge scene (the owner, 2026-11-15)

After the server has made or tempered a piece (the request returned yes), the client plays a few seconds at the Market's anvil
(`client/ForgeScene.play(gearId, tempered)`, every number in `Config.Ui.Forge`). It is only a show: the piece is already in the
bag. It needs the Market's `Blacksmith` model with `AnvilFace`, `HammerHead` and `HammerHandle` (`Forge.Anvil`); without them,
or while another scene plays, nothing plays.

**Timeline** (seconds; a tier's own number in brackets):
1. The village screens and the player's own character hide, and the camera glides (`Glide` 0.35) to `CameraBack` 7.5 studs from
   the anvil's face towards the player, turned `SideAngle` -30 degrees, `CameraUp` 4.5 above it, `FieldOfView` 50.
2. A copy of the hammer lifts from `FirstHit` (0.35) and strikes `Hits` times (2 for Common and Uncommon, 3 for Epic, Mythic and
   Legendary), `HitGap` 0.33 apart. Each strike: the effect `hit.forge_strike` (variant = the tier) on the face, a ring of the
   anvil, the face heats towards `HotFace` (`HeatShare` 0.6 of the way by the last blow) and a light flashes in the tier's
   `Heat` colour (Common orange, Uncommon green, Epic violet, Mythic deep orange, Legendary gold; `HeatLight` 3, `HeatRange`
   7, fading in `HeatFade` 0.3).
3. `RiseDelay` (0.06) after the last strike the piece rises out of the face over `Rising` (0.8): from `StartScale` 0.15 to
   full size, its foot `Hover` 0.8 studs over the face, turning `Turns` once, then `SpinAfter` radians a second. A weapon is its
   model `WeaponLength` 2.6 studs tall (a tempered twin shows the plain piece's model); a helm, a charm, or a weapon whose mesh
   is not loaded yet, its picture `IconSize` 110 pixels. The burst `burst.forge_reveal` and a ting play as it rises; from Epic
   up, a weapon gets its class aura (`Config.Weapons.Fx.AuraTiers`) once it is `AuraAt` 0.9 of the way up.
4. Its name shows over it in the rarity colour (`CardAbove` 0.9 studs over, `CardWidth` x `CardHeight` 480 x 64 pixels) and
   stays `Hold` (0.6 Common and Uncommon, 0.7 Epic, 0.8 Mythic, 0.9 Legendary).
5. The camera glides back (`Back` 0.4) and everything is restored. The whole scene is about 2.9 s for Common and Uncommon,
   3.3 Epic, 3.4 Mythic and 3.5 s Legendary.

**Tempered pieces** also play the quench as the piece rises: `burst.forge_quench` and a hiss (`Sounds.steam`, cut after 1.3 s).

**Skip**: the first scene of a tier in a session always plays whole; after it, a tap anywhere ends a scene of that tier.

**Effects and sounds**: the three effects are VFX library ids (`Forge.Effects`: `hit.forge_strike`, `burst.forge_reveal`,
`burst.forge_quench`, imported from library 4c63757), each with a variant per tier; the scene skips any effect the game's
copy lacks, and loads the three's pictures once at start with `VfxLib.preload` (a picture first asked for mid-scene came
too late). Sounds are Roblox's licensed Pro Sound Effects (`Forge.Sounds`: strike, ting, steam), played at the
anvil.
