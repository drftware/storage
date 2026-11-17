# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-17, session 236 (finds on the shelf, sparkling, D-285) · **Checks:** green for
this work (in a worktree; the checkout is red only from another session's half-done
`src/shared/Finds/*` and `Tools/*`) · **Git:** `main`, committed, not pushed (`origin` is
github.com/drftware/storage); Brix pinned at `482368f`, NOT on Brix's `origin` yet (push Brix first, OWNER.md).

## State
- The home (D-259; the Claude Doc https://claude.ai/artifact/EUdGarQ2sEiUC6BU5E7Tww, docs tools
  only) is built a ROADMAP piece a session (S5-03): ground floor, fronts, starter sets, switch,
  a home each as you join (D-275), the hard hat on your head (D-277, D-283), the mirror (D-280),
  the oak shelf (D-284) and now finds standing on it (D-285).
- S5-03c1b (D-285), verified in Studio Play: the new Home.fbx is uploaded and imported (the
  place's `Props.Home` has the Shelf). `Shelves` (server) stands each save `shelf` spot's find
  in the home's `Starter.Shelf`, fitted (`Home/Shelf.fit`), lights off, tagged `ShelfFind`;
  `ShelfView` twinkles new ones, plays your walk-up (tink; a never-owned kind chimes, turns,
  shows "New") and fires `ShelfSeen`, which the server checks and marks seen. Seen: six finds
  landing, the walk-up, all six seen on the server, still there after a rejoin. Captures:
  `docs/art/S5-03c1b-from-door.jpg`, `-walk-up.jpg`. Not seen at Galaxy A16 size (OWNER.md).
- Dev path: `ServerStorage.ShelfTest:Invoke(player, key)` (Studio) keeps a find as a gate does.
- Save version 5 (`Save.luau`): `shelf` spots `{ find, fresh }`; `Save.keep` leaves a find in
  `finds` alone when the shelf is full: that's the job box's (S5-03c2a).

## Next task: S5-03c2a The job box
The moment: the shelf's full, you keep one more at the gate, and when you come home the job box's
lid sparkles; press Open and the lid swings up with a soft steel creak. Precedent: Animal
Crossing's house storage, Fortnite's locker marks (what's new shows until you look).
1. Read the home doc's job box idea (docs tools; search the heading text "job box"); its "What
   you decided (Nov 16)" wins. ROADMAP says the steel job-site box, calm (D-263).
2. Art the unit's way: `art/home/furnish.py` a `jobbox` piece, body and lid as separate parts
   (the lid hinges), in `Specs.Pieces` and the `Starter` set (my default spot: against a side
   wall near the shelf; an OWNER.md line). `scripts/art.sh`, then upload and import as c1b did
   (`lune run scripts/upload_art Home`; LoadAsset, `Home.prepare`, replace `Props.Home`).
3. Save version 6: a flag that a kept find went in the box since you last opened it (set in
   `Save.keep` when `Save.shelve` returns nil; a migration; `tests/save.spec`).
4. Server: the box's Open button for its holder only; opening lifts the lid, clears the flag.
   Client: the lid twinkles while the flag is set (ShelfView's sparkle), the creak on open.
5. Studio Play: `ShelfTest` six finds then a seventh; come home, capture at half scale to
   `docs/art/S5-03c2a-*.jpg`. Split again in ROADMAP if it won't fit.
**Acceptance:** check green; in Studio Play the seventh find makes the lid twinkle; Open lifts it
and the twinkle stops; after a rejoin the box is quiet.
**Read first:** ROADMAP S5-03c2a; D-284 and D-285; `art/home/furnish.py` (`shelf`);
`art/home/README.md`; `src/shared/Save.luau` (`keep`, `shelve`, version 5); `src/server/Shelves.luau`.

## Queue (next sessions, the owner's ticket order)
1. S5-03c2b the panel, c3 selling; S5-03d-h; S5-03a2d the cars' hidden triangles; F-G1b4a2 the
   headlamp's beam (ROADMAP Step 4); F-G1b4b the hat spent (start its minute when a hat worn at
   home leaves the ground floor).
2. F-G1b5 waits for its art. Brix: ENG-25b's two-client run (OWNER.md's home test covers it).
3. Brix ticket: Driving's stick read needs `PlayerScripts.PlayerModule`; fall back to the
   camera-turned `Humanoid.MoveDirection` as `input` does (D-254). Built in `../engine`.
4. S4-02 monsters by lowest floor, S4-03 the elevator's choice, S4-04 trapping pays, S4-05.
5. The item catalog doc and the design doc's finds section need D-250, D-251, D-259 and D-277.
6. Once the owner's real purchase passes: mark Brix's ENG-23e done in `../engine`'s HANDOFF.
7. Spread late arrivals off `ClimbEnd.spot`; the driving torch's rules vs what's seen (D-257);
   Play logs asset 203785492 ("asset type does not match"). The front office's counter and
   shelves are still the climb's steel. The lobby's cart seats didn't seat a server `Seat:Sit`
   (S5-03a2b4). A spare home lifted from inside stays unpadlocked until held and left (D-275).
   The worn hat's first-Wear dark screen (STUDIO.md). After a respawn under a held camera,
   Roblox never re-hid your body in first person (D-282).
8. Another session's find work is uncommitted in the shared checkout (`src/shared/Finds/*`,
   `OneMesh.luau`, `Tools/*`, two specs) and turns the check red until it lands.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
