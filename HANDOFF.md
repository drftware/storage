# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-17, session 283 (S5-03h3a, Large and XL for Robux, D-342) · **Checks:** green ·
**Git:** `main`, committed, not pushed (`origin` drftware/storage); Brix pinned at `7f25310`,
NOT on Brix's `origin` yet.

## State
- The home (D-259; Claude Doc https://claude.ai/artifact/EUdGarQ2sEiUC6BU5E7Tww, docs tools only)
  is built a ROADMAP piece a session. S5-03h is h1 to h6: h1, h2 and h3a done.
- h3a done (D-342): `Products` rows `homeLarge` ("Large Unit") and `homeXL` ("XL Unit") from
  `Grow.Robux`; owned at that size or bigger (`Grow.owns`), the grant only grows (`Grow.grant`).
  `Growing`: a Robux size's press puts Purchasing's prompt up ("had", "off" when it can't; Studio
  a made-up `DevReceipt`); closed unbought answers "closed"; Purchasing's `granted` re-lays the
  home and answers "" only to a screen waiting on that prompt. The shelf carries Robux prices.
  `UnitsTab`: Large and XL cards with the Robux mark. Growing now starts after wearing.
- Checked in Studio Play from scripts only (the viewport read 1 by 1). No products on Roblox yet.
- Studio hooks: `GrowTest` (a size; "cash", n; "price", n), `ArrangeTest` "size", `DevReceipt`.
  Test save: Small, cash 188, nothing set out, Unit1. Stage only your own paths.

## Next task: S5-03h3b The gift versions
The moment: your friend's home is the little one, and you grow it for them from the counter, as
Pet Simulator and Adopt Me let you gift Robux things. Gifts of Large and XL only (Robux).
1. Read ROADMAP S5-03h3b, D-342, D-206 (recipients) and how Free a Friend is prompted with a
   recipient and granted as a spare the server then spends (`src/server/CutFrees.luau`, grep
   "freeFriend\|recipient").
2. Spec first (failing): gift rows (`giftLarge`, `giftXL`, `forAnother`), the recipient picked on
   the server (a player in this server, not you, smaller than the size); a gift never sold to a
   home already that big. Decide how the recipient's save changes: my default, the grant is a
   spare in the buyer's save (never lost), and the server spends it by writing the recipient's
   `homeSize` first and the buyer's spare second; a spare left over (the recipient left, a
   write failed) waits for the buyer's next gift press. OWNER.md line for the default.
3. The server: who's giftable (a short list of friends here), the prompt with the recipient, the
   grant, the recipient's home re-laid and both told (a gift headline on theirs).
4. The Units tab: a Gift choice on Large and XL (the friends here, their size), the answer's
   motion and sound; the recipient's own "More room!" moment.
**Acceptance:** check green; the spec fails first then passes; in Studio's 2-player test a
made-up gift receipt grows player 2's home (`HomeSize`), never twice, never smaller; a failed
save keeps the spare.
**Read first:** ROADMAP S5-03h3b; D-342; D-206; `src/server/CutFrees.luau` (Free a Friend);
`src/server/Growing.luau`; `src/shared/Products.luau`.

## Queue (next sessions, the owner's ticket order)
1. S5-03h4 to h6 (ROADMAP). S5-03g3c a card's style, h; S5-03d4; S5-03a2d the cars' hidden
   triangles; F-G1b4a2 the headlamp's beam; F-G1b4b the hat spent.
2. Sitting on a crate, the cushion or the camp bed (Seats); the steel shelf's lower tiers. In
   Arrange the job box's "Open" shows over the room; the starter shelf hides a piece behind it
   from Arrange's corner camera and from the doorway. A lifted lit piece's light stays where it
   was until it's set down. The looks' polish (g2b2, g2b3, g3b). A size change while Arrange is
   open doesn't rebuild the screen's judge (h6 should). Units: plans small; Robux cards unseen.
3. The home's warm fill (D-290): faces turned from the bulb go near black. F-G1b5 waits for its
   art. Brix (in `../engine`): ENG-25b's two-client run; Driving's stick read (D-254); a
   PlayerSaves hook before a leaving save's last write. S4-02 to S4-05.
4. The item catalog doc and the design doc's finds section need D-250, D-251, D-259, D-277, D-297,
   D-299, D-300, D-301, D-302, D-304, D-305, D-308 (the spot column), D-309, D-311 to D-342.
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
