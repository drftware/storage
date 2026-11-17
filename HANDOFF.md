# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-17, session 247 (taking finds up wired on the server, D-304) · **Checks:**
green in the shared checkout · **Git:** `main`, committed, not pushed (`origin` is
github.com/drftware/storage); Brix pinned at `482368f`, NOT on Brix's `origin` yet.

## State
- The home (D-259; the Claude Doc https://claude.ai/artifact/EUdGarQ2sEiUC6BU5E7Tww, docs tools
  only) is built a ROADMAP piece a session (S5-03): ground floor, fronts, starter sets, switch,
  a home each, hard hat, mirror, oak shelf with finds, job box, its panel, taking out, selling,
  Golds, cracked finds selling at half, and now taking finds up wired on the server (S5-03d2).
- Taking up (D-302, D-304): a find out of a job box goes up as its holder rides a lobby car into
  floor 1 (Climbs' `board` calls `Slots:up`). Slots' `taken` fires Lost (cleared with a floor or
  the climb, its piece gone, used up, its owner leaving mid-climb) or Back (recalled home); a
  gate's `keep` hands a friend's back apart (`Moved`). GatePay settles each with
  `Home.Taken.settle` and writes every touched save at once; a stopping server settles nothing.
  A leaving owner's strike reaches their last write through `Saving:leaving(userId)`.
- Passes checks, untested in Studio. On a live server the climb is on its own server and the
  teleport carries nothing yet (S5-03d4); Studio climbs on the same server, so d3 can see it.
- Studio: the Edit DataModel can't reach DataStores from the MCP. In Play,
  `ServerStorage.StudioCrack:Invoke(player, "BlobLamp")` cracks one in the test save. Taking a
  find out in Play: the notes `s5-03c2b2b-take-out-seen.md` and `s5-03c3a-sell-seen.md` in the
  shared notes folder. The test save: cash 476, one Blob lamp (whole), Gold Teddies.
- Stage only your own paths; the find run commits its own `art/finds/` and `src/shared/Finds/`.

## Next task: S5-03d3 Taking finds up, seen
The moment: you bring your lamp up for the dark floors, it lights your way through floor 1, the
gate slams and it's still in your hand. Get caught with it and it's gone from your box for good.
1. Studio Play, one player. Take the Blob lamp out of your job box into your hand (Output: no
   save write). Ride a lobby car up (Studio climbs on the same server; Trips sends off).
2. On floor 1, open the gate (find the code, or a Studio dev path in Elevators/Climbs) and ride
   with the lamp in hand: Output shows GatePay keeping nothing for it; it stays in your slot.
3. Drop it on floor 2 and ride on without it: as floor 2 is cleared, Output prints
   "GatePay: BlobLamp out of …'s job box: Lost" and the save's next write has no Blob lamp.
4. Stop and Play again: the job box lists what's left, nothing doubled. Then take a find out and
   leave at home (stop Play): it's Back, never struck.
5. Fix what Play shows (a failing Lune spec first for any pure bug). Captures to
   `docs/art/S5-03d3-*.jpg`. Two-player steps (a friend carries yours aboard: theirs; you leave
   mid-climb: struck, and theirs to carry) go to OWNER.md.
**Acceptance:** check green; steps 1 to 4 seen in Studio Output and written in STUDIO.md.
**Read first:** ROADMAP S5-03d3; D-304; `src/server/GatePay.luau` (`onTaken`, `settleMoved`);
`src/server/Slots.luau` (`up`, `lost`, `strand`, `keep`); the two shared notes named above.

## Queue (next sessions, the owner's ticket order)
1. S5-03d4 across the trip (ROADMAP), then S5-03e-h; S5-03a2d the cars' hidden triangles;
   F-G1b4a2 the headlamp's beam (ROADMAP Step 4); F-G1b4b the hat spent.
2. The home's warm fill (D-290): faces turned from the bulb go near black (D-263: warm all round).
3. F-G1b5 waits for its art. Brix: ENG-25b's two-client run; Driving's stick read needs
   `PlayerModule`, fall back to the camera-turned `MoveDirection` (D-254), built in `../engine`.
   A PlayerSaves hook that runs before a leaving save's last write would replace `leaving`.
4. S4-02 monsters by lowest floor, S4-03 the elevator's choice, S4-04 trapping pays, S4-05.
5. The item catalog doc and the design doc's finds section need D-250, D-251, D-259, D-277, D-297,
   D-299, D-300, D-301, D-302, D-304.
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
