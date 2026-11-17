# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-16, session 223 (the ground floor in the game) · **Checks:** green · **Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage); Brix pinned at `c9f6667`.

## State
- The home (D-259; the Claude Doc https://claude.ai/artifact/EUdGarQ2sEiUC6BU5E7Tww, docs tools
  only) is built a ROADMAP piece a session (S5-03). S5-03a2a is done (D-262): the 156-deep
  ground floor is exported, uploaded (asset 80376262399856), imported as `Props.Lobby` and the
  place saved (version 57). `Lobby.front` stands the climb's M unit in each of the 12 gaps
  (walls, floor, top dropped; oxblood door; tagged, so Doors runs it; anyone may open any one).
- Light (pulled in from a2b): fills in three rows of two; each front's bulb is a home's
  (`UnitLight.Home`: reach 22, 1.7 times as bright, no shadow, real whenever lit). Verified in
  Studio Play: twelve fronts, a door rolling, every open unit warm from the spawn, a car taking
  you to floor 1. Not yet on a phone or in the A16 emulator.
- Find art (third find run): A1's audit is in `art/finds/WAVES.md` ("Every built find, in the
  game"); all 46 built finds match the catalog's grade and worth. Next: P1 (ROADMAP F-G1f).
- The name cards over the doors (`Specs.Cards` `Unit1` to `Unit12`) are laid empty: a3 writes
  each owner's name.

## Next task: S5-03a2b The home look: calm, welcoming, yours
The moment: you step out of the car and the building breathes out: soft warm light, a finished
ceiling, plants by the doors, twelve units that look like little homes rather than the climb's
lockups; in yours you flick the light switch and it's warm (owner, Nov 16, D-263; Lethal
Company's ship and Resident Evil's save rooms, the safe place set against the danger).
1. Read D-263, then look at `art/sheets/lobby-spawn.png`, `lobby-unit.png`, `lobby-inside.png`.
2. Re-do the ground floor calm in `art/lobby`: a finished ceiling with warm, soft lights in
   place of the bare joists and strip lights, warmer walls, a cared-for floor, potted plants
   by the units, a bench. The six cars and their back wall keep the climb's edge.
3. A home unit kit of its own (built the unit's way, its own folder or a home variant of
   `art/unit`): smooth painted partitions, a finished ceiling in place of the wire top, a clean
   roll-up door in a warm colour, the same door rig so it rolls, a light switch plate inside by
   the door; a rug, a beanbag and a floor lamp to start. The climb's units don't change.
4. In the game: home units in the twelve gaps in place of the climb's M fronts (D-262); the
   switch (Switch; a click; the light warms up or down over about 0.2 s; dark inside with the
   door down and the light off; starts on; anyone may switch it until a3 gives units owners).
5. Judge at Galaxy A16 size: calm, safe, somewhere you'd hang out, plainly not the climb.
Split it (art, then the game) if it won't fit; the art alone may be a session.
**Acceptance:** check green; new sheets show a calm ground floor and a home unit unlike the
climb's; in Studio Play the switch works, a door rolls, and a car still takes you up.
**Read first:** D-263 and D-262 (grep "^## D-26" docs/DECISIONS.md); `art/lobby/README.md`;
`art/unit/README.md`; `src/shared/Lobby/init.luau` (`front`, `lay`); `src/shared/UnitLight.luau`.

## Queue (next sessions, the owner's ticket order)
1. S5-03a2c the ground floor weighed for a phone, after the new look (ROADMAP has its steps:
   triangles and real lights with every door open against the GDD caps, trim, time spawn to
   car), then S5-03a3 a unit each (a Brix plots system first, D-252; the owner's name on its card, the
   doors' rules), F-G1b4a the hard hat on your head (no run-down at home, D-259), S5-03b the
   mirror test, then S5-03c to h.
2. F-G1b4b the hard hat spent and broken; F-G1b5 waits for its art.
3. Brix ticket: Driving's stick read needs `PlayerScripts.PlayerModule`; fall back to the camera-
   turned `Humanoid.MoveDirection` as `input` does (D-254). Built in `../engine`, then the pin.
4. S4-02 monsters by lowest floor (its plan is in ROADMAP), then S4-03 the choice on the
   elevator's buttons, S4-04 trapping pays (5 coins a trapped monster), S4-05 the big find.
5. The item catalog doc and the design doc's finds section need D-250, D-251 and D-259 when
   next opened (lamps and RC car "at home"; hard hat, skates, slippers).
6. Once the owner's real purchase passes: mark Brix's ENG-23e done in `../engine`'s HANDOFF.
7. Spread late arrivals off the one arrival spot (`ClimbEnd.spot`); the driving torch's rules
   vs what's seen (D-257); Play logs assets 92259888500166 (box opens, 27 fails) and 203785492
   (type mismatch). Small polish: ROADMAP lists it.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
