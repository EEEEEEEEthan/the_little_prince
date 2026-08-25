class_name DialogueCatalog
extends RefCounted
## 对话目录。按地物 id 取小王子旁白。

const PRINCE_SPEAKER := "小王子"
const ROSE_SPEAKER := "玫瑰"
const KING_SPEAKER := "国王"
const DRUNKARD_SPEAKER := "酒鬼"
const GEOGRAPHER_SPEAKER := "地理学家"
const CHARACTER_BUST_FRAMES := preload("res://ui/prince_rose_king_slumped_wine_drinker_hunched_ledger_merchant_black_coat_lamplighter_gray_beard_parchment_scholar_frames.png")

enum CharacterBust {
	PRINCE,
	ROSE,
	KING,
	SLUMPED_WINE_DRINKER,
	HUNCHED_LEDGER_MERCHANT,
	BLACK_COAT_LAMPLIGHTER,
	GRAY_BEARD_PARCHMENT_SCHOLAR,
}

static var PRINCE_PORTRAIT: Texture2D:
	get:
		return _character_bust(CharacterBust.PRINCE)
static var ROSE_PORTRAIT: Texture2D:
	get:
		return _character_bust(CharacterBust.ROSE)
static var KING_PORTRAIT: Texture2D:
	get:
		return _character_bust(CharacterBust.KING)
static var DRUNKARD_PORTRAIT: Texture2D:
	get:
		return _character_bust(CharacterBust.SLUMPED_WINE_DRINKER)
static var GEOGRAPHER_PORTRAIT: Texture2D:
	get:
		return _character_bust(CharacterBust.GRAY_BEARD_PARCHMENT_SCHOLAR)

static var _character_busts: Array[Texture2D] = []


static func _character_bust(character_bust: CharacterBust) -> Texture2D:
	var character_bust_count := CharacterBust.GRAY_BEARD_PARCHMENT_SCHOLAR + 1
	if _character_busts.size() != character_bust_count:
		_character_busts.clear()
		for frame_index in character_bust_count:
			const character_bust_frame_size := 32
			var atlas := AtlasTexture.new()
			atlas.atlas = CHARACTER_BUST_FRAMES
			atlas.region = Rect2(
					frame_index * character_bust_frame_size,
					0,
					character_bust_frame_size,
					character_bust_frame_size
			)
			_character_busts.append(atlas)
	return _character_busts[character_bust]


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
