# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-16, session 213 (worn finds and the home unit, designed with the owner) · **Checks:** green at this commit · **Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage).

## State
- F-G1b3c1 is done (D-250): the desk lamp, night-light, moon, blob and glass lamps and the neon
  sign each have a Switch anywhere, lit a minute (`Use.LampLasts`), keeping what's left when off,
  fading out by their switch-off when spent. Seen in Studio Play: the desk lamp on, off (31 s
  kept), on again, out after its time and no press after; the neon sign stutters on and buzzes.
- The owner made the RC car a recon car (D-250, ROADMAP F-G1b3c2 and c3): driven from a camera
  on its hood through the halls and into open units, so a player hiding in a unit can watch for
  monsters or look for finds; the collector (the Packrat) steals it. Defaults in D-250 (no range,
  no battery, monsters don't hear it, no headlight); the owner said "go ahead" to them.
- The owner's design (D-251, nothing built): the hard hat is worn, a headlamp for a minute,
  then it falls and breaks (no battery); skates make you faster, slippers are looks; monsters
  don't hear feet yet. Home is your own unit off the lobby with a shelf and a chest (every find
  you own, counted, sold from there); any find can be taken up in a slot and lost; whoever
  carries a find aboard keeps it. Tickets F-G1b4, F-G1b5, S5-03a-c; one question in `OWNER.md`.
- Find art (`art/finds/WAVES.md`): the second run ended at F-05d3, the galaxy goo ball;
  F-05e (step 14) and F-05f (step 15) are left.

## Next task: F-G1b3c2 Drive the RC car
The moment: you crouch in a unit with the door half down, and through a camera on the car's hood
you watch the hall for what's coming. Precedent: Rainbow Six Siege's drones.
1. Read ROADMAP F-G1b3c2 and D-250. Check `docs/FRAMEWORK.md` for anything Brix has for a
   vehicle, a camera swap or taking over the move stick before building one.
2. If it won't fit one session, split it in ROADMAP first (say, driving on your screen and the
   hood camera; then the server's checks and friends seeing it).
3. The pure core first, with a Lune spec: the car's step (throttle and steering in, a speed and
   turn cap, stopping at walls and shut doors), as the toy car's walk is pure today.
4. Server: Drive sets the car down in front of you, as the toy car's Push does (`down`), then
   moves it by the driver's input, checking every move (rate-limited, speed-capped, no walls).
   Pick the way that's smooth on a phone and still checked (network ownership with the server
   checking, or the server stepping input), verify the API, and note it in `docs/STUDIO.md`.
   Your body crouches still with the transmitter; caught, the drive ends.
5. Client: the view moves to the hood (low, wide, a jolt on bumps); the move stick drives; a
   button brings you back and the car stays. A motor whine rising with speed.
6. Studio Play: drive from the lobby down a hall into an open unit; it stops at a shut door;
   walk back to it and take it.
**Acceptance:** checks green; the step's spec fails before and passes after; seen in Studio Play
driving into a unit and stopping at a shut door; a friend's view and the phone stick go to
`OWNER.md` as exact steps.
**Read first:** ROADMAP F-G1b3c2 (grep "F-G1b3c2"); D-250 (grep "^## D-250" docs/DECISIONS.md);
`src/shared/Finds/Use.luau` (grep "DiecastCar", "down"); `src/server/FindUses.luau` (grep "down",
the toy car's walk); `src/shared/Finds/Sets/Figures.luau` lines 10-130 (the RC car's parts and
its Launch, Drive and Stop motions); `docs/FRAMEWORK.md`.

## Queue (next sessions, the owner's ticket order)
1. F-G1b3c3 the collector steals the car (ROADMAP), right after F-G1b3c2; then F-G1b4 the hard
   hat on your head. F-G1b5 (skates, slippers) waits for their art.
2. S4-02 monsters by lowest floor (its plan is in ROADMAP), then S4-03 the choice on the
   elevator's buttons, S4-04 trapping pays (5 coins a trapped monster), S4-05 the big find.
3. The item catalog doc still says "at home" for the six lamps and the RC car; `WAVES.md` has
   the new lines (D-250). The catalog's hard hat, skates and slippers and the design doc's
   finds and home sections need D-251. Bring both in line when they're next opened.
4. Once the owner's real purchase passes: mark Brix's ENG-23e done in `../engine`'s HANDOFF.
5. Trips stands every late arrival or respawn on the one arrival spot; two at once overlap
   until physics pushes them apart. Spread them (`ClimbEnd.spot`) as the carry's fallback does.
6. Small (ROADMAP lists them): the lamps going out, the finds' press sounds and hand, the monkey
   and toy car's polish; B-05b2b's box round the bend; L-08e3c, L-14b2d wait; S3-04b's polish;
   Free Everyone's swap sound; `sell*` Config warnings, a dropped find bumps a walker (D-182),
   the save's "best floor" still 0 after a ride, S1-07a to S2-07b2 leftovers, box words (D-215).

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
