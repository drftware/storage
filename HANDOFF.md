# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-16, session 209 (a dropped lantern holds the Mannequin) · **Checks:** green · **Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage).

## State
- F-G1b3b done (D-234): a found light lying lit on the floor holds a Mannequin as far as its own
  lamp reaches (lantern 9.6 studs, tea light 7.2), shaded by walls and shut doors, until it runs
  down (`Use.litUntil`, `Use.reach`, `Keeper.Glows`, `Keepers`' `lamps`). In a hand it holds
  nothing (the owner's call, `OWNER.md`). Seen in Studio Play: the dropped lantern's clank woke a
  Mannequin, it came at the player, froze 9.5 studs from the lantern, held 35 s with nobody near
  and walked on as the light ran out. New Studio hook: Workspace `StandMannequin`.
- F-G1b is done but for F-G1b3c (the RC car), which waits on `OWNER.md`.
- Find art (`art/finds/WAVES.md`): the toy siren car is half built (Nov 16, F-04e: baked and
  exported, fixes not rendered yet); next finish it, then the squeaky duck. The run commits its
  own files by path; stage HEAD plus your own lines only.

## Next task: S3-05a Two players left behind land on top of each other, and can't be cut free
The moment: left behind, you wake shut in a unit of your own, wrapped, bang on the door, and a
friend follows the noise and cuts you free. In the owner's three-player test (Nov 15) two left
behind both woke wrapped on one spot in front of the elevator, cameras inside each other, and
the third player's Cut free said "Get closer" forever.
1. A lead: `src/server/Climbs.luau` near line 441 carries each left-behind player up in its own
   `spawn`, and when `KeptPlayers:store` fails it pivots the character to the one `lobby` CFrame,
   so two failures stack on one spot, still wrapped, in no unit, so Cut free never finds them.
2. Find why `store` failed for both: `KeptPlayers.luau`'s `store` (grep "local function store")
   and `Kept.choose` / `Kept.free` (`src/shared/Kept.luau`); whether two carries in the same
   moment pick the same unit before either is marked holding someone; whether the new floor's
   units are ready (dealt, doors down) when the pick runs. A failing Lune spec first for any
   pure part (two picks in a row never share a unit).
3. Fix so each wakes in a unit of their own. If a fallback stays, it never stands two players on
   one spot and never leaves a wrapped player nobody can free (stand them unwrapped, spaced
   apart, or retry the pick a beat later; D-186 has the rule).
4. Studio: STUDIO.md "Testing left behind from the MCP" with two stand-ins left behind; read
   Output for where each was stored, and check Cut free works at each one's door.
**Acceptance:** checks green; two left behind each land wrapped in a different unit with the
Bang button, and a friend at each door can cut them free; `OWNER.md`'s carried-up steps (S3-01a)
become three-player steps covering this (numbered, plain words).
**Read first:** ROADMAP S3-05a (grep "S3-05a"); `src/server/Climbs.luau` 410-450;
`src/server/KeptPlayers.luau` (`store`, grep only); `src/shared/Kept.luau` (`choose`, `free`);
D-186 (grep "^## D-186" docs/DECISIONS.md); STUDIO.md "Testing left behind from the MCP".

## Queue (next sessions, the owner's ticket order)
1. **S3-05b A caught friend put in the unit you're standing in** (ROADMAP S3-05b; a failing spec
   for the pick first). Then S4-02 to S4-05 (5 coins a trapped monster).
2. F-G1b3c the RC car drives off its transmitter, if the owner says so (`OWNER.md`).
3. Once the owner's real purchase passes: mark Brix's ENG-23e done in `../engine`'s HANDOFF.
4. A Studio hook to catch yourself for real (CatchTest finds no keeper even after WakeSleepers
   and 24 s, Nov 15; a Workspace attribute that catches by the nearest sleeper would do).
5. Small (ROADMAP lists them): the finds' press sounds and hand (F-G1b2 polish), the monkey and
   toy car's polish (F-G1b3a); B-05b2b's box round the bend; L-08e3c, L-14b2d wait; S3-04b's
   polish; Free Everyone's swap sound; `sell*` Config warnings, a dropped find bumps a walker
   (D-182), the save's "best floor" still 0 after a ride, S1-07a to S2-07b2 leftovers, box
   words (D-215).

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
