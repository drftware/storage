--!strict
-- lune run tests/curtain.spec
-- The Luau curtain must match the Python solver that posed every render (art/unit/curtain.py).
local fs = require("@lune/fs")
local serde = require("@lune/serde")

local Curtain = require("../src/shared/StorageUnit/Curtain")

local fixture = serde.decode("json", fs.readFile("tests/fixtures/curtain_M.json"))
local c = Curtain.new(fixture.params)
local TOL = 1e-6
local failures = 0
local checks = 0

local function near(a: number, b: number, what: string)
	checks += 1
	if math.abs(a - b) > TOL then
		failures += 1
		print(string.format("FAIL %s: lua %.9f vs python %.9f", what, a, b))
	end
end

local buf = {}
for _, case in fixture.cases do
	local st = c:slats(case.rise, buf)
	local tag = string.format("rise %.2f", case.rise)
	near(st.phi, case.phi, tag .. " phi")
	near(st.theta, case.theta, tag .. " theta")
	near(st.ell, case.ell, tag .. " ell")
	near(c:drumAngle(st), case.drum, tag .. " drum")
	for i, f in case.slats do
		local j = 4 * (i - 1)
		for k = 1, 4 do
			near(buf[j + k], f[k], string.format("%s slat %d[%d]", tag, i - 1, k))
		end
	end
	-- links stay rigid: neighbouring chord midpoints never further apart than one pitch
	for i = 1, fixture.params.Count - 1 do
		local j, k = 4 * (i - 1), 4 * i
		local d = math.sqrt((buf[k + 1] - buf[j + 1]) ^ 2 + (buf[k + 2] - buf[j + 2]) ^ 2)
		checks += 1
		if d > fixture.params.Pitch + 1e-9 then
			failures += 1
			print(string.format("FAIL %s link %d stretched to %.5f", tag, i, d))
		end
	end
end

-- warm-started solves (what a moving door does every frame) agree with cold ones
local phi: number? = nil
for r = 0, 7.65, 0.05 do
	local warm = c:solve(r, phi)
	local cold = c:solve(r)
	near(warm.phi, cold.phi, string.format("warm start at %.2f", r))
	phi = warm.phi
end

print(string.format("curtain: %d checks, %d failures", checks, failures))
if failures > 0 then
	error("curtain spec failed")
end
