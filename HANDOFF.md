# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-17, session 227 (the home switch seen to press) · **Checks:** green · **Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage); Brix pinned at `c9f6667`.

## State
- The home (D-259; the Claude Doc https://claude.ai/artifact/EUdGarQ2sEiUC6BU5E7Tww, docs tools
  only) is built a ROADMAP piece a session (S5-03). The calm ground floor, the home fronts,
  their starter sets and the light switch are in the game (D-268). `Props.Lobby` and
  `Props.Home` are in the open Studio place (not saved by me).
- S5-03a2b4: the switch was never broken. A button shows only while it's on screen, and the
  last test's first-person view faced away from it. Verified in Studio Play: T flipped the
  light with the door down and up (the click played, both lamps went out), and on the Galaxy
  A16 simulator a tap on the drawn button flipped it. Every seat (beanbag, bench, planter)
  sits you facing out. Only the FrontOffice comment changed in code.
- Not seen: any picture. `screen_capture` timed out all session (Studio drew at 15 fps, likely
  hidden behind other windows), so the look at phone size is the owner's (OWNER.md "Walk into
  your home").
- Find art (third find run): another session is working; its uncommitted files (Finds,
  FindUses, FindUseView, art/finds, CODEMAP, one OWNER.md and one DECISIONS hunk) are theirs.

## Next task: S5-03a2c The ground floor weighed for a phone
The moment: on a cheap phone the calm ground floor runs smooth from the spawn to your home and
on to a car, with every home lit.
1. Read the GDD tech plan's caps (real lights, awake keepers, triangles): docs tools, search the
   heading, don't pull the whole doc.
2. In Studio Play on the Galaxy A16 simulator (STUDIO.md "The Device Simulator's calls"), count
   the ground floor's enabled real lights (now 6 fills, 12 ceiling lamps, 12 floor lamps, 6
   car lamps, the porch) and its triangles, with every home lit, and frames a second over 5 s
   at the spawn, inside a home and at the cars.
3. Trim what's over the caps: the floor lamps' real light only near you (UnitLight's near-bulb
   budget is the pattern), fewer fills, a front's hidden parts. Each light that goes keeps its
   glow (the shade or glass colour) so nothing reads dark.
4. Time the run from the spawn to a car (under 15 s); carts, cars and trips unchanged.
**Acceptance:** check green; the counts and frame rates, before and after, in STUDIO.md; within
the caps, or the gap in OWNER.md with a default chosen.
**Read first:** the GDD tech plan section; `src/shared/Lobby/init.luau` (grep `Fill`);
`src/shared/UnitLight.luau` (the near-bulb budget); `src/client/HomeLights.luau`; D-268 (grep
"^## D-268" docs/DECISIONS.md); `docs/STUDIO.md` (grep "A button off screen").

## Queue (next sessions, the owner's ticket order)
1. S5-03a3 a unit each (a Brix plots system first, D-252; the switch then the owner's only,
   D-263), F-G1b4a the hard hat, S5-03b the mirror, S5-03c-h.
2. ShutIn's "inside" uses the M's 12-stud depth, so deep in a home (30 deep) BehindDoors
   doesn't count you shut in: the fills light the back of a shut home. Fix with a3.
3. F-G1b4b the hard hat spent and broken; F-G1b5 waits for its art.
4. Brix ticket: Driving's stick read needs `PlayerScripts.PlayerModule`; fall back to the
   camera-turned `Humanoid.MoveDirection` as `input` does (D-254). Built in `../engine`.
5. S4-02 monsters by lowest floor, S4-03 the elevator's choice, S4-04 trapping pays, S4-05.
6. The item catalog doc and the design doc's finds section need D-250, D-251 and D-259.
7. Once the owner's real purchase passes: mark Brix's ENG-23e done in `../engine`'s HANDOFF.
8. Spread late arrivals off `ClimbEnd.spot`; the driving torch's rules vs what's seen (D-257);
   Play logs assets 92259888500166 and 203785492. The front office's counter and shelves are
   still the climb's steel. The lobby's cart seats (`Cart1.RideSeat`) didn't seat a server
   `Seat:Sit` in a quick try (S5-03a2b4); look before blaming them.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
