---
name: godot-builtin
description: 本仓库资源放置：只用过一次的脚本/贴图/shader 必须写进所属 tscn 的 builtin。编写或审查 .tscn/.gd/.gdshader/贴图引用时使用。覆盖全局 godot-best-practice 的「根脚本必须同名外置 .gd」。
---

# 单次引用必须 builtin

只被**一个** `.tscn` 引用的资源不要留独立文件，写进该场景。PackedScene 被多处 `instance` 仍算「一个 tscn 持有该脚本」（如 `player_trigger.tscn`）。

| 类型 | 写法 |
|------|------|
| 脚本 | `[sub_resource type="GDScript"]` + `script/source` |
| Shader | `[sub_resource type="Shader"]` + `code` |
| 仅一处用的 PNG | `[sub_resource type="Texture2D"]` + `EditableTexture` 的 `_base64_data` |

根脚本同样适用：非继承场景、脚本只服务该 tscn 时，根也用 builtin，不必再配同名 `.gd`。继承场景（如 `main.tscn` 实例化 `planet_run_shell.tscn`）的扩展根脚本也用 builtin。

## 与全局技能

本仓库以此文件为准，覆盖全局 `godot-best-practice` 里「根必须同目录同名外置 `.gd`」。子节点 builtin、场景信号边界等其它条目仍有效。

## `class_name`

Godot **禁止** builtin 脚本写 `class_name`。跨文件类型用已有工具类上的枚举（如 `WorldConstants.TriggerKind`），或 `has_method` / 无类型节点引用。必须全局 `class_name` 的脚本才外置。

## 继续留独立文件的

- 被多个场景各自挂载，或 `preload` / `load` / `extends "res://...gd"` 的脚本（如 `planet_run_shell.gd`、`surface_prop.gd`）
- 多星球共用的 shader / 贴图 / 音频
- 无场景挂载的工具类（`WorldConstants`、`SkyPhase`、`DialogueCatalog`）
- `addons/` 插件

## 手改 tscn

`script/source` / `code` 里的 `"` 写成 `\"`。优先在编辑器里改嵌入脚本。
