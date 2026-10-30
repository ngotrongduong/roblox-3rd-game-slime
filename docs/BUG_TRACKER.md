# Gameplay and visual issues (owner reports)

This file tracks reproducible defects and player-experience improvements. Changes are made on feature branches, never directly on `main`. **Implemented** means committed, not verified in Roblox Studio.

| ID | Owner report (2026-10-30) | Root cause | Change | Status |
|---|---|---|---|---|
| UX-001 | Upgrades pop in too quickly; players cannot tell what changed or feel rewarded. | `AreaUpgrade.server.luau` immediately rebuilt/destroyed stage models; the only effect was a brief burst beside the upgrade pad. | `UpgradeReveal` tags changed models/pieces, clients reveal them in waves with a gold outline, sparkles and an area/level announcement at the **actual construction site**; era-start levels use a bigger flourish. A level loaded from saved data never plays it. | Implemented on `chatgpt/garden-upgrade-reveal`; Studio QA pending |
| GAME-002 | One gardener works a single bed repeatedly while most of the 20 plots are empty. | `GardenPlots.choose` prioritized thirsty stage-2/3 crops ahead of all unsown beds. | Prioritize harvest, finish hoe/plant/water on each new bed, **then** maintain older plants at stages 2/3. Keep the same worker shift speed, one chore at a time, server-side saved crop states. Add coverage tests for multiple beds and one-worker simulation. | Implemented on `chatgpt/garden-upgrade-reveal`; Lune/Studio QA pending |

| GAME-003 | Max-level village capacity is 216 slimes but production slots stop at four per area; food may run short even below max, while a kitchen can hoard raw ingredients for dishes nobody can eat. | Population cap grew by four every level, independent of production milestones; hunger was 2/min idle and 3/min working; cooking ignored opt-in demand. | Whole-slot cap grows from 12 to **70**, hunger is 1.25/min idle and 1.9/min working, fish cycle 50s, garden actions 12.5s. A staffed kitchen prepares at most two outstanding dishes per opted-in eater and no ingredients when none opted in. Existing over-cap saves are never trimmed. | Implemented on `chatgpt/food-economy-balance`; run Lune/Studio validation |

## Studio acceptance checks

1. In MapWork sync the feature branch and play at the normal gameplay camera. Step on upgrade pads for garden, pond, pantry, kitchen, breeding, training: confirm each upgrade announces its area/level at the **changed objects** and builds visually in staggered waves; inspect the 11/21/31/41 milestone upgrades, where the reveal should be stronger.
2. Verify scenery collisions and the level/save state change immediately and correctly even while local visual effects are running. Verify normal loading of a previously saved upgraded area produces **no** celebration.
3. Upgrade quickly twice, and move far away then return. Effects must expire, not accumulate or replay after streaming. Check weak-device FPS with the particle burst and marked-piece limit.
4. Assign one slime to the garden. Leave it working for 5–10 minutes: it should hoe/plant/water on **multiple** different beds; save/reconnect, verify occupied beds and growth stages are preserved. Verify 2–4 assigned slime workers reserve different beds; no double-harvest and no vegetables lost when the ten-item bin fills.
5. Run a food stress test with SPD-1 producers and a full population at village levels 10, 20, 30, 40 and 50. Measure actual fish/vegetables delivered, hunger, travel delays and idle couriers for at least two hours. Check a kitchen with zero and with one opted-in eater; neither may drain raw food without purpose. Check that an old over-cap profile still keeps every slime but cannot breed until below its current capacity.
6. Run `tools/check.ps1` and `tools/types.ps1` locally; only mark complete after **CHECK OK**, **TYPES OK**, and the Studio checks pass.

## Future refinement

- On low-end devices, adjust `Config.UpgradeFx.MaxChangedParts`, `SparkleCount` and the reveal timings; never make physical gameplay wait on cosmetics.
- If the pond's land-shaping needs its own visual rise, animate the *client-only water/shore reveal* separately from server terrain changes. Do not hide or move collision geometry on the server to create an effect.
