-- 剧情脚本
-- 节点字段:who 说话人(nil 为旁白) / text / bg 背景ID / portrait 立绘ID("@calm" 表示按当前年龄段自动选,"none" 隐藏)
-- choices = { { t = 选项文字, eff = 效果, flag = {键, 值}, say = 选后旁白 } }
local P = {}

P.opening = {
  { bg = "bg_ruin_night", portrait = "none", text = "那一夜,一道钉状的冷光坠进了蒙德城外的山谷。" },
  { text = "光落下的地方没有声音,连风都停了。" },
  { who = "你", text = "……那是什么?" },
  { text = "你本该转身离开。可你是——",
    choices = {
      { t = "退役的冒险家", eff = { body = 5 }, flag = { "father", "adventurer" },
        say = "多年的直觉告诉你,坑底有活物。(她的体魄起点更高)" },
      { t = "落魄的学者", eff = { wit = 5 }, flag = { "father", "scholar" },
        say = "你认出了坑壁上的纹路,那不是这个时代的东西。(她的智识起点更高)" },
      { t = "走南闯北的商人", eff = { mora = 300 }, flag = { "father", "merchant" },
        say = "你掂了掂钱袋,还是走了下去。(初始摩拉更多)" },
    } },
  { text = "坑底没有陨石。只有一个蜷着身子的孩子,手里攥着一枚停摆的沙漏。", portrait = "ist_child_sleep" },
  { text = "她身上没有伤。沙漏里的沙,一粒也没有落下。",
    choices = {
      { t = "抱起她", eff = { hum = 3 }, say = "她很轻,轻得像一段还没开始的时间。" },
      { t = "先看看那枚沙漏", eff = { div = 2, exp = 2 }, say = "沙漏在你掌心亮了一下,又暗了下去。" },
    } },
  { who = "???", text = "……" },
  { who = "你", text = "你叫什么名字?" },
  { who = "???", text = "……伊斯……塔露。" },
  { text = "她说完就睡着了,像是用尽了全部的力气。" },
  { text = "远处传来了脚步声。",
    choices = {
      { t = "用斗篷裹住她,从小路离开", eff = { hum = 2 },
        say = "你们绕了很远的路。回头时,山谷里的冷光已经熄了。" },
      { t = "站在原地等", eff = { exp = 10 },
        say = "只是巡逻的骑士。可你总觉得,还有别的什么,看见了她。(暴露度 +10)" },
    } },
  { bg = "bg_home_night", portrait = "ist_child_sleep", text = "就这样,你的屋子里多了一个孩子。" },
  { text = "离她长大成人,还有三年。" },
}

P.events = {
  { id = "first_night", when = function(S) return S.year == 1 and S.month == 1 end, script = {
    { bg = "bg_home_night", portrait = "ist_child_calm", text = "第一个夜晚,她没有睡。" },
    { text = "她坐在窗边,把沙漏举到月光下,一遍一遍地看。",
      choices = {
        { t = "给她讲个故事", eff = { emo = 3, hum = 3 }, say = "你讲了风神与诗人的故事。她听到一半,靠在你肩上睡着了。" },
        { t = "陪她一起数沙子", eff = { wit = 3, div = 2 }, say = "沙子一粒也没有落下。她却数得很认真。" },
      } },
  } },
  { id = "first_word", when = function(S) return S.year == 1 and S.month == 2 end, script = {
    { bg = "bg_home_room", portrait = "ist_child_happy", who = "伊斯塔露", text = "……时间。" },
    { who = "你", text = "什么?" },
    { who = "伊斯塔露", text = "你身上,有很多时间。" },
    { text = "这是她来到这个家以后,说的第一句完整的话。",
      choices = {
        { t = "“那你呢?”", eff = { imag = 3 }, say = "她想了很久,摇了摇头。" },
        { t = "“以后慢慢告诉我。”", eff = { hum = 3, mood = 10 }, say = "她点点头,第一次对你笑了。" },
      } },
  } },
  { id = "heart_father", when = function(S) return S.year == 1 and S.month == 4 end, script = {
    { bg = "bg_home_room", portrait = "ist_child_calm", who = "伊斯塔露", text = "你……是我的什么?" },
    { text = "她问得很认真。",
      choices = {
        { t = "守护你的人", eff = { body = 2, hum = 2 }, flag = { "goal", "guard" }, say = "她把沙漏往你手里塞了塞,像是交给你保管。" },
        { t = "教你长大的人", eff = { wit = 3 }, flag = { "goal", "guide" }, say = "她郑重地点头:“那,老师。”" },
        { t = "陪你一起走的人", eff = { emo = 3, mood = 10 }, flag = { "goal", "companion" }, say = "她牵住了你的手指。" },
      } },
    { text = "(你的回答会影响她今后如何看待你。)" },
  } },
  { id = "tianding_light", when = function(S) return S.year == 1 and S.month == 6 end, script = function(S)
    local sc = { { bg = "bg_sky_tianding", portrait = "@calm", text = "夜空里出现了一道钉状的冷光,和你捡到她那晚一模一样。" } }
    if S.st.exp >= 20 then
      sc[#sc + 1] = { portrait = "@sad", who = "伊斯塔露", text = "它……在找我。" }
      sc[#sc + 1] = { text = "冷光在屋顶上方停了很久。",
        choices = {
          { t = "抱紧她", eff = { hum = 5, exp = -5 }, say = "冷光终于移开了。她在你怀里发抖到天亮。" },
          { t = "拉上窗帘", eff = { exp = -3, mood = -5 }, say = "屋里暗了下来。她一句话也没说。" },
        } }
    else
      sc[#sc + 1] = { who = "伊斯塔露", text = "它看不见我。" }
      sc[#sc + 1] = { text = "冷光掠过山谷,消失了。", choices = {
        { t = "摸摸她的头", eff = { hum = 2, mood = 5 }, say = "她眯起眼睛,像一只晒太阳的猫。" } } }
    end
    sc[#sc + 1] = { text = "(暴露度越高,天理就越容易找到她。修行权能、教令院旁听都会增加暴露度,“藏起沙漏”可以降低它。)" }
    return sc
  end },
  { id = "year2", when = function(S) return S.year == 2 and S.month == 1 end, script = {
    { bg = "bg_home_room", portrait = "@calm", text = "又是一年。她长高了,已经够得着书架顶层。" },
    { who = "伊斯塔露", text = "我想去更远的地方看看。" },
    { text = "(进入少年期。须弥、纳塔的课程已开放。)" },
  } },
  { id = "year3", when = function(S) return S.year == 3 and S.month == 1 end, script = {
    { bg = "bg_home_room", portrait = "@calm", text = "第三年的春天。她站在门口,背影已经很像大人了。" },
    { who = "伊斯塔露", text = "如果有一天我必须离开,你会怪我吗?" },
    { text = "(进入青年期。离她成年只剩最后一年。)" },
  } },
}

-- 点击她时的日常对话,按年龄段与心情选
P.talk = {
  child = {
    happy = { "今天的云,走得很慢。", "我数到一百了!", "你回来啦。" },
    calm = { "沙漏今天也没有动。", "……要出门吗?" },
    sad = { "我不想上课。", "……可以抱一下吗?" },
  },
  teen = {
    happy = { "下次带我去港口好不好?", "我交到朋友了。" },
    calm = { "书里说,时间是一条河。你觉得呢?", "今天也辛苦了。" },
    sad = { "别管我。", "……我是不是很奇怪?" },
  },
  adult = {
    happy = { "谢谢你,一直都在。", "我想记住今天。" },
    calm = { "我在想以后的事。", "窗外的光,好像近了一点。" },
    sad = { "如果我不是我就好了。", "……我有点累。" },
  },
}

return P
