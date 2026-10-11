extends Node
## 房间切换的「传令兵」。
##
## ═══ 为什么需要它 ═══
## 剧本（.dialogue）是纯文本，够不到房间节点。
## 它只能做两件事：开一个开关，或者调某个自动加载的方法。
##
## 所以门那边只写一行：
##     $> Travel.go("hallway", "教室门口")
##                     ↑去哪       ↑到了站在哪个出生点旁边
##
## Travel 记下这个请求，然后【喊一声】。
## 真正换房间的是 world.tscn 里的 RoomManager —— 它听到喊声就去干活。
##
## ═══ 为什么用信号，而不是在这里直接换 ═══
## 因为 Travel 是自动加载，它不知道当前场景是谁、RoomManager 在哪。
## 「喊一声，谁来接谁接」——这样 Travel 和具体场景解耦，
## 以后你有十张地图，这个脚本一个字都不用改。
##
## ═══ 和 GameState 的关系 ═══
## 门开的那两个开关（比如"离开教室"）是【给任务系统用的】，
## 表示"玩家做过这件事"。切房间走的是这个脚本，两条线互不干扰。


## 有人请求换房间。RoomManager 监听这个。
signal go_requested(room_name: String, spawn_name: String)

## 最后一次请求的内容。
## RoomManager 在 _ready 时也要读它 ——
## 因为"请求"可能发生在场景刚加载完、RoomManager 还没准备好的时候。
var room_name: String = ""
var spawn_name: String = ""

## 有没有还没被处理的请求
var _pending: bool = false


## 请求换房间。剧本里这样写：$> Travel.go("hallway", "教室门口")
##
## room_name  : 目标房间的场景文件名（不含 .tscn）。比如 hallway.tscn 就叫 "hallway"
## spawn_name : 到了之后站在哪个出生点旁边（房间里的 SpawnPoints 底下的名字）
##              留空 = 不挪玩家，保持原位置
func go(target_room: String, target_spawn: String = "") -> void:
	room_name = target_room
	spawn_name = target_spawn
	_pending = true
	go_requested.emit(room_name, spawn_name)


## RoomManager 处理完之后调这个，表示"这个请求我接了"。
func consume() -> void:
	_pending = false


func has_pending() -> bool:
	return _pending
