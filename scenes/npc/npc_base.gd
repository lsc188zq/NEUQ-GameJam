extends CharacterBody2D
## NPC 基类。
##
## 目前有：站定时随机换朝向、被玩家按 E 时显示对话。
## 巡逻、对话状态以后用 Godot State Charts 加。
##
## 动画命名必须和玩家**完全一致**（idle_down / run_up 这样），
## 这样以后可以直接复用同一套切换逻辑，少一套规则少一个出错点：
##   idle_down / idle_up / idle_left / idle_right
##   run_down  / run_up  / run_left  / run_right


# ═══════════════════════════════════════════════════
#  可调参数
# ═══════════════════════════════════════════════════

## 换方向的最短间隔（秒）
@export var min_idle_time: float = 1.5

## 换方向的最长间隔（秒）
## 用随机间隔而不是固定间隔：固定的话看起来像机器人，
## 随机 1.5~4 秒才像"东张西望"。
@export var max_idle_time: float = 4.0

## 这个 NPC 要说的话。
##
## ⚠️ 在检查器里把 content/dialogues/ 里的 .dialogue 文件拖进来。
## 不填的话按 E 只会在输出面板警告一句，不会弹对话框。
@export var dialogue: DialogueResource

## 从剧本的哪一段开始说。
## 一般不用改 —— .dialogue 文件里的入口段落通常就叫 start。
@export var start_cue: String = "start"


# ═══════════════════════════════════════════════════
#  节点引用
# ═══════════════════════════════════════════════════

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


# ═══════════════════════════════════════════════════
#  内部状态
# ═══════════════════════════════════════════════════

## 四个朝向。和动画名一一对应，拼起来就是 "idle_down" 这种。
const DIRECTIONS: Array[String] = ["down", "up", "left", "right"]

var _timer: float = 0.0        ## 已经过了多久
var _next_change: float = 0.0  ## 这次要等多久才换


# ═══════════════════════════════════════════════════
#  生命周期
# ═══════════════════════════════════════════════════

func _ready() -> void:
	motion_mode = MOTION_MODE_FLOATING
	_change_facing()
	_reset_timer()


func _process(delta: float) -> void:
	# 这里用 _process 而不是 _physics_process：
	# 换朝向不是物理行为，不需要跑在物理帧上，用普通的渲染帧就行。
	_timer += delta
	if _timer >= _next_change:
		_change_facing()
		_reset_timer()


# ═══════════════════════════════════════════════════
#  行为
# ═══════════════════════════════════════════════════

## 随机挑一个朝向，播放对应的待机动画。
##
## 注意：pick_random() 有可能连续两次选到同一个方向。
## 这没关系——就是"看了一眼又看回来"，现实里本来就会发生，不用特意避免。
func _change_facing() -> void:
	var dir: String = DIRECTIONS.pick_random()
	sprite.play("idle_" + dir)


## 重新随机一个等待时长
func _reset_timer() -> void:
	_timer = 0.0
	_next_change = randf_range(min_idle_time, max_idle_time)


# ═══════════════════════════════════════════════════
#  被交互
# ═══════════════════════════════════════════════════

## 玩家按 E 时会调用这个方法。
##
## ⚠️ 方法名必须叫 interact —— 玩家的代码是按这个名字找的。
##
## 这个方法只负责"把对话弹出来"，剩下的全归 Dialogue Manager 管：
## 逐字显示、按键翻页、显示选项、跳转、结束时自动关闭。
func interact() -> void:
	if dialogue == null:
		push_warning("%s 没有指定对话文件，在检查器里拖一个进去" % name)
		return

	DialogueManager.show_dialogue_balloon(dialogue, start_cue)
	#                  ↑ 全局单例（插件自动注册的）  ↑ 剧本  ↑ 从哪段开始
