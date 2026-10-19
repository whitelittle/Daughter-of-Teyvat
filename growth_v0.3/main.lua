-- 天理的女儿 · 养成框架 v0.3
-- 运行环境:LÖVE 11.x  https://love2d.org
-- 中文显示:把中文 TTF/OTF 字体改名为 font.ttf 放在本目录
--
-- 目录结构
--   core/ui.lua         界面基础(按钮、占位框、弹窗)
--   core/router.lua     场景切换
--   game/state.lua      数值与存档数据
--   game/flow.lua       月度流程
--   data/assets.lua     素材 ID 清单(立绘、背景)
--   data/activities.lua 日程活动表
--   data/story.lua      序章、月初事件、日常对话
--   scenes/*.lua        对话 / 主界面 / 结算

local U = require("core.ui")
local R = require("core.router")
local F = require("game.flow")
R.scenes.dialogue = require("scenes.dialogue")
R.scenes.home = require("scenes.home")
R.scenes.ending = require("scenes.ending")

function love.load()
  love.window.setTitle("天理的女儿 · 养成框架 v0.3")
  U.init()
  F.newGame()
end

function love.update(dt) U.update(dt) end

function love.draw()
  U.beginFrame()
  R.cur.draw()
  U.drawPopup()
  U.drawToast()
  if not U.fontOK then
    U.txt("Chinese font missing: put a CJK font named font.ttf next to main.lua", 10, U.H - 22, U.C.red, U.fS)
  end
end

function love.mousepressed(x, y, b)
  if b == 1 then U.click(x, y) end
end
