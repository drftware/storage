# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-17, session 232 (the mirror test, S5-03b) · **Checks:** green · **Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage); Brix pinned at `482368f`, NOT on Brix's `origin` yet (push Brix first, OWNER.md).

## State
- The home (D-259; the Claude Doc https://claude.ai/artifact/EUdGarQ2sEiUC6BU5E7Tww, docs tools
  only) is built a ROADMAP piece a session (S5-03): ground floor, fronts, starter sets, switch,
  a home each handed out as you join (D-275), the hard hat on your head (D-277).
- S5-03b (D-280): every home has a mirror leaning on its left wall by the rug (`Home.mirror`,
  plain parts for the test). `MirrorView` puts a ViewportFrame on its glass holding a world
  built behind it: the room copied once, the door, lamps and switch each frame, each person near
  posed each frame with left and right swapped (`Shared.Mirror`'s maths, `tests/mirror.spec`).
  Your camera looks square into the glass and the picture is cut to it, so it's a window onto
  the reflected world. One mirror at a time: live within 24 studs and on screen, still within 70.
- Checked by numbers in Studio Play: copies within 0.002 studs of their reflections, your right
  hand's reflection on your right, the copy's head facing back out. The picture itself was NOT
  seen: Studio drew at 15 frames a second and every screenshot timed out. The owner's look (and
  the phone's frame rate in front of it) waits on OWNER.md; if it doesn't convince, a fix goes in
  ahead of S5-03f.
- Still over the triangle default: the cars' 51k, ticketed as S5-03a2d.

## Next task: S5-03c The shelf and the chest (the owner's order, D-259)
The moment: you come home from a climb and the find you carried lands on your shelf with a
sparkle; a kind you've never owned chimes and turns. Precedent: Animal Crossing's museum and
house storage, Lethal Company's ship shelf. It's big: split it in ROADMAP first (likely c1 the
shelf and finds landing on it, c2 the job box and its panel) and build only the first part.
1. Read ROADMAP S5-03c (grep "S5-03c The shelf") and D-251 (grep -n "^## D-251"
   docs/DECISIONS.md). Read the plan doc's ideas 6 to 9 only (docs tools, search by heading; its
   "What you decided (Nov 16)" wins).
2. Split S5-03c in ROADMAP. Build the shelf's art the unit's way (`art/home`, `art/unit/README.md`):
   6, 10, 16, 24 spots by unit size; the small unit's 6 now.
3. Finds that come home land on its spots (the server owns which, saved in the profile's finds),
   sparkling until you walk up; a never-owned kind chimes and turns. Every action answers.
4. Judge at Galaxy A16 size in Studio Play. OWNER.md: the owner's look, exact steps; defaults.
**Acceptance:** check green; in Studio Play a find carried home stands on your shelf with its
sparkle, and stays there after a rejoin.
**Read first:** ROADMAP S5-03c; D-251; the plan doc's ideas 6 to 9; `src/shared/Home/init.luau`
(`Home.piece`, `Home.mirror`); `src/server/FrontOffice.luau` (the homes); `art/unit/README.md`.

## Queue (next sessions, the owner's ticket order)
1. S5-03d-h; S5-03a2d the cars' hidden triangles; F-G1b4a2 the headlamp's beam (ROADMAP Step 4);
   F-G1b4b the hat spent (also: start its minute when a hat worn at home leaves the ground floor).
2. F-G1b5 waits for its art. Brix: ENG-25b's two-client run (OWNER.md's home test covers it).
3. Brix ticket: Driving's stick read needs `PlayerScripts.PlayerModule`; fall back to the
   camera-turned `Humanoid.MoveDirection` as `input` does (D-254). Built in `../engine`.
4. S4-02 monsters by lowest floor, S4-03 the elevator's choice, S4-04 trapping pays, S4-05.
5. The item catalog doc and the design doc's finds section need D-250, D-251, D-259 and D-277.
6. Once the owner's real purchase passes: mark Brix's ENG-23e done in `../engine`'s HANDOFF.
7. Spread late arrivals off `ClimbEnd.spot`; the driving torch's rules vs what's seen (D-257);
   Play logs assets 92259888500166 and 203785492. The front office's counter and shelves are
   still the climb's steel. The lobby's cart seats (`Cart1.RideSeat`) didn't seat a server
   `Seat:Sit` in a quick try (S5-03a2b4). A spare home lifted from inside stays unpadlocked
   until someone holds it and leaves (D-275). The worn hat's first-Wear dark screen (STUDIO.md):
   if it comes back, make `FindUseView` re-read a tagged model whose key arrives late.
8. The mirror once seen: if the picture spills past the glass, a ViewportFrame larger than its
   SurfaceGui isn't being cut; clip it in a Frame or a CanvasGroup. The finds session's work
   (D-278, D-279) was left uncommitted in the shared checkout, not staged here.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
