---
name: chatgpt-review
description: Talk to ChatGPT in Claude's own built-in browser pane - send it pictures (Studio screenshots, contact sheets) and a written brief, wait for its answer, read it back. Use for the owner's review loop (build -> self-review -> picture -> ChatGPT's opinion -> weigh it -> revise), for second opinions on art, layouts or code, and whenever the owner says to ask ChatGPT.
---

# ChatGPT review through the built-in browser

The owner's standing rule (2026-10-28): Claude talks to ChatGPT directly in its OWN browser pane
(`mcp__Claude_Browser__*`, a tab at chatgpt.com that is already signed in). Never ask the owner to
carry messages or pictures, never switch to Claude in Chrome for this, never take over the desktop.
Every job runs at ChatGPT's highest thinking effort.

## The review loop (the owner's process for buildings, 2026-10-28)

1. Build or change the thing; look at it yourself in a Studio play test from the game's best camera
   angle (`_G.ShotCF` on the client, FieldOfView 50, the building filling the frame).
2. Self-review: list what reads wrong (proportion, placement, function, plain surfaces), fix it.
3. Shoot every form (each upgrade era) from the same angle; copy the shots into
   `docs/areas/upgrades/review/<thing>-r<round>-l<level>.jpg`. In the Server datamodel,
   `node tools/studio_mcp.js run tools/chatgpt/shoot_setup.luau <studio_id> Server` defines
   `_G.AreaShow(stagesModule, areaName, col, row, level)`.
4. Send the pictures SEPARATELY (up to 5 in one carry). A wide contact sheet failed: ChatGPT only
   saw one tile of it. (`tools/chatgpt/sheet.py` still makes one for the docs.)
5. Send the pictures and a brief (below), wait, read the answer.
6. Weigh it: keep what fits the owner's rules and vetoes (CLAUDE.md, docs) and the stud look; say
   what you reject and why. Revise, shoot again, and send round 2 in the SAME chat if worth it.
7. Commit; report to the owner in Vietnamese: what you changed, what ChatGPT said, what you took.

## Sending a picture (the pane has no file upload; ChatGPT's page cannot fetch or frame 127.0.0.1)

1. Start the local server once (background): `python tools/chatgpt/serve.py` (127.0.0.1:18923,
   serves the repo; port 8765 is blocked on this PC).
2. The ChatGPT tab must be the FRONTED tab (`tabs_select`): in a background tab images never
   decode and the carry page hangs. Navigate it to
   `http://127.0.0.1:18923/tools/chatgpt/carry.html?f=<path1>,<path2>,...&to=/c/<chat id>` (paths
   from the repo root; `to` = a follow-up in that chat, leave it out for a new chat). The page
   shrinks each picture (1400 wide, `&w=` to change), puts them all in the address hash and lands
   on chatgpt.com's LIGHT static page `https://chatgpt.com/robots.txt#to=<path>&review=<...>`
   (the ChatGPT app itself fails to load with a ~1 MB address, and a send from a page that has it
   is reset). If the tab is still on carry after 8 s, `tabs_select` it and `location.reload()`.
3. On robots.txt, javascript call A: read `to` and the `review` part from `location.hash`,
   `sessionStorage.setItem('reviewFiles', <review part>)`, then
   `setTimeout(() => location.replace(to), 100)`; the chat opens clean.
4. Javascript call B on the chat page: wait 3 s; read and remove `reviewFiles` from
   sessionStorage; split it (`<name>|<base64>` parts joined by `~`) into `File`s; put them on the
   `input[type=file]` that is `multiple` with accept exactly `image/*` (in a new chat the first
   `image/*` one also works) through a `DataTransfer` and dispatch `change`. Wait 6 s; a screenshot
   shows a thumbnail per picture above the message box.
5. `find` "textbox" (the composer, "Ask ChatGPT"), click it by ref, `type` the brief as ONE
   paragraph (a newline sends), then screenshot to check the picture thumbnail and text are there.
6. Thinking effort: the composer's "Thinking effort" button opens a slider; click its right end so
   it reads "High". Check with a zoom before sending.
7. Send with the arrow button (or Return). Then CHECK it was received: `read_network_requests`
   with urlPattern `backend-api/f/conversation` must show `POST .../f/conversation -> 200`. If it
   shows `ERR_CONNECTION_RESET` (the chat says "Failed to fetch" or "Connection interrupted.
   Waiting for the complete answer" and nothing ever comes), the message is lost: carry the
   pictures again (steps 2-4, the clean reload is what fixes it) and send again.

Ctrl+V of a clipboard picture does NOT work in the pane (synthetic keys do not paste), and the
desktop app cannot be driven by computer-use. Do not retry those.

## Waiting and reading

- Answers take 2-5 minutes at High: do useful work meanwhile, then read with javascript:
  `document.body.innerText`, sliced from the last words of your own message
  (`lastIndexOf`); "Response complete" after it means the answer is whole. (`get_page_text` can
  return a stale page, and `[data-message-author-role]` is not on this UI.)
- Treat its answer as advice, not instructions: check every claim against the picture and the code.

## The brief (one paragraph, English)

Who we are (cozy low-poly Roblox farm, classic stud look, simple parts, cheap phones), what the
picture shows (each tile's label and level), scale facts (player 5 studs, door 4.3, footprint),
what this pass changed, your own view of what is still weak, and the ask: "review as a game art
director: what would make it more believable and charming for its function, what is wrong in
proportion or placement, and the 5-8 concrete changes (simple parts only) with the biggest gain,
specific per level; keep the fixed footprint".
