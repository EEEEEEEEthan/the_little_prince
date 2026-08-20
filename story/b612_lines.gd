class_name B612Lines
extends RefCounted
## B612 剧情台词：对话框与头顶侧写。

const OPENING_OVERHEAD_VANITY := "小王子看出了这花儿不太谦逊，可是她确实丽姿动人"
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


static func opening_screen() -> Array[DialogueLine]:
	return _pack([
		_rose("我有点冷，难道你没有屏风吗"),
	])


static func pull_shoot(remaining_after_this: int) -> String:
	return PULL_SHOOT_OVERHEAD_LINES[
			PULL_SHOOT_OVERHEAD_LINES.size() - 1 - remaining_after_this
	]


static func farewell_cues() -> Array[StoryCue]:
	return [
		_overhead("小王子最后一次浇花，他发觉自己要哭出来"),
		_dialogue([_prince("再见了")]),
		_overhead("花儿没有答应他"),
		_dialogue([_prince("再见了")]),
		_overhead("花儿咳嗽了一阵，但并不是由于感冒"),
		_dialogue([_rose("我真蠢，请你原谅我。希望你能幸福。")]),
		_overhead("小王子不知所措，不明白她为什么突然这样温柔恬静"),
		_dialogue([
			_rose("的确，我爱你"),
			_rose("但由于我的过错，你一点也没有理会"),
			_rose("这丝毫不重要"),
			_rose("不过，你也和我一样的蠢"),
			_rose("希望你今后能幸福"),
			_rose("把罩子放一边吧，我用不着他了"),
			_prince("要是风来了怎么办？"),
			_rose("我的感冒并不那么重"),
			_prince("要是有虫子野兽呢？"),
			_rose("我有爪子"),
		]),
		_overhead("玫瑰天真地露出她那四根刺"),
		_dialogue([
			_rose("别这么磨蹭了。真烦人！"),
			_rose("既然决定离开这儿，那么，快走吧！"),
		]),
		_overhead("玫瑰怕小王子看见她在哭。她总是这么傲娇"),
	]


static func farewell() -> Array[DialogueLine]:
	var lines: Array[DialogueLine] = []
	for cue in farewell_cues():
		lines.append_array(cue.dialogue_lines)
	return lines


static func _prince(text: String) -> DialogueLine:
	return DialogueLine.new("小王子", text, _PRINCE_PORTRAIT)


static func _rose(text: String) -> DialogueLine:
	return DialogueLine.new("玫瑰", text, _ROSE_PORTRAIT)


static func _pack(parts: Array) -> Array[DialogueLine]:
	var lines: Array[DialogueLine] = []
	for part in parts:
		lines.append(part)
	return lines


static func _overhead(text: String) -> StoryCue:
	var cue := StoryCue.new()
	cue.overhead_text = text
	return cue


static func _dialogue(parts: Array) -> StoryCue:
	var cue := StoryCue.new()
	cue.dialogue_lines = _pack(parts)
	return cue


class StoryCue extends RefCounted:
	var overhead_text := ""
	var dialogue_lines: Array[DialogueLine] = []
