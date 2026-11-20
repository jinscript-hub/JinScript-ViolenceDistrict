local ICON_ID     = ""
local ICON_URL    = ""
local ICON_FILE   = "jin_icon.png"
local SHEET_ID    = ""
local SHEET_FILE  = "jin_icons.png"
local SOCIAL_ID   = ""
local SOCIAL_FILE = "jin_social.png"
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
local FOLDER = "jin_hub"
local BASE = ""
pcall(function()
    if makefolder and isfolder then
        if not isfolder(FOLDER) then makefolder(FOLDER) end
        if isfolder(FOLDER) then BASE = FOLDER .. "/" end
    end
end)
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
    chaseCol = {Color3.fromRGB(0, 255, 80), Color3.fromRGB(255, 235, 0), Color3.fromRGB(255, 40, 40)},
    cone = {on = true, range = 70, angle = 100, color = Color3.fromRGB(255, 60, 60), transp = 0.75, line = true, lineLen = 30, lineColor = Color3.fromRGB(255, 255, 255), body = false, bodyColor = Color3.fromRGB(60, 255, 90)},
    sc = {enabled = true, mode = "Perfect"},
    fov = {on = false, val = 70},
    fb = {on = false, bright = 2},
    al = {particles = false, post = false, shadows = false, quality = false, sky = false, tex = false, white = false, grass = false, trees = false, lights = false, perf = false},
    ar = {on = false, ratio = 0.75},
}
local roleOf, isSpectator, found, classify, getKillers, survivorState, espFolder, pvis, ovis, selfBB, destroyPlayerVis, destroyObj, update, coneFolder, updateCone, scUnbind, scBind, fbSave, fbApply, fbRestore, shadowsSave, shadowsRestore
do
for _, c in ipairs(CATS) do
    S.cat[c.key] = {on = c.on, color = Color3.fromRGB(c.color[1], c.color[2], c.color[3])}
end
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
function roleOf(plr)
    if plr.Team then
        local t = plr.Team.Name:lower()
        if t:find("killer") or t:find("slasher") then return "killer" end
        if t:find("survivor") then return "survivor" end
    end
    return attrRole(plr) or attrRole(plr.Character) or "survivor"
end
local SPEC_WORDS = {"spectat", "lobby", "waiting", "queue", "intermission", "dead", "eliminat"}
local function specWord(str)
    str = str:lower()
    for _, w in ipairs(SPEC_WORDS) do
        if str:find(w, 1, true) then return true end
    end
    return false
end
function isSpectator(plr)
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
local MATCH = {
    generator = function(i) return i:IsA("Model") and i.Name:lower() == "generator" end,
    window    = function(i) return i:IsA("PVInstance") and i.Name:lower() == "window" end,
    hook      = function(i) return i:IsA("Model") and i.Name:lower() == "hook" end,
    pallet    = function(i)
        if not i:IsA("Model") then return false end
        local n = i.Name:lower()
        return n ~= "pallets" and n:find("pallet") ~= nil and n:find("point") == nil and n:find("slide") == nil
    end,
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
found = {}
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
function classify(i)
    local n = i.Name:lower()
    if not (n:find("generator") or n:find("window") or n:find("pallet") or n:find("hook") or n:find("pumpkin") or n:find("labu") or n:find("gate") or n:find("exit") or n:find("escape")) then return end
    for cat, f in pairs(MATCH) do
        if f(i) and topmost(cat, i) and not inCharacter(i) then found[cat][i] = true return end
    end
end
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
function getKillers()
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
    return false, have
end
function survivorState(plr, char, hum, hrp, killers)
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
    local key = "survivor"
    if st.hooked then key = "hooked"
    elseif st.knocked then key = "knocked"
    elseif hum.Health < hum.MaxHealth - 0.5 then key = "injured" end
    return key, st.chased and true or false
end
espFolder = Instance.new("Folder")
espFolder.Name = "JinESP"
attach(espFolder)
pvis, ovis, selfBB = {}, {}, {}
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
function destroyPlayerVis(plr)
    local v = pvis[plr]
    if v then pcall(function() v.hl:Destroy() v.nameBB:Destroy() v.distBB:Destroy() end) pvis[plr] = nil end
end
function destroyObj(inst)
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
    local box = Instance.new("Highlight")
    box.Adornee = inst
    box.FillTransparency = 0.6
    box.OutlineTransparency = 0
    box.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
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
    local c = {at = os.clock()}
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
            if v > 1 or name:lower():find("percent", 1, true) then v = v / 100 end
            prog = math.clamp(v, 0, 1)
            if prog >= 0.995 then done = true end
        end
    end
    return prog, done
end
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
function update()
    local lc = lp.Character
    local lhrp = lc and lc:FindFirstChild("HumanoidRootPart")
    local maxD = S.maxDist > 0 and S.maxDist or math.huge
    local ts = S.textSize
    local killers = getKillers()
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
    local plCount = 0
    for _ in pairs(pvis) do plCount = plCount + 1 end
    local hlBudget = math.max(0, 30 - plCount)
    local cand = {}
    for cat, set in pairs(found) do
        local enabled = S.cat[cat].on
        for inst in pairs(set) do
            if not inst:IsDescendantOf(workspace) then
                set[inst] = nil
                destroyObj(inst)
            elseif enabled and ((cat == "generator" and S.genHideDone and select(2, genProgress(inst))) or (cat == "pallet" and S.palHideDown and palletDown(inst))) then
                destroyObj(inst)
            elseif enabled then
                local o = ovis[inst] or createObj(cat, inst)
                local prog = (cat == "generator" and S.genProgCol) and genProgress(inst) or nil
                local dist = lhrp and (inst:GetPivot().Position - lhrp.Position).Magnitude
                if (not dist) or dist <= maxD then
                    local c = S.cat[cat].color
                    if prog then c = c:Lerp(S.genDoneCol, prog) end
                    o.box.FillColor, o.box.OutlineColor = c, c
                    cand[#cand + 1] = {o = o, d = dist or 0}
                    if o.nameBB then
                        setLabel(o.nameBB, o.nameLbl, S.names and (CAT[cat].label .. (prog and (" " .. math.floor(prog * 100 + 0.5) .. "%") or "")) or "", c, ts)
                        setLabel(o.distBB, o.distLbl, (S.dist and dist) and ("%dm"):format(math.floor(dist)) or "", c, ts)
                    end
                else
                    o.box.Enabled = false
                    if o.nameBB then o.nameBB.Enabled = false o.distBB.Enabled = false end
                end
            else
                destroyObj(inst)
            end
        end
    end
    table.sort(cand, function(a, b) return a.d < b.d end)
    for idx, e in ipairs(cand) do e.o.box.Enabled = idx <= hlBudget end
end
local CONE_N = 12
coneFolder = Instance.new("Folder")
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
local function mkLine(col)
    local l = Instance.new("Part")
    l.Anchored, l.CanCollide, l.CanQuery, l.CanTouch, l.CastShadow = true, false, false, false, false
    l.Material = Enum.Material.Neon
    l.Transparency = 0.15
    l.Color = col
    l.Size = Vector3.new(0.14, 0.14, 1)
    l.Parent = coneFolder
    return l
end
local coneLineA, coneLineB = mkLine(Color3.fromRGB(255, 255, 255)), mkLine(Color3.fromRGB(60, 255, 90))
local function placeLine(l, origin, dir, len)
    if dir.Magnitude < 0.01 then l.Transparency = 1 return end
    dir = dir.Unit
    l.Transparency = 0.15
    l.Size = Vector3.new(0.14, 0.14, len)
    l.CFrame = CFrame.lookAt(origin + dir * (len / 2), origin + dir * len)
end
local coneRP = RaycastParams.new()
coneRP.FilterType = Enum.RaycastFilterType.Exclude
coneRP.RespectCanCollide = true
local function tri3(a, b, c, w1, w2)
    local ab, ac, bc = b - a, c - a, c - b
    local abd, acd, bcd = ab:Dot(ab), ac:Dot(ac), bc:Dot(bc)
    if abd > acd and abd > bcd then c, a = a, c
    elseif acd > bcd and acd > abd then a, b = b, a end
    ab, ac, bc = b - a, c - a, c - b
    if ac:Cross(ab).Magnitude < 1e-3 then w1.Transparency, w2.Transparency = 1, 1 return end
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
    local r = workspace:Raycast(Vector3.new(p.X, fy + 4, p.Z), Vector3.new(0, -14, 0), coneRP)
    if r and r.Normal.Y > 0.6 then return r.Position + Vector3.new(0, 0.12, 0) end
    return Vector3.new(p.X, fy + 0.12, p.Z)
end
local coneC = {t = 0, ks = {}, selfK = false}
function updateCone()
    if S.lobby or not (S.cone.on or S.cone.line or S.cone.body) then coneFolder.Parent = nil return end
    local now = os.clock()
    if now - coneC.t > 0.15 then
        coneC.t = now
        coneC.selfK = roleOf(lp) == "killer"
        coneC.ks = getKillers()
        local ex = {coneFolder}
        for _, p in ipairs(Players:GetPlayers()) do if p.Character then ex[#ex + 1] = p.Character end end
        coneRP.FilterDescendantsInstances = ex
    end
    local k = coneC.ks[1]
    if coneC.selfK or not (k and k.hrp.Parent) then coneFolder.Parent = nil return end
    local cl = k.char:GetAttribute("CamLook")
    local look = (typeof(cl) == "Vector3") and cl or k.hrp.CFrame.LookVector
    look = Vector3.new(look.X, 0, look.Z)
    if look.Magnitude < 0.01 then
        local lv = k.hrp.CFrame.LookVector
        look = Vector3.new(lv.X, 0, lv.Z)
    end
    look = look.Unit
    local prev = S.cone.look
    if prev then
        local mix = prev:Lerp(look, 0.4)
        if mix.Magnitude > 0.05 then look = mix.Unit end
    end
    S.cone.look = look
    local o = groundAt(k.hrp.Position, k.hrp.Position.Y - 3)
    local half = math.rad(S.cone.angle / 2)
    if S.cone.on then
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
    else
        for i = 1, CONE_N * 2 do coneW[i].Transparency = 1 end
    end
    local head = k.char:FindFirstChild("Head")
    local ho = head and head.Position or (k.hrp.Position + Vector3.new(0, 1.5, 0))
    if S.cone.line then
        coneLineA.Color = S.cone.lineColor
        placeLine(coneLineA, ho, look, S.cone.lineLen)
    else
        coneLineA.Transparency = 1
    end
    if S.cone.body then
        local lv = k.hrp.CFrame.LookVector
        coneLineB.Color = S.cone.bodyColor
        placeLine(coneLineB, ho - Vector3.new(0, 0.3, 0), Vector3.new(lv.X, 0, lv.Z), S.cone.lineLen)
    else
        coneLineB.Transparency = 1
    end
    coneFolder.Parent = workspace
end
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
                pcall(press)
            end
        end
        task.wait(0.12)
        scBusy = false
        if running and S.sc.enabled and C.Visible and G.Rotation ~= handled then arm() end
    end)
end
function scUnbind()
    for _, c in ipairs(scBound) do pcall(function() c:Disconnect() end) end
    scBound = {}
end
function scBind()
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
local fbOrig
function fbSave()
    if fbOrig then return end
    local atm = Lighting:FindFirstChildOfClass("Atmosphere")
    fbOrig = {
        Brightness = Lighting.Brightness, ClockTime = Lighting.ClockTime, FogEnd = Lighting.FogEnd,
        FogStart = Lighting.FogStart, GlobalShadows = Lighting.GlobalShadows, Ambient = Lighting.Ambient,
        OutdoorAmbient = Lighting.OutdoorAmbient, atm = atm, Density = atm and atm.Density, Haze = atm and atm.Haze,
    }
end
function fbApply()
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
function fbRestore()
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
function shadowsSave()
    if shadowOrig ~= nil then return end
    if fbOrig then shadowOrig = fbOrig.GlobalShadows else shadowOrig = Lighting.GlobalShadows end
end
function shadowsRestore()
    if shadowOrig ~= nil then
        if not S.fb.on then Lighting.GlobalShadows = shadowOrig end
        shadowOrig = nil
    end
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
local postSweep, postRestore, setQuality, Reg, CFG_FILE, loading, dirty, loadConfig, gui, HEAD, PADL, PADR, curSize, curRatio, isOpen, setOpen, applyLayout, tabHolder, content, selectTab, tHome, tKill, tMisc, tSet, curFps, refreshDash
do
local POST = {BloomEffect = 1, BlurEffect = 1, ColorCorrectionEffect = 1, DepthOfFieldEffect = 1, SunRaysEffect = 1}
local postOff = {}
function postSweep()
    for _, root in ipairs({Lighting, workspace.CurrentCamera}) do
        if root then
            for _, e in ipairs(root:GetChildren()) do
                if POST[e.ClassName] and e.Enabled then postOff[e] = true; e.Enabled = false end
            end
        end
    end
end
function postRestore()
    for e in pairs(postOff) do if e.Parent then pcall(function() e.Enabled = true end) end end
    postOff = {}
end
local origQuality
function setQuality(low)
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
local function tw(o, t, p, style, dir)
    TS:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), p):Play()
end
local fadeIn
do
local origT = setmetatable({}, {__mode = "k"})
fadeIn = function(root, dur)
    local list = {root}
    for _, d in ipairs(root:GetDescendants()) do list[#list + 1] = d end
    for _, o in ipairs(list) do
        local props
        if o:IsA("GuiObject") then
            props = {"BackgroundTransparency"}
            if o:IsA("TextLabel") or o:IsA("TextButton") then props[#props + 1] = "TextTransparency" end
            if o:IsA("ImageLabel") or o:IsA("ImageButton") then props[#props + 1] = "ImageTransparency" end
        elseif o:IsA("UIStroke") then
            props = {"Transparency"}
        end
        if props then
            local rec = origT[o]
            if not rec then
                rec = {}
                for _, k in ipairs(props) do rec[k] = o[k] end
                origT[o] = rec
            end
            local goal = {}
            for _, k in ipairs(props) do
                if rec[k] < 1 then o[k] = 1 goal[k] = rec[k] end
            end
            if next(goal) then tw(o, dur or 0.16, goal) end
        end
    end
end
end
local function hover(btn, normal, over)
    track(btn.MouseEnter:Connect(function() tw(btn, 0.12, {BackgroundColor3 = over}) end))
    track(btn.MouseLeave:Connect(function() tw(btn, 0.15, {BackgroundColor3 = normal}) end))
end
local function esc(s) return (tostring(s):gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")) end
local function headshot(uid) return "rbxthumb://type=AvatarHeadShot&id=" .. uid .. "&w=150&h=150" end
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
local SHEET = assetOf(SHEET_ID, SHEET_FILE)
local CELL = 64
local SHEET_MAP = {home = {0, 0}, eye = {1, 0}, target = {2, 0}, sliders = {3, 0},
    gear = {0, 1}, xmark = {1, 1}, down = {2, 1}, user = {3, 1}, blade = {0, 2}}
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
    elseif name == "user" then
        shape(8, 4.8, 5.5, 5.5, 0, true)
        shape(8, 12.2, 11, 5.5, 0, true)
    elseif name == "blade" then
        shape(10, 6, 2.2, 9, 45)
        shape(6.8, 9.2, 7, 2, 45)
        shape(4.6, 11.4, 2.2, 4, 45)
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
Reg = {}
CFG_FILE = "jin_config.json"
loading, dirty = true, false
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
function loadConfig()
    local p = findFile(CFG_FILE)
    if not (p and readfile) then return end
    local ok, data = pcall(function() return HttpService:JSONDecode(readfile(p)) end)
    if ok and type(data) == "table" then
        for id, v in pairs(data) do
            if Reg[id] then pcall(Reg[id].set, v) end
        end
    end
end
do
gui = Instance.new("ScreenGui")
gui.Name = "JinScript"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 1000
attach(gui)
local ICON = loadLogo()
local cam = workspace.CurrentCamera
local vp = cam and cam.ViewportSize or Vector2.new(844, 390)
local SB = 46
HEAD = 38
PADL, PADR = 12, 14
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
        uiScale.Scale = layoutScale() * 0.9
        tw(uiScale, 0.28, {Scale = layoutScale()}, Enum.EasingStyle.Back)
    else
        tw(uiScale, 0.12, {Scale = layoutScale() * 0.94})
        task.delay(0.12, function() if not isOpen and main then main.Visible = false end end)
    end
end
function applyLayout()
    local r = RATIOS[curRatio]
    local info = TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    TS:Create(main, info, {Size = UDim2.fromOffset(r[1], r[2])}):Play()
    TS:Create(uiScale, info, {Scale = isOpen and layoutScale() or layoutScale() * 0.94}):Play()
end
pcall(function()
    track(workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(applyLayout))
end)
local side = new("Frame", {Size = UDim2.new(0, SB, 1, 0), BackgroundColor3 = WHITE, BorderSizePixel = 0}, main)
round(side, 10)
grad(side, T.side0, T.side1, 90)
local sideCover = new("Frame", {Size = UDim2.new(0, 10, 1, 0), Position = UDim2.new(1, -10, 0, 0), BackgroundColor3 = WHITE, BorderSizePixel = 0}, side)
grad(sideCover, T.side0, T.side1, 90)
new("Frame", {Size = UDim2.new(0, 1, 1, 0), Position = UDim2.new(0, SB, 0, 0), BackgroundColor3 = T.stroke, BorderSizePixel = 0}, main)
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
content = new("Frame", {Size = UDim2.new(1, -SB - 1, 1, 0), Position = UDim2.new(0, SB + 1, 0, 0), BackgroundTransparency = 1}, main)
local header = new("Frame", {Size = UDim2.new(1, 0, 0, HEAD), BackgroundTransparency = 1, Active = true}, content)
new("Frame", {Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, -1), BackgroundColor3 = T.stroke, BorderSizePixel = 0}, header)
local ttl = mkLabel(header, "JÌN SCRIPT", 12, T.text, F_BOLD)
ttl.Position = UDim2.fromOffset(14, 0); ttl.Size = UDim2.fromOffset(78, HEAD - 1)
local ver = mkLabel(header, "v3.9", 10, T.dim)
ver.Position = UDim2.fromOffset(92, 1); ver.Size = UDim2.fromOffset(30, HEAD - 1)
local closeBtn = new("TextButton", {Size = UDim2.fromOffset(24, 24), AnchorPoint = Vector2.new(1, 0.5),
    Position = UDim2.new(1, -8, 0.5, -1), BackgroundTransparency = 1, Text = "", AutoButtonColor = false}, header)
local closeIc = mkIcon(closeBtn, "xmark", T.dim, 12)
closeIc.box.Position = UDim2.new(0.5, 0, 0.5, 0)
track(closeBtn.MouseEnter:Connect(function() closeIc:Tween(T.text, 0.12) end))
track(closeBtn.MouseLeave:Connect(function() closeIc:Tween(T.dim, 0.15) end))
track(closeBtn.MouseButton1Click:Connect(function() setOpen(false) end))
draggable(header, main)
local SOCIAL = assetOf(SOCIAL_ID, SOCIAL_FILE)
local SOC_ORDER = {"YouTube", "TikTok", "WhatsApp", "Discord"}
local SOC_RECT = {
    YouTube = {6, 0, 138, 108}, TikTok = {160, 0, 102, 108},
    WhatsApp = {272, 0, 102, 108}, Discord = {374, 0, 138, 108},
}
local SOC_TXT = {YouTube = "YT", TikTok = "TT", WhatsApp = "WA", Discord = "DC"}
local SOC_W, SOC_H, SOC_STEP = 26, 20, 31
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
end
do
local notifs = {}
local function layoutNotifs()
    for i, n in ipairs(notifs) do
        tw(n, 0.3, {Position = UDim2.new(0.5, 0, 0, 16 + (i - 1) * 48)}, Enum.EasingStyle.Quint)
    end
end
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
    notifs[#notifs + 1] = f
    layoutNotifs()
    task.delay(2.3, function()
        local idx = table.find(notifs, f)
        if idx then table.remove(notifs, idx) end
        if f.Parent then tw(f, 0.25, {Position = UDim2.new(0.5, 0, 0, -56)}, Enum.EasingStyle.Quint, Enum.EasingDirection.In) end
        layoutNotifs()
        task.wait(0.3)
        pcall(function() f:Destroy() end)
    end)
end
end
local Tab, Card = {}, {}
Tab.__index = Tab
Card.__index = Card
local tabList = {}
function selectTab(t)
    for _, o in ipairs(tabList) do
        local sel = (o == t)
        o.sel = sel
        if sel and not o.page.Visible then
            o.page.Position = UDim2.fromOffset(0, HEAD + 10)
            o.page.Visible = true
            tw(o.page, 0.3, {Position = UDim2.fromOffset(0, HEAD)}, Enum.EasingStyle.Quint)
        elseif not sel then
            o.page.Visible = false
        end
        tw(o.btn, 0.18, {BackgroundTransparency = sel and 0 or 1})
        o.ic:Tween(sel and T.text or T.dim, 0.18)
        tw(o.bar, 0.24, {
            BackgroundTransparency = sel and 0 or 1,
            Size = sel and UDim2.fromOffset(2, 16) or UDim2.fromOffset(2, 6),
            Position = sel and UDim2.new(0, -5, 0.5, -8) or UDim2.new(0, -5, 0.5, -3),
        }, Enum.EasingStyle.Quint)
    end
end
local function addTab(name, iconKey, single)
    local btn = new("TextButton", {Size = UDim2.fromOffset(36, 34), BackgroundColor3 = T.sel, BackgroundTransparency = 1,
        Text = "", AutoButtonColor = false, LayoutOrder = #tabList + 1}, tabHolder)
    round(btn, 8)
    local ic = mkIcon(btn, iconKey, T.dim, 16)
    ic.box.Position = UDim2.new(0.5, 0, 0.5, 0)
    local bar = new("Frame", {Size = UDim2.fromOffset(2, 6), Position = UDim2.new(0, -5, 0.5, -3),
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
    track(btn.MouseEnter:Connect(function() if not t.sel then tw(btn, 0.12, {BackgroundTransparency = 0.6}) end end))
    track(btn.MouseLeave:Connect(function() if not t.sel then tw(btn, 0.15, {BackgroundTransparency = 1}) end end))
    return t
end
local function sectionLabel(parent, text, order)
    local l = mkLabel(parent, string.upper(text), 10, T.dim, F_BOLD)
    l.Size = UDim2.new(1, 0, 0, 14)
    l.LayoutOrder = order or 1
    return l
end
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
function Tab:SelectSub(sub)
    for _, o in ipairs(self.subs) do
        local sel = (o == sub)
        o.sel = sel
        if sel and not o.frame.Visible then
            o.frame.Position = UDim2.fromOffset(0, 10)
            o.frame.Visible = true
            tw(o.frame, 0.28, {Position = UDim2.new()}, Enum.EasingStyle.Quint)
        elseif not sel then
            o.frame.Visible = false
        end
        tw(o.btn, 0.18, {BackgroundTransparency = sel and 0 or 1, TextColor3 = sel and T.text or T.dim})
    end
    self.scroll.CanvasPosition = Vector2.new(0, 0)
end
function Tab:Sub(name)
    if not self.subs then
        self.subs = {}
        self.cols[1].Parent.Visible = false
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
    local sub = setmetatable({cols = {c1, c2}, nextCol = 1, frame = frame, btn = btn, scroll = self.scroll}, Tab)
    self.subs[#self.subs + 1] = sub
    local owner = self
    track(btn.MouseButton1Click:Connect(function() owner:SelectSub(sub) end))
    track(btn.MouseEnter:Connect(function() if not sub.sel then tw(btn, 0.12, {BackgroundTransparency = 0.6}) end end))
    track(btn.MouseLeave:Connect(function() if not sub.sel then tw(btn, 0.15, {BackgroundTransparency = 1}) end end))
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
        tw(sw, 0.22, {BackgroundColor3 = state and WHITE or T.off}, Enum.EasingStyle.Quint)
        tw(knob, 0.22, {
            Position = state and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7),
            BackgroundColor3 = state and KNOB_ON or KNOB_OFF,
        }, Enum.EasingStyle.Quint)
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
        track(dot.MouseButton1Click:Connect(function()
            pop.Visible = not pop.Visible
            if pop.Visible then fadeIn(pop, 0.18) end
        end))
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
    new("UICorner", {CornerRadius = UDim.new(0.5, 0)}, knob)
    local hit = new("TextButton", {Size = UDim2.new(1, 0, 0, 26), Position = UDim2.fromOffset(0, 16), BackgroundTransparency = 1, Text = "", ZIndex = 2}, row)
    local value = default
    local function render(instant)
        local p = (value - min) / (max - min)
        if instant then
            fill.Size = UDim2.new(p, 0, 1, 0)
            knob.Position = UDim2.new(p, 0, 0.5, 0)
        else
            tw(fill, 0.09, {Size = UDim2.new(p, 0, 1, 0)})
            tw(knob, 0.09, {Position = UDim2.new(p, 0, 0.5, 0)})
        end
        val.Text = tostring(value) .. (suffix or "")
    end
    local function set(v, silent)
        v = math.clamp(min + math.floor((v - min) / step + 0.5) * step, min, max)
        if v == value and not silent then return end
        value = v
        render()
        if not silent then cb(v) touch() end
    end
    render(true)
    dragBar(hit, self.tab.scroll, function(x)
        local p = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        set(min + p * (max - min))
    end)
    track(hit.MouseEnter:Connect(function() tw(knob, 0.12, {Size = UDim2.fromOffset(15, 15)}, Enum.EasingStyle.Quint) end))
    track(hit.MouseLeave:Connect(function() tw(knob, 0.16, {Size = UDim2.fromOffset(12, 12)}, Enum.EasingStyle.Quint) end))
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
        tw(arrow.box, 0.2, {Rotation = lst.Visible and 180 or 0}, Enum.EasingStyle.Quint)
        if lst.Visible then fadeIn(lst, 0.2) end
    end))
    Reg[id] = {get = function() return value end, set = function(v) if table.find(values, v) then set(v) end end}
end
function Card:Button(txt, cb)
    local b = new("TextButton", {Size = UDim2.new(1, 0, 0, 28), BackgroundColor3 = T.btn, Text = txt, TextColor3 = T.text,
        Font = F_MED, TextSize = 12, AutoButtonColor = false, LayoutOrder = self:nextOrder()}, self.body)
    round(b, 7)
    hover(b, T.btn, Color3.fromRGB(46, 46, 52))
    track(b.MouseButton1Down:Connect(function() tw(b, 0.08, {BackgroundColor3 = T.off}) end))
    track(b.MouseButton1Up:Connect(function() tw(b, 0.14, {BackgroundColor3 = Color3.fromRGB(46, 46, 52)}) end))
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
tHome = addTab("Dashboard", "home", true)
local tSurv = addTab("Survivor", "user")
tKill = addTab("Killer", "blade")
local tESP = addTab("ESP", "eye")
tMisc = addTab("Misc", "sliders")
tSet = addTab("Settings", "gear")
do
local homeCol = tHome.cols[1]
local selectedUid = lp.UserId
curFps = 0
local chipSig = ""
local avatarTag = {}
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
sectionLabel(homeCol, "Player statistics", 2)
local chipScroll = new("ScrollingFrame", {Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, BorderSizePixel = 0,
    ScrollBarThickness = 0, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.X,
    ScrollingDirection = Enum.ScrollingDirection.X, LayoutOrder = 3}, homeCol)
vlist(chipScroll, 6, Enum.FillDirection.Horizontal)
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
local STAT_ORDER = {"Level", "EXP", "Screws", "Gears", "KillerChance", "Ornaments", "PassExp", "PassClaimed"}
local function fmt(v)
    if type(v) ~= "number" then return tostring(v) end
    local s = ("%.0f"):format(math.floor(math.abs(v))):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
    return v < 0 and ("-" .. s) or s
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
end
do
    local sP, sW = tESP:Sub("Player"), tESP:Sub("World")
    local sD = tESP:Sub("Tampilan")
    local cPlayers, cObj = sP:Group("Players", 1), sW:Group("Objek", 1)
    for _, c in ipairs(CATS) do
        local key = c.key
        local target = c.player and cPlayers or cObj
        target:Toggle("T_" .. key, c.label, c.on,
            function(v) S.cat[key].on = v end,
            key ~= "chased" and {id = "C_" .. key, default = S.cat[key].color, cb = function(col) S.cat[key].color = col end} or nil)
    end
    local cChase = sP:Group("Chase (dikejar killer)", 1)
    cChase:Slider("ESP_ChaseDist", "Jarak chase (0 = off)", 0, 120, 40, 5, function(v) S.chaseDist = v end, "m")
    local cRange = sW:Group("Jarak", 2)
    cRange:Slider("ESP_MaxDist", "Jarak max objek (0 = bebas)", 0, 3000, 600, 50, function(v) S.maxDist = v end, "m")
    local cLbl = sD:Group("Label", 1)
    cLbl:Toggle("ESP_Names", "Nama (di atas)", true, function(v) S.names = v end)
    cLbl:Toggle("ESP_Dist", "Jarak (di bawah)", true, function(v) S.dist = v end)
    cLbl:Slider("ESP_TextSize", "Ukuran teks", 10, 24, 13, 1, function(v) S.textSize = v end)
    local cCone = sP:Group("Area liat killer (tanah)", 2)
    cCone:Toggle("Cone_On", "Aktif", true, function(v) S.cone.on = v end)
    cCone:Slider("Cone_Angle", "Sudut area killer", 40, 180, 100, 5, function(v) S.cone.angle = v end)
    cCone:Toggle("Cone_Line", "Garis arah kamera", true, function(v) S.cone.line = v end,
        {id = "Cone_LineCol", default = S.cone.lineColor, cb = function(c) S.cone.lineColor = c end})
    cCone:Toggle("Cone_Body", "Garis arah badan", false, function(v) S.cone.body = v end,
        {id = "Cone_BodyCol", default = S.cone.bodyColor, cb = function(c) S.cone.bodyColor = c end})
    cCone:Slider("Cone_LineLen", "Panjang garis", 10, 100, 30, 5, function(v) S.cone.lineLen = v end, "m")
    cCone:Slider("Cone_Range", "Jarak area killer", 20, 150, 70, 5, function(v) S.cone.range = v end, "m")
end
local cSC = tSurv:Group("Auto skill check", 1)
cSC:Toggle("SC_Enabled", "Enabled (F6)", true, function(v) S.sc.enabled = v end)
cSC:Dropdown("SC_Mode", "Mode", {"Instant", "Perfect", "Great", "Random"}, "Perfect", function(v) S.sc.mode = v end)
do local function parryInit()
    S.parry = {on = false, aggr = false, dist = 14, last = 0, busy = false, method = 2, hitOnly = false, circle = false, color = Color3.fromRGB(170, 0, 255), detect = false, learn = true, pre = false, hitDot = 0.55, block = 0, cdLo = 0, nl = 0, face = false, human = true, earlyK = 0.043}
    local PARRY_DEBUG = false
    local PARRY_LOG = true
    local ATTACK_ANIMS = {}
    for _, id in ipairs({
        "135002183282873", "121216847022485",
        "81963230963908", "84926129581106",
        "117042998468241", "133963973694098", "105374834496520", "111920872708571", "101636125032002",
        "129626174716003", "113691709436161", "130593238885843",
        "83333467665074",
        "98163597193511",
        "122812055447896",
        "132817836308238", "129784271201071", "82666958311998",
        "78432063483146", "118907603246885", "80411309607666",
        "139369275981139", "110355011987939",
        "138720291317243", "115244153053858",
        "74968262036854", "113255068724446",
        "106871536134254",
    }) do ATTACK_ANIMS[id] = true end
    -- ID tambahan dari hanxhub (hasil decode _AA). Sudah disaring: ID di NOT_SWING, ID spear, dan ID lama yang pendek (2874840706, 72042024) tidak ikut.
    for _, id in ipairs({
        "71008020992570", "72742711718023", "72908958549833", "73923929500477",
        "76385865186777", "76503974441748", "77081789642514", "78935059863801",
        "79935565590141", "79965656177566", "83873880822918", "84525330720658",
        "85030641905220", "89185525343404", "92125118598365", "92362656727126",
        "92554564590253", "96839438835309", "99472251587670", "102055678391920",
        "104689417033027", "109402730355822", "112166042383605", "112633191985365",
        "112840768179724", "117207742458428", "119752564209631", "121571390309073",
        "123047897844134", "123812278891591", "124706657239027", "124735239320776",
        "125224839697689", "126081405469607", "126497551689502", "126527634689050",
        "126626340093785", "126751859125353", "128241974219045", "130012819736632",
        "130585295123651", "133002120549396", "133881825716964", "134838390519433",
        "135403091566760", "135727476735024", "136365031119137", "137504605181913",
        "137688077908355", "137795837089724", "137846825408335", "138045669415653",
        "117187218825161", "105221485497534", "86868198964957", "134758728973154",
        "132636403911470", "125350153877085", "110850539331763",
        "75618342544502", "93902163029544", "79310600168078", "104540716539347",
        "73681849513551", "100014992013740",
    }) do ATTACK_ANIMS[id] = true end
    local EARLY_ANIMS = {["125430111937587"] = 0.048, ["127417297154354"] = 0.036}
    local NOT_SWING = {["117070354890871"] = true, ["81198376178242"] = true, ["70719237641923"] = true, ["78196404793645"] = true, ["108286715411226"] = true, ["75857500533792"] = true,
        ["77303734522729"] = true, ["101443662521580"] = true, ["127622545856523"] = true, ["129669521834246"] = true, ["79809716042968"] = true, ["87436543050891"] = true, ["84404617799721"] = true}
    local cPar = tSurv:Group("Auto parry (Dagger)", 2)
    cPar:Toggle("PAR_On", "Auto Parry", false, function(v) S.parry.on = v end)
    S.parry.pre = false
    S.parry.aimGate, S.parry.aimMin, S.parry.closeMin = false, -0.25, 8
    S.parry.rayGate, S.parry.rayTol, S.parry.zoneManual, S.parry.rayMinD = false, 4, false, 5
    cPar:Slider("PAR_Zone", "Jarak zona parry", 4, 25, 14, 1, function(v) S.parry.dist = v end, "m")
    cPar:Toggle("PAR_Bait", "Anti rege bait", true, function(v) S.parry.baitCheck = v end)
    cPar:Label("Skip parry kalau kamera killer ngebelakangi.")
    S.parry.zoneMax, S.parry.swingDot = 22, 0
    S.parry.baitCheck, S.parry.baitDot = true, 0.3
    S.parry.close, S.parry.closeR, S.parry.lateSkip = false, 4.0, false
    S.parry.circle = true
    S.parry.circShow = 8
    cPar:Toggle("PAR_Circle", "Garis zona parry", true, function(v) S.parry.circle = v end,
        {id = "PAR_CircleCol", default = S.parry.color, cb = function(c) S.parry.color = c end})
    cPar:Slider("PAR_CircleNear", "Garis muncul dari jarak", 0, 30, 8, 1, function(v) S.parry.circShow = v end, "m")
    local stLbl = cPar:Label("Status: OFF")
    local learned, recent, nopar, stats, idReach, idLag = {}, {}, {}, {}, {}, {}
    local PFILE = BASE .. "jin_parry.json"
    local function saveP()
        if not writefile then return end
        pcall(function()
            local a, n = {}, {}
            for id in pairs(learned) do a[#a + 1] = id end
            for id in pairs(nopar) do n[#n + 1] = id end
            writefile(PFILE, HttpService:JSONEncode({anims = a, nopar = n, stats = stats, reach = idReach, lag = idLag, btn = S.parry.btn, key = S.parry.key and S.parry.key.Name}))
        end)
    end
    local function addLearn(id, why)
        learned[id] = true
        S.parry.nl = S.parry.nl + 1
        saveP()
        notify("Auto parry: belajar", ("dipelajari dari %s: %s"):format(tostring(why), id))
    end
    pcall(function()
        if isfile and readfile and isfile(PFILE) then
            local d = HttpService:JSONDecode(readfile(PFILE))
            for _, id in ipairs(d.anims or {}) do learned[tostring(id)] = true S.parry.nl = S.parry.nl + 1 end
            for _, id in ipairs(d.nopar or {}) do nopar[tostring(id)] = true end
            if type(d.stats) == "table" then stats = d.stats end
            if type(d.lag) == "table" then for id, v in pairs(d.lag) do if type(v) == "table" and tonumber(v.n) and tonumber(v.sum) then idLag[tostring(id)] = {n = tonumber(v.n), sum = tonumber(v.sum)} end end end
            if type(d.reach) == "table" then for id, v in pairs(d.reach) do if tonumber(v) then idReach[tostring(id)] = tonumber(v) end end end
            if type(d.btn) == "table" then S.parry.btn = d.btn end
            if type(d.key) == "string" then S.parry.key = Enum.KeyCode[d.key] end
        end
    end)
    idReach["106871536134254"] = math.max(idReach["106871536134254"] or 0, 16)
    for id, r in pairs({
        ["83333467665074"] = 12,
        ["84926129581106"] = 15, ["81963230963908"] = 15,
        ["129626174716003"] = 14, ["113691709436161"] = 14,
        ["75618342544502"] = 17, ["93902163029544"] = 17,
        ["74968262036854"] = 17, ["113255068724446"] = 17,
        ["105374834496520"] = 17, ["111920872708571"] = 17,
        ["130593238885843"] = 22, ["115244153053858"] = 17, ["98163597193511"] = 12,
        ["122812055447896"] = 15, ["129784271201071"] = 15, ["118907603246885"] = 15, ["110355011987939"] = 15,
    }) do idReach[id] = math.max(idReach[id] or 0, r) end
    if not idLag["101636125032002"] then idLag["101636125032002"] = {n = 3, sum = 0.12} end
    local idLagD = {}
    local function lagAdd(id, dist, lag)
        local r = idLagD[id]
        if not r then r = {n = 0, sx = 0, sy = 0, sxx = 0, sxy = 0} idLagD[id] = r end
        if r.n >= 40 then return end
        r.n, r.sx, r.sy, r.sxx, r.sxy = r.n + 1, r.sx + dist, r.sy + lag, r.sxx + dist * dist, r.sxy + dist * lag
    end
    local function lagPredict(id, dist)
        local r = idLagD[id]
        if not (r and r.n >= 3) then return nil end
        local den = r.n * r.sxx - r.sx * r.sx
        if den < 4 then return nil end
        local b = math.max(0, (r.n * r.sxy - r.sx * r.sy) / den)
        local a = (r.sy - b * r.sx) / r.n
        return math.min(1.5, math.max(0.02, a + b * dist))
    end
    for _, pt in ipairs({{2.2, 0.13}, {8.5, 0.24}, {7.0, 0.22}}) do lagAdd("129626174716003", pt[1], pt[2]) end
    local LOGF = BASE .. "jin_parry_log.txt"
    local logbuf, logBusy = {}, false
    local function plog(...)
        if not (PARRY_DEBUG or PARRY_LOG) then return end
        local a = table.pack(...)
        for i = 1, a.n do a[i] = tostring(a[i]) end
        logbuf[#logbuf + 1] = ("[%.2f] %s"):format(os.clock(), table.concat(a, " ", 1, a.n))
        if #logbuf > 600 then table.remove(logbuf, 1) end
        if writefile and not logBusy then
            logBusy = true
            task.delay(3, function()
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
        local function mask(s) return PARRY_DEBUG and s or (s:gsub("%d%d%d%d%d%d+", "#")) end
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
                            plog("PARRYOBJ ketemu | tool", tostring(u.tool and u.tool:GetFullName()), "| lockDuration", tostring(u.lockDuration), "| attr dagger:", attrDump(u.tool))
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
        if os.clock() - pc.t < 1 then return nil end
        pc.t = os.clock()
        pc.self = nil
        return findParryObj()
    end
    task.spawn(function()
        local ok, r = pcall(function()
            return game:GetService("ReplicatedStorage"):WaitForChild("Remotes", 30):WaitForChild("Items", 30):WaitForChild("Parrying Dagger", 30):WaitForChild("parryResult", 30)
        end)
        if ok and r then
            track(r.OnClientEvent:Connect(function(...)
                local a = table.pack(...)
                local cdSrv = tonumber(a[2])
                for i = 1, a.n do a[i] = tostring(a[i]) end
                plog("PARRYRESULT", table.concat(a, " | ", 1, a.n))
                if cdSrv and cdSrv > 0 and cdSrv <= 120 then
                    local P = S.parry
                    P.block = math.max(P.block or 0, os.clock() + cdSrv)
                end
            end))
        end
    end)
    local function ready()
        local ch = lp.Character
        local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
        local hum = ch and ch:FindFirstChildOfClass("Humanoid")
        if not (hrp and hum and hum.Health > 0) then return nil, "belum spawn / mati" end
        if roleOf(lp) == "killer" then return nil, "kamu killer" end
        local eq = attr("EquippedItem")
        if eq ~= nil and eq ~= "Parrying Dagger" then return nil, "item = " .. tostring(eq) .. ", bukan dagger" end
        if ch:GetAttribute("ParrySpent") then
            if pc.self and pc.self.isSilenced then return nil, "dagger udah kepake (silenced, parry berhasil sebelumnya; kemungkinan sekali pakai)" end
            return nil, "cooldown dagger (abis parry: meleset 60 dtk, sukses juga kena cooldown, log: > 17 dtk)"
        end
        if ch:GetAttribute("Parry") or ch:GetAttribute("Knocked") then return nil, "parry lagi aktif / knocked" end
        if hum.PlatformStand then return nil, "PlatformStand (kena stun / ragdoll)" end
        for an, av in pairs(ch:GetAttributes()) do
            if av == true then
                local ln = string.lower(tostring(an))
                if ln:find("knock") or ln:find("downed") or ln:find("carried") or ln:find("hooked") or ln:find("incap") or ln:find("grab") then
                    return nil, "kamu lagi downed / digendong / di-hook (" .. tostring(an) .. ")"
                end
            end
        end
        local P = S.parry
        local now = os.clock()
        if now < P.block then return nil, ("dagger cooldown ~%.1f dtk"):format(P.block - now) end
        local po = parryObj()
        if po then
            local okC, can = pcall(po.CanUse, po)
            if okC and can == false then
                local function q(name) local okq, v = pcall(po[name], po) if okq then return v end return nil end
                local why = {}
                if q("_isEquipped") == false then why[#why + 1] = "dagger ga di-equip" end
                if po.isSilenced then why[#why + 1] = "silenced" end
                if po.isParryOnCooldown then why[#why + 1] = "cooldown" end
                if po.isParryResolving then why[#why + 1] = "nunggu hasil server" end
                if q("_isBusy") then why[#why + 1] = "lagi aksi (vault/pallet/gen/dll)" end
                if q("_isLowHealth") then why[#why + 1] = "HP < 50%" end
                return nil, "dagger ga bisa: " .. (#why > 0 and table.concat(why, ", ") or "?")
            end
        end
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
    local SKIN_NAME = {
        ["109133187196613"] = "Default", ["75939529748815"] = "Shield/BloodShield", ["126894569253341"] = "Robot/Feedbacker",
        ["127096285501517"] = "Katana/Enten", ["123307242865945"] = "Fish/Fih", ["81793464499285"] = "Watcher/StopWatch",
    }
    local skinStats = {}
    local function startupEst()
        local st = skinStats[S.parry.fireSkin or ""]
        if st and (st.nNP or 0) >= 1 then return math.min(math.max(st.sumNP / st.nNP, 0.03), 0.2) end
        return 0.10
    end
    local parryHooked = setmetatable({}, {__mode = "k"})
    local function watchParryAttr()
        local ch = lp.Character
        if not ch or parryHooked[ch] then return end
        parryHooked[ch] = true
        track(ch:GetAttributeChangedSignal("Parry"):Connect(function()
            local P = S.parry
            if ch:GetAttribute("Parry") and P.firedT and os.clock() - P.firedT < 1.2 then
                plog("PARRY ATTR nyala", ("+%.3fs sejak FIRE"):format(os.clock() - P.firedT))
                local dly, pg0, sk = os.clock() - P.firedT, P.firePing or 0, P.fireSkin or "?"
                local st = skinStats[sk]
                if not st then st = {n = 0, sum = 0, min = 9, max = 0} skinStats[sk] = st end
                st.n, st.sum, st.min, st.max = st.n + 1, st.sum + dly, math.min(st.min, dly), math.max(st.max, dly)
                if pg0 > 0 and pg0 <= 0.4 then st.sumNP, st.nNP = (st.sumNP or 0) + (dly - pg0), (st.nNP or 0) + 1 end
                plog("PARRYTIME skin", sk, SKIN_NAME[sk] or "?", ("| delay %.3f | ping %.3f | delay-ping %.3f | n %d avg %.3f min %.3f max %.3f"):format(dly, pg0, dly - pg0, st.n, st.sum / st.n, st.min, st.max))
            end
            if not ch:GetAttribute("Parry") or os.clock() - (P.firedT or 0) < 1.2 then return end
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
    local function attempt(ch, hum)
        local P = S.parry
        local hn, hwhy
        local po = parryObj()
        if po then
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
            return 0
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
            if P.nfWhy ~= hum or now - (P.nfT or 0) > 1 then
                P.nfWhy, P.nfT = hum, now
                plog("NOFIRE", reason, "id", id, "|", hum, "|", cuDetail())
            end
            return
        end
        P.busy = true
        local t0 = os.clock()
        P.block = t0 + 0.35
        P.firedT = t0
        do
            local okp, pgv = pcall(function() return lp:GetNetworkPing() end)
            P.firePing = okp and pgv or 0
            local dg = ch:FindFirstChild("Parrying Dagger")
            P.fireSkin = dg and (tostring(dg:GetAttribute("useanim")):gsub("rbxassetid://", "")) or "?"
        end
        task.spawn(function()
            local hrp = ch:FindFirstChild("HumanoidRootPart")
            if P.face and hrp and k and k.hrp.Parent then
                local kp = k.hrp.Position
                hrp.CFrame = CFrame.lookAt(hrp.Position, Vector3.new(kp.X, hrp.Position.Y, kp.Z))
                task.wait(0.05)
            end
            local front = false
            if hrp and k and k.hrp.Parent then
                local dir = k.hrp.Position - hrp.Position
                front = dir.Magnitude > 0 and hrp.CFrame.LookVector:Dot(dir.Unit) >= 0.5
            end
            local okA, m = pcall(attempt, ch, hum)
            if not okA then plog("attempt error", tostring(m)) m = nil end
            P.busy = false
            local since = P.okT and t0 - P.okT
            if since and since > 60 then since = nil end
            if m then
                if since and since < P.cdLo then P.cdLo = since end
                P.okT = t0
                P.block = t0 + (parryObj() and 0.8 or math.max(P.cdLo, 0.8))
                P.res = ("parry DITEKAN via %s (%s, killer di %s) | cd>=%.1fs"):format(m == 0 and "handler asli" or ("remote metode " .. m), reason, front and "depan" or "samping/belakang", P.cdLo)
                if m ~= 0 then notify("Auto parry", "Parry nyala (" .. reason .. ")") end
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
        plog("FIRE", reason, "id", id, "| sejak anim mulai", P.animT and ("%.3fs"):format(t0 - P.animT) or "-", "| ping", pcall(function() return lp:GetNetworkPing() end) and ("%.3f"):format(lp:GetNetworkPing()) or "?", "| char:", attrDump(ch))
    end
    local SWING_PRIO = {
        [Enum.AnimationPriority.Action] = true, [Enum.AnimationPriority.Action2] = true,
        [Enum.AnimationPriority.Action3] = true, [Enum.AnimationPriority.Action4] = true,
    }
    local function looksLikeSwing(tr)
        if tr.Looped or not SWING_PRIO[tr.Priority] then return false end
        local L = tr.Length
        return L == 0 or (L >= 0.3 and L <= 2.5)
    end
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
    local function rayMiss(k, to)
        local aim = aimOf(k)
        local v = Vector3.new(to.X - k.hrp.Position.X, 0, to.Z - k.hrp.Position.Z)
        local along = v:Dot(aim)
        if along <= 0 then return v.Magnitude, along end
        return math.sqrt(math.max(0, v.Magnitude * v.Magnitude - along * along)), along
    end
    local AIM_MIN, AIM_MARGIN = 0.55, 0.15
    local function targetsUs(k, hrp)
        if k.char:GetAttribute("IsChasing") and k.char:GetAttribute("ChaseTargetUserId") == lp.UserId then return true end
        local aim, kp = aimOf(k), k.hrp.Position
        local mine = aimDot(aim, kp, hrp.Position)
        local dMine0 = (hrp.Position - kp).Magnitude
        do
            local cid = k.char:GetAttribute("ChaseTargetUserId")
            if k.char:GetAttribute("IsChasing") and type(cid) == "number" and cid ~= 0 and cid ~= lp.UserId then
                local pl = Players:GetPlayerByUserId(cid)
                local c = pl and pl.Character
                local h = c and c:FindFirstChild("HumanoidRootPart")
                local hm = c and c:FindFirstChildOfClass("Humanoid")
                if h and hm and hm.Health > 0 and not c:GetAttribute("Knocked") then
                    local dT = (h.Position - kp).Magnitude
                    if not (dMine0 < dT - 3 and mine >= AIM_MIN) then return false, "killer ngejar " .. pl.DisplayName end
                end
            end
        end
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
                    if dv <= dMine + 3 and aimDot(aim, kp, h.Position) >= math.max(AIM_MIN, mine + AIM_MARGIN) then
                        return false, "killer ngincer " .. pl.DisplayName
                    end
                end
            end
        end
        return true
    end
    local HIT_T, EVAL_DELAY = 0.12, 0
    local function willHit(k, hrp, tRem, id)
        local P = S.parry
        local kv, uv = k.hrp.AssemblyLinearVelocity, hrp.AssemblyLinearVelocity
        local kp = k.hrp.Position + Vector3.new(kv.X, 0, kv.Z) * tRem
        local up = hrp.Position + Vector3.new(uv.X, 0, uv.Z) * tRem
        local d = Vector3.new(up.X - kp.X, 0, up.Z - kp.Z).Magnitude
        local dot = aimDot(aimOf(k), kp, up)
        return d <= P.dist and (dot >= P.hitDot or d <= 2.5), d, dot
    end
    local hooked = setmetatable({}, {__mode = "k"})
    local hookedChar = setmetatable({}, {__mode = "k"})
    local hookedAttr = setmetatable({}, {__mode = "k"})
    local kanimT = {}
    local KATTR_SKIP = {CamLook = true, VeilRenderedAt = true, AC_MovementGraceUntil = true, AC_StrictAllowedSpeedUntil = true, AC_AllowedSpeed = true, CorruptWaveAt = true, CorruptWaveFrom = true, CorruptWaveDir = true, CorruptWindupAt = true}
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
            if typeof(v) == "number" and now - (lastT[name] or 0) < 0.25 then return end
            lastT[name] = now
            plog("KATTR", k.char.Name, name, tostring(pv), "->", tostring(v), ("| %.1fm"):format(d))
        end))
    end
    local function hookKiller(k)
        hookKillerAttrs(k)
        local cached = hookedChar[k.char]
        if cached and cached.Parent then return end
        local an = k.char:FindFirstChildWhichIsA("Animator", true)
        if not an then return end
        hookedChar[k.char] = an
        if hooked[an] then return end
        hooked[an] = true
        track(an.AnimationPlayed:Connect(function(tr)
            local a = tr.Animation
            local id = a and tostring(a.AnimationId):match("%d+")
            if not (id and k.hrp.Parent) then return end
            local P = S.parry
            if not tr.Looped then
                local now = os.clock()
                recent[#recent + 1] = {id = id, t = now, pos = k.hrp.Position, swing = looksLikeSwing(tr)}
                if ATTACK_ANIMS[id] or learned[id] then P.lastAtkT = now end
                while #recent > 0 and (now - recent[1].t > 2 or #recent > 30) do table.remove(recent, 1) end
            end
            local ch = lp.Character
            local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            local off = hrp.Position - k.hrp.Position
            local d = off.Magnitude
            if PARRY_DEBUG and d <= 30 and d > 0 then
                local nk = os.clock()
                kanimT[id] = kanimT[id] or 0
                if nk - kanimT[id] > 0.5 then
                    kanimT[id] = nk
                    plog("KANIM", id, "| prio", tostring(tr.Priority):gsub("Enum.AnimationPriority.", ""), ("| len %.2f | %s | %.1fm | killer %s"):format(tr.Length, tr.Looped and "loop" or "once", d, k.char.Name))
                end
            end
            if d > 30 or d == 0 then return end
            local nowT = os.clock()
            if P.lastId == id and nowT - (P.lastIdT or 0) < 0.1 then return end
            P.lastId, P.lastIdT = id, nowT
            P.anim = ("%s %.2fs %.0fm %s"):format(id, tr.Length, d, tr.Looped and "loop" or "once")
            P.animT = os.clock()
            if not P.on then return end
            local E = P.early
            if E and E.k == k and (ATTACK_ANIMS[id] or learned[id]) and not E.stk and nowT - E.t > 0.05 and nowT - E.t < 1.2 then
                E.stk = true
                plog("STRIKE", id, ("| ancang->ayunan %.2fs | jarak ancang %.1fm"):format(nowT - E.t, E.d))
            end
            if EARLY_ANIMS[id] and not nopar[id] then
                local nowE = os.clock()
                local chasingUs = k.char:GetAttribute("IsChasing") and k.char:GetAttribute("ChaseTargetUserId") == lp.UserId
                local whyE
                local pingE = 0
                pcall(function() pingE = lp:GetNetworkPing() end)
                local needE = math.min(pingE, 0.25) + startupEst()
                local hitInE = ((P.earlyKs and P.earlyKs[id]) or EARLY_ANIMS[id]) * d
                local missE = P.rayGate and rayMiss(k, hrp.Position) or 0
                local zoneE = P.dist
                if d > zoneE then whyE = ("ancang-ancang tapi killer %.0fm (> zona %.0fm)"):format(d, zoneE)
                elseif P.rayGate and missE > P.rayTol * 1.5 and d > P.rayMinD then whyE = ("ancang-ancang tapi garis bidik meleset %.1fm (toleransi %.1f x1.5)"):format(missE, P.rayTol)
                elseif not (chasingUs or d <= 10) then whyE = ("ancang-ancang tapi killer ga ngejar kita (%.0fm)"):format(d)
                elseif nowE - (P.lastHitT or 0) < 0.3 then whyE = "ancang-ancang tapi baru abis hit"
                elseif P.lateSkip and hitInE < needE - 0.03 then whyE = ("ancang-ancang tapi pasti telat: ancang->hit ~%.2fs < latensi parry %.2fs (dagger dihemat)"):format(hitInE, needE) end
                plog("EARLY anim", id, ("| %.1fm | ngejar kita %s | ->"):format(d, tostring(chasingUs and true or false)), whyE and ("SKIP: " .. whyE) or "TEMBAK")
                if whyE then P.why, P.whyT = whyE, nowE P.whyK, P.whyKT = whyE, nowE return end
                P.lastEval = nil
                P.early = {id = id, t = nowE, d = d, k = k}
                if not (P.human or P.baitCheck) then
                    tryFire("ancang-ancang", k, id)
                    return
                end
                local ping = 0
                pcall(function() ping = lp:GetNetworkPing() end)
                ping = math.min(ping, 0.25)
                local lead = math.min(startupEst() + ping, 0.5)
                local K = (P.earlyKs and P.earlyKs[id]) or EARLY_ANIMS[id]
                local tFire = nowE + math.max(0, K * d - lead)
                local d0 = d
                task.spawn(function()
                    while running and os.clock() < tFire do task.wait() end
                    local P3 = S.parry
                    local c3 = lp.Character
                    local h3 = c3 and c3:FindFirstChild("HumanoidRootPart")
                    if not (running and P3.on and h3 and k.hrp.Parent) then return end
                    local d3 = (h3.Position - k.hrp.Position).Magnitude
                    local why3
                    if os.clock() - (P3.firedT or 0) < 1 then why3 = "udah ditembak lewat jalur lain"
                    elseif (P3.lastHitT or 0) > nowE then why3 = "udah ada hit sebelum waktunya"
                    elseif d3 > 18 or d3 > d0 + 4 then why3 = ("killer ngejauh (%.1fm -> %.1fm), kemungkinan pancingan"):format(d0, d3)
                    elseif P3.baitCheck and (tFire - nowE) >= 0.03 then
                        local dot3 = aimDot(aimOf(k), k.hrp.Position, h3.Position)
                        plog("EARLY cek arah", ("dot %.2f (min %.2f) | tunggu %.2fs"):format(dot3, P3.baitDot, tFire - nowE))
                        if dot3 < P3.baitDot then why3 = ("killer muter kamera ke arah lain (dot %.2f) = rege bait"):format(dot3) end
                    end
                    plog("EARLY tunda", ("%.2fs"):format(tFire - nowE), ("| jarak %.1f -> %.1f | K %.3f | lead %.2f |"):format(d0, d3, K, lead), why3 and ("BATAL: " .. why3) or "TEMBAK")
                    if why3 then P3.why, P3.whyT = why3, os.clock() P3.whyK, P3.whyKT = why3, os.clock() return end
                    tryFire("ancang-ancang (ditunda)", k, id)
                end)
                return
            end
            local toUs = off.Unit
            local known = ATTACK_ANIMS[id] or learned[id]
            local closing = (k.hrp.AssemblyLinearVelocity - hrp.AssemblyLinearVelocity):Dot(toUs)
            local base = P.dist
            local reach = P.dist
            local why
            if NOT_SWING[id] then why = "anim " .. id .. " = recovery / bukan serangan"
            elseif not (known or (P.detect and looksLikeSwing(tr))) then why = "anim " .. id .. " ga dikenal sbg serangan"
            elseif nopar[id] then why = "anim " .. id .. " ga bisa di-parry"
            elseif not known and nowT - (P.lastHitT or 0) < 0.6 then why = "tebakan: baru abis hit (anim recovery)"
            elseif not known and (k.char:GetAttribute("IsCarrying") or k.char:GetAttribute("Immobile") or k.char:GetAttribute("IsStunned")) then why = "tebakan: killer lagi bawa / ga gerak / stun"
            elseif not known and not (k.char:GetAttribute("IsChasing") and k.char:GetAttribute("ChaseTargetUserId") == lp.UserId) then
                why = "tebakan: killer ga lagi ngejar kita"
            elseif d > reach then why = ("killer %.0fm, di luar jarak (reach %.0fm)"):format(d, reach) P.lastSkip = {id = id, t = os.clock(), d = d}
            else
                local ok, w = targetsUs(k, hrp)
                if not ok then why = w
                else
                    local near = (not known) and nearInteract(k, toUs)
                    if near then why = "killer lagi ngerjain " .. near end
                end
            end
            if why then
                P.why, P.whyT = why, os.clock()
                if known then P.whyK, P.whyKT = why, os.clock() plog("SKIP anim", id, "|", why) end
                return
            end
            local reason = known and "ayunan" or "ayunan (tebakan)"
            local function evalFire()
                local P2 = S.parry
                if not (running and P2.on and k.hrp.Parent) then return end
                local c2 = lp.Character
                local h2 = c2 and c2:FindFirstChild("HumanoidRootPart")
                if not h2 then return end
                local ok2, d2, dot2 = willHit(k, h2, HIT_T - EVAL_DELAY, id)
                P2.lastEval = {id = id, t = os.clock(), d = d2, dot = dot2}
                plog("EVAL anim", id, ("| d_prediksi %.1f (range %.1f) | dot %.2f (min %.2f) | jarak skrg %.1f | ->"):format(d2, P2.dist, dot2, P2.hitDot, (h2.Position - k.hrp.Position).Magnitude), (ok2 or not P2.hitOnly) and "TEMBAK" or "SKIP (ga bakal kena)")
                if P2.rayGate then
                    local offv = h2.Position - k.hrp.Position
                    local closing2 = 0
                    if offv.Magnitude > 0.01 then
                        closing2 = (k.hrp.AssemblyLinearVelocity - h2.AssemblyLinearVelocity):Dot(offv.Unit)
                    end
                    local miss, along = rayMiss(k, h2.Position)
                    local bad = miss > P2.rayTol and closing2 < P2.closeMin and d2 > P2.rayMinD
                    local cs = P2.inClose and P2.inClose[k.char]
                    local bl = Vector3.new(k.hrp.CFrame.LookVector.X, 0, k.hrp.CFrame.LookVector.Z)
                    local tu = Vector3.new(offv.X, 0, offv.Z)
                    local bodyDot = (bl.Magnitude > 0.1 and tu.Magnitude > 0.1) and bl.Unit:Dot(tu.Unit) or -1
                    plog("RAYGATE", id, (" | garis meleset %.1fm (toleransi %.1f) | sepanjang garis %.1fm | badan dot %.2f | closing %.1f (min %.1f) | di <=4m sejak %s | ->"):format(miss, P2.rayTol, along, bodyDot, closing2, P2.closeMin, cs and ("%.2fs"):format(os.clock() - cs) or "-"), bad and "SKIP" or "ok")
                    if bad then
                        P2.why, P2.whyT = (" garis bidik killer meleset %.1fm dari kita (toleransi %.1f)"):format(miss, P2.rayTol), os.clock()
                        P2.whyK, P2.whyKT = P2.why, P2.whyT
                        return
                    end
                elseif P2.aimGate then
                    local offv = h2.Position - k.hrp.Position
                    local closing2 = 0
                    if offv.Magnitude > 0.01 then
                        closing2 = (k.hrp.AssemblyLinearVelocity - h2.AssemblyLinearVelocity):Dot(offv.Unit)
                    end
                    local bad = dot2 < P2.aimMin and d2 > 2.5 and closing2 < P2.closeMin
                    local cs = P2.inClose and P2.inClose[k.char]
                    plog("AIMGATE", id, (" | dot %.2f (min %.2f) | closing %.1f (min %.1f) | d_prediksi %.1f | di <=4m sejak %s | ->"):format(dot2, P2.aimMin, closing2, P2.closeMin, d2, cs and ("%.2fs"):format(os.clock() - cs) or "-"), bad and "SKIP" or "ok")
                    if bad then
                        P2.why, P2.whyT = (" ayunan ga ngadep kita (dot %.2f, closing %.1f)"):format(dot2, closing2), os.clock()
                        P2.whyK, P2.whyKT = P2.why, P2.whyT
                        return
                    end
                end
                if P2.baitCheck and dot2 < P2.swingDot and d2 > 2 then
                    P2.why, P2.whyT = (" arah kamera killer dot %.2f < min %.2f"):format(dot2, P2.swingDot), os.clock()
                    P2.whyK, P2.whyKT = P2.why, P2.whyT
                    plog("SKIP anim", id, ("| arah kamera dot %.2f < min %.2f (anti rege bait jalur ayun) | %.1fm"):format(dot2, P2.swingDot, d2))
                    return
                end
                if P2.hitOnly and not ok2 then
                    P2.why, P2.whyT = ("ayunan diprediksi meleset (d %.1f > %.1f / dot %.2f)"):format(d2, P2.dist, dot2), os.clock()
                    P2.whyK, P2.whyKT = P2.why, P2.whyT
                    return
                end
                local lg = idLag[id]
                local lagD = lagPredict(id, d2)
                if (lg and lg.n >= 2) or lagD then
                    local png = 0
                    pcall(function() png = lp:GetNetworkPing() end)
                    png = math.min(png, 0.25)
                    local avg, need = lagD or (lg.sum / lg.n), png + startupEst()
                    if P2.lateSkip and avg < need then
                        P2.why, P2.whyT = ("anim %s pasti telat (jeda %.2fs < latensi parry %.2fs)"):format(id, avg, need), os.clock()
                        P2.whyK, P2.whyKT = P2.why, P2.whyT
                        plog("SKIP anim", id, "| pasti telat: jeda anim->hit", (lagD and "(prediksi @ %.1fm)" or "(rata2)"):format(d2), ("%.3fs"):format(avg), "< latensi parry", ("%.3fs"):format(need), "| dagger dihemat biar ga kena cooldown 60 dtk")
                        return
                    end
                end
                tryFire(reason, k, id)
            end
            if EVAL_DELAY > 0 then task.delay(EVAL_DELAY, evalFire) else evalFire() end
        end))
    end
    local hits, watched = {}, setmetatable({}, {__mode = "k"})
    local function watchHum(hum, mine)
        if watched[hum] then return end
        watched[hum] = true
        local last = hum.Health
        track(hum.HealthChanged:Connect(function(h)
            local drop = h < last - 0.5
            last = h
            if not drop then return end
            S.parry.lastHitT = os.clock()
            local vh = hum.Parent and hum.Parent:FindFirstChild("HumanoidRootPart")
            if not vh then return end
            local now = os.clock()
            local best
            for i = 1, #recent do
                local e = recent[i]
                local dt = now - e.t
                if dt <= 0.6 and dt >= 0.03 and (vh.Position - e.pos).Magnitude <= 22 then
                    if not best or (e.swing and not best.swing) then best = e end
                end
            end
            if mine then
                local rl, seenR = {}, {}
                for i = 1, #recent do
                    local e = recent[i]
                    if now - e.t <= 1.2 and not seenR[e.id] then seenR[e.id] = true rl[#rl + 1] = ("%s(-%.2fs)"):format(e.id, now - e.t) end
                end
                plog("RECENT anim <= 1.2s sebelum hit:", #rl > 0 and table.concat(rl, ", ") or "-")
                local Ee = S.parry.early
                if Ee and not Ee.cal and now - Ee.t > 0.05 and now - Ee.t < 1.5 then
                    Ee.cal = true
                    local ks = S.parry.earlyKs
                    if not ks then ks = {} S.parry.earlyKs = ks end
                    local oldK = ks[Ee.id] or EARLY_ANIMS[Ee.id] or 0.04
                    local obs = (now - Ee.t) / math.max(Ee.d, 1)
                    ks[Ee.id] = math.min(0.12, math.max(0.015, oldK * 0.6 + obs * 0.4))
                    plog("KALIBRASI ancang->hit", Ee.id, ("| %.2fs @ %.1fm | K %.3f -> %.3f"):format(now - Ee.t, Ee.d, oldK, ks[Ee.id]))
                end
                if best and best.id and not NOT_SWING[best.id] then
                    local lg = idLag[best.id]
                    if not lg then lg = {n = 0, sum = 0} idLag[best.id] = lg end
                    if lg.n < 20 then lg.n = lg.n + 1 lg.sum = lg.sum + (now - best.t) end
                    if (now - best.t) < 1 then lagAdd(best.id, (vh.Position - best.pos).Magnitude, now - best.t) end
                    saveP()
                end
                plog("HIT KITA | HP", ("%.0f/%.0f"):format(hum.Health, hum.MaxHealth), "| anim", best and best.id or "?", "| Parry", tostring(hum.Parent and hum.Parent:GetAttribute("Parry")), "| sejak FIRE", S.parry.firedT and ("%.3fs"):format(now - S.parry.firedT) or "-")
                local ls = S.parry.lastSkip
                if ls and (not best or ls.id == best.id) and now - ls.t <= 0.8 and ls.d > (idReach[ls.id] or S.parry.dist) then
                    local old = idReach[ls.id] or S.parry.dist
                    idReach[ls.id] = math.min(ls.d + 1.5, 22)
                    plog("KALIBRASI per-anim", ls.id, "| reach", ("%.1f -> %.1f"):format(old, idReach[ls.id]))
                    saveP()
                    notify("Auto parry: kalibrasi", "jangkauan serangan itu dilebarin dari hit tadi")
                    S.parry.lastSkip = nil
                end
                local pd = S.parry.pending
                if pd and not pd.done and now - pd.t <= 0.8 then
                    pd.pierced, pd.pid = true, best and best.id
                    resolvePending(pd)
                end
                local Pd = S.parry
                if Pd.on and now - (Pd.hitNotifT or 0) > 1.5 then
                    local nearK = best ~= nil
                    if not nearK then
                        for _, kk in ipairs(getKillers()) do
                            if kk.hrp.Parent and (kk.hrp.Position - vh.Position).Magnitude <= 25 then nearK = true break end
                        end
                    end
                    if nearK then
                        local since = Pd.firedT and (now - Pd.firedT) or nil
                        local why
                        local keepRes = false
                        if since and since <= 1.0 then
                            if since < 0.25 then why = ("TELAT: parry ditembak %.2fs sebelum hit (parry belum nyala / anim killer telat kebaca)"):format(since)
                            else why = ("tembus: parry ditembak %.2fs sebelum hit"):format(since) keepRes = true end
                        elseif (Pd.whyK and now - (Pd.whyKT or 0) < 1.5) or (Pd.nfWhy and now - (Pd.nfT or 0) < 1.5) then
                            local wOK = Pd.whyK and now - (Pd.whyKT or 0) < 1.5
                            local nOK = Pd.nfWhy and now - (Pd.nfT or 0) < 1.5
                            if nOK and (not wOK or (Pd.nfT or 0) >= (Pd.whyKT or 0)) then why = "ga bisa nembak: " .. tostring(Pd.nfWhy)
                            else why = "di-skip: " .. Pd.whyK end
                        else why = "ga ada anim serang ke-detect (anim belum dikenal?)" end
                        Pd.hitNotifT = now
                        if not keepRes then Pd.res, Pd.resT = "KENA HIT, " .. why, now end
                        plog("HIT DIAG |", why)
                        notify("Auto parry: kena hit", why)
                    end
                end
            end
            if best and S.parry.learn and not (learned[best.id] or ATTACK_ANIMS[best.id]) then
                hits[best.id] = (hits[best.id] or 0) + 1
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
        if P.on then
            local nowC = os.clock()
            P.inClose = P.inClose or setmetatable({}, {__mode = "k"})
            for _, k in ipairs(ks) do
                local dC = (hrp.Position - k.hrp.Position).Magnitude
                if dC <= 4 then
                    if not P.inClose[k.char] then P.inClose[k.char] = nowC end
                elseif dC > 5 then
                    P.inClose[k.char] = nil
                end
            end
        end
        if P.close and P.on then
            local nowP = os.clock()
            if nowP - (P.closeT or 0) > 1.0 and nowP - (P.lastHitT or 0) > 3.0 and nowP - (P.lastAtkT or 0) > 3.0 then
                for _, k in ipairs(ks) do
                    local ck = k.char
                    if ck:GetAttribute("IsChasing") and ck:GetAttribute("ChaseTargetUserId") == lp.UserId
                        and not (ck:GetAttribute("IsCarrying") or ck:GetAttribute("Immobile") or ck:GetAttribute("IsStunned")) then
                        local off = hrp.Position - k.hrp.Position
                        local d = off.Magnitude
                        if d > 0 and d <= P.closeR then
                            local u = off.Unit
                            local closing = (k.hrp.AssemblyLinearVelocity - hrp.AssemblyLinearVelocity):Dot(u)
                            local adot = aimDot(aimOf(k), k.hrp.Position, hrp.Position)
                            if closing > -8 and not nearInteract(k, u) then
                                P.closeT = nowP
                                plog("CLOSE-FIRE", k.char.Name, (" | %.1fm | closing %.1f | dot %.2f | ping %.3f"):format(d, closing, adot, ping))
                                tryFire("dekat", k)
                                break
                            end
                        end
                    end
                end
            end
        end
        if P.pre and P.on then
            local nowP = os.clock()
            if nowP - (P.preT or 0) > 1.0 and nowP - (P.lastHitT or 0) > 1.0 then
                for _, k in ipairs(ks) do
                    local ck = k.char
                    if ck:GetAttribute("IsChasing") and ck:GetAttribute("ChaseTargetUserId") == lp.UserId
                        and not (ck:GetAttribute("IsCarrying") or ck:GetAttribute("Immobile") or ck:GetAttribute("IsStunned")) then
                        local off = hrp.Position - k.hrp.Position
                        local d = off.Magnitude
                        if d > 0 and d <= 12 then
                            local u = off.Unit
                            local closing = (k.hrp.AssemblyLinearVelocity - hrp.AssemblyLinearVelocity):Dot(u)
                            local adot = aimDot(aimOf(k), k.hrp.Position, hrp.Position)
                            if (d <= 5.5 or (closing > 3 and d / closing <= 0.35 + ping)) and adot >= 0.5 and not nearInteract(k, u) then
                                P.preT = nowP
                                plog("PRE-FIRE", k.char.Name, ("| %.1fm | closing %.1f | dot %.2f | ping %.3f"):format(d, closing, adot, ping))
                                tryFire("preemptive", k)
                                break
                            end
                        end
                    end
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
    local RING_MAX, DASH_W, DASH_H = 64, 0.3, 0.12
    local ring = {folder = Instance.new("Folder"), pool = {}, act = {}, cfs = {}, n = 0, len = 0, a = 0, hot = 0,
        near = false, inZone = false, spin = 0, tr = -1, col = nil}
    ring.folder.Name = tostring(math.random(1000000, 9999999))
    S.parryCircle = ring.folder
    for i = 1, RING_MAX do
        local p = Instance.new("Part")
        p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
        p.Material = Enum.Material.Neon
        p.Transparency = 1
        p.Size = Vector3.new(1, DASH_H, DASH_W)
        ring.pool[i] = p
    end
    local function ringCount(n)
        ring.n, ring.len, ring.tr, ring.col = n, 0, -1, nil
        ring.act, ring.cfs = {}, {}
        for i = 1, RING_MAX do
            local p = ring.pool[i]
            if i <= n then
                ring.act[i] = p
                p.Parent = ring.folder
            else
                p.Parent = nil
            end
        end
    end
    local ringKs, ringT, ringSelfK = {}, 0, false
    -- circle is visual only: auto parry reads S.parry.dist directly and never touches this
    track(RS.RenderStepped:Connect(function(dt)
        pcall(function()
            local P = S.parry
            local ch = lp.Character
            local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
            local hum = ch and ch:FindFirstChildOfClass("Humanoid")
            local cam = workspace.CurrentCamera
            if not (hrp and hum and cam) then
                ring.a = 0
                if ring.folder.Parent then ring.folder.Parent = nil end
                return
            end
            local r = P.circR or P.dist
            local want = false
            if P.circle and not S.lobby and hum.Health > 0 then
                local now = os.clock()
                if now - ringT > 0.12 then
                    ringT = now
                    ringSelfK = roleOf(lp) == "killer"
                    ringKs = getKillers()
                end
                if not ringSelfK then
                    local nd, p0 = math.huge, hrp.Position
                    for _, k in ipairs(ringKs) do
                        if k.char ~= ch and k.hrp.Parent then
                            local d = (k.hrp.Position - p0).Magnitude
                            if d < nd then nd = d end
                        end
                    end
                    local show = P.circShow or 8
                    ring.near = nd <= r + (ring.near and show + 4 or show)
                    ring.inZone = nd <= r
                    want = ring.near
                end
            else
                ring.near, ring.inZone = false, false
            end
            local target = want and 1 or 0
            if ring.a ~= target then
                ring.a = ring.a + (target - ring.a) * math.min(1, dt * (want and 10 or 7))
                if math.abs(target - ring.a) < 0.01 then ring.a = target end
            end
            if ring.a <= 0 then
                if ring.folder.Parent then ring.folder.Parent = nil end
                return
            end
            if ring.folder.Parent ~= cam then ring.folder.Parent = cam end
            local n = math.clamp(math.floor(r * 2.6 + 0.5), 20, RING_MAX)
            if n ~= ring.n then ringCount(n) end
            local act, cfs = ring.act, ring.cfs
            ring.hot = ring.hot + ((ring.inZone and want) and 1 - ring.hot or -ring.hot) * math.min(1, dt * 8)
            local e = ring.a * ring.a * (3 - 2 * ring.a)
            local tr = 1 - (1 - (0.3 - 0.22 * ring.hot)) * e
            if math.abs(tr - ring.tr) > 0.004 then
                ring.tr = tr
                for i = 1, n do act[i].Transparency = tr end
            end
            if P.color ~= ring.col then
                ring.col = P.color
                for i = 1, n do act[i].Color = P.color end
            end
            local step = 2 * math.pi / n
            local len = 2 * r * math.sin(step * 0.55 / 2)
            if math.abs(len - ring.len) > 0.005 then
                ring.len = len
                local sz = Vector3.new(len, DASH_H, DASH_W)
                for i = 1, n do act[i].Size = sz end
            end
            ring.spin = (ring.spin + dt * 0.3) % (2 * math.pi)
            local c = hrp.Position - Vector3.new(0, hrp.Size.Y / 2 + hum.HipHeight - 0.08, 0)
            for i = 1, n do
                local ang = ring.spin + (i - 1) * step
                local s, co = math.sin(ang), math.cos(ang)
                -- X axis = tangent, Y = up, so each dash lies flat along the ring
                cfs[i] = CFrame.fromMatrix(Vector3.new(c.X + co * r, c.Y, c.Z + s * r), Vector3.new(-s, 0, co), Vector3.yAxis)
            end
            if not pcall(workspace.BulkMoveTo, workspace, act, cfs, Enum.BulkMoveMode.FireCFrameChanged) then
                for i = 1, n do act[i].CFrame = cfs[i] end
            end
        end)
    end))
end parryInit() end
do
    -- Silent aim Twist of Fate: ganti aimDirection milik game (modul), tanpa hook remote
    S.sa = {on = false, radius = 150, maxDist = 150, maxAngle = 180, flat = false, predict = false, circle = true, calls = 0, angleMode = true, fovAngle = 120}
    local cSA = tSurv:Group("Silent aim (Twist of Fate)", 1)
    local saLbl = cSA:Label("Status: OFF")
    local pendingTxt
    local function saSay(t) pendingTxt = t end
    -- GUI cuma disentuh dari thread ini (thread game ga punya izin)
    track(RS.Heartbeat:Connect(function()
        if pendingTxt then saLbl.Text = pendingTxt pendingTxt = nil end
    end))

    local saGui = Instance.new("ScreenGui")
    saGui.Name = "JinSAFov"
    saGui.ResetOnSpawn = false
    saGui.IgnoreGuiInset = true
    saGui.DisplayOrder = 999
    attach(saGui)
    track({Disconnect = function() pcall(function() saGui:Destroy() end) end})
    local ring = Instance.new("Frame")
    ring.AnchorPoint = Vector2.new(0.5, 0.5)
    ring.Position = UDim2.new(0.5, 0, 0.5, 0)
    ring.BackgroundTransparency = 1
    ring.Active = false
    pcall(function() ring.Interactable = false end)
    ring.Visible = false
    ring.Parent = saGui
    Instance.new("UICorner", ring).CornerRadius = UDim.new(1, 0)
    local saStroke = Instance.new("UIStroke", ring)
    saStroke.Color = Color3.new(1, 1, 1)
    saStroke.Thickness = 1.5
    saStroke.Transparency = 0.25
    local function updRing()
        ring.Size = UDim2.fromOffset(S.sa.radius * 2, S.sa.radius * 2)
        ring.Visible = S.sa.on and S.sa.circle and not S.sa.angleMode
    end

    cSA:Toggle("SA_On", "Silent aim", false, function(v)
        S.sa.on = v
        saSay(v and "ON, nunggu tembakan" or "Status: OFF")
        updRing()
    end)
    cSA:Slider("SA_Radius", "Ukuran lingkaran (px)", 40, 400, 150, 10, function(v) S.sa.radius = v updRing() end)
    cSA:Toggle("SA_Circle", "Tampilkan lingkaran FOV", true, function(v) S.sa.circle = v updRing() end)
    cSA:Slider("SA_Dist", "Jarak max killer", 20, 300, 150, 10, function(v) S.sa.maxDist = v end, "m")
    cSA:Dropdown("SA_Area", "Area bidik", {"Sudut kamera", "Lingkaran layar"}, "Sudut kamera", function(v) S.sa.angleMode = v == "Sudut kamera" updRing() end)
    cSA:Slider("SA_Angle", "Sudut bidik (derajat)", 20, 360, 120, 10, function(v) S.sa.fovAngle = v end)

    local function dot3(a, b) return a.X * b.X + a.Y * b.Y + a.Z * b.Z end
    local function aimPart(char, hrp)
        -- selalu lengan kanan (R6 = "Right Arm", R15 = "RightUpperArm"); kalau ga ada, jatuh ke HRP
        for _, n in ipairs({"Right Arm", "RightUpperArm", "RightLowerArm", "RightHand"}) do
            local a = char:FindFirstChild(n)
            if a and a:IsA("BasePart") then return a end
        end
        return hrp
    end
    local function muzzlePos()
        local ch = lp.Character
        local tof = ch and ch:FindFirstChild("Twist of Fate")
        local arm = tof and tof:FindFirstChild("Right Arm")
        local gun
        if arm then
            for _, c in ipairs(arm:GetChildren()) do
                if c:IsA("Model") then gun = c break end
            end
        end
        gun = gun or (ch and ch:FindFirstChild("gun", true))
        if not gun then return nil end
        for _, n in ipairs({"SmokePart", "barrel"}) do
            local p = gun:FindFirstChild(n, true)
            if p and p:IsA("BasePart") then return p.Position end
        end
        local ok, pos = pcall(function() return gun:GetPivot().Position end)
        return ok and pos or nil
    end
    local function leadPoint(part, origin)
        local hrp = part.Parent and part.Parent:FindFirstChild("HumanoidRootPart")
        local v = hrp and hrp.AssemblyLinearVelocity or Vector3.zero
        local pos = part.Position
        if v.Magnitude < 1 then return pos end
        local t = (pos - origin).Magnitude / 800
        local p = pos
        for _ = 1, 3 do
            p = pos + v * t
            t = (p - origin).Magnitude / 800
        end
        return p
    end
    -- true kalau part masuk area bidik; angka kedua = jarak ke tengah (px atau derajat), dipakai buat milih yang paling dekat
    local function inAim(cam, part, c)
        if S.sa.angleMode then
            local dir = part.Position - cam.CFrame.Position
            if dir.Magnitude < 0.1 then return true, 0 end
            local a = math.deg(math.acos(math.clamp(dot3(cam.CFrame.LookVector, dir.Unit), -1, 1)))
            return a <= S.sa.fovAngle / 2, a
        end
        local v, on = cam:WorldToViewportPoint(part.Position)
        if not (on and v.Z > 0) then return false end
        local d = (Vector2.new(v.X, v.Y) - c).Magnitude
        return d <= S.sa.radius, d
    end
    -- killer asli: Team "Killer" / atribut IsKiller, Role (sama kayak yang dipakai game).
    -- getKillers() itu nebak longgar dari nama atribut apa aja, makanya survivor kadang ikut kebaca killer.
    -- Deteksi longgar cuma jadi cadangan kalau yang ketat ga nemu siapa-siapa.
    local function isKillerStrict(p)
        if p.Team then
            local t = p.Team.Name:lower()
            if t:find("survivor", 1, true) then return false end
            if t:find("killer", 1, true) or t:find("slasher", 1, true) then return true end
        end
        local ch = p.Character
        if ch and (ch:GetAttribute("IsKiller") == true or ch:GetAttribute("Role") == "Killer") then return true end
        return p:GetAttribute("IsKiller") == true or p:GetAttribute("Role") == "Killer"
    end
    local function strictKillers()
        local list = {}
        for _, p in ipairs(Players:GetPlayers()) do
            local kc = p.Character
            local kh = kc and kc:FindFirstChild("HumanoidRootPart")
            if kh and isKillerStrict(p) then list[#list + 1] = {char = kc, hrp = kh} end
        end
        if #list > 0 then return list end
        return getKillers()
    end
    S.strictKillers = strictKillers
    -- killer harus ada di area bidik (sudut kamera atau lingkaran layar); yang paling dekat tengah dipilih
    local function pickTarget()
        local cam = workspace.CurrentCamera
        local myCh = lp.Character
        local myHrp = myCh and myCh:FindFirstChild("HumanoidRootPart")
        if not (cam and myHrp) then return nil, "kamera/karakter ga ada" end
        local c = cam.ViewportSize / 2
        local best, bestD, any = nil, nil, false
        for _, k in ipairs(strictKillers()) do
            if k.char ~= myCh then
                any = true
                local part = aimPart(k.char, k.hrp)
                if (part.Position - myHrp.Position).Magnitude <= S.sa.maxDist then
                    local ok, d = inAim(cam, part, c)
                    if ok and (not bestD or d < bestD) then best, bestD = part, d end
                end
            end
        end
        if not best then return nil, any and "killer di luar area bidik/jarak" or "killer ga kedeteksi" end
        return best
    end
    local function computeDir()
        local part, why = pickTarget()
        if not part then return nil, nil, why end
        local origin = muzzlePos()
        if not origin then
            local h = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
            origin = h and h.Position
        end
        if not origin then return nil, nil, "asal arah ga ketemu" end
        local tp = S.sa.predict and leadPoint(part, origin) or part.Position
        local d = tp - origin
        if S.sa.flat then d = Vector3.new(d.X, 0, d.Z) end
        if d.Magnitude < 0.01 then return nil, nil, "arah nol" end
        return d.Unit, part.Parent and part.Parent.Name or "?", nil
    end

    -- pasang ke modul pistol; dicoba terus tiap 2 detik (modul baru ada setelah masuk match / ronde ganti)
    local patched = {}
    local function makeWrapper(orig)
        return function(...)
            S.sa.calls = S.sa.calls + 1
            if not (running and S.sa.on) then return orig(...) end
            local r = table.pack(orig(...))
            local okC, d, who, why = pcall(computeDir)
            local o = r[1]
            if okC and d and typeof(o) == "Vector3" and o.Magnitude > 0.01 then
                local ang = math.deg(math.acos(math.clamp(dot3(o, d) / o.Magnitude, -1, 1)))
                if ang <= S.sa.maxAngle then
                    saSay(("Diarahin ke %s (geser %d derajat) [dipanggil %dx]"):format(tostring(who), math.floor(ang), S.sa.calls))
                    return d
                end
                saSay("Lolos asli: geser " .. math.floor(ang) .. " derajat > batas [dipanggil " .. S.sa.calls .. "x]")
            else
                saSay("Lolos asli: " .. tostring(okC and (why or ("arah asli bukan Vector3: " .. typeof(o))) or d) .. " [dipanggil " .. S.sa.calls .. "x]")
            end
            return table.unpack(r, 1, r.n)
        end
    end
    local function install()
        local m = game:GetService("ReplicatedStorage"):FindFirstChild("Modules")
        m = m and m:FindFirstChild("Items")
        m = m and m:FindFirstChild("TwistOfFate")
        m = m and m:FindFirstChild("TwistoffateEffects")
        if not m then return false, "modul pistol belum ada (masuk match dulu)" end
        local ok, mod = pcall(require, m)
        if not ok or type(mod) ~= "table" or type(mod.aimDirection) ~= "function" then return false, "aimDirection ga ada" end
        local rec = patched[mod]
        if rec and mod.aimDirection == rec.wrapper then return true end
        local orig = mod.aimDirection
        local w = makeWrapper(orig)
        patched[mod] = {orig = orig, wrapper = w}
        mod.aimDirection = w
        return true, "baru"
    end
    task.spawn(function()
        local was = false
        while running do
            local ok, a, b = pcall(install)
            if ok and a then
                if b == "baru" or not was then
                    saSay(S.sa.on and "ON, nunggu tembakan" or "Status: OFF (modul pistol kepasang)")
                end
                was = true
            else
                was = false
                saSay("Menunggu modul pistol: " .. tostring(ok and b or a))
            end
            task.wait(2)
        end
    end)
    S.saRestore = function()
        for mod, rec in pairs(patched) do
            pcall(function() if mod.aimDirection == rec.wrapper then mod.aimDirection = rec.orig end end)
        end
    end
end
end
do
local AL2 = {}
do
    local Terrain = workspace:FindFirstChildOfClass("Terrain")
    local flags = S.al
    local orig = setmetatable({}, {__mode = "k"})
    local held = {sky = {}, surf = {}}
    local charSet = setmetatable({}, {__mode = "k"})
    local gsave = {}
    local sweepId = 0
    local WHITE3 = Color3.new(1, 1, 1)
    local SMOOTH = Enum.Material.SmoothPlastic
    local VEG_GRASS = {"grass", "rumput", "weed", "fern", "flower", "bunga"}
    local VEG_TREE = {"tree", "leaf", "leaves", "foliage", "bush", "pohon", "daun", "palm", "branch", "canopy", "shrub", "hedge"}
    local MATS = {}
    if Terrain then
        for _, m in ipairs(Enum.Material:GetEnumItems()) do
            if m ~= Enum.Material.Air and m ~= Enum.Material.Water then
                local ok = pcall(function() return Terrain:GetMaterialColor(m) end)
                if ok then MATS[#MATS + 1] = m end
            end
        end
    end
    local function anyOn()
        return flags.sky or flags.tex or flags.white or flags.grass or flags.trees or flags.lights or flags.perf
    end
    local function skip(i)
        local p = i
        while p and p ~= workspace do
            if charSet[p] or p == espFolder or p == coneFolder then return true end
            p = p.Parent
        end
        local cam = workspace.CurrentCamera
        return cam ~= nil and i:IsDescendantOf(cam)
    end
    local function save(i, prop)
        local o = orig[i]
        if not o then o = {} orig[i] = o end
        if o[prop] == nil then o[prop] = i[prop] end
    end
    local function nameHas(n, list)
        n = string.lower(n)
        for _, w in ipairs(list) do
            if string.find(n, "%f[%a]" .. w) then return true end
        end
        return false
    end
    local function vegMatch(i, list)
        local p, depth = i, 0
        while p and p ~= workspace and depth < 4 do
            if nameHas(p.Name, list) then return true end
            p = p.Parent
            depth = depth + 1
        end
        return false
    end
    local function applyOne(i)
        if not anyOn() then return end
        local cn = i.ClassName
        if cn == "Sky" or cn == "Atmosphere" or cn == "Clouds" then
            if flags.sky and i.Name ~= "JinBlankSky" then
                held.sky[#held.sky + 1] = {inst = i, parent = i.Parent}
                i.Parent = nil
            end
            return
        end
        if i:IsA("BasePart") then
            if i == Terrain then return end
            if not (flags.white or flags.perf or flags.tex or flags.grass or flags.trees) then return end
            if skip(i) then return end
            if flags.white and (i.Color ~= WHITE3 or i.Material ~= SMOOTH or i.Reflectance ~= 0 or i.MaterialVariant ~= "") then
                save(i, "Color") save(i, "Material") save(i, "Reflectance") save(i, "MaterialVariant")
                i.MaterialVariant = ""
                i.Color = WHITE3
                i.Material = SMOOTH
                i.Reflectance = 0
            end
            local hide = (flags.grass and vegMatch(i, VEG_GRASS)) or (flags.trees and vegMatch(i, VEG_TREE))
            if hide then save(i, "Transparency") i.Transparency = 1 end
            if flags.perf or hide then save(i, "CastShadow") i.CastShadow = false end
            if flags.perf and i:IsA("MeshPart") then
                save(i, "RenderFidelity")
                i.RenderFidelity = Enum.RenderFidelity.Performance
            end
            if (flags.tex or flags.white) and i:IsA("MeshPart") and i.TextureID ~= "" then
                save(i, "TextureID")
                i.TextureID = ""
            end
        elseif i:IsA("Decal") then
            if (flags.tex or flags.white) and not skip(i) then save(i, "Transparency") i.Transparency = 1 end
        elseif cn == "SurfaceAppearance" then
            if (flags.tex or flags.white) and not skip(i) then
                held.surf[#held.surf + 1] = {inst = i, parent = i.Parent}
                i.Parent = nil
            end
        elseif cn == "SpecialMesh" then
            if (flags.tex or flags.white) and not skip(i) then
                if i.TextureId ~= "" then save(i, "TextureId") i.TextureId = "" end
                if flags.white and i.VertexColor ~= Vector3.new(1, 1, 1) then save(i, "VertexColor") i.VertexColor = Vector3.new(1, 1, 1) end
            end
        elseif cn == "PointLight" or cn == "SpotLight" or cn == "SurfaceLight" then
            if flags.lights and i.Enabled and not skip(i) then save(i, "Enabled") i.Enabled = false end
        end
    end
    local function restoreProps(props, filter)
        local list = {}
        for inst in pairs(orig) do list[#list + 1] = inst end
        task.spawn(function()
            for idx, inst in ipairs(list) do
                local o = orig[inst]
                if o and inst.Parent and (not filter or filter(inst)) then
                    for _, pr in ipairs(props) do
                        if o[pr] ~= nil then
                            pcall(function() inst[pr] = o[pr] end)
                            o[pr] = nil
                        end
                    end
                end
                if idx % 400 == 0 then task.wait() end
            end
        end)
    end
    local function heldRestore(kind)
        local list = held[kind]
        held[kind] = {}
        for _, h in ipairs(list) do
            if h.parent and h.parent.Parent then pcall(function() h.inst.Parent = h.parent end) end
        end
    end
    local function restoreTex()
        restoreProps({"TextureID", "TextureId", "VertexColor"})
        restoreProps({"Transparency"}, function(i) return i:IsA("Decal") end)
        heldRestore("surf")
    end
    local WATER = {"WaterWaveSize", "WaterWaveSpeed", "WaterReflectance"}
    local function applyGlobal()
        if Terrain then
            if flags.grass then
                if gsave.decor == nil then pcall(function() gsave.decor = Terrain.Decoration end) end
                pcall(function() Terrain.Decoration = false end)
                pcall(function() if sethiddenproperty then sethiddenproperty(Terrain, "Decoration", false) end end)
            elseif gsave.decor ~= nil then
                local d = gsave.decor
                gsave.decor = nil
                pcall(function() Terrain.Decoration = d end)
            end
            if flags.white then
                if not gsave.tcol then
                    gsave.tcol = {}
                    for _, m in ipairs(MATS) do pcall(function() gsave.tcol[m] = Terrain:GetMaterialColor(m) end) end
                end
                for _, m in ipairs(MATS) do pcall(function() Terrain:SetMaterialColor(m, WHITE3) end) end
            elseif gsave.tcol then
                local t = gsave.tcol
                gsave.tcol = nil
                for m, c in pairs(t) do pcall(function() Terrain:SetMaterialColor(m, c) end) end
            end
            if flags.white then
                if gsave.wcol == nil then pcall(function() gsave.wcol = Terrain.WaterColor end) end
                pcall(function() Terrain.WaterColor = WHITE3 end)
            elseif gsave.wcol ~= nil then
                local w = gsave.wcol
                gsave.wcol = nil
                pcall(function() Terrain.WaterColor = w end)
            end
            if flags.perf then
                if not gsave.water then
                    gsave.water = {}
                    for _, pr in ipairs(WATER) do pcall(function() gsave.water[pr] = Terrain[pr] end) end
                end
                for _, pr in ipairs(WATER) do pcall(function() Terrain[pr] = 0 end) end
            elseif gsave.water then
                local w = gsave.water
                gsave.water = nil
                for pr, v in pairs(w) do pcall(function() Terrain[pr] = v end) end
            end
        end
        if flags.white then
            if not gsave.lt then
                gsave.lt = {top = Lighting.ColorShift_Top, bot = Lighting.ColorShift_Bottom}
            end
            pcall(function()
                Lighting.ColorShift_Top = Color3.new(0, 0, 0)
                Lighting.ColorShift_Bottom = Color3.new(0, 0, 0)
            end)
        elseif gsave.lt then
            local l = gsave.lt
            gsave.lt = nil
            pcall(function()
                Lighting.ColorShift_Top, Lighting.ColorShift_Bottom = l.top, l.bot
            end)
        end
        if flags.sky then
            if not (gsave.blank and gsave.blank.Parent) then
                pcall(function()
                    local sk = Instance.new("Sky")
                    sk.Name = "JinBlankSky"
                    sk.SkyboxBk, sk.SkyboxDn, sk.SkyboxFt, sk.SkyboxLf, sk.SkyboxRt, sk.SkyboxUp = "", "", "", "", "", ""
                    sk.StarCount = 0
                    sk.CelestialBodiesShown = false
                    sk.Parent = Lighting
                    gsave.blank = sk
                end)
            end
        elseif gsave.blank then
            pcall(function() gsave.blank:Destroy() end)
            gsave.blank = nil
        end
    end
    local function sweepAll()
        sweepId = sweepId + 1
        local my = sweepId
        task.spawn(function()
            for _, i in ipairs(Lighting:GetDescendants()) do pcall(applyOne, i) end
            local list = workspace:GetDescendants()
            for idx, i in ipairs(list) do
                if not running or sweepId ~= my then return end
                pcall(applyOne, i)
                if idx % 400 == 0 then task.wait() end
            end
        end)
    end
    function AL2.set(name, v)
        flags[name] = v and true or false
        if v then
            applyGlobal()
            sweepAll()
            return
        end
        if name == "white" then
            restoreProps({"Color", "Material", "Reflectance", "MaterialVariant"}, function(i) return i:IsA("BasePart") end)
            if not flags.tex then restoreTex() end
        elseif name == "perf" then
            restoreProps({"RenderFidelity"})
            if not (flags.grass or flags.trees) then restoreProps({"CastShadow"}) end
        elseif name == "tex" then
            if not flags.white then restoreTex() end
        elseif name == "grass" or name == "trees" then
            restoreProps({"Transparency"}, function(i) return i:IsA("BasePart") end)
            if not flags.perf then restoreProps({"CastShadow"}) end
        elseif name == "lights" then
            restoreProps({"Enabled"}, function(i) return string.find(i.ClassName, "Light") ~= nil end)
        elseif name == "sky" then
            heldRestore("sky")
        end
        applyGlobal()
        if flags.grass or flags.trees or flags.perf or flags.white or flags.tex or flags.lights then task.delay(1.5, sweepAll) end
    end
    function AL2.restoreAll()
        for _, n in ipairs({"sky", "tex", "white", "grass", "trees", "lights", "perf"}) do
            if flags[n] then AL2.set(n, false) end
        end
        if AL2.fpsChanged and setfpscap then pcall(setfpscap, AL2.fpsOrig or 60) AL2.fpsChanged = false end
    end
    track(workspace.DescendantAdded:Connect(function(i) if anyOn() then pcall(applyOne, i) end end))
    track(Lighting.DescendantAdded:Connect(function(i) if flags.sky then pcall(applyOne, i) end end))
    local function onChar(c)
        charSet[c] = true
        task.defer(function()
            for _, i in ipairs(c:GetDescendants()) do
                local o = orig[i]
                if o then
                    for pr, v in pairs(o) do pcall(function() i[pr] = v end) end
                    orig[i] = nil
                end
            end
        end)
    end
    for _, pl in ipairs(Players:GetPlayers()) do
        track(pl.CharacterAdded:Connect(onChar))
        if pl.Character then charSet[pl.Character] = true end
    end
    track(Players.PlayerAdded:Connect(function(pl) track(pl.CharacterAdded:Connect(onChar)) end))
    task.spawn(function()
        local n = 0
        while running do
            task.wait(2)
            n = n + 1
            if flags.sky then
                for _, c in ipairs(Lighting:GetChildren()) do pcall(applyOne, c) end
                pcall(applyGlobal)
            end
            if n % 4 == 0 and (flags.white or flags.lights) then sweepAll() end
        end
    end)
end
local cView = tMisc:Group("View", 1)
cView:Toggle("FOV_On", "Custom FOV", false, function(v)
    S.fov.on = v
    if not v and S.fov.orig then
        local o = S.fov.orig
        S.fov.orig = nil
        pcall(function() workspace.CurrentCamera.FieldOfView = o end)
    end
end)
cView:Slider("FOV_Val", "FOV", 30, 120, 70, 1, function(v) S.fov.val = v end)
cView:Toggle("AR_On", "Rasio layar custom", false, function(v) S.ar.on = v end)
cView:Slider("AR_Val", "Rasio layar", 0.3, 1.5, 0.75, 0.05, function(v) S.ar.ratio = v end)
cView:Label("Kecil = melebar, besar = tinggi.")
cView:Dropdown("AR_Tpl", "Template rasio", {"Pilih template", "Normal (1.00)", "Stretch ringan (0.85)", "4:3 stretch (0.75)", "Stretch sedang (0.65)", "Stretch berat (0.55)", "Gepeng banget (0.45)", "Tinggi / renggang (1.25)"}, "Pilih template", function(v)
    local n = tonumber(string.match(tostring(v), "%(([%d%.]+)%)"))
    local r = Reg["AR_Val"]
    if n and r then r.set(n) end
end)
Reg["AR_Tpl"] = nil
local cLight = tMisc:Group("Fullbright", 1)
cLight:Toggle("FB_On", "Fullbright", false, function(v) S.fb.on = v if v then fbSave() else fbRestore() end end)
cLight:Slider("FB_Bright", "Brightness", 1, 5, 2, 1, function(v) S.fb.bright = v end)
local cAL = tMisc:Group("Anti lag: efek", 2)
local cAM = tMisc:Group("Anti lag: map", 2)
cAL:Toggle("AL_Particles", "Matiin partikel / api", false,
    function(v) S.al.particles = v if v then particlesScan() else particlesRestore() end end)
cAL:Toggle("AL_PostFX", "Matiin bloom / blur / DOF", false,
    function(v) S.al.post = v if v then postSweep() else postRestore() end end)
cAL:Toggle("AL_Shadows", "Matiin shadow", false,
    function(v) S.al.shadows = v if v then shadowsSave() else shadowsRestore() end end)
cAL:Toggle("AL_Quality", "Render quality terendah", false, function(v) S.al.quality = v setQuality(v) end)
cAM:Toggle("AL_Sky", "Hapus skybox & awan", false, function(v) AL2.set("sky", v) end)
cAM:Toggle("AL_Tex", "Hapus tekstur", false, function(v) AL2.set("tex", v) end)
cAM:Toggle("AL_White", "Semua putih (kecuali player)", false, function(v) AL2.set("white", v) end)
cAM:Toggle("AL_Grass", "Hapus rumput", false, function(v) AL2.set("grass", v) end)
cAM:Toggle("AL_Trees", "Hapus pohon & daun", false, function(v) AL2.set("trees", v) end)
cAM:Toggle("AL_Lights", "Matiin lampu", false, function(v) AL2.set("lights", v) end)
cAM:Toggle("AL_Perf", "Ringanin part & air", false, function(v) AL2.set("perf", v) end)
cAL:Slider("AL_FPS", "FPS cap (0 = jangan ubah)", 0, 240, 0, 10, function(v)
    if v > 0 and setfpscap then
        if not AL2.fpsChanged then
            AL2.fpsOrig = nil
            if getfpscap then
                local okc, cur = pcall(getfpscap)
                if okc and type(cur) == "number" and cur > 0 then AL2.fpsOrig = cur end
            end
        end
        AL2.fpsChanged = true
        pcall(setfpscap, v)
    elseif v == 0 and AL2.fpsChanged and setfpscap then
        AL2.fpsChanged = false
        pcall(setfpscap, AL2.fpsOrig or 60)
    end
end)
local AL_IDS = {"AL_Particles", "AL_PostFX", "AL_Shadows", "AL_Quality", "AL_Sky", "AL_Tex", "AL_White", "AL_Grass", "AL_Trees", "AL_Lights", "AL_Perf"}
cAM:Button("SUPER ANTI LAG: nyalain semua", function()
    for _, id in ipairs(AL_IDS) do local r = Reg[id] if r then r.set(true) end end
    notify("Anti lag", "Semua nyala")
end)
cAM:Button("Matiin semua anti lag", function()
    for _, id in ipairs(AL_IDS) do local r = Reg[id] if r then r.set(false) end end
    notify("Anti lag", "Semua mati")
end)
do
    -- Silent Veil: lemparan tombak Veil otomatis ngarah ke survivor (hook remote SpearThrow).
    -- Arah dikunci pas tombak dilempar (prediksi gerak + kompensasi gravitasi), bukan belok di tengah jalan.
    S.sv = {on = false, angle = 180, range = 400, predict = true, los = true}
    local SPEAR_SPEED, DROP, SPAWN_OFF = 180, 0.5, 3
    local cSV = tKill:Group("Silent Veil (tombak)", 1)
    local svLbl = cSV:Label("Status: OFF")
    local pendingTxt
    local function svSay(t) pendingTxt = t end
    -- GUI cuma disentuh dari thread ini (hook jalan di thread game)
    track(RS.Heartbeat:Connect(function()
        if pendingTxt then svLbl.Text = pendingTxt pendingTxt = nil end
    end))
    cSV:Toggle("SV_On", "Silent Veil", false, function(v)
        S.sv.on = v
        svSay(v and "ON, nunggu lemparan tombak" or "Status: OFF")
    end)
    cSV:Slider("SV_Angle", "Sudut bidik (derajat)", 20, 360, 180, 10, function(v) S.sv.angle = v end)
    cSV:Slider("SV_Range", "Jarak max target", 50, 500, 400, 10, function(v) S.sv.range = v end, "m")
    cSV:Toggle("SV_Predict", "Prediksi gerak survivor", true, function(v) S.sv.predict = v end)
    cSV:Toggle("SV_LOS", "Utamakan yang ga ketutup", true, function(v) S.sv.los = v end)
    cSV:Label("Dipakai pas main jadi Veil. Arah tombak dikunci pas dilempar.")

    local function alive(ch)
        local h = ch and ch:FindFirstChildOfClass("Humanoid")
        return h and h.Health > 0
    end
    local function veilEquipped(ch)
        if not ch then return false end
        if ch:GetAttribute("MorphedKiller") == "Veil" or ch:GetAttribute("Veil") == true then return true end
        if ch:GetAttribute("spearmode") == true or ch:GetAttribute("VeilSpearEquipped") == true then return true end
        return ch:FindFirstChild("Spear") ~= nil
    end
    local rayP = RaycastParams.new()
    rayP.FilterType = Enum.RaycastFilterType.Exclude
    -- true kalau ada tembok/objek (bukan karakter) di antara origin dan target
    local function blocked(origin, hrp)
        local ex = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Character then ex[#ex + 1] = p.Character end
        end
        rayP.FilterDescendantsInstances = ex
        local ok, r = pcall(function() return workspace:Raycast(origin, hrp.Position - origin, rayP) end)
        return ok and r ~= nil
    end
    -- target = survivor yang paling pas sama arah kamera (bukan yang paling dekat), jadi lemparan ga tiba-tiba muter ke orang lain
    local function pickTarget(origin)
        local cam = workspace.CurrentCamera
        local myCh = lp.Character
        local myHrp = myCh and myCh:FindFirstChild("HumanoidRootPart")
        if not (cam and myHrp) then return nil end
        local isK = {}
        for _, k in ipairs(S.strictKillers and S.strictKillers() or getKillers()) do isK[k.char] = true end
        local look = cam.CFrame.LookVector
        local best, bestScore, bestAng, bestDist
        for _, p in ipairs(Players:GetPlayers()) do
            local ch = p.Character
            if p ~= lp and ch and not isK[ch] and alive(ch)
                and not ch:GetAttribute("Immobile") and not ch:GetAttribute("IsHooked") and not ch:GetAttribute("Knocked") then
                local hrp = ch:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local d = (hrp.Position - myHrp.Position).Magnitude
                    local dir = hrp.Position - cam.CFrame.Position
                    if d <= S.sv.range and dir.Magnitude > 0.1 then
                        local ang = math.deg(math.acos(math.clamp(look:Dot(dir.Unit), -1, 1)))
                        if ang <= S.sv.angle / 2 then
                            local score = ang + ((S.sv.los and blocked(origin, hrp)) and 1000 or 0)
                            if not bestScore or score < bestScore then
                                best, bestScore, bestAng, bestDist = hrp, score, ang, d
                            end
                        end
                    end
                end
            end
        end
        return best, bestAng, bestDist
    end
    -- arah lempar dengan prediksi gerak + kompensasi gravitasi
    local function solve(origin, hrp)
        local g = Vector3.new(0, -workspace.Gravity * DROP, 0)
        local vel = S.sv.predict and hrp.AssemblyLinearVelocity or Vector3.zero
        local okP, ping = pcall(function() return lp:GetNetworkPing() end)
        ping = okP and ping * 0.5 or 0.035
        local t = (hrp.Position - origin).Magnitude / SPEAR_SPEED
        local aim = hrp.Position
        for _ = 1, 5 do
            aim = hrp.Position + vel * (t + ping)
            t = math.max(0.04, (aim - origin).Magnitude / SPEAR_SPEED)
        end
        local v = ((aim - origin) - 0.5 * g * t * t) / t
        if v.Magnitude < 0.01 then return nil end
        return v.Unit
    end

    local svOld
    local wrap = newcclosure or function(f) return f end
    if hookmetamethod and getnamecallmethod then
        svOld = hookmetamethod(game, "__namecall", wrap(function(self, ...)
            local method = getnamecallmethod()
            if running and S.sv.on and (method == "FireServer" or method == "fireServer")
                and typeof(self) == "Instance" and self.Name:lower() == "spearthrow"
                and not (checkcaller and checkcaller()) then
                local args = table.pack(...)
                pcall(function()
                    if not veilEquipped(lp.Character) then svSay("Lolos asli: tombak Veil ga kedeteksi") return end
                    local cam = workspace.CurrentCamera
                    local a1 = args[1]
                    local origin
                    if type(a1) == "table" and typeof(a1.Origin) == "Vector3" then origin = a1.Origin
                    elseif typeof(a1) == "Vector3" and typeof(args[2]) == "Vector3" then origin = a1
                    else origin = cam.CFrame.Position + cam.CFrame.LookVector * SPAWN_OFF end
                    local target, ang, dist = pickTarget(origin)
                    if not target then svSay("Lolos asli: ga ada survivor di sudut/jarak") return end
                    local dir = solve(origin, target)
                    if not dir then svSay("Lolos asli: arah ga kehitung") return end
                    if type(a1) == "table" and typeof(a1.Origin) == "Vector3" then
                        a1.Direction = dir
                        if a1.Velocity ~= nil then a1.Velocity = dir * SPEAR_SPEED end
                    elseif typeof(a1) == "Vector3" and typeof(args[2]) == "Vector3" then
                        args[2] = dir
                    elseif typeof(a1) == "Vector3" then
                        args[1] = dir
                    end
                    svSay(("Diarahin ke %s (%d m, geser %d derajat)"):format(tostring(target.Parent and target.Parent.Name), math.floor(dist), math.floor(ang)))
                end)
                setnamecallmethod(method)
                return svOld(self, table.unpack(args, 1, args.n))
            end
            return svOld(self, ...)
        end))
    else
        svSay("hookmetamethod ga ada di executor ini")
    end
    -- sengaja ga re-hook: hook udah pass-through pas running == false (re-hook bisa numpuk layer / rekursi di beberapa executor)
    S.svRestore = function() end
end
do
    local cPred = tKill:Group("Prediksi killer berikutnya", 2)
    local mlbl = cPred:Label("Map: nunggu pengumuman server...")
    local lbl = cPred:Label("Nunggu data...")
    task.spawn(function()
        pcall(function()
            local r = game:GetService("ReplicatedStorage"):WaitForChild("Remotes", 15):WaitForChild("Messages", 15):WaitForChild("Mapinfo", 15)
            if not running then return end
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
do
    -- vignette overlay: hidden by default, no menu entry (matches any GuiObject/ScreenGui named *vignet*)
    local vigSaved = {}
    local function killVig(i)
        local isScreen = i:IsA("ScreenGui")
        if vigSaved[i] or not (isScreen or i:IsA("GuiObject")) then return end
        if not i.Name:lower():find("vignet", 1, true) then return end
        local prop = isScreen and "Enabled" or "Visible"
        vigSaved[i] = {prop = prop, v = i[prop]}
        i[prop] = false
        track(i:GetPropertyChangedSignal(prop):Connect(function()
            if running and i[prop] then i[prop] = false end
        end))
    end
    for _, i in ipairs(pg:GetDescendants()) do pcall(killVig, i) end
    track(pg.DescendantAdded:Connect(function(i) task.defer(pcall, killVig, i) end))
    S.vigRestore = function()
        for i, st in pairs(vigSaved) do pcall(function() i[st.prop] = st.v end) end
    end
end
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
local arLast, arBase, arRatio
track(RS.RenderStepped:Connect(function(dt)
    pcall(updateCone)
    fpsAcc, fpsN = fpsAcc + dt, fpsN + 1
    local c = workspace.CurrentCamera
    if c and S.fov.on then
        if not S.fov.orig then S.fov.orig = c.FieldOfView end
        c.FieldOfView = S.fov.val
    end
    if c and S.ar.on then
        local cf = c.CFrame
        if cf ~= arLast then arBase = cf end
        if arBase and (cf ~= arLast or arRatio ~= S.ar.ratio) then
            arRatio = S.ar.ratio
            arLast = arBase * CFrame.new(0, 0, 0, 1, 0, 0, 0, S.ar.ratio, 0, 0, 0, 1)
            c.CFrame = arLast
        end
    end
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
    pcall(function() if S.saRestore then S.saRestore() end end)
    pcall(function() if S.svRestore then S.svRestore() end end)
    for plr in pairs(pvis) do destroyPlayerVis(plr) end
    for inst in pairs(ovis) do destroyObj(inst) end
    pcall(function() espFolder:Destroy() end)
    pcall(function() coneFolder:Destroy() end)
    pcall(function() if S.parryCircle then S.parryCircle:Destroy() end end)
    S.fb.on, S.al.shadows = false, false
    pcall(fbRestore) pcall(shadowsRestore) pcall(particlesRestore) pcall(postRestore)
    pcall(setQuality, false)
    pcall(AL2.restoreAll)
    if S.fov.orig then
        local o = S.fov.orig
        S.fov.orig = nil
        pcall(function() workspace.CurrentCamera.FieldOfView = o end)
    end
    pcall(S.vigRestore)
    pcall(function() gui:Destroy() end)
    getgenv().JinHub = nil
end
getgenv().JinHub = {Unload = cleanup, Refresh = refreshDash}
end
loadConfig()
loading = false
pcall(refreshDash)
setOpen(true)
notify("Jìn Script", "Loaded")
warn("[jin] v3.9 loaded (patched)")
