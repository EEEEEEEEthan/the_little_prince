class_name B612Lines
extends RefCounted
## B612 剧情台词：对话框与头顶侧写。

const OVERHEAD_PLANET_NAME := "B-612。"
const OVERHEAD_MY_PLANET := "我的星球。"
const OVERHEAD_PULL_HINT := "嫩芽必须立刻拔掉。"
const OVERHEAD_ROSE_THANKLESS := "她从来不肯说谢谢。"
const OVERHEAD_WALK_TO_SUNSET := "往前走。日落会来。"
const OVERHEAD_SUNSET := "日落。"
const OVERHEAD_FAREWELL_HINT := "该去向她告别了。"

const _PRINCE_PORTRAIT := preload("res://ui/portraits/prince.png")
const _ROSE_PORTRAIT := preload("res://ui/portraits/rose.png")


static func opening() -> Array[DialogueLine]:
	return _pack([
		_prince("上面有三座火山。两座还活着。"),
		_prince("猴面包树的嫩芽，必须立刻拔掉。"),
		_prince("不然整颗星球都会裂开。"),
	])


static func pull_shoot(remaining_shoot_count: int) -> Array[DialogueLine]:
	if remaining_shoot_count <= 1:
		return _pack([
			_prince("还剩一棵。"),
		])
	return _pack([
		_prince("这棵还小。"),
		_prince("现在拔，还来得及。"),
	])


static func shoots_finished() -> Array[DialogueLine]:
	return _pack([
		_prince("好了。"),
		_prince("火山也要疏通。每天都要。"),
	])


static func clean_volcano(is_active_volcano: bool) -> Array[DialogueLine]:
	if is_active_volcano:
		return _pack([
			_prince("把喷口疏通。"),
			_prince("不然会把星球烧掉。"),
		])
	return _pack([
		_prince("这座已经熄了。"),
		_prince("不过还是要打扫。"),
	])


static func volcanoes_finished() -> Array[DialogueLine]:
	return _pack([
		_prince("她该喝水了。"),
	])


static func tend_rose() -> Array[DialogueLine]:
	return _pack([
		_rose("我刚刚被风吹到了。"),
		_rose("夜里会冷。你该把我罩起来。"),
		_prince("我给你浇水。"),
		_rose("咳咳。"),
		_rose("我不是故意咳嗽的。"),
		_rose("你知道老虎的。"),
		_prince("这里没有老虎。"),
		_rose("那更好。我的刺就没用了。"),
	])


static func farewell() -> Array[DialogueLine]:
	return _pack([
		_prince("我要走了。"),
		_rose("我当然是爱你的。"),
		_rose("你一直那么傻。请原谅我。"),
		_rose("玻璃罩就别要了。我不需要。"),
		_rose("去吧。"),
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
