# The interface — direction (owner, 2026-10-27)

"The simplest interface possible, so it sits neatly on a small screen. Every upgrade and every
interaction happens directly with the objects on the player's plot and on the map."

What follows from it (to be detailed when the UI is designed):

- The screen keeps only what cannot live in the world: a small resource strip (coins, food), a
  few round buttons (quick travel Home / Market / Wild Garden, the squad), and short toasts.
  No menu wall of buttons, no big panels open by default. Judged on a landscape phone first (the owner, 2026-11-02): the
  strip is one row on the line of Roblox's own buttons, the round buttons one column on the right edge above jump.
- The world is the menu. Each area of a plot (pond, garden, kitchen, pantry, training ground,
  breeding house, hatchery) and each Market stall is tapped (or approached: a ProximityPrompt) to
  act on it: assign a worker by dragging/tapping a slime onto a work spot, upgrade from a small
  sign on the building, collect food from the pantry, put two slimes in the breeding house.
- What a panel must show (an upgrade's cost, a slime's stats) appears as a small card anchored
  to the object (BillboardGui / a compact bottom sheet on phones), closed by tapping elsewhere.
- Work spots, level signs and ready eggs are visible objects in the world, so the state of the
  farm is read by looking at it, not from lists.
- The owner's earlier UI likes and vetoes still hold (docs/reference/05-owner-history-*): icons
  over words, no explanatory text, lists that keep their scroll and sort, only usable slimes in
  pickers, thin elegant frames, tap outside to close, touch targets of 44 px or more.

## The UI kit (the owner, 2026-11-04: "the UI in the game exactly like ChatGPT's", every screen in that style)

Every frame, button, chip and bar is a piece of one painted kit that ChatGPT drew after the slime page concept
(`docs/ui/slime-sheet/concept.webp`): three sheets on magenta (`art/inbox/kit-frames|buttons|ornaments.webp`) cut by
`tools/chatgpt/prepare_ui_kit.py`, named and squeezed for 9-slicing by `tools/chatgpt/kit_slices.py` (map: `tools/chatgpt/ui_kit.json`)
into `art/ui/kit/<name>.png`, uploaded, and listed in `Config.Ui.Kit` (id, size, slice, scale, inset). `UiKit.kit(parent, name)`
draws a piece; `UiKit.skin` (modals = window, cards = square, with a `Fill` that `UiKit.setFill` tints for a picked or locked
state), `UiKit.button` (gold primary, green good, red danger, purple special, cream secondary; icon-only buttons are the square
piece tinted), `UiKit.chip` (the counter piece) and `UiKit.bar` (track + orange / blue / pink fill) all use it, so a new screen
built with UiKit is in the style with no extra work. Text on a coloured piece is white with the concept's dark outline
(`UiKit.outline`). Missing pieces go to ChatGPT in the same chat, on magenta, in the same style.
- Roblox quirk: a piece sliced only left and right (pills, bars, plates, ribbon) must use a thin middle row as its SliceCenter
  and `SliceScale = height / picture height`; a SliceCenter as tall as the picture draws arches. `UiKit.kit` does this.
- One frame per thing (the owner, 2026-11-04): a slime inside a card that has a frame is drawn bare
  (`UiSlimes.portrait(..., bare = true)`); only a slime standing alone (a team slot, a seat) keeps its own frame. A list row is
  the kit's row plate (`UiKit.rowBack`), never a hand-drawn rounded box with a stroke; a text pill is wide enough for its word to
  clear the round ends; an empty bar or line gives its room back to the list under it.
- Slime portrait backdrops (2026-11-15; the owner's concept glow, now painted): `UiSlimes.portrait` puts a ChatGPT-painted backdrop
  behind every slime, by kind: normal, dual, secret or material (`Config.Ui` backdrop ids; pictures `art/icons/backdrop_*.png`). The kind
  is read from the slime's attributes `SecretId`, then `Material`, then `DualId`, else normal. A normal slime's glow is tinted
  `BackdropTint` 0.35 of the way to its colour swatch; `BackdropTransparency` sets its strength, `DisabledTransparency` 0.5 a greyed
  one. It sits at ZIndex 0 with a UICorner.
- Buttons feel alive (2026-11-15; `UiKit` `pressable`, shared by `UiKit.button` and `UiKit.feel`; numbers in `Config.Ui`): on hover a
  button grows to `HoverScale` 1.05; pressed it shrinks to `PressScale` 0.92 and darkens to `PressShade` 0.8, then springs back. Rows
  and tiles (`UiKit.feel`) use the gentler `FeelHover` 1.02 and `FeelPress` 0.97. Hover follows mouse movement only, so a phone never
  leaves a button grown. Every press plays `UiKit.sound("click")` (`Sounds.click`, volume 0.25); a second tap inside `TapGap` 0.15 s is
  ignored.
- Coin fly (2026-11-15; `UiKit.coinFly(from, amount)`, the HUD coin chip registered with `UiKit.coinTarget`): after the server says a sale
  went through (slimes in `UiSquad`, dishes in `UiDishShop`), `CoinFlyMin` 6 to `CoinFlyMax` 12 coins (more for a bigger sale) burst up
  to `CoinBurst` 60 points from the button, then one every `CoinFlyStagger` 0.05 s curves into the chip in `CoinFlySeconds` 0.5. The
  chip pops to `CoinPop` 1.18, the coin jingle (`Sounds.coins`) plays on the first coin home, and the HUD number counts up over
  `CoinCountSeconds` 0.8 (a lower amount drops at once). The coins live in the ScreenGui `CoinFlyLayer`, 5 above the others.
- Shots on a phone frame: `docs/ui/kit/`.

## The slime's page (the owner, 2026-11-04: "make it like an RPG")

The detail page of the slime book (`client/UiSlimeSheet`, `client/UiGearSlots`; sizes in `Config.Ui.SlimeSheet`), built to
match `docs/ui/slime-sheet/concept.webp` with the kit. Header: Back, the hexagon portrait, a ribbon with the name and a "Lv n"
pill (the modal's Close at the right). Left: the slime on its pedestal between two gold accents, Head above it, Weapon (the Hand
slot) and Charm (the Tail slot) beside it, each a framed slot under a name plate (empty: the faint picture
`Icons.slotWeapon / slotHead / slotCharm`; worn: the piece); under it Feed (green), the Food / Energy / Fun bars on a plate, and
Equip (purple). Feed opens a list of the dishes in the fridge (tap one: `FeedDish`); Equip opens the list of the first empty slot.
Tapping a slot opens a short list beside it (the pieces of that slot in the bag, "Take off"); a tap outside closes it. Right: a
panel with Attack, Defence, Speed, HP, each a row with the slime's own value and the gear's bonus as a green "+n" pill, the trait
on a scroll ("Trait: Shy") and, while it works, Stop work. The page is a fixed stage of 720 x 320 points, shrunk to fit a
smaller room and never grown past 1.25x; it is laid out for landscape, not for a 360 px portrait phone.

## The Bag (the owner, 2026-11-04: an inventory for loot and gear)

`client/UiBag` (`Config.Ui.Bag`), a read-only modal from a round edge button just left of the book's (shown with the trophy,
once the tutorial is over). Tabs Materials and Gear. Materials: a tile for each material held (picture, count in the corner) in
the Dungeon's drop order, coins and food left out. Gear: grouped Weapon / Head / Charm, weakest tier first; a piece counts the
ones in the bag plus the ones slimes wear, and a small slime badge says how many are worn. Tapping a tile opens a strip at the
bottom: a material shows where it drops (`UiSmithy.sourceText`; a trophy reads "Used to temper gear.") and the pieces that need it
(picture and how many), a piece its points, rarity and how many are worn. A tempered twin is listed right after its plain piece and
wears the tempered badge (`Icons.tempered`, top right of its picture, `BadgeShare` 0.4 of the width). It reads the village folder's `Materials` and `GearBag` and each slime's `Gear`, and asks the server for nothing.

## The Market's Grocer tab (2026-11-15)

`client/UiDishShop` has two tabs at the Market: Dishes (only sellable dishes; spice dishes cannot be sold, so they never show) and
Grocer. The Grocer lists a row for each spice in `Config.Food.SpiceOrder`: its picture, its name in its rarity colour, the price of
one, how many are held, and two buy buttons, one for 1 and one for `Config.Food.SpiceBuyMax` (10). A button greys out when the coins
are short or the purchase would pass `SpiceCap` (99). A buy asks the server (`BuySpice`), and the coin fly and the counting chip
(above) play on the answer. The food list and the squad page read each dish's own numbers, so a Lasting Stew shows its +3% / +5% on all
four stats.

## The Smithy sheet and the forge scene (2026-11-15)

The Smithy's screen (tabs, family row, cost chips, Temper row) is in `docs/SMITHY.md` §6 and the forge scene after a craft or a
temper in §7; sizes are in `Config.Ui.Gear` and `Config.Ui.Forge`.
