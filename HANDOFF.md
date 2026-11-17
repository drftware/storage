# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-17, session 226 (the home look in the game) · **Checks:** green · **Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage); Brix pinned at `c9f6667`.

## State
- The home (D-259; the Claude Doc https://claude.ai/artifact/EUdGarQ2sEiUC6BU5E7Tww, docs tools
  only) is built a ROADMAP piece a session (S5-03). S5-03a2b3 (D-268) put the calm ground floor
  and the home fronts in the game: `Props.Lobby` (re-uploaded) and the new `Props.Home` are in
  the open Studio place (NOT saved by me), each unit's gap a home front on the M's door rig
  (`Home.dress`), its starter set inside, 24 plants, 10 benches, 2 planters, hall lights only
  over the cars, warm fills tagged so a shut unit goes dark.
- The switch: server state `Home.LightAttribute`, drawn by `src/client/HomeLights.luau`.
  Verified in Studio Play by flipping the attribute on the server: the rocker rocks, both lamps
  ease out over 0.2 s, the lamp goes plain; shut in, the fills drop to 0.2. NOT verified: a real
  press. E took the door's Lift (so it's T now); T from 3 studs did nothing either.
- Find art (third find run): another session is working; `src/shared/Finds/init.luau` is theirs.

## Next task: S5-03a2b4 The switch's button shows and presses
The moment: inside your home by the door you press Switch and the light answers at once.
1. In Studio Play, stand in Unit 1 by its switch (FrontOffice's `wireSwitch` hangs the button on
   `SwitchSpot`, 0.6 off the plate) and find out whether the button shows at all: hook
   `ProximityPromptService.PromptShown` on the client, or turn `RequiresLineOfSight` off to test.
2. Fix the cause (line of sight through the front's colliders, `Exclusivity`, ButtonView, or the
   MCP's simulated key not reaching prompts: try a click on the drawn button too).
3. See a real press flip it with the door up and with it down; the click heard; Output clean.
4. Look at a home at phone size (Galaxy A16) in Play: the front, the lamp lit and off, the
   seats (sit on each); fix what reads wrong. Then S5-03a2c.
**Acceptance:** check green; a real press in Studio Play flips the light (seen in Output or the
attribute); OWNER.md's "Walk into your home" step 3 made true.
**Read first:** D-268 (grep "^## D-268" docs/DECISIONS.md); `src/server/FrontOffice.luau`
(`wireSwitch`); `src/server/Prompts.luau` (`make`); `src/client/ButtonView.luau` (grep
`PromptShown`); `src/client/HomeLights.luau`; `docs/STUDIO.md` (tail).

## Queue (next sessions, the owner's ticket order)
1. S5-03a2c the ground floor weighed for a phone (now 6 fills, 12 ceiling lamps, 12 floor
   lamps, 6 car lamps, the porch), then S5-03a3 a unit each (a Brix plots system first, D-252;
   the switch then the owner's only, D-263), F-G1b4a the hard hat, S5-03b the mirror, S5-03c-h.
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
   still the climb's steel.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
