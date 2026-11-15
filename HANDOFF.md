# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-15, session 186 (B-02a, D-209) · **Checks:** green · **Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage).

## State
- B-02a done, verified in Studio Play (one player): Workspace `DevBox` stood a marked box in
  Unit301; its seam lit, hum playing, warm light on near; Open stamped it (`OpenedBy`, `OpenedAt`)
  and the button went; the client played the open from its first frame 0.09 s after the press,
  the rip 0.1 s and slap 0.3 s in, seam and hum gone by 0.14 s, flaps settled on their last keys.
  Output clean. Captures: `docs/art/B-02a-burst-level01.jpg`, `B-02a-settled-level21.jpg`.
- New: `src/shared/Boxes/Opening.luau` (pure rules and feel numbers; `tests/boxopen.spec.luau`),
  `src/server/MarkedBoxes.luau` (slot `markedBoxes`: `stand`, the checks, `opened` signal),
  `src/client/MarkedBoxView.luau`; `Boxes.cloneMarked`'s parent is optional; Deals' `DevBox`.
- Nothing put in the place by hand. Studio shows two copies of new modules (Rojo glitch; harmless).

## Next task: B-02b The find comes out
ROADMAP B-02 and B-02b (D-205, D-209). The moment: the tape rips, then a held breath with the
grade's coloured light leaking through the flap gaps and its own sound (blue Rare, purple Epic,
gold Legendary, as Pet Simulator's eggs and Brawl Stars' Starr Drops tell the prize by colour),
the flaps burst, the find lifts, turns once and is yours. Two seconds you can't skip; friends near
see and hear it, a Legendary further off. A Common must still feel good (a warm puff, still lifts).
1. The grade reaches screens only at the open: the server stamps the box's grade (and what's in
   it) before `OpenedAt` in `MarkedBoxes`' open (attributes in one batch arrive in order:
   STUDIO.md), never on a shut box (an exploiter reads attributes). `MarkedBoxes.stand` takes
   what's inside; `opened` hands it to whoever grants it.
2. The held beat: today the flaps burst at 0.16 s, straight after the tear. On screens, hold the
   flap tracks after the tear for a per-grade `Hold` (feel numbers in `Opening`): sample the
   flaps at `t - hold` once past the tear, a small tremble while held; move the slap beat by the
   hold. Pure: extend `Opening.pose`/`due`/`settled` with the hold, specs first.
3. The light: one PointLight in the grade's colour inside the box, brightening through the hold
   and flaring at the burst, then gone (counts against the light cap; `Grades.luau` has the
   colours, if not, put them there). Its sound from Roblox's library, measured as
   STUDIO.md "The marked box's sounds" did; Legendary heard further (`Opening.Heard` per grade).
4. The find: lifts out of the box, turns once (F-G1a's pose, `Finds.pose`), then goes to the
   opener as a find picked up does (grep `Slots` for how a find is given to a player's hands; a
   full hand: decide a default, OWNER.md). Coins and tools come in B-03.
5. Studio: `DevBox` as a find's key (a string) stands a box holding it; true keeps "a random
   built find". Prove in Play as STUDIO.md "Opening a marked box in Play" does, one capture per
   grade colour mid-hold at Level01; Output clean. OWNER.md: two-player steps, one per grade.
**Acceptance:** checks green; in Play a Rare, Epic and Legendary each show their light and sound
in the hold, then the find comes out and is the opener's; a Common feels finished, not empty.
**Read first:** ROADMAP B-02b; D-205, D-209; `src/server/MarkedBoxes.luau`;
`src/client/MarkedBoxView.luau`; `src/shared/Boxes/Opening.luau`; `src/shared/Grades.luau`.

## Queue (next sessions, the owner's ten-ticket order)
0. **B-03 to B-05** (ROADMAP, D-205): B-03 deals what's found into boxes (`MarkedBoxes.stand`
   from the deal, replacing `DevBox`; coins to the bank, a tool to your hands). Then S3-03 Cut
   Free (it owns Studio's "CutFree" let-in; rows in `Products`, `Purchasing:prompt`), then S3-04.
1. **S4-01 Floors made by rules.** Split first: S4-01a the rules table and the top gone, S4-01b
   what changes floor to floor. Read the GDD's "Floor rules", D-106, D-128, `Climb.luau`,
   `Deal.luau`; grep `Climb.Top`, `Climb.Building`, `topped`. The escape ("Made it") has no trigger
   once the top goes: keep its code, note it. The climb goes past floor 3 in Studio (DevFloorNumber 3).
2. **F-G1b Using a find plays what it does** (ROADMAP F-G1); then S4-02 to S4-05 (5 coins a trapped
   monster, D-188). Any ticket that adds finds starts from the catalog doc the GDD's finds section links.
3. Once the owner's real purchase passes: mark Brix's ENG-23e done in `../engine`'s HANDOFF.
4. L-08e3c, L-14b2d wait on `OWNER.md`; R-01 later. A GDD section costs ~15k context: `view`
   with `outline: true` and `from` the heading's id, then `search` with `blocks` on just the part needed.
5. Small, from earlier (ROADMAP and `git log` hold the detail): Rojo's duplicate modules (above);
   a dropped find bumps a walking player (D-182); a take could show the arm first (KeeperView Kit);
   rbxassethash warnings in Play; the Packrat's dead Slots entry and S2-06b1's way home; move the
   Mannequin's pose onto `Rig.luau` (D-176); the watch bar's empty panel; S3-01b's wipe after the
   bring unseen; S1-07a, S2-02b to d4, S2-03b, S2-05a, S2-07a1 to b2 leftovers; unseen S1-10d1-3.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
