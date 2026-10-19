-- 结算界面(完整结局系统待实现,这里先给出倾向)
local U = require("core.ui")
local S = require("game.state")
local F = require("game.flow")
local lg = love.graphics
local C = U.C
local E = {}

local CAREER = { body = "骑士团 / 千岩军 方向", wit = "教令院 / 学者 方向",
  emo = "吟游诗人 / 歌剧院 方向", imag = "占星 / 艺术 方向" }
local GOAL = { guard = "守护者", guide = "引路人", companion = "同行者" }

function E.enter(a) E.kind = a.kind end

function E.draw()
  lg.clear(C.night[1], C.night[2], C.night[3])
  U.box(C.cream, 240, 60, 800, 600, 16)
  local exposed = E.kind == "exposed"
  U.txt(exposed and "天理察觉" or "她长大了", 240, 92, exposed and C.red or C.ink, U.fXL, 800, "center")
  U.txt(exposed and "暴露度达到上限。夜空中的冷光,终于落在了你们的屋顶上。"
    or "三年过去了。那个攥着沙漏的孩子,如今站在门口,回头对你笑。", 300, 160, C.ink, U.fM, 680, "center")
  local best = "body"
  for _, k in ipairs(S.BASE) do if S.st[k] > S.st[best] then best = k end end
  local lines = {}
  for _, k in ipairs(S.BASE) do
    local g = S.grade(S.st[k])
    lines[#lines + 1] = S.NAME[k] .. " " .. S.st[k] .. "(" .. g .. ")"
  end
  local fate
  if S.st.div > S.st.hum + 15 then fate = "神性占上风:更接近“回归”或“叛离”"
  elseif S.st.hum > S.st.div + 15 then fate = "人性占上风:更接近“凡人”"
  else fate = "神性与人性相当:可能走向“融合”" end
  local body = table.concat(lines, "    ") ..
    "\n\n职业倾向:" .. CAREER[best] ..
    "\n命运倾向:" .. fate ..
    "\n你在她心中:" .. (GOAL[S.flags.goal] or "未定") ..
    "\n\n神性 " .. S.st.div .. "    人性 " .. S.st.hum .. "    暴露度 " .. S.st.exp .. "    摩拉 " .. S.st.mora ..
    "\n\n(完整结局判定待实现)"
  U.txt(body, 300, 240, C.ink, U.fM, 680, "center")
  U.button("重新开始", 540, 580, 200, 58, F.newGame)
end

return E
