# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-16, session 217 (the RC car's driver) · **Checks:** green · **Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage); Brix pinned at `c9f6667`.

## State
- F-G1b3c2d is done (D-256): while you drive, every screen (yours too) crouches your body on
  its heels over the transmitter, left hand round its grip, right on its wheel, aerial up past
  your bowed head, torch at the floor (`DriverBodies`, `Drive.Crouch`, eased with a rustle).
  Your own body shows only while your view is on the car, so the hood sees you when you drive
  back. With its car out, the transmitter is held by its handle (Drives' `regrip`). Caught, the
  server ends the drive and your view leaves the hood before the lunge (DriveView's `leave`).
  Driving it back to your feet, once it's been 4.5 studs away, takes it back (`Drive.home`).
- Seen in Studio Play: the crouch from outside and from the hood after a U-turn; root still;
  driven home from 11 studs ("driven home"); a hand-made catch ended the drive ("caught").
  Not run: a friend's view, a phone, a real keeper's catch (OWNER.md, the RC car's steps 5-7).
- Your own torch is held to your view, so while you drive it sits on the hood and would light
  the hall like a headlight: F-G1b3c2e step 6 hides it.

## Next task: F-G1b3c2e The car sees in the dark
The moment: you drive out of a lit hall into a dark one, the view clicks over to grainy green,
and at the edge of what it shows two white eyes look back. (Owner, D-255.)
1. Your torch off the hood first (ROADMAP step 6): hide `Workspace.YourFlashlight` and its light
   while DriveView's `viewing()`; back as it was when your view is home.
2. Lit or dark near the car: find where the lit state lives (`MotionLights`, `HallLights`,
   `UnitLights`, `Breakers` in CODEMAP) and judge it at the hull each few frames on the client.
3. Infrared where dark: a ColorCorrection (desaturated, green cast, contrast) plus grain on the
   driver's screen only, switched with a relay click and a quick flicker both ways.
4. The lamp only the driver sees: one local light on the hood about 30 studs ahead, fading past
   it; never a light in the game's rules (no Mannequin hold), friends see nothing.
5. Monsters' eyes shine white in it (KeeperView's bodies: a small local glow at each head).
6. Back: your own eyes in full colour at once.
**Acceptance:** check green; in Play the dev hall (dark) shows infrared with the relay click,
a lit hall shows colour, Back is colour at once, a Mannequin's eyes shine; the lamp is a local
light only; the motion-lights decision stays in `OWNER.md`.
**Read first:** `docs/ROADMAP.md` (grep "F-G1b3c2e"); D-255 (grep "^## D-255"
docs/DECISIONS.md); `src/client/DriveView.luau`; CODEMAP rows for MotionLights, HallLights,
UnitLights, Breakers; `src/client/FlashlightView.luau` lines 680-730 (your torch at your view).

## Queue (next sessions, the owner's ticket order)
1. F-G1b3c3 the collector steals the car (it lives in `Workspace.Driven` today, so it would
   outlive its floor); then F-G1b4 the hard hat. F-G1b5 waits for its art.
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
7. Small (ROADMAP lists them): the RC car's polish (buttons hidden while driving, Ackermann,
   the aerial telescoping, the view's transmitter grip); the lamps going out, the finds' press
   sounds and hand, the monkey and toy car's polish; B-05b2b's box round the bend; L-08e3c,
   L-14b2d wait; S3-04b's polish; Free Everyone's swap sound; `sell*` Config warnings, a dropped
   find bumps a walker (D-182), the save's "best floor" still 0 after a ride, S1-07a to S2-07b2
   leftovers, box words (D-215); opening a box in Play logs rbxassetid://92259888500166
   failing 27 times; Play logs rbxassetid://203785492 "Asset type does not match" six times
   (find what loads it).
8. F-G1e pressing the wind-ups and squishies (ROADMAP), when the owner slots it in.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
