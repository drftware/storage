# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-16, session 219 (the Packrat steals the RC car) · **Checks:** green · **Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage); Brix pinned at `c9f6667`.

## State
- F-G1b3c3 is done (D-258): to monsters the RC car is where its car is (`Slots.out`); the
  Packrat's hands closing on the car bring the transmitter to it and the whole find goes to its
  pile, taken back with Take. The driver's view lifts, tips, shakes, cuts to the feed's snow and
  hiss, and comes home (`Drive.lifted`). Robbed from a driver's hands, the car comes home first.
  The car lives in its floor's model; at the gate an RC car with its car out isn't kept, and the
  transmitter dies in your hand as the floor below goes (`Slots.lose`).
- Seen in Studio Play: the theft from a roof, the rob from hands, pocketing leaving the car out
  (it used to destroy the car: fixed), the floor destroyed with the car out. Not run: taking it
  back off the pile, a real gate shut, a phone, a friend (OWNER.md, the RC car's steps 10-12).

## Next task: F-G1b4a The hard hat on your head and lit
The moment: your torch stutters out, no battery, the Mannequin two halls off, and you pull the
hard hat on; its tight white beam goes where you look. (Owner, ROADMAP F-G1b4a, D-251;
Phasmophobia's head torch.) F-G1b4b (it running out and breaking) is next, not this.
1. A head place on the character apart from the three slots: the worn hat welded to the head
   as the ladder is welded to the shoulder (`Slots`' `dress`), shown to everyone, and saved
   nowhere yet (it's a find: kept at the gate like one; default, an OWNER.md line).
2. The hat's one word becomes Wear (`Finds/Use.luau`'s `HardHat`, now Switch): it lifts onto
   your head with the shell's knock and the lamp's click, lit, and its slot is free.
3. Its beam: tighter and whiter than the torch's (`FlashlightView`'s own light as the pattern),
   from your forehead where you look, bobbing with your walk; friends see the lamp lit on your
   forehead and its light on the walls.
4. It holds a Mannequin as any found light does: Keepers' `lampOf` stamp, now from the head.
5. Caught (or dying), it drops with everything else, still lit, as a dropped lamp lies.
**Acceptance:** check green; in Play `GiveFind` "HardHat", Wear: it's on your head lit, the slot
empty, the beam where you look; a Mannequin walked into its beam stops; caught, it drops.
**Read first:** `docs/ROADMAP.md` (grep "F-G1b4a"); D-251 (grep "^## D-251"
docs/DECISIONS.md); `src/shared/Finds/Use.luau` (the header and `HardHat`);
`src/server/Slots.luau` lines 405-455 (`dress`, the shoulder weld); `src/server/Keepers.luau`
lines 1150-1180 (`lampOf`); `src/client/FlashlightView.luau` (grep "Beam" for the light).

## Queue (next sessions, the owner's ticket order)
1. F-G1b4b the hard hat spent and broken; F-G1b5 waits for its art.
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
   the aerial telescoping, the view's transmitter grip, infrared's bonnet and hiss, infrared
   through the lift, the car's crackle as it's lifted, the car seen going when its driver is
   robbed); the lamps going out, the finds' press sounds and hand, the monkey and toy car's
   polish; B-05b2b's box round the bend; L-08e3c, L-14b2d wait; S3-04b's polish; Free
   Everyone's swap sound; `sell*` Config warnings, a dropped find bumps a walker (D-182), the
   save's "best floor" still 0 after a ride, S1-07a to S2-07b2 leftovers, box words (D-215);
   opening a box in Play logs rbxassetid://92259888500166 failing 27 times; Play logs
   rbxassetid://203785492 "Asset type does not match" six times (find what loads it).
9. F-G1e pressing the wind-ups and squishies (ROADMAP), when the owner slots it in.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
