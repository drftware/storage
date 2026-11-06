---
name: wrap
description: End this session now and hand off to a fresh one. Stops at the nearest green point, then runs the end steps of AGENTS.md's Session protocol (checks, ROADMAP, HANDOFF.md, commit, reply sections, kickoff block). Use when the owner says "wrap", "wrap up", "hand off", "new session", or "end the session", or when AGENTS.md's context budget says it's time.
---

The session ends now, whether or not the ticket is finished. A fresh session with a good handoff
beats a long one running on a crowded context.

1. Start nothing new. Finish the smallest coherent piece in progress, or revert it, until
   `scripts/check.sh` passes. Never hand off red.
2. If the ticket isn't done, split it: what's done goes under State in HANDOFF.md, and the rest
   becomes the Next task with ordered steps, acceptance checks and a Read-first list. Make the same
   split in `docs/ROADMAP.md`.
3. Run the End steps of AGENTS.md's Session protocol exactly, and finish the reply with the kickoff
   block the owner pastes into the next session.
