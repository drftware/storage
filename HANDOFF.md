# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-17, session 229 (Brix's plots, S5-03a3a) · **Checks:** green · **Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage); Brix pinned at `482368f`, which is NOT on Brix's `origin` yet (push Brix first, OWNER.md).

## State
- The home (D-259; the Claude Doc https://claude.ai/artifact/EUdGarQ2sEiUC6BU5E7Tww, docs tools
  only) is built a ROADMAP piece a session (S5-03). The calm ground floor, the home fronts,
  their starter sets and the light switch are in the game (D-268), weighed for a phone (D-271).
- S5-03a3a (D-273): Brix has Plots (its ENG-25a, `482368f`): `Brix.Plots.new({ plots, pick })`,
  `Brix.PlotPick.inOrder()`, and `Brix.Roblox.PlayerPlots.new({ plots, players, attribute? })`,
  which claims a plot by UserId on join, lets it go on leave, puts a thirteenth player in line,
  fires `claimed`/`released` with `{ player, plot }` and writes the plot's name on the player
  (attribute `Plot`). Specs green in Brix; not yet run in Studio (Brix's ENG-25b). The game
  pins it but doesn't use it yet.
- Still over the triangle default: the cars' 51k, ticketed as S5-03a2d after a3.
- Find art (third find run): V2 done (D-272). Next: V3 (ROADMAP F-G1e3; `art/finds/WAVES.md`).

## Next task: S5-03a3b Your home, claimed as you join (on Brix's Plots)
The moment: you load in and one of the twelve homes is yours, your name over its door, its door
up and its light on, waiting; pull it down and only you get back in (a locked rattle for anyone
else). Precedent: Bee Swarm Simulator's and Grow a Garden's plots, one claimed per player on join.
1. Read `docs/modules/Plots.md` in `vendor/brix` (the whole API in 30 lines) and FrontOffice's
   homes (grep `Switch`, `Card`, the home list). Name the twelve homes nearest the spawn first.
2. In FrontOffice, make `Brix.Plots` + `Brix.Roblox.PlayerPlots`; on `claimed`, write the holder's
   name on the home's card (Lobby Specs `Card`, the stencil lettering) and raise its door with the
   slow loud open; on `released`, blank the card, drop the door and padlock it. Unclaimed homes
   start shut and padlocked (the home doc's idea 2).
3. A pulled-down door opens for its holder only: anyone else gets the climb's locked rattle and
   no motion (D-263 says the switch is the holder's only too). Server checks every press.
4. Queue item from a3: ShutIn's "inside" uses the M's 12-stud depth, so deep in a home (30 deep)
   it doesn't count you shut in. Use the home's own depth.
5. Run it in Studio Play (one player gets the nearest home, named), log it in `docs/STUDIO.md`
   and in Brix's `docs/STUDIO.md` as ENG-25b's run; tick ENG-25b in Brix's ROADMAP (its commit).
**Acceptance:** check green; in Studio Play your home is claimed, named and open; a shut door
refuses another player (two-client steps in OWNER.md); Brix's ENG-25b logged and ticked.
**Read first:** `vendor/brix/docs/modules/Plots.md`; `src/server/FrontOffice.luau` (grep
`Switch`); D-263 and D-273 (grep "^## D-26[3]\|^## D-273" docs/DECISIONS.md);
`src/shared/StorageUnit/ShutIn.luau`; the home doc's idea 3 "Your door" (docs tools, search).

## Queue (next sessions, the owner's ticket order)
1. F-G1b4a the hard hat, S5-03b the mirror, S5-03c-h; S5-03a2d the cars' hidden triangles.
2. F-G1b4b the hard hat spent and broken; F-G1b5 waits for its art.
3. Brix ticket: Driving's stick read needs `PlayerScripts.PlayerModule`; fall back to the
   camera-turned `Humanoid.MoveDirection` as `input` does (D-254). Built in `../engine`.
4. S4-02 monsters by lowest floor, S4-03 the elevator's choice, S4-04 trapping pays, S4-05.
5. The item catalog doc and the design doc's finds section need D-250, D-251 and D-259.
6. Once the owner's real purchase passes: mark Brix's ENG-23e done in `../engine`'s HANDOFF.
7. Spread late arrivals off `ClimbEnd.spot`; the driving torch's rules vs what's seen (D-257);
   Play logs assets 92259888500166 and 203785492. The front office's counter and shelves are
   still the climb's steel. The lobby's cart seats (`Cart1.RideSeat`) didn't seat a server
   `Seat:Sit` in a quick try (S5-03a2b4); look before blaming them.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
