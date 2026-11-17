# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-17, session 233 (the mirror seen and fixed, S5-03b) · **Checks:** green · **Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage); Brix pinned at `482368f`, NOT on Brix's `origin` yet (push Brix first, OWNER.md).

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
- Seen in Studio Play (session 233, `docs/art/S5-03b-*.jpg`): it was blank, the lobby's merged
  walls copied in front of the glass. Now `Mirror.keeps` picks what's copied, the unit's walls
  stand in it as plain parts, and it sharpens up close. You, the right way round, your room
  behind you, 60 frames a second. The owner's look and the phone's frame rate wait on OWNER.md.
- The hat you wear is out of your own eye (D-282, `HeadView`): seen in Play, `docs/art/F-G1b4a-own-view.jpg`.
- Still over the triangle default: the cars' 51k, ticketed as S5-03a2d.
- Find art (third find run): V4a built the siren car (D-281: rolls off wailing, its roof light
  lit only while it plays, a 90-stud lure); NOT seen in Play (Studio was busy). Next: V4b, its
  wail measured and the Play check (ROADMAP F-G1e4b, `art/finds/WAVES.md`), then V5a.

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
8. The worn hard hat sits on your chin (seen in the mirror, D-280): `Slots`' head weld seats the
   find's pivot, which isn't at the hat's rim; fit it so the shell sits on your head (F-G1b4a's).
   After a respawn under a held camera, Roblox never re-hid your body in first person (D-282).
   The finds session's work (D-278, D-279) is still uncommitted in the shared checkout.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
