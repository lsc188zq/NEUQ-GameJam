extends MainMenu
## 主菜单。
##
## ═══ 这个脚本只管一个地方：存档 ═══
## 其余按钮（选项 / 致谢 / 退出）全是 Maaack 插件自带的，在基类 MainMenu 里，
## 一个字都不用改。
##
## ═══ 「新的游戏」和「载入存档」的区别 ═══
##   新的游戏 → 把状态【清空】（但**不删存档文件** —— 点错了还能读回来），然后进游戏
##   载入存档 → 弹出【三槽位选存档界面】→ 玩家挑一个 → 读档 → 进游戏
##
## ═══ ⚠️ 顺序：选完槽先读档、【再】切场景 ═══
## world.tscn 里的 RoomManager 一 _ready 就会问两件事：
##   "这一局是不是读档进来的？" / "该装哪个房间？"
## 要是先切场景，它看到的是空状态，就会装成默认房间、把人放在出生点 ——
## 读档就白读了。

## 选存档界面（三个槽位的那个）。
## 在检查器里把 scenes/ui/save_slots.tscn 拖进来。
@export var save_slot_scene : PackedScene

## 场景里那个「载入存档」按钮（节点上勾了"在所属场景中唯一名称"）
@onready var load_game_button: Button = %LoadGameButton


func _ready() -> void:
	super()

	# 三个槽【全空】的时候把「载入存档」灰掉。
	# 只要有一个槽存过东西就不灰 —— 点进去还能挑。
	load_game_button.disabled = not _has_any_save()


## 三个存档位里有没有任何一个存过东西？
func _has_any_save() -> bool:
	for slot in range(1, SaveManager.SLOT_COUNT + 1):
		if SaveManager.has_save(slot):
			return true
	return false


func _on_new_game_button_pressed() -> void:
	SaveManager.start_new_game()   # ← 先清空状态
	load_game_scene()              # ← 再进游戏


## 「载入存档」：弹出三槽位界面，让玩家自己挑。
##
## ⚠️ 这里【不读档】—— 读哪个槽由玩家在界面里点。
##    读档和进游戏都在界面的 load_done 信号里做（见下面那行 connect）。
func _on_load_game_button_pressed() -> void:

	if not _has_any_save():
		load_game_button.disabled = true
		return

	var slots := _open_sub_menu(save_slot_scene) as SaveSlots
	if slots == null:
		return

	slots.set_mode(SaveSlots.Mode.LOAD)
	slots.load_done.connect(load_game_scene)    # ← 选完槽、读完档，才切场景
	slots.closed.connect(_on_save_slots_closed)


## 界面关掉之后把它清理掉。
##
## Maaack 的 _open_sub_menu 本来就靠 hidden 信号清理，
## 但我们的弹窗不一定每次都发那个信号，所以自己再兜一道 ——
## 不然反复开关会攒一堆实例在场景树里。
func _on_save_slots_closed() -> void:
	if sub_menu != null:
		sub_menu.queue_free()
		sub_menu = null
