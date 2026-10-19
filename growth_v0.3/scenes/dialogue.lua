-- 对话场景:序章与月初事件共用
local U = require("core.ui")
local S = require("game.state")
local A = require("data.assets")
local lg = love.graphics
local C = U.C
local D = {}
local cur

local BG = {
  bg_ruin_night = { 0.07, 0.08, 0.15 }, bg_home_night = { 0.17, 0.11, 0.09 },
  bg_home_room = { 0.55, 0.37, 0.19 }, bg_sky_tianding = { 0.05, 0.06, 0.13 },
}

local function resolve(p)
  if p:sub(1, 1) == "@" then return "ist_" .. S.stageKey() .. "_" .. p:sub(2) end
  return p
end

local function nextNode()
  cur.i = cur.i + 1
  local n = cur.script[cur.i]
  if not n then cur.onDone(); return end
  if n.bg then cur.bg = n.bg end
  if n.portrait then cur.portrait = n.portrait ~= "none" and resolve(n.portrait) or nil end
end

function D.enter(args)
  local sc = args.script
  if type(sc) == "function" then sc = sc(S) end
  cur = { script = sc, i = 0, onDone = args.onDone, bg = "bg_home_room" }
  nextNode()
end

local function choose(c)
  local ch = c.eff and S.apply(c.eff) or ""
  if c.flag then S.flags[c.flag[1]] = c.flag[2] end
  if c.say then cur.extra = { text = c.say, changes = ch } else nextNode() end
end

local function advance()
  if cur.extra then cur.extra = nil; nextNode(); return end
  local n = cur.script[cur.i]
  if n and n.choices then return end
  nextNode()
end

function D.draw()
  local n = cur.script[cur.i]
  if not n then return end
  local bgc = BG[cur.bg] or C.night
  lg.clear(bgc[1], bgc[2], bgc[3])
  if not U.background(cur.bg) then
    if cur.bg == "bg_sky_tianding" or cur.bg == "bg_ruin_night" then
      U.setc(C.light, 0.7); lg.setLineWidth(4); lg.line(930, 0, 880, 250); lg.setLineWidth(1)
    end
    U.tag("背景占位:" .. cur.bg .. "  " .. (A.backgrounds[cur.bg] or ""), 16, 16)
  end
  U.zone(0, 0, U.W, U.H, advance)
  if cur.portrait then U.portrait(cur.portrait, A.portraits[cur.portrait], 440, 30, 400, 470) end

  local who, text = n.who, n.text
  if cur.extra then who, text = nil, cur.extra.text end
  local x, y, w, h = 90, 510, 1100, 190
  U.box(C.woodD, x - 6, y - 6, w + 12, h + 12, 18, "fill", 0.95)
  U.box(C.cream, x, y, w, h, 14)
  if who then
    U.box(C.orange, x + 30, y - 24, 160, 42, 10)
    U.txt(who, x + 30, y - 15, C.ink, U.fM, 160, "center")
  end
  U.txt(text, x + 40, y + 34, C.ink, U.fL, w - 80)
  if cur.extra and cur.extra.changes ~= "" then U.txt(cur.extra.changes, x + 40, y + h - 44, C.red, U.fM, w - 300) end

  if n.choices and not cur.extra then
    local k = #n.choices
    for i, c in ipairs(n.choices) do
      U.button(c.t, U.W / 2 - 230, 480 - (k - i + 1) * 70, 460, 58, function() choose(c) end)
    end
  else
    U.txt("点击继续", x, y + h - 32, C.mut, U.fS, w - 30, "right")
  end
end

return D
