-- 月度流程:月初事件 → 主界面安排 → 月末结算
local S = require("game.state")
local R = require("core.router")
local story = require("data.story")
local F = {}

function F.newGame()
  S.new()
  R.go("dialogue", { script = story.opening, onDone = F.startMonth })
end

function F.startMonth()
  if F.isOver() then R.go("ending", { kind = "grown" }); return end
  for _, ev in ipairs(story.events) do
    if not S.flags["ev_" .. ev.id] and ev.when(S) then
      S.flags["ev_" .. ev.id] = true
      R.go("dialogue", { script = ev.script, onDone = function()
        if not F.checkFail() then R.go("home") end
      end })
      return
    end
  end
  R.go("home")
end

-- 月末:扣生活费、恢复心情、推进时间;返回结算说明
function F.endMonth()
  local res = S.apply({ mora = -S.CFG.livingCost, mood = S.CFG.moodRegen })
  S.month = S.month + 1
  if S.month > 12 then S.month, S.year = 1, S.year + 1 end
  S.ap, S.talked = S.CFG.apMax, false
  return res
end

function F.checkFail()
  if S.st.exp >= 100 then R.go("ending", { kind = "exposed" }); return true end
  return false
end

function F.isOver() return S.monthIndex() > S.CFG.totalMonths end

return F
