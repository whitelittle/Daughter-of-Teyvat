-- 场景切换
local R = { scenes = {}, cur = nil, name = nil }
function R.go(name, args)
  R.name, R.cur = name, R.scenes[name]
  if R.cur.enter then R.cur.enter(args or {}) end
end
return R
