#!/usr/bin/env python3
"""把 LÖVE 工程打包成浏览器可直接运行的单个 HTML(用 Fengari 在浏览器里跑 Lua)。

用法(在 game1 目录下):
  python tools/build_web.py growth_v0.3 web/养成框架试玩.html "天理的女儿 · 养成框架 v0.3" "说明文字"
  python tools/build_web.py battle_v0.2 web/战斗原型试玩.html "天理的女儿 · 战斗原型 v0.2" "说明文字"

工程里除 main.lua / conf.lua 外的 .lua 文件都会按目录注册成模块(core/ui.lua → require("core.ui"))。
生成的页面需要联网加载 Fengari 和中文字体。
"""
import os, sys

root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
proj = os.path.join(root, sys.argv[1])
out = os.path.join(root, sys.argv[2])
title = sys.argv[3] if len(sys.argv) > 3 else "天理的女儿"
desc = sys.argv[4] if len(sys.argv) > 4 else "点击操作。虚线框为素材占位,可用“选择本地图片”按素材 ID 替换。"

def read(p):
    with open(p, encoding="utf-8") as f:
        return f.read()

mods = []
for dp, dn, fn in os.walk(proj):
    dn.sort()
    for f in sorted(fn):
        if f.endswith(".lua") and not (dp == proj and f in ("main.lua", "conf.lua")):
            name = os.path.relpath(os.path.join(dp, f), proj)[:-4].replace(os.sep, ".")
            mods.append('package.preload["%s"] = function(...)\n%s\nend\n' % (name, read(os.path.join(dp, f))))
main = "".join(mods) + read(os.path.join(proj, "main.lua"))
if "</script" in main:
    sys.exit("Lua 源码里不能出现 </script")

html = read(os.path.join(root, "tools", "shell.html"))
html = html.replace("__TITLE__", title).replace("__DESC__", desc)
html = html.replace("__PRELUDE__", read(os.path.join(root, "tools", "prelude.lua"))).replace("__MAIN__", main)
os.makedirs(os.path.dirname(out), exist_ok=True)
with open(out, "w", encoding="utf-8") as f:
    f.write(html)
print("已生成", out, "(模块 %d 个)" % len(mods))
