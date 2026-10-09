@tool
extends Quest
class_name SimpleQuest
## 「开关型」任务：GameState 里某个开关变成 true，任务就自动完成。
##
## ═══ 成员怎么用（全程不用写代码）═══
##   ① 复制一份 content/quests/ 里现成的 .tres，改名
##   ② 双击打开，在检查器里填四个框：
##        id / quest_name / quest_description / complete_flag
##   ③ 在剧本里写：$> GameState.set_flag("你填的那个开关名")
##
## ═══ 为什么要重写 update() ═══
## 插件自带的 Quest.update() 是【空的】—— 它只会发一个信号，
## 根本不知道什么算完成。条件必须我们自己写。
## 插件文档原话：要做自定义任务，就继承 Quest 实现自己的逻辑。
##
## ═══ 谁在什么时候调 update() ═══
## QuestTracker（自动加载）一听到 GameState 有东西变了，
## 就把所有【进行中】的任务挨个 update 一遍。
## 也就是说：**任务不会自己检查自己 —— 必须有人叫它。**
##
## ═══ 为什么是 @tool ═══
## 不带 @tool 的话，Godot 编辑器【不允许实例化这个脚本】，
## 成员就没法在 FileSystem 面板里右键新建它的资源。
## 加上之后编辑器才肯创建。
## （它的方法在编辑器里不会被调用，所以 @tool 没有副作用。）
##
## 适用：和某人说过话 / 捡到钥匙 / 进过机房 这类「做过没有」。


## 完成条件：GameState 里这个开关变成 true 时，任务自动完成。
@export var complete_flag: String = ""


func update(_args: Dictionary = {}) -> void:
	super()
	if complete_flag.is_empty():
		return
	if not GameState.get_flag(complete_flag):
		return

	# ⚠️ 这两句的【顺序不能反】：
	#   插件默认要求「目标已完成」才允许完成任务
	#   （项目设置 → quest_system/config/require_objective_completed = true）
	#   所以必须先设 objective_completed，再调 complete_quest()。
	#
	#   反过来写的后果很坑：complete_quest() 会【静默拒绝】——
	#   不报错、不警告，任务就是不动，能查半天。
	objective_completed = true
	QuestSystem.complete_quest(self)
