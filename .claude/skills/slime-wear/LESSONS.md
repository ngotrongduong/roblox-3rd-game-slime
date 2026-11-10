# Slime wear: lessons

What went wrong while dressing Secret slimes, and the fix now in the tools. Newest last; add to it after every kit that
taught something.

## 2026-11-10 (Tempest Dragon, Steam Dragon, Fire-Ice Chimera, Shadow Wolf)

| What went wrong | The fix |
|---|---|
| A horn's base found as its lowest 6 % of vertices caught one corner of a slanted cut; the horn sank by nothing and its base showed | `base_plane`: the plane, within 40 degrees of straight down, that touches the most vertices (a sole, or a hollow cup's lip) |
| Finding the base cap by flood fill took only part of it | the plane fit above |
| Scoring `base_plane` by face area instead of vertex count moved Steam Dragon's horns | kept the vertex count; rerun every kit after a change to `wear_kit.py` |
| `tilt_back` leaned the wrong way | positive leans back now; Tempest's numbers were changed to keep its look |
| The Chimera's horns, levelled, leaned 30-36 degrees and sideways: the file already had them upright | `level=False` keeps the file's turn |
| An ear's anchor was its single lowest vertex | `foot="low"`: the middle of its lowest tenth |
| Ears looked small and hidden in the game though fine in the renders | judge size in Play at the game's camera, not only in renders (scale 0.65 -> 0.85) |
| Horns and ears were sunk until their collar (an ear: its lowest 12 %) lay 0.03 inside: the wolf's lower fur, the Chimera's spiked collars and the dragons' horn bands were lost. The owner: "nằm sát phần ngoài của slime nhiều nhất có thể để giữ được các chi tiết gần gốc" | `seat`: moved along its axis until its foot touches the skin, only the foot's rim 0.02 under it; on a slope the lowest part is drawn down onto the skin |
| The two ears of a pair are different meshes, so their seated anchors differ by 0.0001 and the pair test failed | the test allows 0.005 for anchors of a pair |
| `upload_image` failed without its `imagePaths` | pass picture-server URLs |
| The owner's character stood in the shots | `play_check.luau` steps it aside |
| New files could not go into `git commit --only` | `git add` them first |
