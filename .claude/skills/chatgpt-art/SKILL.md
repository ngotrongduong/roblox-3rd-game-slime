---
name: chatgpt-art
description: Get game art from ChatGPT in Claude's own browser pane and into the game in one sitting - icon sheets, UI parts (a prize wheel, frames, buttons), item and shop icons, textures, flipbook sprites, concept pictures - attach the owner's icons as the style lock, ask for flat-magenta sheets, bring the pictures back without the owner, cut and key them, upload through Studio, name the ids in Config. Use whenever a picture is missing, for any batch of icons or UI art, and before drawing anything in code.
---

# ChatGPT art, end to end

Proven on 2026-11-06 (the Lucky Wheel and 20 shop icons, all usable at the first try, about 10 minutes of Claude time).
The owner's rules: a missing picture goes to ChatGPT AT ONCE, at its highest thinking effort; never a code-drawn shape
as the final look; the owner's own art is never redrawn. Talking to ChatGPT happens in Claude's OWN browser pane
(`mcp__Claude_Browser__*`, already signed in); the attach/send/read mechanics are in skill `chatgpt-review`.

## 1. Ask

- Start the picture server once, in the background: `python "C:/Roblox 3rd game/tools/chatgpt/serve.py"` (127.0.0.1:18923).
- Attach 3-4 of the owner's existing icons as the STYLE LOCK (carry them with
  `http://127.0.0.1:18923/tools/chatgpt/carry.html?f=art/icons/a.png,art/icons/b.png&w=512`, then the two javascript
  calls of `chatgpt-review` steps 3-4). Pick icons of the same family as the new ones (rewards icons for reward art).
- One message, one paragraph, English, asking for up to THREE images (ChatGPT returns at most a few per reply):
  - "match their exact style (chunky cartoon shapes, soft gradients, dark outline, small white shine, warm saturated
    colours, readable on a phone at 64 px)";
  - "each image on a completely flat pure magenta #FF00FF background, no shadow on the background, every item clearly
    separated with wide magenta gaps, no text, letters or numbers anywhere";
  - name the layout: "a 4 x 3 grid of 12 square icons: <icon 1>, <icon 2>, ..." in reading order, one concrete noun
    phrase each (what it is + one telling detail: "a heavy steel vault door with gold coins spilling");
  - UI parts as separate pieces side by side ("a prize wheel split into 9 equal empty slices, a pointer, a hub").
- Thinking effort "High" (check the composer's chip), send, check `POST .../f/conversation -> 200`.
- Wait 3-5 minutes doing other work; the reply is done when `document.body.innerText` contains "Response complete".

## 2. Bring the pictures back (no owner needed)

On the chat page, javascript: every `img` with `naturalWidth > 500`, unique by `src` (each appears twice), drawn to a
canvas and turned to `toDataURL('image/webp', 0.95)`; then navigate to
`http://127.0.0.1:18923/tools/chatgpt/receive.html#back=<encoded chat url>&files=<name>|<base64>~...` (keep under
~1.8 MB). `serve.py` writes them to `art/inbox/` and the tab returns to the chat. Read each file to look at it.

## 3. Cut, key, size

- One picture per item already: `python tools/chatgpt/prepare_icons.py <name> ...` (keys out magenta with a soft edge
  and no pink fringe, trims, pads, 256 px) -> `art/icons/<name>.png`.
- A grid sheet: crop each cell first, then key. The script used for the wheel (keep it as the pattern):
  import `key_out` from `tools/chatgpt/prepare_icons.py`, crop cell `(c*w/cols, r*h/rows, ...)`, `key_out`, trim to
  alpha > 16, pad, resize to 256 (1024 for a big UI piece such as the wheel face). Names in the order you asked.
- Look at a few results (a big one and one whose box touched the cell edge) before uploading.

## 4. Upload and name

- Studio's MCP `upload_image` with `http://127.0.0.1:18923/art/icons/<name>.png` URLs, any open Studio (`list_roblox_studios`);
  it returns `rbxassetid://` ids on the owner's account in one call for the whole batch.
- Put the ids in `Config.Ui.Icons` (one name each), commit the PNGs in `art/icons/`.
- A picture drawn by a Roblox font glyph is fine where Roblox itself draws it: the Robux symbol is `utf8.char(0xE002)`.

## What went wrong before

- A wide contact sheet sent TO ChatGPT for review: it saw only one tile. Send pictures separately.
- Thumbnails load lazily: scroll every reply image into view before the canvas export, or one is missing.
- A pie of N slices: count them on the picture before placing icons (slice 1 centred at 12 o'clock, clockwise).
