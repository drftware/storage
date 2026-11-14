# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-13, session 117 (L-08e4b2 Home again) · **Checks:** green ·
**Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage).

## State
- **L-08e4b2 built (D-129), passes checks, untested in Studio.** A cart parked at a car's
  stripes rolls itself home 1.2 s later, one left elsewhere after 20 s: nose first to the
  nearest free slot, curving to line up and easing straight in between the hoops, swinging round
  on the spot first if it faces away (`Cart.Home`, 58 Lune checks). The server sends the way and
  a run stamped with its clock once (`Home*` attributes, `Carts`); every screen places the cart
  each frame (`CartView`), rattling, with a soft clunk into the rack. It brakes and waits for
  anyone ahead; held 12 s, or boxed in, it's put in its slot.
- **Studio isn't getting Rojo's syncs.** The place still runs the code from before this session
  (Edit's `Carts` has no `goHome`; no `Cart.Home`). Studio's MCP can't sync around it (it
  refuses HTTP to localhost). A ride to the stripes in Play worked on the old code. The owner's
  Connect click is `OWNER.md`'s first line; until then nothing new can be checked in Studio.
- The GDD (D-127, D-128) is the newer word; ROADMAP Phase 2 is its build order. The GDD says
  "monsters"; the code says keepers.

## Next task: L-08e3b Share and follow
The moment: a friend taps your invite while your group is already climbing on its own server,
and lands beside you instead of alone in the public lobby. If it won't fit one session, split it
in ROADMAP first (the three pieces are separable; do (2) first).
1. First, in Edit, check Studio has the code (`Carts.Source` contains `goHome`). If it does, run
   L-08e4b2's checks before anything else: ride a cart onto a car's stripes (STUDIO.md "Testing
   a cart ride from the MCP"; hold W about 5 s from the slot) and log Cart1's pivot and
   `HomeAt` from a client Heartbeat; it should set off about 1.5 s after the hop-off and park in
   slot 1 (x -19.5, z 554.85) about 10 s later; Output clean. Fix what fails first.
2. (2) Invite from a group's own server: the launch data names that server (`Trip` data
   carries its id); the public lobby a friend lands in sends them on (`TeleportAsync`, the same
   `ReservedServerId`), standing them at the front office there.
3. (3) The dial's floor for a climb on another server: the group's server tells its lobby
   (MessagingService, the lobby's JobId in the trip's data); the car's dial says "Floor N"
   until they're back.
4. (1) The share link (`SocialService:PromptLinkSharingAsync`, server only): where it sits waits
   on `OWNER.md` (Decide, L-08e3 item 3); default a Share key beside Invite, and say so there.
**Acceptance:** checks green; Lune specs for any pure piece (the launch data, who's sent where);
what Studio can show verified (one player: the panel, the data round trip); real invites,
reserved servers and MessagingService go to `OWNER.md` as exact steps.
**Read first:** ROADMAP L-08e3b; DECISIONS D-122 and D-124; `src/shared/Lobby/Trip.luau`;
`src/server/Trips.luau`; `src/server/LobbyCars.luau`; `src/client/CarPanel.luau`.

## Queue (the overnight run, owner Nov 13: sessions until 8:30am, the updated plan)
1. L-08e3b (next). Then ROADMAP Phase 2 in order from S1-01. S1-01 Saving waits on Brix's
   ENG-10 save data (unticked in `../engine/docs/ROADMAP.md`): skip it, make sure Brix's
   ROADMAP names the missing piece in neutral terms, and promote the next buildable ticket.
   S2-06 waits on `OWNER.md`. Lobby polish ("The ride's finish", "The dials' finish") waits.
2. Untested in Studio until Rojo syncs: L-08e4b2 (above), and anything built after it.
3. Found L-08e4b1: no PlayerModule in PlayerScripts in Play (STUDIO.md), so WatchView's
   `controls` lookup fails quietly (controls may stay on while you watch; untested).
4. Seen (owner, Nov 12, "fix them later"): lobby car floors go splotchy inside; a sawn side or
   top flashes see-through as its panel drops (`TopHole.saw`, `CrawlHole.saw`). Older, see git
   log of HANDOFF (session 116): a lobby car's dim lamp, the gate cache, ladder and tool edge
   cases, the rbxassethash lines at Play, the flashlight out in the lobby and while riding.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
