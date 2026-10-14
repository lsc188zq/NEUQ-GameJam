extends Node
## 存档系统。【三个存档位】。
##
## ═══ 存什么 ═══
## 全部来自 GameState —— 这个脚本【只负责读写文件】，自己一个游戏状态都不存。
##
##   flags            开关              {"见过小绿面": true}
##   counters         计数 / 物品        {"钥匙": 1}
##   current_room     在哪个房间         "classroom"
##   position         站在哪             [126, -80]
##   quests_active    进行中的任务       ["帮学长找钥匙"]
##   quests_completed 已完成的任务       ["去见学长"]
##
## ═══ 存在哪 ═══
## user://save_1.json / save_2.json / save_3.json
## 在 Windows 上是 %APPDATA%\Godot\app_userdata\NEUQ-GameJam\
## 【不在项目文件夹里】—— 不会进 git，也不会被 git 操作误删。
##
## ═══ 什么时候存 / 读 ═══
## 【不由这个脚本决定】，全看谁调它：
##   换房间时自动存  → 见 room_manager.gd（存在【当前槽位】里）
##   暂停菜单点保存  → 见 save_slots.gd（玩家选的槽位）
##   主菜单点载入    → 同上
##
## ⚠️ 自动加载顺序：必须排在 GameState / QuestBook 【之后】。
##
## ⚠️ 每次保存都会覆盖那个槽位原来的内容 —— 所以 UI 上要显示"这个槽里现在是什么"，
##    让玩家知道自己在覆盖什么。


## 一共几个【手动】存档位。改这里就能加减（UI 那边会自动跟着变）。
const SLOT_COUNT := 3

## 【自动存档】专用的槽位。
##
## ⚠️ 故意用 0 —— 因为手动槽位是 1..SLOT_COUNT，
##    存档界面只循环 1..SLOT_COUNT，所以这一位【自动不会出现在界面上】，
##    不用额外写"跳过自动存档"的逻辑。
##
## 什么时候写它：玩家走过门换房间时（见 room_manager.gd）。
## 用途：意外退出/崩溃之后，能回到刚才那个房间。
const AUTO_SLOT := 0

## 存档文件的路径格式。%d 会换成槽位号。
const SAVE_PATH_FORMAT := "user://save_%d.json"

## 房间的【显示名】。存档列表上要显示"在哪个房间"，总不能显示 canteen。
##
## ⚠️ 做了新房间，一定要来这里加一行。
##    忘了加不会报错，只会在存档界面上显示成英文文件名 ——
##    所以 save_game() 里有一句警告帮你发现。
const ROOM_LABELS := {
	"classroom": "教室",
	"hallway": "走廊",
	"canteen": "食堂",
}

## 读档完成了。
##
## 【谁在听】RoomManager ——
## 游戏【中途】读档的时候，光恢复 GameState 是不够的：
## 玩家可能在另一个房间，得把那个房间重新装出来、人挪到存档位置。
##
## 开局那次读档不走这个信号（RoomManager 的 _ready 自己处理，
## 因为那时候它还没连上信号）。
signal loaded

## 这一局是不是"读档进来的"。
##
## RoomManager 靠它判断开局该进哪个房间：
##   读档进来的 → 去存档里那个房间，并且把玩家放在存档位置
##   新游戏      → 去默认房间，玩家站在正常出生点
var _loaded: bool = false

## 换房间自动存档时，存到哪个槽位。
## 由"最近一次读档"决定 —— 你从 2 号槽读的档，自动存档就接着存回 2 号。
var current_slot: int = 1


func _ready() -> void:
	# ⚠️ 这里【故意不自动读档】。
	#
	# 读哪个档、读不读，应该由【玩家】决定 ——
	# 主菜单上有「新的游戏」和「载入存档」，玩家点哪个就是哪个。
	# 如果这里自动读档，"新的游戏"就永远是"接着上次玩"。
	pass


# ═══════════════════════════════════════════════════
#  槽位工具
# ═══════════════════════════════════════════════════

func save_path(slot: int) -> String:
	return SAVE_PATH_FORMAT % slot


func has_save(slot: int) -> bool:
	return FileAccess.file_exists(save_path(slot))


## 这一局是不是读档进来的？
func has_loaded() -> bool:
	return _loaded


## 某个槽位里存的是什么。空槽返回 {"exists": false}。
##
## 存档界面上每一行显示的内容就来自这里。
func slot_info(slot: int) -> Dictionary:
	if not has_save(slot):
		return {"exists": false}

	var file := FileAccess.open(save_path(slot), FileAccess.READ)
	if file == null:
		return {"exists": false}
	var text := file.get_as_text()
	file.close()

	var data = JSON.parse_string(text)
	if typeof(data) != TYPE_DICTIONARY:
		return {"exists": true, "broken": true}

	var room_key: String = data.get("current_room", "")
	var unix := FileAccess.get_modified_time(save_path(slot))
	var completed: Array = data.get("quests_completed", [])

	return {
		"exists": true,
		"broken": false,
		"room_key": room_key,
		"room": ROOM_LABELS.get(room_key, room_key),
		"time": Time.get_datetime_string_from_unix_time(unix, true),   # true = UTC
		"quest_count": completed.size(),
		"slot": slot,
	}


# ═══════════════════════════════════════════════════
#  开新游戏
# ═══════════════════════════════════════════════════

## 把状态清空。
##
## 【不删任何存档文件】—— 万一点错了还能回去读档。
## 新进度会在下次保存时把那个槽覆盖掉。
func start_new_game() -> void:
	_loaded = false
	current_slot = 1

	GameState.flags = {}
	GameState.counters = {}
	GameState.completed_quests = []
	GameState.player_position = Vector2.ZERO
	GameState.current_room = "classroom"

	QuestSystem.available.reset()
	QuestSystem.active.reset()
	QuestSystem.completed.reset()

	# ⚠️ 清空之后【必须】把"开局任务"重新接一遍。
	#
	# 不接的后果很隐蔽：那些任务不在 active 池里，
	# 而 QuestTracker 只更新【在 active 池里】的任务 ——
	# 于是它们永远不会完成，HUD 上也不会出现。
	# 表现出来就是"点了新游戏，第一个任务不见了"，
	# 以及"明明做完了该做的事，门还是不开"。
	QuestBook.start_opening_quests()

	# ⚠️ 自动存档【要删掉】。
	#
	# 它是"上一局的现场"。留着的话，下次开机点"继续游戏"
	# 会读到上一局的位置，玩家会一脸问号。
	#
	# 手动存档位（1..3）依然【不删】—— 点错了"新的游戏"还能回去读。
	delete_save(AUTO_SLOT)

	print("【SaveManager】开新游戏：状态已清空，自动存档已删，手动存档没动")


# ═══════════════════════════════════════════════════
#  存
# ═══════════════════════════════════════════════════

## 存到某个槽位。
##
## slot 传什么：
##   -1（默认）    → 用"当前槽"（current_slot）
##   AUTO_SLOT(0)  → 自动存档位【不影响当前槽】
##   1..SLOT_COUNT → 玩家在存档界面上选的位
func save_game(slot: int = -1) -> void:
	if slot < 0:
		slot = current_slot

	# ⚠️ 只有【玩家手动选的槽】才更新"当前槽"。
	#    自动存档不能改它 —— 否则你手动存在 2 号位，
	#    走两步路之后"当前槽"就被自动存档顶掉了。
	if slot != AUTO_SLOT:
		current_slot = slot

	# ⚠️ 先记录玩家现在站在哪，再存。
	#    不然存的是"上一次换房间时"的旧位置。
	_capture_player_position()

	var data := {
		"slot":             slot,
		"flags":            GameState.flags,
		"counters":         GameState.counters,
		"current_room":     GameState.current_room,
		"position":         [GameState.player_position.x, GameState.player_position.y],
		"quests_active":    _quest_names(QuestSystem.get_active_quests()),
		"quests_completed": _quest_names(QuestSystem.completed.get_all_quests()),
	}

	var path := save_path(slot)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_warning("【SaveManager】存档写不进去：%s" % path)
		return

	# 带缩进写，方便你自己用记事本打开看
	file.store_string(JSON.stringify(data, "\t"))
	file.close()

	print("【SaveManager】已存到 %d 号位（房间=%s，位置=%s）" % [slot, GameState.current_room, GameState.player_position])

	# 房间没配中文显示名的话，存档界面上会直接显示英文文件名（比如 canteen）。
	# 那种"看起来没坏但就是不对劲"的问题最难发现，所以这里主动喊一声。
	if not ROOM_LABELS.has(GameState.current_room):
		push_warning("【SaveManager】房间「%s」还没配中文显示名，存档列表上会显示成英文。去 save_manager.gd 的 ROOM_LABELS 里加一行。" % GameState.current_room)


# ═══════════════════════════════════════════════════
#  读
# ═══════════════════════════════════════════════════

func load_game(slot: int) -> bool:
	if not has_save(slot):
		return false

	var file := FileAccess.open(save_path(slot), FileAccess.READ)
	if file == null:
		push_warning("【SaveManager】存档读不出来：%s" % save_path(slot))
		return false

	var text := file.get_as_text()
	file.close()

	var data = JSON.parse_string(text)
	if typeof(data) != TYPE_DICTIONARY:
		push_warning("【SaveManager】%d 号位的存档坏了" % slot)
		return false

	# ── 恢复状态 ──
	GameState.flags = data.get("flags", {})
	GameState.counters = data.get("counters", {})
	GameState.current_room = data.get("current_room", "classroom")

	var pos: Array = data.get("position", [0.0, 0.0])
	GameState.player_position = Vector2(float(pos[0]), float(pos[1]))

	_restore_quests(data)

	_loaded = true
	current_slot = slot
	print("【SaveManager】已读 %d 号位（房间=%s，位置=%s）" % [slot, GameState.current_room, GameState.player_position])
	loaded.emit()
	return true


## 删掉某个槽位。
func delete_save(slot: int) -> void:
	if not has_save(slot):
		return
	DirAccess.remove_absolute(save_path(slot))
	print("【SaveManager】%d 号位已删除" % slot)


# ═══════════════════════════════════════════════════
#  内部
# ═══════════════════════════════════════════════════

## 把玩家现在的位置记到 GameState 里。
##
## 怎么找到玩家：从"当前场景"往下找叫 Player 的子节点。
## 找不到就算了（比如你正在主菜单、或者还没进游戏）——
## 这时候不该报错，跳过就行。
func _capture_player_position() -> void:
	var world := get_tree().current_scene
	if world == null:
		return
	var player := world.get_node_or_null("Player") as Node2D
	if player == null:
		return
	GameState.player_position = player.global_position


func _quest_names(quests: Array) -> Array:
	var names: Array = []
	for quest in quests:
		if quest != null:
			names.append(quest.quest_name)
	return names


## 按存档重建三个任务池。
##
## ⚠️ 为什么先 reset 再重建：
##    QuestBook 在自己的 _ready 里接了一批"开局任务"，
##    读档时那些【不该】被接上（玩家可能早就做完了）。
##    所以把三个池子清空，完全照存档来。
##
## ⚠️ 为什么"已完成"的要先 start 再 complete：
##    QuestSystem.complete_quest() 要求任务【已经在 active 池里】，
##    不在的话它直接返回、什么都不做 —— 而且是静默的，不报错。
func _restore_quests(data: Dictionary) -> void:
	QuestSystem.available.reset()
	QuestSystem.active.reset()
	QuestSystem.completed.reset()

	for quest_name in data.get("quests_active", []):
		QuestBook.start(quest_name)

	for quest_name in data.get("quests_completed", []):
		QuestBook.start(quest_name)      # 先接上，让它进 active 池
		QuestBook.complete(quest_name)   # 再标记完成，移进 completed 池
