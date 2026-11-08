-- Jìn Script v3.12.2 | Violence District
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
    {key = "gate",      label = "Exit Gate", color = {255, 255, 255}, on = false},
    {key = "pumpkin",   label = "Pumpkin",   color = {255, 140, 0},   on = false},
}
local CAT = {}
for _, c in ipairs(CATS) do CAT[c.key] = c end

local S = {
    cat = {}, names = true, dist = true, textSize = 13, maxDist = 600, chaseDist = 40, hookNear = 10,
    hideSpec = true, palHideDown = true, genHideDone = true, genProgCol = true, genDoneCol = Color3.fromRGB(0, 255, 80), lobby = false,
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

-- spectator / nunggu ronde: team atau attribute bernama spectat / lobby / waiting dst.
-- FILL: kalau game pake nama lain, tambahin ke SPEC_WORDS
local SPEC_WORDS = {"spectat", "lobby", "waiting", "queue", "intermission", "dead", "eliminat"}
local function specWord(str)
    str = str:lower()
    for _, w in ipairs(SPEC_WORDS) do
        if str:find(w, 1, true) then return true end
    end
    return false
end
local function isSpectator(plr)
    if plr.Team and specWord(plr.Team.Name) then return true end
    local ch = plr.Character
    for _, inst in ipairs({plr, ch}) do
        for k, v in pairs(inst:GetAttributes()) do
            local kl = k:lower()
            if type(v) == "boolean" and v and (kl:find("spectat", 1, true) or kl:find("lobby", 1, true)) then return true end
            if type(v) == "string" and ROLE_KEYS[kl] and specWord(v) then return true end
        end
    end
    return false
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
    -- dump: Workspace.Map.Gate.ExitLever (Model); LeftGate = MeshPart, Map.gate = Part (ga ke-match, Model only)
    gate      = function(i)
        if not i:IsA("Model") then return false end
        local n = i.Name:lower()
        return n == "exitlever" or n == "gate" or n == "exit" or n:find("exitgate", 1, true) ~= nil or n:find("exit gate", 1, true) ~= nil or n:find("escape", 1, true) ~= nil
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
    if not (n:find("generator") or n:find("window") or n:find("pallet") or n:find("hook") or n:find("pumpkin") or n:find("labu") or n:find("gate") or n:find("exit") or n:find("escape")) then return end
    for cat, f in pairs(MATCH) do
        if f(i) and topmost(cat, i) and not inCharacter(i) then found[cat][i] = true return end
    end
end

----------------------------------------------------------------------
-- ESP: STATUS SURVIVOR (hooked > knocked > chased)
-- urutan cek: attribute / Value di Player+Character -> animasi yang lagi jalan -> fallback jarak
--   hooked  harus dalam S.hookNear stud dari model Hook; flag hooked tapi jauh dari Hook = jatuh/merangkak (knocked)
--   chased  fallback: killer dalam S.chaseDist stud dan ga ketutup tembok (raycast)
-- kalau game pake nama lain, edit STATE_KEYS / ANIM_KEYS (cek nama attribute / animasinya langsung di game)
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

-- PROGRESS GENERATOR: nyari attribute / NumberValue bernama mirip "progress" di dalam model Generator (dicache per generator)
-- terverifikasi: attribute RepairProgress (0..100) + Completed (bool); kalau game update dan ga kedetek, isi GEN_PROG_KEYS / GEN_DONE_KEYS
local GEN_PROG_KEYS = {"progress", "percent", "repair", "completion"}
local GEN_DONE_KEYS = {"complete", "finish", "repaired", "fixed", "done", "powered"}
local GEN_SKIP_KEYS = {"max", "speed", "rate", "skill", "time", "count", "player"}
local genCache = setmetatable({}, {__mode = "k"})
local function keyHit(name, list)
    name = name:lower()
    for _, k in ipairs(list) do
        if name:find(k, 1, true) then return true end
    end
    return false
end
local function genScan(inst)
    local c = {at = os.clock()}   -- c.prog / c.done = {objek, namaAttribute|nil}
    local list = {inst}
    for _, d in ipairs(inst:GetDescendants()) do list[#list + 1] = d end
    for _, o in ipairs(list) do
        for k, v in pairs(o:GetAttributes()) do
            if type(v) == "number" and not c.prog and keyHit(k, GEN_PROG_KEYS) and not keyHit(k, GEN_SKIP_KEYS) then
                c.prog = {o, k}
            elseif type(v) == "boolean" and not c.done and keyHit(k, GEN_DONE_KEYS) then
                c.done = {o, k}
            end
        end
        if o:IsA("NumberValue") or o:IsA("IntValue") then
            if not c.prog and keyHit(o.Name, GEN_PROG_KEYS) and not keyHit(o.Name, GEN_SKIP_KEYS) then c.prog = {o} end
        elseif o:IsA("BoolValue") then
            if not c.done and keyHit(o.Name, GEN_DONE_KEYS) then c.done = {o} end
        end
    end
    return c
end
local function genRead(ref)
    local o, k = ref[1], ref[2]
    if not o.Parent then return nil end
    if k then return o:GetAttribute(k) end
    return o.Value
end
-- return: progress 0..1 (nil kalau ga kedetek), selesai (bool)
local function genProgress(inst)
    local c = genCache[inst]
    if not c or (not c.prog and not c.done and os.clock() - c.at > 3) then
        c = genScan(inst)
        genCache[inst] = c
    end
    local done, prog = false, nil
    if c.done then
        local v = genRead(c.done)
        if v == nil then genCache[inst] = nil elseif v == true then done = true end
    end
    if c.prog then
        local v = genRead(c.prog)
        if v == nil then
            genCache[inst] = nil
        elseif type(v) == "number" then
            local name = c.prog[2] or c.prog[1].Name
            if v > 1 or name:lower():find("percent", 1, true) then v = v / 100 end   -- 0..100 -> 0..1
            prog = math.clamp(v, 0, 1)
            if prog >= 0.995 then done = true end
        end
    end
    return prog, done
end

-- PALLET JATUH: nyari attribute boolean / BoolValue bernama mirip "dropped / fallen / down" di model Pallet (dicache)
-- attribute/BoolValue dicoba dulu (PAL_DOWN_KEYS); ga ada di game ini, jadi fallback struktur Intact/Broken di bawah. BELUM dites pas pallet beneran jatuh
local PAL_DOWN_KEYS = {"drop", "fall", "down", "broken", "destroy"}
local palCache = setmetatable({}, {__mode = "k"})
local function palletDown(inst)
    local c = palCache[inst]
    if not c or (not c.ref and os.clock() - c.at > 3) then
        c = {at = os.clock()}
        local list = {inst}
        for _, d in ipairs(inst:GetDescendants()) do list[#list + 1] = d end
        for _, o in ipairs(list) do
            if c.ref then break end
            for k, v in pairs(o:GetAttributes()) do
                if type(v) == "boolean" and keyHit(k, PAL_DOWN_KEYS) then c.ref = {o, k} break end
            end
            if not c.ref and o:IsA("BoolValue") and keyHit(o.Name, PAL_DOWN_KEYS) then c.ref = {o} end
        end
        palCache[inst] = c
    end
    if not c.ref then
        -- dump: pallet ga punya bool attribute, cuma child Intact / Broken (Model). Jatuh/patah = Intact ilang atau semua part-nya transparan
        local intact = inst:FindFirstChild("Intact")
        if not intact then return inst:FindFirstChild("Broken") ~= nil end
        local n = 0
        for _, d in ipairs(intact:GetDescendants()) do
            if d:IsA("BasePart") then
                n = n + 1
                if d.Transparency < 0.99 then return false end
            end
        end
        return n > 0
    end
    local v = genRead(c.ref)
    if v == nil then palCache[inst] = nil return false end
    return v == true
end

local function update()
    local lc = lp.Character
    local lhrp = lc and lc:FindFirstChild("HumanoidRootPart")
    local maxD = S.maxDist > 0 and S.maxDist or math.huge
    local ts = S.textSize
    local killers = getKillers()

    -- spectator atau lobby (ga ada Generator di map) -> semua ESP dimatiin, hemat fps
    local lobby = false
    if S.hideSpec then
        local live = false
        for g in pairs(found.generator) do
            if g.Parent and g:IsDescendantOf(workspace) then live = true break end
        end
        lobby = (not live) or isSpectator(lp)
    end
    S.lobby = lobby
    if lobby then
        for plr in pairs(pvis) do destroyPlayerVis(plr) end
        for inst in pairs(ovis) do destroyObj(inst) end
        if selfBB.bb then selfBB.bb.Enabled = false end
        return
    end

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= lp then
            local char = plr.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local role = roleOf(plr)
            local alive = hrp and hum and hum.Health > 0 and not (S.hideSpec and isSpectator(plr))
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
            elseif enabled and ((cat == "generator" and S.genHideDone and select(2, genProgress(inst))) or (cat == "pallet" and S.palHideDown and palletDown(inst))) then
                destroyObj(inst)   -- generator beres / pallet udah jatuh -> ESP dihilangin
            elseif enabled then
                local o = ovis[inst] or createObj(cat, inst)
                local prog = (cat == "generator" and S.genProgCol) and genProgress(inst) or nil
                local dist = lhrp and (inst:GetPivot().Position - lhrp.Position).Magnitude
                if (not dist) or dist <= maxD then
                    local c = S.cat[cat].color
                    if prog then c = c:Lerp(S.genDoneCol, prog) end   -- 0% = warna asli, 100% = ijo
                    o.box.Adornee = inst
                    o.box.Color3, o.box.SurfaceColor3 = c, c
                    if o.nameBB then
                        setLabel(o.nameBB, o.nameLbl, S.names and (CAT[cat].label .. (prog and (" " .. math.floor(prog * 100 + 0.5) .. "%") or "")) or "", c, ts)
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
    if S.lobby or not S.cone.on or roleOf(lp) == "killer" then coneFolder.Parent = nil return end
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
local ver = mkLabel(header, "v3.3", 10, T.dim)
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

-- SUB-TAB: strip tombol di bawah judul halaman (Player | World | ...). tab:Sub("Nama") balikin objek yang bisa dipanggil :Group() kayak Tab biasa
function Tab:SelectSub(sub)
    for _, o in ipairs(self.subs) do
        local sel = (o == sub)
        o.frame.Visible = sel
        tw(o.btn, 0.15, {BackgroundTransparency = sel and 0 or 1, TextColor3 = sel and T.text or T.dim})
    end
    self.scroll.CanvasPosition = Vector2.new(0, 0)
end
function Tab:Sub(name)
    if not self.subs then
        self.subs = {}
        self.cols[1].Parent.Visible = false   -- frame kolom bawaan tab ini ga dipake kalau pake sub-tab
        self.strip = new("Frame", {Size = UDim2.new(1, -PADL, 0, 26), Position = UDim2.fromOffset(PADL, 34), BackgroundTransparency = 1}, self.page)
        vlist(self.strip, 6, Enum.FillDirection.Horizontal)
        self.scroll.Position = UDim2.fromOffset(0, 66)
        self.scroll.Size = UDim2.new(1, 0, 1, -66)
    end
    local frame = new("Frame", {Size = UDim2.new(1, -PADR, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Visible = false}, self.scroll)
    vlist(frame, 8, Enum.FillDirection.Horizontal)
    local c1 = new("Frame", {Size = UDim2.new(0.5, -4, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = 1}, frame)
    vlist(c1, 10)
    local c2 = new("Frame", {Size = UDim2.new(0.5, -4, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = 2}, frame)
    vlist(c2, 10)
    local btn = new("TextButton", {Size = UDim2.fromOffset(#name * 7 + 24, 24), BackgroundColor3 = T.sel, BackgroundTransparency = 1,
        Text = name, TextSize = 12, Font = F_BOLD, TextColor3 = T.dim, AutoButtonColor = false, LayoutOrder = #self.subs + 1}, self.strip)
    round(btn, 12)
    local sub = setmetatable({cols = {c1, c2}, nextCol = 1, frame = frame, btn = btn}, Tab)
    self.subs[#self.subs + 1] = sub
    local owner = self
    track(btn.MouseButton1Click:Connect(function() owner:SelectSub(sub) end))
    if #self.subs == 1 then self:SelectSub(sub) end
    return sub
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
        if roleOf(p) == "killer" then killer = p.DisplayName elseif not isSpectator(p) then surv = surv + 1 end
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
-- ESP dipisah jadi sub-tab. Hide spectator / gen progress / gen beres / pallet jatuh = selalu ON (default di S), ga ada tombolnya
do
    local sP, sW = tESP:Sub("Player"), tESP:Sub("World")
    local sD, sK = tESP:Sub("Tampilan"), tESP:Sub("Area Killer")
    local cPlayers, cObj = sP:Group("Players", 1), sW:Group("Objek", 1)
    for _, c in ipairs(CATS) do
        local key = c.key
        local target = c.player and cPlayers or cObj
        target:Toggle("T_" .. key, c.label, c.on,
            function(v) S.cat[key].on = v end,
            key ~= "chased" and {id = "C_" .. key, default = S.cat[key].color, cb = function(col) S.cat[key].color = col end} or nil)
    end
    local cChase = sP:Group("Chase", 2)
    cChase:Slider("ESP_ChaseDist", "Jarak deteksi chase (0 = off)", 0, 120, 40, 5, function(v) S.chaseDist = v end, "m")
    local cRange = sW:Group("Jarak", 2)
    cRange:Slider("ESP_MaxDist", "Jarak max objek (0 = bebas)", 0, 3000, 600, 50, function(v) S.maxDist = v end, "m")
    local cLbl = sD:Group("Label", 1)
    cLbl:Toggle("ESP_Names", "Nama (di atas)", true, function(v) S.names = v end)
    cLbl:Toggle("ESP_Dist", "Jarak (di bawah)", true, function(v) S.dist = v end)
    cLbl:Slider("ESP_TextSize", "Ukuran teks", 10, 24, 13, 1, function(v) S.textSize = v end)
    local cCone = sK:Group("Area liat killer (tanah)", 1)
    cCone:Toggle("Cone_On", "Aktif", true, function(v) S.cone.on = v end)
    cCone:Slider("Cone_Angle", "Sudut area killer", 40, 180, 100, 5, function(v) S.cone.angle = v end)
    cCone:Slider("Cone_Range", "Jarak area killer", 20, 150, 70, 5, function(v) S.cone.range = v end, "m")
end

local cSC = tSC:Group("Auto skill check", 1)
cSC:Toggle("SC_Enabled", "Enabled (F6)", true, function(v) S.sc.enabled = v end)
cSC:Dropdown("SC_Mode", "Mode", {"Instant", "Perfect", "Great", "Random"}, "Perfect", function(v) S.sc.mode = v end)

-- AUTO PARRY (default OFF). Log: Items["Parrying Dagger"].parry:FireServer(karakter sendiri) -> Char.Parry=true ~0.8 dtk, abis itu Char.ParrySpent=true.
-- Normal    : REAKTIF, nembak pas animasi ayun killer (ATTACK_ANIMS) main dan killer dalam jarak + ngadep. Lewat jarak doang ga nembak.
-- Aggressive: PREDIKTIF, killer yang lagi ngejar KITA (IsChasing + ChaseTargetUserId), waktu tabrakan <= 0.4 dtk + ping/2.
-- Tiap tembakan DIVERIFIKASI: Char.Parry harus nyala <= 0.3 dtk, kalau ngga coba metode berikutnya (1 remote, 2 StopEmote+remote, 3 tool:Activate)
-- dan dicatat di baris Status. BELUM dites di game.
-- Dibungkus fungsi: batas Lua 200 local per fungsi utama kelewat kalau semua local parry ditaruh di scope file (error "attempt to call a nil value" pas load).
do local function parryInit()
    S.parry = {on = false, aggr = false, dist = 9, last = 0, busy = false, method = 2, hitOnly = true, circle = false, color = Color3.fromRGB(170, 0, 255), detect = true, learn = true, hitDot = 0.55, block = 0, cdLo = 0, nl = 0, face = false}
    -- v3.12: Parry Distance + Hit reach digabung jadi SATU slider "Jangkauan parry" (S.parry.dist, id config baru PAR_Range, ga bawa nilai lama).
    --   willHit() pake dist langsung; gerbang kandidat di hookKiller = dist*1.5 + lunge; lingkaran = dist; kalibrasi otomatis nambah slider-nya sendiri (maks 14).
    -- PARRY_DEBUG = true -> log file + id anim di Status (kayak v3.10). Set false sebelum publish (id ke-mask, file log ga ditulis).
    local PARRY_DEBUG = true
    -- id animasi ayun killer, ditanem di script. Sumber: baris "HIT KITA" / parry sukses di jin_parry_log.txt.
    -- SENGAJA ga dimasukin: 87833180786200, 110466971021611 (muncul berkala pas killer deket 3.5m dot 1.0 = bukan serangan), 101443662521580 (muncul abis kena hit).
    local ATTACK_ANIMS = {}
    for _, id in ipairs({
        "135002183282873", "121216847022485",   -- Slasher
        "81963230963908", "84926129581106",     -- pasangan ayunan (HIT KITA di 81963230963908)
        "117042998468241", "133963973694098", "105374834496520", "111920872708571", "101636125032002",   -- HIT KITA terkonfirmasi
        "129626174716003", "113691709436161", "130593238885843",   -- hasil auto-learn lama, BELUM diverifikasi ulang
    }) do ATTACK_ANIMS[id] = true end
    local cPar = tSC:Group("Auto parry (Dagger)", 2)
    cPar:Toggle("PAR_On", "Auto Parry", false, function(v) S.parry.on = v end)
    cPar:Toggle("PAR_Aggr", "Auto Parry Aggressive (Predict)", false, function(v) S.parry.aggr = v end)
    cPar:Toggle("PAR_Detect", "Deteksi anim serang semua killer", true, function(v) S.parry.detect = v end)
    cPar:Toggle("PAR_Learn", "Auto-learn anim serang dari hit", true, function(v) S.parry.learn = v end)
    cPar:Toggle("PAR_Face", "Hadap killer pas parry (tes: parry depan doang?)", false, function(v) S.parry.face = v end)
    cPar:Slider("PAR_Range", "Jangkauan parry", 4, 16, 9, 0.5, function(v) S.parry.dist = v end, "m")
    cPar:Toggle("PAR_HitOnly", "Parry cuma kalau ayunan bakal KENA", true, function(v) S.parry.hitOnly = v end)
    cPar:Toggle("PAR_Circle", "Show Parry Circle", false, function(v) S.parry.circle = v end,
        {id = "PAR_CircleCol", default = S.parry.color, cb = function(c) S.parry.color = c end})
    local stLbl = cPar:Label("Status: OFF")
    -- learned = anim serang hasil auto-learn. nopar = anim yang TEMBUS parry dari depan, di-skip. stats[id] = {pf,bf,po,bo}. Disimpen ke jin_parry.json
    local learned, recent, nopar, stats = {}, {}, {}, {}
    local PFILE = BASE .. "jin_parry.json"
    local function saveP()
        if not writefile then return end
        pcall(function()
            local a, n = {}, {}
            for id in pairs(learned) do a[#a + 1] = id end
            for id in pairs(nopar) do n[#n + 1] = id end
            writefile(PFILE, HttpService:JSONEncode({anims = a, nopar = n, stats = stats, btn = S.parry.btn, key = S.parry.key and S.parry.key.Name}))
        end)
    end
    local function addLearn(id, why)
        learned[id] = true
        S.parry.nl = S.parry.nl + 1
        saveP()
        notify("Auto parry", "anim serang baru (" .. tostring(why) .. "): " .. id)
    end
    pcall(function()
        if isfile and readfile and isfile(PFILE) then
            local d = HttpService:JSONDecode(readfile(PFILE))
            for _, id in ipairs(d.anims or {}) do learned[tostring(id)] = true S.parry.nl = S.parry.nl + 1 end
            for _, id in ipairs(d.nopar or {}) do nopar[tostring(id)] = true end
            if type(d.stats) == "table" then stats = d.stats end
            if type(d.btn) == "table" then S.parry.btn = d.btn end
            if type(d.key) == "string" then S.parry.key = Enum.KeyCode[d.key] end
        end
    end)
    -- LOG (v3.5): tiap tembakan / hit / skip ditulis ke jin_parry_log.txt (200 baris terakhir) buat diagnosa "notif muncul tapi dagger ga kepake"
    local LOGF = BASE .. "jin_parry_log.txt"
    local logbuf, logBusy = {}, false
    local function plog(...)
        if not PARRY_DEBUG then return end
        local a = table.pack(...)
        for i = 1, a.n do a[i] = tostring(a[i]) end
        logbuf[#logbuf + 1] = ("[%.2f] %s"):format(os.clock(), table.concat(a, " ", 1, a.n))
        if #logbuf > 600 then table.remove(logbuf, 1) end
        if writefile and not logBusy then   -- debounce: writefile tiap baris bikin burst event nge-lag
            logBusy = true
            task.delay(1, function()
                logBusy = false
                pcall(writefile, LOGF, table.concat(logbuf, "\n"))
            end)
        end
    end
    local function attrDump(inst)
        local o = {}
        if inst then
            for k, v in pairs(inst:GetAttributes()) do o[#o + 1] = k .. "=" .. tostring(v) end
        end
        table.sort(o)
        return table.concat(o, ",")
    end
    local function toolLoc(ch)
        local bp = lp:FindFirstChild("Backpack")
        if ch:FindFirstChild("Parrying Dagger") then return "char" end
        if bp and bp:FindFirstChild("Parrying Dagger") then return "backpack" end
        return "ga ada"
    end
    local function render(base)
        local P = S.parry
        local t = base
        local function mask(s) return PARRY_DEBUG and s or (s:gsub("%d%d%d%d%d%d+", "#")) end   -- publik: id anim ga boleh nongol di UI
        if P.res and os.clock() - P.resT < 6 then t = t .. " | " .. mask(P.res) end
        if PARRY_DEBUG and P.anim then t = t .. " | anim killer: " .. P.anim end
        if PARRY_DEBUG then t = t .. " | learned " .. P.nl end
        if P.why and os.clock() - (P.whyT or 0) < 6 then t = t .. " | skip: " .. mask(P.why) end
        if PARRY_DEBUG and P.cdAttr then t = t .. " | " .. P.cdAttr end
        if P.stat ~= t then P.stat = t stLbl.Text = t end
    end
    local function attr(k)
        local v = lp:GetAttribute(k)
        if v == nil and lp.Character then v = lp.Character:GetAttribute(k) end
        return v
    end
    local function rm(...)
        local o = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
        for _, n in ipairs({...}) do o = o and o:FindFirstChild(n) end
        return o
    end
    -- PARRYCLIENT (v3.9, dari jin_parry_src.txt): instance ParryClient (self) diambil sekali dari upvalue closure Gui-mob.MouseButton1Down dan di-cache
    -- (getconnections tiap tembakan lambat: sempat 0.25 dtk antara FIRE dan handler, padahal hit dateng ~0.2 dtk). Dari instance ini:
    --   self:CanUse() = equipped + ga silenced + ga cooldown (server kasih angkanya lewat parryResult) + ga resolving + ga busy + HP >= 50%
    --   self:Parry()  = kode asli: FireServer(char) -> puter badan -> anim -> berhenti (slow 0) ; dipanggil langsung, tanpa tes hit lingkaran tombol
    local pc = {t = 0}
    local function parryBtn()
        local pgui = lp:FindFirstChild("PlayerGui")
        local m = pgui and pgui:FindFirstChild("Survivor-mob")
        local c = m and m:FindFirstChild("Controls")
        return c and c:FindFirstChild("Gui-mob")
    end
    local function findParryObj()
        local b = parryBtn()
        local gu = (debug and debug.getupvalues) or getupvalues
        if not (b and getconnections and gu) then return nil end
        local ok, cs = pcall(getconnections, b.MouseButton1Down)
        if not ok then return nil end
        for _, c in ipairs(cs) do
            local f = c.Function
            local okS, sc = pcall(function() return getfenv(f).script end)
            if f and okS and sc and sc.Name == "ParryClient" then
                local okU, us = pcall(gu, f)
                if okU and type(us) == "table" then
                    for _, u in pairs(us) do
                        if type(u) == "table" and rawget(u, "parryEvent") then
                            pc.self = u
                            plog("PARRYOBJ ketemu | tool", tostring(u.tool and u.tool:GetFullName()), "| lockDuration", tostring(u.lockDuration))
                            return u
                        end
                    end
                end
            end
        end
        return nil
    end
    local function parryObj()
        local s = pc.self
        if s and s.tool and s.tool.Parent and s.character == lp.Character then return s end
        if os.clock() - pc.t < 1 then return nil end   -- cari ulang paling cepet 1x / dtk (respawn / ronde baru bikin instance baru)
        pc.t = os.clock()
        pc.self = nil
        return findParryObj()
    end
    task.spawn(function()   -- hasil parry dari server: success, cooldown, permanent, chain, char. Cuma dicatat.
        local ok, r = pcall(function()
            return game:GetService("ReplicatedStorage"):WaitForChild("Remotes", 30):WaitForChild("Items", 30):WaitForChild("Parrying Dagger", 30):WaitForChild("parryResult", 30)
        end)
        if ok and r then
            track(r.OnClientEvent:Connect(function(...)
                local a = table.pack(...)
                for i = 1, a.n do a[i] = tostring(a[i]) end
                plog("PARRYRESULT", table.concat(a, " | ", 1, a.n))
            end))
        end
    end)
    -- return ch, hum kalau boleh nembak, atau nil + alasan
    local function ready()
        local ch = lp.Character
        local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
        local hum = ch and ch:FindFirstChildOfClass("Humanoid")
        if not (hrp and hum and hum.Health > 0) then return nil, "belum spawn / mati" end
        if roleOf(lp) == "killer" then return nil, "kamu killer" end
        local eq = attr("EquippedItem")
        if eq ~= nil and eq ~= "Parrying Dagger" then return nil, "item = " .. tostring(eq) .. ", bukan dagger" end
        if ch:GetAttribute("ParrySpent") then return nil, "ParrySpent aktif" end
        if ch:GetAttribute("Parry") or ch:GetAttribute("Knocked") then return nil, "parry lagi aktif / knocked" end
        local P = S.parry
        local now = os.clock()
        if now < P.block then return nil, ("dagger cooldown ~%.1f dtk"):format(P.block - now) end
        local po = parryObj()
        if po then
            local okC, can = pcall(po.CanUse, po)
            if okC and can == false then return nil, "dagger ga bisa dipake (cooldown / resolving / busy / HP < 50%)" end
        end
        -- kalau game punya attribute cooldown (nama ada "cool") di karakter / tool: ditampilin di Status. boolean true = lagi cooldown
        local out = {}
        local bp = lp:FindFirstChild("Backpack")
        for _, inst in ipairs({ch, ch:FindFirstChild("Parrying Dagger") or (bp and bp:FindFirstChild("Parrying Dagger"))}) do
            for n, v in pairs(inst:GetAttributes()) do
                if n:lower():find("cool") then out[#out + 1] = n .. "=" .. tostring(v) end
            end
        end
        P.cdAttr = #out > 0 and table.concat(out, ",") or nil
        for _, o in ipairs(out) do if o:find("=true$") then return nil, "attr " .. o end end
        return ch, hum, hrp
    end
    -- PRESS ASLI: dagger yang ditembak lewat remote doang ga mencet apa-apa di sisi klien (anim / tombol ga jalan). Jadi script ngerekam
    -- parry MANUAL kamu: tombol GUI / key yang kepencet <= 0.5 dtk sebelum Char.Parry nyala, terus nge-press yang sama pas auto.
    -- Urutan press: Tool:Activate (kalau dagger ada sbg Tool) -> tombol kerekam (firesignal) -> key kerekam (VirtualInputManager).
    local UIS = game:GetService("UserInputService")
    local lastIn, lastKey, hookedBtn = {t = 0}, {t = 0}, setmetatable({}, {__mode = "k"})
    local function hookBtn(b)
        if hookedBtn[b] or not b:IsA("GuiButton") then return end
        hookedBtn[b] = true
        track(b.Activated:Connect(function() lastIn = {t = os.clock(), btn = b, name = b:GetFullName()} end))
    end
    task.spawn(function()
        local pg = lp:WaitForChild("PlayerGui", 15)
        if not pg then return end
        for _, d in ipairs(pg:GetDescendants()) do hookBtn(d) end
        track(pg.DescendantAdded:Connect(hookBtn))
    end)
    track(UIS.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.Keyboard then lastKey = {t = os.clock(), code = i.KeyCode} end
    end))
    local parryHooked = setmetatable({}, {__mode = "k"})
    local function watchParryAttr()
        local ch = lp.Character
        if not ch or parryHooked[ch] then return end
        parryHooked[ch] = true
        track(ch:GetAttributeChangedSignal("Parry"):Connect(function()
            local P = S.parry
            if not ch:GetAttribute("Parry") or os.clock() - (P.firedT or 0) < 1.2 then return end   -- bukan parry manual
            local now, info = os.clock(), {}
            if lastIn.btn and now - lastIn.t < 0.5 then
                P.btn, P.btnInst = {name = lastIn.btn.Name, parent = lastIn.btn.Parent and lastIn.btn.Parent.Name}, lastIn.btn
                info[#info + 1] = "tombol " .. lastIn.name
            end
            if lastKey.code and now - lastKey.t < 0.5 then P.key = lastKey.code info[#info + 1] = "key " .. lastKey.code.Name end
            P.res = "parry MANUAL kerekam: " .. (#info > 0 and table.concat(info, ", ") or "ga ada tombol/key (mungkin sentuhan layar / input lain)") .. " | item " .. tostring(attr("EquippedItem"))
            P.resT = os.clock()
            saveP()
        end))
    end
    local function findBtn()
        local P = S.parry
        if P.btnInst and P.btnInst.Parent then return P.btnInst end
        local pg, b = lp:FindFirstChild("PlayerGui"), P.btn
        if not (pg and b) then return end
        for _, d in ipairs(pg:GetDescendants()) do
            if d:IsA("GuiButton") and d.Name == b.name and d.Parent and d.Parent.Name == b.parent then P.btnInst = d return d end
        end
    end
    local function pressReal(ch, hum)
        local P = S.parry
        local bp = lp:FindFirstChild("Backpack")
        local tool = ch:FindFirstChild("Parrying Dagger") or (bp and bp:FindFirstChild("Parrying Dagger"))
        if tool and tool:IsA("Tool") then
            if tool.Parent ~= ch then hum:EquipTool(tool) task.wait(0.1) end
            tool:Activate()
            return
        end
        local b = findBtn()
        if b and firesignal then
            pcall(firesignal, b.Activated)
            pcall(firesignal, b.MouseButton1Click)
            return
        end
        if P.key then
            pcall(function()
                local vim = game:GetService("VirtualInputManager")
                vim:SendKeyEvent(true, P.key, false, game)
                task.wait(0.03)
                vim:SendKeyEvent(false, P.key, false, game)
            end)
        end
    end
    -- HANDLER ASLI (v3.8, dari jin_recon.txt): tombol parry HP = PlayerGui.Survivor-mob.Controls.Gui-mob. MouseButton1Down-nya disambung ke module
    -- ReplicatedStorage.Modules.Items.ParryingDagger.ParryClient (Activated / yang lain cuma UI). Kita panggil function itu langsung (pola sama kayak
    -- skill check), jadi yang jalan kode client asli: animasi, berhenti, gate recharge, baru remote. Remote-doang (metode lama) ga ngelewatin itu semua.
    -- fallback lambat (instance ga kebaca dari upvalue): panggil closure tombol lewat getconnections. return jumlah handler yang dipanggil, alasan
    local function pressHandlerSlow()
        local b = parryBtn()
        if not b then return 0, "tombol Survivor-mob.Controls.Gui-mob ga ada" end
        if not getconnections then return 0, "getconnections ga ada" end
        local pos = b.AbsolutePosition + b.AbsoluteSize / 2
        local n = 0
        local ok, cs = pcall(getconnections, b.MouseButton1Down)
        if not ok then return 0, "getconnections error" end
        for _, c in ipairs(cs) do
            local f = c.Function
            local okS, sc = pcall(function() return getfenv(f).script end)
            if f and okS and sc and sc.Name == "ParryClient" then
                local ok2, err = pcall(f, pos.X, pos.Y)
                n = n + 1
                plog("  HANDLER ParryClient dipanggil | ok", ok2, err or "")
            end
        end
        return n, n == 0 and "ParryClient ga nyambung ke Gui-mob.MouseButton1Down" or nil
    end
    -- coba handler asli dulu; kalau ga ketemu baru metode remote lama. Berhasil (remote) = Char.Parry nyala <= 0.3 dtk
    local function attempt(ch, hum)
        local P = S.parry
        local hn, hwhy
        local po = parryObj()
        if po then
            -- jalur cepat: instance ParryClient udah di-cache. Parry() nunggu animasi (yield) -> task.spawn biar ga ngeblok
            task.spawn(function()
                local okP, errP = pcall(po.Parry, po)
                plog("  Parry() selesai | ok", okP, errP or "")
            end)
            hn = 1
        else
            hn, hwhy = pressHandlerSlow()
        end
        if hn > 0 then
            task.delay(0.3, function()
                plog("  +0.3s setelah handler | Parry attr", tostring(ch:GetAttribute("Parry")), "| ParrySpent", tostring(ch:GetAttribute("ParrySpent")), "| WalkSpeed", hum.WalkSpeed)
            end)
            return 0   -- 0 = handler asli (ga diverifikasi lewat attr Parry: belum ada bukti attr itu nyala di jalur asli)
        end
        plog("  handler asli ga bisa:", hwhy)
        local function on()
            local t0 = os.clock()
            repeat
                if ch:GetAttribute("Parry") then return true end
                task.wait()
            until os.clock() - t0 > 0.3
            return false
        end
        local steps = {
            function() pressReal(ch, hum) end,
            function() local r = rm("Items", "Parrying Dagger", "parry") if r then r:FireServer(ch) end end,
            function()
                local e = rm("EmoteHandler")
                if e then e:FireServer("StopEmote") end
                local r = rm("Items", "Parrying Dagger", "parry")
                if r then r:FireServer(ch) end
            end,
        }
        -- v3.6: log nunjukin step 2 (remote doang) udah cukup bikin Char.Parry nyala, sedangkan step 1 (press) ga ngapa-ngapain kalau
        -- tombol/key belum kerekam dan malah buang 0.3 dtk. Sekarang remote duluan, press cuma dipake kalau ada tombol/key kerekam.
        local hasPress = P.btn or P.key or P.btnInst
        local order = {}
        for _, i in ipairs({P.method, 2, 3, 1}) do
            local dup = false
            for _, o in ipairs(order) do if o == i then dup = true end end
            if not dup and (i ~= 1 or hasPress) then order[#order + 1] = i end
        end
        for _, i in ipairs(order) do
            local okc, err = pcall(steps[i])
            local good = on()
            plog("  step", i, "pcall", okc, err or "", "-> Parry nyala:", good, "| EquippedItem", attr("EquippedItem"), "| dagger di", toolLoc(ch), "| ParrySpent", ch:GetAttribute("ParrySpent"))
            if good then P.method = i return i end
        end
        return nil
    end
    -- hasil tiap parry yang KITA tembak: tembus (kena hit <= 0.8 dtk) atau ketahan. Dari sini nopar & statistik depan/belakang keisi sendiri.
    local function resolvePending(pd)
        if pd.done then return end
        pd.done = true
        local id = pd.pid or pd.id
        if not id then return end
        local st = stats[id]
        if not st then st = {pf = 0, bf = 0, po = 0, bo = 0} stats[id] = st end
        local key = (pd.pierced and "p" or "b") .. (pd.front and "f" or "o")
        st[key] = (st[key] or 0) + 1
        local arah = pd.front and "depan" or "samping/belakang"
        if pd.pierced then
            S.parry.res = ("KENA walau parry (%s) anim %s"):format(arah, id)
            S.parry.resT = os.clock()
            if pd.front and st.pf >= 2 and st.pf > st.bf and not nopar[id] then
                nopar[id] = true
                notify("Auto parry", "ada serangan yang tembus parry dari depan -> di-skip (ga bisa di-parry)")
            end
        end
        saveP()
    end
    -- killer lagi ngerjain objek (gen / pallet / window) = bukan nyerang kita: killer ngadep objek lebih lurus daripada ngadep kita
    local function nearInteract(k, toUs)
        local kp, look = k.hrp.Position, k.hrp.CFrame.LookVector
        local ours = look:Dot(toUs)
        for _, cat in ipairs({"generator", "pallet", "window"}) do
            for o in pairs(found[cat]) do
                if o.Parent then
                    local ok, pos = pcall(function() return o:GetPivot().Position end)
                    if ok then
                        local v = pos - kp
                        local dist = v.Magnitude
                        if dist > 0 and dist <= 8 and look:Dot(v.Unit) > ours then return cat end
                    end
                end
            end
        end
    end
    -- cooldown dagger ga ada datanya -> diukur sendiri. okT = kapan terakhir parry NYALA, cdLo = batas bawah cooldown (dibuktiin dari tembakan gagal).
    -- gagal pas jarak dari okT = x -> cooldown > x -> cdLo = x + 0.25, tembak lagi nunggu segitu (ga spam 3 metode).
    -- sukses pas jarak x < cdLo -> cdLo turun ke x. Konvergen dalam 2-3 parry.
    -- v3.10: rincian CanUse() buat log NOFIRE. Log v3.9: EVAL bilang TEMBAK tapi ga ada FIRE sama sekali, alasannya ketelen diem-diem di ready().
    local function cuDetail()
        local P = S.parry
        local po = parryObj()
        if not po then return "ParryClient: ga ketemu" end
        local function f(name)
            local ok, v = pcall(po[name], po)
            return ok and tostring(v) or "err"
        end
        local ch = lp.Character
        local hum = ch and ch:FindFirstChildOfClass("Humanoid")
        return ("ParryClient: equipped %s | silenced %s | cooldown %s | resolving %s | busy %s | lowHP %s | HP %s/%s | block %.1fs"):format(
            f("_isEquipped"), tostring(po.isSilenced), tostring(po.isParryOnCooldown), tostring(po.isParryResolving), f("_isBusy"), f("_isLowHealth"),
            hum and ("%.0f"):format(hum.Health) or "?", hum and ("%.0f"):format(hum.MaxHealth) or "?", math.max(0, P.block - os.clock()))
    end
    local function tryFire(reason, k, id)
        local P = S.parry
        if P.busy then return end
        local ch, hum = ready()
        if not ch then
            local now = os.clock()
            if P.nfWhy ~= hum or now - (P.nfT or 0) > 1 then   -- hum = alasan (string) kalau ready() nolak
                P.nfWhy, P.nfT = hum, now
                plog("NOFIRE", reason, "id", id, "|", hum, "|", cuDetail())
            end
            return
        end
        P.busy = true
        local t0 = os.clock()
        plog("FIRE", reason, "id", id, "| sejak anim mulai", P.animT and ("%.3fs"):format(t0 - P.animT) or "-", "| ping", pcall(function() return lp:GetNetworkPing() end) and ("%.3f"):format(lp:GetNetworkPing()) or "?", "| char:", attrDump(ch))
        P.block = t0 + 0.35
        P.firedT = t0
        task.spawn(function()
            local hrp = ch:FindFirstChild("HumanoidRootPart")
            if P.face and hrp and k and k.hrp.Parent then
                -- opsi: puter badan ke killer dulu (kalau parry ternyata cuma kena dari depan). CFrame client -> ke-replicate
                local kp = k.hrp.Position
                hrp.CFrame = CFrame.lookAt(hrp.Position, Vector3.new(kp.X, hrp.Position.Y, kp.Z))
                task.wait(0.05)
            end
            local front = false
            if hrp and k and k.hrp.Parent then
                local dir = k.hrp.Position - hrp.Position
                front = dir.Magnitude > 0 and hrp.CFrame.LookVector:Dot(dir.Unit) >= 0.5
            end
            local m = attempt(ch, hum)
            P.busy = false
            local since = P.okT and t0 - P.okT
            if since and since > 60 then since = nil end
            if m then
                if since and since < P.cdLo then P.cdLo = since end
                P.okT = t0
                P.block = t0 + (parryObj() and 0.8 or math.max(P.cdLo, 0.8))   -- ada ParryClient: cooldown asli dicek CanUse() di ready(), ga perlu tebakan cdLo
                P.res = ("parry DITEKAN via %s (%s, killer di %s) | cd>=%.1fs"):format(m == 0 and "handler asli" or ("remote metode " .. m), reason, front and "depan" or "samping/belakang", P.cdLo)
                if m ~= 0 then notify("Auto parry", "Parry nyala (" .. reason .. ")") end   -- handler asli: ga ada bukti nyala, cek log
                local pd = {id = id, front = front, t = os.clock()}
                P.pending = pd
                task.delay(0.9, function() resolvePending(pd) end)
            else
                if since then
                    P.cdLo = math.max(P.cdLo, since + 0.25)
                    P.block = math.max(P.okT + P.cdLo, os.clock() + 0.2)
                else
                    P.block = os.clock() + 1
                end
                P.res = ("parry GAGAL (kemungkinan cooldown) | cd>=%.1fs"):format(P.cdLo)
            end
            P.resT = os.clock()
        end)
    end
    -- reaktif: dengerin animasi killer.
    -- ATTACK_ANIMS = hardcode (Slasher). learned = anim yang kebukti nurunin HP SURVIVOR MANAPUN (bukan cuma kita), disimpen ke file.
    -- detect (heuristik) = anim non-loop, priority Action+, panjang 0.3-2.5 dtk, buat killer yang belum kepelajar.
    local SWING_PRIO = {
        [Enum.AnimationPriority.Action] = true, [Enum.AnimationPriority.Action2] = true,
        [Enum.AnimationPriority.Action3] = true, [Enum.AnimationPriority.Action4] = true,
    }
    local function looksLikeSwing(tr)
        if tr.Looped or not SWING_PRIO[tr.Priority] then return false end
        local L = tr.Length
        return L == 0 or (L >= 0.3 and L <= 2.5)   -- L == 0: track belum ke-load, jangan dibuang
    end
    -- TARGET GATE (v3.4): killer cuma dihitung nyerang KITA kalau (1) arah bidik (CamLook, fallback LookVector) ngarah ke kita
    -- dan (2) ga ada survivor lain yang jelas lebih pas di garis bidik dia. Dagger kebuang kalau nembak ayunan ke orang lain.
    -- Bidik diukur di bidang datar (Y dibuang), sama kayak cone.
    local function aimOf(k)
        local cl = k.char:GetAttribute("CamLook")
        local v = (typeof(cl) == "Vector3") and cl or k.hrp.CFrame.LookVector
        v = Vector3.new(v.X, 0, v.Z)
        if v.Magnitude < 0.01 then
            local lv = k.hrp.CFrame.LookVector
            v = Vector3.new(lv.X, 0, lv.Z)
        end
        return v.Magnitude > 0.01 and v.Unit or Vector3.new(0, 0, 1)
    end
    local function aimDot(aim, from, to)
        local v = Vector3.new(to.X - from.X, 0, to.Z - from.Z)
        if v.Magnitude < 0.01 then return 1 end
        return aim:Dot(v.Unit)
    end
    local AIM_MIN, AIM_MARGIN = 0.55, 0.15   -- ~57 derajat dari bidik; survivor lain dianggap target kalau lebih lurus >= 0.15
    local function targetsUs(k, hrp)
        local aim, kp = aimOf(k), k.hrp.Position
        local mine = aimDot(aim, kp, hrp.Position)
        -- v3.12.1: log: killer lunge 12-13m, hit kena tapi CamLook belum ngadep (dot < 0.55) -> ke-skip. Kalau killer lagi mendekat cepet, batas dot dilonggarin.
        local closeV = (k.hrp.AssemblyLinearVelocity - hrp.AssemblyLinearVelocity):Dot((hrp.Position - kp).Unit)
        local minDot = closeV > 8 and 0.2 or AIM_MIN
        if mine < minDot then return false, ("killer ga ngebidik kita (dot %.2f, mendekat %.0f)"):format(mine, closeV) end
        local dMine = (hrp.Position - kp).Magnitude
        for _, pl in ipairs(Players:GetPlayers()) do
            if pl ~= lp and roleOf(pl) ~= "killer" then
                local c = pl.Character
                local h = c and c:FindFirstChild("HumanoidRootPart")
                local hm = c and c:FindFirstChildOfClass("Humanoid")
                if h and hm and hm.Health > 0 and not c:GetAttribute("Knocked") then
                    local dv = (h.Position - kp).Magnitude
                    if dv <= dMine and aimDot(aim, kp, h.Position) >= math.max(AIM_MIN, mine + AIM_MARGIN) then
                        return false, "killer ngincer " .. pl.DisplayName
                    end
                end
            end
        end
        return true
    end
    -- HIT PREDICTION (v3.7): parry baru nyala ~0.13 dtk setelah ditembak, hit dateng ~0.2 dtk setelah anim mulai -> ga bisa nunggu HP turun.
    -- Jadi tunggu EVAL_DELAY (biar kecepatan lunge killer kebaca), ekstrapolasi posisi killer + kita sampai waktu hit, tembak kalau
    -- jarak prediksi <= hitReach dan kita masih di arah bidik (dot >= hitDot). hitReach / hitDot MELEBAR sendiri tiap kita kena hit
    -- yang tadinya diprediksi meleset (auto-kalibrasi, lihat watchHum).
    -- v3.9: log: anim killer baru kelihatan ~0.02 dtk sebelum hit (anim 121216847022485), jadi nunggu 0.04 dtk = pasti telat. Putusin langsung, ekstrapolasi 0.12 dtk.
    local HIT_T, EVAL_DELAY = 0.12, 0
    local function willHit(k, hrp, tRem)
        local P = S.parry
        local kv, uv = k.hrp.AssemblyLinearVelocity, hrp.AssemblyLinearVelocity
        local kp = k.hrp.Position + Vector3.new(kv.X, 0, kv.Z) * tRem
        local up = hrp.Position + Vector3.new(uv.X, 0, uv.Z) * tRem
        local d = Vector3.new(up.X - kp.X, 0, up.Z - kp.Z).Magnitude
        local dot = aimDot(aimOf(k), kp, up)
        return d <= P.dist and dot >= P.hitDot, d, dot   -- P.dist = slider "Jangkauan parry"
    end
    local hooked = setmetatable({}, {__mode = "k"})
    local hookedAttr = setmetatable({}, {__mode = "k"})
    local kanimT = {}
    local KATTR_SKIP = {CamLook = true, VeilRenderedAt = true, AC_MovementGraceUntil = true, AC_StrictAllowedSpeedUntil = true, AC_AllowedSpeed = true, CorruptWaveAt = true, CorruptWaveFrom = true, CorruptWaveDir = true, CorruptWindupAt = true}
    -- KATTR: perubahan attribute di karakter killer (jarak <= 30m dari kita) -> cari attribute "lagi nyerang" (mis. ActionState/Attacking) biar id anim jadi opsional
    local function hookKillerAttrs(k)
        if not PARRY_DEBUG or hookedAttr[k.char] then return end
        hookedAttr[k.char] = true
        local old, lastT = k.char:GetAttributes(), {}
        plog("KATTR awal", k.char.Name, "|", attrDump(k.char))
        track(k.char.AttributeChanged:Connect(function(name)
            if KATTR_SKIP[name] then return end
            local v = k.char:GetAttribute(name)
            local pv = old[name]
            old[name] = v
            local ch = lp.Character
            local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
            if not (hrp and k.hrp.Parent) then return end
            local d = (hrp.Position - k.hrp.Position).Magnitude
            if d > 30 then return end
            local now = os.clock()
            if typeof(v) == "number" and now - (lastT[name] or 0) < 0.25 then return end   -- atribut angka yang berubah terus (noise)
            lastT[name] = now
            plog("KATTR", k.char.Name, name, tostring(pv), "->", tostring(v), ("| %.1fm"):format(d))
        end))
    end
    local function hookKiller(k)
        hookKillerAttrs(k)
        -- Animator bisa ada di Humanoid atau AnimationController, cari rekursif. Key = animator, jadi kalau diganti ke-hook ulang
        local an = k.char:FindFirstChildWhichIsA("Animator", true)
        if not an or hooked[an] then return end
        hooked[an] = true
        track(an.AnimationPlayed:Connect(function(tr)
            local a = tr.Animation
            local id = a and tostring(a.AnimationId):match("%d+")
            if not (id and k.hrp.Parent) then return end
            local P = S.parry
            if not tr.Looped then   -- log SEMUA anim non-loop killer (jarak berapa pun) buat auto-learn dari hit survivor lain
                local now = os.clock()
                recent[#recent + 1] = {id = id, t = now, pos = k.hrp.Position, swing = looksLikeSwing(tr)}
                while #recent > 0 and (now - recent[1].t > 2 or #recent > 30) do table.remove(recent, 1) end
            end
            local ch = lp.Character
            local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            local off = hrp.Position - k.hrp.Position
            local d = off.Magnitude
            if PARRY_DEBUG and d <= 30 and d > 0 then   -- KANIM: ciri anim killer (id, priority, panjang, loop) buat cari sinyal "lagi nyerang" yang generik
                local nk = os.clock()
                kanimT[id] = kanimT[id] or 0
                if nk - kanimT[id] > 0.5 then
                    kanimT[id] = nk
                    plog("KANIM", id, "| prio", tostring(tr.Priority):gsub("Enum.AnimationPriority.", ""), ("| len %.2f | %s | %.1fm | killer %s"):format(tr.Length, tr.Looped and "loop" or "once", d, k.char.Name))
                end
            end
            if d > 30 or d == 0 then return end   -- cap kasar, jarak sebenernya dicek di bawah (reach = dist*1.3 + lunge)
            local nowT = os.clock()
            if P.lastId == id and nowT - (P.lastIdT or 0) < 0.1 then return end   -- log: 76 event anim sama dalam 0.1 dtk (burst)
            P.lastId, P.lastIdT = id, nowT
            P.anim = ("%s %.2fs %.0fm %s"):format(id, tr.Length, d, tr.Looped and "loop" or "once")
            P.animT = os.clock()
            if not P.on then return end
            -- alasan skip ditulis ke Status (skip: ...) biar keliatan kenapa ga nembak
            local toUs = off.Unit
            local known = ATTACK_ANIMS[id] or learned[id]
            -- killer lunge: log nunjukin killer mulai ayun dari 9m lalu tetep kena. Jarak dihitung + kecepatan dia ke arah kita x 0.25 dtk (delay hit ~0.2 dtk)
            local closing = (k.hrp.AssemblyLinearVelocity - hrp.AssemblyLinearVelocity):Dot(toUs)
            local reach = P.dist * 1.5 + math.max(0, closing) * 0.25   -- gerbang kandidat otomatis dari slider; keputusan akhir di willHit()
            local why
            if not (known or (P.detect and looksLikeSwing(tr))) then why = "anim " .. id .. " ga dikenal sbg serangan"
            elseif nopar[id] then why = "anim " .. id .. " ga bisa di-parry"
            elseif not known and not (d <= P.dist or (k.char:GetAttribute("IsChasing") and k.char:GetAttribute("ChaseTargetUserId") == lp.UserId)) then
                why = "tebakan: killer ga lagi ngejar kita"   -- anim belum dikenal cuma ditembak kalau killer ngejar KITA / udah deket banget
            elseif d > reach then why = ("killer %.0fm, di luar jarak (reach %.0fm)"):format(d, reach)
            else
                local ok, w = targetsUs(k, hrp)
                if not ok then why = w
                else
                    -- v3.12.2: log: 2 ayunan asli ke-skip "killer lagi ngerjain window" (killer deket jendela pas nyerang kita, 1.9m / 7.6m) -> kena hit.
                    -- id yang udah dikenal = pasti serangan, cek gen/pallet/window cuma buat tebakan.
                    local near = (not known) and nearInteract(k, toUs)
                    if near then why = "killer lagi ngerjain " .. near end
                end
            end
            if why then
                P.why, P.whyT = why, os.clock()
                if known then plog("SKIP anim", id, "|", why) end
                return
            end
            local reason = known and "ayunan" or "ayunan (tebakan)"
            task.delay(EVAL_DELAY, function()
                local P2 = S.parry
                if not (running and P2.on and k.hrp.Parent) then return end
                local c2 = lp.Character
                local h2 = c2 and c2:FindFirstChild("HumanoidRootPart")
                if not h2 then return end
                local ok2, d2, dot2 = willHit(k, h2, HIT_T - EVAL_DELAY)
                P2.lastEval = {id = id, t = os.clock(), d = d2, dot = dot2}
                plog("EVAL anim", id, ("| d_prediksi %.1f (range %.1f) | dot %.2f (min %.2f) | jarak skrg %.1f | ->"):format(d2, P2.dist, dot2, P2.hitDot, (h2.Position - k.hrp.Position).Magnitude), (ok2 or not P2.hitOnly) and "TEMBAK" or "SKIP (ga bakal kena)")
                if P2.hitOnly and not ok2 then
                    P2.why, P2.whyT = ("ayunan diprediksi meleset (d %.1f > %.1f / dot %.2f)"):format(d2, P2.dist, dot2), os.clock()
                    return
                end
                tryFire(reason, k, id)
            end)
        end))
    end
    -- auto-learn: HP survivor mana pun turun -> anim non-loop killer yang MULAI paling awal dalam jendela 0.03-0.6 dtk sebelum hit
    -- (killer <= 16 stud dari korban; yang lolos heuristik swing didahulukan) = anim serang. Ambil yang paling awal, bukan yang terakhir,
    -- soalnya anim recovery / lanjutan main SETELAH ayunan. korban = kita / lolos heuristik -> langsung kepelajar; selain itu nunggu 2 hit.
    local hits, watched = {}, setmetatable({}, {__mode = "k"})
    local function watchHum(hum, mine)
        if watched[hum] then return end
        watched[hum] = true
        local last = hum.Health
        track(hum.HealthChanged:Connect(function(h)
            local drop = h < last - 0.5
            last = h
            if not drop then return end
            local vh = hum.Parent and hum.Parent:FindFirstChild("HumanoidRootPart")
            if not vh then return end
            local now = os.clock()
            local best
            for i = 1, #recent do
                local e = recent[i]
                local dt = now - e.t
                if dt <= 0.6 and dt >= 0.03 and (vh.Position - e.pos).Magnitude <= 16 then
                    if not best or (e.swing and not best.swing) then best = e end
                end
            end
            if mine then
                plog("HIT KITA | HP", ("%.0f/%.0f"):format(hum.Health, hum.MaxHealth), "| anim", best and best.id or "?", "| Parry", tostring(hum.Parent and hum.Parent:GetAttribute("Parry")), "| sejak FIRE", S.parry.firedT and ("%.3fs"):format(now - S.parry.firedT) or "-")
                -- auto-kalibrasi: kena hit padahal prediksi bilang meleset -> lebarin hitReach / hitDot sesuai angka prediksi itu
                local le, Pc = S.parry.lastEval, S.parry
                if le and best and le.id == best.id and now - le.t <= 0.5 then
                    local oldR, oldD = Pc.dist, Pc.hitDot
                    -- cap 14: slider ikut naik (kesimpen di config), cuma bisa naik, jangan sampe satu skill jarak jauh narik semua killer
                    if le.d > Pc.dist then
                        local nv = math.min(le.d * 1.05, 14)
                        local rg = Reg["PAR_Range"]
                        if rg and rg.set then pcall(rg.set, nv) end
                        if Pc.dist < nv - 0.01 then Pc.dist = nv end   -- fallback kalau slider ga ke-set
                    end
                    if le.dot < Pc.hitDot then Pc.hitDot = math.max(le.dot - 0.05, 0.2) end
                    if Pc.dist ~= oldR or Pc.hitDot ~= oldD then
                        plog("KALIBRASI kena hit | range", ("%.1f -> %.1f"):format(oldR, Pc.dist), "| hitDot", ("%.2f -> %.2f"):format(oldD, Pc.hitDot))
                        notify("Auto parry", "kalibrasi otomatis: jangkauan parry disesuaikan")
                    end
                end
                local pd = S.parry.pending   -- kena hit pas parry kita lagi aktif = tembus
                if pd and not pd.done and now - pd.t <= 0.8 then
                    pd.pierced, pd.pid = true, best and best.id
                    resolvePending(pd)
                end
            end
            if best and S.parry.learn and not (learned[best.id] or ATTACK_ANIMS[best.id]) then
                hits[best.id] = (hits[best.id] or 0) + 1
                -- v3.4: 1 hit cuma cukup kalau anim-nya lolos heuristik swing. Selain itu butuh 2 hit, biar anim random (emote / interaksi) ga kepelajar permanen
                if best.swing or hits[best.id] >= 2 then addLearn(best.id, mine and "hit kita" or "hit survivor lain") end
            end
        end))
    end
    local function watchAll()
        for _, pl in ipairs(Players:GetPlayers()) do
            local hum = pl.Character and pl.Character:FindFirstChildOfClass("Humanoid")
            if hum and roleOf(pl) ~= "killer" then watchHum(hum, pl == lp) end
        end
    end
    local function parryTick()
        local P = S.parry
        if not (running and (P.on or P.aggr)) then render("Status: OFF") return end
        local ks = getKillers()
        for _, k in ipairs(ks) do hookKiller(k) end
        watchAll()
        watchParryAttr()
        local ch, hum, hrp = ready()
        if not ch then render("Status: " .. hum) return end
        local ping = 0
        pcall(function() ping = lp:GetNetworkPing() end)
        local nd = math.huge
        for _, k in ipairs(ks) do
            local off = hrp.Position - k.hrp.Position
            local d = off.Magnitude
            if d > 0 then
                nd = math.min(nd, d)
                if P.aggr and d <= P.dist * 1.6 and k.char:GetAttribute("IsChasing") and k.char:GetAttribute("ChaseTargetUserId") == lp.UserId then
                    local u = off.Unit
                    local closing = (k.hrp.AssemblyLinearVelocity - hrp.AssemblyLinearVelocity):Dot(u)
                    if closing > 4 and d / closing <= 0.4 + ping / 2 and targetsUs(k, hrp) and not nearInteract(k, u) then tryFire("predict", k) end
                end
            end
        end
        render(nd < math.huge and ("Status: siap | killer terdekat %.0fm"):format(nd) or "Status: siap | ga ada killer")
    end
    task.spawn(function()
        while running do
            pcall(parryTick)
            task.wait(0.05)
        end
    end)
    -- circle jarak parry di tanah (Part di bawah Camera, ga ke-replicate)
    local circ
    track(RS.RenderStepped:Connect(function()
        pcall(function()
            local ch = lp.Character
            local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
            local hum = ch and ch:FindFirstChildOfClass("Humanoid")
            local cam = workspace.CurrentCamera
            if not (S.parry.circle and hrp and hum and cam) then
                if circ then circ.Parent = nil end
                return
            end
            if not circ then
                circ = Instance.new("Part")
                circ.Name = "JinParryCircle"
                circ.Shape = Enum.PartType.Cylinder
                circ.Anchored, circ.CanCollide, circ.CanQuery, circ.CanTouch, circ.CastShadow = true, false, false, false, false
                circ.Material = Enum.Material.Neon
                circ.Transparency = 0.75
                S.parryCircle = circ
            end
            circ.Color = S.parry.color
            local r = S.parry.dist
            circ.Size = Vector3.new(0.15, r * 2, r * 2)
            circ.CFrame = CFrame.new(hrp.Position - Vector3.new(0, hrp.Size.Y / 2 + hum.HipHeight - 0.05, 0)) * CFrame.Angles(0, 0, math.rad(90))
            -- pas map/ronde baru CurrentCamera diganti, circ ikut ke-Destroy (Parent locked) -> buang & bikin ulang frame berikutnya
            if circ.Parent ~= cam then
                if not pcall(function() circ.Parent = cam end) then circ = nil S.parryCircle = nil end
            end
        end)
    end))
end parryInit() end

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

-- PREDIKSI KILLER: attribute KillerChance (dump jin_objs: ada di data pemain) dianggap bobot undian killer berikutnya.
-- BELUM dites di pemain lain; arti AllowKiller=false (ga mau jadi killer) juga tebakan. Map: dari Remotes.Messages.Mapinfo
do
    local cPred = tMisc:Group("Prediksi killer berikutnya", 2)
    local mlbl = cPred:Label("Map: nunggu pengumuman server...")
    local lbl = cPred:Label("Nunggu data...")
    -- Remotes.Messages.Mapinfo(namaMap, 1) dari scan2: masuk pas lobby (sebelum ronde), jadi dianggap map berikutnya. Argumen ke-2 belum jelas artinya
    task.spawn(function()
        pcall(function()
            local r = game:GetService("ReplicatedStorage"):WaitForChild("Remotes", 15):WaitForChild("Messages", 15):WaitForChild("Mapinfo", 15)
            track(r.OnClientEvent:Connect(function(name) S.mapName = tostring(name) end))
        end)
    end)
    local function attr(pl, k)
        local v = pl:GetAttribute(k)
        if v == nil and pl.Character then v = pl.Character:GetAttribute(k) end
        return v
    end
    S.predUpdate = function()
        if S.mapName then
            local inRound = game:GetService("ReplicatedStorage"):GetAttribute("RoundInProgress")
            mlbl.Text = (inRound and "Map sekarang: " or "Map berikutnya: ") .. S.mapName
        end
        local list = {}
        for _, pl in ipairs(Players:GetPlayers()) do
            local v = attr(pl, "KillerChance")
            if type(v) == "number" then list[#list + 1] = {pl = pl, v = v, off = attr(pl, "AllowKiller") == false} end
        end
        if #list == 0 then lbl.Text = "KillerChance ga kebaca di pemain manapun" return end
        table.sort(list, function(a, b)
            if a.off ~= b.off then return not a.off end
            return a.v > b.v
        end)
        local out = {}
        for i = 1, math.min(#list, 6) do
            local e = list[i]
            out[i] = ("%d. %s  %s%s"):format(i, e.pl.DisplayName, tostring(math.floor(e.v * 10 + 0.5) / 10), e.off and "  (AllowKiller off)" or "")
        end
        lbl.Text = table.concat(out, "\n")
    end
end

local cleanup
local cUI = tSet:Group("Tampilan", 1)
cUI:Dropdown("UI_Size", "Ukuran", {"Kecil", "Sedang", "Besar", "Jumbo"}, "Sedang", function(v) curSize = v applyLayout() end)
cUI:Dropdown("UI_Ratio", "Rasio", {"4:3", "16:10", "16:9", "21:9"}, "16:9", function(v) curRatio = v applyLayout() end)
cUI:Label("4:3 = tinggi, 21:9 = lebar dan gepeng.")
local cMenu = tSet:Group("Menu", 2)
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
        if isOpen and S.predUpdate then pcall(S.predUpdate) end
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
    pcall(function() if S.parryCircle then S.parryCircle:Destroy() end end)
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
warn("[jin] v3.3 loaded")

--[==[
======================================================================
CATATAN BUAT AI / DEV BERIKUTNYA (baca ini dulu sebelum edit)
======================================================================
PROYEK : Jin Script, ESP + auto skill check buat Roblox "Violence District" (mirip Dead by Daylight)
RUN DI : Delta executor (HP) / PC, Luau. Menu: RightShift (PC) / tap logo (HP). F6 = skill check on/off
SIFAT  : script satu file (~2000 baris), UI bikin sendiri (ga pake lib). Config JSON di workspace/jin_hub/

PETA FILE (urutan, cari banner "-----" + judulnya)
  config atas -> state S + CATS -> ESP role -> ESP objek (MATCH/found/classify) -> status survivor
  -> ESP update() -> area liat killer (cone) -> skill check -> fullbright/anti lag -> UI helper
  -> config save/load -> window (do-block) -> Tab/Card -> Dashboard (do-block) -> tab ESP/SC/Misc/Settings
  -> loop + cleanup

ATURAN KERAS
  1. LIMIT 200 LOCAL per chunk. Kalau kelewat, loadstring balikin nil dan loader error
     "attempt to call a nil value" di Line 1. Saat ini ~175 di main chunk. Bagian window dan Dashboard
     sudah dibungkus do ... end (variabel yang dipake di luar di-predeclare). Fitur baru: bungkus pakai
     do-block atau taruh di table, JANGAN nambah local top-level sembarangan.
  2. Sandbox AI ga punya Lua/Luau, jadi hasil edit belum pernah dijalanin. Cek pakai pasangan do/end/kurung
     + hitung local, dan bilang jujur "belum dites di game".
  3. Edit kecil (str_replace / patch per baris). Jangan tulis ulang file. Selalu kerja dari file TERBARU,
     bukan dari upload lama, dan jangan timpa file output tanpa baca isinya dulu.
  4. Semua fitur ada toggle di menu, ga ada yang jalan otomatis tanpa toggle.
  5. Riset / tes / nyari nama remote, attribute, animasi = script TERPISAH (jin_scan.lua), BUKAN di script utama
     (boros token dan nambah local). Script utama cuma fitur final.

SUDAH JADI
  - ESP pemain: highlight, nama, jarak. Status: sehat / kena hit / jatuh / digantung / killer.
  - Hooked vs jatuh: dianggap "digantung" cuma kalau dalam S.hookNear (10 stud) dari model Hook,
    kalau jauh = jatuh (merangkak). Kalau model Hook ga ketemu, status dari game dipercaya.
  - Tanda chase !/!!/!!! (ijo/kuning/merah makin dekat killer), muncul di atas karakter KITA sendiri.
  - Area liat killer (cone merah di tanah): arah dihaluskan, raycast cuma ke lantai, wedge rusak disembunyiin.
  - ESP objek: generator, pallet, window, hook, pumpkin.
  - Generator: warna lerp dari warna asli ke ijo sesuai progress, label + "%", ESP ilang kalau beres.
  - ESP mati total kalau lagi spectator atau lobby (ga ada Generator di workspace). Toggle: "ESP mati pas spectator / lobby".
  - Auto skill check (mode Instant / Perfect / Great / Random), fullbright, FOV, anti lag, dashboard.

  - UI: tab ESP dipecah sub-tab (Player / World / Tampilan / Area Killer) lewat Tab:Sub(). Fitur survivor/killer nanti pake pola sama.
    Hide spectator, gen progress, gen beres, pallet jatuh = selalu ON (S default true), tombolnya dihapus.

SUDAH DIVERIFIKASI DI GAME (dikonfirmasi user)
  - Progress generator = attribute RepairProgress (0..100) di model Generator, selesai = attribute Completed (bool).
    Attribute lain yang ada: IsRepairing (di GeneratorPointN), PlayersRepairingCount, ProgressPaused.
  - Deteksi spectator (Team / attribute lewat SPEC_WORDS) jalan.
  - Heuristik lobby = "ga ada model Generator". Kalau di mode lain game ga ada generator, matiin toggle itu.

LAGI DIKERJAIN (belum diverifikasi di game)
  - Pallet jatuh = ESP ilang: dump jin_objs.txt nunjukin pallet ga punya bool attribute, cuma child Intact / Broken / hitbox.
    palletDown() sekarang fallback struktur: Intact ilang, atau semua part Intact transparan = jatuh/patah. Cuma ada sampel
    pallet UTUH di dump, jadi belum tau apa yang berubah pas jatuh. Kalau ga jalan: dump Intact/Broken/hitbox (Transparency,
    CanCollide, Parent) sebelum dan sesudah pallet dijatuhin.
  - ESP Exit Gate: MATCH.gate sekarang ngenain Model "ExitLever" (Workspace.Map.Gate.ExitLever) + Model bernama gate.
    LeftGate = MeshPart dan Map.gate = Part, ga ke-match (Model only). Status kebuka belum ada datanya. Default OFF.
  - PREDIKSI KILLER (tab Misc): baca KillerChance semua pemain, urut terbesar. Belum dites di pemain lain.
    Dari scan2: KillerChance punya user 30 -> 31 pas ronde jalan (naik tiap ronde ga jadi killer, cocok sama undian berbobot).
  - PREDIKSI MAP (tab Misc): dengerin Remotes.Messages.Mapinfo(nama, 1). Di scan2 masuk sebelum RoundInProgress=true (re4 masuk ~17 dtk sebelum ronde),
    jadi dianggap map berikutnya; pas RoundInProgress=true ditulis "Map sekarang". Event pertama pas join bisa jadi map lama. Arg ke-2 ("1") artinya belum jelas.
  - AUTO PARRY (tab Skill Check, default OFF). Bug user v2: (1) FireServer ga bikin parry beneran tapi script nganggep udah, (2) masuk jarak doang dianggap ayun.
    v3: tiap tembakan diverifikasi (Char.Parry nyala <= 0.3 dtk) dengan 3 metode berurutan (remote / StopEmote+remote / tool:Activate), hasilnya di baris Status.
    Normal = reaktif lewat ATTACK_ANIMS (Slasher: 135002183282873, 121216847022485); killer lain: isi ID dari baris "anim killer" di Status. Aggressive = prediktif, wajib IsChasing kita.
    CATATAN: relTo() di jin_scan2.lua facing-nya kebalik (negatif = ngadep ke kita). Di script utama udah bener.
    Belum tau parry nahan hit atau cuma stun killer; belum ada log parry yang kena killer.
    FIX: (1) parry cuma jalan di Slasher -> sekarang auto-learn anim serang dari hit (HP turun) + heuristik anim non-loop/Action (toggle "Deteksi anim serang"),
    Animator dicari rekursif. Heuristik bisa salah tembak (dagger sekali pake) -> matiin toggle kalau boros. (2) lingkaran parry ilang pas map baru:
    circ nempel di Camera, Camera diganti -> circ ke-destroy, sekarang dibikin ulang. BELUM dites di game.
    v3.1: auto-learn sekarang dari hit SEMUA survivor (bukan cuma kita) + disimpen ke jin_parry.json (kebawa antar sesi). Cooldown dagger ga ada datanya ->
    diukur sendiri (tembakan gagal = cooldown, interval naik 0.25 dtk, ga spam metode); Status nampilin attribute bernama "cool" kalau ada di karakter/tool.
    Cek arah cuma ke arah killer (<= 90 derajat), arah kita ga dicek. BELUM dites di game.
    v3.2: (1) killer ngerjain gen/pallet/window ga dihitung nyerang (killer ngadep objek lebih lurus dari ngadep kita). (2) Status "skip: ..." ngasih tau
    kenapa ga nembak. (3) learn ambil anim yang mulai PALING AWAL sebelum hit (bukan yang terakhir: anim recovery bisa ke-ambil). (4) skill ga bisa di-parry:
    tiap parry dicek tembus/ketahan; tembus dari depan >= 2x dan lebih banyak dari ketahan -> masuk nopar (di-skip), disimpen di jin_parry.json.
    v3.3: tembakan sekarang NGE-PRESS beneran dulu (Tool:Activate -> tombol GUI kerekam -> key kerekam), baru remote (metode 1 = press, 2 = remote,
    3 = StopEmote+remote). Tombol/key direkam dari parry MANUAL kamu (Status: "parry MANUAL kerekam: ..."), jadi parry manual sekali dulu tiap ganti device. BELUM dites.
    (5) toggle "Hadap killer pas parry" buat tes kalau parry cuma kena dari depan; Status nulis killer ada di depan / samping-belakang pas nembak. BELUM dites.
    v3.4: auto parry dirapihin biar ga ngawur. (1) TARGET GATE targetsUs(): killer harus ngebidik kita (CamLook, dot >= 0.55) dan ga ada survivor lain
    yang lebih lurus di garis bidik (selisih >= 0.15, dan lebih deket/sama) -> skip, Status "skip: killer ngincer <nama>". Berlaku di mode Normal dan Aggressive.
    (2) "Tebak anim serang" (detect) default OFF: heuristik ini nembak ke anim non-loop apa aja (interaksi, emote). Nyalain cuma buat killer baru yang belum kepelajar.
    (3) auto-learn 1 hit cuma cukup kalau anim lolos heuristik swing, selain itu 2 hit (sebelumnya "hit kita" langsung belajar -> anim random bisa kepelajar permanen).
    (4) bug: cap jarak 14 stud ngabaikan slider Parry Distance > 10.8m, sekarang max(14, dist*1.3). (5) Aggressive juga skip kalau killer lagi ngerjain gen/pallet/window.
    Kalau jin_parry.json lama udah keracunan anim salah: hapus id-nya dari "anims" (atau hapus file-nya). BELUM dites di game.
    v3.5: logger diagnosa -> workspace/jin_hub/jin_parry_log.txt (200 baris terakhir): FIRE (jeda sejak anim mulai, ping, semua attribute karakter),
    tiap step metode (pcall ok?, Parry nyala?, EquippedItem, dagger di char/backpack), SKIP (alasan), HIT KITA (Parry aktif ga, berapa lama setelah FIRE).
    Buat nyari kenapa "notif muncul tapi dagger ga kepake" (lagi lari / telat / ga ke-press).
    v3.6 (dari log jin_parry_log.txt): (1) PENYEBAB UTAMA TELAT: step 1 (press) ga ngapa-ngapain kalau tombol/key belum kerekam, tapi nunggu 0.3 dtk dulu, baru remote (step 2)
    nembak ~0.5 dtk setelah anim mulai, padahal hit dateng 0.2 dtk. Step 2 (remote doang) KEBUKTI bikin Char.Parry nyala (~0.13 dtk). Sekarang remote duluan (method=2),
    press cuma dicoba kalau ada tombol/key kerekam -> ga perlu parry manual lagi. (2) jarak: killer lunge (mulai ayun dari 9m, tetep kena) -> reach = dist*1.3 + kecepatan
    killer ke arah kita x 0.25 dtk. (3) detect ON lagi tapi anim yang belum dikenal cuma ditembak kalau killer ngejar KITA (IsChasing + ChaseTargetUserId) atau udah <= dist.
    (4) event anim sama < 0.1 dtk di-dedupe (log: burst 76 event), log ditulis ke file tiap 1 dtk (debounce). BELUM dites di game.
    v3.7: parry cuma nembak kalau ayunan diprediksi KENA (user: killer ayun tapi meleset di dalam zona, parry kebuang). Slider "Parry Distance" sekarang cuma
    gerbang kandidat; keputusan akhir di willHit(): EVAL_DELAY 0.04 dtk setelah anim mulai, posisi killer + kita diekstrapolasi (kecepatan x sisa waktu ke hit, HIT_T 0.2 dtk
    dari log), tembak kalau jarak prediksi <= hitReach (default 6m, slider) dan dot bidik >= hitDot (0.55). Auto-kalibrasi: kena hit yang tadinya diprediksi meleset ->
    hitReach / hitDot dilebarin ke angka prediksi itu (hitReach max 14). Toggle "Parry cuma kalau ayunan bakal KENA" buat balik ke perilaku lama. Log: baris EVAL (angka prediksi +
    keputusan) dan KALIBRASI. Nilai hasil kalibrasi ga disimpen antar sesi. BELUM dites di game; default 6m itu tebakan, cek baris EVAL vs HIT KITA buat nyetel.
    v3.8 (dari jin_recon.txt, Delta): parry sekarang MANGGIL HANDLER ASLI tombol HP: Survivor-mob.Controls.Gui-mob.MouseButton1Down -> function dari module
    ReplicatedStorage.Modules.Items.ParryingDagger.ParryClient (getconnections, filter script.Name == "ParryClient"). Remote yang ditembak handler itu =
    ReplicatedStorage.Remotes.Items["Parrying Dagger"].parry:FireServer(karakter), argumen SAMA kayak metode remote lama; bedanya remote-doang ngelewatin
    animasi / berhenti / gate client. Di recon: ~20 pencetan tombol -> cuma 1 remote, jadi client ngegate (recharge; ada module ItemRechargeClock) dan
    metode remote-spam lama nembus gate itu. Metode remote cuma dipake kalau handler ga ketemu. Hasil handler ga diverifikasi lewat attr Parry (di recon attr Parry
    GA nyala sama sekali, ANIM useanim 81793464499285 juga ga kerekam) -> cek baris "+0.3s setelah handler" di log. BELUM dites di game.
    Info dagger: Model (bukan Tool) di karakter; attr useanim=81793464499285, parriedanim=72219761917132; LocalScript "parrying dagger" + "animation".
    v3.9 (dari jin_parry_src.txt + log): ParryClient.Parry() = FireServer(char) -> puter badan -> anim -> slow(0) (berhenti) -> nunggu anim / ParryLands naik ->
    bebas. CanUse() = equipped, ga silenced, ga cooldown, ga resolving (nunggu parryResult dari server), ga busy (vault/pallet/repair/heal/unhook/dibawa/digantung/
    tag "doing action"), HP >= 50%. Jadi: (1) instance ParryClient di-cache dari upvalue closure Gui-mob (getconnections tiap tembakan = lambat, sempat 0.25 dtk),
    (2) ready() pake CanUse() sbg sumber kebenaran cooldown (cdLo tebakan cuma fallback), (3) Parry() dipanggil langsung di task.spawn, (4) EVAL_DELAY 0 / HIT_T 0.12 karena
    anim killer bisa kelihatan cuma 0.02 dtk sebelum hit, (5) baris PARRYRESULT di log = jawaban server (success, cooldown, permanent, chain, char).
    Aggressive mode (FIRE predict) nembak tanpa ayunan -> matiin kalau mau parry cuma pas kena. BELUM dites di game.
    v3.10 (dari log v3.9): (1) log NOFIRE: tiap EVAL "TEMBAK" yang ditolak ready() sekarang dicatat + rincian CanUse() (equipped / silenced / cooldown / resolving /
    busy / lowHP / HP). Sebelumnya ketelen diem-diem, makanya "anim ketangkep tapi dagger ga jalan" ga ketahuan sebabnya. (2) HIT KITA nyatet HP/MaxHP (cek dugaan:
    CanUse() nolak kalau HP < 50% = injured). (3) hitReach default 6 -> 8 (log: hit kena di jarak prediksi 7.2, kalibrasi manual 7.6). Catatan dari log: PARRYRESULT false|60 =
    parry meleset kena cooldown 60 dtk; PARRYRESULT false|0 = server nolak tanpa cooldown. Dua-duanya muncul TANPA baris FIRE (bukan dari script).
    v3.12 (di atas v3.10): Parry Distance + Hit reach digabung jadi satu slider "Jangkauan parry" (config id baru PAR_Range, default 9, maks 16). willHit() pake nilai itu,
    gerbang kandidat otomatis = range*1.5 + lunge*0.25, lingkaran = range. Kalibrasi (kena hit padahal prediksi meleset) nambah slider-nya sendiri (maks 14, kesimpen).
    Mode Hemat/Sensitif dibuang; toggle v3.10 (Aggressive, Deteksi, Auto-learn, Hadap, Hit-only, Circle) balik. ATTACK_ANIMS sekarang 12 id. PARRY_DEBUG = true (false pas publish).
    Log baru: KATTR (attribute killer berubah <= 30m, CamLook di-skip, angka dibatasi 0.25 dtk) + KANIM (id/priority/panjang/loop/jarak, 0.5 dtk per id). Buffer log 600 baris.
    BELUM dites di game.
  - PERFECT VAULT: BELUM ditulis. jin_remotes.txt ga ada satupun event vault (isinya cuma UpdateCharacterLook, PushRemote,
    GetPing, EmoteHandler, parry, anim idle/run/walk). Yang ada di dump: remote Window.VaultEvent / fastvault / VaultCommit /
    VaultReject / VaultCompleteEvent (argumen ga diketahui) dan attribute karakter isvaulting, VaultTier (medium), VaultReason (pace),
    vaultspeed, VaultSfxToken, __VaultFireCount. Tier kayaknya ditentuin server dari "pace" (jalan/lari). Butuh log remote
    pas vault di window: sekali jalan, sekali lari, plus attribute berubah di karakter. Jangan nembak remote tanpa argumen asli.

DIHAPUS (jangan dibalikin kalau ga perlu)
  - Tombol Scan lama (dumpData / dumpPlayers / dumpGens) dan picker warna "Chased (!)". Udah ga kepake.
    Riset / nyari nama / remote sekarang di script terpisah: jin_scan.lua.

IDE LANJUTAN (belum dikerjain)
  - Config simpen S.hookNear / S.chaseCol kalau mau bisa diatur dari menu.
======================================================================
]==]
