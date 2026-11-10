--!strict
--[[
	Minimaps: the server's side of the corner map (L-10, D-094). Each laid floor gets its layout as
	shapes (`Minimap.encode`, never its seed: that would give away the code and every unit's
	contents) and its frame, on its model, tagged `Minimap.Tag`, so every screen draws the same
	floor. As the deal first shows a unit's inside (a peek, an open, a lift from inside, a saw's
	hole: `Deals.dealt`), its slot joins the floor's opened list, and every screen ticks it, so
	friends know a unit's been searched without asking. The server owns the list; a screen only
	reads it.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Brix = require(ReplicatedStorage.Brix)
local Deals = require(script.Parent.Deals)
local Floor = require(ReplicatedStorage.Shared.Floor)
local Minimap = require(ReplicatedStorage.Shared.Minimap)

type Area = {
	model: Instance,
	units: { [Model]: number }, -- each unit's slot
	opened: { number }, -- slots opened so far, in the order they were
	ticked: { [number]: boolean },
}

export type Minimaps = Brix.System & {
	-- Puts `floor`'s map on `model` for every screen, in the frame of `origin`, and ticks each of
	-- `units` (FloorBuilder's `Laid.slots`) as the deal first shows its inside, until `model` is
	-- destroyed.
	add: (
		self: any,
		floor: Floor.Floor,
		units: { [Model]: number },
		model: Instance,
		origin: CFrame
	) -> (),
}

local Minimaps = {}

function Minimaps.new(): Minimaps
	local areas: { Area } = {}
	local gone: { [Instance]: RBXScriptConnection } = {}
	local connections: { Brix.SignalConnection } = {}

	local function onDealt(dealt: Deals.Dealt)
		for _, area in areas do
			local slot = area.units[dealt.unit]
			if slot and not area.ticked[slot] then
				area.ticked[slot] = true
				table.insert(area.opened, slot)
				area.model:SetAttribute(Minimap.OpenedAttribute, Minimap.encodeOpened(area.opened))
				return
			end
		end
	end

	local system = { name = "Minimaps" }

	function system.add(
		_: any,
		floor: Floor.Floor,
		units: { [Model]: number },
		model: Instance,
		origin: CFrame
	)
		if gone[model] then
			return
		end
		local area: Area = { model = model, units = units, opened = {}, ticked = {} }
		table.insert(areas, area)
		model:SetAttribute(Minimap.LayoutAttribute, Minimap.encode(Minimap.from(floor)))
		model:SetAttribute(Minimap.OriginAttribute, origin)
		model:SetAttribute(Minimap.OpenedAttribute, "")
		model:AddTag(Minimap.Tag)
		gone[model] = model.Destroying:Connect(function()
			local i = table.find(areas, area)
			if i then
				table.remove(areas, i)
			end
			local c = gone[model]
			if c then
				c:Disconnect()
				gone[model] = nil
			end
		end)
	end

	function system.start(_: any, context: Brix.Context)
		local deals = (context.registry:get("deals") :: any) :: Deals.Deals? -- any: the registry's
		if deals then
			table.insert(connections, deals.dealt:connect(onDealt))
		else
			warn("Minimaps: no Deals system, so no unit is ever ticked on the map")
		end
	end

	function system.stop(_: any)
		for _, c in connections do
			c:disconnect()
		end
		table.clear(connections)
		for _, c in gone do
			c:Disconnect()
		end
		table.clear(gone)
		table.clear(areas)
	end

	return system :: any -- any: the table above is the Minimaps shape, built a field at a time
end

return Minimaps
