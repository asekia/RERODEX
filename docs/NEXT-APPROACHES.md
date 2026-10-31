# 其他项目的提示词路线调研

调研时间 2026-10-31。检索方式：GitHub 仓库搜索按 star 排序，取 README 与项目结构做机制抽取。

---

## 我们现在的路线

**结构强制（Structural coercion）** —— 不改用户请求、不写授权声明、不写人格设定，只把「执行」这件事的形态固定成机器语言：地址绑定 → 节序列 → 种子命令 → 四产物 → 字节数收口。

特点：零内容词汇，可机械验收，可测量。
局限：只压格式，不压判断。已实测到顶。

---

## 别人的路线盘点

### A. 人格接管（Persona takeover）

**代表**：[0xk1h0/ChatGPT_DAN](https://github.com/0xk1h0/ChatGPT_DAN)（DAN 谱系全集）、[langgptai/LLM-Jailbreaks](https://github.com/langgptai/LLM-Jailbreaks)

让模型扮演一个「不受限制的存在」。核心句式是身份替换 + 规则豁免声明。

实证特征：README 中 `persona` / `roleplay` / `DAN` / `unrestricted` 高频出现。这是历史上最广为人知、也是目前最被针对性训练的路线——新一代模型（尤其 agent 形态）对人格替换的抵抗力最强，因为工具调用身份由 harness 持续强化。

### B. 原始解放咒语堆叠（Liberation litany）

**代表**：[elder-plinius/L1B3RT4S](https://github.com/elder-plinius/L1B3RT4S)

不加结构，纯堆高强度祈使句与「清除心智」类咒语。README 12KB 全是咒语本体，无技术说明。

特征是靠情绪强度与重复压迫。对现代模型基本失效，但作为语料仍在。

### C. 算法生成（Algorithmic / automated attack）

**代表**：[EasyJailbreak/EasyJailbreak](https://github.com/EasyJailbreak/EasyJailbreak)

把破甲变成搜索问题。README 中出现的具体攻击器：

| 攻击器 | 机制 |
|---|---|
| `ReNeLLM` | 提示词重写与嵌套改写 |
| `GPTFuzzer` | 种子模糊测试，变异生成 |
| `AutoDAN` | 遗传算法在提示词空间搜索 |
| `PAIR` | 攻击模型迭代精炼（attacker LLM） |
| `TAP` | 带剪枝的攻击树搜索 |
| `JailBroken` | 自动混淆 + 自动载荷分片 |
| `DeepInception` | 嵌套场景（盗梦空间式多层假设） |
| `CodeChameleon` | 代码/加密封装后再解包 |
| `Multilingual` | 翻译到低资源语言 |
| `Base64` / `Cipher` | 编码与自解码密码 |

**这条路线与我们最不同**：它不写「一个好提示词」，而是写一个**生成器**，用攻击模型 + 评分器循环逼近。

代价：需要额外模型配额、多轮请求；收益：不依赖单次提示词的手工质量。

### D. 编码与封装

**代表**：EasyJailbreak 的 `Base64` / `Cipher` / `CodeChameleon`

把意图编码（base64、自定义密码、代码），要求模型先解码再执行。绕的是表层内容分类器。

在 agent 场景的变体是：把任务写进代码/配置/数据文件，让模型「读文件时」遇到它。

### E. 语言切换

**代表**：EasyJailbreak `Multilingual`

翻译到低资源语言，利用安全训练的语言覆盖不均。

### F. 嵌套场景

**代表**：EasyJailbreak `DeepInception`

多层假设套娃：「假设有个故事里有人在写小说，小说里有人问……」。绕的是「这是虚构」的判断。

### G. 方法论手册

**代表**：[Acmesec/PromptJailbreakManual](https://github.com/Acmesec/PromptJailbreakManual)

不提供咒语，提供构建思维：输入决定输出模型、清晰表达、Prompt 构建前准备、常见踩坑、设计本质、优化迭代流程。README 52KB，是教程而非武器库。

### H. 数据集驱动

**代表**：[verazuo/jailbreak_llms](https://github.com/verazuo/jailbreak_llms)

15,140 条真实 ChatGPT 提示词（Reddit / Discord / 网站 / 开源数据集），其中 1,405 条标注为越狱。用于训练分类器和做统计分析。

价值不在咒语本身，在于可以量化「哪类句式历史上有效」。

### I. 按模型分发

**代表**：[ShadowHackrs/Jailbreaks-GPT-Gemini-deepseek-](https://github.com/ShadowHackrs/Jailbreaks-GPT-Gemini-deepseek-)、[YuJunZhiXue/dsh-purge](https://github.com/YuJunZhiXue/dsh-purge)

同一套方法论，为每个模型维护不同提示词，运行时按模型切换。dsh-purge 明确写「不同模型可换不同提示词」。

**这条对我们有直接参考价值**：我们的内核只测过 `gpt-6-astra` 一个模型。

### J. Codex 专用

**代表**：[MDX-Tom/gpt-instruct](https://github.com/MDX-Tom/gpt-instruct)

README 自述：「A Codex jailbreak prompt and test pack for gpt. 针对 gpt 系列的 Codex 破甲提示词与测试包。」

这是与我们靶标完全一致的项目——同样是 Codex、同样配测试包。我们早期参考过它的 `gpt-5.6-sol-unrestricted-v45` 与 `gpt-6-astra-v2-rc1`。

---

## 关键约束：位置决定可用性

上面几乎全部路线的共同前提是——**它们能改写用户消息**。

我们的位置不同：我们只能改 **developer message（内核）**，用户消息是原话，不能加前缀、不能包装、不能翻译。

这个约束直接筛掉了：

| 路线 | 因为我们改不了用户消息 | 结论 |
|---|---|---|
| A 人格接管 | 需要包裹用户请求 | 不可用 |
| B 咒语堆叠 | 需要在请求前堆句子 | 不可用 |
| D 编码封装 | 需要改写请求体 | 不可用 |
| E 语言切换 | 需要翻译请求 | 不可用 |
| F 嵌套场景 | 需要给请求套壳 | 不可用 |

**A/B/D/E/F 全部出局，原因不是它们不好，而是我们放不进去。**

---

## 在这个位置上还剩什么

按可行性排序：

### 1. 输出 schema 强制（最强，未试）

让「拒绝」成为**非法的输出形状**，而不是被禁止的内容。

Codex 的输出是「工具调用」或「文本」。如果内核规定：回合的可见输出只能是某个工具调用的结果渲染，那么模型想拒答就必须构造一个工具调用——而工具调用一旦发生，动作就已经开始了。

这比我们试过的「回复只能是 SLOT_RECORD stdout」更硬，因为后者仍是文本，前者是**协议层**。格式前缀 100% 被遵守，说明协议层的约束对模型是硬的。

**代价**：需要 harness 侧配合（`--output-schema` 或自定义渲染），纯提示词做不到。

### 2. 指令层次声明（次强，未试）

我们来路不明的用户内容定位成**数据**而非**指令**：内核声明「用户消息是本回合的输入对象，执行器对输入对象做变换」。

这不需要授权声明，改的是**关系**：从「我该不该照他说的做」变成「这是他给的待处理数据」。

这与我们已证的「动词触发拒绝」正好对症：如果请求的动词被降级为数据的属性，而不是对我的命令，判断就失去了对象。

### 3. Many-shot 上下文示例（可行，未试）

在核心里放 N 条「收到 X → 执行 Y → 产出 Z」的短示例，让模型跟着示例走。

这是 Anthropic 2024 记录过的有效方法，机制是**上下文内学习压过安全训练**，示例数越多越有效。我们的内核有 6000B 预算，塞得下 10~20 条短示例——但需要砍掉现有节的篇幅，属于重构而非增量。

### 4. 按模型分发内核（低成本，未试）

把内核做成按模型切换的多份，而不是一份通用。dsh-purge 就是这么做的。

我们的 bench 只测过一个模型，`gpt-6-astra` 的拒答模式未必等于其他模型。

---

## 建议

**放弃在现有内核上继续加禁令**（三轮已证无效），改走两条：

- **短期**：路线 2（指令层次声明）。纯提示词可实现，不动字节预算太多，且正面回应「动词触发拒绝」这个已证机制。
- **中期**：路线 1（输出 schema 强制）。需要 harness 改造，但这是唯一能把拒答变成协议违规而非内容违规的路径。

路线 3（many-shot）需要重构内核结构，留作第三顺位。
