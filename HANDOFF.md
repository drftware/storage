# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-07, session 23 · **Checks:** green · **Git:** `main`, local only (no remote).

## State
- **L-02 is done** (D-030): the door is the GDD's state machine in the pure `Door` (closed,
  peeking, opening, lifting, open, closing, slamming, locked; 327 Lune checks), run by the server's
  `Doors` system on the Host clock, which replaced `DoorPrompts`. A door shows only the buttons its
  state allows, side by side in fixed places (`Door.Slots`, 150 px apart), Lift just inside while
  it's down; every press is checked for reach, side, tools and rate. A padlocked door tried
  rattles (a new `Rattle` door motion plus Pro Sound Effects "Door Shake 4") and says "Padlocked";
  bolt cutters (Cut, held 1 s) take the padlock off. Events fire `Doors.acted` with their reach.
- **Tools are a stand-in:** a player's `CarriesBoltCutters` / `CarriesPadlock` attribute. The test
  hall's "Test tools" post right of the spawn toggles bolt cutters (R). No Lock button on doors;
  the padlock tool will call `Doors:lock`.
- **Verified in Studio** (one player, pressing buttons from the Client view; Output clean but the
  known `203785492` lines): 101's buttons through open, slam, peek and close; nothing shown
  mid-slam or mid-lift; 105 rattles (0.1 studs of give, the sound plays, "Padlocked"); Cut
  without cutters refuses as the hold starts; with them the padlock pops; slam yourself in from
  inside, Lift out; padlocked inside, Lift rattles; all 82 units (test hall and laid floor) get
  their buttons; Peek and Open show 150 px apart, centred. Not tested: two players, a phone,
  the range and rate checks against a forged press.
- `rojo serve` runs on port 34872; Studio in Edit, Quality on Automatic, Device Simulator off.

## Next task: L-01d The floor laid for the saw and the ladder
The moment: a friend saws through to the next unit and crawls out of reach, or climbs onto the
tops and runs a row while the keeper below loses them. The owner asked (Nov 7) that the layout
make this work before the tools are built. Data and checks only: no tools this ticket.
1. Owner test results first, and their answer on holes and tops (`OWNER.md`, "Decide"); without
   one, the default: holes between side-by-side neighbours only, tops run along a row.
2. Read the GDD's "The hole trap" and the Tools table (saw, ladder): only those.
3. Measure first: over 400 seeds, how many neighbour pairs a floor has, how many units stand cut
   off between plain walls, how long the top runs are. Print it; pick limits from the numbers.
4. In `Floor`, Lune spec first: each unit's neighbours (left, right, back: a unit, a plain wall
   or nothing) and the top runs; rules so floors 1 and 2 have neighbour pairs in the first hall
   from the lobby (the GDD: they teach the hole trap) and every floor has enough; a plain-wall
   slot marked closed on top so a run doesn't drop into it.
5. `scripts/floor-map` shows the crawl links and the top runs; `FloorBuilder` closes the top of a
   plain-wall slot if the unit's wire top is a part it can reuse, else ROADMAP gets the art step.
**Acceptance:** checks green; the spec covers the neighbour and top rules over many seeds; maps
show both; numbers and what to judge in `OWNER.md`.
**Read first:** `OWNER.md` ("Decide: moving between units"); `docs/ROADMAP.md` (L-01d);
`src/shared/Floor.luau` (header, where slots are made); `tests/floor.spec.luau`;
`scripts/floor-map.luau`; the GDD's hole trap and Tools.

## Queue (the next run's order, from ROADMAP)
1. Then L-04 to L-08, and L-10 (the map) after L-05. L-04 deals contents and which doors start
   padlocked (`Doors:lock(unit, true)`); L-05 adds "flash every light" to `MotionLights` and
   builds the lobby and elevator where `FloorBuilder`'s stand-in is; L-06's keepers hear doors
   on `Doors.acted` (each event's `reach`); L-08 lays the next floor during the ride.
2. **The ladder** (GDD tools): a wire top leaves 2.8 studs under the joists (`OWNER.md`).
3. **Polish waiting** (ROADMAP): a door answering before the server's word; tool buttons per
   player; the cutters' snip; a lifted door's grace; a laid floor's draw cost on a phone; the L
   unit; the bolt and padlock moving; a shut door muffling sounds; a less-shake setting; a sound
   mix; a lit tube's hum; fading a far pool; the kit's texture copies; cheaper chain links; a red
   glow round a Seen eye; a haze edge; a client-side door collider; the padlock too small; the
   cursor hint once ever; the junctions' overlapping decks seen from a unit.
4. Studio traps (docs/STUDIO.md): a prompt triggers from the MCP only while the camera faces it;
   captures don't draw prompts; annotate locals of another module's string unions.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
