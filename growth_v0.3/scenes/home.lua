-- 主界面:房间 + 顶栏 + 属性面板 + 场景热点 + 日程安排面板
local U = require("core.ui")
local S = require("game.state")
local R = require("core.router")
local F = require("game.flow")
local ACT = require("data.activities")
local A = require("data.assets")
local story = require("data.story")
local lg = love.graphics
local C = U.C
local H = { sched = false }

local STAT_COL = { body = C.red, wit = C.green, emo = C.pink, imag = C.blue }

function H.enter()
  H.sched = false
  if not S.flags.tutorial then
    S.flags.tutorial = true
    U.openPopup("每个月的安排",
      "每月有 " .. S.CFG.apMax .. " 点行动力。\n点“安排”选课程或打工,点房间里的物品做小事,点她可以聊天。\n心情越好,成长越快。\n点“结束本月”进入下个月。", "开始")
  end
end

local function preview(eff)
  local t = {}
  for _, k in ipairs({ "body", "wit", "emo", "imag", "div", "hum", "exp", "mood" }) do
    local v = eff[k]
    if v then t[#t + 1] = S.NAME[k] .. (v > 0 and "+" or "") .. v end
  end
  return table.concat(t, "  ")
end

local function quick(name, ap, eff)
  S.ap = S.ap - ap
  local ch = S.apply(eff)
  if F.checkFail() then return end
  U.toast(name .. "   " .. ch)
end

local function talk()
  local lines = story.talk[S.stageKey()][S.moodKey()]
  local line = lines[love.math.random(1, #lines)]
  if S.talked then U.toast("她说:“" .. line .. "”"); return end
  S.talked = true
  U.toast("她说:“" .. line .. "”   " .. S.apply({ emo = 1, mood = 3 }))
end

local function endMonth()
  local function go()
    local res = F.endMonth()
    U.openPopup("月末结算", "生活费 -" .. S.CFG.livingCost .. ",心情恢复 +" .. S.CFG.moodRegen .. "\n\n" .. res,
      F.isOver() and "迎来成年" or "下个月", F.startMonth)
  end
  if S.ap > 0 then
    U.openPopup("结束本月?", "还剩 " .. S.ap .. " 点行动力,结束后会作废。", "结束本月", go, "再想想")
  else go() end
end

---------------------------------------------------------------- 绘制
local function drawRoom()
  if U.background("bg_home_room") then return end
  lg.clear(C.wall[1], C.wall[2], C.wall[3])
  for i = 0, 31 do U.setc(C.woodD, 0.18); lg.rectangle("fill", i * 40, 0, 3, 520) end
  U.box(C.floor, 0, 520, U.W, 200, 0)
  U.box(C.woodD, 450, 100, 380, 320, 6)
  U.box(C.window, 465, 115, 350, 290, 4, "fill", 0.95)
  U.setc(C.woodD); lg.rectangle("fill", 636, 115, 8, 290); lg.rectangle("fill", 465, 256, 350, 8)
  U.box(C.woodD, 50, 170, 220, 350, 6)
  for i = 0, 3 do U.box(C.woodL, 62, 236 + i * 70, 196, 8, 2) end
  U.box(C.woodD, 960, 430, 300, 200, 10)
  U.box(C.cream, 975, 445, 270, 64, 10)
  U.box(C.green, 975, 500, 270, 116, 10)
  U.setc(C.orange, 0.35); lg.ellipse("fill", 640, 668, 320, 44)
  U.tag("背景占位:bg_home_room", 360, 92)
end

local function clamp01(v) return math.max(0, math.min(1, v)) end

local function pill(x, w, icon, text, frac, col)
  local y = 26
  U.box(C.woodD, x, y, w, 48, 24)
  U.box(C.black, x + 42, y + 9, w - 54, 30, 15, "fill", 0.35)
  U.box(col, x + 42, y + 9, (w - 54) * clamp01(frac), 30, 15)
  U.txtO(text, x + 42, y + 12, C.light, U.fM, w - 54, "center")
  U.box(col, x - 6, y - 4, 56, 56, 28)
  U.box(C.woodD, x - 6, y - 4, 56, 56, 28, "line")
  U.txt(icon, x - 6, y + 14, C.ink, U.fS, 56, "center")
end

local function drawTop()
  U.box(C.woodD, 14, 10, 310, 126, 16)
  U.box(C.wood, 20, 16, 298, 114, 12)
  U.box(C.woodL, 20, 16, 298, 114, 12, "line")
  U.txtO("第 " .. S.year .. " 年 · " .. S.stage(), 30, 22, C.light, U.fM, 278, "center")
  U.txtO(S.month .. " 月", 30, 46, C.gold, U.fXL, 278, "center")
  U.txtO("距她成年还有 " .. S.monthsLeft() .. " 回合", 30, 102, C.light, U.fS, 278, "center")

  pill(352, 200, "摩拉", tostring(S.st.mora), 1, C.gold)
  pill(582, 260, "行动", S.ap .. "/" .. S.CFG.apMax, S.ap / S.CFG.apMax, C.yellow)
  pill(872, 214, "心情", S.st.mood .. "/100", S.st.mood / 100, C.pink)

  local x = 1102
  U.box(C.woodD, x, 10, 168, 126, 14)
  U.txtO("暴露度", x, 16, C.light, U.fS, 168, "center")
  U.box(C.black, x + 14, 44, 140, 14, 6, "fill", 0.5)
  U.box(C.red, x + 14, 44, 140 * S.st.exp / 100, 14, 6)
  U.txt(S.st.exp .. "/100", x, 62, C.light, U.fS, 168, "center")
  U.txt("神性 " .. S.st.div .. "  人性 " .. S.st.hum, x, 94, C.gold, U.fS, 168, "center")
end

local function drawStats()
  local x, y = 8, 452
  U.box(C.woodD, x, y, 346, 262, 14)
  U.box(C.wood, x + 6, y + 6, 334, 250, 10)
  U.txtO("成长倍率 ×" .. S.moodMult() .. "(看心情)", x + 18, y + 14, C.light, U.fS)
  for i, k in ipairs(S.BASE) do
    local v = S.st[k]
    local g, nxt = S.grade(v)
    local ry = y + 44 + (i - 1) * 52
    U.box(C.cream, x + 16, ry, 316, 46, 8)
    U.box(C.woodL, x + 16, ry, 316, 46, 8, "line")
    U.txt(S.NAME[k], x + 26, ry + 12, STAT_COL[k], U.fM)
    U.txt(tostring(v), x + 80, ry + 6, C.ink, U.fL)
    if nxt then U.txt("还差 " .. (nxt - v), x + 160, ry + 15, C.mut, U.fS) end
    U.txt(g, x + 270, ry + 6, STAT_COL[k], U.fL, 50, "center")
  end
end

local function drawSchedule()
  U.box(C.black, 0, 0, U.W, U.H, 0, "fill", 0.5)
  U.zone(0, 0, U.W, U.H, function() end)
  local px, py, pw, ph = 120, 56, 1040, 616
  U.box(C.woodD, px - 6, py - 6, pw + 12, ph + 12, 18)
  U.box(C.cream, px, py, pw, ph, 14)
  U.txt("本月安排", px + 30, py + 20, C.ink, U.fL)
  U.txt("剩余行动力 " .. S.ap .. "    摩拉 " .. S.st.mora .. "    心情 " .. S.st.mood .. "(成长 ×" .. S.moodMult() .. ")",
    px + 190, py + 28, C.ink, U.fM)
  U.button("关闭", px + pw - 130, py + 16, 110, 46, function() H.sched = false end)
  for i, a in ipairs(ACT) do
    local col, row = (i - 1) % 3, math.floor((i - 1) / 3)
    local x, y, w, h = px + 30 + col * 330, py + 84 + row * 128, 310, 116
    local ok, why = S.canAfford(a.eff, a.ap)
    if a.unlock and S.year < a.unlock then ok, why = false, "第 " .. a.unlock .. " 年开放" end
    local hov = ok and U.hit(x, y, w, h)
    U.box(ok and (hov and C.yellow or C.light) or C.creamD, x, y, w, h, 10)
    U.box(C.woodL, x, y, w, h, 10, "line")
    U.box(C.orange, x + 10, y + 10, 64, 26, 13)
    U.txt(a.place, x + 10, y + 13, C.ink, U.fS, 64, "center")
    U.txt(a.name, x + 84, y + 10, C.ink, U.fM)
    local m = a.eff.mora
    U.txt("行动力 " .. a.ap .. (m and ("    摩拉 " .. (m > 0 and "+" or "") .. m) or ""), x + 12, y + 46, C.wood, U.fS)
    U.txt(preview(a.eff), x + 12, y + 70, C.ink, U.fS, w - 24)
    if not ok then U.txt(why, x, y + h - 24, C.red, U.fS, w - 12, "right") end
    if ok then
      U.zone(x, y, w, h, function()
        S.ap = S.ap - a.ap
        local ch = S.apply(a.eff)
        if F.checkFail() then H.sched = false; return end
        U.openPopup(a.place .. " · " .. a.name, a.say .. "\n\n" .. ch)
      end)
    end
  end
end

function H.draw()
  drawRoom()
  -- 女儿立绘(按年龄段 + 心情切换 ID)
  local id = "ist_" .. S.stageKey() .. "_" .. S.moodKey()
  U.portrait(id, A.portraits[id], 470, 150, 340, 570)
  U.zone(500, 160, 280, 520, talk)
  if not S.talked then U.txtO("点她聊天", 500, 640, C.light, U.fS, 280, "center") end

  local can = S.ap >= 1
  U.hotspot("读书", "+智识", 100, 330, 150, C.greenL, function() quick("读书", 1, { wit = 2, mood = -2 }) end, can)
  U.hotspot("陪她玩", "+情感 +心情", 100, 410, 150, C.yellow, function() quick("陪她玩", 1, { emo = 2, mood = 6 }) end, can)
  U.hotspot("藏起沙漏", "-暴露度", 840, 330, 160, C.creamD, function() quick("藏起沙漏", 1, { exp = -3, div = -1 }) end, can)
  U.hotspot("结束本月", "床", 1030, 372, 170, C.orange, endMonth, true)

  drawTop()
  drawStats()
  U.button("外出探险", 930, 648, 160, 62, function() end, false, "开发中")
  U.button("安排", 1106, 648, 160, 62, function() H.sched = true end)
  if H.sched then drawSchedule() end
end

return H
