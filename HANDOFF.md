# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-17, session 261 (S5-03f4b2, the counter's mirror seen, D-320) ·
**Checks:** green in the shared checkout · **Git:** `main`, committed, not pushed (`origin` is
github.com/drftware/storage); Brix pinned at `7f25310`, NOT on Brix's `origin` yet.

## State
- The home (D-259; the Claude Doc https://claude.ai/artifact/EUdGarQ2sEiUC6BU5E7Tww, docs tools
  only) is built a ROADMAP piece a session (S5-03), up to f4b2: the counter's mirror, seen.
- Seen in Play on the A16 (D-320, `docs/art/S5-03f4b-*.jpg`): the mirror by the counter, you in
  it, its picture whole; the cards' Try on pills; Pink tried on from the shop, the shop sliding
  away, you wound in pink in the glass, the peel. Two faults fixed in code: MirrorView copied your
  body again for every sound (a black slab in the glass at the peel; now `looksChange` and a
  copy posed before it's shown), and from the counter you stood off the glass's edge (the mirror
  moved to the button's x 49.6, `Shop.Mirror`; the cards' Try on only in line, `TryOn.inLine`).
- Studio (Rojo still unconnected) holds ae5b614's code, patched by hand, plus MirrorView's fix;
  NOT the in-line fix (Shop, TryOn, ShopView, TryOns). The doubled Shop, Mirror, Home are single
  now. Studio's TryOn, TryOns and TryOnView are comment-stripped copies (hunks won't anchor).
- The test save: one HardHat (on the rail), cash 478. Device Simulator: Galaxy A16, landscape.
  `screen_capture` timed out all session: capture Studio's window from macOS (STUDIO.md).
- Stage only your own paths; the find run commits its own `art/finds/`, `src/shared/Finds/`,
  `tests/stuffdeal.spec.luau`, and may have hunks in `docs/`: stage yours as a blob then.

## Next task: S5-03f4b3 The counter's mirror, in line, seen
The moment: at the counter you open the shop facing it, tap Pink's figure, and your view swings
to the mirror beside you with you in the middle of the glass, wound in Pink; no flash as it peels.
1. Patch Studio from Edit (STUDIO.md "Patching Studio by hand, cheaply"): Shop and TryOn as NEW
   ModuleScripts (old one's Source plus hunks for Shop; TryOn sent whole, comment-stripped),
   ShopView (both copies) and TryOns by hunks or whole. `git diff ae5b614 HEAD -- src/`.
2. Play; from a Client `execute_luau` stand at (49.6, 3, 452.4) facing the counter (+x). Tap the
   HUD Shop button (its AbsolutePosition X + 47, Y), then Pink's figure the same way, with a
   background `screencapture` loop running (every 0.25 s; window number from Swift).
3. Look for: you centred in the glass, wound in pink; no black slab through the peel; the glass
   not going dark as it swings on screen (seen once in S5-03f4b2: if it does, find why in
   MirrorView's `pick`, a `PixelsPerStud` change or the still picture, and fix). Stand 3 studs to
   one side: no pills.
4. Capture to `docs/art/S5-03f4b3-*.jpg`. Then start S5-03g1 (ROADMAP): the art first.
**Acceptance:** check green; seen in Play with pictures, or exact steps in OWNER.md.
**Read first:** ROADMAP S5-03f4b3, S5-03g; D-320; STUDIO.md "Patching Studio by hand, cheaply",
"When `screen_capture` times out"; `src/client/MirrorView.luau` (`pick`, `addBody`).

## Queue (next sessions, the owner's ticket order)
1. S5-03g (split: g1 art first, g2 paint and floors, g3 doors and name cards, g4 furniture), h;
   S5-03d4 across the trip (unblocked); S5-03a2d the cars' hidden triangles; F-G1b4a2 the
   headlamp's beam (ROADMAP Step 4); F-G1b4b the hat spent.
2. The home's warm fill (D-290): faces turned from the bulb go near black (D-263: warm all round).
3. F-G1b5 waits for its art. Brix: ENG-25b's two-client run; Driving's stick read needs
   `PlayerModule`, fall back to the camera-turned `MoveDirection` (D-254), built in `../engine`.
   A PlayerSaves hook that runs before a leaving save's last write would replace `leaving`.
4. S4-02 monsters by lowest floor, S4-03 the elevator's choice, S4-04 trapping pays, S4-05.
5. The item catalog doc and the design doc's finds section need D-250, D-251, D-259, D-277, D-297,
   D-299, D-300, D-301, D-302, D-304, D-305, D-308 (the spot column), D-309, D-311 to D-320.
6. Once the owner's real purchase passes: mark Brix's ENG-23e done in `../engine`'s HANDOFF.
7. Late arrivals off `ClimbEnd.spot`; the driving torch (D-257); asset 203785492's type error;
   the front office's steel; cart seats vs `Seat:Sit`; a spare home unpadlocked (D-275); the
   hat's first-Wear dark screen; the body unhidden after a respawn (D-282); a Gold's own
   textures and the Packrat wanting a Gold most; a crack drawn on a cracked card (ROADMAP polish).
8. `CaughtSeized` is set by CaughtLunge and ArrangeView and read by FlashlightView, each with its
   own string: share one constant (a "camera held" attribute) when next in those files.
9. S5-03d4's climb server must restamp the lights it receives (`Use.leave`), as Climbs does.
10. The catch's film now comes from `Film.make`: watch a catch in Play once Rojo is connected.
11. The HUD coin count read 0 in Play with the save's cash at 478: check it counts up.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
