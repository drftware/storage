--!strict
--[[
	Film: the stretch film a body is wrapped in, made on the server, the one way for everything
	that wraps someone. The catch wraps a kept player head to foot (KeptPlayers, L-07b) and a
	mirror's try-on wraps you for a few seconds (TryOns, S5-03f4a): both are a copy of
	`Props.KeptWrap` (art/keptwrap) fitted to the body at rest (`Kept.fit`), welded to its root and
	tinted a wrap colour (S3-04a, `WrapColours.tint`), so every screen sees the colour with the part
	itself. No collision, weight or shadow: it's only seen.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Kept = require(ReplicatedStorage.Shared.Kept)
local KeptWrap = require(ReplicatedStorage.Shared.KeptWrap.Specs)
local WrapColours = require(ReplicatedStorage.Shared.WrapColours)

local Film = {}

local function box(size: Vector3, centre: Vector3): Kept.Box
	return { size = { size.X, size.Y, size.Z }, centre = { centre.X, centre.Y, centre.Z } }
end
local DRAWN = box(KeptWrap.Body.Size, KeptWrap.Body.Centre)
local WRAP = box(KeptWrap.Wrap.Size, KeptWrap.Wrap.Centre)

local warned = false

-- The body's box standing at rest, from its root: each body part (the character's own parts, not
-- its hats or hair) placed by its joints' rest offsets, Motor6D or AnimationConstraint, so an
-- arm caught mid-swing doesn't size the wrap. Nil when no part hangs off the root.
local function restBox(character: Model, root: BasePart): Kept.Box?
	local links: { { a: BasePart, b: BasePart, offset: CFrame } } = {}
	for _, j in character:GetDescendants() do
		if j:IsA("Motor6D") then
			local a, b = j.Part0, j.Part1
			if a and b then
				table.insert(links, { a = a, b = b, offset = j.C0 * j.C1:Inverse() })
			end
		elseif j:IsA("AnimationConstraint") then
			local a0, a1 = j.Attachment0, j.Attachment1
			local a, b = a0 and a0.Parent, a1 and a1.Parent
			if a0 and a1 and a and b and a:IsA("BasePart") and b:IsA("BasePart") then
				table.insert(links, { a = a, b = b, offset = a0.CFrame * a1.CFrame:Inverse() })
			end
		end
	end
	local at: { [BasePart]: CFrame } = { [root] = CFrame.identity }
	local found = true
	while found do
		found = false
		for _, l in links do
			local from = at[l.a]
			if from and not at[l.b] then
				at[l.b] = from * l.offset
				found = true
			end
		end
	end
	local lo, hi = Vector3.one * math.huge, -Vector3.one * math.huge
	for part, cf in at do
		if part ~= root and part.Parent == character then
			local h = part.Size / 2
			for _, c in
				{
					Vector3.new(1, 1, 1),
					Vector3.new(1, 1, -1),
					Vector3.new(1, -1, 1),
					Vector3.new(1, -1, -1),
				}
			do
				local p, q = cf * (h * c), cf * (-h * c)
				lo, hi = lo:Min(p):Min(q), hi:Max(p):Max(q)
			end
		end
	end
	if lo.X > hi.X then
		return nil
	end
	return box(hi - lo, (hi + lo) / 2)
end

--- A film for `character`, fitted to its body at rest round `root`, welded to `root` and tinted
--- the wrap colour named `colour` (nil or empty for the plain film); not yet parented, so the
--- caller tags and stamps it first. Nil, with one warning, when the place has no Props.KeptWrap.
function Film.make(character: Model, root: BasePart, colour: string?): BasePart?
	local props = ReplicatedStorage:FindFirstChild("Props")
	local template = props and props:FindFirstChild(Kept.Wrap)
	if not (template and template:IsA("BasePart")) then
		if not warned then
			warned = true
			warn(
				"Film: no ReplicatedStorage.Props.KeptWrap, so nobody is wrapped (art/keptwrap/README.md)"
			)
		end
		return nil
	end
	local fit = Kept.fit(restBox(character, root) or DRAWN, DRAWN, WRAP)
	local offset = CFrame.new(fit.centre[1], fit.centre[2], fit.centre[3])
	local wrap = template:Clone()
	wrap.Size = Vector3.new(fit.size[1], fit.size[2], fit.size[3])
	wrap.Anchored = false
	wrap.CanCollide, wrap.CanTouch, wrap.CanQuery = false, false, false
	wrap.Massless = true
	wrap.CastShadow = false
	wrap.Transparency = Kept.WrapBlend
	local look = wrap:FindFirstChildWhichIsA("SurfaceAppearance")
	if look then
		look.Color = WrapColours.tint(colour)
	end
	wrap.CFrame = root.CFrame * offset
	local weld = Instance.new("Weld")
	weld.Part0, weld.Part1, weld.C0 = root, wrap, offset
	weld.Parent = wrap
	return wrap
end

return Film
