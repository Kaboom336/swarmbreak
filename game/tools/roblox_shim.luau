-- A small fake of the Roblox API, enough to run the part builders (EnemyBuilder, WeaponModels,
-- ArenaBuilder) outside Studio and export their geometry. Not a game engine: no physics, no rendering.
local Shim = {}

-- ---------- Vector3 ----------
local Vector3 = {}
Vector3.__index = Vector3
local function v3(x, y, z)
	return setmetatable({ X = x or 0, Y = y or 0, Z = z or 0 }, Vector3)
end
Vector3.new = v3
Vector3.zero = v3(0, 0, 0)
Vector3.one = v3(1, 1, 1)
Vector3.xAxis = v3(1, 0, 0)
Vector3.yAxis = v3(0, 1, 0)
Vector3.zAxis = v3(0, 0, 1)
Vector3.__add = function(a, b)
	return v3(a.X + b.X, a.Y + b.Y, a.Z + b.Z)
end
Vector3.__sub = function(a, b)
	return v3(a.X - b.X, a.Y - b.Y, a.Z - b.Z)
end
Vector3.__unm = function(a)
	return v3(-a.X, -a.Y, -a.Z)
end
Vector3.__mul = function(a, b)
	if type(a) == "number" then
		return v3(a * b.X, a * b.Y, a * b.Z)
	elseif type(b) == "number" then
		return v3(a.X * b, a.Y * b, a.Z * b)
	end
	return v3(a.X * b.X, a.Y * b.Y, a.Z * b.Z)
end
Vector3.__div = function(a, b)
	return v3(a.X / b, a.Y / b, a.Z / b)
end
Vector3.__eq = function(a, b)
	return a.X == b.X and a.Y == b.Y and a.Z == b.Z
end
Vector3.__tostring = function(a)
	return string.format("%.2f, %.2f, %.2f", a.X, a.Y, a.Z)
end
function Vector3:Dot(b)
	return self.X * b.X + self.Y * b.Y + self.Z * b.Z
end
function Vector3:Cross(b)
	return v3(self.Y * b.Z - self.Z * b.Y, self.Z * b.X - self.X * b.Z, self.X * b.Y - self.Y * b.X)
end
local vecIndex = Vector3.__index
Vector3.__index = function(t, k)
	if k == "Magnitude" then
		return math.sqrt(t.X * t.X + t.Y * t.Y + t.Z * t.Z)
	elseif k == "Unit" then
		local m = math.sqrt(t.X * t.X + t.Y * t.Y + t.Z * t.Z)
		if m == 0 then
			return v3(0, 0, 0)
		end
		return v3(t.X / m, t.Y / m, t.Z / m)
	end
	return vecIndex[k]
end

local Vector2 = {
	new = function(x, y)
		return { X = x, Y = y }
	end,
}

-- ---------- CFrame (position + 3x3 rotation, row-major r[i][j]) ----------
local CFrame = {}
CFrame.__index = CFrame
local function identityR()
	return { { 1, 0, 0 }, { 0, 1, 0 }, { 0, 0, 1 } }
end
local function mulR(a, b)
	local r = {}
	for i = 1, 3 do
		r[i] = {}
		for j = 1, 3 do
			r[i][j] = a[i][1] * b[1][j] + a[i][2] * b[2][j] + a[i][3] * b[3][j]
		end
	end
	return r
end
local function rotV(r, v)
	return v3(
		r[1][1] * v.X + r[1][2] * v.Y + r[1][3] * v.Z,
		r[2][1] * v.X + r[2][2] * v.Y + r[2][3] * v.Z,
		r[3][1] * v.X + r[3][2] * v.Y + r[3][3] * v.Z
	)
end
local function transposeR(r)
	return {
		{ r[1][1], r[2][1], r[3][1] },
		{ r[1][2], r[2][2], r[3][2] },
		{ r[1][3], r[2][3], r[3][3] },
	}
end
local function cf(p, r)
	return setmetatable({ p = p, r = r }, CFrame)
end
CFrame.new = function(a, b, c, ...)
	local m = { ... }
	if #m == 9 then
		return cf(v3(a, b, c), { { m[1], m[2], m[3] }, { m[4], m[5], m[6] }, { m[7], m[8], m[9] } })
	end
	if a == nil then
		return cf(v3(0, 0, 0), identityR())
	elseif type(a) == "number" then
		return cf(v3(a, b, c), identityR())
	else
		return cf(v3(a.X, a.Y, a.Z), identityR())
	end
end
CFrame.identity = CFrame.new()
CFrame.Angles = function(rx, ry, rz)
	local cx, sx = math.cos(rx), math.sin(rx)
	local cy, sy = math.cos(ry), math.sin(ry)
	local cz, sz = math.cos(rz), math.sin(rz)
	local Rx = { { 1, 0, 0 }, { 0, cx, -sx }, { 0, sx, cx } }
	local Ry = { { cy, 0, sy }, { 0, 1, 0 }, { -sy, 0, cy } }
	local Rz = { { cz, -sz, 0 }, { sz, cz, 0 }, { 0, 0, 1 } }
	return cf(v3(0, 0, 0), mulR(Rx, mulR(Ry, Rz)))
end
CFrame.fromEulerAnglesXYZ = CFrame.Angles
CFrame.lookAt = function(at, target, up)
	up = up or v3(0, 1, 0)
	local f = (target - at).Unit
	if f.Magnitude == 0 then
		return CFrame.new(at)
	end
	if math.abs(f:Dot(up)) > 0.999 then
		up = v3(0, 0, 1)
	end
	local right = f:Cross(up).Unit
	local up2 = right:Cross(f)
	local r = { { right.X, up2.X, -f.X }, { right.Y, up2.Y, -f.Y }, { right.Z, up2.Z, -f.Z } }
	return cf(v3(at.X, at.Y, at.Z), r)
end
CFrame.__mul = function(a, b)
	if getmetatable(b) == Vector3 then
		return a.p + rotV(a.r, b)
	end
	return cf(a.p + rotV(a.r, b.p), mulR(a.r, b.r))
end
CFrame.__add = function(a, v)
	return cf(a.p + v, a.r)
end
CFrame.__sub = function(a, v)
	return cf(a.p - v, a.r)
end
function CFrame:Inverse()
	local rt = transposeR(self.r)
	return cf(-rotV(rt, self.p), rt)
end
function CFrame:ToWorldSpace(other)
	return self * other
end
function CFrame:ToObjectSpace(other)
	return self:Inverse() * other
end
local cfIndex = CFrame.__index
CFrame.__index = function(t, k)
	if k == "Position" then
		return t.p
	elseif k == "LookVector" then
		return v3(-t.r[1][3], -t.r[2][3], -t.r[3][3])
	elseif k == "RightVector" then
		return v3(t.r[1][1], t.r[2][1], t.r[3][1])
	elseif k == "UpVector" then
		return v3(t.r[1][2], t.r[2][2], t.r[3][2])
	elseif k == "X" then
		return t.p.X
	elseif k == "Y" then
		return t.p.Y
	elseif k == "Z" then
		return t.p.Z
	end
	return cfIndex[k]
end

-- ---------- Color3 ----------
local Color3 = {}
Color3.__index = Color3
local function c3(r, g, b)
	return setmetatable({ R = r, G = g, B = b }, Color3)
end
Color3.new = function(r, g, b)
	return c3(r or 0, g or 0, b or 0)
end
Color3.fromRGB = function(r, g, b)
	return c3(r / 255, g / 255, b / 255)
end
function Color3:Lerp(o, t)
	return c3(self.R + (o.R - self.R) * t, self.G + (o.G - self.G) * t, self.B + (o.B - self.B) * t)
end

-- ---------- Enum: any path resolves to its last name (and .Value = 0) ----------
local function enumNode(path)
	return setmetatable({ Name = path, Value = 0 }, {
		__index = function(_, k)
			return enumNode(k)
		end,
		__tostring = function()
			return path
		end,
	})
end
local Enum = enumNode("Enum")

-- ---------- misc value types ----------
local function anyNew()
	return {
		new = function(...)
			return { ... }
		end,
	}
end
local NumberRange = anyNew()
local NumberSequence = anyNew()
local NumberSequenceKeypoint = anyNew()
local ColorSequence = anyNew()
local UDim2 = {
	new = function(...)
		return { ... }
	end,
	fromScale = function(...)
		return { ... }
	end,
	fromOffset = function(...)
		return { ... }
	end,
}
local UDim = anyNew()
local TweenInfo = anyNew()
local RaycastParams = {
	new = function()
		return {}
	end,
}

local Random = {}
Random.__index = Random
Random.new = function(seed)
	return setmetatable({ s = seed or 1 }, Random)
end
function Random:NextNumber(a, b)
	self.s = (self.s * 1103515245 + 12345) % 2147483648
	local r = self.s / 2147483648
	if a == nil then
		return r
	end
	return a + (b - a) * r
end
function Random:NextInteger(a, b)
	return math.floor(self:NextNumber(a, b + 1))
end

-- ---------- Instances ----------
local Instance = {}
local classParents = {
	Part = "BasePart",
	MeshPart = "BasePart",
	WedgePart = "BasePart",
	SpawnLocation = "BasePart",
	BasePart = "PVInstance",
	Model = "PVInstance",
	Folder = "Instance",
	PointLight = "Light",
	Script = "Instance",
}
local function isA(class, want)
	while class do
		if class == want then
			return true
		end
		class = classParents[class] or (class ~= "Instance" and "Instance" or nil)
	end
	return false
end

local Inst = {}
Inst.__index = function(t, k)
	local raw = rawget(t, "_props")[k]
	if raw ~= nil then
		return raw
	end
	local m = Inst[k]
	if m then
		return m
	end
	-- child lookup by name (Roblox allows model.Child)
	for _, c in rawget(t, "_children") do
		if c.Name == k then
			return c
		end
	end
	if k == "Position" then
		return t._props.CFrame and t._props.CFrame.Position or v3()
	end
	return nil
end
Inst.__newindex = function(t, k, val)
	if k == "Parent" then
		local old = t._props.Parent
		if old then
			local ch = old._children
			for i, c in ch do
				if c == t then
					table.remove(ch, i)
					break
				end
			end
		end
		t._props.Parent = val
		if val then
			table.insert(val._children, t)
		end
		return
	elseif k == "Position" then
		local old = t._props.CFrame or CFrame.new()
		t._props.CFrame = cf(v3(val.X, val.Y, val.Z), old.r)
		return
	end
	t._props[k] = val
end
Inst.__tostring = function(t)
	return t.Name
end
function Inst:IsA(class)
	return isA(self.ClassName, class)
end
function Inst:GetChildren()
	return table.clone(self._children)
end
function Inst:GetDescendants()
	local out = {}
	local function walk(n)
		for _, c in n._children do
			table.insert(out, c)
			walk(c)
		end
	end
	walk(self)
	return out
end
function Inst:FindFirstChild(name, recursive)
	for _, c in self._children do
		if c.Name == name then
			return c
		end
	end
	if recursive then
		for _, c in self._children do
			local f = c:FindFirstChild(name, true)
			if f then
				return f
			end
		end
	end
	return nil
end
Inst.WaitForChild = Inst.FindFirstChild
function Inst:FindFirstChildWhichIsA(class)
	for _, c in self._children do
		if c:IsA(class) then
			return c
		end
	end
	return nil
end
function Inst:FindFirstChildOfClass(class)
	for _, c in self._children do
		if c.ClassName == class then
			return c
		end
	end
	return nil
end
function Inst:FindFirstAncestorOfClass(class)
	local p = self._props.Parent
	while p do
		if p.ClassName == class then
			return p
		end
		p = p._props.Parent
	end
	return nil
end
function Inst:IsDescendantOf(other)
	local p = self._props.Parent
	while p do
		if p == other then
			return true
		end
		p = p._props.Parent
	end
	return false
end
function Inst:Destroy()
	self.Parent = nil
end
function Inst:ClearAllChildren()
	for _, c in table.clone(self._children) do
		c.Parent = nil
	end
end
function Inst:SetAttribute(k, v)
	self._attrs[k] = v
end
function Inst:GetAttribute(k)
	return self._attrs[k]
end
function Inst:GetAttributeChangedSignal()
	return {
		Connect = function()
			return { Disconnect = function() end }
		end,
	}
end
function Inst:Clone()
	local c = Instance.new(self.ClassName)
	for k, val in self._props do
		if k ~= "Parent" then
			c._props[k] = val
		end
	end
	for _, ch in self._children do
		ch:Clone().Parent = c
	end
	return c
end
local function partBounds(part)
	local c = part._props.CFrame or CFrame.new()
	local s = part._props.Size or v3(1, 1, 1)
	local minv, maxv = v3(math.huge, math.huge, math.huge), v3(-math.huge, -math.huge, -math.huge)
	for _, sx in { -1, 1 } do
		for _, sy in { -1, 1 } do
			for _, sz in { -1, 1 } do
				local p = c * v3(sx * s.X / 2, sy * s.Y / 2, sz * s.Z / 2)
				minv = v3(math.min(minv.X, p.X), math.min(minv.Y, p.Y), math.min(minv.Z, p.Z))
				maxv = v3(math.max(maxv.X, p.X), math.max(maxv.Y, p.Y), math.max(maxv.Z, p.Z))
			end
		end
	end
	return minv, maxv
end
function Inst:GetBoundingBox()
	local minv, maxv = v3(math.huge, math.huge, math.huge), v3(-math.huge, -math.huge, -math.huge)
	for _, d in self:GetDescendants() do
		if d:IsA("BasePart") then
			local a, b = partBounds(d)
			minv = v3(math.min(minv.X, a.X), math.min(minv.Y, a.Y), math.min(minv.Z, a.Z))
			maxv = v3(math.max(maxv.X, b.X), math.max(maxv.Y, b.Y), math.max(maxv.Z, b.Z))
		end
	end
	return CFrame.new((minv + maxv) / 2), maxv - minv
end
function Inst:GetExtentsSize()
	local _, e = self:GetBoundingBox()
	return e
end
function Inst:PivotTo(target)
	local pp = self._props.PrimaryPart
	if not pp then
		return
	end
	local delta = target * pp._props.CFrame:Inverse()
	for _, d in self:GetDescendants() do
		if d:IsA("BasePart") then
			d._props.CFrame = delta * d._props.CFrame
		end
	end
end
function Inst:GetPivot()
	local pp = self._props.PrimaryPart
	return pp and pp._props.CFrame or CFrame.new()
end
function Inst:Connect()
	return { Disconnect = function() end }
end

local created = {}
Instance.new = function(class, parent)
	local t = setmetatable(
		{ _props = { Name = class, ClassName = class }, _children = {}, _attrs = {} },
		Inst
	)
	if isA(class, "BasePart") then
		t._props.Size = v3(4, 1, 2)
		t._props.CFrame = CFrame.new()
		t._props.Color = c3(0.6, 0.6, 0.6)
		t._props.Material = "Plastic"
		t._props.Shape = if class == "WedgePart" then "Wedge" else "Block"
		t._props.Transparency = 0
		t._props.Anchored = false
		t._props.CanCollide = true
	end
	table.insert(created, t)
	if parent then
		t.Parent = parent
	end
	return t
end
Shim.created = created

-- ---------- services ----------
local services = {}
local function service(name)
	if not services[name] then
		local s = Instance.new(name)
		s.Name = name
		services[name] = s
	end
	return services[name]
end
local game = setmetatable({}, {
	__index = function(_, k)
		if k == "GetService" then
			return function(_, name)
				return service(name)
			end
		end
		return service(k)
	end,
})
local workspace = service("Workspace")
workspace.Name = "Workspace"

-- ---------- export ----------
local function enumName(x)
	if type(x) == "table" and x.Name then
		return (x.Name:gsub("^.*%.", ""))
	end
	return tostring(x)
end
function Shim.exportParts(root)
	local out = {}
	for _, d in root:GetDescendants() do
		if d:IsA("BasePart") then
			local p = d._props
			local c = p.CFrame
			local mesh = d:FindFirstChildOfClass("SpecialMesh")
			table.insert(out, {
				name = p.Name,
				shape = if mesh then enumName(mesh._props.MeshType) else enumName(p.Shape),
				size = { p.Size.X, p.Size.Y, p.Size.Z },
				pos = { c.p.X, c.p.Y, c.p.Z },
				rot = {
					c.r[1][1],
					c.r[1][2],
					c.r[1][3],
					c.r[2][1],
					c.r[2][2],
					c.r[2][3],
					c.r[3][1],
					c.r[3][2],
					c.r[3][3],
				},
				color = { p.Color.R, p.Color.G, p.Color.B },
				material = enumName(p.Material),
				transparency = p.Transparency or 0,
				light = (function()
					local l = d:FindFirstChildOfClass("PointLight")
					return l
							and {
								l._props.Color
										and { l._props.Color.R, l._props.Color.G, l._props.Color.B }
									or { 1, 1, 1 },
								l._props.Range or 8,
							}
						or nil
				end)(),
				particles = d:FindFirstChildOfClass("Attachment") ~= nil,
			})
		end
	end
	return out
end

Shim.env = {
	Vector3 = Vector3,
	Vector2 = Vector2,
	CFrame = CFrame,
	Color3 = Color3,
	Enum = Enum,
	NumberRange = NumberRange,
	NumberSequence = NumberSequence,
	NumberSequenceKeypoint = NumberSequenceKeypoint,
	ColorSequence = ColorSequence,
	UDim2 = UDim2,
	UDim = UDim,
	TweenInfo = TweenInfo,
	RaycastParams = RaycastParams,
	Random = Random,
	Instance = Instance,
	game = game,
	workspace = workspace,
	task = {
		wait = function() end,
		spawn = function(f, ...)
			f(...)
		end,
		delay = function() end,
		defer = function() end,
	},
	warn = print,
	typeof = function(x)
		local mt = getmetatable(x)
		if mt == Vector3 then
			return "Vector3"
		elseif mt == CFrame then
			return "CFrame"
		end
		return type(x)
	end,
}
Shim.service = service
Shim.Instance = Instance
Shim.CFrame = CFrame
Shim.Vector3 = Vector3
return Shim
