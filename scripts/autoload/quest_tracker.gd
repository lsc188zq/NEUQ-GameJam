extends Node
## 任务追踪器。把「GameState 里有东西变了」翻译成「重新检查所有任务」。
##
## ═══ 为什么需要这个自动加载 ═══
## QuestSystem 是【被动】的：不主动调 QuestSystem.update_quest(q)，
## 任务里的 update() 就永远不会跑。
##
## 而"玩家干了件事"这个信息，只会以 GameState 的 value_changed 信号出现。
## 这个小脚本干的就是把这两头接起来：
##
##     GameState 有东西变了
##             ↓
##     遍历所有【进行中】的任务，挨个 update_quest()
##             ↓
##     SimpleQuest / CountQuest 在里面一查：
##         "我要的那个开关 / 那个计数到位了吗？"
##             ↓ 到位了
##     objective_completed = true → QuestSystem.complete_quest()
##
## ═══ 为什么用 call_deferred ═══
## QuestSystem.start_quest() 的内部顺序是：
##     active.add_quest() → 发 quest_accepted 信号 → quest.start()
##
## 信号是在 start() 【之前】发出的。如果在信号里同步跑检查，
## 就会在任务还没 start() 的时候去 update 它。
## 推迟到本帧末尾再跑，这个顺序问题就不存在了。
##
## ═══ 自动加载顺序 ═══
## 这个脚本必须在 GameState 和 QuestSystem 【之后】注册，
## 否则 _ready() 里找不到它们。
## （project.godot 的 [autoload] 段是从上往下执行的。）


func _ready() -> void:
	GameState.value_changed.connect(_on_game_state_changed)
	QuestSystem.quest_accepted.connect(_on_quest_accepted)


## GameState 里任何东西变了（开关 / 计数）都会走到这里。
func _on_game_state_changed(_key: String, _value) -> void:
	_recheck_all.call_deferred()


## 刚接下一个任务时也立刻判一次 —— 说不定条件早就满足了。
func _on_quest_accepted(_quest: Quest) -> void:
	_recheck_all.call_deferred()


## 把所有进行中的任务重新检查一遍。
func _recheck_all() -> void:
	# ⚠️ 这里的 duplicate() 【不能省】：
	#    任务在 update() 里可能就完成了，完成时会被从 active 池里【移除】。
	#    直接遍历原数组 = 边遍历边删元素 —— 会漏掉任务，甚至报错。
	for quest in QuestSystem.get_active_quests().duplicate():
		QuestSystem.update_quest(quest)
