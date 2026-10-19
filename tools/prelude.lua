local cur = { size = 16 }
local function mkfont(a, b)
  local s = type(a) == "number" and a or (b or 16)
  return { size = s, getHeight = function() return math.floor(s * 1.25) end,
    getWidth = function(_, str) return _js_measure(tostring(str), s) end }
end
love = {
  graphics = {
    newFont = mkfont,
    setFont = function(f) cur = f end,
    setColor = function(r, g, b, a) _js_color(r, g, b, a or 1) end,
    rectangle = function(m, x, y, w, h, rx) _js_rect(m, x, y, w, h, rx or 0) end,
    circle = function(m, x, y, r) _js_circle(m, x, y, r) end,
    ellipse = function(m, x, y, rx, ry) _js_ellipse(m, x, y, rx, ry) end,
    polygon = function(m, ...) _js_poly(m, ...) end,
    line = function(...) _js_line(...) end,
    setLineWidth = function(w) _js_lw(w) end,
    print = function(s, x, y) _js_text(tostring(s), x, y, cur.size, -1, "left") end,
    printf = function(s, x, y, w, al) _js_text(tostring(s), x, y, cur.size, w, al or "left") end,
    clear = function(r, g, b) _js_clear(r, g, b) end,
    newImage = function(p)
      local id = p:match("^assets/(.+)%.%w+$")
      return { id = id,
        getWidth = function() local w = _js_imgsize(id); return w end,
        getHeight = function() local _, h = _js_imgsize(id); return h end }
    end,
    draw = function(im, x, y, r, sx, sy) _js_drawimg(im.id, x, y, sx or 1, sy or 1) end,
  },
  math = { random = function(a, b) if a then return math.random(a, b) end return math.random() end },
  mouse = { getPosition = function() return _js_mouse() end },
  filesystem = { getInfo = function(p)
    if p == "font.ttf" then return {} end
    local id = p:match("^assets/(.+)%.png$")
    if id and _js_hasimg(id) then return {} end
  end },
  window = { setTitle = function() end, setMode = function() end },
}
