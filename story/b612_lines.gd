class_name B612Lines
extends RefCounted
## B612 剧情台词：对话框与头顶侧写。

const OPENING_OVERHEAD_LINES: PackedStringArray = [
	"B-612。走几步，天就会再红一次。",
	"有些嫩芽，跟花长得像。看见了，就要拔掉。",
]
const PULL_SHOOT_OVERHEAD_LINES: PackedStringArray = [
	"刚冒尖的时候，几乎像一朵玫瑰。",
	"根已经摸到土的深处。",
	"再晚一点，整颗星球都会裂开。",
	"土里还睡着许多。有的不该发芽。",
	"芽尽了。喷口里，还闷着灰。",
]
const OVERHEAD_PLANET_NAME := "B-612。"
const OVERHEAD_SUNSET := "人在忧伤的时候，就喜欢看日落。"

const _PRINCE_PORTRAIT := preload("res://ui/portraits/prince.png")
const _ROSE_PORTRAIT := preload("res://ui/portraits/rose.png")


static func opening_rose() -> Array[DialogueLine]:
	return _pack([
		_rose("我刚醒来。请原谅，花瓣还有点乱。"),
		_prince("你很好看。"),
		_rose("给我弄点水来。要晒过的。"),
	])


static func pull_shoot(remaining_after_this: int) -> String:
	return PULL_SHOOT_OVERHEAD_LINES[
			PULL_SHOOT_OVERHEAD_LINES.size() - 1 - remaining_after_this
	]


static func clean_volcano(is_active_volcano: bool, remaining_after_this: int) -> String:
	if remaining_after_this <= 0:
		return "烟囱通了。风会把沙吹到她叶子上。"
	if is_active_volcano:
		return "这座还热着。灰会把热气堵死。"
	if remaining_after_this == 1:
		return "冷的喷口，也会自己堵住。"
	return "已经不喷了。也要掏干净。谁知道呢。"


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
