# Kitchen (home plot, middle-left area)

Built directly in Studio in the classic stud look, like the fishing pond and the garden.

## Level 1 (built: `tools/map/build_kitchen_l1.luau`, picture `kitchen-l1.jpg`)

| Piece | What | Notes |
|---|---|---|
| Floor | a 22 x 18 warm-brick stud patch with a darker one-stud border | the kitchen's island on the lawn |
| Stove | stone base and top, a glowing fire mouth (Neon + PointLight + a few embers), a short stone chimney | the hero piece |
| Pot | iron pot with orange soup, a ladle, a slow wisp of steam | |
| Cooking spot 1 | a round straw mat in front of the stove with an Attachment `WorkSpot1` | where the working slime stands, facing the stove |
| Counter | honey-wood counter with a cutting board, a fish (from the pond), carrots and a cabbage (from the garden), a bowl | shows the food loop: raw food in, dish out |
| Firewood | a small pyramid of logs, round ends to the front | |
| Signpost | pan icon, at the front corner | the area's interaction point (tap: level and upgrade) |
| Dressing | Nature stylized Pack: berry and flowering bushes, fern, tufts, flowers, a sunflower, a mossy boulder | Sway tags and blob shadows as on the other areas |

## Upgrades, levels 1-50 (`src/server/KitchenStages.luau`, pictures `upgrades/kitchen-l21.jpg`, `kitchen-L50.jpg`)

The pantry's pattern: five eras of ten levels, nothing taken away.

- Era start (1 / 11 / 21 / 31 / 41): 1 open pad with low rails, corner lamps and an entrance arch with a
  frying pan; 11 a gable roof on posts over the cooking line, hanging lanterns; 21 a back wall with
  windows, half walls at the sides, a brick bread oven, cooking spot 2; 31 a chimney stack through the
  roof, a pot rack, cooking spot 3; 41 a vent lantern on the ridge with a pan weather vane.
- Levels 2-5 of an era: one prop a level. Ingredients: VeggieCrates > PickleBarrels > SpiceCabinet >
  IceBox > GooFridge. Grill: CampGrill > StoneGrill > BrickBBQ > SteelGrill > PlasmaGrill. Water:
  WoodBarrel > HandPump > StoneSink > SteelSink > GooTap. Dishes: DishRack > PlateShelf > ServingCart >
  BuffetWarmer > FoodDispenser. Ingredients and water stand against the left wall, dishes against
  the right one, all facing in; the grill is out in the front yard, turned to the path (owner,
  2026-10-28: the props must face sensibly). HandPump and GooTap came from generate_mesh with their
  front sideways and get a fixed turn (`FRONT_TURN`). Picture `upgrades/kitchen-l45.jpg`.
- Levels 6-10 of an era: floor, floor border, rails and walls, lamps and roof, arch each move up one
  material tier.
