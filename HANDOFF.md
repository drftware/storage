# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-14, session 128 (S1-07a Padlocked doors) ·
**Checks:** green · **Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage).

## State
- **S1-07 is split** (no battery art; a battery means nothing until the flashlight runs down):
  S1-07a built (D-140), S1-07b batteries waits for S1-09 and is built right after it.
- **S1-07a:** a padlocked unit always holds a find (7 in 10) or a tool, and about 3 in 10 have a
  monster standing in there with it (`Contents.beside`, `Deal.keeperIn`); tools are about one
  unit in twelve (Build's tool odds 20 to 6). No new draw: nothing a seed lays moved (deal.spec
  pins a fingerprint); what doors deal did (stuffdeal.spec's fingerprint retaken). `Deals` lays
  the keeper behind the bulb clear of the find, `Dealt.keeper` its spot; `Keepers` stands it.
- **Seen in Studio Play** (dev floor, floor 3, seed 7): cut and opened all five padlocked units by
  their Open prompts. Output: `Deals: Unit305 held a find, the Television, the Mannequin standing
  with it, asleep and 1 coins`, `Keepers: the Mannequin stands in Unit 305, asleep`, `Recording:
  doorOpened 1 (floor 3, gave find)`; 320's Boombox with an awake one that chased. Seen in 305:
  the TV in the bulb's light, the Mannequin right behind it. All five drew one by chance (30%).
- Studio left in Edit, `DevFloorSeed` 7, place not saved by me. The GDD (D-127, D-128) is the
  newer word; ROADMAP Phase 2 is its build order.

## Next task: S1-08 Tools wear out
The moment: your bolt cutters bite through a third padlock and snap, and you feel the loss;
a glance at your slot always told you it was coming.
1. Read ROADMAP S1-08 and the GDD's "Tools wear out" (docs tools, search "wear").
2. Uses per tool as data in `Tools.Catalog` (bolt cutters 3 padlocks, the saw 2 holes, the air
   horn 3 blasts, the padlock 1 door; the ladder, bubble wrap and flashlight as the GDD says).
   Uses left live on the server with the held tool (Slots), never trusted from a client.
3. Each use spends one where it happens today (`Slots:spend` in Doors' Cut and Lock, Saws, the
   horn, Wraps). At none left the tool breaks in hand with its own sound and motion, and the
   slot empties; it never just vanishes.
4. A mark on the slot in the inventory wheel (`ToolView`, `Tools.Wheel`) shows the uses left,
   readable at phone size, no words (AGENTS: no rule-explaining text).
5. Lune: the pure part (uses, spending, breaking) in a spec. Studio Play: cut padlocks with one
   pair of cutters (bolt cutters lie in Unit 323 on the dev floor; padlocks on 305, 320, 329,
   330, 336; recipe in `docs/STUDIO.md` "Opening a unit so it deals") and say what's seen.
**Acceptance:** checks green; uses proven in a spec; a tool breaking seen in Play.
**Read first:** ROADMAP S1-08; GDD (search "wear"); `src/shared/Tools/Catalog.luau`;
`src/server/Slots.luau` (`spend`, `lay`); `src/client/ToolView.luau`; `src/shared/Tools/Wheel.luau`.

## Queue (the overnight run, owner Nov 13: sessions until 8:30am, the updated plan)
1. S1-08 (next), then S1-09 The flashlight runs down, then S1-07b batteries, then ROADMAP Phase 2
   in order. S2-06 and L-08e3c wait on `OWNER.md`. Lobby polish waits.
2. Found S1-07a: the GDD says the three in ten units without coins hold nothing to take; today a
   unit's kind is drawn apart from its coins, so about 16 in 100 hold nothing at all. Owner's
   call if it matters; not changed.
3. Found S1-02: in Studio the test hall begins a climb on floor 3 as the server starts, so Studio
   records "climb floor 3 started" before any lobby car (Studio only). An onboarding funnel and
   the trip carrying the lobby join time are listed under S1-02 in ROADMAP.
4. Found S1-06: a kept find's save write and the friends' spark are unseen in Play; a "New" mark
   on a find kept the first time is polish (ROADMAP).
5. Found S1-05: the finds' places in your view (moved after one look) are unseen in Play; a find
   standing in a unit can be walked through (inert, as a lying tool; polish list).
6. Found S1-04b2: keepers move on their own map and don't know about stuff, so one could walk
   through it; the heap's front reaches 7.2 into an M unit. A player can likely jump onto it.
7. Found S1-04b1: the stacks' boxes all wear the same few marker words (polish list).
8. Found S1-01: arriving on another server, the save claim may wait up to 5 s if the lobby's
   let-go lands after you. If too slow, a Brix ticket in neutral terms.
9. Found L-08e3b: a lobby car's `far` isn't cleared when its trip fails (it ages out); L-08e4b1:
   no PlayerModule in PlayerScripts, so WatchView's `controls` lookup fails quietly (untested).
10. Seen (owner, Nov 12, "fix them later"): lobby car floors splotchy inside; a sawn side or top
   flashes see-through as its panel drops; the lobby car's lamp very dim.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
