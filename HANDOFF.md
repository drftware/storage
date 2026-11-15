# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-15, session 181 (the order changed: purchases first, D-204) · **Checks:** green · **Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage).

## State
- S3-01 done (D-187); F-G1a done (D-203): 19 Nov 15 finds dealt by grade, stood as found,
  carried and banked; using one does nothing yet. Find art: 20 finds in the place, F-04c next.
- **Order changed** (D-204): Brix built purchases (its main at `5cdb8c2`, pushed, in no release
  yet), so Step 3's products come before Step 4 again. F-G1c (the grade shown at the door) is
  parked: the owner is shaping packed units, finds in boxes you open (`OWNER.md` asks).

## Next task: S3-02 Purchases that are never lost
ROADMAP S3-02. The moment: a player pays Robux and gets it at once, exactly once, never lost, even
when a save fails or they change servers. Nothing goes on sale here: S3-03 sells Cut Free first.
1. Read ROADMAP S3-02 and the GDD's "Monetization" section only (docs tools, never WebFetch),
   then Brix's purchases contract and its HANDOFF's purchases notes in `../engine`.
2. Move the pin: `vendor/brix` to Brix `5cdb8c2` (or its latest green commit); update
   FRAMEWORK.md's pinned commit and its "built since the pin" table. Checks green before going on.
3. Hand Brix's purchases the player's save (`src/server/Saving.luau`): a product is granted only
   once the save holding it has gone through, and only then is Roblox's receipt answered.
4. One table of products (what each grants, its live-config switch); prices read from Roblox
   (`Roblox.Marketplace`), never written in code. Every purchase and every prompt shown is
   recorded (`src/server/Recording.luau`); any offer can be switched off live (Brix `LiveConfig`).
5. Prove it in Studio with Brix's made-up receipts on a Studio-only test product: granted once,
   a repeated receipt ignored, a failed save retried and nothing granted.
**Acceptance:** checks green; the product table and grant rules spec'd; made-up receipts run in
Studio; `OWNER.md`: make the products on the published place, then the phone test (a forced save
failure, a server hop, a regional price, an offer switched off), which is also Brix's ENG-23e.
**Read first:** ROADMAP S3-02; GDD "Monetization"; FRAMEWORK.md; `../engine`'s Purchases contract
and HANDOFF; `src/server/Saving.luau`; `src/server/Recording.luau`.

## Queue (next sessions per ROADMAP Phase 2)
0. S3-03 Cut Free, Free a Friend, Free Everyone (it owns Studio's "CutFree" let-in, which still
   stands a watcher in the lobby); then S3-04 the counter's shop (gifts wait on `OWNER.md`).
1. **S4-01 Floors made by rules.** Split first: S4-01a the rules table and the top gone, S4-01b
   what changes floor to floor (packed units slot in before S4-01b once answered). Read the GDD's
   "Floor rules", D-106, D-128, `Climb.luau`, `Deal.luau`; grep `Climb.Top`, `Climb.Building`,
   `topped` for what leans on the top. The escape ("Made it") has no trigger once the top goes:
   keep its code, note it. Spec any floor number up to 100 and past it; the climb goes past
   floor 3 in Studio Play (DevFloorNumber 3). Leave room for boss floors and bigger-inside units.
2. **F-G1b Using a find plays what it does** (ROADMAP F-G1 has its plan and Read-first list);
   then S4-02, S4-03, S4-04 (5 coins a trapped monster, D-188), S4-05. Any ticket that adds finds
   starts from the catalog doc the GDD's finds section links.
3. L-08e3c, L-14b2d wait on `OWNER.md`; R-01 later.
4. A dropped find lands 2.2 studs ahead, solid, and a walking player bumps it (D-182).
5. On other screens a take goes from the hunt's walk straight to Take: a few frames of the arm
   coming out first would make the snatch land (KeeperView Kit). `grab` (4) not measured.
6. Output in Play: rbxassethash permission warnings (25, Nov 14); 203785492's asset type mismatch.
7. The Packrat: carrying a find when its floor is dropped, Slots keeps a dead entry (tiny);
   S2-06b1's way home shut is unspecced; woken shut in it faces its door; no medium-unit home
   in 600 floors. The TV meets the forearms at the carry point: seat finds by depth or accept.
8. Move the Mannequin's pose math onto `Rig.luau` when next touched; fold its and the Packrat's
   prepare and pose into one body module when a third jointed monster comes (D-176). Trim the
   watch bar's empty panel height (S3-01a) when the bar is next touched.
9. S3-01b: a wipe after the bring (while the unit streams in) is spec'd but unseen.
10. Left from earlier: S1-07a 16 in 100 units hold nothing; S2-02c only a wandering Mannequin
   takes the errand; S2-02b nobody can throw the breaker by hand; S2-03b loose keepers look at a
   pounding door; S2-07a2 a monster let out by a wrong code, a missed tap or bursting out can
   pass the floor's limit; S2-02d4 the first clunk may come 0.3 s late; S2-05a a sleeper woken by
   a missed tap isn't in `woken`; S2-07a1 a feed copies every monster at the start; S2-07b1 a
   light coming back over a still player fires `woke`; S2-07b2 the coin's TexturePack
   (`OWNER.md` asks). Unseen: S1-10d1 to d3, S1-06, S1-05.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
