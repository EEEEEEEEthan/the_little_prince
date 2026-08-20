class_name B612Lines
extends RefCounted
## B612 剧情台词：对话框与头顶侧写。口吻贴近原著的认真与忧伤。

const OVERHEAD_PLANET_NAME := "B-612。"
const OVERHEAD_MY_PLANET := "我的星球。"
const OVERHEAD_PULL_HINT := "看见一棵，拔一棵。"
const OVERHEAD_ROSE_THANKLESS := "她没有说谢谢。"
const OVERHEAD_SUNSET := "人在忧伤的时候，就喜欢看日落。"
const OVERHEAD_SUNSET_LEAVE := "这颗星球太小了。我该走了。"

const _PRINCE_PORTRAIT := preload("res://ui/portraits/prince.png")
const _ROSE_PORTRAIT := preload("res://ui/portraits/rose.png")


static func opening() -> Array[DialogueLine]:
	return _pack([
		_prince("我有三座火山。只有一座还活着。"),
		_prince("两座已经熄了。不过谁知道呢。"),
		_prince("猴面包树的嫩芽，看见就要拔。等到太晚，就再也拔不掉了。"),
	])


static func pull_shoot(remaining_shoot_count: int) -> String:
	if remaining_shoot_count <= 0:
		return "好了。去通火山。"
	if remaining_shoot_count == 1:
		return "还剩一棵。"
	const pull_lines: PackedStringArray = [
		"刚长出来，跟玫瑰差不多。",
		"根已经往下钻了。",
		"这是纪律。每天都要拔。",
	]
	return pull_lines[(remaining_shoot_count - 2) % pull_lines.size()]


static func clean_volcano(is_active_volcano: bool, remaining_volcano_count: int) -> String:
	if remaining_volcano_count <= 0:
		return "通好了。去看看她。我就要离开了。"
	if is_active_volcano:
		return "这座还活着。喷口又堵了。"
	return "已经不喷了。也要掏干净。谁知道呢。"


static func shoot_walk_lines() -> PackedStringArray:
	return PackedStringArray([
		"嫩芽刚长出来，跟玫瑰差不多。",
		"必须每天拔。这是纪律。",
		"根会钻到地心去。",
		"一棵就能把星球撑裂。",
	])


static func volcano_walk_lines() -> PackedStringArray:
	return PackedStringArray([
		"两座已经熄了。一座还热着。",
		"熄灭的也要扫。谁知道会不会再醒。",
		"这颗星球太小了。",
		"我已经看过许多次日落。也许该走了。",
	])


static func rose_walk_lines() -> PackedStringArray:
	return PackedStringArray([
		"她叶子上有沙。",
		"夜里风会冻着她。",
	])


static func farewell_walk_lines() -> PackedStringArray:
	return PackedStringArray([
		"候鸟就要来了。",
		"该向她告别了。",
	])


static func tend_rose() -> Array[DialogueLine]:
	var lines := tend_rose_until_cover()
	lines.append_array(tend_rose_after_cover())
	return lines


static func tend_rose_until_cover() -> Array[DialogueLine]:
	return _pack([
		_rose("你来了。我等了你好久。"),
		_prince("我给你浇水。"),
		_rose("要晒过的。凉水我会咳。"),
		_rose("夜里有风。把玻璃罩罩上。"),
	])


static func tend_rose_after_cover() -> Array[DialogueLine]:
	return _pack([
		_prince("罩好了。"),
		_rose("我有四根刺。老虎来了，我会扎它。"),
		_prince("这里没有老虎。"),
		_rose("那就去忙你的。"),
	])


static func farewell() -> Array[DialogueLine]:
	var lines := farewell_until_uncover()
	lines.append_array(farewell_after_uncover())
	return lines


static func farewell_until_uncover() -> Array[DialogueLine]:
	return _pack([
		_prince("我要走了。"),
		_rose("玻璃罩拿走吧。今晚这点风，我受得住。"),
	])


static func farewell_after_uncover() -> Array[DialogueLine]:
	return _pack([
		_rose("你以前不懂。水浇得太凉，罩子扣得太早。"),
		_prince("我那时太年轻。"),
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
