--!strict
--[[
	ArrangeStage (S5-03j1d, D-444): while Arrange's build camera looks down on your home, the rest
	of the world goes from your screen: the lobby's roof, its walls and ceiling, the neighbours'
	units and everything else near. Your room stands open-topped and lit on a calm dark floor, as
	The Sims 4's build mode drops an apartment's neighbours and Animal Crossing shows a room alone
	on black. Only your screen changes (`LocalTransparencyModifier`, written on this client), so
	every other player still sees the lobby whole.

	Why the whole world and not just the roof: a slanted look into a room only clears its near
	walls if nothing stands between the eye and them, and a lid round your room, the hall's upper
	wall or a neighbour's partition always does (seen in Studio, D-444).

	`ArrangeCamera` owns one: `lift` when its orbit becomes the view, `drop` when a fixed shot or
	your own eyes come back. Lifting walks what's near your home once; while lifted, parts that
	stream in near it are hidden as they come. Nothing steps every frame. Kept whole: your unit,
	every player's character, and the camera's own children (Arrange's lifted finds). The lobby's
	haze (its `Atmosphere`) and depth of field go too while lifted: from 20 studs across they turn
	the room black (seen in Studio). So does the room's own bulb, which Roblox stops drawing from
	that far (and sooner on a low-end phone), so while lifted the ambient light rises to `light`:
	the room reads evenly lit from any distance, as The Sims' build mode does.
]]
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local ArrangeStage = {}

export type Stage = {
	-- Hides everything within `reach` of `centre` but `unit`, and lays the dark floor at `floor`.
	lift: (unit: Model, centre: Vector3, floor: number) -> (),
	-- Brings it all back.
	drop: () -> (),
	destroy: () -> (),
}

-- What the stage hides: parts, the pictures on them, and the signs' text on them (a SurfaceGui
-- draws on a part its transparency hid: a lobby card's text showed as a white line, S5-03j1d3b).
local function shows(i: Instance): boolean
	return i:IsA("BasePart")
		or i:IsA("Decal")
		or i:IsA("Texture")
		or i:IsA("SurfaceGui")
		or i:IsA("BillboardGui")
end

-- The Workspace child an instance stands under, or nil if it isn't in Workspace.
local function topOf(i: Instance): Instance?
	local at: Instance? = i
	while at and at.Parent ~= Workspace do
		at = at.Parent
	end
	return at
end

-- `reach`: how far from your home's middle the world goes (studs). `colour`: the dark floor's.
-- `light`: the ambient light while lifted.
function ArrangeStage.new(reach: number, colour: Color3, light: Color3): Stage
	local hidden: { Instance } = {}
	-- Signs switched off while lifted (a gui has no transparency modifier), to switch back on.
	local switched: { LayerCollector } = {}
	local added: RBXScriptConnection? = nil
	local ground: Part? = nil
	local keep: Model? = nil
	local middle = Vector3.zero
	-- The haze and the blur as they were, to put back.
	local air: Atmosphere? = nil
	local airDensity = 0
	local blurs: { DepthOfFieldEffect } = {}
	local ambient: { Color3 }? = nil

	local function near(i: Instance): boolean
		local part = if i:IsA("BasePart") then i else i.Parent
		if not (part and part:IsA("BasePart")) then
			return false
		end
		return (part.Position - middle).Magnitude - part.Size.Magnitude / 2 < reach
	end

	-- Whether a top-level Workspace child stays whole: the camera, terrain, a player's character.
	local function spared(top: Instance): boolean
		return top == Workspace.CurrentCamera
			or top == Workspace.Terrain
			or (top:IsA("Model") and Players:GetPlayerFromCharacter(top) ~= nil)
	end

	local function hide(i: Instance)
		local k = keep
		if k and i:IsDescendantOf(k) then
			return
		end
		if not near(i) then
			return
		end
		if i:IsA("LayerCollector") then
			if i.Enabled then
				i.Enabled = false
				table.insert(switched, i)
			end
		else
			(i :: any).LocalTransparencyModifier = 1 -- any: BasePart, Decal and Texture all have it
			table.insert(hidden, i)
		end
	end

	local function drop()
		local a = added
		added = nil
		if a then
			a:Disconnect()
		end
		for _, i in hidden do
			(i :: any).LocalTransparencyModifier = 0 -- any: as `hide`
		end
		table.clear(hidden)
		for _, gui in switched do
			gui.Enabled = true
		end
		table.clear(switched)
		local g = ground
		ground = nil
		if g then
			g:Destroy()
		end
		keep = nil
		local a2 = air
		air = nil
		if a2 then
			a2.Density = airDensity
		end
		for _, b in blurs do
			b.Enabled = true
		end
		table.clear(blurs)
		local was = ambient
		ambient = nil
		if was then
			Lighting.Ambient, Lighting.OutdoorAmbient = was[1], was[2]
		end
	end

	local function lift(unit: Model, centre: Vector3, floor: number)
		if keep == unit then
			return
		end
		drop()
		keep, middle = unit, centre
		for _, top in Workspace:GetChildren() do
			if not spared(top) then
				if shows(top) then
					hide(top)
				end
				for _, d in top:GetDescendants() do
					if shows(d) then
						hide(d)
					end
				end
			end
		end
		added = Workspace.DescendantAdded:Connect(function(d: Instance)
			if shows(d) then
				local top = topOf(d)
				if top and not spared(top) then
					hide(d)
				end
			end
		end)
		-- The dark floor: flat-coloured whatever lights it (Neon draws its own colour), so the
		-- room sits on an even dark, a hair under its own floor.
		local g = Instance.new("Part")
		g.Name = "ArrangeStage"
		g.Anchored = true
		g.CanCollide = false
		g.CanQuery = false
		g.CanTouch = false
		g.CastShadow = false
		g.Material = Enum.Material.Neon
		g.Color = colour
		g.Size = Vector3.new(reach * 2, 0.2, reach * 2)
		g.CFrame = CFrame.new(centre.X, floor - 0.15, centre.Z)
		g.Parent = Workspace.CurrentCamera
		ground = g
		local a = Lighting:FindFirstChildOfClass("Atmosphere")
		if a then
			air, airDensity = a, a.Density
			a.Density = 0
		end
		ambient = { Lighting.Ambient, Lighting.OutdoorAmbient }
		Lighting.Ambient, Lighting.OutdoorAmbient = light, light
		for _, e in Lighting:GetChildren() do
			if e:IsA("DepthOfFieldEffect") and e.Enabled then
				e.Enabled = false
				table.insert(blurs, e)
			end
		end
	end

	return {
		lift = lift,
		drop = drop,
		destroy = drop,
	}
end

return ArrangeStage
