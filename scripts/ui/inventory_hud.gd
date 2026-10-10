extends Label
## 背包显示：右上角列出 GameState.counters 里的东西。
##
## ═══ 数据从哪来 ═══
## 全部来自 GameState.counters —— 这个脚本自己【一个变量都不存】。
## 所以"到底有几个"永远以 GameState 为准，
## 不会出现"HUD 显示有钥匙但其实已经用掉了"这种对不上的情况。
##
## ═══ 成员怎么用（什么都不用做）═══
## 在剧本里写：$> GameState.bump("钥匙")
## 右上角就自动多出一行「钥匙 ×1」。
## 用掉时 $> GameState.spend("钥匙")，数量归零会自动消失。
##
## ⚠️ 物品和计数是【同一个字典】——
## "钥匙"是物品，"见过的人数"是计数，在 HUD 上长得一样。
## 这是故意的：少一个概念，成员好记。


func _ready() -> void:
	# 听到"有东西变了"就刷新。
	# 这个信号由 GameState 的 set_flag / bump / spend 发出。
	GameState.value_changed.connect(_on_value_changed)
	refresh()


func _on_value_changed(_key: String, _value) -> void:
	refresh()


## 重新画一遍。数量和内容全从 GameState 读，不缓存。
func refresh() -> void:
	var lines: PackedStringArray = []

	for key in GameState.counters:
		var n: int = GameState.counters[key]
		if n <= 0:
			continue          # 数量归零的不显示（用掉了就等于没有）
		lines.append("%s ×%d" % [key, n])

	# 空背包也要把标题显示出来 ——
	# 玩家得知道"这个位置有个背包"，不然会以为游戏没有背包系统。
	if lines.is_empty():
		lines.append("（空）")

	text = "【背包】\n" + "\n".join(lines)
