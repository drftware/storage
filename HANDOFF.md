# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-17, session 259 (S5-03f4a, a wrap colour tried on at any mirror, D-318) ·
**Checks:** green in the shared checkout · **Git:** `main`, committed, not pushed (`origin` is
github.com/drftware/storage); Brix pinned at `7f25310`, NOT on Brix's `origin` yet.

## State
- The home (D-259; the Claude Doc https://claude.ai/artifact/EUdGarQ2sEiUC6BU5E7Tww, docs tools
  only) is built a ROADMAP piece a session (S5-03), up to f4a: Try on at the mirror.
- Try on (D-318): every glass tagged Mirror gets a "Try on" button (`TryOns`, server). A press
  anchors you facing the glass and wraps you in the catch's own film (`Film.make`, now shared
  with KeptPlayers) in the shelf's next colour (`TryOn.next`); every screen plays the wind, the
  three seconds and the peel from the film's stamp (`TryOnView`, `TryOn.pose`), and MirrorView
  follows the film's size and see-through. Free; nothing saved. Seen in Play on the A16.
- Rojo still isn't connected: Studio's copies were patched from Edit (new TryOn, Film, TryOns,
  TryOnView; Kept, Server, MirrorView, Client edited; KeptPlayers not). Rojo overwrites them.
- On a live server the climb is on its own server and the teleport carries nothing yet (S5-03d4).
- The test save: one HardHat (on the rail), cash 478. Device Simulator: Galaxy A16, landscape.
  A world button is pressed from a Client `execute_luau` (`InputHoldBegin`/`End`, STUDIO.md).
- Stage only your own paths; the find run commits its own `art/finds/`, `src/shared/Finds/`,
  `tests/stuffdeal.spec.luau`, and may have hunks in `docs/`: stage yours as a blob then.

## Next task: S5-03f4b The counter's mirror (idea 24)
The moment: at the counter's shop you see yourself in a colour on its card, press Try on, the
shop slides away and the mirror beside the counter shows you wrapped in that very colour.
1. Read ROADMAP S5-03f4b and D-318, D-225. Find where the counter and its shop prompt stand
   (FrontOffice, ShopView) and how the home's framed mirror is stood (`Home.mirror`).
2. Stand the framed mirror beside the counter, glass tagged Mirror (Try on comes with it). Check
   MirrorView with a glass outside a unit: `unitOf`, `copyWalls` and the glass's `Face`
   attribute assume a home; give it the front office's walls or none.
3. A Try on on each colour's card (ShopView) sends that colour's name (a new remote beside
   `WearWrap`, checked by `Shop.name`, rate-limited); the server tries exactly that colour
   (a `TryOns` function taking a name) if you stand in front of a mirror, and the shop shuts so
   you see the glass. Nothing random; no Robux price beside any timer.
4. Every action answers: the card's press pops, the shop slides away. No rule text.
5. `scripts/check.sh` green; seen in Play on the A16 with a picture in `docs/art/`.
**Acceptance:** check green; a failing Lune test first for any pure rule; seen in Play by the
counter, or exact steps in OWNER.md.
**Read first:** ROADMAP S5-03f4b; D-318 and D-225 in `docs/DECISIONS.md`;
`src/server/TryOns.luau`; `src/client/ShopView.luau` (its cards and the counter's prompt);
`src/server/FrontOffice.luau` (where the counter stands); `src/client/MirrorView.luau`
(`unitOf`, `copyWalls`).

## Queue (next sessions, the owner's ticket order)
1. S5-03g, h; S5-03d4 across the trip (unblocked); S5-03a2d the cars' hidden triangles;
   F-G1b4a2 the headlamp's beam (ROADMAP Step 4); F-G1b4b the hat spent.
2. The home's warm fill (D-290): faces turned from the bulb go near black (D-263: warm all round).
3. F-G1b5 waits for its art. Brix: ENG-25b's two-client run; Driving's stick read needs
   `PlayerModule`, fall back to the camera-turned `MoveDirection` (D-254), built in `../engine`.
   A PlayerSaves hook that runs before a leaving save's last write would replace `leaving`.
4. S4-02 monsters by lowest floor, S4-03 the elevator's choice, S4-04 trapping pays, S4-05.
5. The item catalog doc and the design doc's finds section need D-250, D-251, D-259, D-277, D-297,
   D-299, D-300, D-301, D-302, D-304, D-305, D-308 (the spot column), D-309, D-311 to D-318.
6. Once the owner's real purchase passes: mark Brix's ENG-23e done in `../engine`'s HANDOFF.
7. Late arrivals off `ClimbEnd.spot`; the driving torch (D-257); asset 203785492's type error;
   the front office's steel; cart seats vs `Seat:Sit`; a spare home unpadlocked (D-275); the
   hat's first-Wear dark screen; the body unhidden after a respawn (D-282); a Gold's own
   textures and the Packrat wanting a Gold most; a crack drawn on a cracked card (ROADMAP polish).
8. `CaughtSeized` is set by CaughtLunge and ArrangeView and read by FlashlightView, each with its
   own string: share one constant (a "camera held" attribute) when next in those files.
9. S5-03d4's climb server must restamp the lights it receives (`Use.leave`), as Climbs does.
10. The catch's film now comes from `Film.make`: watch a catch in Play once Rojo is connected.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
