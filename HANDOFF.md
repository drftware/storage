# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-17, session 248 (taking finds up, seen in Studio, D-305) · **Checks:** green
in a throwaway worktree at HEAD plus this session's change; red in the shared checkout only from
the find run's uncommitted `src/shared/Finds/Rows.luau` and `tests/stuffdeal.spec.luau` ·
**Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage); Brix pinned at
`482368f`, NOT on Brix's `origin` yet.

## State
- The home (D-259; the Claude Doc https://claude.ai/artifact/EUdGarQ2sEiUC6BU5E7Tww, docs tools
  only) is built a ROADMAP piece a session (S5-03): ground floor, fronts, starter sets, switch,
  a home each, hard hat, mirror, oak shelf with finds, job box, its panel, taking out, selling,
  Golds, cracked finds at half, and taking finds up into a climb, now seen in Studio (S5-03d3).
- Taking up (D-302, D-304, D-305), verified in Studio Play with one player: the take writes
  nothing; the gate keeps your own in your hand; one left on a floor is struck as the floor goes
  ("GatePay: BlobLamp out of …'s job box: Lost") and the save written at once; a rejoin lists
  the rest; one left at home is never struck. Found and fixed: Studio's Stop mid-climb struck a
  taken-up find; GatePay now settles on the next Heartbeat (a stopping server steps no more).
  A Kick mid-climb (a real leave) still strikes it. Two-player steps are in OWNER.md.
- On a live server the climb is on its own server and the teleport carries nothing yet (S5-03d4).
- Studio: watch the save with a Server `GetAsync` on "Saves.studio" (STUDIO.md "Taking finds up,
  seen"). The test save: cash 476, 37 finds (no Blob lamp, Skates 1, Boombox 9), Gold Teddies.
- Stage only your own paths; the find run commits its own `art/finds/` and `src/shared/Finds/`.
- Find art: the colour-change goo ball is done and seen in Play (S2b: fingertip prints bloom
  and cool back); next S3, the mega goo ball (`art/finds/WAVES.md`'s Next line).

## Next task: S5-03e1 Placements, in Brix
The moment it serves: you lift your lava lamp off the shelf, it glides over a half-stud grid on
your desk, turns a quarter at a tap, glows red where it won't fit, and settles where you put it.
This piece is the system under that, built in Brix (D-252); no screen yet.
1. Read `../engine/AGENTS.md` and `../engine/HANDOFF.md`; work there by Brix's rules (neutral
   names, its checks, its commits). Check Brix's exports first for any grid or footprint code.
2. Read the home plan's Arrange section (ideas 11 to 15, and "What you decided (Nov 16)") with
   the docs tools, by heading. Add a Brix ROADMAP ticket for a placements system.
3. Build it pure, with Lune specs: a room's surfaces (floor, tabletop, wall, ceiling) as
   rectangles; an item's footprint snapped to a half-stud grid with quarter turns; checks for in
   bounds, overlap and which surfaces an item may use, each refusal naming its reason; a count
   against a limit. No Roblox instances in the core.
4. Brix's checks green, commit in `../engine`; move this game's pin (`vendor/brix`) to it, add the
   new export to `docs/FRAMEWORK.md`, and run `scripts/check.sh` here (in a throwaway worktree if
   the find run has the checkout red; link `vendor/brix` into it).
**Acceptance:** Brix's checks and specs green; the pin moved; check green; FRAMEWORK.md lists it.
**Read first:** ROADMAP S5-03e; D-252; `docs/FRAMEWORK.md`; `../engine/AGENTS.md`;
`../engine/HANDOFF.md`; the home plan's Arrange section (docs tools).

## Queue (next sessions, the owner's ticket order)
1. S5-03e2, e3, then S5-03f-h; S5-03d4 across the trip (unblocked); S5-03a2d the cars' hidden
   triangles; F-G1b4a2 the headlamp's beam (ROADMAP Step 4); F-G1b4b the hat spent.
2. The home's warm fill (D-290): faces turned from the bulb go near black (D-263: warm all round).
3. F-G1b5 waits for its art. Brix: ENG-25b's two-client run; Driving's stick read needs
   `PlayerModule`, fall back to the camera-turned `MoveDirection` (D-254), built in `../engine`.
   A PlayerSaves hook that runs before a leaving save's last write would replace `leaving`.
4. S4-02 monsters by lowest floor, S4-03 the elevator's choice, S4-04 trapping pays, S4-05.
5. The item catalog doc and the design doc's finds section need D-250, D-251, D-259, D-277, D-297,
   D-299, D-300, D-301, D-302, D-304, D-305.
6. Once the owner's real purchase passes: mark Brix's ENG-23e done in `../engine`'s HANDOFF.
7. Late arrivals off `ClimbEnd.spot`; the driving torch (D-257); asset 203785492's type error;
   the front office's steel; cart seats vs `Seat:Sit`; a spare home unpadlocked (D-275); the
   hat's first-Wear dark screen; the body unhidden after a respawn (D-282); a Gold's own
   textures and the Packrat wanting a Gold most; a crack drawn on a cracked card (ROADMAP polish).

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
