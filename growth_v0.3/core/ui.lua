-- 界面基础:颜色、字体、文字、按钮、占位框、弹窗、提示
local lg = love.graphics
local U = { W = 1280, H = 720, buttons = {}, mx = 0, my = 0, popup = nil, toastS = nil, toastT = 0 }

U.C = {
  wall = {0.55, 0.37, 0.19}, floor = {0.64, 0.46, 0.25}, window = {0.99, 0.85, 0.5},
  wood = {0.47, 0.3, 0.15}, woodD = {0.29, 0.17, 0.08}, woodL = {0.75, 0.53, 0.28},
  cream = {0.98, 0.93, 0.83}, creamD = {0.8, 0.74, 0.63}, ink = {0.26, 0.15, 0.07},
  light = {1, 0.96, 0.86}, mut = {0.66, 0.58, 0.47},
  orange = {0.94, 0.62, 0.22}, orangeD = {0.6, 0.45, 0.28}, gold = {0.98, 0.8, 0.36},
  red = {0.84, 0.3, 0.2}, pink = {0.96, 0.52, 0.47}, green = {0.4, 0.72, 0.42},
  greenL = {0.62, 0.86, 0.55}, yellow = {0.98, 0.86, 0.45}, blue = {0.3, 0.45, 0.8},
  night = {0.07, 0.08, 0.15}, black = {0, 0, 0},
}
local C = U.C

function U.init()
  local path
  for _, p in ipairs({ "font.ttf", "font.otf" }) do
    if love.filesystem.getInfo(p) then path = p end
  end
  local function f(sz)
    if path then return lg.newFont(path, sz) end
    return lg.newFont(math.floor(sz * 0.85))
  end
  U.fS, U.fM, U.fL, U.fXL = f(15), f(19), f(26), f(42)
  U.fontOK = path ~= nil
end

function U.setc(c, a) lg.setColor(c[1], c[2], c[3], a or 1) end
function U.box(c, x, y, w, h, r, mode, a)
  U.setc(c, a); lg.rectangle(mode or "fill", x, y, w, h, r or 8, r or 8)
end
function U.txt(s, x, y, c, f, w, al, a)
  lg.setFont(f or U.fM); U.setc(c or C.light, a)
  if w then lg.printf(s, x, y, w, al or "left") else lg.print(s, x, y) end
end
-- 深棕描边字(主界面风格)
function U.txtO(s, x, y, c, f, w, al)
  for _, d in ipairs({ { -2, 0 }, { 2, 0 }, { 0, -2 }, { 0, 2 }, { 0, 3 } }) do
    U.txt(s, x + d[1], y + d[2], C.woodD, f, w, al)
  end
  U.txt(s, x, y, c, f, w, al)
end

function U.hit(x, y, w, h) return U.mx >= x and U.mx <= x + w and U.my >= y and U.my <= y + h end
function U.zone(x, y, w, h, fn) U.buttons[#U.buttons + 1] = { x = x, y = y, w = w, h = h, fn = fn, enabled = true } end

function U.button(label, x, y, w, h, fn, enabled, sub)
  if enabled == nil then enabled = true end
  local hov = enabled and U.hit(x, y, w, h)
  U.box(C.woodD, x, y + 4, w, h, 12)
  U.box(enabled and (hov and C.gold or C.orange) or C.orangeD, x, y, w, h, 12)
  U.box(C.woodD, x, y, w, h, 12, "line")
  local ty = sub and (y + 6) or (y + h / 2 - U.fM:getHeight() / 2)
  U.txt(label, x, ty, enabled and C.ink or C.wood, U.fM, w, "center")
  if sub then U.txt(sub, x + 4, y + h - 22, C.ink, U.fS, w - 8, "center", 0.8) end
  U.buttons[#U.buttons + 1] = { x = x, y = y, w = w, h = h, fn = fn, enabled = enabled }
end

-- 场景里的漂浮热点(上方小字标收益)
function U.hotspot(label, tag, x, y, w, col, fn, enabled)
  local h = 44
  local hov = enabled and U.hit(x, y, w, h)
  U.box(C.woodD, x, y + 3, w, h, 22, "fill", 0.9)
  U.box(enabled and col or C.creamD, x, y, w, h, 22)
  if hov then lg.setLineWidth(3); U.box(C.light, x, y, w, h, 22, "line"); lg.setLineWidth(1) end
  U.txt(label, x, y + h / 2 - U.fM:getHeight() / 2, C.ink, U.fM, w, "center")
  if tag then U.txtO(tag, x, y - 22, C.light, U.fS, w, "center") end
  if enabled then U.zone(x, y, w, h, fn) end
end

function U.dashRect(x, y, w, h, c, a)
  U.setc(c, a); lg.setLineWidth(2)
  local function seg(x1, y1, x2, y2)
    local len = math.sqrt((x2 - x1) ^ 2 + (y2 - y1) ^ 2)
    local n = math.max(1, math.floor(len / 18))
    for i = 0, n - 1 do
      local t1, t2 = i / n, math.min(1, (i + 0.6) / n)
      lg.line(x1 + (x2 - x1) * t1, y1 + (y2 - y1) * t1, x1 + (x2 - x1) * t2, y1 + (y2 - y1) * t2)
    end
  end
  seg(x, y, x + w, y); seg(x + w, y, x + w, y + h); seg(x + w, y + h, x, y + h); seg(x, y + h, x, y)
  lg.setLineWidth(1)
end

-- 立绘/素材占位框:显示资源 ID,替换素材时按 ID 对应
function U.placeholder(id, desc, x, y, w, h)
  U.box(C.light, x, y, w, h, 18, "fill", 0.14)
  U.dashRect(x, y, w, h, C.light, 0.85)
  U.txtO("【立绘占位】", x, y + h / 2 - 46, C.light, U.fM, w, "center")
  U.txtO(id, x, y + h / 2 - 14, C.gold, U.fM, w, "center")
  if desc then U.txtO(desc, x + 14, y + h / 2 + 18, C.light, U.fS, w - 28, "center") end
end

-- 图片素材:assets/<素材ID>.png 或 .jpg,找不到时逐级去掉 ID 末段再找
-- 例:ist_child_happy → ist_child → ist,所以只放一张 ist.png 也能用
local cache = {}
local function find(id)
  if cache[id] then return cache[id] end
  for _, ext in ipairs({ ".png", ".jpg", ".jpeg" }) do
    local p = "assets/" .. id .. ext
    if love.filesystem.getInfo(p) then cache[id] = lg.newImage(p); return cache[id] end
  end
  return nil
end
function U.image(id)
  local s = id
  while s do
    local im = find(s)
    if im then return im end
    s = s:find("_") and s:match("^(.*)_[^_]*$") or nil
  end
  return nil
end

-- 立绘:有图就按框等比缩放、底部对齐;没图显示占位框
function U.portrait(id, desc, x, y, w, h)
  local im = U.image(id)
  if not im then U.placeholder(id, desc, x, y, w, h); return end
  local iw, ih = im:getWidth(), im:getHeight()
  local sc = math.min(w / iw, h / ih)
  lg.setColor(1, 1, 1, 1)
  lg.draw(im, x + (w - iw * sc) / 2, y + h - ih * sc, 0, sc, sc)
end

-- 背景:有图就铺满屏幕,返回 true
function U.background(id)
  local im = U.image(id)
  if not im then return false end
  local iw, ih = im:getWidth(), im:getHeight()
  local sc = math.max(U.W / iw, U.H / ih)
  lg.setColor(1, 1, 1, 1)
  lg.draw(im, (U.W - iw * sc) / 2, (U.H - ih * sc) / 2, 0, sc, sc)
  return true
end

function U.tag(s, x, y)
  lg.setFont(U.fS)
  local w = U.fS:getWidth(s) + 20
  U.box(C.black, x, y, w, 26, 6, "fill", 0.45)
  U.txt(s, x + 10, y + 4, C.light, U.fS)
end

-- 弹窗:一个或两个按钮;打开时屏蔽下层点击
function U.openPopup(title, body, btn, onOk, cancel)
  U.popup = { title = title, body = body, btn = btn or "继续", onOk = onOk, cancel = cancel }
end
function U.drawPopup()
  local p = U.popup
  if not p then return end
  U.box(C.black, 0, 0, U.W, U.H, 0, "fill", 0.5)
  U.zone(0, 0, U.W, U.H, function() end)
  local x, y, w, h = 330, 170, 620, 380
  U.box(C.woodD, x - 6, y - 6, w + 12, h + 12, 18)
  U.box(C.cream, x, y, w, h, 14)
  U.txt(p.title, x, y + 26, C.ink, U.fL, w, "center")
  U.txt(p.body, x + 40, y + 84, C.ink, U.fM, w - 80, "center")
  local function close(ok)
    U.popup = nil
    if ok and p.onOk then p.onOk() end
  end
  if p.cancel then
    U.button(p.cancel, x + 120, y + h - 80, 170, 56, function() close(false) end)
    U.button(p.btn, x + w - 290, y + h - 80, 170, 56, function() close(true) end)
  else
    U.button(p.btn, x + w / 2 - 100, y + h - 80, 200, 56, function() close(true) end)
  end
end

function U.toast(s) U.toastS, U.toastT = s, 2 end
function U.update(dt) if U.toastT > 0 then U.toastT = U.toastT - dt end end
function U.drawToast()
  if U.toastT <= 0 or not U.toastS then return end
  local a = math.min(1, U.toastT * 2)
  lg.setFont(U.fM)
  local w = math.min(1000, U.fM:getWidth(U.toastS) + 60)
  U.box(C.woodD, U.W / 2 - w / 2, 150, w, 50, 25, "fill", 0.9 * a)
  U.txt(U.toastS, U.W / 2 - w / 2, 164, C.light, U.fM, w, "center", a)
end

function U.beginFrame()
  U.buttons = {}
  U.mx, U.my = love.mouse.getPosition()
end
function U.click(x, y)
  U.mx, U.my = x, y
  for i = #U.buttons, 1, -1 do
    local b = U.buttons[i]
    if b.enabled and x >= b.x and x <= b.x + b.w and y >= b.y and y <= b.y + b.h then b.fn(); return end
  end
end

return U
