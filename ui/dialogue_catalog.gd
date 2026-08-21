class_name DialogueCatalog
extends RefCounted
## 对话目录。按地物 id 取小王子旁白。

const PRINCE_SPEAKER := "小王子"
const ROSE_SPEAKER := "玫瑰"
const KING_SPEAKER := "国王"
const DRUNKARD_SPEAKER := "酒鬼"
const GEOGRAPHER_SPEAKER := "地理学家"
const PRINCE_PORTRAIT := preload("res://ui/portraits/prince.png")
const ROSE_PORTRAIT := preload("res://ui/portraits/rose.png")
const KING_PORTRAIT := preload("res://ui/portraits/king.png")
const DRUNKARD_PORTRAIT := preload("res://ui/portraits/slumped_wine_drinker.png")
const GEOGRAPHER_PORTRAIT := preload("res://ui/portraits/gray_beard_parchment_scholar.png")


static func lines_for_id(id: StringName) -> Array[DialogueLine]:
	var lines: Array[DialogueLine] = []
	match id:
		&"baobab", &"baobab_shoot":
			lines.append(DialogueLine.new(
					PRINCE_SPEAKER, "刚长出来的时候，跟玫瑰差不多。", PRINCE_PORTRAIT
			))
			lines.append(DialogueLine.new(
					PRINCE_SPEAKER, "等到太晚，就再也拔不掉了。", PRINCE_PORTRAIT
			))
		&"rose":
			lines.append(DialogueLine.new(
					PRINCE_SPEAKER, "她是我的玫瑰。", PRINCE_PORTRAIT
			))
			lines.append(DialogueLine.new(
					PRINCE_SPEAKER, "全宇宙只有这一朵。", PRINCE_PORTRAIT
			))
		&"king":
			lines.append(DialogueLine.new(
					PRINCE_SPEAKER, "他是一位绝对的君主。", PRINCE_PORTRAIT
			))
			lines.append(DialogueLine.new(
					PRINCE_SPEAKER, "他的命令都是通情达理的。", PRINCE_PORTRAIT
			))
		&"drunkard":
			lines.append(DialogueLine.new(
					DRUNKARD_SPEAKER, "喝是为了忘羞耻", DRUNKARD_PORTRAIT
			))
		&"star_jar":
			lines.append(DialogueLine.new(
					PRINCE_SPEAKER, "他把星星锁进玻璃罐。", PRINCE_PORTRAIT
			))
		&"street_lamp":
			lines.append(DialogueLine.new(
					PRINCE_SPEAKER, "帮他点一次。", PRINCE_PORTRAIT
			))
		&"geographer":
			lines.append(DialogueLine.new(
					GEOGRAPHER_SPEAKER, "我只记下别人的报告。", GEOGRAPHER_PORTRAIT
			))
	return lines
