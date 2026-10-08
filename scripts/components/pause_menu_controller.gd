extends Node
## 暂停控制器。挂在游戏场景里的一个普通 Node 上。
##
## ⚠️ 为什么不用插件自带的 pause_menu_controller.gd：
##
##    自带那个的做法是：先把菜单 add 到【当前场景】（Node2D）下面，
##    等打开时再 reparent 到 CanvasLayer。
##
##    问题是 Godot 的 reparent() 默认会"保持原来的屏幕位置"——
##    菜单在 Node2D 下时锚点算错了位置，reparent 又把这个错误位置原样搬了过去。
##    结果：菜单确实挪到了 CanvasLayer 下，但停在左上角。
##
##    本脚本的做法：自己建一个 CanvasLayer，从第一帧起就把菜单放在它下面，
##    中间不经过 Node2D —— 锚点从一开始就算对，位置自然是居中的。
##
## ⚠️ 配套要求：
##    1. 检查器里必须给 `Pause Menu Packed` 指定 pause_menu.tscn
##    2. pause_menu.tscn 的 `Parent Scene` 属性必须清空
##       （否则菜单的 open() 里还会再 reparent 一次）

## 暂停菜单场景。
## ⚠️ 必须在检查器里指定！不指定的话游戏一启动就会报警告。
@export var pause_menu_packed: PackedScene

## 用哪个输入动作触发暂停。
## 默认用你自定义的 "pause"；如果没建，用内置的 "ui_cancel"（ESC）也行。
@export var pause_action: StringName = &"pause"

var _menu: Control
var _layer: CanvasLayer


func _ready() -> void:
	# ── 防呆检查 ──
	# 不检查的话，下面那句会对 null 调 instantiate()，
	# 报错信息是 "Cannot call method 'instantiate' on a null value" ——
	# 完全看不出真正的原因（忘了在检查器里指定场景）。
	if pause_menu_packed == null:
		push_error("【暂停控制器】没有指定暂停菜单场景！" +
			"请在检查器里把 Pause Menu Packed 设为 pause_menu.tscn。" +
			"这个节点在：" + str(get_path()))
		return

	# ① 建一个 CanvasLayer 当菜单的家
	_layer = CanvasLayer.new()
	_layer.name = "PauseLayer"
	_layer.layer = 10          # 层级调高一点，保证盖在其它 UI 上面
	add_child(_layer)

	# ② 实例化菜单
	_menu = pause_menu_packed.instantiate()

	# ⚠️ 必须在 add_child 之前就隐藏。
	# 因为插件的 PopupWindowPanel 在 _ready 里有这么一句：
	#     if is_visible_in_tree(): await _popup_open_coroutine()
	# 如果加进树的时候是可见的，它就会立刻执行那套 reparent 逻辑。
	_menu.hide()

	# ③ 挂到 CanvasLayer 下面（不经过 Node2D）
	_layer.add_child(_menu)


func _unhandled_input(event: InputEvent) -> void:
	if _menu == null:
		return
	if event.is_action_pressed(pause_action):
		_toggle()


func _toggle() -> void:
	# ⚠️ 用 is_opened 判断，不要用 visible。
	# open() / close() 除了显示隐藏，还会自动处理暂停、鼠标可见性、焦点。
	if _menu.is_opened:
		_menu.close()
	else:
		_menu.open()
