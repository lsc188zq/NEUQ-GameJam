@tool
extends PopupWindowPanel
class_name SaveSlots
## 选存档界面。**保存和读取共用这一个界面**。
##
## ═══ 谁会用这个界面 ═══
##   暂停菜单的「保存游戏」 → set_mode(Mode.SAVE) 然后 show()
##   主菜单的「载入存档」   → set_mode(Mode.LOAD) 然后 show()
##
## ═══ 里面有哪些行 ═══
##   自动存档   ← **只在读取模式出现**（见下面 _refresh 里的说明）
##   ① ② ③     ← 手动存档位，两种模式都出现
##
## ═══ 点了之后 ═══
##   保存模式 · 槽是空的   → 直接存，然后刷新这一行 ✓
##   保存模式 · 槽里有东西 → **也是直接存**（覆盖）
##                           —— 这一行本来就显示着"里面现在是什么"，
##                              玩家看清楚了才点的
##   读取模式 · 槽是空的   → 按钮【灰掉】，点不了 ✓
##   读取模式 · 槽里有东西 → 读档 → 关掉界面 → 发 load_done 信号
##
## ═══ 为什么是 @tool ═══
## Maaack 的弹窗基类全都带 @tool，子类不跟着加的话，编辑器里加载会报错。

enum Mode { SAVE, LOAD }

## 三个手动存档位前面的圈码
const CIRCLED := ["①", "②", "③"]

## 读取模式下，成功读档并关掉界面之后发出。
## 主菜单收到它就切到游戏场景。
## （保存模式不发 —— 存完还留在这个界面，让玩家看得见"存成功了"。）
signal load_done

## 现在是来存的还是来读的
var mode: Mode = Mode.SAVE

@onready var _auto_button: Button = %AutoSlotButton
@onready var _slot_buttons: Array[Button] = [%Slot1Button, %Slot2Button, %Slot3Button]


func _ready() -> void:
	super()

	# 自动存档位（0 号）单独一个按钮
	_auto_button.pressed.connect(_on_slot_pressed.bind(SaveManager.AUTO_SLOT))

	for i in _slot_buttons.size():
		_slot_buttons[i].pressed.connect(_on_slot_pressed.bind(i + 1))

	_refresh()


# ═══════════════════════════════════════════════════
#  给外面调用的接口
# ═══════════════════════════════════════════════════

## 打开之前先调这个，告诉它是来存的还是来读的。
##
## ⚠️ 名字故意不叫 setup() —— Maaack 的弹窗基类可能已经占了这个名字，
##    撞上了会覆盖基类的行为，那种 bug 很难查。
func set_mode(new_mode: Mode) -> void:
	mode = new_mode
	if is_node_ready():
		_refresh()


# ═══════════════════════════════════════════════════
#  点了某一行
# ═══════════════════════════════════════════════════

func _on_slot_pressed(slot: int) -> void:
	if mode == Mode.SAVE:
		SaveManager.save_game(slot)
		_refresh()          # 立刻刷新，让玩家看到"这一行现在有我刚存的东西了"
		return

	# ── 读取模式 ──
	if not SaveManager.load_game(slot):
		_refresh()          # 读失败（存档坏了之类）
		return

	close()                 # 关掉界面
	load_done.emit()        # 通知主菜单"该进游戏了"


# ═══════════════════════════════════════════════════
#  刷新界面
# ═══════════════════════════════════════════════════

## 把每一行的文字、灰不灰、标题、提示语全部重画一遍。
## 每次打开、每次存完，都会调它。
func _refresh() -> void:
	title = "保存游戏" if mode == Mode.SAVE else "载入存档"

	text = (
		"选一个位置保存。\n已经有存档的位置会被【覆盖】。"
		if mode == Mode.SAVE
		else "选一个存档继续玩。\n（灰色的位置说明还没存过。）"
	)

	# ⚠️ 【自动存档只在读取模式出现】。
	#
	# 保存模式下也显示它的话，玩家会以为能手动存进"自动存档位" ——
	# 而那个位子是【走过门时自动写的】，手动存进去，
	# 下次一换房间就被自动存档盖掉了，玩家会觉得"我存的档丢了"。
	_auto_button.visible = (mode == Mode.LOAD)
	if mode == Mode.LOAD:
		_refresh_slot(SaveManager.AUTO_SLOT)

	for i in _slot_buttons.size():
		_refresh_slot(i + 1)


## 槽位 → 按钮。0 号位（自动存档）是单独一个按钮，不走数组。
func _button_for(slot: int) -> Button:
	if slot == SaveManager.AUTO_SLOT:
		return _auto_button
	return _slot_buttons[slot - 1]


## 槽位前面那个标记。0 号位不叫"⓪"，直接写"自动存档"。
func _slot_mark(slot: int) -> String:
	if slot == SaveManager.AUTO_SLOT:
		return "自动存档"
	return CIRCLED[slot - 1]


func _refresh_slot(slot: int) -> void:
	var button := _button_for(slot)
	var info := SaveManager.slot_info(slot)
	var mark := _slot_mark(slot)

	if not info.get("exists", false):
		button.text = (
			"自动存档　（还没有）" if slot == SaveManager.AUTO_SLOT
			else "%s　（空）" % mark
		)
		# 读取模式下，空槽点不了 —— 一眼就知道"这里没东西可读"
		button.disabled = (mode == Mode.LOAD)
		return

	if info.get("broken", false):
		button.text = "%s　⚠ 存档坏了" % mark
		button.disabled = (mode == Mode.LOAD)
		return

	button.text = "%s　%s · %s" % [mark, info.room, info.time]
	button.disabled = false
