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
- Not done: the concept's warm glow behind the slime (it needs a painted glow piece, not a code shape).
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
bottom: a material shows the pieces that need it (picture and how many), a piece its points, rarity and how many are worn. It
reads the village folder's `Materials` and `GearBag` and each slime's `Gear`, and asks the server for nothing.
