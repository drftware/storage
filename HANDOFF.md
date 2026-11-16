# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-16, session 214 (the RC car's handling, built in Brix) · **Checks:** green here and in Brix · **Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage); Brix `main` at `1a97787`, committed, not pushed.

## State
- The owner (D-252): "absolute world-class", and Brix code is written from here when a ticket needs
  a system Brix lacks, by Brix's own rules, then the pin moves. AGENTS.md and `docs/FRAMEWORK.md`
  carry the rule.
- F-G1b3c2 (drive the RC car) is split in four (ROADMAP, D-252). The car is a physics body the
  driver's device moves, so walls and shut doors stop it and friends see it smoothly; the server
  checks every move. F-G1b3c2a is done: Brix's `Handling.car` (its ENG-24a, E-079), throttle and
  steering in with the car's real speed, the speed and turn out; 41 specs, a bench, a module page.
- The pin is still `5cdb8c2`: it moves once Brix is pushed (`OWNER.md`'s new item).
- Earlier today: the lamps switch on anywhere (F-G1b3c1, D-250); worn finds and the home unit are
  designed (D-251: F-G1b4, F-G1b5, S5-03a-c, one question in `OWNER.md`). Find art: F-05e (step
  14) and F-05f (step 15) are left in `art/finds/WAVES.md`.
- F-G1d done (D-253, a side session): the 12 wind-ups and 10 squishies built overnight are dealt;
  seen in Play, the stress ball found, carried aboard and kept. Pressing them is F-G1e.

## Next task: F-G1b3c2b Driving a body from a player's device, in Brix (its ENG-24b)
The moment it serves: the car moves the instant you push the stick on a phone, stops dead at a
wall, and can't be cheated through one. This session works in `../engine` by Brix's rules.
1. Read `../engine/AGENTS.md` and `../engine/HANDOFF.md`: its Next task is this ticket, with steps,
   acceptance and a Read-first list. Follow Brix's protocol there (its HANDOFF untracked, its commit
   with no trailer, ask before pushing).
2. Verify the Roblox APIs first (network ownership, `LinearVelocity` in plane mode,
   `AlignOrientation`, the control module's `GetMoveVector`) and log them in Brix's `docs/STUDIO.md`.
3. The pure move check with specs; then `Roblox.Driving.server` and `Roblox.Driving.client`; then
   Brix's `examples/Driving` run in Studio (a copy of Brix's dev place, never the "Storage" window).
4. Back here: tick F-G1b3c2b, update `docs/FRAMEWORK.md`'s Brix rows, and promote F-G1b3c2c.
**Acceptance:** Brix's check green; the move check's specs; the example driven into a wall stops,
a forced teleport is put back, the driver leaving ends the drive, each logged in Brix's
`docs/STUDIO.md`; this repo's check green.
**Read first:** `../engine/AGENTS.md`; `../engine/HANDOFF.md` and its Read-first list; D-252 (grep
"^## D-252" docs/DECISIONS.md).

## After it: F-G1b3c2c Drive it (needs Brix pushed, then the pin moved)
The car set down in front of you apart from its transmitter, which stays in your hands (the model
is one: `RCCar_Remote` is the root and the car hangs off `RCCar_Arms`, so the car needs its own
assembly); the hood camera low and wide with a jolt on a bump; the stick through Brix, a sideways
push mixing in a little throttle; a motor whine rising with speed; wheels turning and steering;
the back button; walking to it takes it back. Feel numbers in Config. Studio Play: lobby, down a
hall, into an open unit, stopping at a shut door.

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

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
