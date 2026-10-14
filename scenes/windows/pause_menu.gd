@tool
extends PopupWindowPanel

@export var options_menu_scene : PackedScene
## 选存档界面（三个槽位的那个）。在检查器里把 scenes/ui/save_slots.tscn 拖进来。
##
## ⚠️ 不拖的话「保存游戏」按钮点了会报警告、弹不出界面。
@export var save_slot_scene : PackedScene
## Path to a main menu scene.
## Will use ProjectSettings paths if left empty.
@export_file("*.tscn") var main_menu_scene_path : String

@onready var restart_confirmation = %RestartConfirmation
@onready var main_menu_confirmation = %MainMenuConfirmation
@onready var exit_confirmation = %ExitConfirmation
@onready var options_button = %OptionsButton
@onready var main_menu_button = %MainMenuButton
@onready var exit_button = %ExitButton
## If Maaack's Scene Loader is installed, then it will be used to change scenes.
@onready var scene_loader_node = get_tree().root.get_node_or_null(^"SceneLoader")

var open_window : Node
var restarting : bool = false

func get_main_menu_scene_path() -> String:
	return MaaacksMenusTemplate.get_main_menu_path(main_menu_scene_path)

func close_window() -> void:
	if open_window != null:
		if open_window.has_method(&"close"):
			open_window.close()
		else:
			open_window.hide()
		open_window = null

func _load_scene(scene_path: String) -> void:
	_scene_tree.paused = false
	if scene_loader_node:
		scene_loader_node.load_scene(scene_path)
	else:
		get_tree().change_scene_to_file(scene_path)

func _show_window(window : Control) -> void:
	window.show()
	open_window = window
	await window.hidden
	open_window = null

func _load_and_show_menu(scene : PackedScene) -> void:
	var window_instance : Control = scene.instantiate()
	window_instance.visible = false
	add_sibling.call_deferred(window_instance)
	await _show_window(window_instance)
	window_instance.queue_free()

func _handle_cancel_input() -> void:
	if open_window != null:
		return
	super._handle_cancel_input()

func _refresh_exit_button() -> void:
	exit_button.visible = !OS.has_feature("web")

func _refresh_options_button() -> void:
	options_button.visible = options_menu_scene != null

func _refresh_main_menu_button() -> void:
	main_menu_button.visible = !get_main_menu_scene_path().is_empty()

func _ready() -> void:
	super._ready()
	_refresh_exit_button()
	_refresh_options_button()
	_refresh_main_menu_button()
	restart_confirmation.confirmed.connect(_on_restart_confirmation_confirmed)
	restart_confirmation.closed.connect(_on_restart_confirmation_closed)
	main_menu_confirmation.confirmed.connect(_on_main_menu_confirmation_confirmed)
	exit_confirmation.confirmed.connect(_on_exit_confirmation_confirmed)

func _on_restart_button_pressed() -> void:
	_show_window(restart_confirmation)

func _on_options_button_pressed() -> void:
	_load_and_show_menu(options_menu_scene)


## 「保存游戏」按钮。弹出三槽位的存档界面，模式是【保存】。
##
## 为什么不直接用 _load_and_show_menu()：
##    那个函数没法在"显示之前"给界面设置模式，
##    而存档界面必须先知道自己是来存的还是来读的，否则标题和灰按钮都是错的。
func _on_save_button_pressed() -> void:
	if save_slot_scene == null:
		push_warning("【暂停菜单】没配 save_slot_scene，把 scenes/ui/save_slots.tscn 拖进检查器那一栏")
		return

	var slots := save_slot_scene.instantiate() as SaveSlots
	slots.visible = false
	add_sibling.call_deferred(slots)

	# 等它进场景树、_ready 跑完，再设模式（set_mode 里会顺便刷新界面文字）
	await slots.ready
	slots.set_mode(SaveSlots.Mode.SAVE)

	# 关掉之后自己清理掉，别留一堆实例在场景树里
	slots.closed.connect(slots.queue_free)

	_show_window(slots)

func _on_main_menu_button_pressed() -> void:
	_show_window(main_menu_confirmation)

func _on_exit_button_pressed() -> void:
	_show_window(exit_confirmation)

func _on_restart_confirmation_confirmed() -> void:
	restarting = true

func _on_restart_confirmation_closed() -> void:
	if restarting:
		await draw
		get_tree().reload_current_scene()

func _on_main_menu_confirmation_confirmed():
	_load_scene(get_main_menu_scene_path())

func _on_exit_confirmation_confirmed():
	get_tree().quit()
