class_name B612Lines
extends RefCounted
## B612 剧情台词：对话框与头顶侧写。

const OPENING_OVERHEAD_LINES: PackedStringArray = [
	"小王子很喜欢玫瑰花",
	"可是玫瑰的傲娇，尖刺，总是让他恼火"
]
const PULL_SHOOT_OVERHEAD_LINES: PackedStringArray = [
	"小王子的星球总会长出猴面包树",
	"小王子每天都要拔掉猴面包树苗",
	"如果不拔的话，星球就会被猴面包树弄得支离破碎",
	"可是现在他决定要离开了",
	"这是最后一株",
]
const OVERHEAD_PLANET_NAME := "B-612。"
const SUNSET_OVERHEAD_LINES: PackedStringArray = [
	"人在忧伤的时候，就喜欢看日落。",
	"有一天小王子看了二十多次日落",
]

const _PRINCE_PORTRAIT := preload("res://ui/portraits/prince.png")
const _ROSE_PORTRAIT := preload("res://ui/portraits/rose.png")


static func opening_rose() -> Array[DialogueLine]:
	return _pack([
		_rose("我刚刚睡醒，真对不起，瞧我的头发还是乱蓬蓬的。。。"),
		_prince("你很好看。"),
		_rose("是吧，我是与太阳同时出生的。。。"),
	])


static func pull_shoot(remaining_after_this: int) -> String:
	return PULL_SHOOT_OVERHEAD_LINES[
			PULL_SHOOT_OVERHEAD_LINES.size() - 1 - remaining_after_this
	]


static func tend_rose() -> Array[DialogueLine]:
	var lines := tend_rose_until_cover()
	lines.append_array(tend_rose_after_cover())
	return lines


static func tend_rose_until_cover() -> Array[DialogueLine]:
	return _pack([
		_rose("夜里有风。把玻璃罩罩上。"),
	])


static func tend_rose_after_cover() -> Array[DialogueLine]:
	return _pack([
		_rose("我有四根刺。老虎来了，我会扎它。"),
		_prince("这里没有老虎。"),
	])


static func farewell() -> Array[DialogueLine]:
	var lines := farewell_until_uncover()
	lines.append_array(farewell_after_uncover())
	return lines


static func farewell_until_uncover() -> Array[DialogueLine]:
	return _pack([
		_prince("再见。"),
		_rose("玻璃罩拿走吧。我不需要了。"),
	])


static func farewell_after_uncover() -> Array[DialogueLine]:
	return _pack([
		_rose("我当然爱你。你一直不知道，是我的错。"),
		_rose("去吧。你已经决定了。"),
	])


static func _prince(text: String) -> DialogueLine:
	return DialogueLine.new("小王子", text, _PRINCE_PORTRAIT)


static func _rose(text: String) -> DialogueLine:
	return DialogueLine.new("玫瑰", text, _ROSE_PORTRAIT)


static func _pack(parts: Array) -> Array[DialogueLine]:
	var lines: Array[DialogueLine] = []
	for part in parts:
		lines.append(part)
	return lines
