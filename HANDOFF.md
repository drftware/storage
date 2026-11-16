# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-16, session 218 (the RC car sees in the dark) · **Checks:** green · **Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage); Brix pinned at `c9f6667`.

## State
- F-G1b3c2e is done (D-257): driving into a dark hall, the hood view clicks and flickers over to
  grainy green, a lamp only your screen has lights 30 studs ahead, and monsters' eyes shine as
  two pale points (`Finds/Infrared`, `InfraredView`). A lit hall light's pool, a unit with its
  door up or the elevator's lamp gives colour back the same way; Back is colour at once. Your
  torch is put away while you drive (FlashlightView's `away`) and lit again when you're back.
- Seen in Studio Play: all of the above in the dev hall and on the laid floor with a Mannequin.
  Not run: a phone, a friend's view (OWNER.md, the RC car's steps 8-9).
- Found and fixed on the way: a streamed-out elevator's lamp read as sitting on the dev hall
  (STUDIO.md, the RC car's section). Positions are now read when used.

## Next task: F-G1b3c3 The collector steals the car
The moment: you're nosing the car down a dark hall, the Packrat's pale hands close round it, the
view lifts off the floor, shakes, cuts to static, and you're back in your own eyes. The car is on
its pile, there to take back. (Owner, ROADMAP F-G1b3c3; Dandy's World's and Piggy's item thieves.)
This likely won't fit one session: split it in ROADMAP first, e.g. c3a and c3b below.
1. (c3a) The car belongs to its floor: set down into the floor's model, not `Workspace.Driven`
   (`Drives`, line ~479), so a car still out when the elevator leaves is left with the floor.
   Decide what the transmitter does when its car is lost (default: it stays a transmitter that
   drives nothing until its car is back in hand; an OWNER.md line).
2. (c3a) A friend picking the car up ends your drive too.
3. (c3b) The Packrat sees a car out on the floor as a find lying loose (`Keepers`' `tellLying`,
   `tookFind`, `laidFind`, lines ~1180-1300) and takes it as it takes any; the drive ends.
4. (c3b) On the driver's screen: the view lifts, shakes (CameraShake), cuts to the feed's snow
   (`Feed.Snow`, `Feed.InSound`) and your view is home. Friends see it carried off.
5. (c3b) Taken back from the pile with the transmitter in hand, as walking to it does today.
**Acceptance:** check green; in Play a car left out when the gate shuts is gone with the floor; a
Packrat sent at a car (StandPackrat, STUDIO.md) takes it with the lift, shake and static on the
driver's screen, lays it on its pile, and it can be taken back.
**Read first:** `docs/ROADMAP.md` (grep "F-G1b3c3"); D-179 and D-180 (grep "^## D-179\|^## D-180"
docs/DECISIONS.md); `src/server/Drives.luau`; `src/server/Keepers.luau` lines 1180-1300; CODEMAP
rows for Slots and FeedView; STUDIO.md "Testing a drop in front of a hunting Packrat".

## Queue (next sessions, the owner's ticket order)
1. F-G1b4 the hard hat; F-G1b5 waits for its art.
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
7. While you drive, your torch is still on in the game's rules, tested from your head along
   where the hood looks, though friends see it held at the floor (D-257). Make the rules match
   what's seen (aim it at the floor while driving) or put it to the owner.
8. Small (ROADMAP lists them): the RC car's polish (buttons hidden while driving, Ackermann,
   the aerial telescoping, the view's transmitter grip, infrared's bonnet and hiss); the lamps
   going out, the finds' press sounds and hand, the monkey and toy car's polish; B-05b2b's box
   round the bend; L-08e3c, L-14b2d wait; S3-04b's polish; Free Everyone's swap sound; `sell*`
   Config warnings, a dropped find bumps a walker (D-182), the save's "best floor" still 0
   after a ride, S1-07a to S2-07b2 leftovers, box words (D-215); opening a box in Play logs
   rbxassetid://92259888500166 failing 27 times; Play logs rbxassetid://203785492 "Asset type
   does not match" six times (find what loads it).
9. F-G1e pressing the wind-ups and squishies (ROADMAP), when the owner slots it in.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
