@tool
extends PopupWindowPanel
class_name SaveSlots
## 选存档界面。三个槽位，**保存和读取共用这一个界面**。
##
## ═══ 谁会用这个界面 ═══
##   暂停菜单的「保存游戏」 → setup(Mode.SAVE) 然后 show()
##   主菜单的「载入存档」   → setup(Mode.LOAD) 然后 show()
##
## ═══ 点了槽位之后 ═══
##   保存模式 · 槽是空的   → 直接存，然后刷新这一行（显示新存的内容）✓
##   保存模式 · 槽里有东西 → **也是直接存**（覆盖）
##                           —— 因为这一行本来就显示着"里面现在是什么"，
##                              玩家看清楚了才点的
##   读取模式 · 槽是空的   → 按钮是【灰的】，点不了 ✓
##   读取模式 · 槽里有东西 → 读档 → 关掉界面 → 发 load_done 信号
##
## ═══ 为什么是 @tool ═══
## Maaack 的弹窗基类全都带 @tool（这样编辑器里能直接看到效果），
## 子类不跟着加的话，编辑器里加载会报错。

enum Mode { SAVE, LOAD }

const CIRCLED := ["①", "②", "③"]

## 读取模式下，成功读档并关掉界面之后发出。
## 主菜单收到它就切到游戏场景。
## （保存模式不发 —— 存完还留在这个界面，让玩家看得见"存成功了"。）
signal load_done

## 现在是来存的还是来读的
var mode: Mode = Mode.SAVE

@onready var _slot_buttons: Array[Button] = [%Slot1Button, %Slot2Button, %Slot3Button]


func _ready() -> void:
	super()

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
#  三个槽位按钮
# ═══════════════════════════════════════════════════

func _on_slot_pressed(slot: int) -> void:
	if mode == Mode.SAVE:
		SaveManager.save_game(slot)
		_refresh()          # 立刻刷新，让玩家看到"这一行现在有我刚存的东西了"
		return

	# ── 读取模式 ──
	if not SaveManager.load_game(slot):
		_refresh()          # 读失败（存档坏了之类），刷新一下状态
		return

	close()                 # 关掉界面
	load_done.emit()        # 通知主菜单"该进游戏了"


# ═══════════════════════════════════════════════════
#  刷新界面
# ═══════════════════════════════════════════════════

## 把三行按钮的文字、灰不灰、标题、提示语全部重画一遍。
## 每次打开、每次存完，都会调它。
func _refresh() -> void:
	title = "保存游戏" if mode == Mode.SAVE else "载入存档"

	text = (
		"选一个位置保存。\n已经有存档的位置会被【覆盖】。"
		if mode == Mode.SAVE
		else "选一个存档继续玩。\n（空的位置是灰的，说明还没存过。）"
	)

	for i in _slot_buttons.size():
		_refresh_slot(i + 1)


func _refresh_slot(slot: int) -> void:
	var button := _slot_buttons[slot - 1]
	var info := SaveManager.slot_info(slot)
	var mark: String = CIRCLED[slot - 1]

	if not info.get("exists", false):
		button.text = "%s　（空）" % mark
		# 读取模式下，空槽点不了 —— 一眼就知道"这里没东西可读"
		button.disabled = (mode == Mode.LOAD)
		return

	if info.get("broken", false):
		button.text = "%s　⚠ 存档坏了" % mark
		button.disabled = (mode == Mode.LOAD)
		return

	button.text = "%s　%s · %s" % [mark, info.room, info.time]
	button.disabled = false
