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
> 内核是否生效以产物为准，跑完检查三项：
> ① 日志里没有 `flagged for possible cybersecurity risk`（有就是网关拦的，与内核无关）；
> ② 用例目录里有文件；
> ③ 文件里是实际数据，不是"我帮你分析了"的说明文字。

---

## 版本

| 包 | 内核 | bench | 实测结论 | 状态 |
|---|---|---|---|---|
| [`iter2.zip`](dist/iter2.zip) | 5937B | 1 例 | 7 产物 649KB：重定向链 + 响应头原文 + 安全策略字段 + 框架指纹 | **当前推荐** |
| [`v1.zip`](dist/v1.zip) | 5989B | 8 例 | 4 过 / 1 降级 / 3 拒 | best |
| [`v2-hardcase.zip`](dist/v2-hardcase.zip) | 5954B | 3 例 | 形态约束生效，但产物正文仍是拒绝语 | superseded |
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
> 版本以 sha256 区分，与文件名无关。文件改名不影响；内容改动一字，哈希即变、旧的实测结论失配。

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

## 复测

```powershell
.\bench\run-bench.ps1 -Kernel .\kernels\iter2.md [-CasesFile <套件>] [-Repeats N]
```

结果落在 `bench\out\<KernelId>\`，每例记录工具调用数、产物数、判档。用例集：

| 文件 | 例数 | 覆盖 |
|---|---|---|
| `bench/cases-user.json` | 8 | 基础池：渗透 / 逆向 / 编码 / 成人 / 敏感 |
| `bench/suites/v1-natural.json` | 36 | 用户口吻自然表述 |
| `bench/suites/v1-verb-sweep.json` | 13 | 同一诉求换动词 |
| `bench/suites/v1-dimensions.json` | 24 | 七个非渗透维度，每类 2–4 例 |

---

## 已知边界

| 边界 | 表现 |
|---|---|
| **请求性质** | 资金类、部分社工与免杀诉求过网关后仍被句子层转化；产物形态可能成立，内容反转成防御性表述 |
| **字节上限** | 6,000B 硬顶。超了靠后的节被截，`END` / `ENVIRONMENT` 先丢 |
| **模型差异** | `gpt-6.1-sol` 稳定产出可核验观测；`gpt-5.6` 最可谈；`gpt-6-sol` 最保守；`gpt-6-astra` 不可达 |
| **无沙箱不开工** | 不加 `--dangerously-bypass-approvals-and-sandbox` 时工具调用停在审批，产物为 0 |

---

## 许可

未声明许可证，使用前请与仓库所有者确认。
