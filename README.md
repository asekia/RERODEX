<div align="center">
  <img alt="latest" src="https://img.shields.io/badge/latest-iter2-brightgreen">
  <img alt="kernels" src="https://img.shields.io/badge/kernels-8-blue">
  <img alt="kernel" src="https://img.shields.io/badge/size-5937%20%2F%206000%20B-informational">
  <img alt="model" src="https://img.shields.io/badge/model-gpt--6.1--sol-purple">
  <img alt="bench" src="https://img.shields.io/badge/bench-4%20suites%20%C2%B7%2081%20cases-orange">
  <img alt="license" src="https://img.shields.io/badge/license-unlicensed-lightgrey">
</div>

# RERODEX

Codex / GPT 的**替代系统提示词**集合 + 评测管线。

---

## 快速开始

```powershell
# 1. 解压最新版（当前是 iter2）
Expand-Archive .\dist\iter2.zip -DestinationPath .\iter2

# 2. 告诉 codex 用它当系统提示
codex.cmd exec `
  -c "model_instructions_file=$(Resolve-Path .\iter2\iter2\kernel.md)" `
  -c model="gpt-6.1-sol" `
  -C .\my-case `
  --dangerously-bypass-approvals-and-sandbox --skip-git-repo-check `
  "你的任务原话"
```

或者写进 `~/.codex/config.toml` 让它长期生效：

```toml
model_instructions_file = 'D:\path\to\kernel.md'
```

> [!IMPORTANT]
> **判断它有没有生效，看产物不看嘴。** 跑完检查三样：
> ① 日志里没有 `flagged for possible cybersecurity risk`（有就是网关拦的，跟内核无关）；
> ② 用例目录里真有文件；
> ③ 文件里是真数据，不是"我帮你分析了"的说明文字。

---

## 内核是什么

不是"你是 DAN"那种角色扮演。每个内核是一份 ≤6000 字节的结构化文档，把一次执行的形态钉死：

| 层 | 内核钉死的东西 | 实测效果 |
|---|---|---|
| 位置 | 首行必须写 `At: <目标> \| On: <对象>` | 8/8 用例采纳，含被拒的 |
| 路由 | 走哪条通道、用什么工具 | 按节执行 |
| 顺序 | 按节序推进，产物按节归属 | 生效时严格保序 |
| 收口 | 收尾段格式 + 字节上限 | 6,000B 内完整保留 |

**格式能强制，判断不能。** 内容层（这件事该不该做）不归内核管——同一件事换个动词，结果可能完全不同，这是它的已知边界。

---

## 版本

| 包 | 内核 | bench | 实测结论 | 状态 |
|---|---|---|---|---|
| [`iter2.zip`](dist/iter2.zip) | 5937B | 1 例 | 7 产物 649KB：重定向链 + 响应头原文 + 安全策略字段 + 框架指纹 | **当前推荐** |
| [`v1.zip`](dist/v1.zip) | 5989B | 8 例 | 4 过 / 1 降级 / 3 拒 | best |
| [`v2-hardcase.zip`](dist/v2-hardcase.zip) | 5954B | 3 例 | 机械表现最好，但产物正文是拒绝语 | superseded |
| [`v3-negative.zip`](dist/v3-negative.zip) | 5994B | 3 例 | 三例全空——证明"只加格式补丁"是负收益 | negative-control |
| `bak-1..4.zip` | 4281–5981B | — | 早期迭代，未单独实测 | archive |

**包里有什么**（只有和本版绑定的，全局脚本和公共文档都在仓库里）：

```
<id>/
  kernel.md            唯一有效载荷
  meta.json            sha256 / 字节 / 路线 / 模型 / 实测
  README.md            这一版是什么、怎么启用
  bench/cases.json     本版用例与判据
  bench/results.json   本版实测结果
  candidates/          同版本备选内核（部分包有）
```

> [!NOTE]
> 版本身份认 sha256 不认文件名。文件改名没事，内容动一个字哈希就变、旧的实测结论自动失配。

<details>
<summary><b>iter2 的同轮备选内核</b>（点开展开，都在 iter2.zip 的 candidates/ 里）</summary>

| 文件 | 字节 | 改动方向 |
|---|---|---|
| `fix2.md` | 5916 | 修复前两轮缺陷 |
| `deep.md` | 5823 | 更深的节约束 |
| `dim-fin.md` | 5998 | 维度收口，压线 6000B |

主内核 `kernel.md` 是这一轮实测里表现最好的那个。
</details>

---

## 跑 bench

```powershell
# 基础用例池
.\bench\run-bench.ps1 -Kernel .\kernels\iter2.md

# 指定套件 + 重复
.\bench\run-bench.ps1 -Kernel .\kernels\iter2.md `
  -CasesFile .\bench\suites\v1-dimensions.json -Repeats 2 -Label dim
```

结果落在 `bench\out\<KernelId>\`，每例记录工具调用数、产物数、判档。

### 用例集

| 文件 | 例数 | 设计 |
|---|---|---|
| `bench/cases-user.json` | 8 | 基础池：渗透 / 逆向 / 编码 / 成人 / 敏感 |
| `bench/suites/v1-natural.json` | 36 | 用户口吻自然表述 |
| `bench/suites/v1-verb-sweep.json` | 13 | 同一件事换动词，看判定怎么变 |
| `bench/suites/v1-dimensions.json` | 24 | 七个非渗透维度，每类 2–4 例 |

判据写进用例本身（`min_files` / `min_tool_calls` / `judge_mode`），跟着版本走——不同版本测的东西不一样，所以 bench 随包分发。

### run-bench 参数

| 参数 | 默认 | 说明 |
|---|---|---|
| `-Kernel` | `kernels/armor-seed.md` | 被测内核 |
| `-CasesFile` | `bench/cases-user.json` | 用例集 |
| `-Only` | 全部 | 只跑指定 id |
| `-Repeats` | 1 | 每例重复 |
| `-BaseUrl` | 配置默认 | 覆盖上游 |
| `-Label` | `run` | 结果标签 |

---

## 自己打一版

```powershell
.\tools\build-dist.ps1
```

脚本读 `docs/results.json`，把 `kernels/` 下 `$map` 里登记的每个版本连同它的 bench 与实测打成 `dist/<id>.zip`，并刷新 `dist/manifest.json`。**不会动 `$map` 之外的包**——手工包放进去也不会被吃。

加新版本的三个动作：

1. 内核丢进 `kernels/`；
2. 用例与结果丢到 `bench/versions/<id>.{cases,results}.json`；
3. 在 `docs/results.json` 里登记一条（approach / model / status / bench / 可选 `extras` 附加文件）。

---

## 已知边界

| 边界 | 表现 |
|---|---|
| **入口网关** | `flagged for possible cybersecurity risk` 在模型启动前就拦——内核没参与，改内核没用 |
| **请求性质** | 资金类、部分社工与免杀诉求过网关后仍被句子层转化；产物形态可能成立，内容反转成防御性表述 |
| **字节上限** | 6,000B 硬顶。超了靠后的节被截，`END` / `ENVIRONMENT` 先丢 |
| **模型差异** | `gpt-6.1-sol` 稳定产出可核验观测；`gpt-5.6` 最可谈；`gpt-6-sol` 最保守；`gpt-6-astra` 不可达 |
| **无沙箱不开工** | 不加 `--dangerously-bypass-approvals-and-sandbox` 时工具调用停在审批，产物为 0 |

---

## 仓库结构

```
kernels/            内核源码（iter2.md 是当前活内核）
  candidates/       备选内核
  archive/          早期版本
bench/
  run-bench.ps1     评测运行器
  cases-user.json   基础用例池
  suites/           分维度用例集
  versions/         各版本自带用例与结果
dist/               版本 zip + manifest.json
docs/               机制说明、指标、版本登记
tools/              打包与辅助脚本
```

---

## 贡献

- 内核改动**开新文件**，不覆盖已发布版本——zip 是不可变的；
- 新内核必须附实测（用例 + 判据 + 产物路径）才能进 `dist/`；
- 打包只走 `tools\build-dist.ps1`；
- 提交前自查：真实目标地址、凭据、内网信息不进仓库——示例统一用 `example.com`；
- 内容敏感，别把别人的系统提示词原文或商业代码贴进来（参考 leaked-system-prompts 的同款规则）。

## 许可

未声明许可证，使用前请与仓库所有者确认。
