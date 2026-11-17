# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-17, session 240 (taking a find out of the job box, built, D-293) ·
**Checks:** green for the home's files (the checkout is red from the find run's half-done
FairyLights: `StrandView`, `Keepers`, `kitrows.spec`) · **Git:** `main`, committed, not pushed
(`origin` is github.com/drftware/storage); Brix pinned at `482368f`, NOT on Brix's `origin` yet.

## State
- The home (D-259; the Claude Doc https://claude.ai/artifact/EUdGarQ2sEiUC6BU5E7Tww, docs tools
  only) is built a ROADMAP piece a session (S5-03): ground floor, fronts, starter sets, switch,
  a home each, hard hat, mirror, oak shelf with finds, job box, its panel (D-291), and now taking
  a find out (D-293), built and green but not yet seen in Studio.
- S5-03c2b2a: the panel lists what's in the box (`Save.boxed`: owned less the shelf's and what's
  out). Tap a card: it lifts and glows, Take (and Shelf while a cubby is free) over its name; your
  three hands sit as round wells over the panel's corner. Take: the picture rises, `JobBoxTake`
  is asked, and on `JobBoxTook` it flies in a bow into the hand (InFlight holds your view's copy
  till it lands, pick-up sound); Shelf flies up to the cubby (the shelf's tink). Counts tick down;
  hands full shakes the wells; a refusal settles the picture back. Never a word.
- The server never writes the save for a take to hand: Slots marks the find with whose box it
  came from (`unbox`), counts what's out live (`fromBox`), never keeps one at a gate, and recalls
  them when the owner leaves. Shelf: `Save.shelve` (seen) and `Shelves:lay`. Lune:
  `tests/boxpanel.spec` (91 checks) covers boxed, free, canTake, the wire, took.

## Next task: S5-03c2b2b Taking a find out, seen in Studio
The moment: you tap the Boombox card, it lifts and glows, Take; it flies out of the panel into
one of your three hands with its pick-up sound and the x2 goes; Shelf sends the next one up to a
cubby with a tink.
1. Check the checkout first: if `scripts/check.sh` is still red from the find run, check yours in
   a throwaway worktree (STUDIO.md). Confirm Rojo has the new code in Studio (Edit mode).
2. Play. Keep finds with `ServerStorage.ShelfTest:Invoke(player, key)`: seven or more, two of
   one kind, so the shelf fills and the box holds the rest. Open the box from the Client (the
   prompt's `InputHoldBegin`/`End`, a Scriptable camera over it; see the job box notes in
   STUDIO.md).
3. Press for real: `execute_luau` can't fire `Activated`, so click the card and Take with the
   Studio MCP's `user_mouse_input` at screen points (read `AbsolutePosition` from the Client
   first). Watch: the lift, the flight into a hand, the pick-up sound, the count, the find in your
   hand after Close. Then Shelf, then Take with all three hands full. Check Output for errors.
4. Server path alone: fire `JobBoxTake` from the Client with a name you don't own and with a full
   box taken out; each answer is `false` and nothing changes. Leave, rejoin: the box is whole.
5. Capture at half scale with the macOS window capture (STUDIO.md): `docs/art/S5-03c2b2-pick.jpg`,
   `-flight.jpg`, `-shelf.jpg`. Fix what looks wrong (the wells' place on a 1380x761 window, the
   verbs' size on a small card). Tick c2b2b, trim OWNER.md's take item to what you saw.
**Acceptance:** check green for the home's files; in Studio Play a find goes from the panel into
a hand and onto the shelf with its motion and sound, the count updates, refused takes change
nothing, and Output is clean; captures in `docs/art/`.
**Read first:** ROADMAP S5-03c2b2b; D-293 and D-291; `src/client/BoxPanelView.luau` (`takeOut`,
`took`, `fly`, the wells in `start`); `src/server/JobBoxes.luau` (`takeAsked`); STUDIO.md's job box,
window capture and worktree notes.

## Queue (next sessions, the owner's ticket order)
1. S5-03c3 selling and Gold; S5-03d-h; S5-03a2d the cars' hidden triangles; F-G1b4a2 the
   headlamp's beam (ROADMAP Step 4); F-G1b4b the hat spent (its minute starts when a hat worn at
   home leaves the ground floor). S5-03d builds on D-293: a box find is never kept at a gate yet.
2. The home's warm fill (D-290): faces turned from the bulb go near black (D-263: warm all round).
3. F-G1b5 waits for its art. Brix: ENG-25b's two-client run; Driving's stick read needs
   `PlayerModule`, fall back to the camera-turned `MoveDirection` (D-254), built in `../engine`.
4. S4-02 monsters by lowest floor, S4-03 the elevator's choice, S4-04 trapping pays, S4-05.
5. The item catalog doc and the design doc's finds section need D-250, D-251, D-259 and D-277.
6. Once the owner's real purchase passes: mark Brix's ENG-23e done in `../engine`'s HANDOFF.
7. Late arrivals off `ClimbEnd.spot`; the driving torch (D-257); asset 203785492's type error;
   the front office's steel; cart seats vs `Seat:Sit`; a spare home unpadlocked (D-275); the
   hat's first-Wear dark screen; the body unhidden after a respawn (D-282).

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
