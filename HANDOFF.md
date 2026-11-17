# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-17, session 250 (S5-03e2a, the save and the spots, D-308) · **Checks:** green
in the shared checkout, the find run's uncommitted files in · **Git:** `main`, committed, not
pushed (`origin` is github.com/drftware/storage); Brix pinned at `7f25310`, NOT on Brix's `origin`
yet (nor 482368f and 6574e0c before it).

## State
- The home (D-259; the Claude Doc https://claude.ai/artifact/EUdGarQ2sEiUC6BU5E7Tww, docs tools
  only) is built a ROADMAP piece a session (S5-03): ground floor, fronts, starter sets, switch,
  a home each, hard hat, mirror, oak shelf with finds, job box, its panel, taking out, selling,
  Golds, cracked finds at half, and taking finds up into a climb, seen in Studio (S5-03d3).
- Arrange (S5-03e): Brix's `Placements` judges (D-306). The save is at version 8 with `placed`
  and `Save.boxed` takes what's set out off the job box; `Home/Spots` has the spots, footprints,
  room areas, tops, limits, ids and checks (D-308). Pure and spec'd; no server, nothing in Studio.
- On a live server the climb is on its own server and the teleport carries nothing yet (S5-03d4).
- Studio: watch the save with a Server `GetAsync` on "Saves.studio" (STUDIO.md "Taking finds up,
  seen"). The test save: cash 476, 37 finds (no Blob lamp, Skates 1, Boombox 9), Gold Teddies.
- Stage only your own paths; the find run commits its own `art/finds/` and `src/shared/Finds/`,
  and has its own hunks in `docs/DECISIONS.md` and `docs/ROADMAP.md`: stage yours as a blob.

## Next task: S5-03e2b The server arranges
The moment: you set your lava lamp on the job box and it stays there, for you and for every friend
who walks in, after a rejoin too; a cheat can't drop it in a wall or a friend's unit. Server only.
1. `src/shared/Home/Arranged.luau` (CFrame maths, shared so e3's screen uses it), by D-308's
   frames: an area's frame from the unit's `face` and a `Spots.room` or furniture area, a pose's
   frame, a find's top, and where a find is drawn by its spot (its art's box, `Finds.box`).
2. `src/server/Arranging.luau`, a system after jobBoxes, Shelves' pattern: one `Brix.Placements`
   per held home (areas: `Spots.room` from the slot's Inside through `laid.pivot` into `face`,
   plus ShelfTop and JobBoxTop from `Starter`; limit `Spots.limit(Spots.Start)`), loaded from
   `data.placed` trimmed by `Spots.owned(rows, Save.settable(data, slots:fromBox(player)))`;
   what's dropped written back (`placements:save()`); laid on load and a Plot change, cleared on
   leave; a newer form refuses moves and is never written.
3. Remotes by `Spots`' names: Place (`Spots.ask`; the holder's own home; a name needs one in
   `Save.boxed`, gets `Spots.nextId`; an id must be set out), PutAway (`Spots.askId`; what stands
   on it goes back first), each `Brix.RateLimit.bucket(Spots.Limit)`; answered on Arranged; each
   change saved into `data.placed` and drawn (a `Tools.clone`, gilded for a Gold, inert, lights
   off, tagged `Spots.Tag`); riders follow a moved find.
4. `ServerStorage.ArrangeTest` (Studio only), then Play: a lava lamp on JobBoxTop, a sign on
   BackWall, one refused in a wall, kept on rejoin, the box one fewer. `scripts/check.sh` green.
**Acceptance:** check green; seen in Studio Play (placed, refused, kept on rejoin), or the steps
in OWNER.md.
**Read first:** D-308; `src/shared/Home/Spots.luau`; `src/server/Shelves.luau`;
`src/shared/Lobby/init.luau` 318-366 (`face`, the slot's Inside); `../engine/docs/modules/Placements.md`;
`src/server/JobBoxes.luau` 140-150 (`Save.boxed` with `fromBox`).

## Queue (next sessions, the owner's ticket order)
1. S5-03e2b, e3, then S5-03f-h; S5-03d4 across the trip (unblocked); S5-03a2d the cars' hidden
   triangles; F-G1b4a2 the headlamp's beam (ROADMAP Step 4); F-G1b4b the hat spent.
2. The home's warm fill (D-290): faces turned from the bulb go near black (D-263: warm all round).
3. F-G1b5 waits for its art. Brix: ENG-25b's two-client run; Driving's stick read needs
   `PlayerModule`, fall back to the camera-turned `MoveDirection` (D-254), built in `../engine`.
   A PlayerSaves hook that runs before a leaving save's last write would replace `leaving`.
4. S4-02 monsters by lowest floor, S4-03 the elevator's choice, S4-04 trapping pays, S4-05.
5. The item catalog doc and the design doc's finds section need D-250, D-251, D-259, D-277, D-297,
   D-299, D-300, D-301, D-302, D-304, D-305, D-308 (the spot column).
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
