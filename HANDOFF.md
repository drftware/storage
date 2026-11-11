# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-10, session 83 · **Checks:** green · **Git:** `main`, local only (no remote).

## State
- **L-07b done (D-096): the wrap you can see and hear.** Kept, you stand in a cloudy cocoon of
  stretch film (`art/keptwrap`, `Props.KeptWrap`), fitted by pure `Kept.fit` to your body at rest
  and welded on by `KeptPlayers` at the move, off as you're let out; never drawn on your own
  screen (`CaughtView`). `KeptSqueal` plays a tape's screeching peel on every screen as anyone's
  `Kept` attribute turns on: close for you, from where you stood for friends.
- Its alpha blends only above 0 part Transparency (`Kept.WrapBlend`); the template is unsaved.
- **Owner, Nov 10:** scarier keeper walk and catch (jump scare, no gore): **L-06c1**, **L-06c2**,
  after L-07e. How does a kept player make noise? Today they can't: L-07c, next.

## Next task: L-07c Banging
The moment: alone in the dark, wrapped, you hammer on the door; down the hall your friends hear
it thud and see which door, and so might a keeper. Precedent: Dead by Daylight's hook (everyone
sees where you hang, and a teammate comes).
1. Owner test results first, if pasted.
2. Pure rules in `Kept` (Lune-tested): how often a bang lands (a cooldown), how long a bang marks
   your unit on friends' screens and the corner map, how far a keeper hears it.
3. Server: a `Remotes.Bang` from the kept player only (type, kept, rate-limited, D-095's held
   player and unit), each one jolting their door (`RollUpDoor.play(unit, "Bang")`, the keepers'
   own bang, so the door's thud and shake come with it), `Keepers:hear` at the door (D-092), and
   a mark on the unit friends' screens read (an attribute with the time).
4. Screen: a big Bang button for the kept player in place of "Wait for a friend" (phone first;
   a key too), each press a kick of the view; friends see the banging door marked for a few
   seconds and the corner map flashes it (`MinimapView`).
5. The hall's light under the door: a thin warm strip where the door meets the floor, from
   inside, only while the hall light outside is on.
6. Torch: keep it working while wrapped (the default); ask in `OWNER.md`.
**Acceptance:** checks green; in Studio on seed 7, floor 1, caught by 157's Mannequin: the Bang
button shows, each press jolts your door (its `DoorMotion` reads Bang) no faster than the
cooldown, a keeper hears it (Output), the unit carries the mark for friends; a spam of presses
from the Client is refused past the rate; the strip under the door shows; Output clean.
**Read first:** ROADMAP L-07c; D-095, D-096; `src/server/KeptPlayers.luau`; `src/client/CaughtView.luau`;
`Keepers:hear` in `src/server/Keepers.luau` (D-092); Bang in `src/shared/StorageUnit/RollUpDoor.luau`.

## Queue (the next run's order, from ROADMAP)
1. L-07c, then L-07d (cut free), L-07e (the padlock), then L-06c1 (a walk that frightens) and
   L-06c2 (the catch as a jump scare). L-14b2d if the owner asks. Then L-08, L-09.
2. **Small, own session:** cut `MovingBlanket`, `GlowSticks` from `Deal.Tools`/`Deal.Bag` (D-091);
   it reshuffles every seed, so recheck the units `OWNER.md`'s steps name (seed 7, floors 1, 3).
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

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
