# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-17, session 235 (the shelf's art and its spots in the save, D-284) · **Checks:** green · **Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage); Brix pinned at `482368f`, NOT on Brix's `origin` yet (push Brix first, OWNER.md).

## State
- The home (D-259; the Claude Doc https://claude.ai/artifact/EUdGarQ2sEiUC6BU5E7Tww, docs tools
  only) is built a ROADMAP piece a session (S5-03): ground floor, fronts, starter sets, switch,
  a home each as you join (D-275), the hard hat on your head (D-277, D-283), the mirror (D-280).
- S5-03c split in ROADMAP: c1a (done), c1b, c2 the job box and panel, c3 selling and Gold.
- S5-03c1a (D-284): an oak open shelf, cream back, six cubbies, in every home's starter set behind
  the rug facing the door (`art/home/furnish.py` `shelf`, `Home.Specs.Shelf.Spots`/`Room`: each
  spot's middle on its board in the piece's frame, the box a find fits in). Built: `Home.fbx`
  11,048 triangles. NOT uploaded or imported: the place's `Props.Home` has no Shelf, so
  `Home.has` leaves it out with one warning until c1b re-imports it.
- Save version 5 (`Save.luau`): `shelf`, each spot `{ find, fresh }` (`Save.Fresh` Seen 0, New 1,
  Kind 2). `Save.keep(data, names, now, spots)` lands each kept find on the first empty spot;
  GatePay passes `#Home.Specs.Shelf.Spots`; `Save.seen(data, i)`. `tests/save.spec` covers it.
- Still over the triangle default: the cars' 51k, ticketed as S5-03a2d.
- Find art (third find run): the siren car is done and seen in Play (V4b): it rolls off
  wailing, its red beacon sweeping a dark hall, and a Mannequin comes to it. Next there: V5a,
  a press on a one-mesh find (ROADMAP F-G1e5a, `art/finds/WAVES.md`).

## Next task: S5-03c1b Finds on the shelf, sparkling (D-284)
The moment: your door goes up after a climb and what you brought home stands on your shelf,
sparkling; walk up and it answers with a soft tink; a kind you'd never owned chimes, turns once
slowly and shows "New". Precedent: Animal Crossing's museum, Fortnite's locker marks.
1. `lune run scripts/upload_art Home`; in Edit load it, `Home.prepare`, replace
   `ReplicatedStorage.Props.Home` (art/home/README.md "Into Studio"). The shelf stands in Play.
2. A server system (`Shelves`, after frontOffice in init.server): a player's home is the unit for
   their `Plot` attribute (`Holding.number`, `FrontOffice:laid().units`); when their save loads
   and on GatePay's `kept`, stand each spot's find (`Tools.clone`, inert, fitted into
   `Specs.Shelf.Room` from its parts' box in pivot space, shrunk never grown, its bottom on the
   spot); attributes Fresh, Spot, Owner; clear on leave.
3. A remote: Seen(spot): type, range, a fresh spot, your root within reach of it, rate-limited;
   `Save.seen`. Client `ShelfView`: sparkle (the glint texture Slots uses) on Fresh > 0; your
   own within ~7 studs (checked every 0.2 s, not per frame): New a tink and a burst, Kind
   Boxes' falling twinkles, one slow eased turn and a small "New" billboard; then fire Seen.
4. Studio Play at Galaxy A16 size: keep a find via the dev path, come home, capture at half
   scale to `docs/art/S5-03c1b-*.jpg`; rejoin, it's still there. OWNER.md: the look, steps.
**Acceptance:** check green; in Studio Play a kept find stands on your shelf sparkling, the walk-up
plays, and it's still there after a rejoin.
**Read first:** ROADMAP S5-03c1b; D-284; `src/server/GatePay.luau` (kept, store); `src/shared/Save.luau`
(`keep`, `seen`); `src/shared/Tools/init.luau` (`clone`, `inert`); `src/server/FrontOffice.luau`.

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
8. After a respawn under a held camera, Roblox never re-hid your body in first person (D-282).
   The finds session's work (D-278, D-279) is still uncommitted in the shared checkout.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
