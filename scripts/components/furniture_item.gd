@tool
## 一件家具（桌子 / 柜子 / 盆栽 / 海报……）。
##
## 【设计要点】贴图和碰撞盒的原点都放在【底边中心】——
## 也就是物体接触地面的那条线的中点。
##
## 为什么要这样：
##   俯视角游戏用 y 排序（y_sort_enabled）决定谁挡谁，
##   Godot 比较的是节点的【世界坐标 Y】。
##   原点放在脚下 = 世界坐标 Y 就是「脚站在哪」，
##   角色走到家具前面（Y 更大）就挡住家具，走到后面（Y 更小）就被挡住。
##
##   如果把原点放在贴图正中心，那「中心点」在半空中，
##   角色贴着家具下沿走就会被错误遮挡 —— 这是俯视角最常见的视觉 bug。
##
## 用法：把这个场景拖进关卡 → 在检查器里选【贴图】→ 完事。
## 碰撞盒会自动跟着贴图大小。
extends StaticBody2D

## 家具的外观贴图。选完之后尺寸和碰撞盒会自动刷新。
@export var texture: Texture2D:
	set(value):
		texture = value
		if is_node_ready():
			_refresh()

## 关掉 = 纯装饰，不挡路（地毯、墙上的画、海报用这个）。
@export var blocks_movement: bool = true:
	set(value):
		blocks_movement = value
		if is_node_ready():
			_refresh()

## 碰撞盒高度（像素）。0 = 自动，取「贴图高度」和 10 里较小的那个。
##
## 【为什么碰撞盒不能等于贴图高度】
## 家具的贴图通常比它真正「占地」的范围大：桌子上方有显示器、柜子上方有柜身，
## 那些部分角色应该能从前面【挡住】它，但不该把路堵死。
## 碰撞盒只盖【底边那一小块】（真正接触地面的部分），角色才能贴着家具走。
## 如果碰撞盒 = 整张贴图，桌椅之间那条几像素的缝人就钻不过去，会当场卡死。
@export var footprint_height: float = 0.0:
	set(value):
		footprint_height = value
		if is_node_ready():
			_refresh()

## 这件家具的剧本。留空 = 不能互动（按 E 没反应）。
##
## ⚠️ 所有家具共用同一个 furniture_item.tscn，剧本是【每个实例各填各的】。
## 所以"10 把椅子共用一份剧本"的做法 = 把同一个 .dialogue 文件
## 分别拖到那 10 个椅子实例的这个格子里（资源只有一份，指向它而已）。
@export var dialogue: DialogueResource

## 从剧本的哪一段开始说。一般不用改 —— .dialogue 文件里的入口段落通常就叫 start。
@export var start_cue: String = "start"

## 互动区比家具本身四周各外扩多少像素。
## 不外扩的话玩家得贴到家具上才触发，手感很别扭。
@export var interact_padding: float = 8.0:
	set(value):
		interact_padding = value
		if is_node_ready():
			_refresh()

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _shape: CollisionShape2D = $CollisionShape2D
@onready var _area_shape: CollisionShape2D = $InteractArea/CollisionShape2D


func _ready() -> void:
	_refresh()


func _refresh() -> void:
	if texture == null:
		return
	var size: Vector2 = texture.get_size()

	# ① 贴图：往【上】挪半个高度，这样原点正好落在底边中点
	_sprite.texture = texture
	_sprite.offset = Vector2(0, -size.y / 2.0)

	# ② 碰撞盒：宽度跟贴图一样，但【只盖底边那一小条】——
	#    那才是家具真正「占地」的范围
	var fh: float = footprint_height if footprint_height > 0.0 else minf(size.y, 10.0)
	var rect := RectangleShape2D.new()
	rect.size = Vector2(size.x, fh)
	_shape.shape = rect
	_shape.position = Vector2(0, -fh / 2.0)
	_shape.disabled = not blocks_movement

	# ③ 互动区：比家具本身四周各外扩 interact_padding，
	#    这样玩家不用贴到家具上就能按 E。
	#    ⚠️ 尺寸算完之后由这个函数统一设，
	#    所以换贴图时互动区会自动跟着变，不用手调。
	var area_rect := RectangleShape2D.new()
	area_rect.size = size + Vector2(interact_padding * 2.0, interact_padding * 2.0)
	_area_shape.shape = area_rect
	_area_shape.position = Vector2(0, -size.y / 2.0)


# ═══════════════════════════════════════════════════
#  被交互
# ═══════════════════════════════════════════════════

## 玩家在附近按 E 时会调用这个方法。
##
## ⚠️ 方法名必须叫 interact —— player.gd 是按这个名字找的，
##    而且它调的是【InteractArea 的父节点】，也就是这件家具自己。
func interact() -> void:
	if dialogue == null:
		return     # 没配剧本 = 纯装饰。不警告，因为大多数家具本来就不该有剧本
	DialogueManager.show_dialogue_balloon(dialogue, start_cue)
