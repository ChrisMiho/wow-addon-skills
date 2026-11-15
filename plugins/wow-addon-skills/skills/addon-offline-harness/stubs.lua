-- WoW client stand-ins for running addon Lua under LuaJIT, off the device.
-- Generalised from an offline QuestieDB harness (GPL-3.0). Only what addons
-- commonly touch while loading is here; add a stub when a run fails with
-- "attempt to call/index a nil value" naming a game global.
--
--   local S = dofile(LIB .. "/stubs.lua")
--   S.init(LIB)                         load LibDeflate.lua, decode.lua, metadata.lua from LIB
--   S.install(persona, extra)           (re)install the client globals below
--       persona = { faction = "Alliance"|"Horde", class = "WARRIOR"|..., locale = "enUS" }
--       extra   = { GlobalName = value, ... } more globals, set after the defaults
--   S.loadAddon(tocPath, addonName, opts) -> ns, header
--       load every Lua file the TOC lists, in order, as the game does: each file
--       gets (addonName, ns). opts = { baseDir = dir the TOC's paths resolve
--       against (default: the TOC's folder), gameType = "forever"|"vanilla"|...
--       (needed when the TOC has [AllowLoadGameType ...] lines), reset = { names
--       of globals to clear first, so a reload starts clean } }
--   S.loadFile(path, addonName, ns) -> ns   run one Lua file with (addonName, ns)
--   S.fire(event, ...)                  call OnEvent on every stub frame registered for event
--   S.runTimers()                       run queued C_Timer.After callbacks until none are left
--   S.questLog.set(q | { q, ... } | nil)  quest log contents; q = { id, title, complete, objectives }
--
-- C_AddOns.GetAddOnMetadata answers only for the addon loaded last by S.loadAddon.
-- XML files listed in a TOC are skipped (metadata.lua is a Lua-only loader).

local S = {}
local metadata, encoding

local noop = function() end

function S.init(libDir)
    local LibDeflate = dofile(libDir .. "/LibDeflate.lua")
    encoding = dofile(libDir .. "/decode.lua")(LibDeflate)
    metadata = dofile(libDir .. "/metadata.lua")
end

-- Frames: a minimal event frame. Methods the code calls that are missing here
-- fail loudly, which tells you what to add.
local frames = {}
local Frame = {}
Frame.__index = Frame
function Frame:RegisterEvent(event) self.events[event] = true end
function Frame:UnregisterEvent(event) self.events[event] = nil end
function Frame:UnregisterAllEvents() self.events = {} end
function Frame:IsEventRegistered(event) return self.events[event] == true end
function Frame:SetScript(name, fn) self.scripts[name] = fn end
function Frame:GetScript(name) return self.scripts[name] end
function Frame:Hide() self.shown = false end
function Frame:Show() self.shown = true end
function Frame:IsShown() return self.shown end

local function CreateFrame(frameType, name)
    local f = setmetatable({ events = {}, scripts = {}, shown = true, frameType = frameType, name = name }, Frame)
    frames[#frames + 1] = f
    if type(name) == "string" then _G[name] = f end
    return f
end

function S.fire(event, ...)
    for _, f in ipairs(frames) do
        local fn = f.events[event] and f.scripts.OnEvent
        if fn then fn(f, event, ...) end
    end
end

-- C_Timer.After only queues; S.runTimers() runs the queue.
local timers = {}

function S.runTimers()
    local guard = 0
    while #timers > 0 do
        guard = guard + 1
        if guard > 10000 then error("C_Timer callbacks keep scheduling more callbacks") end
        local fn = table.remove(timers, 1)
        fn()
    end
end

-- The quest log: a list of quests, no headers.
local quests = {}
S.questLog = {}
function S.questLog.set(q)
    if q == nil then quests = {}
    elseif q.id ~= nil then quests = { q }
    else quests = q end
end

local function quest(id)
    for _, q in ipairs(quests) do
        if q.id == id then return q end
    end
end

local C_QuestLog = {
    GetNumQuestLogEntries = function() return #quests end,
    GetInfo = function(i)
        local q = quests[i]
        if not q then return nil end
        return { questID = q.id, title = q.title, isHeader = false, isHidden = false }
    end,
    IsComplete = function(id) local q = quest(id); return q and q.complete or false end,
    GetQuestObjectives = function(id) local q = quest(id); return q and q.objectives or {} end,
    IsOnQuest = function(id) return quest(id) ~= nil end,
    GetTitleForQuestID = function(id) local q = quest(id); return q and q.title or nil end,
}

local CLASS_ID = { WARRIOR = 1, PALADIN = 2, HUNTER = 3, ROGUE = 4, PRIEST = 5, SHAMAN = 7,
    MAGE = 8, WARLOCK = 9, DRUID = 11 }

function S.install(persona, extra)
    persona = persona or {}
    local faction, class = persona.faction or "Alliance", persona.class or "WARRIOR"
    local locale = persona.locale or "enUS"
    timers = {}
    frames = {}
    quests = {}
    _G.CreateFrame = CreateFrame
    _G.C_Timer = { After = function(_, fn) timers[#timers + 1] = fn end }
    _G.C_QuestLog = C_QuestLog
    _G.wipe = function(t) for k in pairs(t) do t[k] = nil end return t end
    _G.time = os.time
    _G.GetTime = os.clock
    _G.debugstack = function(level) return debug.traceback("", (level or 1) + 1) end
    _G.DEFAULT_CHAT_FRAME = { AddMessage = noop }
    _G.UnitFactionGroup = function() return faction, faction end
    _G.UnitClassBase = function() return class, CLASS_ID[class] end
    _G.GetLocale = function() return locale end
    _G.C_EncodingUtil = encoding and {
        DecodeBase64 = encoding.DecodeBase64,
        DecompressString = encoding.DecompressString,
        DeserializeCBOR = encoding.DeserializeCBOR,
    } or nil
    for k, v in pairs(extra or {}) do _G[k] = v end
end

-- Each TOC is parsed once; each load runs the addon's files again into a new namespace.
local parsed = {}

function S.loadAddon(tocPath, addonName, opts)
    if not metadata then error("call S.init(libDir) before S.loadAddon", 2) end
    opts = opts or {}
    local p = parsed[tocPath]
    if not p then
        local _, header = metadata.parse(tocPath)
        p = { header = header }
        parsed[tocPath] = p
    end
    for _, name in ipairs(opts.reset or {}) do _G[name] = nil end
    -- The whole header, not only X- keys: the real client also answers Title, Version...
    metadata.install(addonName, p.header)
    local baseDir = opts.baseDir or tocPath:match("^(.*)/[^/]+$") or "."
    local ns = metadata.loadAddon(tocPath, addonName, baseDir, opts.gameType)
    return ns, p.header
end

function S.loadFile(path, addonName, ns)
    ns = ns or {}
    local chunk, err = loadfile(path)
    if not chunk then error("cannot load " .. path .. ": " .. tostring(err), 0) end
    chunk(addonName, ns)
    return ns
end

return S
