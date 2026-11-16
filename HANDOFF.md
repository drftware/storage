# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-16, session 216 (driving the RC car) · **Checks:** green · **Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage); Brix pinned at `c9f6667`.

## State
- F-G1b3c2c is done (D-254): Drive sets the RC car down in front of you off its transmitter
  (its parts move into their own model on a frictionless hull; the transmitter stays in hand),
  your view swoops onto its hood (88 degrees), and Brix's Driving runs it from your device with
  the server checking every move. The stick comes from `Humanoid.MoveDirection` (Brix's default
  read gives nothing in this place). A whine rises with speed, the wheels turn and steer, the
  springs lean, a bump or put-back jolts the view. Back is jump, B, Backspace or the Back button;
  walking to it with the transmitter in hand takes it back.
- Seen in Studio Play (steered by the Studio-only `DriveStick` attribute): set down, 0 to 16
  studs a second in 0.4 s, stopped dead at a shut door with no put back, Back, taken back. Not
  run: into an open unit (dev-hall doors all shut), phone, a friend's view (OWNER.md).
- The dev hall is unlit, so the hood view there is black: OWNER.md asks about a headlight.

## Next task: F-G1b3c2d The driver's body
The moment: you crouch in a unit, transmitter up, antenna raised, watching the hall through
the hood; a friend sees you hunched over it; a monster finds your body and the drive cuts out.
1. While you drive, your body crouches still with the transmitter held up in both hands, its
   antenna up (find the transmitter's parts: `Drive.carParts` gives the car's; the rest stay).
   The peek's crouch may serve: `Kneel`, `Kneels`, `KneelView` (grep CODEMAP for "Kneel").
2. Caught (the game's caught state, `KeptPlayers`/`Caught.luau`): the drive ends on the server
   (`Drives.endDrive`), the view snaps back with the catch's own feedback.
3. Driving it to your feet takes it back (`Drive.takes` while driving, from your body's feet).
4. Friends see it drive: check the whine and wheels on a second client (Studio's two-player
   test if it runs; otherwise OWNER.md steps).
**Acceptance:** check green; in Play your character crouches with the transmitter while
driving and stands back up after; a caught driver's drive ends; driving to your feet takes it
back, logged; the phone stick and friends' view in `OWNER.md`.
**Read first:** `docs/ROADMAP.md` (grep "F-G1b3c2d"); `src/server/Drives.luau`;
`src/client/DriveView.luau`; D-254 (grep "^## D-254" docs/DECISIONS.md); CODEMAP's Kneel rows.

## Queue (next sessions, the owner's ticket order)
1. F-G1b3c3 the collector steals the car (ROADMAP; the car lives in `Workspace.Driven` today, so
   it would outlive its floor); then F-G1b4 the hard hat. F-G1b5 waits for its art.
2. Brix ticket: Driving's default stick read requires `PlayerScripts.PlayerModule`, which places
   on Roblox's Input Action System lack; fall back to `Humanoid.MoveDirection` turned by the
   camera, as this game's `input` does (D-254). Built in `../engine` by its rules, then the pin.
3. S4-02 monsters by lowest floor (its plan is in ROADMAP), then S4-03 the choice on the
   elevator's buttons, S4-04 trapping pays (5 coins a trapped monster), S4-05 the big find.
4. The item catalog doc still says "at home" for the six lamps and the RC car; `WAVES.md` has
   the new lines (D-250). The catalog's hard hat, skates and slippers and the design doc's
   finds and home sections need D-251. Bring both in line when they're next opened.
5. Once the owner's real purchase passes: mark Brix's ENG-23e done in `../engine`'s HANDOFF.
6. Trips stands every late arrival or respawn on the one arrival spot; two at once overlap
   until physics pushes them apart. Spread them (`ClimbEnd.spot`) as the carry's fallback does.
7. Small (ROADMAP lists them): the RC car's polish (buttons hidden while driving, Ackermann);
   the lamps going out, the finds' press sounds and hand, the monkey and toy car's polish;
   B-05b2b's box round the bend; L-08e3c, L-14b2d wait; S3-04b's polish; Free Everyone's swap
   sound; `sell*` Config warnings, a dropped find bumps a walker (D-182), the save's "best
   floor" still 0 after a ride, S1-07a to S2-07b2 leftovers, box words (D-215); opening a box
   in Play logs rbxassetid://92259888500166 failing 27 times; Play also logs
   rbxassetid://203785492 "Asset type does not match" six times (find what loads it).
8. F-G1e pressing the wind-ups and squishies (ROADMAP), when the owner slots it in.
9. Two Studio windows of Brix's dev place (`dev-drive.rbxl`, `dev-drive2.rbxl`) may still be
   open and can be closed; never the "Storage" window.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
