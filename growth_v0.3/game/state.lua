-- 存档数据与数值规则(对应千星奇域里的全局变量)
local S = {}

S.NAME = { body = "体魄", wit = "智识", emo = "情感", imag = "想象",
  div = "神性", hum = "人性", exp = "暴露度", mood = "心情", mora = "摩拉" }
S.BASE = { "body", "wit", "emo", "imag" }
local ORDER = { "body", "wit", "emo", "imag", "div", "hum", "exp", "mood", "mora" }
local IS_BASE = { body = true, wit = true, emo = true, imag = true }
local CLAMP100 = { div = true, hum = true, exp = true, mood = true }

-- 评级门槛:E D C B A S
S.GRADES = { { 0, "E" }, { 30, "D" }, { 70, "C" }, { 120, "B" }, { 180, "A" }, { 250, "S" } }

S.CFG = {
  totalMonths = 36,   -- 三年,一回合一个月
  apMax = 13,         -- 每月行动力
  livingCost = 30,    -- 每月生活费
  moodRegen = 8,      -- 月末心情恢复
}

function S.new()
  S.year, S.month = 1, 1
  S.ap = S.CFG.apMax
  S.st = { body = 10, wit = 10, emo = 10, imag = 12, div = 30, hum = 20, exp = 0, mood = 80, mora = 300 }
  S.flags = {}
  S.talked = false
end

function S.monthIndex() return (S.year - 1) * 12 + S.month end
function S.monthsLeft() return S.CFG.totalMonths - S.monthIndex() + 1 end
function S.stage() return S.year == 1 and "幼年" or (S.year == 2 and "少年" or "青年") end
function S.stageKey() return S.year == 1 and "child" or (S.year == 2 and "teen" or "adult") end
function S.moodKey()
  local m = S.st.mood
  if m >= 70 then return "happy" elseif m >= 35 then return "calm" end
  return "sad"
end

function S.grade(v)
  local g, nxt = "E", nil
  for i, t in ipairs(S.GRADES) do
    if v >= t[1] then g = t[2]; nxt = S.GRADES[i + 1] and S.GRADES[i + 1][1] or nil end
  end
  return g, nxt
end

-- 心情影响成长:高心情 ×1.2,低心情 ×0.5
function S.moodMult()
  local m = S.st.mood
  if m >= 70 then return 1.2 elseif m < 30 then return 0.5 end
  return 1
end

-- 应用效果表,返回变化说明文字
function S.apply(eff)
  local out = {}
  for _, k in ipairs(ORDER) do
    local v = eff[k]
    if v and v ~= 0 then
      if IS_BASE[k] and v > 0 then v = math.max(1, math.floor(v * S.moodMult() + 0.5)) end
      local old = S.st[k]
      local nv = old + v
      if CLAMP100[k] then nv = math.max(0, math.min(100, nv))
      elseif k ~= "mora" then nv = math.max(0, nv) end
      S.st[k] = nv
      local d = nv - old
      if d ~= 0 then out[#out + 1] = S.NAME[k] .. (d > 0 and " +" or " ") .. d end
    end
  end
  return table.concat(out, "   ")
end

function S.canAfford(eff, ap)
  if S.ap < (ap or 0) then return false, "行动力不足" end
  if eff and eff.mora and eff.mora < 0 and S.st.mora < -eff.mora then return false, "摩拉不足" end
  return true
end

return S
