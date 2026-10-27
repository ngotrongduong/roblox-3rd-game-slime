---
name: store-page
description: Make or update Goo Lineage V2's page on Roblox - title, description, icon, thumbnails, genre, the content questionnaire, audience reach. Use before the first publish to the public, for every content update, and when the owner asks why few people play.
---

# The game's page

Adapted from the owner's previous games (Tile Smash, Egg Heist). The page is what a player sees before deciding to
click: the icon in a grid of other icons, then the thumbnails and the first two lines of the description.

## Title

The title is exactly "Goo Lineage V2" (the owner's name for the game). Search words may follow it after a colon only if
the owner agrees ("Goo Lineage V2: Slime Farm"); update tags go in front in brackets for a week at most (`[NEW]`).

## Icon and thumbnails

- Made from the owner's art and ChatGPT pictures in the locked style (`art-pipeline`): one clear subject, a slime face
  with an expression, high contrast, readable at 150 px. Text is added afterwards, never baked in by the image AI.
- Three thumbnails, each one promise of the game: breeding and the reveal, the cozy farm, the Wild Garden fights.
- Icon 512 x 512, thumbnails 1920 x 1080; JPEG around 400 KB uploads reliably, large PNGs have hung.
- Upload on the Creator Hub (Claude in Chrome, signed in to the account that owns the game): the place's Icon page, and
  the Thumbnails page's **Experience Detail Page** tab (in Egg Heist only the Home Page set had pictures and the public
  page showed a grey placeholder). The page has one hidden `input[type=file]`: stub `HTMLInputElement.prototype.click`
  for file inputs, press "Upload thumbnail", then `file_upload` into that input; one picture at a time; the newest lands
  on top, drag to reorder, Save Changes.

## Description

English, with a Vietnamese translation beside it in `store/description.txt` for the owner. First line: what you do, in
one sentence a nine-year-old gets. Then short lines for the features, the update, and how to follow the game. No promise
the game does not keep, nothing about Robux giveaways. At most 1,000 characters.

## Settings the owner must know about

- Genre can only be changed once every three months: confirm with the owner before saving it.
- The content questionnaire decides the age label: answer what the game truly contains (cartoon slime fights; no blood;
  paid random items only if one is sold).
- Audience reach: a new public game is shown to ages 16+ only until it has 250 highly engaged players, or the owner pays a
  refundable fee (Egg Heist, 2026-10-18). That is the first answer when the owner asks why few people play; growth then
  comes from the owner's own shares and ads.
- Making the game public, paying any fee, and anything under account or security settings are the owner's own clicks.

## After an update

A new first thumbnail or icon only when the update changes what the game promises. Note in the project memory what is
live on the page and when it changed. Creator Hub analytics (under `/dashboard/creations/experiences/<universe>/`:
`analytics/engagement`, `acquisition`, `audience`, `retention`, `economy`, `funnels`, `errors`) tell how long new players
stay: in Egg Heist they left after 1.6 minutes, before anything happened to them.
