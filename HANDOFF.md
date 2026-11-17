# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-17, session 253 (S5-03e3a2, Arrange seen on a phone, D-312) · **Checks:**
green in the shared checkout · **Git:** `main`, committed, not pushed (`origin` is
github.com/drftware/storage); Brix pinned at `7f25310`, NOT on Brix's `origin` yet.

## State
- The home (D-259; the Claude Doc https://claude.ai/artifact/EUdGarQ2sEiUC6BU5E7Tww, docs tools
  only) is built a ROADMAP piece a session (S5-03): ground floor, fronts, starter sets, switch,
  a home each, hard hat, mirror, oak shelf with finds, job box, its panel, taking out, selling,
  Golds, cracked finds at half, taking finds up into a climb, the server arranging, and the
  Arrange screen (S5-03e3a).
- Arrange is seen in Studio Play on the Galaxy A16 (D-312, `docs/art/S5-03e3a2-*`): tray lift,
  room lift, green, red, Turn, Place, Put away, ×, Done, a true Stop and Play rejoin. The button
  sits top right; the tray slides away while a find is lifted; the verbs are a corner cluster;
  your body, torch (`CaughtSeized`) and the tool wheel (`Tools.StowAttribute`) leave the room.
- On a live server the climb is on its own server and the teleport carries nothing yet (S5-03d4).
- The test save: cash 476, finds as before less one Boombox, MoonLamp and CampLantern in the box;
  set out in Unit1: MoonLamp#1 on the job box, Boombox#1 and CampLantern#1 on the floor.
  Watch it with a Server `GetAsync` on "Saves.studio" or `ServerStorage.ArrangeTest` "rows".
- Studio's Device Simulator is left on the Galaxy A16, landscape.
- Stage only your own paths; the find run commits its own `art/finds/`, `src/shared/Finds/`,
  `src/shared/Tools/Catalog.luau`, and may have hunks in `docs/`: stage yours as a blob then.
- Find art (third run): S4a done, the squishy cake slice's art and row (cream pushes out of its
  sides on 47 bones), not ticked, imported or seen in Play. Next: S4b (WAVES.md's Next).

## Next task: S5-03e3b The limit bar, the lid and friends
The moment: arranging, a small bar fills as you set finds out (12 of 25), so you see room left
without a word; open your job box and the lamp on its lid rides up with it; a friend watching
sees your find settle into place, not snap. Bloxburg's build budget bar is the bar.
1. The limit bar on the Arrange screen: count out of `Spots.limit` (the server's count of what's
   set out), filled as Place answers; at the limit a find from the tray won't lift (the card
   dims, no words). Every change eases.
2. Finds on the job box's lid ride it as it opens (JobBoxView poses the lid on each screen; the
   drawn finds on `JobBoxTop` move with it and settle back; D-308).
3. Friends: a find set out by another player settles in (a short drop and the knock heard
   nearby) rather than appearing. Server draws stay the truth.
4. Lune specs for any pure count logic; `scripts/check.sh` green; see it in Studio Play on the
   A16 (the lid with the moon lamp on it is in the test save) and capture to `docs/art/`.
**Acceptance:** check green; the bar and the lid seen in Play at phone size, or steps in OWNER.md;
split in ROADMAP if it won't fit (e3b1 the bar, e3b2 the lid, e3b3 friends).
**Read first:** D-311, D-312; `src/client/ArrangeView.luau` (gui `makeGui`, `answered`,
`fillTray`); `src/client/JobBoxView.luau` (the lid's pose); `src/server/Arranging.luau` (draws,
limit); `src/shared/Home/Spots.luau` (`limit`).

## Queue (next sessions, the owner's ticket order)
1. S5-03e3b, then S5-03f-h; S5-03d4 across the trip (unblocked); S5-03a2d the cars' hidden
   triangles; F-G1b4a2 the headlamp's beam (ROADMAP Step 4); F-G1b4b the hat spent.
2. The home's warm fill (D-290): faces turned from the bulb go near black (D-263: warm all round).
3. F-G1b5 waits for its art. Brix: ENG-25b's two-client run; Driving's stick read needs
   `PlayerModule`, fall back to the camera-turned `MoveDirection` (D-254), built in `../engine`.
   A PlayerSaves hook that runs before a leaving save's last write would replace `leaving`.
4. S4-02 monsters by lowest floor, S4-03 the elevator's choice, S4-04 trapping pays, S4-05.
5. The item catalog doc and the design doc's finds section need D-250, D-251, D-259, D-277, D-297,
   D-299, D-300, D-301, D-302, D-304, D-305, D-308 (the spot column), D-309, D-311, D-312.
6. Once the owner's real purchase passes: mark Brix's ENG-23e done in `../engine`'s HANDOFF.
7. Late arrivals off `ClimbEnd.spot`; the driving torch (D-257); asset 203785492's type error;
   the front office's steel; cart seats vs `Seat:Sit`; a spare home unpadlocked (D-275); the
   hat's first-Wear dark screen; the body unhidden after a respawn (D-282); a Gold's own
   textures and the Packrat wanting a Gold most; a crack drawn on a cracked card (ROADMAP polish).
8. `CaughtSeized` is now set by CaughtLunge and ArrangeView and read by FlashlightView, each with
   its own string: share one constant (a "camera held" attribute) when next in those files.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
