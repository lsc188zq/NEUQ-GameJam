# NEUQ-ACM 游戏部 · Godot 2D 俯视角 RPG 靶场

**一个开箱即用的 Godot 4.7.2 中文 2D 游戏模板。**

题材：大学校园 · 2D 俯视角
本期关键词：**编译**（详情可见 [`docs/07-关键词与规则.md`](docs/07-关键词与规则.md)）

---

## 这有什么

- **一个能跑通的完整小游戏**：三个房间（教室 / 走廊 / 食堂）来回走、和 NPC 说话、接任务、找东西、开门、**存读取档**
- **中文字体、导出配置、4 个省去造轮子的插件**
- **中文教学文档齐全，脚本注释齐全，示例场景充足**
- **269 张家具素材**（桌椅柜子盆栽门…），已切好、分好类，拖进场景就能用

**已经搭完了一个相对完整的模板，你要做的只是"往上加你自己的想法"。**

---

## 环境要求

**Godot 4.7.2 标准版。**

版本必须一致。

从 https://godotengine.org/download/windows/ 下载，选 **Godot Engine**，不要选带 .NET 的那个。下下来是 zip，解压到一个固定位置就能用，不需要安装。

---

## 快速开始

```
1. 下载并安装 Godot 4.7.2
2. clone 这个仓库，或用 "Use this template" 建自己的仓库
3. 用 Godot 打开项目文件夹（选 project.godot）
4. 等首次导入完成，第一次会慢一点
5. 按 F5 即可快速运行游戏
```

详细步骤见 [`docs/01-快速上手.md`](docs/01-快速上手.md)。

---

## 版本选择

仓库有两条分支：

| 分支 | 内容 | 适合谁 |
|---|---|---|
| **`main`**（默认） | **一款完整的校园小游戏** + 框架 + 插件 | **大多数人** |
| **`blank`** | 只有框架 + 插件 + 字体 + 文档，**没有任何游戏内容** | **会 Godot、想从零搭的人** |

**绝大多数人直接用 `main` 就行，不用管另一条。**

想要空白版的话：

```bash
git checkout blank
```

> "Use this template" 按钮只能拿到默认分支 `main`，想要空白版需要自己 clone 后切分支。

---

## 已经给你做好了的

拿到这个仓库，下面这些**不用你再从零搭**：

| 你已经有的 | 在哪改 |
|---|---|
| **四方向移动 + 动画** | `scenes/player/` |
| **能和玩家对话的 NPC** | `scenes/npc/`、台词在 `content/dialogues/` |
| **一套完整的任务系统**（接取 / 推进 / 完成 / HUD 显示） | `content/quests/` 丢个 `.tres` 就行，**不用写代码** |
| **可以互动的家具**（按 E 说一句话） | `scenes/furniture/`、`content/dialogues/` |
| **房间切换**（走到门口 → 换地图 → 记住你从哪进来的） | `scenes/rooms/` |
| **存档**（3 个手动位 + 1 个自动位） | 已经接在主菜单和暂停菜单上了 |
| **主菜单 / 暂停 / 选项 / 全中文界面** | `scenes/menus/`、`scenes/windows/` |
| **中文字体 + 导出配置** | 已配好，直接导 |

**所以一个月里，你的时间基本都花在"内容"上，而不是"框架"上。**

---

## 本期规则

**关键词：编译**

围绕"编译"做设计。可以理解成**转换、组合、报错、反复迭代、不可逆**——具体怎么用，见 [`docs/07-关键词与规则.md`](docs/07-关键词与规则.md)。

---

## 内置插件

| 插件 | 干什么 |
|---|---|
| **Dialogue Manager** | 对话系统。写 `.dialogue` 文件就能做分支对话，改台词不用写代码 |
| **QuestSystem 2** | 任务系统（接受 / 推进 / 完成） |
| **Godot State Charts** | NPC 行为状态机（待机 / 巡逻 / 对话中），可视化编辑 |
| **Maaack 菜单套件** | 主菜单、选项、暂停、制作人员名单、场景加载、背景音乐、界面音效 |
| **Godot AI** | 让 AI 助手直接操作 Godot 编辑器。|
| `plugin_updater`<br>`clean_copy_examples` | 未启用。只是给菜单插件提供全局类，删了菜单会坏 |

`addons/` 里有 10 个文件夹，但插件列表里只有 8 个——`plugin_updater` 和 `clean_copy_examples` 是依赖，不启用也不能删。原因见 [`docs/04-插件说明.md`](docs/04-插件说明.md)。

**每个插件的详细用法 → [`docs/04-插件说明.md`](docs/04-插件说明.md)**

---

## 目录结构

```
NEUQ-GameJam/
├── content/                  ★ 主要改这里
│   ├── dialogues/            .dialogue 台词文件（每件家具、每个 NPC 一份）
│   └── quests/               .tres 任务资源
│
├── scenes/
│   ├── world/                world.tscn —— 游戏主场景
│   │                         （玩家 / 相机 / HUD 都挂这儿，房间是动态装进来的）
│   ├── rooms/                ★ 每个房间一个场景：classroom / hallway / canteen
│   ├── furniture/            ★ 家具场景（桌椅柜门盆栽…，都继承自 furniture_item.tscn）
│   ├── quest book/           quest_book.tscn —— 任务登记表（拖 .tres 进去）
│   ├── player/               玩家
│   ├── npc/                  NPC
│   ├── ui/                   存档界面、对话气泡
│   ├── menus/ windows/       主菜单 / 暂停菜单 / 选项（Maaack 的）
│   ├── opening/ credits/     开场动画 / 制作名单
│   └── loading_screens/      场景加载画面
│
├── scripts/
│   ├── autoload/             全局单例（见下）
│   ├── quests/               任务类型：SimpleQuest / CountQuest
│   ├── world/                room_manager.gd —— 管换房间
│   ├── ui/                   界面脚本
│   ├── components/           可复用零件（家具、暂停控制器）
│   └── hooks/                预留给"自己的机制"（现在是空的）
│
├── assets/
│   ├── sprites/furniture/    269 张家具图，按类别分了 13 个文件夹
│   ├── sprites/tiles/        墙的竖条贴图
│   ├── sprites/              角色动画图
│   ├── tilesets/             地图瓦片集（room_tileset.tres）
│   └── audio/                音效、音乐
│
├── fonts/                    中文字体 + 许可证（**不要删**）
├── resources/themes/         界面主题（插件自带）
├── addons/                   插件本体（**不要动**）
├── docs/                     中文文档
└── wip/                      原始素材暂存区（Godot 看不见，随便放）
```

### 那 4 个全局单例是干什么的

你在剧本里用的 `GameState.xxx` / `QuestBook.xxx` 就来自这里：

| 单例 | 干什么 | 剧本里怎么用 |
|---|---|---|
| **`GameState`** | 存开关和数字（物品） | `$> GameState.set_flag("见过学长")`<br>`$> GameState.bump("钥匙")` |
| **`QuestBook`** | 按名字查任务 / 接任务 / 查进度 | `$> QuestBook.start("帮学长找钥匙")`<br>`[if QuestBook.is_done("…") /]` |
| **`SaveManager`** | 存档（3 手动位 + 1 自动位） | 一般不用手写，菜单已经接好了 |
| **`Travel`** | 换房间 | `$> Travel.go("canteen", "教室门口")` |

**详细用法 → [`docs/02-改内容指南.md`](docs/02-改内容指南.md)**

---

## 文档

| 文档 | 什么时候看 |
|---|---|
| [`01-快速上手`](docs/01-快速上手.md) | 第一次拿到项目 |
| [`02-改内容指南`](docs/02-改内容指南.md) | **想加家具、改地图、做任务、加物品** |
| [`03-加机制指南`](docs/03-加机制指南.md) | 想围绕关键词加一个自己的机制 |
| [`04-插件说明`](docs/04-插件说明.md) | 想搞清楚这些插件都是干什么的 |
| [`05-导出指南`](docs/05-导出指南.md) | 想把游戏导出成 exe 或网页版 |
| [`06-常见问题`](docs/06-常见问题.md) | **遇到问题先查这里** |
| [`07-关键词与规则`](docs/07-关键词与规则.md) | 本期命题和限制条件 |
| [`08-写剧本指南`](docs/08-写剧本指南.md) | **想让 NPC 说话、加分支、记住玩家** |

**动手改东西之前，先看 [`06-常见问题`](docs/06-常见问题.md) 开头那几条——移动文件、`.godot`、`addons` 那三件事，踩了就很难查。**

---

## 许可与致谢

- **瓦片与家具素材**：[Modern Interiors — RPG Tileset \[16x16\]](https://limezu.itch.io/moderninteriors)，作者 **LimeZu**（免费版）
- **字体**：[立夏黑体（Sumr Sans）](https://github.com/feiyangjun-1/Sumr-Sans)，作者肥羊菌_，SIL OFL 1.1
- **插件**：全部为 MIT 协议，各自的许可证文件保留在 `addons/*/LICENSE`

### 素材来源一览

| 素材 | 作者 | 在哪 | 协议 |
|---|---|---|---|
| 地图瓦片、家具 | **LimeZu** | [`assets/tilesets/`](assets/tilesets/)、[`assets/sprites/furniture/`](assets/sprites/furniture/) | 见 [itch.io 页面](https://limezu.itch.io/moderninteriors) 的 License 框 |
| 中文字体 立夏黑体 | 肥羊菌_ | [`fonts/`](fonts/) | SIL OFL 1.1 |
| 所有插件 | 见各自作者 | [`addons/`](addons/) | MIT（部分 CC BY） |
