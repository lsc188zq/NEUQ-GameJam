extends Node2D
## 游戏场景（地图）的脚本。
##
## 目前只做一件事：**根据地板的实际范围，自动设置相机边界**。
##
## 为什么要自动算，而不是在检查器里填死数字：
##   你以后扩建或重铺地图（比如从 28×16 改成 40×24），
##   只要地板铺到哪，相机边界就跟到哪，**不用改任何代码**。
##   这符合模板的原则——改内容不碰代码。


## 一个瓦片的像素尺寸。和 TileSet 里设的要一致。
const TILE_SIZE: int = 16

## 地板层。相机边界按它画过的范围来算。
## ⚠️ 路径跟着场景结构走：Ground 在 Classroom 底下（见 world.tscn 的节点树）。
@onready var ground: TileMapLayer = $Classroom/Ground

## 玩家身上那台相机。
@onready var camera: Camera2D = $Player/Camera2D


# ═══════════════════════════════════════════════════
#  任务
# ═══════════════════════════════════════════════════

## 开局自动接取的任务，现在归【QuestBook】管了 —— 见 scenes/quest_book.tscn。
##
## 为什么要搬走：从剧本里接任务需要"按名字查任务"这张查找表，
## 而查找表必须跨场景一直存在，所以放进自动加载更合适。
##
##   想加开局任务   → 打开 scenes/quest_book.tscn，拖进 opening_quests 数组
##   想由对话触发   → 剧本里写 $> QuestBook.start("任务名")


func _ready() -> void:
	_update_camera_limits()


## 读地板层画过的范围，换算成像素，设为相机边界。
func _update_camera_limits() -> void:
	if ground == null or camera == null:
		push_warning("【world.gd】找不到 Ground 层或 Camera2D，相机边界没设置")
		return

	# get_used_rect() 返回"画过的格子的最小外接矩形"（格坐标）
	var rect: Rect2i = ground.get_used_rect()

	if rect.size.x == 0 or rect.size.y == 0:
		push_warning("【world.gd】Ground 层还是空的，相机边界没设置")
		return

	# 格坐标 → 像素坐标
	camera.limit_left = rect.position.x * TILE_SIZE
	camera.limit_top = rect.position.y * TILE_SIZE
	camera.limit_right = rect.end.x * TILE_SIZE
	camera.limit_bottom = rect.end.y * TILE_SIZE

	print("【world.gd】相机边界已设为：", rect.position * TILE_SIZE, " 到 ", rect.end * TILE_SIZE)
