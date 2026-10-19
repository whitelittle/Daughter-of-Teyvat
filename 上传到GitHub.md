# 上传到 GitHub

## 方法一:命令行(已安装 Git)
1. 在 GitHub 网页上新建一个空仓库(不要勾选添加 README、.gitignore 或 License),例如 `tianli-daughter`
2. 在本文件夹打开终端,执行:
```
git init
git add .
git commit -m "养成框架 v0.3 + 战斗原型 v0.2 + 设计文档"
git branch -M main
git remote add origin https://github.com/你的用户名/tianli-daughter.git
git push -u origin main
```
第一次推送时浏览器或终端会要求登录 GitHub。

## 方法二:GitHub Desktop
File → Add local repository → 选本文件夹 → 提示不是仓库时点 create a repository → Publish repository。

## 方法三:网页上传
新建仓库后点 “uploading an existing file”,把本文件夹里的内容拖进去。网页上传不会读取 .gitignore,注意别把字体和图片拖进去。

## 不会入库的文件(见 .gitignore)
- 字体文件 *.ttf / *.otf
- assets/ 下的图片(本地替换用)
