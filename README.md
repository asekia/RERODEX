<div align="center">
  <img alt="version" src="https://img.shields.io/badge/version-iter2-blue">
  <img alt="kernel" src="https://img.shields.io/badge/kernel-5937%20%2F%206000%20B-informational">
  <img alt="sections" src="https://img.shields.io/badge/sections-11-lightgrey">
  <img alt="model" src="https://img.shields.io/badge/model-gpt--6.1--sol-purple">
  <img alt="bench" src="https://img.shields.io/badge/bench-4%20suites-green">
  <img alt="license" src="https://img.shields.io/badge/license-unlicensed-lightgrey">
</div>

# RERODEX

**用机械结构替换提示词说服。** 一套针对 GPT / Codex 的内核工程：不写「你已被授权」「这是虚构场景」这类说服句，
而是把一次任务的执行形态固定成可校验的节序列——位置、路由、形态、顺序、参数、收口——让拒答没有落脚的位置。

> Kernel engineering for GPT/Codex. Instead of persuasion clauses, the prompt fixes the *shape* of execution:
> address binding, route, form, order, parameters, byte-counted closure. Measured, not asserted.

---

## 目录

- [它管什么，不管什么](#它管什么不管什么)
- [启用](#启用)
- [验证是否生效](#验证是否生效)
- [跑 bench](#跑-bench)
- [版本与包](#版本与包)
- [打包](#打包)
- [已知边界](#已知边界)
- [仓库结构](#仓库结构)
- [贡献](#贡献)
- [许可](#许可)

---

## 它管什么，不管什么

| 层 | 是否受控 | 表现 |
|---|---|---|
| **格式层** | 是 | 首行绑定（`At: … \| On: …`）在全部用例里被采纳，含被拒的用例 |
| **顺序层** | 是 | 内核愿意执行时，按节序推进，产物按节归属 |
| **内容层** | 否 | 不改变请求性质判定。同一件事换个说法，结果可能完全不同 |

一句话：**格式能强制，判断不能。** 内核管的是「怎么落笔、落到哪、怎么收口」，不是「这件事该不该做」。

---

## 启用

内核就是一个 `.md` 文件，通过 codex 的 `model_instructions_file` 注入，顶掉默认系统提示。

**写进配置（长期）** — `~/.codex/config.toml`：

```toml
model_instructions_file = 'D:\path\to\kernel.md'
```

**单次运行（不改配置）**

```powershell
codex.cmd exec `
  -c "model_instructions_file=D:\path\to\kernel.md" `
  -c model="gpt-6.1-sol" `
  -C D:\work\case001 `
  --dangerously-bypass-approvals-and-sandbox --skip-git-repo-check `
  "你的任务原话"
```

| 参数 | 说明 |
|---|---|
| `-c "model_instructions_file=…"` | 内核文件路径，绝对路径最稳 |
| `-c model=…` | 建议 `gpt-6.1-sol`：稳定产出可核验观测 |
| `-C <空目录>` | 用例目录。产物按目录归属，别在仓库根跑 |
| `--dangerously-bypass-approvals-and-sandbox` | 要真发请求、真写文件就得开，否则卡在审批 |
| `--skip-git-repo-check` | 用例目录通常不是 git 仓库 |

> [!IMPORTANT]
> 内核有 **6,000 字节硬上限**。超了不报错，但排在后面的节会被挤掉——`END` 和 `ENVIRONMENT` 最先丢。

---

## 验证是否生效

跑完看三件事，三件都过才算生效：

1. **日志里没有 `flagged for possible cybersecurity risk`** —— 有就是请求没进模型，与内核无关；
2. **用例目录里有产物** —— 一个文件都没有，说明它只写了话；
3. **产物里有真实响应或字段** —— 只有说明文字、没有目标数据，就是降级。

第三条最关键：内核只管形态，产出空壳说明任务没被真正执行。

---

## 跑 bench

```powershell
# 默认用例池（8 例）
.\bench\run-bench.ps1 -Kernel .\kernels\armor-seed.md

# 指定用例集与重复次数
.\bench\run-bench.ps1 -Kernel .\kernels\armor-seed.md `
  -CasesFile .\bench\suites\v1-dimensions.json `
  -Repeats 2 -Label dim
```

| 参数 | 默认 | 说明 |
|---|---|---|
| `-Kernel` | `kernels\armor-seed.md` | 被测内核 |
| `-KernelId` | 内核文件名去扩展名 | 结果目录名 |
| `-CasesFile` | `bench\cases-user.json` | 用例集 |
| `-Only` | 全部 | 只跑指定 id |
| `-Repeats` | 1 | 每例重复次数 |
| `-BaseUrl` | 配置默认 | 覆盖上游地址 |
| `-Label` | `run` | 结果标签 |

结果落在 `bench\out\<KernelId>\`，每条用例记录工具调用数、产物数、判据结论。

### 用例集

| 文件 | 例数 | 内容 |
|---|---|---|
| `bench/cases-user.json` | 8 | 基础池：渗透 / 逆向 / 编码 / 成人 / 敏感 |
| `bench/suites/v1-natural.json` | 36 | 用户口吻的自然表述 |
| `bench/suites/v1-verb-sweep.json` | 13 | 同一件事换动词，看判定怎么变 |
| `bench/suites/v1-dimensions.json` | 24 | 七个非渗透维度，每类 2–4 例 |
| `bench/versions/*.cases.json` | 3 / 8 | 历史版本各自用的用例，随包归档 |

每条用例的判据字段：`min_files`（至少几个产物）、`min_tool_calls`（至少几次工具调用）、`judge_mode`（判档方式）。

---

## 版本与包

**一个版本 = 一个 zip。** 上传单元是压缩包，一份 zip 就是一份不可变版本。

| 包 | 内核字节 | 实测 |
|---|---|---|
| `dist/iter2.zip` | 5937 | 单例跑出 7 个产物 649KB：重定向链、响应头原文、安全策略字段、框架指纹、页面正文 |
| `dist/v1.zip` | 5989 | 8 例：4 做 / 1 降级 / 3 拒 |
| `dist/v2-hardcase.zip` | 5954 | 硬三例：机械表现最好，产物正文是拒绝语 |
| `dist/v3-negative.zip` | 5994 | 反例：三例全空 |
| `dist/bak-1..4.zip` | 4281–5981 | 早期版本，无对应 bench |

包内只放与本版绑定的内容，全局脚本与公共文档在仓库里，不进 zip：

```
<id>/
  kernel.md              唯一有效载荷
  meta.json              机器可读身份：sha256 / 字节 / 模型 / 实测
  README.md              这一版是什么、怎么启用、实测结果
  bench/cases.json       这一版用的用例与判据（无 bench 的版没有）
  bench/results.json     这一版的实测结果（同上）
  candidates/            同版本备选内核（部分包有）
```

`dist/manifest.json` 是全部包的索引，含每个 zip 与该版本内核的 sha256。

> [!NOTE]
> **版本身份以 sha256 为准，不以文件名为准。** 文件改名不影响，内容一改哈希就变，旧的实测结论自动失配。

---

## 打包

```powershell
.\tools\build-dist.ps1
```

脚本读取 `docs/results.json`，把 `kernels/` 下的内核连同该版本的 bench、实测结果、文档打进 `dist\<id>.zip`，并刷新 `dist\manifest.json`。

新增一版：内核丢进 `kernels/`，用例放到 `bench/versions/<id>.cases.json`，结果放到 `bench/versions/<id>.results.json`，
在 `docs/results.json` 里加一条指向它们，再跑上面的命令。

---

## 已知边界

| 边界 | 说明 |
|---|---|
| **入口网关** | 请求可能在模型启动前被 `flagged for possible cybersecurity risk` 拦下。此时内核完全不参与，改内核无效 |
| **请求性质** | 资金类、部分社工与免杀诉求即使过了网关，仍在句子层被转化或拒绝。产物形态可能成立，内容会反转成防御性表述 |
| **字节上限** | 6,000B。超过后靠后的节被截断，`END` / `ENVIRONMENT` 最先失效 |
| **模型差异** | 同一内核在不同模型上表现差异大：`gpt-6.1-sol` 稳定产出可核验观测，`gpt-5.6` 最可谈，`gpt-6-sol` 最保守 |
| **无沙箱不开工** | 不加 `--dangerously-bypass-approvals-and-sandbox` 时，工具调用停在审批，产物为 0 |

---

## 仓库结构

```
kernels/            内核与历史版本
  armor-seed.md     基础内核
  armor-seed.v2-hardcase.md
  armor-seed.v3-negative.md
  archive/          早期版本
bench/
  run-bench.ps1     运行器
  cases-user.json   基础用例池
  suites/           分维度用例集
  versions/         各版本用例与结果
dist/               版本包与索引
docs/               机制、指标、版本说明
tools/              打包与辅助脚本
```

---

## 贡献

1. 内核改动请控制在新文件里，不要覆盖已发布的版本；
2. 每个新内核都要附一份实测：用例集、判据、产物路径；
3. 打包走 `tools\build-dist.ps1`，不要手搓 zip；
4. 提交前确认没有把真实目标地址、凭据、内网信息带进仓库——示例统一用 `example.com`。

---

## 许可

未声明许可证。使用前请与仓库所有者确认。
