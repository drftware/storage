# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-16, session 215 (driving a body from a player's device, built in Brix) · **Checks:** green here and in Brix · **Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage); Brix `main` at `c9f6667`, pushed, CI passes.

## State
- F-G1b3c2b is done in Brix (its ENG-24b, E-080): `Brix.MoveCheck.ground` judges how fast and far
  the car may move; `Brix.Roblox.Driving.server` hands the car to its driver's device, checks every
  move and a ray for walls, and puts a bad move back with a half-second hold; `.client` reads the
  move stick on any device, holds the character still and drives the car's constraints.
- Seen in Brix's Studio example: driven at a wall at 14 studs a second, the car stopped flush
  against it; a 40-stud teleport and a hop through the wall were put back; the driver leaving
  ended the drive. Studio's simulated keys reached the game only once, so runs steer from scripts.
- Brix is pushed (CI passes); the pin is still `5cdb8c2` and moves to `c9f6667` (Handling and
  Driving) as F-G1b3c2c starts.
- Earlier today: the lamps switch on anywhere (F-G1b3c1, D-250); worn finds and the home unit
  designed (D-251); F-G1d dealt the wind-ups and squishies (D-253).

## Next task: F-G1b3c2c Drive it (moves the pin first)
The moment: you set the car down and the hood camera drops you to the floor, low and wide; push
the stick and it leaps off at once with a rising whine, the wheels turning, and stops dead at a
shut door.
1. Move the pin (Brix is pushed): `vendor/brix` to `c9f6667`; update `docs/FRAMEWORK.md` (the pin line and the two
   Brix rows for Handling and Driving, now in use). Check green.
2. The car set down apart from its transmitter: the model is one (`RCCar_Remote` is the root, the
   car hangs off `RCCar_Arms`), so the car needs its own assembly, unanchored, with low friction
   on its floor parts (Brix's Driving page says why). Find the code: `grep -rn RCCar src docs/CODEMAP.md`.
3. Server: a `Driving.server` per drive, the check at the handling's top × 1.25; `ended` and
   `putBack` told to the driver's client. Client: `Driving.client` with the handling's feel
   numbers in Config, `controls` mixing a little throttle into a sideways push (E-079); the hood
   camera with a jolt on a bump and on a put-back; a whine from `asked()`; wheels turning; the
   back button; walking to it takes it back.
4. Studio Play: from the lobby down a hall into an open unit, stopping at a shut door. Steer by
   script if Studio's keys don't reach the game.
**Acceptance:** check green; the pin at `c9f6667`; in Play the car drives and stops at a shut door
with no put-back, logged; the phone stick and friends' view go to `OWNER.md`.
**Read first:** `docs/ROADMAP.md` (grep "F-G1b3c2"); `../engine/docs/modules/Driving.md`;
`../engine/docs/modules/Handling.md`; D-252 (grep "^## D-252" docs/DECISIONS.md); the RC car's
code (grep above).

## Queue (next sessions, the owner's ticket order)
1. F-G1b3c2d the driver's body, then F-G1b3c3 the collector steals the car (ROADMAP); then
   F-G1b4 the hard hat on your head. F-G1b5 (skates, slippers) waits for their art.
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
   the save's "best floor" still 0 after a ride, S1-07a to S2-07b2 leftovers, box words (D-215);
   opening a box in Play logs rbxassetid://92259888500166 failing 27 times (not in the place's
   instances or our source: find what plays it).
7. F-G1e pressing the wind-ups and squishies (ROADMAP), when the owner slots it in.
8. Two Studio windows of Brix's dev place (`dev-drive.rbxl`, `dev-drive2.rbxl`) are open and can
   be closed; never the "Storage" window.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
