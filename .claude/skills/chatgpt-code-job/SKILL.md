---
name: chatgpt-code-job
description: Hand a code job to ChatGPT through GitHub and take the result back - write the brief, send it in the browser pane with the GitHub connector, wait, fetch the branch, run the gates, send failures back, squash-merge. Use for a feature with a clear brief that does not need eyes on the world, to spare Claude's tokens.
---

# A code job for ChatGPT

Repo `ngotrongduong/roblox-3rd-game-slime`, base `main`. Use for logic, server and client code with a clear spec. Positions, looks and
feel need someone who can run Studio: use a Studio agent for those.

## 1. The brief
Write `docs/briefs/<name>.md` and push it: "Claude has full decision authority; never ask the user", the branch `chatgpt/<name>` from the
latest main (never main, no PR), what to read (`CLAUDE.md`, `docs/GAMEPLAY.md`, `docs/LESSONS-village.md`, named files), the owner's words, the
exact list to build, the Lune tests, the gates, files not to touch, the slips below, the report wanted.

Slips to list: no unused variables, imports or parameters (selene; `_` prefix); typed fields added later go in the type, `newFarm` and
`repair`; attribute reads are `any`; no require cycles; tests use the seeded `Rng` and fixed times, never `os.time()`; start new services
from `Main`; a config block's keys must exist in the block the module reads (`Config.Slime` vs `Config.VillageClient`).

## 2. Send it
Browser pane (`mcp__Claude_Browser__*`), tab at chatgpt.com. New chat: click "+" (about 76, 279), `find` "GitHub Triage", click it so the GitHub
chip shows; check the effort reads High. Type ONE paragraph (a newline sends), Return:
"You are a senior Roblox Luau engineer working for Claude, the orchestrator of this project, who has full decision authority: never ask the
user anything and work until the task is done. Use your GitHub connector on the repository ngotrongduong/roblox-3rd-game-slime (base branch
main). Read the brief docs/briefs/<name>.md on main and do exactly that job: ... create the branch chatgpt/<name> from the latest main ...
When done, reply with the report the brief asks for."

## 3. Wait and read
A job takes 20-40 min: a background `Start-Sleep`, never polling loops. A tab may show stale text: reload the chat URL, wait 4 s, read
`document.querySelector('main').innerText.slice(-3000)`; "Skip" in the text means still working. Check `git log origin/chatgpt/<name>`: a commit
under a few minutes old means it is still pushing.

## 4. Take it back
`git fetch`, check out the branch locally, `git merge main` (or a worktree when someone is editing the main checkout; copy
`tools/types/globalTypes.d.luau` there), run `tools/check.ps1` and `tools/types.ps1`.
- A few slips: fix them. Many: paste the exact failures into the same chat and ask it to merge main and fix them.
- Squash-merge into main with a message saying what it is, push, delete the local branch.
- Then `village-playtest`: passing the gates is not proof.
