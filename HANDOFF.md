# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-12, session 105 (L-16d), night run session 6 of 15 · **Checks:** green ·
**Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage).

## State
- **L-16d done (D-118).** Physics steps 60 times a second whatever the screen draws, and your
  body moved only with it, so a computer drawing 120 or 144 held a place, then jumped. LadderView
  now places your own body each drawn frame just before the camera (the "LadderViewPlace" render
  step: ladder, tops, down) and holds it still before each physics step; the crawl over a frame
  is `Tops.advance` (Lune-checked from 15 to 240 frames a second).
- Verified in Studio at 15 frames a second (Studio can't be focused from a script, STUDIO.md):
  every frame moves its share, no server put-backs flat out under no lag, simulated 4G and bad 3G,
  the Galaxy A16 the same, Climb down fine. The full rate and a live server: `OWNER.md`.
- Studio: left in Edit, play stopped, Device Simulator off, network simulator back at 0, nothing
  imported.

## Next task: L-08e1a The front office, built
The moment: you load in and see Everkeep's front office at night, the six freight cars' bays
along one wall, and know at a glance where to go. This session builds the room only (the cars,
joining and the count are L-08e1b; the server trip L-08e1c).
1. Owner test results first, if pasted.
2. Read GDD "The lobby" (docs tools, that section only), ROADMAP L-08e1a and DECISIONS D-112.
3. Read `art/unit/README.md` (how art is made) and `art/elevator/` (`README.md`, `spec.py`): the
   bays must fit the climb's own car and gate exactly, so take their sizes from its spec.
4. Write `art/lobby/` (spec, build, README) the unit's way: front door and glass, the counter
   (dressing), an empty cart rack, six bays on one wall; baked PBR on shared texture sets, an FBX,
   a generated `Specs` module, look sheets. Run `scripts/art.sh`; judge the sheets.
5. Import into the place (STUDIO.md's FBX recipe and importer notes; Roblox_Studio's
   `rbx-import-asset` skill), lay it out on the server from `Specs` away from the test hall, add
   a dev post in the test hall that takes you there, and **save the place** (Studio's save, never
   Publish): the owner is asleep and an import lives only in the place.
6. Light it enough to read on a phone (cap real lights, GDD tech plan); judge on the Galaxy A16.
**Acceptance:** checks green; look sheets in `art/sheets/`; the room in Studio reached by the dev
post, walkable, with the six bays readable at phone size (shots `docs/art/L-08e1a-*.jpg`);
Output clean but 203785492 and the known rbxassethash lines; the place saved.
**Read first:** GDD "The lobby"; ROADMAP L-08e1a; DECISIONS D-112; `art/unit/README.md`;
`art/elevator/README.md` and `art/elevator/spec.py`; docs/STUDIO.md "The FBX recipe".

## Queue (tonight's run order, owner Nov 11 night; ROADMAP Phase 1's order paragraph)
1. L-08e1a (next), then L-08e1b (six cars and the count), L-08e1c (a server of the group's own),
   then L-08e2 to L-08e4 (GDD "The lobby", D-112); split L-08e4 into green-ending sessions too
   (the cart's art script first, then the ride).
2. With sessions left: the Seen fixes below, L-18, then honing tonight's work (ROADMAP polish).
   Never new keepers, no store or paid items, proven mechanics only, never edit Brix.
3. Seen: the elevator's gate cache (`posings`, Elevator/init.luau) is a weak table keyed by the
   car, so it rebuilds after each garbage pass (allocates; works); a ladder stood on a floor
   when it's cleared should go with it (untested); anyone still in the car 6 s after it opens is
   shut in (`OWNER.md`'s L-08a decision 2); watching a friend ride doesn't draw their shaft;
   DevCorridor's "Walk a floor" sign keeps the old floor's number after "Again" (Studio only);
   the ladder can't be knocked flat yet (D-107); tools of a player lost below the world land at
   the world's middle with no Pick up (`Slots.dropAll` with no root drops at `Vector3.zero` and
   the prompt never comes back); FlashlightView's and HornView's screens once stayed on with the
   jump hidden (cause unknown, STUDIO.md); Output lines at Play, "rbxassethash://... Requester
   does not have permission for Asset" (cause unknown); turning right round at a run's end the
   crawl stops for about a third of a second before it moves off (D-110's turn-first rule; judge
   with the owner's L-16d test before changing it).

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
