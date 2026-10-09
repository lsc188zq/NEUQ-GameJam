@tool
extends Quest
class_name CountQuest
## 「计数型」任务：GameState 里某个计数器达到要求数量，任务就自动完成。
##
## ═══ 成员怎么用（全程不用写代码）═══
##   ① 复制一份 content/quests/ 里现成的 .tres，改名
##   ② 双击打开，在检查器里填：
##        id / quest_name / quest_description / counter_key / required
##   ③ 在剧本或代码里写：$> GameState.bump("你填的那个计数器名")
##
## ═══ 和 SimpleQuest 的区别 ═══
##   SimpleQuest：开关 true/false  —— "做过没有"
##   CountQuest ：计数器 数字      —— "够不够数"
##
## 两个类共用同一套触发机制（QuestTracker 在 GameState 变化时挨个 update），
## 所以混着用没问题。
##
## 适用：收集 5 个零件 / 和 3 个人说过话 / 看过 2 块告示牌。


## 计数的名字。**物品名直接填这里** ——
## 因为在本项目里"物品"本质上就是"名叫钥匙的计数器"，
## GameState 的 bump() 加的也是同一个字典。
@export var counter_key: String = ""

## 要凑够几个
@export var required: int = 1


func update(_args: Dictionary = {}) -> void:
	super()
	if counter_key.is_empty():
		return
	if GameState.get_count(counter_key) < required:
		return

	# ⚠️ 先设 objective_completed 再 complete_quest()，顺序不能反。
	#   原因见 simple_quest.gd 里的详细说明（complete_quest 会静默拒绝）。
	objective_completed = true
	QuestSystem.complete_quest(self)
