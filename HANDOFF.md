# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-17, session 245 (a Gold on the shelf and in your hand, D-300) ·
**Checks:** green in the shared checkout at commit time (the find run's uncommitted files
included) · **Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage);
Brix pinned at `482368f`, NOT on Brix's `origin` yet.

## State
- The home (D-259; the Claude Doc https://claude.ai/artifact/EUdGarQ2sEiUC6BU5E7Tww, docs tools
  only) is built a ROADMAP piece a session (S5-03): ground floor, fronts, starter sets, switch,
  a home each, hard hat, mirror, oak shelf with finds, job box, its panel, taking out, selling,
  four make a Gold with its show, and now a Gold out to the hand and the shelf (S5-03c3b3).
- A Gold in your slots keeps its find's key ("Teddy") with a gold mark (`Gold.slotAttribute(i)`
  on the player, `gold` on Slots' carried thing), so every row, model, sound and verb is the
  find's; it's gilded (`Gold.gild`, shared) by the server for everyone and by your view, wheel,
  panel hands and the shelf. Counted and kept by its Gold name (`named` in Slots). D-300.
- Verified in Studio Play with real clicks: a Gold card shows Sell, Take and Shelf; Take flew it
  to the first hand well, gilded; held, it's solid gold under the bulb (view copy and the
  server's `HeldTool` both gold Metal); Shelf stood it in cubby 1 gold (checked on the server).
  Output clean. Captures `docs/art/S5-03c3b3-{card,well,hand}.jpg`. The shelf's cubby never came
  clear in a capture: OWNER.md asks the owner to judge it.
- Studio: the MCP resets a Scriptable camera after each `execute_luau`; aim by moving the
  character (STUDIO.md "Aiming a capture in Play"). Scroll the panel's `Finds` before clicking a
  card's verb. The test save: Gold Teddies (one on the shelf's cubby 1), no plain Teddy.
- Stage only your own paths: the find run shares this checkout.
- Find art: S1 the goo ball is done (S1b: wet glossy skin, imported, seen in Play: dealt, taken,
  squeezed, its squelch). Next S2, the colour-change goo ball (`art/finds/WAVES.md`'s Next line,
  `art/finds/PIPELINE.md`).

## Next task: S5-03c3a2 Selling a cracked find
The moment: you sell a lamp whose glass cracked on the climb, and it goes for half, the price on
Sell saying so before you press it; the whole ones keep their full price.
1. Pure, test first (`tests/boxpanel.spec.luau`): `BoxPanel.sell` sells a cracked one first when
   `chipped[name] > 0`: priced at `Chip.worth(price, true)`, `chipped` down by one, so `chipped`
   never tops `finds` (as `BoxPanel.gold` does it).
2. Server: `JobBoxes`' Sell path prices by that rule and answers the new cash.
3. The panel: the list sent as the lid opens carries how many of each are cracked; Sell on a
   card shows the cracked price while a cracked one is next, the whole price after.
4. Studio Play: crack a fragile find (or set `chipped` from a Studio-only hook), sell it, see half;
   capture `docs/art/S5-03c3a2-*.jpg`.
**Acceptance:** check green; a cracked one sells first at half and the card says so; seen in
Studio Play, Output clean.
**Read first:** ROADMAP S5-03c3a2; D-296, D-297; `src/shared/Home/BoxPanel.luau` (`sell`, `gold`);
`src/shared/Finds/Chip.luau` (`worth`); `src/server/JobBoxes.luau` (the Sell path);
`src/client/BoxPanelView.luau` (Sell's price, `paintVerbs`).

## Queue (next sessions, the owner's ticket order)
1. S5-03d-h; S5-03a2d the cars' hidden triangles; F-G1b4a2 the headlamp's beam (ROADMAP Step 4);
   F-G1b4b the hat spent. S5-03d builds on D-293: a box find is never kept at a gate yet (a Gold
   would be kept as a Gold already, D-300).
2. The home's warm fill (D-290): faces turned from the bulb go near black (D-263: warm all round).
3. F-G1b5 waits for its art. Brix: ENG-25b's two-client run; Driving's stick read needs
   `PlayerModule`, fall back to the camera-turned `MoveDirection` (D-254), built in `../engine`.
4. S4-02 monsters by lowest floor, S4-03 the elevator's choice, S4-04 trapping pays, S4-05.
5. The item catalog doc and the design doc's finds section need D-250, D-251, D-259, D-277, D-297,
   D-299, D-300.
6. Once the owner's real purchase passes: mark Brix's ENG-23e done in `../engine`'s HANDOFF.
7. Late arrivals off `ClimbEnd.spot`; the driving torch (D-257); asset 203785492's type error;
   the front office's steel; cart seats vs `Seat:Sit`; a spare home unpadlocked (D-275); the
   hat's first-Wear dark screen; the body unhidden after a respawn (D-282); a Gold's own
   textures and the Packrat wanting a Gold most (ROADMAP's polish for Golds).

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
