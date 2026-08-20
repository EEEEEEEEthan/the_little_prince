class_name B612Lines
extends RefCounted
## B612 剧情台词：对话框与头顶侧写。

const OVERHEAD_PLANET_NAME := "B-612。"
const OVERHEAD_MY_PLANET := "我的星球。"
const OVERHEAD_PULL_HINT := "看见的都要拔掉。"
const OVERHEAD_ROSE_THANKLESS := "她不会说谢谢。"
const OVERHEAD_WALK_TO_SUNSET := "往前走。等到天红。"
const OVERHEAD_SUNSET := "天红了。"
const OVERHEAD_FAREWELL_HINT := "该去向她告别了。"

const _PRINCE_PORTRAIT := preload("res://ui/portraits/prince.png")
const _ROSE_PORTRAIT := preload("res://ui/portraits/rose.png")


static func opening() -> Array[DialogueLine]:
	return _pack([
		_prince("上面有三座火山。两座还活着。"),
		_prince("猴面包树的嫩芽，看见一棵拔一棵。"),
		_prince("留下就会把星球撑裂。"),
	])


static func pull_shoot(remaining_shoot_count: int) -> String:
	if remaining_shoot_count <= 0:
		return "好了。去通火山。"
	if remaining_shoot_count == 1:
		return "还剩一棵。"
	return "这棵还软。根已经下去了。"


static func clean_volcano(is_active_volcano: bool, remaining_volcano_count: int) -> String:
	if remaining_volcano_count <= 0:
		return "好了。她叶子上有沙。"
	if is_active_volcano:
		return "喷口堵住了。灰还是热的。"
	return "这座不喷了。里面仍要掏干净。"


static func shoot_walk_lines() -> PackedStringArray:
	return PackedStringArray([
		"昨天还只有两片叶子。",
		"根会钻到地心去。",
		"洗完脸就该拔。每天都是。",
		"一棵就能撑破这块地方。",
		"别看它现在像玫瑰。",
	])


static func volcano_walk_lines() -> PackedStringArray:
	return PackedStringArray([
		"灰会把喷口堵住。",
		"两座还活着。一座已经冷了。",
		"通火山像扫烟囱。每天一次。",
	])


static func rose_walk_lines() -> PackedStringArray:
	return PackedStringArray([
		"她比这些树难伺候。",
	])


static func tend_rose() -> Array[DialogueLine]:
	var lines := tend_rose_until_cover()
	lines.append_array(tend_rose_after_cover())
	return lines


static func tend_rose_until_cover() -> Array[DialogueLine]:
	return _pack([
		_rose("你来了。风吹了一整夜。"),
		_rose("左边这片花瓣，边都卷起来了。"),
		_prince("我给你浇水。"),
		_rose("水要晒过。昨晚那壶太凉，我咳到天亮。"),
		_rose("把玻璃罩罩上。沙子会钻进来。"),
	])


static func tend_rose_after_cover() -> Array[DialogueLine]:
	return _pack([
		_prince("好了。"),
		_rose("罩子边上有一道灰。你看见没有。"),
		_prince("看见了。"),
		_rose("我有四根刺。老虎来了，我会扎它。"),
		_prince("这里没有老虎。"),
		_rose("那更好。你去忙你的。"),
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
		_rose("四根刺够用了。"),
		_rose("你以前浇凉水，还把罩子扣得太早。"),
		_prince("我以前不懂。"),
		_rose("去吧。别再站在这儿。"),
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
