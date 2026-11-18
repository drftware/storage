# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-17, session 285 (S5-03h3b2, the Gift screen and the friend's moment, D-344) ·
**Checks:** green · **Git:** `main`, committed, not pushed (`origin` drftware/storage); Brix pinned
at `7f25310`, NOT on Brix's `origin` yet.

## State
- The home (D-259; Claude Doc https://claude.ai/artifact/EUdGarQ2sEiUC6BU5E7Tww, docs tools only),
  a ROADMAP piece a session. S5-03h is h1 to h6: h1, h2 and h3 (a, b1, b2) done.
- h3b2 done (D-344): Large/XL cards carry a Gift pill (the wrapped box, `GiftMark`); pressed, the
  other sizes hide and the friends here deal in as cards (face, name, size, gift price or the box
  for a spare; one that big dimmed); a friend's tap holds till `HomeGrown` answers with their id;
  "" opens the plan from their size, their face, "Sent!". The friend hears it in `GiftedView`: a
  banner under the top bar, the giver's face, "More room!", their name, the roll and knock.
  `Grow.friendId` now takes negative ids (Studio's test players are -1, -2).
- Studio: in Play on the A16 the banner arrived with the right name, face and headline and hid
  after, no errors; Studio then stopped drawing frames (0 a second), so the motion, the Gift and
  the friend cards weren't watched (STUDIO.md). The two-player test is in OWNER.md.
- Studio hooks: `GrowTest` (a size; "cash"/"price", n; "gift", size, friendPlayer; "friend",
  name, size for a made-up friend), `ArrangeTest` "size", `DevReceipt`. Test save: Small, cash 188.

## Next task: S5-03h4 The starter set laid by size
The moment (Animal Crossing's house growing, Bloxburg's starter home): a Small home is snug, just
the shelf, the job box, the mirror and the rail against its walls; a bigger one has the rug, the
beanbag and the lamps too, each piece standing where it looks lived-in at that size.
1. Read ROADMAP S5-03h4; the home doc's idea 30 (search the heading, never the whole doc);
   `art/home/home_spec.py` from line 222 (`STARTER`); `src/shared/Home/Sizes.luau`. If it won't
   fit one session, split it in ROADMAP (h4a the spec and art, h4b laying it at runtime).
2. In the spec, a place per piece per size (Small's snug four; Medium, Large, XL the whole set),
   each piece keeping to its wall so it rides that wall as the home grows. Rebuild with
   `scripts/art.sh`; never hand-edit the generated `Specs`.
3. Where the server lays the starter set (grep "Starter" in `src/shared/Home/Spots.luau`,
   `Arranged.luau`, `Specs.luau`), lay it from the home's size; a size change re-lays it
   (`ArrangingSystem:relay`). Spec the pure part first (Lune).
4. Look sheets of each size at phone size; in Studio, `ArrangeTest` "size" to flip sizes.
**Acceptance:** check green; a spec proves each size's set and that Small holds only its four; the
look sheets read at phone size; in Studio each size's set seen (or OWNER.md steps if Studio won't
draw).
**Read first:** ROADMAP S5-03h4; home doc idea 30; `art/home/home_spec.py` (from line 222);
`src/shared/Home/Sizes.luau`; `src/shared/Home/Spots.luau` (grep "Starter"); D-340.

## Queue (next sessions, the owner's ticket order)
1. S5-03h5, h6 (ROADMAP). S5-03g3c a card's style, h; S5-03d4; S5-03a2d the cars' hidden
   triangles; F-G1b4a2 the headlamp's beam; F-G1b4b the hat spent.
2. Sitting on a crate, the cushion or the camp bed (Seats); the steel shelf's lower tiers. In
   Arrange the job box's "Open" shows over the room; the starter shelf hides a piece behind it
   from Arrange's corner camera and from the doorway. A lifted lit piece's light stays where it
   was until it's set down. The looks' polish (g2b2, g2b3, g3b). A size change while Arrange is
   open doesn't rebuild the screen's judge (h6 should). Units: plans small; Robux cards unseen.
   A gift buyer's `bought` counts only a spare's gift (D-343); the Gift cards unseen (D-344).
3. The home's warm fill (D-290): faces turned from the bulb go near black. F-G1b5 waits for its
   art. Brix (in `../engine`): ENG-25b's two-client run; Driving's stick read (D-254); a
   PlayerSaves hook before a leaving save's last write. S4-02 to S4-05.
4. The item catalog doc and the design doc's finds section need D-250, D-251, D-259, D-277, D-297,
   D-299, D-300, D-301, D-302, D-304, D-305, D-308 (the spot column), D-309, D-311 to D-344.
5. Once the owner's real purchase passes, mark Brix's ENG-23e done. Late arrivals off
   `ClimbEnd.spot`; the driving torch (D-257); asset 203785492's type error; the front office's
   steel; cart seats vs `Seat:Sit`; a spare home unpadlocked (D-275); the hat's first-Wear dark
   screen; the body after a respawn (D-282); a Gold's own textures.
6. One `CaughtSeized` string; S5-03d4's climb server restamps its lights (`Use.leave`). The HUD
   coin count reads 0 in Play (Nov 17, ten times now). Lobby sheets: no plates. Cash spent at
   the counter (furniture, Medium) and sold from the job box isn't sent to analytics.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
