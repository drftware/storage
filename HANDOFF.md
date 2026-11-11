# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-10, session 84 · **Checks:** green · **Git:** `main`, pushed to `origin` (github.com/drftware/storage).

## State
- **L-07c done (D-097): banging.** Kept, a Bang button comes up in the dark (`CaughtView`); each
  press is `Remotes.Bang`, and `KeptPlayers` bangs your door through `Doors:move` (the trapped
  keeper's thud, shake and hearing, 70 studs along the halls), at most one per 0.4 s. The floor's
  model carries each bang (`Kept.BangsAttribute`): friends see a blue mark with your name over the
  door through walls (`BangMarks`) and a ringing dot on the corner map; a kept friend's own map
  dot is hidden. `UnderDoor` draws the hall light's warm line under your door while it's lit.
- **Owner, Nov 10:** scarier keeper walk and catch (jump scare, no gore): **L-06c1**, **L-06c2**,
  after L-07e.

## Next task: L-07d Cut free
The moment: you reach your friend's unit, lift the door, and there they stand wrapped; you hold
Cut free for a second, the film tears and they stagger out with you. Precedent: Dead by
Daylight's unhook (hold beside the hook) and its freeing a friend from a bear trap.
1. Owner test results first, if pasted.
2. Pure rules in `Kept` (Lune-tested): the hold's length (1 s), who may cut (alive, not kept,
   within reach of the kept player, the unit's door all the way up), what counts as in reach.
3. Server (`KeptPlayers`): a "Cut free" prompt (`Prompts.make`, hold 1 s) on the kept player,
   shown only while their door is all the way up; its trigger validated on the server (the rules
   above) lets them go. Remove L-07a's stand-in: the door going up no longer lets you out.
4. Feedback, same ticket: the film tears (a measured tape-rip sound, as `KeptSqueal`'s was
   found, played at the body for everyone near), the wrap comes off over a beat (not a vanish),
   the freed player's view kicks as they're let go, the cutter's view a small kick too.
5. A friend's held Cut free shows nothing to the kept player beyond the sound; check the prompt
   at phone size (the door's own buttons are near: no overlap).
**Acceptance:** checks green; in Studio on seed 7, floor 1, caught by 157's Mannequin: opening
your unit no longer lets you out; the Cut free prompt shows only with the door up; a trigger
from a kept player or from too far is refused (Output); a valid one lets you out, the film gone
with its sound; Output clean.
**Read first:** ROADMAP L-07d; D-095, D-097; `src/server/KeptPlayers.luau`; `src/server/Prompts.luau`;
`src/client/KeptSqueal.luau` (a measured sound played for everyone); docs/STUDIO.md's "Testing
getting kept from the MCP".

## Queue (the next run's order, from ROADMAP)
1. L-07d, then L-07e (the padlock), then L-06c1 (a walk that frightens) and L-06c2 (the catch as
   a jump scare). L-14b2d if the owner asks. Then L-08, L-09.
2. **Small, own session:** cut `MovingBlanket`, `GlowSticks` from `Deal.Tools`/`Deal.Bag` (D-091);
   it reshuffles every seed; the owner said Nov 10 not to worry about old test steps naming units.
3. **Check, small:** caught crawling or on the ladder, `CrawlView`/`LadderView` may keep holding
   PlatformStand after you're let out. A torch arm raised on a Motor6D rig may poke the film.
4. **Check, small:** a press made the moment you arrive reaches the server while it still sees you
   a few studs back (D-085): Saws, Ladders and a door's Cut and Lock check where you stand; allow
   for it as `Crawling.counts` does if one drops. Server facing is 0.4 s late (D-084).
5. **Checks on the tops, small:** Climb or Drop down lying behind a sawn hole slides you across
   it; a friend's drop-in lands 0.2 under the floor; crawlers should be refused a door's buttons
   and the ladder (`Ladders:crawling`). A horn blown up there is heard from the unit under you.
6. **Bugs, small:** FlashlightView's `motor()` takes only `Motor6D` (shoulders are
   `AnimationConstraint`s), so a friend's torch arm never raises; DoorSounds' first slam lands up
   to 0.35 s late (`SoundPrimer.prime`). HornView now carries every verb tool's button: rename it
   (`UseButton`) when a third tool needs it.
7. **Check:** G is a door's Slam and a tool's Drop: which wins at an open door? A left click
   blows a horn (or lays wrap) even while clicking the slots' bar. Output at Play: "rbxassetid://
   203785492 ... Asset type does not match" (none of ours); "KeeperView: can't move ...
   Mannequin: no such keeper, root or joints" once as floor 1 streamed in (Nov 10), harmless?
8. Keepers should hear the keypad, a dropped tool, the saw, a crawl, the ladder and a drop in
   (D-059, D-066) through `Keepers:hear` (D-092). **Small:** a trapped keeper's every blow prints;
   a crawler's feet as `Wraps` reads them must sit within `Wrap.Under` (3), or crawling won't pop.
9. **Check, small:** a kept player's empty slots bar shows under the Bang button: hide it if cluttered.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
