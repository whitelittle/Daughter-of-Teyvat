-- 冒烟测试:在没有窗口的环境里随机点击,检查运行时报错
-- 用法(在 game1 目录下,需要 Lua 5.3 或 5.4):
--   lua tools/tests/smoke_test.lua growth_v0.3 50000
--   lua tools/tests/smoke_test.lua battle_v0.2 50000
local proj, steps = arg[1] or "growth_v0.3", tonumber(arg[2] or "20000")
package.path = proj .. "/?.lua;" .. package.path
for _, n in ipairs({ "_js_color", "_js_rect", "_js_circle", "_js_ellipse", "_js_poly", "_js_line", "_js_lw", "_js_clear", "_js_drawimg" }) do
  _G[n] = function() end
end
_js_text = function(s, x, y, sz) assert(type(s) == "string" and type(sz) == "number", "文字参数错误") end
_js_measure = function(s, sz) return #s * sz / 3 end
_js_hasimg = function() return false end
_js_imgsize = function() return 1, 1 end
local MX, MY = 0, 0
_js_mouse = function() return MX, MY end
dofile("tools/prelude.lua")
dofile(proj .. "/main.lua")
math.randomseed(1)
love.load()
for i = 1, steps do
  love.update(0.05)
  love.draw()
  MX, MY = math.random(0, 1280), math.random(0, 720)
  love.draw()
  love.mousepressed(MX, MY, 1)
end
print(proj .. ":" .. steps .. " 步随机点击,无报错")
