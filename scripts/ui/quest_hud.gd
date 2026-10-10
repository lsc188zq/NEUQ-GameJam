extends CanvasLayer
## 任务 HUD：左上角显示当前正在进行的任务。
##
## ═══ 为什么必须有它 ═══
## QuestSystem 是【纯逻辑】的 —— 一个像素的 UI 都没有。
## 没有 HUD 的话，任务接下了、完成了，玩家屏幕上一点变化都没有，等于没做。
##
## ═══ 它只做两件事 ═══
##   ① 听到 quest_accepted  → 刷新列表
##   ② 听到 quest_completed → 弹一下"✓ 完成"，几秒后刷新列表
##
## 数据全部来自 QuestSystem，这个脚本自己【不存任何任务状态】。
## 所以"任务到底完成没有"永远以 QuestSystem 为准，
## 不会出现"HUD 显示完成了但其实没完成"这种不一致。

## "✓ 完成" 停留几秒
const DONE_HOLD_SECONDS: float = 3.0

## 任务【进行中】时文字的颜色（蓝）
const COLOR_ACTIVE := Color(0.35, 0.65, 1.0)

## 任务【完成】提示的颜色（红）
const COLOR_DONE := Color(1.0, 0.35, 0.3)

@onready var _label: Label = $QuestLabel

## 防止"完成"提示被刷掉：
## 如果连着完成两个任务，第二次的提示会打断第一次的计时。
## 这个变量记着现在是不是正在显示完成提示。
var _showing_done: bool = false


func _ready() -> void:
	QuestSystem.quest_accepted.connect(_on_quest_changed)
	QuestSystem.quest_completed.connect(_on_quest_completed)
	_refresh()


func _on_quest_changed(_quest: Quest) -> void:
	if not _showing_done:
		_refresh()


func _on_quest_completed(quest: Quest) -> void:
	_showing_done = true
	_label.add_theme_color_override("font_color", COLOR_DONE)
	_label.text = "✓ " + quest.quest_name + "　完成"
	await get_tree().create_timer(DONE_HOLD_SECONDS).timeout
	_showing_done = false
	_refresh()


## 把【当前所有进行中的任务】列出来。
## 一条都没有时显示空字符串（Label 就看不见了）。
func _refresh() -> void:
	# 一进这个函数就先把颜色设回"进行中"的蓝色 ——
	# 这样刚显示完红色的"✓ 完成"之后，会正确切回蓝色。
	_label.add_theme_color_override("font_color", COLOR_ACTIVE)

	var active := QuestSystem.get_active_quests()

	if active.is_empty():
		_label.text = ""
		return

	var lines: PackedStringArray = []
	for quest in active:
		lines.append("【任务】" + quest.quest_name)
		# 有目标的就把目标也列出来
		if not quest.quest_objective.is_empty():
			lines.append("　　" + quest.quest_objective)

	_label.text = "\n".join(lines)
