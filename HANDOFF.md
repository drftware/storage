# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-17, session 258 (S5-03f3, a home light's minute starts on the climb, D-317) ·
**Checks:** green in the shared checkout · **Git:** `main`, committed, not pushed (`origin` is
github.com/drftware/storage); Brix pinned at `7f25310`, NOT on Brix's `origin` yet.

## State
- The home (D-259; the Claude Doc https://claude.ai/artifact/EUdGarQ2sEiUC6BU5E7Tww, docs tools
  only) is built a ROADMAP piece a session (S5-03): ground floor, fronts, starter sets, switch,
  a home each, hard hat, mirror test, shelf, job box and its panel, taking out, selling, Golds,
  taking finds up, Arrange, the mirror's frame, the clothes rail, wearing from it, and now
  home's lights never running down.
- Home's lights (D-317): any light lit at home burns for good (`Use.home`); as the lobby car
  lands on floor 1, Climbs calls `FindUses:leave` for each rider and every forever-lit find in
  their slots or on their head (`Slots:onThem`) gets its own full minute from then
  (`Use.leave`: only `UseLeft` grows, the press's clock kept, so nothing replays); screens read
  it through `Use.relit`. Server seen in Play; your screen's run-down is in OWNER.md.
- Rojo's plugin wasn't connected (the owner's Connect click): Studio got the code by patching
  `Source` from Edit, and the client kept the old `Use` (STUDIO.md, "Patching scripts without Rojo").
- A worn find from the rail is "out of your box": at risk up a lobby car (D-302).
- On a live server the climb is on its own server and the teleport carries nothing yet (S5-03d4).
- The test save: one HardHat (on the rail), cash 478. Device Simulator: Galaxy A16, landscape.
  A world button is pressed from a Client `execute_luau` (`InputHoldBegin`/`End`, STUDIO.md).
- Stage only your own paths; the find run commits its own `art/finds/`, `src/shared/Finds/`,
  `tests/stuffdeal.spec.luau`, and may have hunks in `docs/`: stage yours as a blob then.

## Next task: S5-03f4 Wrap colours tried on (idea 24)
The moment: you see yourself in the mirror wrapped in a colour for a few seconds, then it peels
off with a crinkle; a mirror by the counter lets you try one before you buy it (DOORS' and
Fortnite's try-on before buying; the film is the caught player's wrap, D-224).
1. Read idea 24 and the doc's "What you decided (Nov 16)"; split f4 in ROADMAP if it won't fit
   (f4a: trying on at your mirror, built on the film and its tint; f4b: the counter's mirror).
2. Find how the caught player's film goes on a body and is tinted (`KeptPlayers`, `WrapColours`,
   `Wearing`); build the try-on on it, server-owned: who may start it, rate-limited, checked.
3. Every screen sees it: the film wraps you, `MirrorView`'s copy of you shows it, it peels off
   with a crinkle after a few seconds. No text explaining it; a press is one verb.
4. Gaps (what starts a try-on at home, which colours) get a default and an OWNER.md line.
5. `scripts/check.sh` green; seen in Play on the A16 with a picture in `docs/art/`.
**Acceptance:** check green; a failing Lune test first for any pure rule; seen in the mirror in
Play, or exact steps in OWNER.md.
**Read first:** the home doc's idea 24 (docs tools, search its heading); D-224 and D-280;
`src/shared/WrapColours.luau`; `src/server/Wearing.luau`; `src/client/MirrorView.luau` (how
players are copied into the glass); `src/server/KeptPlayers.luau` where the film is put on.

## Queue (next sessions, the owner's ticket order)
1. S5-03g, h; S5-03d4 across the trip (unblocked); S5-03a2d the cars' hidden triangles;
   F-G1b4a2 the headlamp's beam (ROADMAP Step 4); F-G1b4b the hat spent.
2. The home's warm fill (D-290): faces turned from the bulb go near black (D-263: warm all round).
3. F-G1b5 waits for its art. Brix: ENG-25b's two-client run; Driving's stick read needs
   `PlayerModule`, fall back to the camera-turned `MoveDirection` (D-254), built in `../engine`.
   A PlayerSaves hook that runs before a leaving save's last write would replace `leaving`.
4. S4-02 monsters by lowest floor, S4-03 the elevator's choice, S4-04 trapping pays, S4-05.
5. The item catalog doc and the design doc's finds section need D-250, D-251, D-259, D-277, D-297,
   D-299, D-300, D-301, D-302, D-304, D-305, D-308 (the spot column), D-309, D-311 to D-317.
6. Once the owner's real purchase passes: mark Brix's ENG-23e done in `../engine`'s HANDOFF.
7. Late arrivals off `ClimbEnd.spot`; the driving torch (D-257); asset 203785492's type error;
   the front office's steel; cart seats vs `Seat:Sit`; a spare home unpadlocked (D-275); the
   hat's first-Wear dark screen; the body unhidden after a respawn (D-282); a Gold's own
   textures and the Packrat wanting a Gold most; a crack drawn on a cracked card (ROADMAP polish).
8. `CaughtSeized` is set by CaughtLunge and ArrangeView and read by FlashlightView, each with its
   own string: share one constant (a "camera held" attribute) when next in those files.
9. S5-03d4's climb server must restamp the lights it receives (`Use.leave`), as Climbs does.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
