extends CharacterBody2D
## 玩家角色。
##
## 负责三件事：四方向移动、四方向动画切换、记录最后朝向（供其它系统读取）。
##
## ⚠️ 改这个脚本之前，先读这两条：
##   1. motion_mode 必须是 FLOATING（俯视角用）。默认的 GROUNDED 是给横版平台游戏
##      设计的，会让角色"粘"在物体上、移动被莫名抵抗。
##   2. 斜向移动时播"横向"动画，不是纵向。原因见 _update_animation 里的说明。
##
## 动画命名约定（必须存在，缺一个就会报错）：
##   idle_down / idle_up / idle_left / idle_right
##   run_down  / run_up  / run_left  / run_right


# ═══════════════════════════════════════════════════
#  可调参数
# ═══════════════════════════════════════════════════

## 移动速度，单位是像素/秒（不是像素/帧）。

@export var speed: float = 300.0


# ═══════════════════════════════════════════════════
#  节点引用
# ═══════════════════════════════════════════════════

## 角色精灵。@onready 表示"等节点都准备好了再赋值"， 这个应该是方便快速调用子成员的
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


# ═══════════════════════════════════════════════════
#  内部状态
# ═══════════════════════════════════════════════════

## 当前朝向，取值只能是："down" / "up" / "left" / "right"
## 为什么需要这个变量：松开方向键时，角色要停在最后朝向播待机动画。
var facing: String = "down"

# ═══════════════════════════════════════════════════
#  外部关系
# ═══════════════════════════════════════════════════
var nearby:Array[Node] =[]

# ═══════════════════════════════════════════════════
#  生命周期
# ═══════════════════════════════════════════════════

func _ready() -> void:
	# 俯视角必须用 FLOATING。
	#
	# 场景文件（player.tscn）里其实已经设过了，这里再写一遍是**故意的防呆**：
	# 以后如果有人把这个脚本挂到新场景、忘了在检查器里改 motion_mode，
	# 代码这一行会兜住，不会出现"怎么走起来怪怪的"这种难查的问题。
	motion_mode = MOTION_MODE_FLOATING


func _physics_process(_delta: float) -> void:
	# 参数名用 _delta（下划线开头）表示"这个参数我不用"。
	# 这是 GDScript 的惯例，可以避免编辑器报"未使用的参数"警告。
	# 移动速度已经在 speed 里了，不需要再乘以 delta。 这个函数应该是固定每秒执行60次

	# ── 第 1 步：读输入 ──
	#
	# ⚠️ Input.get_vector() 已经帮你把斜向输入**归一化**了：
	#    同时按「右」和「下」，得到的是 (0.707, 0.707)，不是 (1, 1)。
	#    所以斜着走不会比直着走快——你不用再自己 normalized()（归一化） 一次。
	
	
	var direction: Vector2 = Input.get_vector(
		"move_left", "move_right", "move_up", "move_down"
	)
	# ── 第 2 步：算速度并移动 ──
	velocity = direction * speed
	move_and_slide()

	# ── 第 3 步：决定播哪个动画 ──
	# 放在移动之后，用的是这一帧真正的输入方向。
	_update_animation(direction)


# ═══════════════════════════════════════════════════
#  动画
# ═══════════════════════════════════════════════════

## 根据移动方向切换动画。静止时播待机，移动时播奔跑。
func _update_animation(direction: Vector2) -> void:
	var target: String

	if direction.length() < 0.1:
		# ── 情况 A：没在移动 → 播待机，保持最后朝向 ──
		#
		# 判断"长度 < 0.1"而不是"== Vector2.ZERO"：
		# 手柄摇杆在静止时会有微小的漂移值，用 0.1 当门槛可以忽略它。
		target = "idle_" + facing
	else:
		# ── 情况 B：在移动 → 决定用哪个方向的动画 ──
		#
		# ⚠️ 这里是整个脚本最重要的一个决策：**横向优先**。 素材没有斜向的，只能暂时这样
		
		if absf(direction.x) > 0.1:
			facing = "right" if direction.x > 0.0 else "left" 
		else:
			facing = "down" if direction.y > 0.0 else "up"

		target = "run_" + facing #直接字符串拼接成动画的名称，哦这个做的挺好

	# ⚠️ 必须判断"变了才切"，不能每帧无脑调 sprite.play()。
	#
	# 原因：每帧调 play() 有可能让动画每帧都从头播，
	# 结果就是角色永远停在第 1 帧，看起来像完全没有动画。
	# 先比较再切，既避免这个问题，逻辑也更清楚。
	if sprite.animation != target:
		sprite.play(target)
		
		


func _on_area_entered(inarea: Area2D) -> void:
	nearby.append(inarea.get_parent())


func _on_area_exited(outarea: Area2D) -> void:
	nearby.erase(outarea.get_parent())
	
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		var target := _find_nearest_interactable()
		if target != null:
			target.interact()


## 从附近的目标里挑【真正离得最近】的那个。
##
## ⚠️ 不能直接取 nearby[0]：nearby 是按「进入互动区的先后」排的，不是按距离。
##    站在桌子和椅子中间时，可能桌子先进来、椅子后进来，
##    而桌子没配剧本 → 按 E 什么都不会发生，
##    旁边那把明明有剧本的椅子反而没反应（这个 bug 是实测出来的）。
##
## 距离用「两个原点之间」的距离。家具的原点在脚下中点，
## 所以这个距离约等于「脚到脚的远近」，够用了。
func _find_nearest_interactable() -> Node:
	var best: Node = null
	var best_dist: float = INF
	# 倒着遍历，顺便把已经被释放的节点从 nearby 里清掉
	for i in range(nearby.size() - 1, -1, -1):
		var n: Node = nearby[i]
		if not is_instance_valid(n):
			nearby.remove_at(i)
			continue
		if not n.has_method("interact"):
			continue
		var d: float = global_position.distance_squared_to(n.global_position)
		if d < best_dist:
			best_dist = d
			best = n
	return best
		
		
