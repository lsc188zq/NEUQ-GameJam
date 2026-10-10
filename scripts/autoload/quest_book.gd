extends Node
## 任务登记处。把「任务名字」翻译成「任务资源」。
##
## ═══ 为什么需要它 ═══
## 剧本（.dialogue）是纯文本，只能用一行代码触发任务：
##     $> QuestBook.start("帮学长找钥匙")
## 文本里写不出「资源对象」，只能写名字。
## 这个自动加载就是那张「名字 → 任务资源」的查找表。
##
## ═══ 成员怎么用 ═══
##   ① 做一个任务 .tres（见 docs）
##   ② 把 .tres 拖进 quest_book.tscn 的 all_quests 数组里
##   ③ 剧本里写：$> QuestBook.start("你填的任务名")
##
## ═══ ⚠️ 为什么用【场景】当自动加载而不是脚本 ═══
## 自动加载如果直接挂一个 .gd 脚本，它的 @export 数组在编辑器里【改不了】。
## 挂一个 .tscn 就能在检查器里编辑了 —— 所以是 quest_book.tscn。
##
## ═══ ⚠️ 为什么要有 all_quests 这个数组 ═══
## 因为导出（Export）时，只有被某个场景/资源【引用过】的文件才会被打包。
## 光把 .tres 丢在文件夹里，导出后游戏里【找不到】。
## 这个数组就是那个"引用"，保证任务文件一定会被导出。

## 所有任务。做好的 .tres 往这里拖。
@export var all_quests: Array[Quest] = []

## 开局【自动接取】的任务。想让它一进游戏就挂在 HUD 上的，拖到这里。
## 需要玩家先跟某人说话才接的（比如"帮学长找钥匙"），
## 【不要】放这里 —— 在剧本里用 QuestBook.start("...") 接。
@export var opening_quests: Array[Quest] = []

## 名字 → 任务
var _by_name: Dictionary = {}


func _ready() -> void:
	_index()
	_start_opening_quests()
	# 启动时打一行，方便一眼看出"我的任务登记上没有"。
	# 成员新加了一个任务 .tres 却忘了拖进 all_quests 时，看这行就知道了。
	print("【QuestBook】已登记 %d 个任务：%s" % [_by_name.size(), ", ".join(_by_name.keys())])


## 建索引。同名任务后者覆盖前者（会在输出面板提醒）。
func _index() -> void:
	_by_name.clear()
	for quest in all_quests:
		if quest == null:
			continue
		if quest.quest_name.is_empty():
			push_warning("【QuestBook】有个任务没填 quest_name，跳过了")
			continue
		if _by_name.has(quest.quest_name):
			push_warning("【QuestBook】有两个任务都叫「%s」，后一个覆盖前一个" % quest.quest_name)
		_by_name[quest.quest_name] = quest


func _start_opening_quests() -> void:
	for quest in opening_quests:
		if quest != null:
			QuestSystem.start_quest(quest)


# ═══════════════════════════════════════════════════
#  给剧本用的接口
# ═══════════════════════════════════════════════════

## 按名字查任务。查不到返回 null 并警告 ——
## 警告很重要：剧本里写错一个字，任务就静默不触发，很难查。
func get_quest(quest_name: String) -> Quest:
	var quest: Quest = _by_name.get(quest_name)
	if quest == null:
		push_warning("【QuestBook】找不到叫「%s」的任务，检查名字有没有写错" % quest_name)
	return quest


## 开始一个任务。剧本里：$> QuestBook.start("帮学长找钥匙")
func start(quest_name: String) -> void:
	var quest := get_quest(quest_name)
	if quest != null:
		QuestSystem.start_quest(quest)


## 手动完成一个任务（一般不用 —— 任务会自己判断条件）。
func complete(quest_name: String) -> void:
	var quest := get_quest(quest_name)
	if quest != null:
		quest.objective_completed = true
		QuestSystem.complete_quest(quest)


## 这个任务正在进行中吗？剧本条件里可以这样用：
##     [if QuestBook.is_active("帮学长找钥匙") /]
func is_active(quest_name: String) -> bool:
	var quest := get_quest(quest_name)
	return quest != null and QuestSystem.is_quest_active(quest)


## 这个任务完成了吗？
func is_done(quest_name: String) -> bool:
	var quest := get_quest(quest_name)
	return quest != null and QuestSystem.is_quest_completed(quest)
