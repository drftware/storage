--!strict
--[[
	Carts: the lobby's platform carts on the server (L-08e4b1, GDD "The lobby", Cart.Ride). Each
	parked cart in the rack wears a Ride button on its handle. Tap it and you're stood on its
	deck facing the handle (its hidden Seat), the cart is set free of its anchors and handed to
	your screen, which rolls it (CartRide): your screen moves it, the server watches.

	One rider a cart. The server keeps it honest: every half second it checks the cart hasn't
	gone further than a cart can roll (Ride.tooFast) and is still inside the front office, short
	of the cars' striped band; a cart that fails is taken back where it last passed and its rider
	put off. Jump (or the band) puts you off: the cart rolls on a moment on your screen, then the
	server parks it where it stopped, anchored, its trailing casters as they swung, the button
	back. Leaving, dying or a respawn parks it at once.
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Brix = require(ReplicatedStorage.Brix)
local Cart = require(ReplicatedStorage.Shared.Cart)
local FrontOffice = require(script.Parent.FrontOffice)
local Lobby = require(ReplicatedStorage.Shared.Lobby)
local Prompts = require(script.Parent.Prompts)

local Ride = Cart.Ride

-- The button: reached from about a door's reach of the handle.
local REACH = 7
-- A player gets on at most this often (seconds): a hammered button can't flicker a cart.
local MOUNT_GAP = 0.6
-- Where the button sits: just over the handle's grip, clear of the steel for its line of sight.
local BUTTON_RISE = 0.35

type Run = {
	model: Model,
	body: BasePart,
	seat: Seat,
	prompt: ProximityPrompt,
	rider: Player?, -- riding it now
	coaster: Player?, -- hopped off; their screen rolls it to a stop
	look: number, -- os.clock() of the last speed look
	lookAt: Vector3, -- where it was then
	good: CFrame, -- its pivot at the last look it passed
	stillAt: Vector3, -- coasting: where it last moved to
	stillSince: number,
	coastSince: number,
	died: RBXScriptConnection?,
}

local Carts = {}

-- A pivot stood level on the lobby's floor, keeping only its turn about Y.
local function level(at: CFrame): CFrame
	local look = at.LookVector
	local yaw = math.atan2(-look.X, -look.Z)
	local p = at.Position
	return CFrame.new(p.X, Lobby.Origin.Position.Y, p.Z) * CFrame.Angles(0, yaw, 0)
end

-- Whether a cart's middle at `p` is inside the front office, short of the cars' band (with a
-- stud's slack for the network).
local function inside(p: Vector3): boolean
	local l = Lobby.Origin:PointToObjectSpace(p)
	local room = Lobby.Specs.Room
	return math.abs(l.X) <= room.Width / 2
		and l.Z >= -room.Depth
		and l.Z <= -Ride.Band + 1
		and math.abs(l.Y) <= 2
end

function Carts.new(): Brix.System
	local runs: { [Model]: Run } = {}
	local riding: { [Player]: Run } = {}
	local mounted: { [Player]: number } = {}
	local connections: { RBXScriptConnection } = {}

	local function unseat(r: Run)
		local weld = r.seat:FindFirstChild("SeatWeld")
		if weld then
			weld:Destroy()
		end
	end

	local function release(r: Run)
		local died = r.died
		if died then
			died:Disconnect()
			r.died = nil
		end
		for _, p in { r.rider, r.coaster } do
			if p and riding[p] == r then
				riding[p] = nil
			end
		end
		r.rider, r.coaster = nil, nil
	end

	-- Stands the cart where `at` says (or where it is), anchored, ready for the next rider.
	local function park(r: Run, at: CFrame?)
		release(r)
		unseat(r)
		Cart.anchor(r.model, true)
		local where = level(at or r.model:GetPivot())
		r.model:PivotTo(where)
		-- ridden handle first, its trailing casters swung round behind them
		Cart.swivel(r.model, { 180, 180 })
		r.good = where
		r.model:SetAttribute(Cart.RiderAttribute, nil)
		r.model:SetAttribute(Cart.CoastAttribute, nil)
		r.prompt.Enabled = true
	end

	local function alive(player: Player): (Humanoid?, BasePart?)
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if humanoid and humanoid.Health > 0 and root and root:IsA("BasePart") then
			return humanoid, root
		end
		return nil, nil
	end

	local function mount(r: Run, player: Player)
		-- range: a parked cart, a free, living player in reach, not too soon after their last
		if r.rider or r.coaster or not r.body.Anchored or riding[player] then
			return
		end
		if Prompts.wrapped(player) then
			return
		end
		local humanoid, root = alive(player)
		if not (humanoid and root) or humanoid.SeatPart then
			return
		end
		local t = os.clock()
		if t - (mounted[player] or -math.huge) < MOUNT_GAP then
			return
		end
		local button = r.prompt.Parent
		if not (button and button:IsA("Attachment")) then
			return
		end
		if (root.Position - button.WorldPosition).Magnitude > REACH + 3 then
			return
		end
		mounted[player] = t
		-- stood on the mat facing the handle, whatever the body's size: put there first, so
		-- the seat's weld finds you where it holds you and the cart stays in its slot
		local hip = if humanoid.RigType == Enum.HumanoidRigType.R15
			then humanoid.HipHeight + root.Size.Y / 2
			else 3
		local stand = r.seat.CFrame * CFrame.new(0, hip, 0)
		local character = player.Character :: Model
		character:PivotTo(stand * root.CFrame:ToObjectSpace(character:GetPivot()))
		Cart.anchor(r.model, false)
		r.seat:Sit(humanoid)
		local weld = r.seat:FindFirstChild("SeatWeld")
		if not (weld and weld:IsA("Weld")) then
			Cart.anchor(r.model, true)
			return
		end
		weld.C0 = CFrame.new(0, hip, 0)
		weld.C1 = CFrame.identity
		r.body:SetNetworkOwner(player)
		r.rider = player
		riding[player] = r
		local p = r.body.Position
		r.look, r.lookAt = t, p
		r.good = level(r.model:GetPivot())
		r.died = humanoid.Died:Connect(function()
			park(r)
		end)
		r.prompt.Enabled = false
		r.model:SetAttribute(Cart.CoastAttribute, nil)
		r.model:SetAttribute(Cart.RiderAttribute, player.UserId)
	end

	-- The seat lost its rider: a jump, the band, a respawn or a leave.
	local function seatChanged(r: Run)
		local occupant = r.seat.Occupant
		local rider = r.rider
		if occupant then
			-- only Ride seats anyone; anyone else is put off
			local owner = rider and rider.Character
			if not (owner and occupant.Parent == owner) then
				unseat(r)
			end
			return
		end
		if not rider then
			return
		end
		local humanoid = alive(rider)
		if not (humanoid and rider.Parent) or r.body.Anchored then
			park(r)
			return
		end
		-- they hopped off: their screen rolls it on to a stop
		r.rider = nil
		r.coaster = rider
		local t = os.clock()
		r.coastSince, r.stillSince, r.stillAt = t, t, r.body.Position
		r.model:SetAttribute(Cart.RiderAttribute, nil)
		r.model:SetAttribute(Cart.CoastAttribute, rider.UserId)
	end

	local function add(model: Model)
		if runs[model] then
			return
		end
		local body = model:FindFirstChild(Cart.Body)
		if not (body and body:IsA("BasePart")) then
			return
		end
		Cart.rig(model)
		local found = model:FindFirstChild(Cart.Seat)
		if not (found and found:IsA("Seat")) then
			return
		end
		local seat = found
		local button = Instance.new("Attachment")
		button.Name = "RideButton"
		button.Parent = body
		button.WorldCFrame = model:GetPivot()
			* CFrame.new(Cart.Specs.Handle + Vector3.new(0, BUTTON_RISE, 0))
		local prompt = Prompts.make(button, {
			actionText = "Ride",
			key = Enum.KeyCode.E,
			pad = Enum.KeyCode.ButtonX,
			reach = REACH,
		})
		local t = os.clock()
		local r: Run = {
			model = model,
			body = body,
			seat = seat,
			prompt = prompt,
			rider = nil,
			coaster = nil,
			look = t,
			lookAt = body.Position,
			good = level(model:GetPivot()),
			stillAt = body.Position,
			stillSince = t,
			coastSince = t,
			died = nil,
		}
		runs[model] = r
		table.insert(
			connections,
			prompt.Triggered:Connect(function(player: Player)
				mount(r, player)
			end)
		)
		table.insert(
			connections,
			seat:GetPropertyChangedSignal("Occupant"):Connect(function()
				seatChanged(r)
			end)
		)
		model:AddTag(Cart.Tag)
	end

	local function gone(player: Player)
		mounted[player] = nil
		local r = riding[player]
		if r then
			park(r)
		end
	end

	return {
		name = "Carts",
		start = function(_: any, context: Brix.Context)
			-- any: the registry hands back a plain System; FrontOffice fills this slot (init.server)
			local office = (context.registry:get("frontOffice") :: any) :: FrontOffice.FrontOffice
			local laid = office:laid()
			if not laid then
				return
			end
			local dressing = laid.folder:FindFirstChild("Dressing")
			if not dressing then
				return
			end
			for _, m in dressing:GetChildren() do
				if m:IsA("Model") and m.Name:match("^Cart%d+$") then
					add(m)
				end
			end
			table.insert(connections, Players.PlayerRemoving:Connect(gone))
		end,
		-- Only carts out of the rack: their pace and place checked, a coast's end found.
		step = function(_: any, _dt: number)
			if next(riding) == nil then
				return
			end
			local t = os.clock()
			for _, r in runs do
				if not (r.rider or r.coaster) then
					continue
				end
				local p = r.body.Position
				if t - r.look >= Ride.CheckEvery then
					local d = Vector3.new(p.X - r.lookAt.X, 0, p.Z - r.lookAt.Z).Magnitude
					if Ride.tooFast(d, t - r.look) or not inside(r.model:GetPivot().Position) then
						-- too far, too fast, or out of the room: back where it last passed
						local who = r.rider or r.coaster
						warn(`Carts: {r.model.Name} taken back from {who and who.Name or "?"}`)
						park(r, r.good)
						continue
					end
					r.look, r.lookAt = t, p
					r.good = level(r.model:GetPivot())
				end
				if r.coaster then
					if (p - r.stillAt).Magnitude > 0.05 then
						r.stillAt, r.stillSince = p, t
					elseif t - r.stillSince >= Ride.StillFor then
						park(r)
						continue
					end
					if t - r.coastSince >= Ride.CoastMax then
						park(r)
					end
				end
			end
		end,
		stop = function(_: any)
			for _, c in connections do
				c:Disconnect()
			end
			table.clear(connections)
			for _, r in runs do
				if r.rider or r.coaster then
					park(r)
				end
				r.model:RemoveTag(Cart.Tag)
			end
			table.clear(runs)
		end,
	}
end

return Carts
