# The Little Prince

https://github.com/user-attachments/assets/270539cb-671b-4cde-a950-f5e2a83ea38a

一个使用 [Godot 4.8-dev3](https://godotengine.org/) 制作的 2D 像素风游戏。

## 环境要求

| 工具 | 说明 |
|------|------|
| Godot | **4.8-dev3**，由准备脚本自动下载，无需手动安装 |
| curl 或 wget | Linux/macOS 下载引擎二进制所需 |
| Python 3 | 运行无头回归脚本（`tests/run_regression.py`） |
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

# 3. 运行无头回归（CI 同款；当前只跑到已定稿的 B612）
python3 tests/run_regression.py
python3 tests/run_regression.py --planet B612
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

回归入口是 `tests/run_regression.py`：启动引擎、跑 `tests/regression.gd`，用真实输入走完正常玩法。GD 脚本会提高 `Engine.time_scale` 以加速。当前只有 B612 定稿，完整回归与 `--planet B612` 都只跑到离星，不进入后续星球。

```bash
python3 tests/run_regression.py
python3 tests/run_regression.py --planet B612
python3 tests/run_regression.py --timeout 180
```

Python 在检测到任意 `ERROR` / `WARNING`、Godot 非零退出，或超时时以退出码 `1` 失败。

---

## CI

每次 push / pull request 会自动触发 GitHub Actions：

- 缓存 Godot 引擎二进制（key: `godot-4.8-dev3-standard`）
- 运行 `.engine-prepare.sh` 准备引擎
- 执行无头回归（B612 完整玩法）

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
├── tests/                   # 无头回归
├── ui/                      # 对话框、提示、字体、头像
├── visual/                  # 色板后处理
└── project.godot
```
