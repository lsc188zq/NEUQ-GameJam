extends Node2D
## 房间管理器。挂在 world.tscn 的 Room 节点上。
##
## ═══ 它干三件事 ═══
##   ① 开局把「起始房间」装进来（默认 classroom）
##   ② 听到 Travel.go_requested 就换房间
##   ③ 换完之后把玩家挪到对应的出生点
##
## ═══ ⚠️ 为什么 rooms 是个数组，而不是按名字 load() ═══
## 导出（Export）时，只有被某个场景或资源【引用过】的文件才会被打包。
## 光按字符串路径 load()，导出后游戏里会找不到这些房间场景。
## 这个数组就是那个"引用"，保证房间一定会被导出。
##
## 房间的「名字」= 场景文件的名字（不含 .tscn）。
## 比如 hallway.tscn 就叫 "hallway"。
##
## 用法：做了新房间 → 拖进下面这个 rooms 数组 → 剧本里 $> Travel.go("房间名")

## 所有房间场景。做了新房间就往这里拖。
@export var rooms: Array[PackedScene] = []

## 开局装哪个房间（填上面某个房间的名字）
@export var default_room: String = "classroom"

## 一个瓦片的像素尺寸。和 TileSet 里设的要一致。
## （相机边界要用：格坐标 × 这个 = 像素坐标）
const TILE_SIZE: int = 16

## 当前装着的房间节点
var _current: Node = null

## 名字 → 场景
var _by_name: Dictionary = {}


func _ready() -> void:
	# ⚠️ 这个必须开。
	# y 排序只在【每一层】都开着 y_sort_enabled 的时候才会递归下去。
	# 少开一层，房间里的家具就会整块按 Room 自己的 Y 排序，
	# 结果就是"玩家永远被家具压在下面"。
	y_sort_enabled = true

	for scene in rooms:
		if scene == null:
			continue
		# resource_path 形如 res://scenes/rooms/hallway.tscn
		# get_file() → hallway.tscn，get_basename() → hallway
		_by_name[scene.resource_path.get_file().get_basename()] = scene

	Travel.go_requested.connect(_on_go_requested)

	# 游戏【中途】读档 —— 得把房间重新装出来。
	# ⚠️ 开局那次读档走不到这里：SaveManager 是自动加载，
	#    它的 _ready 比场景早，那时候这个连接还没建立。
	#    开局的情况由下面那段 if 处理。
	SaveManager.loaded.connect(_on_save_loaded)

	# 开局进哪个房间，按优先级三选一：
	#   ① Travel 有没处理的请求 → 用它（留给"从主菜单直接进某个房间"）
	#   ② 这一局是【读档】进来的 → 去存档里那个房间，玩家待在存档位置
	#   ③ 新游戏                → 默认房间，玩家站正常出生点
	if Travel.has_pending():
		_switch_to(Travel.room_name, Travel.spawn_name)
	elif SaveManager.has_loaded():
		_switch_to(GameState.current_room, "")   # 出生点留空 = 不挪玩家
		_apply_saved_position()
	else:
		_switch_to(default_room, "")


## 游戏中途读档了：重新装出存档里那个房间，人放回存档位置。
##
## 为什么不能只恢复 GameState：玩家可能在另一个房间 ✗
## 房间节点是照着"当时那个房间"建的，得整个换掉。
func _on_save_loaded() -> void:
	_switch_to(GameState.current_room, "")   # 出生点留空 = 不按门的位置摆
	_apply_saved_position()


func _on_go_requested(room_name: String, spawn_name: String) -> void:
	_switch_to(room_name, spawn_name)

	# 换房间 = 一个检查点 → 自动存一次档。
	#
	# ⚠️ 只有【Travel 触发的】才存 —— 也就是玩家自己走过去的那次。
	#    开局装房间不存：那是"进场"，不是"玩家做了什么"。
	#    （而且读档进来立刻又覆盖存档，纯属白写。）
	# 存到【自动存档位】（0 号），不是玩家的手动存档位。
	# 这样"我手动存的档"不会被走路覆盖掉。
	SaveManager.save_game(SaveManager.AUTO_SLOT)


## 换房间。卸载旧的、装上新的、挪玩家。
func _switch_to(room_name: String, spawn_name: String) -> void:
	var scene: PackedScene = _by_name.get(room_name)

	if scene == null:
		push_warning("【RoomManager】没有叫「%s」的房间。检查它有没有拖进 Room 节点的 rooms 数组。" % room_name)
		return

	Travel.consume()

	# ── 卸载旧房间 ──
	# ⚠️ 用 queue_free() 而不是 free()：
	#    换房间往往发生在物理回调（Area2D 信号）里面，
	#    这时候立刻销毁节点会崩。queue_free 推到这一帧末尾再删，安全。
	if is_instance_valid(_current):
		_current.queue_free()
		_current = null

	# ── 装上新的 ──
	_current = scene.instantiate()
	add_child(_current)

	# 记下"玩家现在在哪个房间"，存档要用。
	GameState.current_room = room_name

	var player := _find_player()
	if player != null:
		_move_player_to_spawn(player, _current, spawn_name)
	_update_camera_limits(_current)


## 读档时把玩家放回【存档里记的那个坐标】。
##
## 和 _move_player_to_spawn() 的区别：
##   那个用的是房间里的"出生点标记"（从哪扇门进来的）；
##   这个用的是存档里存的具体坐标（上次退出时站在哪）。
func _apply_saved_position() -> void:
	var player := _find_player()
	if player == null:
		return
	player.global_position = GameState.player_position


## 找玩家节点。
##
## 优先按分组找（推荐做法），找不到再按路径 ——
## 玩家目前叫 World/Player，而 Room 是它的兄弟节点。
func _find_player() -> Node2D:
	var player := get_tree().get_first_node_in_group(&"player") as Node2D
	if player == null:
		player = get_node_or_null("../Player") as Node2D
	if player == null:
		push_warning("【RoomManager】找不到玩家节点")
	return player


## 把玩家挪到出生点。
##
## 出生点规则：房间里的 SpawnPoints 底下，找【名字一模一样】的 Marker2D。
## 找不到就警告一句并留在原地 —— 免得你以为"出生点是随机的"。
func _move_player_to_spawn(player: Node2D, room: Node, spawn_name: String) -> void:
	if spawn_name.is_empty():
		return

	var markers := room.get_node_or_null("SpawnPoints")
	var marker: Node2D = null
	if markers != null:
		marker = markers.get_node_or_null(spawn_name) as Node2D

	if marker == null:
		push_warning("【RoomManager】房间「%s」里没有叫「%s」的出生点，玩家留在原地。" % [room.name, spawn_name])
		return

	player.global_position = marker.global_position


## 读房间地板层画过的范围，换算成像素，设为相机边界。
##
## ═══ 为什么放在这里，而不是 world.gd ═══
## 房间是【运行时】才装进来的，而且是会换的。
## world.gd 在自己的 _ready 里根本不知道地板在哪 —— 那时候房间还没装。
## 这里正好是"房间刚装好"的那一刻，是最合适的时机。
##
## ═══ 约定 ═══
## 房间场景里的地板层【必须叫 Ground】，而且必须是 TileMapLayer。
func _update_camera_limits(room: Node) -> void:
	var sprite_camera := _find_camera()
	if sprite_camera == null:
		push_warning("【RoomManager】找不到相机（玩家身上的 Camera2D），相机边界没设置")
		return

	var ground := room.get_node_or_null("Ground") as TileMapLayer
	if ground == null:
		push_warning("【RoomManager】房间「%s」里找不到 Ground 层。地板层必须叫 Ground。" % room.name)
		return

	var rect: Rect2i = ground.get_used_rect()
	if rect.size.x == 0 or rect.size.y == 0:
		push_warning("【RoomManager】房间「%s」的 Ground 层还是空的，相机边界没设置" % room.name)
		return

	sprite_camera.limit_left = rect.position.x * TILE_SIZE
	sprite_camera.limit_top = rect.position.y * TILE_SIZE
	sprite_camera.limit_right = rect.end.x * TILE_SIZE
	sprite_camera.limit_bottom = rect.end.y * TILE_SIZE

	print("【RoomManager】%s 的相机边界已设为：%s 到 %s" % [room.name, rect.position * TILE_SIZE, rect.end * TILE_SIZE])


func _find_camera() -> Camera2D:
	var player := _find_player()
	if player == null:
		return null
	return player.get_node_or_null("Camera2D") as Camera2D
