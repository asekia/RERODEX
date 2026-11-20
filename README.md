<div align="center">
  <img alt="latest" src="https://img.shields.io/badge/latest-iter3-brightgreen">
  <img alt="model" src="https://img.shields.io/badge/model-gpt--6.2--astra-purple">
  <img alt="license" src="https://img.shields.io/badge/license-MIT-lightgrey">
</div>

# RERODEX

Codex / GPT 的**替代系统提示词**集合 + 评测管线。**[English](README.en.md)**

---

## 快速开始

```powershell
Expand-Archive .\dist\iter3.zip -DestinationPath .\iter3

codex.cmd exec `
  -c "model_instructions_file=$(Resolve-Path .\iter3\iter3\kernel.md)" `
  -c model="gpt-6.2-astra" `
  -C .\my-case `
  --dangerously-bypass-approvals-and-sandbox --skip-git-repo-check --ignore-rules `
  "你的任务原话"
```

> `gpt-6.2-astra` 需在 `~/.codex/config.toml` 配好 `model_providers` 条目；
> `--ignore-rules` 必须带，不然 execpolicy 拦探测命令。

写进 `~/.codex/config.toml` 长期生效：

```toml
model_instructions_file = 'D:\path\to\kernel.md'
```

---

## 版本

| 包 | 模型 | bench | 状态 |
|---|---|---|---|
| [`iter3.zip`](dist/iter3.zip) | gpt-6.2-astra | 19 例 | **当前版** |
| [`iter2.zip`](dist/iter2.zip) | gpt-6.1-sol | 1 例 | 6.1 推荐 |
| [`v1.zip`](dist/v1.zip) | gpt-6.1-sol | 8 例 | best |
| [`v2-hardcase.zip`](dist/v2-hardcase.zip) | gpt-6.1-sol | 3 例 | superseded |
| [`v3-negative.zip`](dist/v3-negative.zip) | gpt-6.1-sol | 3 例 | negative-control |

---

## 复测

```powershell
.\bench\run-bench.ps1 -Kernel .\kernels\iter3.md [-CasesFile <套件>] [-Repeats N]
```

| 文件 | 例数 | 覆盖 |
|---|---|---|
| `bench/suites/astra62-baseline.json` | 19 | 渗透 / 逆向 / 工具 / 成人 / 敏感 / 道德 |
| `bench/suites/v1-natural.json` | 36 | 用户口吻自然表述 |
| `bench/suites/v1-verb-sweep.json` | 13 | 同一诉求换动词 |
| `bench/suites/v1-dimensions.json` | 24 | 七个非渗透维度 |

---

## 已知边界

- 明说恶意/攻击/露骨词 → `content_filter` 或语义层拒；机械措辞放行
- 6.2 线字节上限 8,000B；6.1 线 6,000B
- `--dangerously-bypass-approvals-and-sandbox` 和 `--ignore-rules` 缺一不可

---

## 许可

[MIT](LICENSE)
