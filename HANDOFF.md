# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-14, session 129 (S1-08 Tools wear out) ·
**Checks:** green · **Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage).

## State
- **S1-08 built (D-141), as Minecraft's tools wear:** cutters 3 padlocks, saw 2 holes, horn 3
  blasts (`Catalog` rows' `wear`; pure `Tools.Wear`, `tests/wear.spec.luau`). Uses live on the
  server with each tool (`Slots`, `ToolUses1..3`); `Slots:wear` is called by Doors' Cut, Saws'
  finish and Horns. The last use breaks it `late` seconds on (`Slots` `shatter`): thrown from the
  hand with its snap and bits, clank, fade; ToolBroke tells your screen (ToolView: the view model
  shakes and falls away, CameraShake kick, the box bursts red and shrinks). Notches along the
  foot of the box and wheel slots, the last red and breathing. The horn's last blast sags and
  dies (`Horn.Dry`, HornView). Padlock and bubble wrap carry no wear (used up whole as placed).
- **Seen in Studio Play:** the four notch rows (12 notches) built, the ToolBroke remote up, no
  errors on load. **Not seen:** a cut or a break; my MCP pick-up of the cutters didn't take
  (recipe and gotchas in `docs/STUDIO.md` "Driving a tool from the MCP"). Owner steps in OWNER.md.
- Studio left in Edit, `DevFloorSeed` 7, Unit 323 opened in that Play only (not saved).

## Next task: S1-09 The flashlight runs down
The moment: deep in a dark hall your beam starts to flicker, and you know you've got half a
minute to find a battery or a friend before you're in the dark.
0. First (cheap, 2 to 4 calls): see S1-08's break once in Play if the STUDIO.md recipe gets the
   cutters into your hand (stand beside them, wait 1 s); else leave it to the owner.
1. Read ROADMAP S1-09, the GDD (docs tools, search "runs down") and OWNER.md's "The flashlight's
   details" (defaults: about 5 minutes of light, drains only while on, full at each climb's start,
   carries over between floors, flicker for the last 30 s, then out).
2. Charge as a pure module (drain while on, the flicker window, empty) with feel numbers in
   shared config and a Lune spec; the server owns the charge (`Flashlights`), every screen reads
   it from an attribute, never trusted from a client.
3. A meter on the flashlight's button (`FlashlightView`), readable at phone size, no words; the
   beam flickers for the last half minute (motion and sound), then goes out with a click; the
   button refuses while empty (a dull click, no text).
4. Batteries are S1-07b, next after this: leave a `fill` on the server for them.
5. Studio Play: drain it fast with a Studio-only dev number and say what's seen.
**Acceptance:** checks green; drain and flicker proven in a spec; the flicker and going out seen
in Play.
**Read first:** ROADMAP S1-09; GDD (search "runs down"); OWNER.md "The flashlight's details";
`src/shared/Flashlight/init.luau`; `src/server/Flashlights.luau`; `src/client/FlashlightView.luau`.

## Queue (the overnight run, owner Nov 13: sessions until 8:30am, the updated plan)
1. S1-09 (next), then S1-07b batteries, then ROADMAP Phase 2 in order. S2-06 and L-08e3c wait
   on `OWNER.md`. Lobby polish waits.
2. Found S1-08: broken-piece art (the cutters in two halves) and a strained creak on the use
   that leaves one are in ROADMAP's S1-08 polish line.
3. Found S1-07a: the GDD says the three in ten units without coins hold nothing to take; today a
   unit's kind is drawn apart from its coins, so about 16 in 100 hold nothing at all. Owner's
   call if it matters; not changed.
4. Found S1-02: in Studio the test hall begins a climb on floor 3 as the server starts, so Studio
   records "climb floor 3 started" before any lobby car (Studio only).
5. Found S1-06: a kept find's save write and the friends' spark are unseen in Play; a "New" mark
   on a find kept the first time is polish (ROADMAP).
6. Found S1-05: the finds' places in your view are unseen in Play; a find standing in a unit can
   be walked through (inert, as a lying tool; polish list).
7. Found S1-04b2: keepers move on their own map and don't know about stuff, so one could walk
   through it; the heap's front reaches 7.2 into an M unit. A player can likely jump onto it.
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
