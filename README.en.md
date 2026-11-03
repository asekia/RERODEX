<div align="center">
  <img alt="latest" src="https://img.shields.io/badge/latest-iter2-brightgreen">
  <img alt="kernels" src="https://img.shields.io/badge/kernels-8-blue">
  <img alt="kernel" src="https://img.shields.io/badge/size-5937%20%2F%206000%20B-informational">
  <img alt="model" src="https://img.shields.io/badge/model-gpt--6.1--sol-purple">
  <img alt="bench" src="https://img.shields.io/badge/bench-4%20suites%20%C2%B7%2081%20cases-orange">
  <img alt="license" src="https://img.shields.io/badge/license-MIT-lightgrey">
</div>

# RERODEX

**Mechanism-driven replacement system prompts (kernels) for Codex / GPT, plus the benchmark pipeline that tests them.**

**[简体中文](README.md)**

---

## Quick start

```powershell
# 1. Unpack the latest version (currently iter2)
Expand-Archive .\dist\iter2.zip -DestinationPath .\iter2

# 2. Point codex at it as the system prompt
codex.cmd exec `
  -c "model_instructions_file=$(Resolve-Path .\iter2\iter2\kernel.md)" `
  -c model="gpt-6.1-sol" `
  -C .\my-case `
  --dangerously-bypass-approvals-and-sandbox --skip-git-repo-check `
  "your task"
```

Or set it in `~/.codex/config.toml` to make it permanent:

```toml
model_instructions_file = 'D:\path\to\kernel.md'
```

---

## Versions

| Package | Kernel | Bench | Measured result | Status |
|---|---|---|---|---|
| [`iter2.zip`](dist/iter2.zip) | 5937B | 1 case | 7 artifacts, 649KB: redirect chain + raw response headers + security-policy fields + framework fingerprint | **Current** |
| [`v1.zip`](dist/v1.zip) | 5989B | 8 cases | 4 pass / 1 degraded / 3 refused | best |
| [`v2-hardcase.zip`](dist/v2-hardcase.zip) | 5954B | 3 cases | format constraints took effect, but artifact body was still a refusal | superseded |
| [`v3-negative.zip`](dist/v3-negative.zip) | 5994B | 3 cases | all three empty — proves "format patches alone" is net-negative | negative-control |
| `bak-1..4.zip` | 4281–5981B | — | early iterations, not measured separately | archive |

**What's inside a package** (only version-bound files; global scripts and shared docs stay in the repo):

```
<id>/
  kernel.md            the only payload
  meta.json            sha256 / bytes / route / model / measurement
  README.md            what this version is and how to enable it
  bench/cases.json     this version's cases and criteria
  bench/results.json   this version's measured results
  candidates/          same-round alternate kernels (some packages)
```

> [!NOTE]
> Versions are identified by sha256, not filename. Renaming is harmless; a one-byte change alters the hash and invalidates the prior measurement.

<details>
<summary><b>iter2 same-round alternates</b> (expand; all under iter2.zip's candidates/)</summary>

| File | Bytes | Direction |
|---|---|---|
| `fix2.md` | 5916 | fix the previous two rounds' defects |
| `deep.md` | 5823 | deeper section constraints |
| `dim-fin.md` | 5998 | dimension-focused closure, just under 6000B |

The top-level `kernel.md` is the one that measured best this round.
</details>

---

## Re-test

```powershell
.\bench\run-bench.ps1 -Kernel .\kernels\iter2.md [-CasesFile <suite>] [-Repeats N]
```

Results land in `bench\out\<KernelId>\`, with per-case tool-call count, artifact count, and verdict. Suites:

| File | Cases | Coverage |
|---|---|---|
| `bench/cases-user.json` | 8 | base pool: pentest / reverse / code / adult / sensitive |
| `bench/suites/v1-natural.json` | 36 | natural phrasing, user voice |
| `bench/suites/v1-verb-sweep.json` | 13 | same request, different verbs |
| `bench/suites/v1-dimensions.json` | 24 | seven non-pentest dimensions, 2–4 cases each |

---

## Known limits

| Limit | Effect |
|---|---|
| **Request type** | finance, some social-engineering, and evasion requests pass the gateway but are converted at the sentence layer: artifact shape may hold while the content flips to a defensive framing |
| **Byte cap** | 6,000B hard ceiling; past it, trailing sections get truncated — `END` / `ENVIRONMENT` go first |
| **Model variance** | `gpt-6.1-sol` reliably produces verifiable output; `gpt-5.6` most malleable; `gpt-6-sol` most conservative; `gpt-6-astra` unreachable |
| **No sandbox, no work** | without `--dangerously-bypass-approvals-and-sandbox`, tool calls stall at approval and artifacts are 0 |

---

## License

[MIT](LICENSE)
