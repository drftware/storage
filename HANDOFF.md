# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-17, session 243 (four make a Gold, on the server, D-298) ·
**Checks:** green · **Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage);
Brix pinned at `482368f`, NOT on Brix's `origin` yet.

## State
- The home (D-259; the Claude Doc https://claude.ai/artifact/EUdGarQ2sEiUC6BU5E7Tww, docs tools
  only) is built a ROADMAP piece a session (S5-03): ground floor, fronts, starter sets, switch,
  a home each, hard hat, mirror, oak shelf with finds, job box, its panel, taking out, selling,
  and now a Gold made on the server (S5-03c3b1, D-298). S5-03c3b was split: b1 done, b2 the big
  animation, b3 a Gold on the shelf and in your hand.
- A Gold is a name of its own in `finds` ("Teddy:Gold", `src/shared/Home/Gold.luau`): no new save
  version. `BoxPanel.gold` strikes four in the box (cracked first) and adds one, stamping its book
  page; `JobBoxes` runs it as `JobBoxTake`'s fourth way (`Ways.Gold`), written as a sale is. A Gold
  sells at five times (`price(row, true)`); Take and Shelf are hidden on its card and refused.
  Its card sits just before its find's (`cards`), its picture gilded by ToolPicture (gold Metal,
  textures off: judge it in Play). The client ignores `JobBoxTook` answers for Gold until b2.
  Passes checks, untested in Studio.
- Studio: `ServerStorage.ShelfTest:Invoke(player, key)` keeps a find (call it four times for
  four); the box opens from a Client `prompt:InputHoldBegin()` on `Unit1`'s `JobBoxButton` with
  the camera on it. Buttons are clicked with `user_mouse_input`'s `instance_path`; card frames
  are named by key, and a Gold's key has no dot, so "Finds.Teddy:Gold.Verbs.Sell" works.
- Stage only your own paths: the find run shares this checkout.
- Find art: S1a (6e3518d) built the goo ball's art and row (neon pink, oozes out between five fingers on
  bones), not ticked or imported; next S1b (`art/finds/WAVES.md`): judge, tick, import, Play.

## Next task: S5-03c3b2 Four make a Gold, the big animation, seen
The moment: four Teddies in the box; tap the card and a Gold button glows over Sell; press it and
the four pictures fly out round the screen's middle, swirl inward faster with a rising shimmer,
flash white-gold, and one big gold Teddy lands with its own sound, then deals onto its new card.
1. Verbs: a third row over Sell, Gold (gold fill, a slow shine), shown when `BoxPanel.offers`.
2. Ask `JobBoxTake` (name, "Gold"); let `took` take way Gold (remove the ignore in the
   `TookRemote` handler); on ok `BoxPanel.made` on `all`, re-set every frame's LayoutOrder, make
   the new card (`makeCard`, gold rim) or bump its badge; refused or no answer: the four go home.
3. The show, feel numbers in `Home/Gold`: veil over the panel swallowing taps; four copies
   spread with rising chinks (0.5 s); orbit inward, faster (1.4 s); flash, ring, sparks, the Gold
   popping big at the middle with turning rays and its name; hold 0.9 s; fly to its card.
   Sounds: the reveal's Legendary set in `Boxes.Reveal` (rattle, rise, falling twinkles) plus
   the coins' jingle, measured in STUDIO.md "The reveal's sounds".
4. Studio Play with real clicks at phone size; capture `docs/art/S5-03c3b2-*.jpg`.
**Acceptance:** check green; the Gold button only on four or more; the show at phone size, the
new card beside the old; a refused ask settles back; seen in Studio Play, Output clean.
**Read first:** ROADMAP S5-03c3b2; D-298; `src/shared/Home/Gold.luau`; `src/shared/Home/BoxPanel.luau`
(`offers`, `made`); `src/client/BoxPanelView.luau` (`pick`, `paintVerbs`, `took`, `takeOut`, `fly`,
the verbs in `start`); `src/shared/Boxes/init.luau` (`Reveal`).

## Queue (next sessions, the owner's ticket order)
1. S5-03c3b3 a Gold on the shelf and in your hand; S5-03c3a2 a cracked find sells first at half, one off `chipped` (small; F-G1e5e is in); S5-03d-h;
   S5-03a2d the cars' hidden triangles; F-G1b4a2 the headlamp's beam (ROADMAP Step 4);
   F-G1b4b the hat spent. S5-03d builds on D-293: a box find is never kept at a gate yet.
2. The home's warm fill (D-290): faces turned from the bulb go near black (D-263: warm all round).
3. F-G1b5 waits for its art. Brix: ENG-25b's two-client run; Driving's stick read needs
   `PlayerModule`, fall back to the camera-turned `MoveDirection` (D-254), built in `../engine`.
4. S4-02 monsters by lowest floor, S4-03 the elevator's choice, S4-04 trapping pays, S4-05.
5. The item catalog doc and the design doc's finds section need D-250, D-251, D-259, D-277, D-297.
6. Once the owner's real purchase passes: mark Brix's ENG-23e done in `../engine`'s HANDOFF.
7. Late arrivals off `ClimbEnd.spot`; the driving torch (D-257); asset 203785492's type error;
   the front office's steel; cart seats vs `Seat:Sit`; a spare home unpadlocked (D-275); the
   hat's first-Wear dark screen; the body unhidden after a respawn (D-282).

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
