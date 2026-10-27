# Câu lệnh ChatGPT: hình ảnh khu nhà người chơi (trước khi dựng 3D)

Mục đích: có tranh mẫu (concept art) cho khu nhà người chơi và từng khu bên trong, ở các cấp
nâng cấp, để làm chuẩn khi dựng mô hình 3D. Hình ảnh đẹp nhất có thể, nhưng thiết kế **đơn giản,
sạch sẽ**: khối lớn, ít đồ lặt vặt, nhìn rõ trên màn hình điện thoại.

## Cách dùng

1. Mở một cuộc trò chuyện mới trong ChatGPT, chọn chế độ tạo ảnh tốt nhất.
2. **Tin nhắn đầu tiên:** đính kèm 8 ảnh trong thư mục `art/chatgpt-refs/` (tranh gốc của bạn),
   rồi dán **Câu lệnh 0** (khóa phong cách). Chưa cần tạo ảnh ở bước này.
3. Dán lần lượt **Câu lệnh 1 → 9**, mỗi câu một tin nhắn, trong cùng cuộc trò chuyện đó để
   phong cách giữ nguyên. Câu 1 là ảnh toàn khu nhà. Hãy duyệt nó trước, rồi mới làm câu 2 → 9.
4. Ảnh nào ưng thì tải về, bỏ vào `art/inbox/` (tên file theo số câu lệnh, ví dụ `1-plot.png`,
   `2-fishing.png`) rồi báo mình. Ảnh nào chưa ưng thì nhắn ChatGPT sửa: "simpler", "fewer props",
   "keep the same footprint"...

Ảnh tham chiếu (đã chép sẵn vào `art/chatgpt-refs/`):
`01-farm-scene.png` toàn cảnh nông trại gốc · `02-fishing-pond.png` · `03-garden.png` ·
`04-kitchen.png` · `05-nest-house.png` · `06-blacksmith.png` · `07-shop.png` · `08-slime.png`.

---

## Câu lệnh 0 — khóa phong cách (gửi kèm 8 ảnh tham chiếu)

```text
These 8 images are my own artwork for my game "Goo Lineage V2". I am rebuilding the game in Roblox
as 3D, and I need concept art first. Study them carefully and use exactly this art style for every
image I ask for in this conversation:

STYLE (keep for every image)
- Hand-painted cozy cartoon, the same rendering as my references: chunky rounded shapes, warm
  honey-coloured wood, cream plaster, soft dark-brown outlines, soft cel shading with gentle
  highlights, saturated but harmonious colours, lush bright green grass with small white flowers,
  rounded grey stones, warm glowing lanterns.
- Accent colours: royal blue and cream, green-and-cream striped awnings, small gold trims.
- Slimes look exactly like my slime reference (08-slime.png): a glossy jelly drop with a little
  peak on top, NO arms, NO legs, NO extra details. Only use slimes for scale and life.
- Camera: the same isometric 3/4 top-down view as my references (about 35 degrees down).
- Sunny warm afternoon light from the upper left, soft short shadows, a little ambient occlusion
  where objects meet the ground, a gentle sparkle on water.

SIMPLE AND CLEAN (very important, simpler than my references)
- Big, readable shapes and clear silhouettes. Few props: at most 4-6 props per area.
- No clutter, no tiny repeated objects, no busy textures. Calm empty grass between areas.
- Designs must be easy to build later as low-poly 3D models for a mobile game.
- No text, no letters, no numbers anywhere (signs use simple icons only). No UI, no frames,
  no glow rings or circles under anything.

Reply only "Style locked" for now. I will send the image requests next.
```

---

## Câu lệnh 1 — toàn khu nhà (ảnh quan trọng nhất)

```text
Image 1: the whole home plot of one player, level 1 (just started), in the locked style.
Wide 16:9 image, isometric 3/4 view looking from the front gate toward the back.

The plot is a square lawn bordered by a low, neat, rounded green hedge, with a small wooden gate
arch in the middle of the FRONT edge (closest to the viewer). A sandy path enters through the gate.
Behind the plot (the far side) rise soft green hills with a small waterfall.

The plot is divided into a clear 3 x 3 layout, each area separated by grass and stepping-stone paths:
- BACK ROW (far): left = a small pond with a short wooden fishing dock and ONE fishing stool;
  middle = a small wooden storehouse (the pantry) with a few crates and barrels;
  right = a vegetable garden of 2 raised wooden soil beds with sprouts and ONE work spot.
- MIDDLE ROW: left = an open-air outdoor kitchen: a small stone oven, a wooden counter and ONE work
  spot, under a green-and-cream striped awning;
  middle = the slime meadow: open grass with the player's small cozy cottage (cream walls,
  royal-blue roof) and 3 or 4 navy slimes hopping and resting;
  right = the breeding house: a small round cottage with a soft pink roof and a little heart icon
  above the door.
- FRONT ROW (near): left = a training yard of packed sand with 2 wooden training dummies;
  middle = the gate area with a wooden signpost showing a slime icon;
  right = the hatchery: a straw nest holding 2 big speckled eggs, next to a tiny fenced baby pen.

Every area has ONE small wooden signpost with a round blank badge (where its level will show).
Keep it simple, tidy and charming, with lots of calm grass. Everything sits at level 1: small,
modest, wooden.
```

---

## Câu lệnh 2 → 9 — từng khu qua 4 cấp

Mỗi ảnh là một dải 4 hình, cùng góc nhìn và cùng tỉ lệ, từ trái sang phải: cấp 1, cấp 4, cấp 7,
cấp 10. Ở cấp 4, 7 và 10 công trình đổi hẳn (như trong `docs/MAP.md`). Các cấp nhỏ ở giữa chỉ thêm
một chi tiết, sẽ làm sau.

Đoạn chung đặt ở đầu mỗi câu 2 → 9 (đã gộp sẵn bên dưới):
"same locked style; a wide 16:9 sheet with 4 versions of the same area side by side on a plain
soft cream background, left to right: level 1, level 4, level 7, level 10; the same camera, the
same scale and the same ground footprint centre in all 4; each level visibly grander but still
simple and clean; a navy slime in each for scale; no text."

### Câu lệnh 2 — Hồ câu cá

```text
Image 2, same locked style: a wide 16:9 sheet with 4 versions of the same area side by side on a
plain soft cream background, left to right: level 1, level 4, level 7, level 10. Same camera, same
scale, same ground footprint centre in all 4; each level visibly grander but still simple and
clean; navy slimes for scale; no text.

Area: the FISHING POND. The number of fishing spots (small stools with a rod) grows: 1, 2, 3, 4.
- Level 1: a small round pond with lily pads, a short plank of wood as a dock, 1 fishing spot,
  a bucket.
- Level 4: a proper wooden dock with rope-wrapped posts and a lantern, 2 fishing spots.
- Level 7: a covered pier with a small roof and a little rowing boat tied to it, 3 fishing spots.
- Level 10: a big, graceful lake pier with a small lighthouse-lantern tower, 4 fishing spots,
  a fish-drying rack.
```

### Câu lệnh 3 — Vườn rau

```text
Image 3, same locked style: a wide 16:9 sheet with 4 versions of the same area side by side on a
plain soft cream background, left to right: level 1, level 4, level 7, level 10. Same camera, same
scale, same ground footprint centre in all 4; each level visibly grander but still simple and
clean; navy slimes for scale; no text.

Area: the VEGETABLE GARDEN. Work spots (a small kneeling mat with a watering can) grow: 1, 2, 3, 4.
- Level 1: 2 small soil beds with sprouts, 1 work spot, a seed sack.
- Level 4: 4 raised wooden beds with carrots, cabbages and tomatoes, a scarecrow, 2 work spots.
- Level 7: raised beds plus a small glass greenhouse corner, sunflowers, 3 work spots.
- Level 10: a full charming greenhouse with a curved glass roof, neat beds around it, a little
  windmill-style water pump, 4 work spots.
```

### Câu lệnh 4 — Bếp nấu

```text
Image 4, same locked style: a wide 16:9 sheet with 4 versions of the same area side by side on a
plain soft cream background, left to right: level 1, level 4, level 7, level 10. Same camera, same
scale, same ground footprint centre in all 4; each level visibly grander but still simple and
clean; navy slimes for scale; no text.

Area: the KITCHEN, where slimes cook dishes. Cooking spots (a stove or work counter) grow: 1, 2, 3, 4.
- Level 1: a small stone campfire stove with one cooking pot and a wooden counter, 1 spot.
- Level 4: an open-air kitchen with a striped green-and-cream awning roof, a stone oven, 2 spots.
- Level 7: a small cottage kitchen with an open front, a brick oven and chimney with soft smoke,
  3 spots.
- Level 10: a grand kitchen house with a big copper cauldron steaming gently, a tall chimney,
  4 spots.
```

### Câu lệnh 5 — Kho lương thực

```text
Image 5, same locked style: a wide 16:9 sheet with 4 versions of the same area side by side on a
plain soft cream background, left to right: level 1, level 4, level 7, level 10. Same camera, same
scale, same ground footprint centre in all 4; each level visibly grander but still simple and
clean; navy slimes for scale; no text.

Area: the PANTRY (food storage). It grows in size; no workers.
- Level 1: a small wooden shed with a few crates and a barrel by the door.
- Level 4: a sturdy storehouse with a stone cellar door at its side, more crates and sacks.
- Level 7: a two-storey wooden storehouse with a hayloft door and a hanging pulley.
- Level 10: a big round granary with a cone roof and a weather vane, crates neatly stacked.
```

### Câu lệnh 6 — Sân tập luyện

```text
Image 6, same locked style: a wide 16:9 sheet with 4 versions of the same area side by side on a
plain soft cream background, left to right: level 1, level 4, level 7, level 10. Same camera, same
scale, same ground footprint centre in all 4; each level visibly grander but still simple and
clean; navy slimes for scale; no text.

Area: the TRAINING GROUND, where slimes train and the squad gathers before going out to fight.
Training spots grow: 1, 2, 3, 4.
- Level 1: a patch of packed sand with 1 wooden training dummy.
- Level 4: a fenced sand yard with 2 dummies, a small hurdle and a weapon rack.
- Level 7: the yard with a simple dojo-style roof over one side, 3 training spots, a target board.
- Level 10: a small round arena with low stone walls and colourful banners (no letters), 4 spots.
```

### Câu lệnh 7 — Nhà sinh sản

```text
Image 7, same locked style: a wide 16:9 sheet with 4 versions of the same area side by side on a
plain soft cream background, left to right: level 1, level 4, level 7, level 10. Same camera, same
scale, same ground footprint centre in all 4; each level visibly grander but still simple and
clean; navy slimes for scale; no text.

Area: the BREEDING HOUSE, where two chosen slimes go to make an egg. It holds 1, 1, 2, 3 pairs.
Soft romantic but simple: pink roof, cream walls, a small heart icon over the door.
- Level 1: a small round cottage with a pink thatch roof, flowers by the door.
- Level 4: a bigger cottage with a little porch and a bell.
- Level 7: a two-room house with a small flower garden and a bench for waiting slimes.
- Level 10: an elegant small manor with a rounded pink roof, a gentle fountain in front.
```

### Câu lệnh 8 — Ổ ấp và nhà trẻ

```text
Image 8, same locked style: a wide 16:9 sheet with 4 versions of the same area side by side on a
plain soft cream background, left to right: level 1, level 4, level 7, level 10. Same camera, same
scale, same ground footprint centre in all 4; each level visibly grander but still simple and
clean; navy slimes for scale (include one small baby slime); no text.

Area: the HATCHERY and NURSERY: eggs incubate, then babies grow up. Egg places grow: 4, 5, 6, 8.
Use my nest-house reference (05-nest-house.png) as the main inspiration.
- Level 1: an open straw nest with 4 egg places and a tiny fenced baby pen.
- Level 4: a covered nest under a small thatched roof, a warm lantern.
- Level 7: a round hatchery hut like my nest-house reference, with a glass incubator window.
- Level 10: a hatchery with a small clock tower and a bigger fenced baby garden.
```

### Câu lệnh 9 — Nhà chính và cổng

```text
Image 9, same locked style: a wide 16:9 sheet with 4 versions side by side on a plain soft cream
background, left to right: level 1, level 4, level 7, level 10. Same camera, same scale, same
ground footprint centre in all 4; each level visibly grander but still simple and clean; navy
slimes for scale; no text.

Subject: the player's HOME COTTAGE in the slime meadow, together with the plot's FRONT GATE.
Cream walls, royal-blue roof, gold trims, like a calm version of my shop reference.
- Level 1: a small cottage with a round door; a simple wooden gate arch.
- Level 4: a bigger cottage with a flower box and a chimney; the gate gets a little roof.
- Level 7: a two-storey cottage with a balcony; a stone-and-wood gate with lanterns.
- Level 10: a charming small manor with a round tower; a grand gate with a banner (no letters).
```

---

## Sau khi ảnh được duyệt (để sau)

Với mỗi công trình được chọn, sẽ có thêm câu lệnh vẽ **bốn mặt** (trước, bên, sau, trên) trên nền
trơn để dựng 3D chính xác. Mình sẽ viết khi bạn đã chốt các ảnh 1 → 9.
