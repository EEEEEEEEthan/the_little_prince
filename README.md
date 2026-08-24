# The Little Prince

https://github.com/user-attachments/assets/270539cb-671b-4cde-a950-f5e2a83ea38a

一个使用 [Godot 4.8-dev3](https://godotengine.org/) 制作的 2D 像素风游戏。

## 环境要求

| 工具 | 说明 |
|------|------|
| Godot | **4.8-dev3**，由准备脚本自动下载，无需手动安装 |
| curl 或 wget | Linux/macOS 下载引擎二进制所需 |
| Python 3 | 运行无头验证脚本（`tests/run_godot_verify.py`） |
| unzip | Linux/macOS 解压引擎压缩包所需 |

引擎二进制下载后存放于 `.engine/`，同时缓存到 `~/.cache/godot-engines/` 以便复用。  
`.engine/` 和 `.tmp/` 均已加入 `.gitignore`，不会提交到仓库。

---

## 快速开始

### Linux / macOS

```bash
# 1. 准备引擎（首次运行会从官方下载，约 60 MB）
bash .engine-prepare.sh

# 2. 打开编辑器
.engine/.engine --editor --path .

# 3. 运行无头验证（CI 同款）
python3 tests/run_godot_verify.py --timeout 120 -- \
  .engine/.engine --headless --path . \
  --script res://tests/verify_arc_planet.gd
```

### Windows

```bat
REM 1. 准备引擎（在仓库根目录双击或命令行执行）
.engine-prepare.bat

REM 2. 打开编辑器（准备完成后自动启动）
.engine-edit.bat
```

---

## 引擎信息

| 项目 | 值 |
|------|----|
| Godot 版本 | 4.8-dev3 |
| 下载来源 | `https://downloads.godotengine.org/` |
| Linux 二进制 | `Godot_v4.8-dev3_linux.x86_64` |
| Windows 二进制 | `Godot_v4.8-dev3_win64.exe` |
| 缓存路径 | `~/.cache/godot-engines/4.8-dev3-standard/` |

---

## 验证 / 测试

项目包含一个无头模式验证脚本，用于检查核心机制和资源：

```bash
python3 tests/run_godot_verify.py --timeout 120 -- \
  .engine/.engine --headless --path . \
  --script res://tests/verify_arc_planet.gd
```

验证内容包括：
- 世界常量（半径、弧顶比例、精灵尺寸等）
- 必要的静态贴图资源可加载且尺寸正确
- 无旧版伪 3D 残留文件
- InputMap 按键映射完整
- 主场景结构（SubViewport、Planet、Player）及圆弧力学

**退出码**：`0` = 全部通过，`1` = 存在失败项。

---

## CI

每次 push / pull request 会自动触发 GitHub Actions：

- 缓存 Godot 引擎二进制（key: `godot-4.8-dev3-standard`）
- 运行 `.engine-prepare.sh` 准备引擎
- 执行上述无头验证脚本

详见 [`.github/workflows/ci.yml`](.github/workflows/ci.yml)。

---

## 项目结构

```
.
├── addons/                  # 编辑器插件（含 EditableTexture）
├── audio/                   # 配乐、脚步、总线布局
├── core/                    # 世界常量
├── interact/                # 交互系统
├── journey/                 # 主旅程入口 main.tscn
├── planet/                  # 星球场景、运行壳、共享贴图与着色器
├── player/                  # 玩家脚本
├── story/                   # 各星球演出脚本
├── tests/                   # 无头验证
├── ui/                      # 对话框、提示、字体、头像
├── visual/                  # 色板后处理
└── project.godot
```
