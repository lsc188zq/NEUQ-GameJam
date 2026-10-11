extends Node2D
## 游戏世界的根节点。
##
## ═══ 这个脚本现在【什么都不做】═══
## 它只剩下"路标"的作用 —— 告诉你东西都搬哪去了，别再往这儿找。
##
##   相机边界      →  scripts/world/room_manager.gd
##                    （房间是运行时装的，只有它知道地板什么时候出现）
##   房间切换      →  scripts/world/room_manager.gd + scripts/autoload/travel.gd
##   开局任务      →  scenes/quest_book.tscn（自动加载）
##   玩家位置记录  →  scripts/autoload/game_state.gd
##
## ═══ 为什么留着这个空脚本 ═══
## world.tscn 的根节点迟早会需要点儿什么（存档点、过场、全局事件……）。
## 与其到时候新建一个脚本再挂上去，不如先把位置占着，
## 顺便当一张"这里都有什么"的索引。
##
## ═══ 节点结构 ═══
##   World
##   ├── Player              玩家（跨房间不销毁）
##   ├── PauseMenuController 暂停菜单
##   ├── Room                房间容器 —— 具体是哪个房间由 RoomManager 决定
##   └── HUD                 任务 + 背包显示
##
## ⚠️ 房间里的东西（地板、墙、家具、NPC、门、出生点）都【不在这一层】，
##    它们在 Room 底下被动态装进来的那个房间场景里。
##    想改房间内容 → 去 scenes/rooms/ 里改对应的场景。
