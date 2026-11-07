-- Jìn Script v3.3 | Violence District
-- Menu: RightShift (PC) / tap logo (HP) | F6 = skill check on/off
-- Semua file (logo, ikon, config) ada di workspace/jin_hub/

-- FILE (taro di folder workspace/jin_hub/). Kosongin ID kalau pake file
local ICON_ID     = ""                  -- logo kamu: "rbxassetid://123456"
local ICON_URL    = ""                  -- atau link LANGSUNG ke png (didownload sekali)
local ICON_FILE   = "jin_icon.png"      -- logo kamu (png transparan)
local SHEET_ID    = ""                  -- spritesheet ikon UI (opsional kalau upload ke Roblox)
local SHEET_FILE  = "jin_icons.png"
local SOCIAL_ID   = ""                  -- spritesheet logo sosmed (opsional)
local SOCIAL_FILE = "jin_social.png"

-- LINK (isi link kamu, tap logonya = ke-copy)
local LINKS = {
    YouTube  = "",
    TikTok   = "",
    WhatsApp = "",
    Discord  = "",
}

if getgenv().JinHub then pcall(getgenv().JinHub.Unload) end
if getgenv().VDHub then pcall(getgenv().VDHub.Unload) end

local Players = game:GetService("Players")
local RS = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TS = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local lp = Players.LocalPlayer
local pg = lp:WaitForChild("PlayerGui")

local running, conns = true, {}
local function track(c) conns[#conns + 1] = c return c end
local function attach(o)
    local ok = pcall(function() o.Parent = game:GetService("CoreGui") end)
    if not ok or not o.Parent then
        pcall(function() o.Parent = (gethui and gethui()) or pg end)
        if not o.Parent then o.Parent = pg end
    end
end
local notify = function() end

----------------------------------------------------------------------
-- FOLDER + FILE
----------------------------------------------------------------------
local FOLDER = "jin_hub"
local BASE = ""
pcall(function()
    if makefolder and isfolder then
        if not isfolder(FOLDER) then makefolder(FOLDER) end
        if isfolder(FOLDER) then BASE = FOLDER .. "/" end
    end
end)
-- cari di jin_hub/ dulu, kalau belum dipindah cari di workspace langsung
local function findFile(name)
    if not isfile then return nil end
    for _, p in ipairs({BASE .. name, name}) do
        local ok, has = pcall(isfile, p)
        if ok and has then return p end
    end
end
local function assetOf(id, file)
    if id ~= "" then return id end
    if not getcustomasset then return nil end
    local p = findFile(file)
    if not p then return nil end
    local ok, a = pcall(getcustomasset, p)
    if ok and a and a ~= "" then return a end
end
local function loadLogo()
    if ICON_ID == "" and ICON_URL ~= "" and writefile and not findFile(ICON_FILE) then
        pcall(function() writefile(BASE .. ICON_FILE, game:HttpGet(ICON_URL)) end)
    end
    return assetOf(ICON_ID, ICON_FILE)
end
local EXEC = "Unknown"
pcall(function()
    local n = identifyexecutor and identifyexecutor()
    if n then EXEC = tostring(n) end
end)

----------------------------------------------------------------------
-- STATE
----------------------------------------------------------------------
local CATS = {
    {key = "survivor",  label = "Survivor (sehat)", color = {0, 255, 80}, on = true,  player = true},
    {key = "injured",   label = "Kena hit",  color = {255, 235, 0},   on = true,  player = true},
    {key = "knocked",   label = "Jatuh",     color = {255, 40, 40},   on = true,  player = true},
    {key = "hooked",    label = "Digantung", color = {130, 0, 0},     on = true,  player = true},
    {key = "chased",    label = "Chased (!)", color = {255, 140, 0},  on = true,  player = true},
    {key = "killer",    label = "Killer",    color = {0, 150, 255},   on = true,  player = true},
    {key = "generator", label = "Generator", color = {170, 80, 255},  on = true},
    {key = "pallet",    label = "Pallet",    color = {0, 230, 255},   on = false},
    {key = "window",    label = "Window",    color = {255, 235, 0},   on = false},
    {key = "hook",      label = "Hook",      color = {255, 105, 180}, on = false},
    {key = "pumpkin",   label = "Pumpkin",   color = {255, 140, 0},   on = false},
}
local CAT = {}
for _, c in ipairs(CATS) do CAT[c.key] = c end

local S = {
    cat = {}, names = true, dist = true, textSize = 13, maxDist = 600, chaseDist = 40, hookNear = 10,
    chaseCol = {Color3.fromRGB(0, 255, 80), Color3.fromRGB(255, 235, 0), Color3.fromRGB(255, 40, 40)}, -- ! ijo, !! kuning, !!! merah
    cone = {on = true, range = 70, angle = 100, color = Color3.fromRGB(255, 60, 60), transp = 0.75},
    sc = {enabled = true, mode = "Perfect"},
    fov = {on = false, val = 70},
    fb = {on = false, bright = 2},
    al = {particles = false, post = false, shadows = false, quality = false},
}
for _, c in ipairs(CATS) do
    S.cat[c.key] = {on = c.on, color = Color3.fromRGB(c.color[1], c.color[2], c.color[3])}
end

----------------------------------------------------------------------
-- ESP: ROLE (team "Survivors" / "Killer")
----------------------------------------------------------------------
local ROLE_KEYS = {role = 1, team = 1, class = 1, type = 1, side = 1, faction = 1, roletype = 1, playertype = 1}
local KILLER_BOOL = {iskiller = 1, isslasher = 1}

local function attrRole(inst)
    if not inst then return nil end
    for k, v in pairs(inst:GetAttributes()) do
        local kl = k:lower()
        if KILLER_BOOL[kl] and type(v) == "boolean" then return v and "killer" or "survivor" end
        if ROLE_KEYS[kl] and type(v) == "string" then
            local s = v:lower()
            if s:find("killer") or s:find("slasher") then return "killer" end
            if s:find("survivor") then return "survivor" end
        end
    end
    return nil
end
local function roleOf(plr)
    if plr.Team then
        local t = plr.Team.Name:lower()
        if t:find("killer") or t:find("slasher") then return "killer" end
        if t:find("survivor") then return "survivor" end
    end
    return attrRole(plr) or attrRole(plr.Character) or "survivor"
end

----------------------------------------------------------------------
-- ESP: OBJEK (Generator / Pallet / Hook / Window)
----------------------------------------------------------------------
local MATCH = {
    generator = function(i) return i:IsA("Model") and i.Name:lower() == "generator" end,
    window    = function(i) return i:IsA("PVInstance") and i.Name:lower() == "window" end,
    hook      = function(i) return i:IsA("Model") and i.Name:lower() == "hook" end,
    pallet    = function(i)
        if not i:IsA("Model") then return false end
        local n = i.Name:lower()
        return n ~= "pallets" and n:find("pallet") ~= nil and n:find("point") == nil and n:find("slide") == nil
    end,
    pumpkin   = function(i)
        if not i:IsA("PVInstance") then return false end
        local n = i.Name:lower()
        return n:find("pumpkin") ~= nil or n:find("labu") ~= nil
    end,
}
local found = {}
for cat in pairs(MATCH) do found[cat] = {} end

local function topmost(cat, i)
    local p = i.Parent
    return not (p and p ~= workspace and MATCH[cat](p))
end
local function inCharacter(i)
    local p = i.Parent
    while p and p ~= workspace do
        if Players:GetPlayerFromCharacter(p) then return true end
        p = p.Parent
    end
    return false
end
local function classify(i)
    local n = i.Name:lower()
    if not (n:find("generator") or n:find("window") or n:find("pallet") or n:find("hook") or n:find("pumpkin") or n:find("labu")) then return end
    for cat, f in pairs(MATCH) do
        if f(i) and topmost(cat, i) and not inCharacter(i) then found[cat][i] = true return end
    end
end

----------------------------------------------------------------------
-- ESP: STATUS SURVIVOR (hooked > knocked > chased)
-- urutan cek: attribute / Value di Player+Character -> animasi yang lagi jalan -> fallback jarak
--   hooked  harus dalam S.hookNear stud dari model Hook; flag hooked tapi jauh dari Hook = jatuh/merangkak (knocked)
--   chased  fallback: killer dalam S.chaseDist stud dan ga ketutup tembok (raycast)
-- kalau game pake nama lain, edit STATE_KEYS / ANIM_KEYS (cek namanya: Settings > Scan status pemain)
----------------------------------------------------------------------
local STATE_KEYS = {
    hooked  = {"hook", "sacrific", "caged"},
    knocked = {"knock", "downed", "isdown", "dying", "crawl", "incap", "carried"},
    chased  = {"chase", "pursu"},
}
local ANIM_KEYS = {
    hooked  = {"hook", "hang"},
    knocked = {"crawl", "knock", "downed", "dying", "incap"},
}
local STATE_ORDER = {"hooked", "knocked", "chased"}
local TAG = {hooked = "HOOK", knocked = "DOWN", injured = "HIT"}

local function hasKey(s, list)
    for _, k in ipairs(list) do
        if s:find(k, 1, true) then return true end
    end
    return false
end
local function mark(text, st)
    if text:find("unhook", 1, true) then return end
    for _, s in ipairs(STATE_ORDER) do
        if hasKey(text, STATE_KEYS[s]) then st[s] = true end
    end
end
local function isStateName(n)
    return n:find("state", 1, true) or n:find("status", 1, true) or n:find("condition", 1, true)
end
local function scanObj(inst, st)
    if not inst then return end
    for k, v in pairs(inst:GetAttributes()) do
        local kl = k:lower()
        if type(v) == "boolean" then
            if v then mark(kl, st) end
        elseif type(v) == "string" and isStateName(kl) then
            mark(v:lower(), st)
        end
    end
    for _, c in ipairs(inst:GetChildren()) do
        if c:IsA("BoolValue") then
            if c.Value then mark(c.Name:lower(), st) end
        elseif c:IsA("StringValue") then
            if isStateName(c.Name:lower()) then mark(c.Value:lower(), st) end
        end
    end
end
local function scanAnims(hum, st)
    local an = hum:FindFirstChildOfClass("Animator")
    if not an then return end
    local ok, tracks = pcall(function() return an:GetPlayingAnimationTracks() end)
    if not ok then return end
    for _, t in ipairs(tracks) do
        local n = t.Name:lower()
        if not n:find("unhook", 1, true) then
            for s, keys in pairs(ANIM_KEYS) do
                if hasKey(n, keys) then st[s] = true end
            end
        end
    end
end

local chaseRP = RaycastParams.new()
chaseRP.FilterType = Enum.RaycastFilterType.Exclude

local function getKillers()
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if roleOf(p) == "killer" then
            local kc = p.Character
            local kh = kc and kc:FindFirstChild("HumanoidRootPart")
            if kh then list[#list + 1] = {char = kc, hrp = kh} end
        end
    end
    return list
end

local function nearHook(pos)
    local have = false
    for h in pairs(found.hook) do
        if h.Parent then
            have = true
            local ok, d = pcall(function() return (h:GetPivot().Position - pos).Magnitude end)
            if ok and d <= S.hookNear then return true, true end
        end
    end
    return false, have   -- have=false: model Hook ga ketemu, ga bisa diverifikasi
end

local function survivorState(plr, char, hum, hrp, killers)
    local st = {}
    scanObj(plr, st)
    scanObj(char, st)
    scanAnims(hum, st)
    if not st.chased and S.chaseDist > 0 then
        for _, k in ipairs(killers) do
            local delta = hrp.Position - k.hrp.Position
            if delta.Magnitude <= S.chaseDist then
                chaseRP.FilterDescendantsInstances = {k.char, char}
                if not workspace:Raycast(k.hrp.Position, delta, chaseRP) then
                    st.chased = true
                    break
                end
            end
        end
    end
    if st.hooked then
        local near, have = nearHook(hrp.Position)
        if have and not near then st.hooked, st.knocked = nil, true end
    end
    -- warna: hooked > knocked > kena hit (HP < max) > sehat. chased = icon "!" terpisah
    local key = "survivor"
    if st.hooked then key = "hooked"
    elseif st.knocked then key = "knocked"
    elseif hum.Health < hum.MaxHealth - 0.5 then key = "injured" end
    return key, st.chased and true or false
end

local espFolder = Instance.new("Folder")
espFolder.Name = "JinESP"
attach(espFolder)
local pvis, ovis, selfBB = {}, {}, {}

local function makeBB(part, offsetY, h)
    local bb = Instance.new("BillboardGui")
    bb.Size = UDim2.fromOffset(200, h or 24)
    bb.StudsOffset = Vector3.new(0, offsetY, 0)
    bb.AlwaysOnTop = true
    bb.Adornee = part
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamBold
    lbl.TextStrokeTransparency = 0.4
    lbl.Parent = bb
    bb.Parent = espFolder
    return bb, lbl
end
local function setLabel(bb, lbl, text, color, size)
    lbl.Text, lbl.TextColor3, lbl.TextSize = text, color, size
    bb.Enabled = text ~= ""
end
local function destroyPlayerVis(plr)
    local v = pvis[plr]
    if v then pcall(function() v.hl:Destroy() v.nameBB:Destroy() v.distBB:Destroy() end) pvis[plr] = nil end
end
local function destroyObj(inst)
    local o = ovis[inst]
    if o then
        pcall(function()
            o.box:Destroy()
            if o.nameBB then o.nameBB:Destroy() o.distBB:Destroy() end
        end)
        ovis[inst] = nil
    end
end
local function partOf(inst)
    if inst:IsA("BasePart") then return inst end
    if inst:IsA("Model") and inst.PrimaryPart then return inst.PrimaryPart end
    return inst:FindFirstChildWhichIsA("BasePart", true)
end
local function halfHeight(inst)
    local ok, h = pcall(function()
        if inst:IsA("Model") then return inst:GetExtentsSize().Y end
        return inst.Size.Y
    end)
    return ((ok and h or 4) / 2) + 1.2
end
local function createObj(cat, inst)
    local box = Instance.new("SelectionBox")
    box.LineThickness = 0.04
    box.SurfaceTransparency = 0.85
    box.Adornee = inst
    box.Parent = espFolder
    local part = partOf(inst)
    local o = {cat = cat, box = box}
    if part then
        local hh = halfHeight(inst)
        o.nameBB, o.nameLbl = makeBB(part, hh)
        o.distBB, o.distLbl = makeBB(part, -hh)
    end
    ovis[inst] = o
    return o
end

local function update()
    local lc = lp.Character
    local lhrp = lc and lc:FindFirstChild("HumanoidRootPart")
    local maxD = S.maxDist > 0 and S.maxDist or math.huge
    local ts = S.textSize
    local killers = getKillers()

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= lp then
            local char = plr.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local role = roleOf(plr)
            local alive = hrp and hum and hum.Health > 0
            local key = role
            if alive and role == "survivor" then
                key = survivorState(plr, char, hum, hrp, killers)
                if not S.cat[key].on then key = "survivor" end
            end
            if alive and S.cat[key].on then
                local v = pvis[plr]
                if not v or v.char ~= char or not v.hl.Parent then
                    destroyPlayerVis(plr)
                    local hl = Instance.new("Highlight")
                    hl.Adornee = char
                    hl.FillTransparency = 0.6
                    hl.OutlineTransparency = 0
                    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    hl.Parent = espFolder
                    local nbb, nlbl = makeBB(hrp, 3.4)
                    local dbb, dlbl = makeBB(hrp, -3.8)
                    v = {hl = hl, nameBB = nbb, nameLbl = nlbl, distBB = dbb, distLbl = dlbl, char = char}
                    pvis[plr] = v
                end
                local c = S.cat[key].color
                v.hl.FillColor, v.hl.OutlineColor = c, c
                local dist = lhrp and math.floor((hrp.Position - lhrp.Position).Magnitude)
                local tag = TAG[key]
                local nameTxt = plr.DisplayName .. (tag and (" [" .. tag .. "]") or "")
                setLabel(v.nameBB, v.nameLbl, S.names and nameTxt or "", c, ts)
                setLabel(v.distBB, v.distLbl, (S.dist and dist) and ("%dm"):format(dist) or "", c, ts)
            else
                destroyPlayerVis(plr)
            end
        end
    end
    for plr in pairs(pvis) do if not plr.Parent then destroyPlayerVis(plr) end end

    -- chase marker: ! ijo / !! kuning / !!! merah (makin deket killer makin banyak), di atas karakter KITA sendiri
    local lhum = lc and lc:FindFirstChildOfClass("Humanoid")
    local lvl = 0
    if S.cat.chased.on and lhrp and lhum and lhum.Health > 0 and roleOf(lp) == "survivor" then
        local _, chasedNow = survivorState(lp, lc, lhum, lhrp, killers)
        if chasedNow then
            local base = S.chaseDist > 0 and S.chaseDist or 40
            local dk = math.huge
            for _, k in ipairs(killers) do
                dk = math.min(dk, (lhrp.Position - k.hrp.Position).Magnitude)
            end
            lvl = dk <= base * 0.4 and 3 or (dk <= base * 0.75 and 2 or 1)
        end
    end
    if lvl > 0 then
        if not selfBB.bb or not selfBB.bb.Parent or selfBB.bb.Adornee ~= lhrp then
            if selfBB.bb then pcall(function() selfBB.bb:Destroy() end) end
            selfBB.bb, selfBB.lbl = makeBB(lhrp, 6.6, 44)
        end
        setLabel(selfBB.bb, selfBB.lbl, string.rep("!", lvl), S.chaseCol[lvl], ts + 16)
    elseif selfBB.bb then
        selfBB.bb.Enabled = false
    end

    for cat, set in pairs(found) do
        local enabled = S.cat[cat].on
        for inst in pairs(set) do
            if not inst:IsDescendantOf(workspace) then
                set[inst] = nil
                destroyObj(inst)
            elseif enabled then
                local o = ovis[inst] or createObj(cat, inst)
                local dist = lhrp and (inst:GetPivot().Position - lhrp.Position).Magnitude
                if (not dist) or dist <= maxD then
                    local c = S.cat[cat].color
                    o.box.Adornee = inst
                    o.box.Color3, o.box.SurfaceColor3 = c, c
                    if o.nameBB then
                        setLabel(o.nameBB, o.nameLbl, S.names and CAT[cat].label or "", c, ts)
                        setLabel(o.distBB, o.distLbl, (S.dist and dist) and ("%dm"):format(math.floor(dist)) or "", c, ts)
                    end
                else
                    o.box.Adornee = nil
                    if o.nameBB then o.nameBB.Enabled = false o.distBB.Enabled = false end
                end
            else
                destroyObj(inst)
            end
        end
    end
end

----------------------------------------------------------------------
-- AREA LIAT KILLER: sektor di tanah, arah dari Char.CamLook (kamera POV killer)
-- dibuat dari WedgePart lokal (ga replicate), ga butuh Drawing
----------------------------------------------------------------------
local CONE_N = 12
local coneFolder = Instance.new("Folder")
coneFolder.Name = tostring(math.random(1000000, 9999999))
local coneW = {}
for i = 1, CONE_N * 2 do
    local w = Instance.new("WedgePart")
    w.Anchored, w.CanCollide, w.CanQuery, w.CanTouch, w.CastShadow = true, false, false, false, false
    w.Material = Enum.Material.Neon
    w.Size = Vector3.new(0.05, 1, 1)
    w.Parent = coneFolder
    coneW[i] = w
end
local coneRP = RaycastParams.new()
coneRP.FilterType = Enum.RaycastFilterType.Exclude
coneRP.RespectCanCollide = true   -- abaikan part dekor yang ga collide

local function tri3(a, b, c, w1, w2)
    local ab, ac, bc = b - a, c - a, c - b
    local abd, acd, bcd = ab:Dot(ab), ac:Dot(ac), bc:Dot(bc)
    if abd > acd and abd > bcd then c, a = a, c
    elseif acd > bcd and acd > abd then a, b = b, a end
    ab, ac, bc = b - a, c - a, c - b
    if ac:Cross(ab).Magnitude < 1e-3 then w1.Transparency, w2.Transparency = 1, 1 return end   -- sliver mati, jangan sisain wedge lama
    local right = ac:Cross(ab).Unit
    local up = bc:Cross(right).Unit
    local back = bc.Unit
    local h = math.abs(ab:Dot(up))
    w1.Size = Vector3.new(0.05, h, math.abs(ab:Dot(back)))
    w1.CFrame = CFrame.fromMatrix((a + b) / 2, right, up, back)
    w2.Size = Vector3.new(0.05, h, math.abs(ac:Dot(back)))
    w2.CFrame = CFrame.fromMatrix((a + c) / 2, -right, up, -back)
end
local function groundAt(p, fy)
    -- cuma lantai: mulai deket tinggi tanah killer, normal harus hadap atas (atap / tembok / prop = pake tinggi killer)
    local r = workspace:Raycast(Vector3.new(p.X, fy + 4, p.Z), Vector3.new(0, -14, 0), coneRP)
    if r and r.Normal.Y > 0.6 then return r.Position + Vector3.new(0, 0.12, 0) end
    return Vector3.new(p.X, fy + 0.12, p.Z)
end
local function updateCone()
    if not S.cone.on or roleOf(lp) == "killer" then coneFolder.Parent = nil return end
    local ks = getKillers()
    local k = ks[1]
    if not k then coneFolder.Parent = nil return end
    local ex = {coneFolder}
    for _, p in ipairs(Players:GetPlayers()) do if p.Character then ex[#ex + 1] = p.Character end end
    coneRP.FilterDescendantsInstances = ex

    local cl = k.char:GetAttribute("CamLook")
    local look = (typeof(cl) == "Vector3") and cl or k.hrp.CFrame.LookVector
    look = Vector3.new(look.X, 0, look.Z)
    if look.Magnitude < 0.01 then
        local lv = k.hrp.CFrame.LookVector
        look = Vector3.new(lv.X, 0, lv.Z)
    end
    look = look.Unit
    local prev = S.cone.look      -- haluskan arah (CamLook replicate-nya patah-patah)
    if prev then
        local mix = prev:Lerp(look, 0.4)
        if mix.Magnitude > 0.05 then look = mix.Unit end
    end
    S.cone.look = look

    local o = groundAt(k.hrp.Position, k.hrp.Position.Y - 3)
    local half = math.rad(S.cone.angle / 2)
    local pts = {}
    for i = 0, CONE_N do
        local dir = CFrame.Angles(0, -half + 2 * half * (i / CONE_N), 0):VectorToWorldSpace(look)
        pts[i] = groundAt(o + dir * S.cone.range, o.Y)
    end
    for i = 1, CONE_N do
        local w1, w2 = coneW[i * 2 - 1], coneW[i * 2]
        w1.Color, w2.Color = S.cone.color, S.cone.color
        w1.Transparency, w2.Transparency = S.cone.transp, S.cone.transp
        tri3(o, pts[i - 1], pts[i], w1, w2)
    end
    coneFolder.Parent = workspace
end

----------------------------------------------------------------------
-- SKILL CHECK
-- Line = jarum, Goal = zona. success = Goal+102..116, neutral = Goal+116..159, selain itu fail
----------------------------------------------------------------------
local Check, Line, Goal, action
local scBound, scBusy = {}, false

local function press()
    if getconnections then
        local fired = false
        for _, c in ipairs(getconnections(action.MouseButton1Down)) do
            local f = c.Function
            local ok, sc = pcall(function() return getfenv(f).script end)
            if f and ok and sc and (sc.Name == "Skillcheck_gen" or sc.Name == "Skillcheck_player") then
                pcall(f); fired = true
            end
        end
        if fired then return end
    end
    if firesignal then firesignal(action.MouseButton1Down) end
end
local function pickKind()
    local m = S.sc.mode
    if m ~= "Random" then return m end
    local r = math.random()
    return r < 0.15 and "Instant" or (r < 0.70 and "Perfect" or "Great")
end
local function arm()
    if scBusy or not S.sc.enabled or not Check then return end
    scBusy = true
    local C, L, G = Check, Line, Goal
    task.spawn(function()
        task.wait()
        local handled = G.Rotation
        if C.Visible and S.sc.enabled then
            local kind = pickKind()
            local off = (kind == "Great") and (137 + math.random(-10, 10)) or (109 + math.random(-4, 4))
            local target = handled + off
            if kind ~= "Instant" then
                while running and S.sc.enabled and C.Visible and G.Rotation == handled and L.Rotation < target - 10 do
                    RS.Heartbeat:Wait()
                end
            end
            if C.Visible and S.sc.enabled and G.Rotation == handled then
                L.Rotation = target
                press()
            end
        end
        task.wait(0.12)
        scBusy = false
        if running and S.sc.enabled and C.Visible and G.Rotation ~= handled then arm() end
    end)
end
local function scUnbind()
    for _, c in ipairs(scBound) do pcall(function() c:Disconnect() end) end
    scBound = {}
end
local function scBind()
    local g = pg:FindFirstChild("SkillCheckPromptGui")
    local c = g and g:FindFirstChild("Check")
    local l = c and c:FindFirstChild("Line")
    local gl = c and c:FindFirstChild("Goal")
    local m = pg:FindFirstChild("Survivor-mob")
    local ctl = m and m:FindFirstChild("Controls")
    local a = ctl and ctl:FindFirstChild("action")
    if not (c and l and gl and a) then return end
    if c == Check and a == action then return end
    scUnbind()
    Check, Line, Goal, action = c, l, gl, a
    scBusy = false
    scBound[#scBound + 1] = Check:GetPropertyChangedSignal("Visible"):Connect(function() if Check.Visible then arm() end end)
    scBound[#scBound + 1] = Goal:GetPropertyChangedSignal("Rotation"):Connect(function() if Check.Visible then arm() end end)
end

----------------------------------------------------------------------
-- MISC: FOV, Fullbright, Anti lag
----------------------------------------------------------------------
local fbOrig
local function fbSave()
    if fbOrig then return end
    local atm = Lighting:FindFirstChildOfClass("Atmosphere")
    fbOrig = {
        Brightness = Lighting.Brightness, ClockTime = Lighting.ClockTime, FogEnd = Lighting.FogEnd,
        FogStart = Lighting.FogStart, GlobalShadows = Lighting.GlobalShadows, Ambient = Lighting.Ambient,
        OutdoorAmbient = Lighting.OutdoorAmbient, atm = atm, Density = atm and atm.Density, Haze = atm and atm.Haze,
    }
end
local function fbApply()
    Lighting.Brightness = S.fb.bright
    Lighting.ClockTime = 14
    Lighting.FogStart = 0
    Lighting.FogEnd = 1e6
    Lighting.GlobalShadows = false
    Lighting.Ambient = Color3.fromRGB(190, 190, 190)
    Lighting.OutdoorAmbient = Color3.fromRGB(190, 190, 190)
    local atm = Lighting:FindFirstChildOfClass("Atmosphere")
    if atm then atm.Density = 0 atm.Haze = 0 end
end
local function fbRestore()
    local o = fbOrig
    if not o then return end
    fbOrig = nil
    pcall(function()
        Lighting.Brightness, Lighting.ClockTime = o.Brightness, o.ClockTime
        Lighting.FogEnd, Lighting.FogStart = o.FogEnd, o.FogStart
        Lighting.GlobalShadows = (not S.al.shadows) and o.GlobalShadows
        Lighting.Ambient, Lighting.OutdoorAmbient = o.Ambient, o.OutdoorAmbient
        if o.atm and o.atm.Parent then o.atm.Density, o.atm.Haze = o.Density, o.Haze end
    end)
end
local shadowOrig
local function shadowsSave()
    if shadowOrig ~= nil then return end
    if fbOrig then shadowOrig = fbOrig.GlobalShadows else shadowOrig = Lighting.GlobalShadows end
end
local function shadowsRestore()
    if shadowOrig ~= nil then
        if not S.fb.on then Lighting.GlobalShadows = shadowOrig end
        shadowOrig = nil
    end
end
local FX = {ParticleEmitter = 1, Trail = 1, Beam = 1, Smoke = 1, Fire = 1, Sparkles = 1}
local fxOff = {}
local function fxKill(i)
    if FX[i.ClassName] and i.Enabled then fxOff[i] = true; i.Enabled = false end
end
local function particlesScan()
    task.spawn(function()
        local d = workspace:GetDescendants()
        for idx, i in ipairs(d) do
            if not running or not S.al.particles then return end
            pcall(fxKill, i)
            if idx % 500 == 0 then task.wait() end
        end
    end)
end
local function particlesRestore()
    for i in pairs(fxOff) do if i.Parent then pcall(function() i.Enabled = true end) end end
    fxOff = {}
end
local POST = {BloomEffect = 1, BlurEffect = 1, ColorCorrectionEffect = 1, DepthOfFieldEffect = 1, SunRaysEffect = 1}
local postOff = {}
local function postSweep()
    for _, root in ipairs({Lighting, workspace.CurrentCamera}) do
        if root then
            for _, e in ipairs(root:GetChildren()) do
                if POST[e.ClassName] and e.Enabled then postOff[e] = true; e.Enabled = false end
            end
        end
    end
end
local function postRestore()
    for e in pairs(postOff) do if e.Parent then pcall(function() e.Enabled = true end) end end
    postOff = {}
end
local origQuality
local function setQuality(low)
    pcall(function()
        local r = settings().Rendering
        if low then
            origQuality = origQuality or r.QualityLevel
            r.QualityLevel = Enum.QualityLevel.Level01
        elseif origQuality then
            r.QualityLevel = origQuality
            origQuality = nil
        end
    end)
end

----------------------------------------------------------------------
-- UI: HELPER
----------------------------------------------------------------------
local F_MED, F_BOLD = Enum.Font.GothamMedium, Enum.Font.GothamBold
local T = {
    text = Color3.fromRGB(240, 240, 240), dim = Color3.fromRGB(138, 138, 138),
    stroke = Color3.fromRGB(48, 48, 48), off = Color3.fromRGB(52, 52, 52), btn = Color3.fromRGB(32, 32, 32),
    acc0 = Color3.fromRGB(245, 245, 245), acc1 = Color3.fromRGB(140, 140, 140),
    bg0 = Color3.fromRGB(23, 23, 23), bg1 = Color3.fromRGB(9, 9, 9),
    side0 = Color3.fromRGB(17, 17, 17), side1 = Color3.fromRGB(10, 10, 10),
    card0 = Color3.fromRGB(29, 29, 29), card1 = Color3.fromRGB(19, 19, 19),
    sel = Color3.fromRGB(46, 46, 46),
}
T.card = T.card1
local WHITE, INK = Color3.new(1, 1, 1), Color3.fromRGB(12, 12, 12)
local PALETTE = {
    Color3.fromRGB(255, 255, 255), Color3.fromRGB(0, 255, 120), Color3.fromRGB(255, 50, 50), Color3.fromRGB(0, 170, 255),
    Color3.fromRGB(255, 235, 0), Color3.fromRGB(170, 80, 255), Color3.fromRGB(255, 140, 0), Color3.fromRGB(255, 105, 180),
}
local LEFT, RIGHT, CENTER = Enum.TextXAlignment.Left, Enum.TextXAlignment.Right, Enum.TextXAlignment.Center

local function new(class, props, parent)
    local o = Instance.new(class)
    for k, v in pairs(props) do o[k] = v end
    if parent then o.Parent = parent end
    return o
end
local function round(o, r) return new("UICorner", {CornerRadius = UDim.new(0, r or 8)}, o) end
local function outline(o, c, th) return new("UIStroke", {Color = c or T.stroke, Thickness = th or 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, o) end
local function grad(o, c0, c1, rot) return new("UIGradient", {Color = ColorSequence.new(c0, c1), Rotation = rot or 0}, o) end
local function panel(o) o.BackgroundColor3 = WHITE grad(o, T.card0, T.card1, 90) return o end
local function pad(o, l, t, r, b)
    return new("UIPadding", {PaddingLeft = UDim.new(0, l), PaddingTop = UDim.new(0, t), PaddingRight = UDim.new(0, r), PaddingBottom = UDim.new(0, b)}, o)
end
local function vlist(o, gap, dir)
    return new("UIListLayout", {Padding = UDim.new(0, gap or 6), SortOrder = Enum.SortOrder.LayoutOrder,
        FillDirection = dir or Enum.FillDirection.Vertical}, o)
end
local function mkLabel(parent, txt, size, color, font, align)
    return new("TextLabel", {BackgroundTransparency = 1, Text = txt, TextSize = size or 12, TextColor3 = color or T.text,
        Font = font or F_MED, TextXAlignment = align or LEFT}, parent)
end
local function tw(o, t, p)
    TS:Create(o, TweenInfo.new(t, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), p):Play()
end
local function hover(btn, normal, over)
    track(btn.MouseEnter:Connect(function() tw(btn, 0.12, {BackgroundColor3 = over}) end))
    track(btn.MouseLeave:Connect(function() tw(btn, 0.15, {BackgroundColor3 = normal}) end))
end
local function esc(s) return (tostring(s):gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")) end
local function headshot(uid) return "rbxthumb://type=AvatarHeadShot&id=" .. uid .. "&w=150&h=150" end
-- avatar: coba rbxthumb dulu, lalu diganti hasil GetUserThumbnailAsync (lebih pasti), ada huruf cadangan
local avCache = {}
local function setAvatar(img, uid)
    img.Image = avCache[uid] or headshot(uid)
    if avCache[uid] then return end
    task.spawn(function()
        local ok, url = pcall(function()
            return Players:GetUserThumbnailAsync(uid, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
        end)
        if ok and url then
            avCache[uid] = url
            if img.Parent then img.Image = url end
        end
    end)
end
local function mkAvatar(parent, size, uid, name)
    local f = new("Frame", {Size = UDim2.fromOffset(size, size), BackgroundColor3 = T.btn, BorderSizePixel = 0}, parent)
    round(f, size / 2)
    local ch = mkLabel(f, string.upper(string.sub(name or "?", 1, 1)), math.floor(size * 0.5), T.dim, F_BOLD, CENTER)
    ch.Size = UDim2.new(1, 0, 1, 0)
    local img = new("ImageLabel", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Image = "", ZIndex = 2}, f)
    round(img, size / 2)
    setAvatar(img, uid)
    return f, img
end

local function draggable(handle, target, onTap)
    local dragging, moved, start, startPos = false, false, nil, nil
    track(handle.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging, moved = true, false
            start, startPos = i.Position, target.Position
        end
    end))
    track(UIS.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - start
            if d.Magnitude > 6 then moved = true end
            if moved then
                target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
            end
        end
    end))
    track(UIS.InputEnded:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch) then
            dragging = false
            if not moved and onTap then onTap() end
        end
    end))
end
local function dragBar(hit, scroll, onX)
    local dragging = false
    track(hit.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            scroll.ScrollingEnabled = false
            onX(i.Position.X)
        end
    end))
    track(UIS.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            onX(i.Position.X)
        end
    end))
    track(UIS.InputEnded:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch) then
            dragging = false
            scroll.ScrollingEnabled = true
        end
    end))
end

----------------------------------------------------------------------
-- IKON: spritesheet jin_icons.png (fallback digambar pake Frame kalau file ga ketemu)
----------------------------------------------------------------------
local SHEET = assetOf(SHEET_ID, SHEET_FILE)
local CELL = 64
local SHEET_MAP = {home = {0, 0}, eye = {1, 0}, target = {2, 0}, sliders = {3, 0},
    gear = {0, 1}, xmark = {1, 1}, down = {2, 1}}

local function mkIcon(parent, name, color, px)
    local box = new("Frame", {Size = UDim2.fromOffset(16, 16), AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1}, parent)
    if px and px ~= 16 then new("UIScale", {Scale = px / 16}, box) end

    local cell = SHEET and SHEET_MAP[name]
    if cell then
        local im = new("ImageLabel", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Image = SHEET,
            ImageRectSize = Vector2.new(CELL, CELL), ImageRectOffset = Vector2.new(cell[1] * CELL, cell[2] * CELL),
            ImageColor3 = color, ScaleType = Enum.ScaleType.Stretch}, box)
        local icon = {box = box}
        function icon:Set(c) im.ImageColor3 = c end
        function icon:Tween(c, t) tw(im, t or 0.18, {ImageColor3 = c}) end
        return icon
    end

    local parts = {}
    local function shape(cx, cy, w, h, rot, circle, ring)
        local f = new("Frame", {Size = UDim2.fromOffset(w, h), Position = UDim2.fromOffset(cx, cy),
            AnchorPoint = Vector2.new(0.5, 0.5), Rotation = rot or 0, BackgroundColor3 = color, BorderSizePixel = 0}, box)
        if circle then new("UICorner", {CornerRadius = UDim.new(0.5, 0)}, f) end
        if ring then
            f.BackgroundTransparency = 1
            local s = new("UIStroke", {Color = color, Thickness = ring, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, f)
            parts[#parts + 1] = {s = s}
        else
            parts[#parts + 1] = {f = f}
        end
    end
    if name == "home" then
        shape(8, 6, 9, 9, 45)
        shape(8, 12.5, 10, 7)
    elseif name == "eye" then
        shape(8, 8, 13, 7, 0, true, 1.5)
        shape(8, 8, 4, 4, 0, true)
    elseif name == "target" then
        shape(8, 8, 11, 11, 0, true, 1.5)
        shape(8, 8, 4, 4, 0, true)
    elseif name == "sliders" then
        shape(8, 3.5, 14, 1.6)
        shape(8, 8, 14, 1.6)
        shape(8, 12.5, 14, 1.6)
        shape(10.5, 3.5, 4.5, 4.5, 0, true)
        shape(5, 8, 4.5, 4.5, 0, true)
        shape(11, 12.5, 4.5, 4.5, 0, true)
    elseif name == "gear" then
        for k = 0, 7 do
            local a = math.rad(k * 45)
            shape(8 + math.cos(a) * 6, 8 + math.sin(a) * 6, 3, 3.2, k * 45)
        end
        shape(8, 8, 8, 8, 0, true, 2)
    elseif name == "xmark" then
        shape(8, 8, 14, 2, 45)
        shape(8, 8, 14, 2, -45)
    elseif name == "down" then
        shape(5.2, 7, 7.5, 2, 45)
        shape(10.8, 7, 7.5, 2, -45)
    end
    local icon = {box = box}
    function icon:Set(c)
        for _, p in ipairs(parts) do
            if p.s then p.s.Color = c else p.f.BackgroundColor3 = c end
        end
    end
    function icon:Tween(c, t)
        for _, p in ipairs(parts) do
            if p.s then tw(p.s, t or 0.18, {Color = c}) else tw(p.f, t or 0.18, {BackgroundColor3 = c}) end
        end
    end
    return icon
end

----------------------------------------------------------------------
-- CONFIG (auto-save ke jin_hub/jin_config.json)
----------------------------------------------------------------------
local Reg = {}
local CFG_FILE = "jin_config.json"
local loading, dirty = true, false

local function saveConfig()
    if not writefile then return end
    local data = {}
    for id, r in pairs(Reg) do data[id] = r.get() end
    pcall(function() writefile(BASE .. CFG_FILE, HttpService:JSONEncode(data)) end)
end
local function touch()
    if loading or dirty then return end
    dirty = true
    task.delay(1.5, function()
        dirty = false
        if running then saveConfig() end
    end)
end
local function loadConfig()
    local p = findFile(CFG_FILE)
    if not (p and readfile) then return end
    local ok, data = pcall(function() return HttpService:JSONDecode(readfile(p)) end)
    if ok and type(data) == "table" then
        for id, v in pairs(data) do
            if Reg[id] then pcall(Reg[id].set, v) end
        end
    end
end

----------------------------------------------------------------------
-- UI: WINDOW
----------------------------------------------------------------------
local gui, HEAD, PADL, PADR, curSize, curRatio, isOpen, setOpen, applyLayout, tabHolder, content
do -- scope window (limit 200 local per chunk)
gui = Instance.new("ScreenGui")
gui.Name = "JinScript"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 1000
attach(gui)

local ICON = loadLogo()
local cam = workspace.CurrentCamera
local vp = cam and cam.ViewportSize or Vector2.new(844, 390)
local SB = 46                         -- lebar sidebar (ikon doang)
HEAD = 38                       -- tinggi header
PADL, PADR = 12, 14

-- ukuran + rasio (preset). Angka rasio = ukuran desain sebelum diskala
local SIZES = {Kecil = 0.7, Sedang = 0.85, Besar = 1.0, Jumbo = 1.15}
local RATIOS = {["4:3"] = {500, 375}, ["16:10"] = {560, 350}, ["16:9"] = {600, 338}, ["21:9"] = {680, 291}}
curSize, curRatio = "Sedang", "16:9"
local function layoutScale()
    local r = RATIOS[curRatio]
    local c = workspace.CurrentCamera
    local v = c and c.ViewportSize or Vector2.new(844, 390)
    return math.min(SIZES[curSize], (v.X * 0.96) / r[1], (v.Y * 0.94) / r[2])
end

local main = new("Frame", {
    Size = UDim2.fromOffset(RATIOS[curRatio][1], RATIOS[curRatio][2]), AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new(0.5, 0, 0.5, 0),
    BackgroundColor3 = WHITE, BorderSizePixel = 0, Visible = false, ClipsDescendants = true, Active = true}, gui)
round(main, 10)
grad(main, T.bg0, T.bg1, 35)
grad(outline(main, WHITE, 1), T.acc0, T.stroke, 45)
local uiScale = new("UIScale", {Scale = layoutScale()}, main)

isOpen = false
function setOpen(v)
    isOpen = v
    if v then
        main.Visible = true
        uiScale.Scale = layoutScale() * 0.94
        tw(uiScale, 0.18, {Scale = layoutScale()})
    else
        tw(uiScale, 0.12, {Scale = layoutScale() * 0.94})
        task.delay(0.12, function() if not isOpen and main then main.Visible = false end end)
    end
end
-- ganti ukuran / rasio dengan transisi halus
function applyLayout()
    local r = RATIOS[curRatio]
    local info = TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    TS:Create(main, info, {Size = UDim2.fromOffset(r[1], r[2])}):Play()
    TS:Create(uiScale, info, {Scale = isOpen and layoutScale() or layoutScale() * 0.94}):Play()
end
pcall(function()
    track(workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(applyLayout))
end)

-- sidebar
local side = new("Frame", {Size = UDim2.new(0, SB, 1, 0), BackgroundColor3 = WHITE, BorderSizePixel = 0}, main)
round(side, 10)
grad(side, T.side0, T.side1, 90)
local sideCover = new("Frame", {Size = UDim2.new(0, 10, 1, 0), Position = UDim2.new(1, -10, 0, 0), BackgroundColor3 = WHITE, BorderSizePixel = 0}, side)
grad(sideCover, T.side0, T.side1, 90)
new("Frame", {Size = UDim2.new(0, 1, 1, 0), Position = UDim2.new(0, SB, 0, 0), BackgroundColor3 = T.stroke, BorderSizePixel = 0}, main)

-- logo kamu: tanpa background, tanpa lingkaran
if ICON then
    new("ImageLabel", {Size = UDim2.fromOffset(26, 26), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0, HEAD / 2),
        BackgroundTransparency = 1, Image = ICON, ScaleType = Enum.ScaleType.Fit}, side)
else
    local j = mkLabel(side, "J", 18, T.text, F_BOLD, CENTER)
    j.Size = UDim2.new(1, 0, 0, HEAD)
end

tabHolder = new("Frame", {Size = UDim2.new(1, 0, 1, -(HEAD + 8)), Position = UDim2.fromOffset(0, HEAD + 6), BackgroundTransparency = 1}, side)
new("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder,
    HorizontalAlignment = Enum.HorizontalAlignment.Center}, tabHolder)

-- area isi
content = new("Frame", {Size = UDim2.new(1, -SB - 1, 1, 0), Position = UDim2.new(0, SB + 1, 0, 0), BackgroundTransparency = 1}, main)
local header = new("Frame", {Size = UDim2.new(1, 0, 0, HEAD), BackgroundTransparency = 1, Active = true}, content)
new("Frame", {Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, -1), BackgroundColor3 = T.stroke, BorderSizePixel = 0}, header)
local ttl = mkLabel(header, "JÌN SCRIPT", 12, T.text, F_BOLD)
ttl.Position = UDim2.fromOffset(14, 0); ttl.Size = UDim2.fromOffset(78, HEAD - 1)
local ver = mkLabel(header, "v3.2", 10, T.dim)
ver.Position = UDim2.fromOffset(92, 1); ver.Size = UDim2.fromOffset(30, HEAD - 1)

local closeBtn = new("TextButton", {Size = UDim2.fromOffset(24, 24), AnchorPoint = Vector2.new(1, 0.5),
    Position = UDim2.new(1, -8, 0.5, -1), BackgroundTransparency = 1, Text = "", AutoButtonColor = false}, header)
local closeIc = mkIcon(closeBtn, "xmark", T.dim, 12)
closeIc.box.Position = UDim2.new(0.5, 0, 0.5, 0)
track(closeBtn.MouseEnter:Connect(function() closeIc:Tween(T.text, 0.12) end))
track(closeBtn.MouseLeave:Connect(function() closeIc:Tween(T.dim, 0.15) end))
track(closeBtn.MouseButton1Click:Connect(function() setOpen(false) end))
draggable(header, main)

-- logo sosmed di header (tap = copy link)
local SOCIAL = assetOf(SOCIAL_ID, SOCIAL_FILE)
local SOC_ORDER = {"YouTube", "TikTok", "WhatsApp", "Discord"}
local SOC_RECT = {                      -- x, y, w, h di jin_social.png
    YouTube = {6, 0, 138, 108}, TikTok = {160, 0, 102, 108},
    WhatsApp = {272, 0, 102, 108}, Discord = {374, 0, 138, 108},
}
local SOC_TXT = {YouTube = "YT", TikTok = "TT", WhatsApp = "WA", Discord = "DC"}
local SOC_W, SOC_H, SOC_STEP = 26, 20, 31   -- ukuran tiap logo + jarak antar logo
local socRow = new("Frame", {Size = UDim2.fromOffset(#SOC_ORDER * SOC_STEP, 26), AnchorPoint = Vector2.new(1, 0.5),
    Position = UDim2.new(1, -38, 0.5, -1), BackgroundTransparency = 1}, header)
for idx, nameKey in ipairs(SOC_ORDER) do
    local hasLink = LINKS[nameKey] ~= nil and LINKS[nameKey] ~= ""
    local b
    if SOCIAL then
        local r = SOC_RECT[nameKey]
        b = new("ImageButton", {Size = UDim2.fromOffset(SOC_W, SOC_H), Position = UDim2.fromOffset((idx - 1) * SOC_STEP, 3),
            BackgroundTransparency = 1, Image = SOCIAL, ImageRectOffset = Vector2.new(r[1], r[2]),
            ImageRectSize = Vector2.new(r[3], r[4]), ScaleType = Enum.ScaleType.Fit,
            ImageTransparency = hasLink and 0.15 or 0.6, AutoButtonColor = false}, socRow)
        if hasLink then
            track(b.MouseEnter:Connect(function() tw(b, 0.1, {ImageTransparency = 0}) end))
            track(b.MouseLeave:Connect(function() tw(b, 0.12, {ImageTransparency = 0.15}) end))
        end
    else
        b = new("TextButton", {Size = UDim2.fromOffset(SOC_W, SOC_H), Position = UDim2.fromOffset((idx - 1) * SOC_STEP, 3),
            BackgroundTransparency = 1, Text = SOC_TXT[nameKey], TextSize = 13, Font = F_BOLD,
            TextColor3 = hasLink and T.text or T.dim, AutoButtonColor = false}, socRow)
    end
    track(b.MouseButton1Click:Connect(function()
        if not hasLink then notify(nameKey, "Link belum diisi di LINKS (atas script)") return end
        local fn = setclipboard or toclipboard
        if fn then pcall(fn, LINKS[nameKey]) notify(nameKey, "Link disalin ke clipboard")
        else notify(nameKey, LINKS[nameKey]) end
    end))
end

-- tombol buka/tutup: logo doang, tanpa lingkaran/background
local fab
if ICON then
    fab = new("ImageButton", {Size = UDim2.fromOffset(46, 46), Position = UDim2.new(0, 10, 0.5, -23),
        BackgroundTransparency = 1, Image = ICON, ScaleType = Enum.ScaleType.Fit, AutoButtonColor = false}, gui)
else
    fab = new("TextButton", {Size = UDim2.fromOffset(46, 46), Position = UDim2.new(0, 10, 0.5, -23),
        BackgroundTransparency = 1, Text = "J", TextSize = 28, Font = F_BOLD, TextColor3 = WHITE,
        TextStrokeTransparency = 0.4, AutoButtonColor = false}, gui)
end
draggable(fab, fab, function() setOpen(not isOpen) end)
end -- /scope window

notify = function(t, c)
    local f = new("Frame", {Size = UDim2.fromOffset(240, 42), AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, -56), BackgroundColor3 = T.card, BorderSizePixel = 0}, gui)
    round(f, 9)
    panel(f)
    outline(f, T.stroke, 1)
    local a = mkLabel(f, t, 12, T.text, F_BOLD)
    a.Position = UDim2.fromOffset(14, 5); a.Size = UDim2.new(1, -28, 0, 16)
    local b = mkLabel(f, c or "", 11, T.dim)
    b.Position = UDim2.fromOffset(14, 22); b.Size = UDim2.new(1, -28, 0, 14)
    b.TextTruncate = Enum.TextTruncate.AtEnd
    tw(f, 0.3, {Position = UDim2.new(0.5, 0, 0, 16)})
    task.delay(2.3, function()
        if f.Parent then tw(f, 0.25, {Position = UDim2.new(0.5, 0, 0, -56)}) end
        task.wait(0.3)
        pcall(function() f:Destroy() end)
    end)
end

----------------------------------------------------------------------
-- UI: TAB + CARD
----------------------------------------------------------------------
local Tab, Card = {}, {}
Tab.__index = Tab
Card.__index = Card
local tabList = {}

local function selectTab(t)
    for _, o in ipairs(tabList) do
        local sel = (o == t)
        o.page.Visible = sel
        tw(o.btn, 0.15, {BackgroundTransparency = sel and 0 or 1})
        o.ic:Tween(sel and T.text or T.dim, 0.15)
        tw(o.bar, 0.15, {BackgroundTransparency = sel and 0 or 1})
    end
end

local function addTab(name, iconKey, single)
    local btn = new("TextButton", {Size = UDim2.fromOffset(36, 34), BackgroundColor3 = T.sel, BackgroundTransparency = 1,
        Text = "", AutoButtonColor = false, LayoutOrder = #tabList + 1}, tabHolder)
    round(btn, 8)
    local ic = mkIcon(btn, iconKey, T.dim, 16)
    ic.box.Position = UDim2.new(0.5, 0, 0.5, 0)
    local bar = new("Frame", {Size = UDim2.fromOffset(2, 16), Position = UDim2.new(0, -5, 0.5, -8),
        BackgroundColor3 = WHITE, BackgroundTransparency = 1, BorderSizePixel = 0}, btn)
    round(bar, 1)

    local page = new("Frame", {Size = UDim2.new(1, 0, 1, -HEAD), Position = UDim2.fromOffset(0, HEAD),
        BackgroundTransparency = 1, Visible = false}, content)
    local pIc = mkIcon(page, iconKey, T.text, 16)
    pIc.box.Position = UDim2.fromOffset(PADL + 8, 17)
    local pLb = mkLabel(page, name, 14, T.text, F_BOLD)
    pLb.Position = UDim2.fromOffset(PADL + 24, 2); pLb.Size = UDim2.new(1, -PADL - 24, 0, 30)

    local scroll = new("ScrollingFrame", {Size = UDim2.new(1, 0, 1, -34), Position = UDim2.fromOffset(0, 34),
        BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = T.stroke,
        AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new()}, page)
    pad(scroll, PADL, 2, 0, 14)
    local cols = new("Frame", {Size = UDim2.new(1, -PADR, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1}, scroll)
    local colList = {}
    if single then
        vlist(cols, 0)
        local c1 = new("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1}, cols)
        vlist(c1, 8)
        colList = {c1}
    else
        vlist(cols, 8, Enum.FillDirection.Horizontal)
        local c1 = new("Frame", {Size = UDim2.new(0.5, -4, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = 1}, cols)
        vlist(c1, 10)
        local c2 = new("Frame", {Size = UDim2.new(0.5, -4, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = 2}, cols)
        vlist(c2, 10)
        colList = {c1, c2}
    end
    local t = setmetatable({name = name, btn = btn, ic = ic, bar = bar, page = page, scroll = scroll,
        cols = colList, nextCol = 1}, Tab)
    tabList[#tabList + 1] = t
    track(btn.MouseButton1Click:Connect(function() selectTab(t) end))
    return t
end

local function sectionLabel(parent, text, order)
    local l = mkLabel(parent, string.upper(text), 10, T.dim, F_BOLD)
    l.Size = UDim2.new(1, 0, 0, 14)
    l.LayoutOrder = order or 1
    return l
end

-- label kecil di atas + card
function Tab:Group(titleText, col)
    col = col or self.nextCol
    if #self.cols == 1 then col = 1 end
    self.nextCol = (col == 1) and 2 or 1
    local holder = new("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1}, self.cols[col])
    vlist(holder, 6)
    sectionLabel(holder, titleText, 1)
    local card = new("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = T.card, BorderSizePixel = 0, LayoutOrder = 2}, holder)
    round(card, 8)
    panel(card)
    outline(card)
    pad(card, 10, 10, 10, 10)
    vlist(card, 8)
    return setmetatable({body = card, tab = self, order = 0}, Card)
end

function Card:nextOrder()
    self.order = self.order + 2
    return self.order
end

function Card:Toggle(id, txt, default, cb, color)
    local o = self:nextOrder()
    local row = new("Frame", {Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1, LayoutOrder = o}, self.body)
    local lb = mkLabel(row, txt, 12, T.text)
    lb.Size = UDim2.new(1, color and -76 or -46, 1, 0)
    lb.TextTruncate = Enum.TextTruncate.AtEnd
    local state = default
    local KNOB_ON, KNOB_OFF = INK, Color3.fromRGB(170, 170, 170)
    local sw = new("Frame", {Size = UDim2.fromOffset(34, 18), Position = UDim2.new(1, -34, 0.5, -9),
        BackgroundColor3 = state and WHITE or T.off, BorderSizePixel = 0}, row)
    round(sw, 9)
    grad(sw, T.acc0, T.acc1, 0)
    local knob = new("Frame", {Size = UDim2.fromOffset(14, 14),
        Position = state and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7),
        BackgroundColor3 = state and KNOB_ON or KNOB_OFF, BorderSizePixel = 0}, sw)
    round(knob, 7)
    local hit = new("TextButton", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "", ZIndex = 2}, row)

    local function set(v, silent)
        state = v and true or false
        tw(sw, 0.16, {BackgroundColor3 = state and WHITE or T.off})
        tw(knob, 0.16, {
            Position = state and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7),
            BackgroundColor3 = state and KNOB_ON or KNOB_OFF,
        })
        if not silent then cb(state) touch() end
    end
    track(hit.MouseButton1Click:Connect(function() set(not state) end))
    Reg[id] = {get = function() return state end, set = function(v) set(v) end}

    if color then
        local col = color.default
        local dot = new("TextButton", {Size = UDim2.fromOffset(16, 16), Position = UDim2.new(1, -60, 0.5, -8),
            BackgroundColor3 = col, Text = "", ZIndex = 3, AutoButtonColor = false}, row)
        round(dot, 8)
        outline(dot, Color3.fromRGB(110, 110, 120))
        local pop = new("Frame", {Size = UDim2.new(1, 0, 0, 54), BackgroundColor3 = T.btn, Visible = false,
            BorderSizePixel = 0, LayoutOrder = o + 1}, self.body)
        round(pop, 8)
        local function setColor(c, silent)
            col = c
            dot.BackgroundColor3 = c
            if not silent then color.cb(c) touch() end
        end
        for i, pc in ipairs(PALETTE) do
            local s = new("TextButton", {Size = UDim2.fromOffset(18, 18), Position = UDim2.fromOffset(6 + (i - 1) * 22, 6),
                BackgroundColor3 = pc, Text = "", AutoButtonColor = false}, pop)
            round(s, 9)
            track(s.MouseButton1Click:Connect(function() setColor(pc) end))
        end
        local hue = new("Frame", {Size = UDim2.new(1, -12, 0, 14), Position = UDim2.fromOffset(6, 32),
            BackgroundColor3 = WHITE, BorderSizePixel = 0}, pop)
        round(hue, 7)
        new("UIGradient", {Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 1, 1)), ColorSequenceKeypoint.new(0.17, Color3.fromHSV(0.17, 1, 1)),
            ColorSequenceKeypoint.new(0.33, Color3.fromHSV(0.33, 1, 1)), ColorSequenceKeypoint.new(0.5, Color3.fromHSV(0.5, 1, 1)),
            ColorSequenceKeypoint.new(0.67, Color3.fromHSV(0.67, 1, 1)), ColorSequenceKeypoint.new(0.83, Color3.fromHSV(0.83, 1, 1)),
            ColorSequenceKeypoint.new(1, Color3.fromHSV(1, 1, 1))})}, hue)
        local hueHit = new("TextButton", {Size = UDim2.new(1, 0, 0, 26), Position = UDim2.new(0, 0, 0.5, -13),
            BackgroundTransparency = 1, Text = "", ZIndex = 2}, hue)
        dragBar(hueHit, self.tab.scroll, function(x)
            local p = math.clamp((x - hue.AbsolutePosition.X) / hue.AbsoluteSize.X, 0, 1)
            setColor(Color3.fromHSV(p, 1, 1))
        end)
        track(dot.MouseButton1Click:Connect(function() pop.Visible = not pop.Visible end))
        Reg[color.id] = {
            get = function() return {math.floor(col.R * 255 + 0.5), math.floor(col.G * 255 + 0.5), math.floor(col.B * 255 + 0.5)} end,
            set = function(v) if type(v) == "table" and #v == 3 then setColor(Color3.fromRGB(v[1], v[2], v[3])) end end,
        }
    end
end

function Card:Slider(id, txt, min, max, default, step, cb, suffix)
    local row = new("Frame", {Size = UDim2.new(1, 0, 0, 38), BackgroundTransparency = 1, LayoutOrder = self:nextOrder()}, self.body)
    local lb = mkLabel(row, txt, 12, T.text)
    lb.Size = UDim2.new(1, -64, 0, 16)
    lb.TextTruncate = Enum.TextTruncate.AtEnd
    local val = mkLabel(row, "", 12, T.dim, F_MED, RIGHT)
    val.Size = UDim2.fromOffset(60, 16); val.Position = UDim2.new(1, -60, 0, 0)
    local bar = new("Frame", {Size = UDim2.new(1, 0, 0, 6), Position = UDim2.fromOffset(0, 26), BackgroundColor3 = T.off, BorderSizePixel = 0}, row)
    round(bar, 3)
    local fill = new("Frame", {Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = WHITE, BorderSizePixel = 0}, bar)
    round(fill, 3)
    grad(fill, T.acc0, T.acc1, 0)
    local knob = new("Frame", {Size = UDim2.fromOffset(12, 12), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 0, 0.5, 0),
        BackgroundColor3 = WHITE, BorderSizePixel = 0}, bar)
    round(knob, 6)
    local hit = new("TextButton", {Size = UDim2.new(1, 0, 0, 26), Position = UDim2.fromOffset(0, 16), BackgroundTransparency = 1, Text = "", ZIndex = 2}, row)
    local value = default
    local function render()
        local p = (value - min) / (max - min)
        fill.Size = UDim2.new(p, 0, 1, 0)
        knob.Position = UDim2.new(p, 0, 0.5, 0)
        val.Text = tostring(value) .. (suffix or "")
    end
    local function set(v, silent)
        v = math.clamp(min + math.floor((v - min) / step + 0.5) * step, min, max)
        if v == value and not silent then return end
        value = v
        render()
        if not silent then cb(v) touch() end
    end
    render()
    dragBar(hit, self.tab.scroll, function(x)
        local p = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        set(min + p * (max - min))
    end)
    Reg[id] = {get = function() return value end, set = function(v) if type(v) == "number" then set(v) end end}
end

function Card:Dropdown(id, txt, values, default, cb)
    local o = self:nextOrder()
    local row = new("TextButton", {Size = UDim2.new(1, 0, 0, 28), BackgroundColor3 = T.btn, Text = "",
        AutoButtonColor = false, LayoutOrder = o}, self.body)
    round(row, 7)
    hover(row, T.btn, T.off)
    local lb = mkLabel(row, txt, 12, T.dim)
    lb.Position = UDim2.fromOffset(10, 0); lb.Size = UDim2.new(0.4, -10, 1, 0)
    local cur = mkLabel(row, default, 12, T.text, F_BOLD, RIGHT)
    cur.Size = UDim2.new(0.6, -28, 1, 0); cur.Position = UDim2.new(0.4, 0, 0, 0)
    local arrow = mkIcon(row, "down", T.dim, 9)
    arrow.box.Position = UDim2.new(1, -14, 0.5, 0)
    local lst = new("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = T.btn,
        Visible = false, BorderSizePixel = 0, LayoutOrder = o + 1}, self.body)
    round(lst, 7)
    pad(lst, 4, 4, 4, 4)
    vlist(lst, 2)
    local value = default
    local function set(v, silent)
        value = v
        cur.Text = v
        lst.Visible = false
        tw(arrow.box, 0.15, {Rotation = 0})
        if not silent then cb(v) touch() end
    end
    for _, v in ipairs(values) do
        local b = new("TextButton", {Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1, Text = v, TextColor3 = T.text,
            Font = F_MED, TextSize = 12, AutoButtonColor = false}, lst)
        round(b, 6)
        track(b.MouseEnter:Connect(function() tw(b, 0.1, {BackgroundTransparency = 0.88, BackgroundColor3 = WHITE}) end))
        track(b.MouseLeave:Connect(function() tw(b, 0.12, {BackgroundTransparency = 1}) end))
        track(b.MouseButton1Click:Connect(function() set(v) end))
    end
    track(row.MouseButton1Click:Connect(function()
        lst.Visible = not lst.Visible
        tw(arrow.box, 0.15, {Rotation = lst.Visible and 180 or 0})
    end))
    Reg[id] = {get = function() return value end, set = function(v) if table.find(values, v) then set(v) end end}
end

function Card:Button(txt, cb)
    local b = new("TextButton", {Size = UDim2.new(1, 0, 0, 28), BackgroundColor3 = T.btn, Text = txt, TextColor3 = T.text,
        Font = F_MED, TextSize = 12, AutoButtonColor = false, LayoutOrder = self:nextOrder()}, self.body)
    round(b, 7)
    hover(b, T.btn, Color3.fromRGB(46, 46, 52))
    track(b.MouseButton1Down:Connect(function() tw(b, 0.08, {BackgroundColor3 = T.off}) end))
    track(b.MouseButton1Click:Connect(function() cb() end))
end

function Card:Label(txt)
    local l = mkLabel(self.body, txt, 11, T.dim)
    l.Size = UDim2.new(1, 0, 0, 0)
    l.AutomaticSize = Enum.AutomaticSize.Y
    l.TextWrapped = true
    l.TextYAlignment = Enum.TextYAlignment.Top
    l.LayoutOrder = self:nextOrder()
    return l
end

----------------------------------------------------------------------
-- HALAMAN: DASHBOARD
----------------------------------------------------------------------
local tHome = addTab("Dashboard", "home", true)
local tESP = addTab("ESP", "eye")
local tSC = addTab("Skill Check", "target")
local tMisc = addTab("Misc", "sliders")
local tSet = addTab("Settings", "gear")

local curFps, refreshDash
do -- scope dashboard (limit 200 local per chunk)
local homeCol = tHome.cols[1]
local selectedUid = lp.UserId
curFps = 0
local chipSig = ""
local avatarTag = {}

-- welcome
local wel = new("Frame", {Size = UDim2.new(1, 0, 0, 64), BackgroundColor3 = T.card, BorderSizePixel = 0, LayoutOrder = 1}, homeCol)
round(wel, 8)
panel(wel)
outline(wel)
local wTitle = mkLabel(wel, ("Welcome back, %s!"):format(lp.DisplayName), 14, T.text, F_BOLD)
wTitle.Position = UDim2.fromOffset(12, 12); wTitle.Size = UDim2.new(1, -78, 0, 18)
wTitle.TextTruncate = Enum.TextTruncate.AtEnd
local wSub = mkLabel(wel, "", 11, T.dim)
wSub.Position = UDim2.fromOffset(12, 34); wSub.Size = UDim2.new(1, -78, 0, 16)
wSub.TextTruncate = Enum.TextTruncate.AtEnd
local ring = new("Frame", {Size = UDim2.fromOffset(44, 44), AnchorPoint = Vector2.new(1, 0.5),
    Position = UDim2.new(1, -12, 0.5, 0), BackgroundTransparency = 1}, wel)
round(ring, 22)
outline(ring, T.text, 1.5)
local wAvF = mkAvatar(ring, 36, lp.UserId, lp.DisplayName)
wAvF.Position = UDim2.fromOffset(4, 4)

-- player chips
sectionLabel(homeCol, "Player statistics", 2)
local chipScroll = new("ScrollingFrame", {Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, BorderSizePixel = 0,
    ScrollBarThickness = 0, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.X,
    ScrollingDirection = Enum.ScrollingDirection.X, LayoutOrder = 3}, homeCol)
vlist(chipScroll, 6, Enum.FillDirection.Horizontal)

-- detail player
local det = new("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = T.card,
    BorderSizePixel = 0, LayoutOrder = 4}, homeCol)
round(det, 8)
panel(det)
outline(det)
pad(det, 12, 10, 12, 12)
vlist(det, 8)
local dh = new("Frame", {Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1, LayoutOrder = 1}, det)
local dAvF, dAva = mkAvatar(dh, 22, lp.UserId, lp.DisplayName)
dAvF.Position = UDim2.fromOffset(0, 1)
local dName = mkLabel(dh, "", 12, T.text, F_BOLD)
dName.Position = UDim2.fromOffset(30, 0); dName.Size = UDim2.new(1, -30, 1, 0)
dName.TextTruncate = Enum.TextTruncate.AtEnd
new("Frame", {Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = T.stroke, BorderSizePixel = 0, LayoutOrder = 2}, det)

-- grid 2 kolom berisi baris "Label: nilai"
local function statGrid(parent, order, rows)
    local g = new("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
        LayoutOrder = order}, parent)
    new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder}, g)
    local out = {}
    for ci = 1, 2 do
        local c = new("Frame", {Size = UDim2.new(0.5, -4, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1, LayoutOrder = ci}, g)
        vlist(c, 5)
        out[ci] = {}
        for r = 1, rows do
            local l = new("TextLabel", {Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1, Text = "", TextSize = 12,
                Font = F_MED, TextColor3 = T.text, TextXAlignment = LEFT, RichText = true, LayoutOrder = r}, c)
            l.TextTruncate = Enum.TextTruncate.AtEnd
            out[ci][r] = l
        end
    end
    return out
end
local function setStat(l, name, value, color)
    l.Text = ('<font color="#808088">%s:</font> <font color="#%s"><b>%s</b></font>'):format(
        esc(name), (color or T.text):ToHex(), esc(value))
end
local dGrid = statGrid(det, 3, 6)

-- stat tambahan dari game: leaderstats, attribute, dan Value di dalam Player
local STAT_ORDER = {"Level", "EXP", "Screws", "Gears", "KillerChance", "Ornaments", "PassExp", "PassClaimed"}
local function fmt(v)
    if type(v) ~= "number" then return tostring(v) end
    local s = tostring(math.floor(v)):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
    return s
end
local function collectStats(plr)
    local list, seen = {}, {}
    local function add(n, v)
        if #list >= 6 or seen[n] then return end
        seen[n] = true
        list[#list + 1] = {n, fmt(v)}
    end
    for _, k in ipairs(STAT_ORDER) do
        local v = plr:GetAttribute(k)
        if v ~= nil then add(k, v) end
    end
    local ls = plr:FindFirstChild("leaderstats")
    if ls then
        for _, v in ipairs(ls:GetChildren()) do
            if v:IsA("ValueBase") then add(v.Name, v.Value) end
        end
    end
    return list
end

-- info round
sectionLabel(homeCol, "Round info", 5)
local rc = new("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = T.card,
    BorderSizePixel = 0, LayoutOrder = 6}, homeCol)
round(rc, 8)
panel(rc)
outline(rc)
pad(rc, 12, 10, 12, 10)
local rGrid = statGrid(rc, 1, 3)

local function cnt(k) local n = 0 for _ in pairs(found[k]) do n = n + 1 end return n end

local function rebuildChips(list)
    for _, c in ipairs(chipScroll:GetChildren()) do
        if c:IsA("GuiButton") then c:Destroy() end
    end
    for i, plr in ipairs(list) do
        local b = new("TextButton", {Size = UDim2.fromOffset(0, 28), AutomaticSize = Enum.AutomaticSize.X,
            BackgroundColor3 = T.sel, BackgroundTransparency = (plr.UserId == selectedUid) and 0 or 1,
            Text = "", AutoButtonColor = false, LayoutOrder = i}, chipScroll)
        round(b, 14)
        pad(b, 5, 0, 10, 0)
        new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6),
            VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder}, b)
        local av = mkAvatar(b, 20, plr.UserId, plr.DisplayName)
        av.LayoutOrder = 1
        local nl = new("TextLabel", {Size = UDim2.fromOffset(0, 28), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1,
            Text = plr.DisplayName, TextSize = 11, Font = F_MED, TextColor3 = T.text, LayoutOrder = 2}, b)
        track(b.MouseButton1Click:Connect(function()
            selectedUid = plr.UserId
            chipSig = ""
            pcall(function() getgenv().JinHub.Refresh() end)
        end))
    end
end

function refreshDash()
    local players = Players:GetPlayers()
    table.sort(players, function(a, b)
        if a == b then return false end
        if a == lp then return true end
        if b == lp then return false end
        return a.Name:lower() < b.Name:lower()
    end)
    local ping = 0
    pcall(function() ping = math.floor(lp:GetNetworkPing() * 1000 + 0.5) end)
    wSub.Text = ("Executor: %s | Players: %d | FPS: %d | Ping: %dms"):format(EXEC, #players, curFps, ping)

    local ids = {}
    for _, p in ipairs(players) do ids[#ids + 1] = p.UserId end
    local sig = table.concat(ids, ",") .. "|" .. selectedUid
    if sig ~= chipSig then
        chipSig = sig
        rebuildChips(players)
    end

    local plr = Players:GetPlayerByUserId(selectedUid)
    if not plr then selectedUid = lp.UserId; plr = lp end
    if avatarTag.uid ~= plr.UserId then
        avatarTag.uid = plr.UserId
        setAvatar(dAva, plr.UserId)
        local ch = dAvF:FindFirstChildOfClass("TextLabel")
        if ch then ch.Text = string.upper(string.sub(plr.DisplayName, 1, 1)) end
    end
    dName.Text = ("%s (@%s)"):format(plr.DisplayName, plr.Name)

    local char = plr.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local lhrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    local role = roleOf(plr)
    local sKey = role
    if role == "survivor" and hum and hrp and hum.Health > 0 then
        sKey = survivorState(plr, char, hum, hrp, getKillers())
    end
    local lines = {
        {"Role", CAT[role].label, S.cat[role].color},
        {"Status", CAT[sKey].label, S.cat[sKey].color},
        {"Health", hum and ("%d/%d"):format(math.floor(hum.Health), math.floor(hum.MaxHealth)) or "-"},
        {"Distance", (plr ~= lp and hrp and lhrp) and ("%dm"):format(math.floor((hrp.Position - lhrp.Position).Magnitude)) or "-"},
        {"Team", plr.Team and plr.Team.Name or "-"},
        {"Account age", ("%d days"):format(plr.AccountAge)},
    }
    for _, e in ipairs(collectStats(plr)) do lines[#lines + 1] = e end
    for i = 1, 12 do
        local l = dGrid[(i % 2 == 1) and 1 or 2][math.floor((i + 1) / 2)]
        local e = lines[i]
        if e then
            setStat(l, e[1], e[2], e[3])
            l.Visible = true
        else
            l.Text = ""
            l.Visible = false
        end
    end

    local surv, killer = 0, "-"
    for _, p in ipairs(players) do
        if roleOf(p) == "killer" then killer = p.DisplayName else surv = surv + 1 end
    end
    setStat(rGrid[1][1], "Survivors", tostring(surv))
    setStat(rGrid[1][2], "Generators", tostring(cnt("generator")))
    setStat(rGrid[1][3], "Pallets", tostring(cnt("pallet")))
    setStat(rGrid[2][1], "Killer", killer)
    setStat(rGrid[2][2], "Hooks", tostring(cnt("hook")))
    setStat(rGrid[2][3], "Windows", tostring(cnt("window")))
end
end -- /scope dashboard

----------------------------------------------------------------------
-- HALAMAN: ESP / SKILL CHECK / MISC / SETTINGS
----------------------------------------------------------------------
local cPlayers = tESP:Group("Players", 1)
local cObj = tESP:Group("Objek", 1)
for _, c in ipairs(CATS) do
    local key = c.key
    local target = c.player and cPlayers or cObj
    target:Toggle("T_" .. key, c.label, c.on,
        function(v) S.cat[key].on = v end,
        {id = "C_" .. key, default = S.cat[key].color, cb = function(col) S.cat[key].color = col end})
end
local cDisp = tESP:Group("Tampilan", 2)
cDisp:Toggle("ESP_Names", "Nama (di atas)", true, function(v) S.names = v end)
cDisp:Toggle("ESP_Dist", "Jarak (di bawah)", true, function(v) S.dist = v end)
cDisp:Slider("ESP_TextSize", "Ukuran teks", 10, 24, 13, 1, function(v) S.textSize = v end)
cDisp:Slider("ESP_MaxDist", "Jarak max objek (0 = bebas)", 0, 3000, 600, 50, function(v) S.maxDist = v end, "m")
cDisp:Toggle("Cone_On", "Area liat killer (tanah)", true, function(v) S.cone.on = v end)
cDisp:Slider("Cone_Angle", "Sudut area killer", 40, 180, 100, 5, function(v) S.cone.angle = v end)
cDisp:Slider("Cone_Range", "Jarak area killer", 20, 150, 70, 5, function(v) S.cone.range = v end, "m")
cDisp:Slider("ESP_ChaseDist", "Jarak deteksi chase (0 = off)", 0, 120, 40, 5, function(v) S.chaseDist = v end, "m")

local cSC = tSC:Group("Auto skill check", 1)
cSC:Toggle("SC_Enabled", "Enabled (F6)", true, function(v) S.sc.enabled = v end)
cSC:Dropdown("SC_Mode", "Mode", {"Instant", "Perfect", "Great", "Random"}, "Perfect", function(v) S.sc.mode = v end)

local cView = tMisc:Group("View", 1)
cView:Toggle("FOV_On", "Custom FOV", false, function(v)
    S.fov.on = v
    if not v then pcall(function() workspace.CurrentCamera.FieldOfView = 70 end) end
end)
cView:Slider("FOV_Val", "FOV", 30, 120, 70, 1, function(v) S.fov.val = v end)
local cLight = tMisc:Group("Fullbright", 1)
cLight:Toggle("FB_On", "Fullbright", false, function(v) S.fb.on = v if v then fbSave() else fbRestore() end end)
cLight:Slider("FB_Bright", "Brightness", 1, 5, 2, 1, function(v) S.fb.bright = v end)
local cAL = tMisc:Group("Anti lag", 2)
cAL:Toggle("AL_Particles", "Matiin partikel / trail / api", false,
    function(v) S.al.particles = v if v then particlesScan() else particlesRestore() end end)
cAL:Toggle("AL_PostFX", "Matiin bloom / blur / DOF", false,
    function(v) S.al.post = v if v then postSweep() else postRestore() end end)
cAL:Toggle("AL_Shadows", "Matiin shadow", false,
    function(v) S.al.shadows = v if v then shadowsSave() else shadowsRestore() end end)
cAL:Toggle("AL_Quality", "Render quality terendah", false, function(v) S.al.quality = v setQuality(v) end)

-- scan data game: nyari tempat stats (Level, Screws, Gears, dll) disimpan, hasil ke jin_hub/jin_dump.txt
local function dumpData()
    notify("Scan", "Lagi nyari data, tunggu bentar...")
    task.spawn(function()
        local out = {}
        local function add(x) if #out < 600 then out[#out + 1] = x end end
        local function str(v) local ok, r = pcall(tostring, v) return ok and r or "?" end
        add(("== %s (%d) | team=%s"):format(lp.Name, lp.UserId, lp.Team and lp.Team.Name or "nil"))
        for k, v in pairs(lp:GetAttributes()) do add(("[attr] Player.%s = %s"):format(k, str(v))) end
        for _, d in ipairs(lp:GetDescendants()) do
            local path = d:GetFullName()
            if d:IsA("ValueBase") then add(("[value] %s = %s"):format(path, str(d.Value))) end
            for k, v in pairs(d:GetAttributes()) do add(("[attr] %s.%s = %s"):format(path, k, str(v))) end
        end
        local pats = {"level", "screw", "gear", "chance", "killer", "coin", "cash", "xp", "exp", "money", "stat", "data"}
        local function hit(n)
            n = n:lower()
            for _, p in ipairs(pats) do if n:find(p, 1, true) then return true end end
            return false
        end
        for _, root in ipairs({game:GetService("ReplicatedStorage"), pg}) do
            for idx, d in ipairs(root:GetDescendants()) do
                if idx % 400 == 0 then task.wait() end
                if not d:IsDescendantOf(gui) then
                    if d:IsA("ValueBase") and (hit(d.Name) or d.Name == lp.Name) then
                        add(("[value] %s = %s"):format(d:GetFullName(), str(d.Value)))
                    elseif (d:IsA("TextLabel") or d:IsA("TextButton")) and d.Text ~= "" and #d.Text < 60 and hit(d.Text) then
                        add(("[text] %s = %s"):format(d:GetFullName(), d.Text))
                    elseif d.Name == lp.Name or d.Name == tostring(lp.UserId) then
                        add(("[node] %s (%s)"):format(d:GetFullName(), d.ClassName))
                    end
                end
            end
        end
        local txt = table.concat(out, "\n")
        if writefile then pcall(writefile, BASE .. "jin_dump.txt", txt) end
        warn("[jin] scan selesai: " .. #out .. " baris")
        notify("Scan", writefile and "Selesai, cek jin_hub/jin_dump.txt" or "Selesai, liat F9")
    end)
end

-- scan status semua pemain (attribute, Value, animasi yang lagi jalan) -> jin_hub/jin_players.txt
-- jalanin pas ada survivor yang lagi chased / knocked / hooked, biar kelihatan nama aslinya
local function dumpPlayers()
    notify("Scan", "Nyari status pemain...")
    task.spawn(function()
        local out = {}
        local function add(x) if #out < 800 then out[#out + 1] = x end end
        local function str(v) local ok, r = pcall(tostring, v) return ok and r or "?" end
        local function dumpInst(tag, inst)
            if not inst then return end
            for k, v in pairs(inst:GetAttributes()) do add(("  [attr] %s.%s = %s"):format(tag, k, str(v))) end
            for _, c in ipairs(inst:GetChildren()) do
                if c:IsA("ValueBase") then add(("  [value] %s.%s = %s"):format(tag, c.Name, str(c.Value))) end
            end
        end
        local killers = getKillers()
        for _, plr in ipairs(Players:GetPlayers()) do
            local role = roleOf(plr)
            local char = plr.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local st = "-"
            if role == "survivor" and hum and hrp and hum.Health > 0 then
                st = survivorState(plr, char, hum, hrp, killers)
            end
            add(("== %s | role=%s | detected=%s | team=%s"):format(plr.Name, role, st, plr.Team and plr.Team.Name or "nil"))
            dumpInst("Player", plr)
            dumpInst("Char", char)
            if hum then
                add(("  [hum] health=%d/%d walkspeed=%s state=%s"):format(
                    math.floor(hum.Health), math.floor(hum.MaxHealth), str(hum.WalkSpeed), str(hum:GetState())))
                local an = hum:FindFirstChildOfClass("Animator")
                if an then
                    local ok, tracks = pcall(function() return an:GetPlayingAnimationTracks() end)
                    if ok then
                        for _, t in ipairs(tracks) do
                            add(("  [anim] %s | %s"):format(t.Name, str(t.Animation and t.Animation.AnimationId)))
                        end
                    end
                end
            end
        end
        local txt = table.concat(out, "\n")
        if writefile then pcall(writefile, BASE .. "jin_players.txt", txt) end
        warn("[jin] scan pemain selesai: " .. #out .. " baris")
        notify("Scan", writefile and "Selesai, cek jin_hub/jin_players.txt" or "Selesai, liat F9")
    end)
end

local cleanup
local cUI = tSet:Group("Tampilan", 1)
cUI:Dropdown("UI_Size", "Ukuran", {"Kecil", "Sedang", "Besar", "Jumbo"}, "Sedang", function(v) curSize = v applyLayout() end)
cUI:Dropdown("UI_Ratio", "Rasio", {"4:3", "16:10", "16:9", "21:9"}, "16:9", function(v) curRatio = v applyLayout() end)
cUI:Label("4:3 = tinggi, 21:9 = lebar dan gepeng.")
local cMenu = tSet:Group("Menu", 2)
cMenu:Button("Scan data game (buat stats)", dumpData)
cMenu:Button("Scan status pemain (chase/down/hook)", dumpPlayers)
cMenu:Button("Reset config", function()
    local p = findFile(CFG_FILE)
    if p and delfile then pcall(delfile, p) end
    notify("Config", "Dihapus, berlaku pas execute ulang")
end)
cMenu:Button("Unload Jìn Script", function() cleanup() end)
cMenu:Label("RightShift = buka/tutup menu.\nDi HP: tap logo (bisa digeser).\nSetting kesimpen otomatis di workspace/jin_hub.")

selectTab(tHome)

----------------------------------------------------------------------
-- LOOPS + CLEANUP
----------------------------------------------------------------------
task.spawn(function()
    local d = workspace:GetDescendants()
    for idx, i in ipairs(d) do
        if not running then return end
        pcall(classify, i)
        if idx % 400 == 0 then task.wait() end
    end
end)
track(workspace.DescendantAdded:Connect(function(i)
    pcall(classify, i)
    if FX[i.ClassName] and S.al.particles then task.defer(pcall, fxKill, i) end
end))
track(Players.PlayerRemoving:Connect(destroyPlayerVis))

local fpsAcc, fpsN = 0, 0
task.spawn(function() while running do pcall(update) task.wait(0.25) end end)
task.spawn(function() while running do pcall(scBind) task.wait(1) end end)
task.spawn(function()
    while running do
        if S.al.post then pcall(postSweep) end
        if S.al.particles then
            for i in pairs(fxOff) do if i.Parent and i.Enabled then pcall(function() i.Enabled = false end) end end
        end
        curFps = math.floor(fpsN / math.max(fpsAcc, 0.001) + 0.5)
        fpsAcc, fpsN = 0, 0
        if isOpen then pcall(refreshDash) end
        task.wait(1)
    end
end)
track(RS.RenderStepped:Connect(function(dt)
    pcall(updateCone)
    fpsAcc, fpsN = fpsAcc + dt, fpsN + 1
    local c = workspace.CurrentCamera
    if c and S.fov.on then c.FieldOfView = S.fov.val end
    if S.fb.on then fbApply() end
    if S.al.shadows or S.fb.on then Lighting.GlobalShadows = false end
end))
track(UIS.InputBegan:Connect(function(i, gp)
    if gp then return end
    if i.KeyCode == Enum.KeyCode.RightShift then
        setOpen(not isOpen)
    elseif i.KeyCode == Enum.KeyCode.F6 then
        local r = Reg["SC_Enabled"]
        if r then r.set(not S.sc.enabled) end
        notify("Skill check", S.sc.enabled and "ON" or "OFF")
    end
end))

function cleanup()
    if not running then return end
    running = false
    for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
    scUnbind()
    for plr in pairs(pvis) do destroyPlayerVis(plr) end
    for inst in pairs(ovis) do destroyObj(inst) end
    pcall(function() espFolder:Destroy() end)
    pcall(function() coneFolder:Destroy() end)
    S.fb.on, S.al.shadows = false, false
    pcall(fbRestore) pcall(shadowsRestore) pcall(particlesRestore) pcall(postRestore)
    pcall(setQuality, false)
    pcall(function() workspace.CurrentCamera.FieldOfView = 70 end)
    pcall(function() gui:Destroy() end)
    getgenv().JinHub = nil
end
getgenv().JinHub = {Unload = cleanup, Refresh = refreshDash}

loadConfig()
loading = false
pcall(refreshDash)
setOpen(true)
notify("Jìn Script", "Loaded")
warn("[jin] v3.2 loaded")
