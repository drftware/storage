# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-17, session 284 (S5-03h3b1, the gifts' rules and server, D-343) · **Checks:**
green · **Git:** `main`, committed, not pushed (`origin` drftware/storage); Brix pinned at `7f25310`,
NOT on Brix's `origin` yet.

## State
- The home (D-259; Claude Doc https://claude.ai/artifact/EUdGarQ2sEiUC6BU5E7Tww, docs tools only),
  a ROADMAP piece a session. S5-03h is h1 to h6: h1, h2, h3a and h3b1 done.
- h3b1 done (D-343): Large and XL as gifts through Brix's own gift (`Products` rows `giftLarge`
  "Large Unit Gift", `giftXL` "XL Unit Gift"): the friend's home grows in their save, written
  before the buyer's purchase counts; a friend gone before it lands leaves a spare in the buyer's
  save, given on their next Gift press friend-save-first (`Grow.give`/`ungive`/`spend`).
  `Growing`: `GrowHome(size, friendId)` is a gift; `HomeGrown` answers with the friend's id last;
  the friend hears `HomeGifted(size, giverId, giverName)`; the shelf carries `gifts`, `spares`,
  `friends`. Specs green (Brix's real gift over this save); untested in Studio; no screen yet.
- Studio: `GrowTest` (a size; "cash"/"price", n; "gift", size, friendPlayer), `ArrangeTest`
  "size", `DevReceipt` (`recipient`: a save key). Test save: Small, cash 188, Unit1. Stage only yours.

## Next task: S5-03h3b2 The Gift screen and the friend's moment
The moment (Pet Simulator's and Adopt Me's gifting): you tap your friend's face on Large's Gift,
the steel rolls, "Sent!"; their screen says "More room!" with your face, their home opens out.
1. Read D-343, `UnitsTab` (`makeCard`, `press`, `onGrown`), Grow's gift part (grep "Gift").
2. Deal `Grow.ladder(have, robux, giftable)` with `giftable[name] = Grow.giftable(shelf, name)`.
   A Gift pill on a giftable Large or XL card (the only button on a card under your size); a held
   spare shows a gift mark, no price.
3. Gift turns the card to the friends here (`shelf.friends`: headshot, name, their size); one
   already that size or bigger dimmed, its press ignored. A friend's press fires
   `GrowHome(size, userId)` and holds (`Shop.GrowPrompt`) till `HomeGrown` answers with that id:
   "" plays the roll, the plan opening from their size, "Sent!" with their face; "closed",
   "gone", "had" settle with no words and ask the shelf again.
4. The friend's moment: a client view started at boot hears `HomeGifted` and shows "More room!"
   with the giver's face and name at the top, the steel's roll and knock, easing in and away.
5. Studio, 2 players (Test > Clients and Servers): from the server, `GrowTest` "gift" Large from
   player 1 to player 2; again ("had"); with `DevSaveFails` and a spare, "save" and the spare kept.
**Acceptance:** check green; in the 2-player test a made-up gift grows player 2's home
(`HomeSize`), never twice, never smaller; a failed save keeps the spare; the friends list and
the friend's headline seen at phone size.
**Read first:** ROADMAP S5-03h3b2; D-343; `src/client/UnitsTab.luau`; `src/shared/Home/Grow.luau`
(gift part); `src/server/Growing.luau` (grep "gift"); `src/client/init.client.luau` (boot).

## Queue (next sessions, the owner's ticket order)
1. S5-03h4 to h6 (ROADMAP). S5-03g3c a card's style, h; S5-03d4; S5-03a2d the cars' hidden
   triangles; F-G1b4a2 the headlamp's beam; F-G1b4b the hat spent.
2. Sitting on a crate, the cushion or the camp bed (Seats); the steel shelf's lower tiers. In
   Arrange the job box's "Open" shows over the room; the starter shelf hides a piece behind it
   from Arrange's corner camera and from the doorway. A lifted lit piece's light stays where it
   was until it's set down. The looks' polish (g2b2, g2b3, g3b). A size change while Arrange is
   open doesn't rebuild the screen's judge (h6 should). Units: plans small; Robux cards unseen.
   A gift's buyer's `bought` counts only a gift that waited as a spare (D-343).
3. The home's warm fill (D-290): faces turned from the bulb go near black. F-G1b5 waits for its
   art. Brix (in `../engine`): ENG-25b's two-client run; Driving's stick read (D-254); a
   PlayerSaves hook before a leaving save's last write. S4-02 to S4-05.
4. The item catalog doc and the design doc's finds section need D-250, D-251, D-259, D-277, D-297,
   D-299, D-300, D-301, D-302, D-304, D-305, D-308 (the spot column), D-309, D-311 to D-343.
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
