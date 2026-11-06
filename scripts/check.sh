#!/usr/bin/env bash
# Every check before handing off: format, lint, strict types, Rojo build, Lune tests.
# Prints only problems plus one summary line. Exit code 0 = all passed.
set -uo pipefail
cd "$(dirname "$0")/.."
export PATH="$HOME/.rokit/bin:$PATH"

fail=0

if [ ! -f roblox.d.luau ]; then
	curl -sSfL https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/main/scripts/globalTypes.d.luau \
		-o roblox.d.luau || { echo "FAIL: could not download roblox.d.luau"; exit 1; }
fi

stylua src tests || { echo "FAIL: stylua could not format"; fail=1; }

lint=$(selene src 2>&1)
if ! echo "$lint" | grep -q "^0 errors" || ! echo "$lint" | grep -q "^0 warnings"; then
	echo "$lint" | grep -E "^(error|warning)" -A4
	echo "FAIL: selene"
	fail=1
fi

rojo sourcemap default.project.json -o sourcemap.json >/dev/null 2>&1 || { echo "FAIL: rojo sourcemap"; fail=1; }

types=$(luau-lsp analyze --definitions=roblox.d.luau --sourcemap=sourcemap.json --base-luaurc=.luaurc src 2>&1 \
	| grep "^$PWD/" | sed -E "s#^$PWD/##; s# \[game/[^]]*\]##" | sort -u)
if [ -n "$types" ]; then
	echo "$types"
	echo "FAIL: luau-lsp (strict types)"
	fail=1
fi

rojo build default.project.json -o "${TMPDIR:-/tmp}/storage-check.rbxl" >/dev/null 2>&1 || { echo "FAIL: rojo build"; fail=1; }

for t in tests/*.spec.luau; do
	out=$(lune run "${t%.luau}" 2>&1) || { echo "$out" | grep -E "FAIL|error" | head -20; echo "FAIL: $t"; fail=1; }
done

if [ $fail -eq 0 ]; then echo "check: all passed"; else echo "check: FAILED"; fi
exit $fail
