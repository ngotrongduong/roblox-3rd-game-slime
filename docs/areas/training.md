# Training ground (home plot, front-left area, beside the gate)

Where slimes train their stats and where the squad gathers before going out to the Wild Garden, and
comes back to recover. Built directly in Studio in the classic stud look. No slimes in the build.

## Level 1 (built: `tools/map/build_training_l1.luau`, picture `training-l1.jpg`)

| Piece | What | Notes |
|---|---|---|
| Yard | a 26 x 24 packed-sand stud yard with a darker border, a low fence (posts and one rail) open at the front | |
| Dummy | a straw dummy on a post (base, burlap body and head, rope ties, a log for arms, a red-white target on the chest), 1.3x size | the hero piece |
| Training spot 1 | a straw mat facing the dummy, Attachment `WorkSpot1` | where a training slime stands |
| Archery target | a three-legged stand with a red-white target face and an arrow in it | |
| Weapon rack | posts and bars with a wooden sword, a staff with a glowing gem, a round blue shield | hints at the squad's weapon classes |
| Banner pole | a blue flag with a gold stripe on a pole, Attachment `SquadPoint` on its base | where the squad gathers before a trip |
| Signpost | crossed swords | tap: train, pick the squad, upgrade |
| Dressing | bushes, rocks, a tuft, flowers, a stump outside the fence | |

## Upgrades, levels 1-50 (`src/server/TrainingStages.luau`, pictures `upgrades/training-l35.jpg`, `training-l50.jpg`)

The pantry's pattern: five eras of ten levels, nothing taken away. The kit fence is replaced by a
part-built ranch fence with an entrance arch (crossed swords on a shield); the weapon rack stands
against the left fence facing in.

- Era start (1 / 11 / 21 / 31 / 41): 1 the yard, lamps by the entrance; 11 two-step stands at the
  back; 21 a punching bag with training spot 2, floodlight masts at the corners; 31 a canopy over the
  stands with a scoreboard, training spot 3 facing the archery target; 41 a podium with a golden
  trophy by the entrance.
- Levels 2-5 of an era: one prop a level, against the fence facing in. Strength: StoneWeights >
  WoodBarbell > DumbbellRack > WeightBench > GravityPress. Agility: TyreRun > JumpHurdles >
  BalanceBeam > ClimbingWall > HoloHoops. Recovery: RestBench > WaterCooler > MassageTable > IceBath >
  HealPod. Gear: SwordBarrel > ShieldRack > ArmorStand > SparringBot > HoloTrainer.
- Levels 6-10 of an era: floor, border, fence and stands, lamps and masts, arch and podium each move
  up one material tier.
