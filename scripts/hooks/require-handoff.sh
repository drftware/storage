#!/usr/bin/env bash
# Claude Code Stop hook (wired in .claude/settings.json).
#
# Enforces the end of AGENTS.md's Session protocol. Blocks the agent from
# ending its turn, at most once per stop, when:
#   1. a project file changed after HANDOFF.md was last written,
#   2. HANDOFF.md or AGENTS.md outgrew its limit (both load into every
#      session, so their size is a cost every session pays), or
#   3. the working tree has uncommitted changes (skipped until the repo has
#      its first commit).
# Turns that change no files are never blocked. If the agent is already
# continuing because of this hook (stop_hook_active), it lets the turn end
# rather than loop.
set -uo pipefail

# A little slack over the 70 lines the protocol asks for.
HANDOFF_MAX=80
AGENTS_MAX=150

input=$(cat)
if [ "$(printf '%s' "$input" | jq -r '.stop_hook_active // false' 2>/dev/null)" = "true" ]; then
	exit 0
fi

cd "${CLAUDE_PROJECT_DIR:-$(dirname "$0")/../..}" || exit 0
[ -f HANDOFF.md ] || exit 0

block() {
	jq -n --arg reason "$1" '{decision: "block", reason: $reason}'
	exit 0
}

newer=$(find src tests scripts docs art/unit/*.py .claude/skills AGENTS.md CLAUDE.md OWNER.md default.project.json \
	rokit.toml selene.toml stylua.toml .luaurc \
	-type f -newer HANDOFF.md 2>/dev/null | head -5 | tr '\n' ' ')
if [ -n "$newer" ]; then
	block "Files changed after HANDOFF.md was last written (${newer% }). Before ending this turn, \
follow the End steps of AGENTS.md's Session protocol: checks pass, overwrite HANDOFF.md, commit, \
then end the reply with Done / Your testing / Kickoff block."
fi

handoff_lines=$(wc -l <HANDOFF.md | tr -d ' ')
if [ "$handoff_lines" -gt "$HANDOFF_MAX" ]; then
	block "HANDOFF.md is $handoff_lines lines (limit $HANDOFF_MAX). It loads into every session: \
trim it to current state only; history belongs in git log."
fi

if [ -f AGENTS.md ]; then
	agents_lines=$(wc -l <AGENTS.md | tr -d ' ')
	if [ "$agents_lines" -gt "$AGENTS_MAX" ]; then
		block "AGENTS.md is $agents_lines lines (limit $AGENTS_MAX). It loads into every session: \
move detail into docs/ and link it from AGENTS.md."
	fi
fi

if git rev-parse --verify -q HEAD >/dev/null 2>&1; then
	dirty=$(git status --porcelain 2>/dev/null | head -5 | awk '{print $2}' | tr '\n' ' ')
	if [ -n "$dirty" ]; then
		block "Uncommitted changes (${dirty% }). Commit them per AGENTS.md's Session protocol or, \
if the owner asked you not to commit, say so in HANDOFF.md under State."
	fi
fi

exit 0
