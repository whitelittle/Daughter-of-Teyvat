-- 天理的女儿 · 探险战斗原型 v0.2
-- 运行环境:LÖVE 11.x  https://love2d.org
-- 中文显示:把任意中文 TTF/OTF 字体改名为 font.ttf,放在本文件同目录
-- 立绘与敌人为占位图形

local W, H = 1280, 720
local lg = love.graphics
local fontS, fontM, fontL, fontXL, fontOK

---------------------------------------------------------------- 可调数值
local CFG = {
  energyPerTurn = 3, energyMax = 6,   -- 每回合获得能量 / 能量上限(可结余)
  burnDmg = 6,                        -- 每层灼烧每回合伤害,结算后层数 -1
  shieldCap = 0.6,                    -- 护盾上限 = 最大生命 × 该值
  foeHp = 1.7, foeAtk = 2.8,          -- 难度旋钮
  restHeal = 0.35,
}

---------------------------------------------------------------- 颜色
local C = {
  sky1 = {0.16, 0.13, 0.26}, sky2 = {0.74, 0.43, 0.24}, ground = {0.25, 0.18, 0.13}, hill = {0.13, 0.1, 0.13},
  panel = {0.12, 0.11, 0.08}, panel2 = {0.19, 0.17, 0.12}, edge = {0.36, 0.29, 0.18},
  cream = {0.95, 0.9, 0.81}, creamDim = {0.6, 0.56, 0.5}, ink = {0.18, 0.12, 0.08},
  light = {0.97, 0.94, 0.87}, mut = {0.68, 0.62, 0.52},
  orange = {0.91, 0.53, 0.17}, orangeDim = {0.5, 0.33, 0.16},
  red = {0.8, 0.26, 0.16}, redDark = {0.3, 0.1, 0.07}, blue = {0.2, 0.33, 0.7},
  gold = {0.96, 0.73, 0.3}, green = {0.42, 0.74, 0.4}, black = {0, 0, 0}, foe = {0.09, 0.06, 0.06},
}
local ELEM = { ["时"] = {0.89, 0.71, 0.35}, ["岩"] = {0.8, 0.6, 0.26}, ["火"] = {0.86, 0.34, 0.22} }
local STATNAME = { body = "体魄", wit = "智识", emo = "情感", imag = "想象" }

---------------------------------------------------------------- 工具
local function setc(c, a) lg.setColor(c[1], c[2], c[3], a or 1) end
local function box(c, x, y, w, h, r, mode, a)
  setc(c, a); lg.rectangle(mode or "fill", x, y, w, h, r or 8, r or 8)
end
local function txt(s, x, y, c, f, w, al, a)
  lg.setFont(f or fontM); setc(c or C.light, a)
  if w then lg.printf(s, x, y, w, al or "left") else lg.print(s, x, y) end
end
local function txtS(s, x, y, c, f, w, al) -- 带阴影,用于战场
  txt(s, x + 2, y + 2, C.black, f, w, al, 0.75); txt(s, x, y, c, f, w, al)
end
local function clamp(v, a, b) return math.max(a, math.min(b, v)) end
local function rnd(a, b) return love.math.random(a, b) end
local function copy(t)
  if type(t) ~= "table" then return t end
  local r = {}
  for k, v in pairs(t) do r[k] = copy(v) end
  return r
end
local function shuffle(t)
  for i = #t, 2, -1 do local j = rnd(1, i); t[i], t[j] = t[j], t[i] end
  return t
end

---------------------------------------------------------------- 按钮
local buttons, mx, my = {}, 0, 0
local function hit(x, y, w, h) return mx >= x and mx <= x + w and my >= y and my <= y + h end
local function zone(x, y, w, h, fn) buttons[#buttons + 1] = { x = x, y = y, w = w, h = h, fn = fn, enabled = true } end
local function button(label, x, y, w, h, fn, enabled, sub)
  if enabled == nil then enabled = true end
  local hov = enabled and hit(x, y, w, h)
  box(enabled and (hov and C.gold or C.orange) or C.orangeDim, x, y, w, h, 10)
  box(C.ink, x, y, w, h, 10, "line")
  local ty = sub and (y + 6) or (y + h / 2 - fontM:getHeight() / 2)
  txt(label, x, ty, enabled and C.ink or C.panel, fontM, w, "center")
  if sub then txt(sub, x, y + h - 22, C.ink, fontS, w, "center", 0.8) end
  buttons[#buttons + 1] = { x = x, y = y, w = w, h = h, fn = fn, enabled = enabled }
end

---------------------------------------------------------------- 角色与技能
local G, B
local endRun

local function curAtk(u)
  local a = u.atk
  if u.buffUntil and B and B.turn <= u.buffUntil then a = math.floor(a * 1.6) end
  return a
end
local function dmgOf(u, mult) return math.floor(curAtk(u) * mult) end

-- kind: atk 单体 / aoe 群体 / shield 全队护盾 / buff 自身增益 / rewind 回溯
local HEROES = {
  { id = "ist", name = "伊斯塔露", elem = "时", atk = 60, hp = 220,
    body = 120, wit = 140, emo = 100, imag = 160,
    skills = {
      { name = "时针", mult = 1, cost = 0, kind = "atk",
        desc = function(u) return "造成" .. dmgOf(u, 1) .. "伤害。" end },
      { name = "迟滞", mult = 0.5, cost = 2, kind = "atk", stun = 1, exp = 3,
        desc = function(u) return "造成" .. dmgOf(u, 0.5) .. "伤害,目标下回合无法行动。\n暴露度 +3" end },
      { name = "回溯", mult = 0, cost = 3, kind = "rewind", exp = 8,
        desc = function() return "全队生命回到上一回合开始时的状态(只升不降),倒下的队员也会起身。\n暴露度 +8" end },
    } },
  { id = "zl", name = "钟离", elem = "岩", atk = 45, hp = 300,
    skills = {
      { name = "岩脊", mult = 1, cost = 0, kind = "atk",
        desc = function(u) return "造成" .. dmgOf(u, 1) .. "伤害。" end },
      { name = "玉璋护盾", mult = 2.5, cost = 2, kind = "shield",
        desc = function(u) return "全队获得" .. dmgOf(u, 2.5) .. "点护盾(可叠加,上限为最大生命的60%)。" end },
      { name = "天星", mult = 3, cost = 3, kind = "atk", stun = 1,
        desc = function(u) return "造成" .. dmgOf(u, 3) .. "伤害,并使目标石化,下回合无法行动。" end },
    } },
  { id = "ht", name = "胡桃", elem = "火", atk = 70, hp = 200,
    skills = {
      { name = "普攻", mult = 1, cost = 0, kind = "atk", burn = 2,
        desc = function(u) return "造成" .. dmgOf(u, 1) .. "伤害。给予2层灼烧。" end },
      { name = "蝶引来生", mult = 0, cost = 2, kind = "buff",
        desc = function() return "消耗自身10%当前生命,接下来2回合攻击提升60%。" end },
      { name = "安神秘法", mult = 2.5, cost = 3, kind = "aoe", burn = 3,
        desc = function(u) return "对全体敌人造成" .. dmgOf(u, 2.5) .. "伤害,给予3层灼烧,并恢复自身15%生命。" end },
    } },
}

local FOES = {
  hili   = { name = "丘丘人",     hp = 260,  atk = 28 },
  archer = { name = "丘丘射手",   hp = 200,  atk = 24, snipe = true },
  brute  = { name = "丘丘暴徒",   hp = 520,  atk = 44, charger = true },
  shaman = { name = "丘丘萨满",   hp = 320,  atk = 20, aoe = true },
  king   = { name = "丘丘岩盔王", hp = 1500, atk = 58, boss = true, aoe = true },
}

local LAYOUT = {
  { "battle", "event" },
  { "event", "rest", "battle" },
  { "treasure", "battle" },
  { "elite", "event" },
  { "boss" },
}
local FOE_POOL = {
  { { "hili", "hili" }, { "hili", "archer" } },
  { { "brute" }, { "hili", "archer", "hili" } },
  { { "shaman", "hili" }, { "archer", "archer", "hili" } },
  { { "brute", "shaman" } },
  { { "king" } },
}
local NODE_STYLE = {
  battle = { "战斗", C.red }, elite = { "精英", C.red }, boss = { "首领", C.red },
  event = { "事件", C.blue }, rest = { "休息", C.green }, treasure = { "宝箱", C.gold },
}

local EVENTS = {
  { title = "风化的石碑", text = "石碑上刻着早已失传的文字。伊斯塔露盯着它看了很久,像是认得。", ch = {
    { t = "让她解读", req = { "wit", 130 }, ok = { istAtk = 10 }, okT = "她读出了一段很久以前的记录。伊斯塔露攻击 +10",
      fail = { exposure = 6 }, failT = "文字刺痛了她的眼睛,沙漏亮了一下。暴露度 +6" },
    { t = "离开", ok = {}, okT = "你们没有停留。" } } },
  { title = "受伤的旅人", text = "一位商队旅人倒在路边,腿上是魔物留下的伤口。", ch = {
    { t = "为他包扎", req = { "emo", 90 }, ok = { humanity = 8, mora = 40 }, okT = "旅人连声道谢,硬塞给你们一点摩拉。人性 +8",
      fail = { humanity = 3 }, failT = "她手忙脚乱,但旅人还是笑了。人性 +3" },
    { t = "拿走他的钱袋", ok = { mora = 120, humanity = -10 }, okT = "伊斯塔露回头看了他很久。人性 -10" },
    { t = "离开", ok = {}, okT = "你们继续赶路。" } } },
  { title = "时间裂缝", text = "半空中有一道细细的裂缝,里面的风是倒着吹的。她的沙漏开始发烫。", ch = {
    { t = "让她触碰裂缝", ok = { istAtk = 15, exposure = 10 }, okT = "沙漏里的沙流动起来。伊斯塔露攻击 +15,暴露度 +10" },
    { t = "让她安抚裂缝", req = { "imag", 150 }, ok = { exposure = -8 }, okT = "裂缝慢慢合上了。暴露度 -8",
      fail = { exposure = 8 }, failT = "裂缝反而扩大了一瞬。暴露度 +8" },
    { t = "离开", ok = {}, okT = "你拉着她快步走开。" } } },
  { title = "坍塌的通道", text = "前方的通道被落石堵住了一半。", ch = {
    { t = "强行搬开", req = { "body", 110 }, ok = { mora = 70 }, okT = "石头后面藏着前人留下的钱袋。摩拉 +70",
      fail = { hurt = 0.15 }, failT = "落石砸了下来。全队生命 -15%" },
    { t = "绕路", ok = { hurt = 0.05 }, okT = "绕了很远的路,大家都有些累了。全队生命 -5%" } } },
}

---------------------------------------------------------------- 探险状态
local function makeHero(d)
  local u = copy(d)
  u.hpMax, u.hp, u.shield, u.acted = d.hp, d.hp, 0, false
  return u
end

local function genMap()
  local evs = shuffle({ 1, 2, 3, 4 })
  local evI, map = 0, {}
  for li, types in ipairs(LAYOUT) do
    map[li] = {}
    for ni, t in ipairs(types) do
      local n = { type = t, layer = li, x = 170 + li * 190, y = 360 + (ni - (#types + 1) / 2) * 170 }
      if t == "battle" or t == "elite" or t == "boss" then
        local pool = FOE_POOL[li]; n.foes = pool[rnd(1, #pool)]
      elseif t == "event" then
        evI = evI + 1; n.ev = EVENTS[evs[evI]]
      end
      map[li][ni] = n
    end
  end
  return map
end

local function notice(title, body) G.state = "notice"; G.noticeT, G.noticeB = title, body end

local function newRun()
  G = { humanity = 50, exposure = 0, mora = 0, crystal = 0, pos = 0, path = {}, map = genMap(), party = {} }
  for i, d in ipairs(HEROES) do G.party[i] = makeHero(d) end
  notice("出发", "伊斯塔露、钟离、胡桃踏入了遗迹。\n全队共用能量,每人每回合行动一次。")
end

local function hero() return G.party[1] end

local function applyEff(e)
  if e.istAtk then hero().atk = hero().atk + e.istAtk end
  if e.humanity then G.humanity = clamp(G.humanity + e.humanity, 0, 100) end
  if e.exposure then G.exposure = clamp(G.exposure + e.exposure, 0, 100) end
  if e.mora then G.mora = G.mora + e.mora end
  if e.hurt then
    for _, u in ipairs(G.party) do
      if u.hp > 0 then u.hp = math.max(1, u.hp - math.floor(u.hpMax * e.hurt)) end
    end
  end
end

---------------------------------------------------------------- 战斗逻辑
local function log(s) table.insert(B.log, 1, s); if #B.log > 3 then table.remove(B.log) end end
local function float(x, y, s, c) B.float[#B.float + 1] = { x = x, y = y, s = s, c = c or C.light, t = 1.1 } end
local function alive(list)
  local r = {}
  for _, u in ipairs(list) do if u.hp > 0 then r[#r + 1] = u end end
  return r
end
local function addExposure(n) G.exposure = clamp(G.exposure + n, 0, 100) end

local function rollIntent(f)
  if f.charging then f.charging = false; f.intent = { type = "heavy", dmg = f.atk * 2 }; return end
  local t
  if f.boss then
    local seq = { "atk", "aoe", "charge", "atk" }
    f.seqI = (f.seqI or 0) % #seq + 1; t = seq[f.seqI]
  else
    local r = love.math.random()
    if f.aoe and r < 0.4 then t = "aoe"
    elseif f.charger and r < 0.35 then t = "charge"
    else t = "atk" end
  end
  if t == "aoe" then f.intent = { type = "aoe", dmg = math.floor(f.atk * 0.6) }
  elseif t == "charge" then f.intent = { type = "charge" }
  else f.intent = { type = "atk", dmg = f.atk } end
end

local function beginPlayerTurn()
  B.energy = math.min(CFG.energyMax, B.energy + CFG.energyPerTurn)
  B.pending = nil
  for _, u in ipairs(B.heroes) do u.acted = u.hp <= 0 end
  B.rewindHP = B.turnHP
  B.turnHP = {}
  for i, u in ipairs(B.heroes) do B.turnHP[i] = u.hp end
end

local function foeX(i, n)
  if n == 1 then return 640 end
  if n == 2 then return i == 1 and 460 or 820 end
  return 330 + (i - 1) * 310
end

local function startBattle(node)
  local foes, n = {}, #node.foes
  for i, id in ipairs(node.foes) do
    local f = copy(FOES[id])
    f.hp = math.floor(f.hp * CFG.foeHp); f.atk = math.floor(f.atk * CFG.foeAtk)
    f.hpMax, f.stun, f.burn = f.hp, 0, 0
    f.x, f.y = foeX(i, n), 175
    rollIntent(f)
    foes[i] = f
  end
  for i, u in ipairs(G.party) do u.cx, u.cy, u.buffUntil = 300 + (i - 1) * 310 + 140, 470, nil end
  B = { heroes = G.party, foes = foes, node = node, turn = 1, energy = 0, log = {}, float = {} }
  log("遭遇 " .. n .. " 个敌人")
  G.state = "battle"
  beginPlayerTurn()
end

local function checkEnd()
  if G.exposure >= 100 then endRun("exposed"); return true end
  if #alive(B.foes) == 0 then
    local node = B.node
    local mora = rnd(40, 90) * #B.foes
    local cry = node.type == "boss" and 3 or (node.type == "elite" and 2 or 1)
    G.mora, G.crystal = G.mora + mora, G.crystal + cry
    for _, u in ipairs(G.party) do u.shield = 0 end
    if node.type == "boss" then endRun("win")
    else notice("战斗胜利", "获得 摩拉 " .. mora .. "、时之晶 " .. cry .. "。\n生命会保留到下一场战斗。") end
    return true
  end
  if #alive(B.heroes) == 0 then endRun("lose"); return true end
  return false
end

local function dmgFoe(f, d, src)
  f.hp = math.max(0, f.hp - d)
  float(f.x, f.y + 20, "-" .. d, C.light)
  log(src .. " 对 " .. f.name .. " 造成 " .. d .. " 伤害")
end

local function hitHero(u, dmg, from)
  local ab = math.min(u.shield, dmg)
  u.shield, dmg = u.shield - ab, dmg - ab
  u.hp = math.max(0, u.hp - dmg)
  float(u.cx, u.cy - 60, ab > 0 and ("-" .. dmg .. " (盾" .. ab .. ")") or ("-" .. dmg), C.red)
  log(from .. " 攻击 " .. u.name .. "," .. dmg .. " 伤害")
end

local function canUse(u, sk)
  if u.hp <= 0 or u.acted or B.energy < sk.cost then return false end
  if sk.kind == "rewind" then
    if not B.rewindHP then return false end
    for i, v in ipairs(B.rewindHP) do if v > B.heroes[i].hp then return true end end
    return false
  end
  return true
end

local function useSkill(u, sk, target)
  B.energy = B.energy - sk.cost
  if sk.kind == "atk" then
    dmgFoe(target, dmgOf(u, sk.mult), u.name)
    if target.hp > 0 then
      if sk.stun then target.stun = math.max(target.stun, sk.stun); float(target.x, target.y - 40, sk.name == "天星" and "石化" or "迟滞", C.gold) end
      if sk.burn then target.burn = target.burn + sk.burn end
    end
  elseif sk.kind == "aoe" then
    for _, f in ipairs(alive(B.foes)) do
      dmgFoe(f, dmgOf(u, sk.mult), u.name)
      if f.hp > 0 and sk.burn then f.burn = f.burn + sk.burn end
    end
    local h = math.floor(u.hpMax * 0.15)
    u.hp = math.min(u.hpMax, u.hp + h); float(u.cx, u.cy - 60, "+" .. h, C.green)
  elseif sk.kind == "shield" then
    local s = dmgOf(u, sk.mult)
    for _, a in ipairs(alive(B.heroes)) do
      a.shield = math.min(math.floor(a.hpMax * CFG.shieldCap), a.shield + s)
      float(a.cx, a.cy - 60, "护盾", C.blue)
    end
    log(u.name .. " 施放" .. sk.name)
  elseif sk.kind == "buff" then
    u.hp = math.max(1, u.hp - math.floor(u.hp * 0.1))
    u.buffUntil = B.turn + 2
    float(u.cx, u.cy - 60, "攻击提升", C.orange)
    log(u.name .. " 进入彼岸蝶舞状态")
  elseif sk.kind == "rewind" then
    for i, a in ipairs(B.heroes) do
      local v = B.rewindHP[i]
      if v > a.hp then float(a.cx, a.cy - 60, "+" .. (v - a.hp), C.gold); a.hp = v end
    end
    log("沙漏倒转,全队回到了上一回合")
  end
  if sk.exp then addExposure(sk.exp) end
  u.acted, B.pending = true, nil
  checkEnd()
end

local function enemyPhase()
  B.pending = nil
  for _, f in ipairs(B.foes) do
    if f.hp > 0 and f.burn > 0 then
      local d = f.burn * CFG.burnDmg
      f.hp = math.max(0, f.hp - d); f.burn = f.burn - 1
      float(f.x, f.y + 50, "灼烧 -" .. d, C.orange)
    end
  end
  if checkEnd() then return end
  for _, f in ipairs(B.foes) do
    if f.hp > 0 then
      if f.stun > 0 then
        f.stun = f.stun - 1; log(f.name .. " 无法行动")
      else
        local it, targets = f.intent, alive(B.heroes)
        if #targets > 0 then
          if it.type == "atk" or it.type == "heavy" then
            local t = targets[rnd(1, #targets)]
            if f.snipe then for _, a in ipairs(targets) do if a.hp < t.hp then t = a end end end
            hitHero(t, it.dmg, f.name)
          elseif it.type == "aoe" then
            for _, a in ipairs(targets) do hitHero(a, it.dmg, f.name) end
          elseif it.type == "charge" then
            f.charging = true; log(f.name .. " 正在蓄力!")
          end
        end
        rollIntent(f)
      end
    end
  end
  if not checkEnd() then B.turn = B.turn + 1; beginPlayerTurn() end
end

local function pick(u, sk)
  if sk.kind == "atk" then B.pending = { u = u, sk = sk } else useSkill(u, sk) end
end

---------------------------------------------------------------- 流程
function endRun(kind) G.state = "result"; G.result = kind end

local function enterNode(n)
  G.pos = n.layer; G.path[n.layer] = n
  if n.type == "battle" or n.type == "elite" or n.type == "boss" then startBattle(n)
  elseif n.type == "event" then G.state, G.ev, G.evRes = "event", n.ev, nil
  elseif n.type == "rest" then
    for _, u in ipairs(G.party) do
      if u.hp <= 0 then u.hp = math.floor(u.hpMax * 0.25)
      else u.hp = math.min(u.hpMax, u.hp + math.floor(u.hpMax * CFG.restHeal)) end
    end
    notice("营火", "你们在背风处休息了一会儿。\n全队回复35%生命,倒下的队员以25%生命起身。")
  elseif n.type == "treasure" then
    local m = rnd(80, 150)
    G.mora, G.crystal = G.mora + m, G.crystal + 1
    notice("宝箱", "获得 摩拉 " .. m .. "、时之晶 1。")
  end
end

local function pickEvent(c)
  local ok = true
  if c.req then ok = hero()[c.req[1]] >= c.req[2] end
  if ok then applyEff(c.ok or {}); G.evRes = c.okT else applyEff(c.fail or {}); G.evRes = c.failT end
end

---------------------------------------------------------------- 战斗绘制
local function drawBattlefield()
  for i = 0, 23 do
    local t = i / 23
    lg.setColor(C.sky1[1] + (C.sky2[1] - C.sky1[1]) * t, C.sky1[2] + (C.sky2[2] - C.sky1[2]) * t, C.sky1[3] + (C.sky2[3] - C.sky1[3]) * t)
    lg.rectangle("fill", 0, i * 10, W, 11)
  end
  setc(C.hill); lg.polygon("fill", 0, 240, 180, 150, 330, 215, 520, 130, 700, 210, 880, 140, 1060, 200, 1280, 120, 1280, 260, 0, 260)
  setc(C.ground); lg.rectangle("fill", 0, 235, W, 120)
  setc(C.sky2, 0.25); lg.ellipse("fill", 640, 300, 520, 40)
end

local function brackets(x, y, w, h, a)
  setc(C.gold, a); lg.setLineWidth(5)
  local L = 26
  lg.line(x, y + L, x, y, x + L, y); lg.line(x + w - L, y, x + w, y, x + w, y + L)
  lg.line(x, y + h - L, x, y + h, x + L, y + h); lg.line(x + w - L, y + h, x + w, y + h, x + w, y + h - L)
  lg.setLineWidth(1)
end

local function intentText(f)
  if f.stun > 0 then return "无法行动", C.gold end
  local it = f.intent
  if it.type == "atk" then return (f.snipe and "狙击 " or "攻击 ") .. it.dmg, C.light end
  if it.type == "aoe" then return "群攻 " .. it.dmg, C.light end
  if it.type == "charge" then return "蓄力中", C.gold end
  return "重击 " .. it.dmg, C.orange
end

local function drawFoe(f, n)
  local x, y = f.x, f.y
  local s = f.boss and 1.35 or 1
  local bw = n >= 3 and 230 or 270
  if f.hp <= 0 then
    setc(C.foe, 0.2); lg.ellipse("fill", x, y + 20, 70 * s, 60 * s)
    return
  end
  -- 占位剪影(正式版替换为游戏内模型)
  setc(C.foe, 0.92)
  lg.ellipse("fill", x, y + 20, 62 * s, 58 * s)
  lg.circle("fill", x, y - 50 * s, 34 * s)
  lg.setLineWidth(10 * s)
  lg.line(x - 55 * s, y + 5, x - 95 * s, y + 45 * s); lg.line(x + 55 * s, y + 5, x + 95 * s, y + 45 * s)
  lg.setLineWidth(1)
  local p = B.pending
  local hov = p and hit(x - 120, y - 115, 240, 210)
  if p then brackets(x - 120, y - 115, 240, 210, hov and 1 or 0.35) end
  if p then zone(x - 120, y - 115, 240, 210, function() useSkill(p.u, p.sk, f) end) end
  -- 意图
  local it, ic = intentText(f)
  box(C.panel, x - 60, y - 112 * s, 120, 26, 13, "fill", 0.8)
  txt(it, x - 60, y - 112 * s + 4, ic, fontS, 120, "center")
  -- 名字 / 生命
  txtS(f.name, x - 120, y + 40, C.light, fontL, 240, "center")
  local hp = f.hp .. "/" .. f.hpMax
  txtS(hp, x - 120, y + 74, C.light, fontL, 240, "center")
  box(C.redDark, x - bw / 2, y + 108, bw, 18, 5)
  box(C.red, x - bw / 2, y + 108, bw * f.hp / f.hpMax, 18, 5)
  box(C.black, x - bw / 2, y + 108, bw, 18, 5, "line")
  -- 状态
  local sx = x - bw / 2 - 4
  if f.burn > 0 then
    setc(C.orange); lg.circle("fill", sx, y + 86, 17)
    txt("灼" .. f.burn, sx - 20, y + 77, C.ink, fontS, 40, "center")
  end
  if f.stun > 0 then
    setc(C.gold); lg.circle("fill", sx + (f.burn > 0 and 38 or 0), y + 86, 17)
    txt("晕", sx - 20 + (f.burn > 0 and 38 or 0), y + 77, C.ink, fontS, 40, "center")
  end
end

local function skillIcon(kind, x, y, a)
  if kind == "atk" or kind == "aoe" then
    setc(C.red, a); lg.polygon("fill", x - 4, y + 12, x + 10, y - 12, x + 14, y - 8, x, y + 14)
    lg.rectangle("fill", x - 9, y + 6, 14, 4)
  elseif kind == "shield" then
    setc(C.blue, a); lg.polygon("fill", x - 9, y - 10, x + 9, y - 10, x + 9, y + 2, x, y + 12, x - 9, y + 2)
  elseif kind == "buff" then
    setc(C.orange, a); lg.polygon("fill", x, y - 12, x + 9, y, x, y + 12, x - 9, y)
  else
    setc(C.gold, a)
    lg.polygon("fill", x - 9, y - 12, x + 9, y - 12, x, y); lg.polygon("fill", x - 9, y + 12, x + 9, y + 12, x, y)
  end
end

local function octagon(x, y, w, h, c)
  local k = 18
  return { x + k, y, x + w - k, y, x + w, y + k, x + w, y + h - k, x + w - k, y + h, x + k, y + h, x, y + h - k, x, y + k }
end

local tipSkill, tipHero

local function drawCard(u, i)
  local x, y = 300 + (i - 1) * 310, 392
  local dead = u.hp <= 0
  -- 头像框
  box(C.panel2, x + 150, y + 36, 125, 92, 10)
  setc(C.edge); lg.polygon("fill", octagon(x + 6, y + 18, 160, 112))
  setc(ELEM[u.elem], 0.85); lg.polygon("fill", octagon(x + 12, y + 24, 148, 100))
  txt(u.elem, x + 12, y + 38, C.ink, fontXL, 148, "center", 0.55)
  txt("立绘位", x + 12, y + 100, C.ink, fontS, 148, "center", 0.6)
  txt(u.name, x + 6, y - 6, C.light, fontM, 160, "center")
  -- 攻击
  txt("攻击:", x + 150, y + 44, C.mut, fontS, 115, "right")
  local buffed = u.buffUntil and B.turn <= u.buffUntil
  txt(tostring(curAtk(u)), x + 150, y + 64, buffed and C.orange or C.gold, fontXL, 115, "right")
  -- 护盾徽章
  setc(C.blue); lg.polygon("fill", x - 8, y + 128, x + 38, y + 128, x + 38, y + 158, x + 15, y + 174, x - 8, y + 158)
  txt(tostring(u.shield), x - 8, y + 134, C.light, fontM, 46, "center")
  -- 生命
  txt("HP", x + 44, y + 126, C.light, fontS)
  box(C.redDark, x + 44, y + 146, 150, 16, 3)
  box(C.red, x + 44, y + 146, 150 * u.hp / u.hpMax, 16, 3)
  txt(u.hp .. "/" .. u.hpMax, x + 198, y + 140, C.red, fontM)
  -- 技能
  for j, sk in ipairs(u.skills) do
    local rx, ry = x + 18, y + 176 + (j - 1) * 50
    local ok = canUse(u, sk)
    local hov = hit(rx, ry, 244, 42)
    if hov then tipSkill, tipHero = sk, u end
    local sel = B.pending and B.pending.sk == sk
    box(ok and C.cream or C.creamDim, rx, ry, 244, 42, 8)
    if (hov and ok) or sel then lg.setLineWidth(3); box(C.gold, rx, ry, 244, 42, 8, "line"); lg.setLineWidth(1) end
    txt(sk.name, rx + 12, ry + 10, C.ink, fontM)
    if sk.mult > 0 and (sk.kind == "atk" or sk.kind == "aoe") then txt("×" .. sk.mult, rx + 140, ry + 10, C.ink, fontM) end
    skillIcon(sk.kind, rx + 200, ry + 21, ok and 1 or 0.5)
    setc(ok and C.orange or C.orangeDim); lg.circle("fill", rx + 238, ry + 21, 17)
    setc(C.ink); lg.circle("line", rx + 238, ry + 21, 17)
    txt(tostring(sk.cost), rx + 221, ry + 11, C.light, fontM, 34, "center")
    if ok then zone(rx, ry, 244, 42, function() pick(u, sk) end) end
  end
  if dead or u.acted then
    box(C.black, x - 10, y - 10, 292, 340, 10, "fill", 0.55)
    txt(dead and "[倒下]" or "[回合结束]", x - 10, y + 150, C.light, fontL, 292, "center")
  end
end

local function drawTip()
  local x, y, w, h = 8, 470, 278, 244
  box(C.cream, x, y, w, h, 10)
  local sk, u = tipSkill, tipHero
  if not sk and B.pending then sk, u = B.pending.sk, B.pending.u end
  if not sk then
    txt("技能说明", x + 16, y + 16, C.ink, fontL)
    box(C.light, x + 10, y + 60, w - 20, h - 70, 8)
    txt("把鼠标移到技能上查看说明。\n\n能量全队共用,每回合 +" .. CFG.energyPerTurn .. ",最多存 " .. CFG.energyMax .. " 点。\n每名队员每回合行动一次。", x + 22, y + 72, C.ink, fontS, w - 44)
    return
  end
  txt(sk.name, x + 16, y + 16, C.ink, fontL)
  if sk.mult > 0 then txt("攻击倍数: " .. sk.mult, x + 16, y + 26, C.ink, fontS, w - 32, "right") end
  box(C.light, x + 10, y + 60, w - 20, h - 70, 8)
  txt(sk.desc(u), x + 22, y + 72, C.ink, fontM, w - 44)
end

local function drawBattle()
  tipSkill, tipHero = nil, nil
  drawBattlefield()
  for _, f in ipairs(B.foes) do drawFoe(f, #B.foes) end
  -- 顶部信息
  txtS("第 " .. B.turn .. " 回合", 20, 14, C.light, fontM)
  for i, l in ipairs(B.log) do txtS(l, 20, 40 + (i - 1) * 20, C.light, fontS) end
  txtS("暴露度 " .. G.exposure, 1060, 10, C.light, fontS)
  box(C.redDark, 1060, 34, 200, 10, 4); box(C.red, 1060, 34, 2 * G.exposure, 10, 4)
  -- 下方面板
  setc(C.panel)
  lg.polygon("fill", 0, 345, 450, 345, 480, 328, 800, 328, 830, 345, W, 345, W, H, 0, H)
  setc(C.edge); lg.setLineWidth(2)
  lg.line(0, 345, 450, 345, 480, 328, 800, 328, 830, 345, W, 345); lg.setLineWidth(1)
  txt("能量", 520, 346, C.light, fontL)
  for i = 1, CFG.energyMax do
    local cx = 612 + (i - 1) * 46
    setc(i <= B.energy and C.orange or C.orangeDim); lg.circle("fill", cx, 362, 19)
    setc(C.ink); lg.circle("line", cx, 362, 19)
    txt(tostring(i), cx - 19, 350, i <= B.energy and C.light or C.mut, fontM, 38, "center")
  end
  for i, u in ipairs(B.heroes) do drawCard(u, i) end
  drawTip()
  if B.pending then
    txtS("选择一个敌人作为目标(Esc 取消)", 0, 300, C.gold, fontM, W, "center")
  end
  button("结束回合", 1140, 340, 128, 44, enemyPhase)
  for _, fl in ipairs(B.float) do txtS(fl.s, fl.x - 100, fl.y, fl.c, fontL, 200, "center") end
end

---------------------------------------------------------------- 其他界面
local function drawHUD()
  box(C.panel2, 0, 0, W, 56, 0)
  txt("天理的女儿 · 探险", 20, 12, C.gold, fontL)
  txt("暴露度 " .. G.exposure, 360, 8, C.mut, fontS)
  box(C.redDark, 360, 32, 180, 10, 4); box(C.red, 360, 32, 1.8 * G.exposure, 10, 4)
  txt("人性 " .. G.humanity .. "    摩拉 " .. G.mora .. "    时之晶 " .. G.crystal, 580, 16, C.light)
end

local function drawPanelBg() lg.clear(C.panel[1], C.panel[2], C.panel[3]) end

local function drawMap()
  txt("选择下一个地点。路线决定你会遇到什么。", 0, 80, C.mut, fontM, W, "center")
  local cur = G.path[G.pos] or { x = 170, y = 360 }
  local prev = { x = 170, y = 360 }
  for li = 1, G.pos do
    local n = G.path[li]
    lg.setLineWidth(4); setc(C.gold); lg.line(prev.x, prev.y, n.x, n.y); lg.setLineWidth(1)
    prev = n
  end
  local nextL = G.map[G.pos + 1]
  if nextL then for _, n in ipairs(nextL) do setc(C.gold, 0.35); lg.line(cur.x, cur.y, n.x, n.y) end end
  setc(C.gold); lg.circle("fill", 170, 360, 26)
  txt("出发", 120, 392, C.light, fontS, 100, "center")
  for li, layer in ipairs(G.map) do
    for _, n in ipairs(layer) do
      local st = NODE_STYLE[n.type]
      local r = n.type == "boss" and 40 or 30
      local chosen, avail = G.path[li] == n, li == G.pos + 1
      local past = li <= G.pos and not chosen
      setc(st[2], past and 0.2 or (avail and 1 or (chosen and 0.8 or 0.45)))
      lg.circle("fill", n.x, n.y, r)
      if avail and hit(n.x - r, n.y - r, r * 2, r * 2) then
        lg.setLineWidth(3); setc(C.light); lg.circle("line", n.x, n.y, r + 6); lg.setLineWidth(1)
      end
      txt(st[1], n.x - 50, n.y - fontS:getHeight() / 2, C.ink, fontS, 100, "center")
      if avail then zone(n.x - r, n.y - r, r * 2, r * 2, function() enterNode(n) end) end
    end
  end
  box(C.panel2, 0, 600, W, 120, 0)
  for i, u in ipairs(G.party) do
    local x = 40 + (i - 1) * 400
    txt(u.name, x, 618, C.gold, fontM)
    box(C.redDark, x, 650, 300, 14, 3); box(C.red, x, 650, 300 * u.hp / u.hpMax, 14, 3)
    txt(u.hp .. "/" .. u.hpMax .. "   攻击 " .. u.atk, x, 672, C.light, fontS)
  end
end

local function drawEvent()
  local ev = G.ev
  box(C.cream, 240, 100, 800, 480, 14)
  txt(ev.title, 240, 128, C.ink, fontL, 800, "center")
  txt(ev.text, 290, 186, C.ink, fontM, 700, "center")
  if G.evRes then
    txt(G.evRes, 290, 320, C.red, fontM, 700, "center")
    button("继续", 540, 480, 200, 56, function()
      if G.exposure >= 100 then endRun("exposed") else G.state = "map" end
    end)
    return
  end
  for i, c in ipairs(ev.ch) do
    local sub
    if c.req then sub = "需 " .. STATNAME[c.req[1]] .. "≥" .. c.req[2] .. "(伊斯塔露 " .. hero()[c.req[1]] .. ")" end
    button(c.t, 390, 270 + (i - 1) * 84, 500, 70, function() pickEvent(c) end, true, sub)
  end
end

local function drawNotice()
  box(C.cream, 340, 190, 600, 320, 14)
  txt(G.noticeT, 340, 220, C.ink, fontL, 600, "center")
  txt(G.noticeB, 380, 290, C.ink, fontM, 520, "center")
  button("继续", 540, 430, 200, 56, function() G.state = "map" end)
end

local RESULT = {
  win = { "探险完成", "丘丘岩盔王倒下了。伊斯塔露在废墟里捡起一块发光的碎片,握得很紧。" },
  lose = { "全队倒下", "你们撤出了遗迹。下一次,也许该换一条路。" },
  exposed = { "天理察觉", "暴露度达到上限。天空中出现了一道钉状的冷光——巡检者来了。" },
}
local function drawResult()
  local r = RESULT[G.result]
  box(C.cream, 290, 150, 700, 420, 14)
  txt(r[1], 290, 186, G.result == "win" and C.ink or C.red, fontL, 700, "center")
  txt(r[2], 340, 246, C.ink, fontM, 600, "center")
  txt("摩拉 " .. G.mora .. "    时之晶 " .. G.crystal .. "\n人性 " .. G.humanity .. "    暴露度 " .. G.exposure, 340, 350, C.ink, fontM, 600, "center")
  button("再来一次", 540, 470, 200, 60, newRun)
end

---------------------------------------------------------------- LÖVE 回调
function love.load()
  love.window.setTitle("天理的女儿 · 探险战斗原型 v0.2")
  love.window.setMode(W, H)
  local path
  for _, p in ipairs({ "font.ttf", "font.otf" }) do if love.filesystem.getInfo(p) then path = p end end
  if path then
    fontS, fontM, fontL, fontXL = lg.newFont(path, 15), lg.newFont(path, 19), lg.newFont(path, 26), lg.newFont(path, 44)
    fontOK = true
  else
    fontS, fontM, fontL, fontXL = lg.newFont(13), lg.newFont(16), lg.newFont(22), lg.newFont(36)
    fontOK = false
  end
  newRun()
end

function love.update(dt)
  if G.state == "battle" and B then
    for i = #B.float, 1, -1 do
      local f = B.float[i]
      f.t, f.y = f.t - dt, f.y - 40 * dt
      if f.t <= 0 then table.remove(B.float, i) end
    end
  end
end

function love.draw()
  buttons = {}
  mx, my = love.mouse.getPosition()
  drawPanelBg()
  local s = G.state
  if s == "battle" then drawBattle()
  else
    drawHUD()
    if s == "map" then drawMap()
    elseif s == "event" then drawEvent()
    elseif s == "notice" then drawNotice()
    elseif s == "result" then drawResult() end
  end
  if not fontOK then txt("Chinese font missing: put a CJK font named font.ttf next to main.lua", 10, H - 22, C.red, fontS) end
end

function love.mousepressed(x, y, b)
  if b == 2 and B and G.state == "battle" then B.pending = nil; return end
  if b ~= 1 then return end
  mx, my = x, y
  for i = #buttons, 1, -1 do
    local bt = buttons[i]
    if bt.enabled and x >= bt.x and x <= bt.x + bt.w and y >= bt.y and y <= bt.y + bt.h then bt.fn(); return end
  end
end

function love.keypressed(k)
  if k == "escape" and G.state == "battle" and B then B.pending = nil end
end
