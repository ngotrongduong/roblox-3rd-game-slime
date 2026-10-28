---
name: area-review
description: The owner's review loop for a plot area that upgrades (pantry, garden, breeding pen, kitchen, training ground, dock, village) - rebuild its buildings and props with detail fitting their function, judge every prop one by one against a 5-stud player, shoot every era in Studio, send the pictures to ChatGPT, weigh its answer, fix, repeat, then take the owner's own play-test notes. Use when the owner says to review, detail or fix an area, or names the next area to do.
---

# Area review loop

The owner set this process on 2026-10-28 and it carried all seven areas through (pantry, garden, breeding pen,
kitchen, training ground, fishing pond, village with its fence, gates and fountain). Replies to the owner are in
Vietnamese; every word in the game is English. Read first: `.claude/skills/studio-build/LESSONS.md` ("Buildings that
upgrade" and the notes under it) and skill `prop-craft` (how each prop is made to the owner's quality bar and placed
with a purpose). Sending to ChatGPT: skill `chatgpt-review`.

## The owner's rules for an area

1. **Every prop judged on its own.** Ask of each piece: does it belong here for what it does, is this spot right,
   if not where else, what could stand beside it. A prop that fits stays inside the area; never move everything out.
2. **Real size.** Check every prop against the red 5-stud block (the player, 1.75 m). Kit models are often half
   the size they should be; the owner asked for "twice as big" on a hoist, a small forklift and a robot arm.
3. **An area may grow with an upgrade, never shrink at a later level.** When it is cramped: grow the area once,
   permanently (the pantry's 14 x 20 service yard from L21; the garden's 4 studs at the back from L11), or move that
   one prop to a fitting spot outside. Never a pad that exists for one era only.
4. **Nothing overlaps, floats or blocks.** No prop through another, no load hanging into a roof or a cart's load,
   doors (a container's, a shed's) with room before them, a clear lane from the gate to the main door.
5. **Big things stand on paving**, never on grass, and show how they connect (pipes, chutes, outriggers).
6. **Fill a bare stretch with something that fits the function** (goods waiting, a small store hut), in the area's
   own style; a kit model from another style (a red-roofed cabin at the slime-tech era) is replaced by a built one.
7. **Things move when the area changes**: e.g. sunflowers back against the fence once the garden grows, a scarer
   to a free corner once the greenhouse fills the side strip.
8. **Crafted, not boxes.** Every prop at the greenhouse vegetables' finish (skill `prop-craft`): generated models for
   solid objects, careful part builds for machines and wall fixtures, never a plain block as the final look.
9. **Purpose and spread.** Each bench, lamp and planter has a reason where it stands; decorations spread over the
   whole area, one of each kind in view; mounted lamps and torches centred and even on every post; shelters keep
   their own space (the table beside the gazebo, not in it); paths all finished alike; no text signs unasked.
10. **The owner may ask for one piece in depth** (the incubator, an area gate, the main gate, the fountain): build it
    as a showpiece with its own module, its per-era look, and motion where it can have it.

## Steps

1. **Read the stage module** (`src/server/<Area>Stages.luau`): its `PROPS`, `SPOT` (slot -> era -> x, z, turn,
   real height, widest), `SURROUND` (life round the area), the builds per era. Note which side is which (+x is the
   area's left as one walks in; in the review camera it shows on screen-left for the pantry and garden).
2. **Measure in Studio** (Edit datamodel): the kit models' sizes (`ServerStorage.Kit.PropKit`), the area's floor and
   scenery (`workspace.Map.Plot5.<Area>`), what is free. The area frame is
   `Layout.plotAreaFacing(5, col, row) * CFrame.new(0, 2, 0)`; the area's own floor stands 0.2-0.4 above it, so
   props on it need that as lift (else they sink).
3. **Fix the code**, then `tools\check.ps1` (CHECK OK) and `tools\types.ps1` (TYPES OK).
4. **Sync and shoot in ONE short Play session** (Studio may be the owner's; stop Play as soon as the shots are in):
   - Edit mode: `node tools/studio_mcp.js run tools/map/sync_server.luau <studio_id> Edit NAME=path ...` (the
     command line is in the file's header; add `HoverBob=src/client/HoverBob.client.luau` when a prop hovers).
   - Start Play; `tools/chatgpt/shoot_setup.luau` (Server) defines `_G.AreaShow(module, areaName, col, row, level)`;
     `tools/chatgpt/shoot_camera.luau` (Client) defines `_G.ShotAt(col, row, eye, target)` (FoV 50).
   - A red `ScaleDummy` part (2 x 5 x 1) in the area near the front, on the floor.
   - Shoot each era (L05/15/25/35/45, or the levels the owner named) from the same camera; then the close-ups
     that matter. Stop Play.
   - Cameras used so far: pantry (0, 1) wide eye (-14, 28, -40) target (-9, 4, 0), close (-3, 17, -27) to
     (5, 3, -4); garden (1, 1) eye (-6, 26, -34) target (0, 2, 5); breeding (1, 0) eye (-2, 30, -42) target
     (-1, 2, 0), dummy at (2, 2.9, -9); breeding gate (4, 7, -30) to (4, 5, -13), incubators (-10, 6.5, -8) to
     (-17, 2.5, 1); kitchen gate (-1, 0) (0, 7, -26) to (0, 5, -9); training gate (-1, -1) (0, 7, -30) to
     (0, 5, -12).
   - The village is the whole plot, not an area: `tools/chatgpt/village_setup.luau` (Server) defines
     `_G.VillageShow(level)` (it returns the models that found no room) and `tools/chatgpt/village_cam.luau` (Client)
     `_G.PlotShot(eye, target)`; its cameras are in that file's header.
5. **Self-review the pictures first** against the rules above; fix what you see before asking anyone.
6. **Copy the shots** to `docs/areas/upgrades/review/<area>-r<round>-l<level>.jpg` (a scratchpad .ps1 with
   Copy-Item from the tool-results folder).
7. **ChatGPT** (skill `chatgpt-review`), one chat per area (pantry `/c/6ae139d2-409c-83ec-833c-ff8b31ccc2e5`,
   garden `/c/6ae146a7-ddf8-83ec-8abc-24d3874fcf8f`, breeding `/c/6ae16cd6-5028-83ec-ae28-cea433d73b62`, kitchen
   `/c/6ae18147-0a34-83ec-a8f3-2bedfb96ccf2`, training `/c/6ae18706-3350-83ec-bc03-72aaf0bcba82`, pond
   `/c/6ae190e4-f674-83ec-b9ec-613f846765c8`, village `/c/6ae19be6-ceb0-83ec-b71f-870ad6ff013a`), up to 5
   pictures a message. Brief in one paragraph:
   what the picture shows and the 5-stud block, the owner's rules above, what this round changed, what you did
   not take and why, your own doubts, and the ask: "judge every prop per level: right place for its function,
   right size against the red block, what could stand beside it, what overlaps or floats; give the 3-8 most
   valuable fixes, simple parts only".
8. **Weigh** its answer (it cannot see what the camera hides; check claims against the code); fix, re-shoot,
   and send again if worth it. Stop when it says the next pass is collisions only, not decoration.
9. **Commit** (only the orchestrator; `-c user.name=ngotrongduong -c user.email=ngotrongduong@gmail.com`), write
   new lessons into `studio-build/LESSONS.md`, report to the owner in Vietnamese: what changed, what ChatGPT said,
   what you took or left.
10. **The owner plays it** and sends pictures with notes; each note is a fix to make exactly (read carefully which
    level and which prop he means: "the forklift at L22-23" is the pallet-jack slot, not the L32 forklift). He often
    plays in the same Studio window: check before taking Play, and write code while waiting.
11. **New generated models**: ask him in the wrap-up box to press Ctrl+S, then export and commit the kit (skill
    `prop-craft` section 5). An area is done when he says it is fine.
