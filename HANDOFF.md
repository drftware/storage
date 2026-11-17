# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-17, session 228 (the ground floor weighed for a phone) · **Checks:** green · **Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage); Brix pinned at `c9f6667`.

## State
- The home (D-259; the Claude Doc https://claude.ai/artifact/EUdGarQ2sEiUC6BU5E7Tww, docs tools
  only) is built a ROADMAP piece a session (S5-03). The calm ground floor, the home fronts,
  their starter sets and the light switch are in the game (D-268).
- S5-03a2c (D-271): weighed in Studio Play on the Galaxy A16 simulator, every home lit. Real
  lights 43 down to 31 (33 in a home): only the two floor lamps nearest you throw real light,
  eased, the rest glowing. The spawn view 160k triangles down to 145k: a front's drum and head
  plates are drawn only from inside that home. Run from the spawn to a car: 8.5 s.
- Still over the triangle default (a climb floor's 61k-112k): the cars' 51k, ticketed as
  S5-03a2d after a3. A phone's frame rate is the owner's (Studio draws 15 fps in the background).
- Find art: another session works in this checkout; its uncommitted files (art/finds,
  Finds/Rows, finduse spec) are theirs.

## Next task: S5-03a3 A unit each (Brix's plots system first, D-252)
The moment: you load in and one of the twelve homes is yours, your name over its door, its door
up and its light on, waiting; pull it down and only you get back in (a locked rattle for anyone
else). Precedent: Bee Swarm Simulator's and Grow a Garden's plots, one claimed per player on join.
Split in ROADMAP if it won't fit: a3a the Brix system, a3b the game's homes on it.
1. Read the home doc's "What you decided (Nov 16)" and its unit-each idea (docs tools, search the
   headings). Check `docs/FRAMEWORK.md` and `../engine` for anything plot-shaped first.
2. a3a, in `../engine` by its own AGENTS.md (neutral names, its checks, its commits): a plots
   system. Claim a free plot for each player on join, free it on leave, a signal for both, a
   pure core with Lune specs (no plot twice, full server). Then move this game's pin.
3. a3b: FrontOffice adopts it for the twelve homes: the owner's name on the front (the name
   card's place, Lobby Specs `Card`), doors up by default, a pulled-down door locked to all but
   the owner (the climb's locked rattle), unclaimed homes padlocked, the switch the owner's only
   (D-263). Every refusal answers with sound and motion, no text.
4. Queue 2: ShutIn's "inside" uses the M's 12-stud depth, so deep in a home (30 deep) it doesn't
   count you shut in and the fills light the back of a shut home. Use the home's own depth.
**Acceptance:** check green; the Brix specs pass and the pin moved; in Studio Play your home is
claimed and named, a shut door refuses another player (two-client steps in OWNER.md).
**Read first:** the home doc's decisions section; `docs/FRAMEWORK.md`; `../engine/AGENTS.md`;
`src/server/FrontOffice.luau` (grep `Switch`); D-263 (grep "^## D-263" docs/DECISIONS.md);
`src/shared/StorageUnit/ShutIn.luau`.

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
