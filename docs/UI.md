# The interface — direction (owner, 2026-10-27)

"The simplest interface possible, so it sits neatly on a small screen. Every upgrade and every
interaction happens directly with the objects on the player's plot and on the map."

What follows from it (to be detailed when the UI is designed):

- The screen keeps only what cannot live in the world: a small resource strip (coins, food), a
  few round buttons (quick travel Home / Market / Wild Garden, the squad), and short toasts.
  No menu wall of buttons, no big panels open by default.
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
