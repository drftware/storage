# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-09, session 59 · **Checks:** green · **Git:** `main`, local only (no remote).

## State
- **L-06b2a is done** (D-069): open or slam a door and the Mannequin walks the halls to stand
  square in front of it, facing it, for 5 s, walks back and goes still mid-stride. Verified in
  Studio on the walked floor: an open 40 studs off and one 79 studs round a corner brought it the
  shortest way (every sample on the halls); one 86 studs off straight but 116 along the halls
  left it still. Phone feel and two players are the owner's (`OWNER.md`).
- **The brain:** pure `src/shared/Keeper.luau` (Asleep, Going, Waiting, Returning; `hear`
  measures along the map; `step`), rows in `src/shared/KeeperRows.luau` (the Mannequin: top 0.9
  of your run, looks at half that, hears as far as you, lingers 5 s, no abilities), run by
  `src/server/Keepers.luau` on the Host's clock: `add` per laid floor (its map kept in step by the
  new `Doors.changed`), `stand`, `remove`, `hallOff`. `tests/keeper.spec.luau`: 20,000 checks.
- **Dev:** "Stand one" in the walked floor's lobby stands a Mannequin 60 studs down the halls.
  Output traces what it hears and does in Studio; each body carries `KeeperState`.

## Next task: L-06b2b Dealt keepers join
The moment: you lift a door and something is standing in there, still, or already turning to you.
1. Owner test results first, if pasted.
2. Read the GDD's doors section ("What's behind") and keepers section (docs tools) for how a
   dealt keeper sleeps and wakes; Granny and the GDD are the precedent, nothing invented.
3. `Keepers` takes `deals.dealt` (look Deals up in `start`): for an Asleep or Awake contents,
   stand the row named `contents.keeper` at `place` on that unit's floor (`floorOf`), facing as
   placed. Asleep: in its shop pose, listening. Awake: up and looking (decide what "looking" is
   before L-06b3's hunt: likely it goes to look at its own door's front once the door is all the
   way up, which `Doors.changed` says).
4. How a dealt keeper wakes: inside a unit it hears nothing while its door is down (D-069).
   Choose with the GDD (its door all the way up? the noise of the open once it's up?), record it
   in DECISIONS, and list the default in `OWNER.md`.
5. `Deal.open`'s `awake` from the brain (a `Keepers` count of keepers awake on that floor) in
   place of `Deals`' `awakeOn` tally; the cap (`Deal.awakeCap`) is unchanged.
6. Lune checks on any pure part (a keeper's wake rule in `Keeper`); in Studio on the walked floor
   (`DevFloorSeed`/`DevFloorNumber`), open units until Output prints a keeper dealt and watch it.
**Acceptance:** checks green; in Studio a dealt keeper stands at its place as its door lifts,
asleep ones still until the chosen wake, awake ones look; `Deal.open` sees the brain's count.
**Read first:** ROADMAP L-06b2b; DECISIONS D-069; `src/server/Keepers.luau` (header, `add`,
`stand`); `src/server/Deals.luau` (Grep `dealt`, `awakeOn`); `src/shared/Deal.luau` (Grep
`Situation`, `awakeCap`); the GDD's doors and keepers sections (docs tools).

## Queue (the next run's order, from ROADMAP)
1. L-06b2b, L-06b3, L-06b4 (D-064, D-068, D-069); L-12c needs L-06b. Then L-14; L-07 to L-10.
2. **Check, small:** Climb down or Drop down while lying behind a sawn hole (a small unit) slides
   your body across the hole on the way to the edge; refuse it there or go round.
3. **Look, small:** from a friend's view, dropping in from behind the hole lunges you toward the
   door before your legs go down; the landing crouch dips your feet 0.2 under the floor.
4. **GDD, small:** its ladder line still says open mesh tops you run across (D-058/D-059); fix it.
5. **Check, small:** lying at a unit's front, are that door's own buttons (Open, Slam) in reach
   from the tops? If so, refuse them for crawlers (`Ladders:crawling` says who's up).
6. **Check, small:** up top, switching to a two-handed tool in your other slot (the ladder) would
   put it on your shoulder while you lie; refuse it for crawlers ("Not up here").
7. **Bug, small:** FlashlightView's `motor()` takes only `Motor6D`, but players' shoulders here
   are `AnimationConstraint`s (docs/STUDIO.md), so a friend's torch arm likely never raises.
8. **Bug, small:** DoorSounds' first slam of a session lands up to 0.35 s late; swap its
   `preload` for `SoundPrimer.prime` (one call) and check the first slam in Studio.
9. **Check, small:** G is a door's Slam and a tool's Drop: at an open door, tool in hand, which?
10. L-06b's keepers hear doors (done), the keypad, a dropped tool, the saw (`kind`), a crawl, the
   ladder and a drop in (D-059, D-066), and see a torch. The map already keeps them off the tops.
11. **Check:** Output's "rbxassetid://203785492 ... Asset type does not match" (six per Play) and
   "rbxassetid://139561946838090 ... content representation is being generated" (about thirty
   on reaching the walked floor); neither id is in our code, templates or the place's services.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
