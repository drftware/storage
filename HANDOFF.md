# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-18, the owner's direction on the home (D-345), docs only ·
**Checks:** green · **Git:** `main`, committed, not pushed (`origin` drftware/storage); Brix pinned
at `7f25310`, NOT on Brix's `origin` yet. The home's chain of sessions is paused by the owner.

## State
- Nov 18, the owner (D-345): everything in a home moves, lifts and works. The starter pieces
  become arrangeable furniture (no shelf mid-room), any find can be taken straight off where it
  stands, and every find set out keeps its button at home. ROADMAP's S5-03i, ahead of h5 and h6.
- The home (D-259; Claude Doc https://claude.ai/artifact/EUdGarQ2sEiUC6BU5E7Tww, docs tools only),
  a ROADMAP piece a session. S5-03h is h1 to h6: h1, h2 and h3 (a, b1, b2) done.
- h3b2 done (D-344): Large/XL cards carry a Gift pill; friends here deal in as cards; the friend
  gets a "More room!" banner with the giver's face (`GiftedView`).
- Studio: in Play on the A16 the banner arrived with the right name, face and headline and hid
  after, no errors; Studio then stopped drawing frames (0 a second), so the motion, the Gift and
  the friend cards weren't watched (STUDIO.md). The two-player test is in OWNER.md.
- Studio hooks: `GrowTest` (a size; "cash"/"price", n; "gift", size, friendPlayer; "friend",
  name, size for a made-up friend), `ArrangeTest` "size", `DevReceipt`. Test save: Small, cash 188.

## Next task: S5-03i1 The starter pieces become furniture
The moment (Animal Crossing's house, Bloxburg's build mode): the shelf isn't stuck mid-room; in
Arrange you lift it, carry it to the back wall, turn it, and set it down like anything you bought.
1. Read D-345, ROADMAP S5-03i, the home doc's "What you decided" (docs tools, search the heading).
2. The shelf, job box, mirror, clothes rail, rug, beanbag and floor lamp become rows in the home's
   layout (`Home/Arranged`, `Spots`, `Save`): lifted, moved, turned, put away in Arrange like
   bought furniture; the job box moves but never goes in the box. The ceiling bulb and the
   light switch stay with the room. Spec the pure part first (Lune).
3. Each piece keeps working where it stands: the shelf's spots and the finds on them, the job
   box's lid and panel, the mirror's reflection (`MirrorView` follows its glass), the rail.
4. A default layout per size (S5-03h4 folded in): nothing mid-room, a new or grown home starts
   from it. A home laid before gets its pieces as rows where they stood (a save version with a
   migration and an old-save sample in `save.spec`).
5. See it in Studio Play at Galaxy A16 size (Rojo is connected now): move the shelf with finds
   on it, the mirror, the box; rejoin; grow a size. Split if it won't fit (rules first).
**Acceptance:** check green; specs prove the rows, the defaults and the migration; in Studio the
shelf, box and mirror move and keep working, and nothing stands mid-room at Small.
**Read first:** D-345 and D-340; ROADMAP S5-03i; `src/shared/Home/Arranged.luau`;
`src/shared/Home/Spots.luau` (grep "Starter"); `art/home/home_spec.py` (from line 222).

## Queue (next sessions, the owner's ticket order)
1. S5-03i2 take anything, i3 every find's button, i4 sit (D-345); then S5-03h5, h6; S5-03g3c
   a card's style; S5-03d4; S5-03a2d the cars' triangles; F-G1b4a2 the beam; F-G1b4b.
2. The steel shelf's lower tiers. In
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
