---
name: robux-products
description: Create or change what Goo Lineage V2 sells for Robux - game passes and developer products on the Creator Hub, their ids and prices in the game, their pictures, the receipt code - and the rules that keep money safe. Use when the owner asks for monetisation, when a product is added or repriced, or when a product still has an id of 0.
---

# Passes and products

Adapted from the owner's previous games (Tile Smash, Egg Heist), where the owner's goal was Robux and these rules were
set and proved. In THIS game `docs/DESIGN.md` §2 decides the frame: Robux comes late (Phase 7, Launch), as passes and
products that are **never pay-to-win against the grind the owner wants** (rare drops, big difficulty steps, expensive
cosmetics), and the list is decided WITH the owner at that phase. Until then nothing is sold.

## Rules that do not bend

- The owner approves the list and the prices before anything is created, and is told what was created. An approval is
  for that batch only: new products or changed prices are asked again.
- Never press Buy, not even to test: the owner makes every test purchase. Never agree to terms on the owner's behalf: a
  dialog that asks to accept something is cancelled and reported. Never pay a fee.
- "Managed pricing" (regional pricing) stays **off** unless the owner turns it on: new forms have it ON by default, and
  switching it on asks to accept terms.
- Everything sold is listed in one catalog table in `src/shared` with its id; an id of 0 means "does not exist on Roblox
  yet" and the shop shows it as SOON and cannot be pressed.
- What Robux buys travels on its receipt: `ProcessReceipt` grants through `PlayerData` and returns `PurchaseGranted`
  only after the grant is saved; a receipt id already granted is never granted twice (two servers may both see it).
  Nothing is sold before the player's save has loaded.
- A price shown in the game is the price in the catalog; a discount label is computed from real prices of things sold
  separately, or not shown.
- Paid random items: the odds are shown before buying, and the product is hidden from players whose `PolicyService`
  says paid random items are not allowed.
- Names on the Creator Hub: no digits ("1500 Coins" is filtered to "#####"); short and plain.
- The `reviewer` agent reads anything that touches receipts, `PlayerData` or a shop remote before it is published.

## Creating them

On the Creator Hub of the experience, through Claude in Chrome, whose profile must be signed in to the account that
owns the game (look at the creator name in the corner first; the owner has more than one Roblox account).

- Pass: `.../passes/create` (upload the picture FIRST: it pre-fills the name with the file name and resets typed
  fields), then `.../passes/<id>/sales` ("Item for sale" on, the price, Managed pricing off, Save), `.../passes/<id>/configure`
  to rename.
- Developer product: the "Create developer product" link of `.../monetization/developer-products` (the URL
  `.../developer-products/create` works; `/monetization/developer-products/create` was a 404), name, description, price,
  its second switch is Managed pricing (switch it OFF), Save. `.../developer-products/<id>/configure` to edit.
- When the Chrome tab is in the background, typed text does not land: set values by script (the native input value
  setter, then `input` / `change` / `blur` events), switch toggles and press Save with `element.click()`, then read the
  list page back for the ids. One product at a time, and check the list afterwards.
- Pictures: 512 x 512, from the owner's art or a ChatGPT picture (`art-pipeline`).

## After

1. Put every id into the catalog, run `check.ps1`.
2. In Studio, a test switch in `Config` hands out a product through the same function as a real receipt (the log must
   show the grant); the switch goes back to off before anything is committed.
3. Tell the owner, in Vietnamese, which purchases to try for real (one cheap product, one pass) and what they should see.

## Ads (for later)

Rewarded video ads were added in the owner's previous game. For ads to show at all Roblox requires: the owner ID-verified
with 2-step verification, 2,000 monthly visitors, the maturity questionnaire, Rewarded Video "Serving" on in the Creator
Hub; only players 13+ see them. These are the owner's own account settings: Claude never changes them.
