# 龟龟投资策略 (Turtle Investment Framework) — WorkBuddy Skill

> **入口 Skill**：运行完整的龟龟策略分析管线。
> 此 Skill 由 WorkBuddy/Hermes Agent + DeepSeek V4 Flash API 驱动。
> Python 脚本层（`scripts/`）直接通过 Bash 工具调用，不需要修改。

---

## 输入格式

```
turtle-investment <股票代码>
```

支持代码格式：
- A股：`600887`、`000858`、`300750` → 自动补全 `.SH` / `.SZ`
- 港股：`00700`、`00700.HK`
- 美股：`AAPL`、`AAPL.US`

---

## 前置条件检查

在执行管线之前，检查以下文件是否存在：

```
{workspace} = Turtle_investment_framework 项目根目录
{output_dir} = {workspace}/output/{code}_{company}
```

**必须存在**：
1. `{output_dir}/qualitative_report.md` — 定性分析报告（通过 business-analysis skill 生成）
2. `{output_dir}/data_pack_market.md` — Tushare 数据包（通过 business-analysis skill 生成）

**可选**：
3. `{output_dir}/data_pack_report.md` — PDF 附注数据

若缺少必须文件，提示用户：
```
⚠️ 前置条件不满足：未找到 {缺失文件}
请先使用 business-analysis skill 对 {stock_code} 进行定性分析。
```

---

## 执行管线

### Step A: 市场数据刷新

刷新数据包中的价格敏感数据（§1 股价/市值, §2 52周范围, §11 周线价格, §14 无风险利率）：

```bash
python scripts/tushare_collector.py --code {code} --output {output_dir}/data_pack_market.md --refresh-market
```

若 data_pack_market.md 超过 7 天未更新，降级为全量采集（不加 --refresh-market）。

### Phase 3: 分析与报告

#### Step 3.1: 数据校验 + 穿透回报率计算

读取 `strategies/turtle/phase3_quantitative.md` 作为完整指令。

同时加载的参考文件：
- `strategies/turtle/references/judgment_examples_turtle.md` — 龟龟专属判断锚点
- `strategies/turtle/references/factor_interface.md` — 参数传递 schema
- `strategies/turtle/references/shared_tables.md` — 税率/门槛/公式

数据输入：
- `{output_dir}/data_pack_market.md`
- `{output_dir}/data_pack_report.md`（若存在）

输出：`{output_dir}/phase3_quantitative.md`

**条件加载**：
- 港股 (.HK) → 额外加载 `shared/qualitative/references/market_rules_hk.md`
- 美股 (.US) → 额外加载 `shared/qualitative/references/market_rules_us.md`
- A股 → 无额外加载

#### Step 3.2: 估值 + 报告组装

读取 `strategies/turtle/phase3_valuation.md` 作为完整指令。

输入文件：
- `{output_dir}/qualitative_report.md` — 定性参数（结构化参数表）
- `{output_dir}/phase3_quantitative.md` — Step 3.1 的输出
- `{output_dir}/data_pack_market.md` — 价格/市场数据

输出：`{output_dir}/{company}_{code}_分析报告.md`

---

## 错误处理

| 异常 | 处理方式 |
|------|---------|
| qualitative_report.md 不存在 | 停止，提示运行 business-analysis |
| data_pack_market.md 不存在 | 停止，提示运行 business-analysis |
| Tushare Token 无效 | 降级使用 yfinance fallback |
| Step A 刷新失败 | 检查 Python 环境，提示安装依赖 |
| 数据不完整 | 总是生成部分报告 |

---

## 文件路径约定

```
{workspace}/
├── scripts/                          ← Python 脚本（Bash 调用）
├── strategies/
│   └── turtle/                       ← 龟龟策略指令文件（只读）
│       ├── coordinator.md            ← 本文件的前身（v2 调度文档）
│       ├── phase3_quantitative.md    ← Step 3.1 指令
│       ├── phase3_valuation.md       ← Step 3.2 指令
│       └── references/               ← 参考数据
├── shared/
│   └── qualitative/                  ← 定性分析模块
├── output/
│   └── {code}_{company}/
│       ├── qualitative_report.md     ← 前置条件
│       ├── data_pack_market.md       ← 前置条件
│       ├── data_pack_report.md       ← 可选
│       ├── phase3_quantitative.md    ← Step 3.1 输出
│       └── {company}_{code}_分析报告.md ← 最终输出
└── .workbuddy/skills/
    └── turtle-investment/
        └── SKILL.md                  ← 本文件
```

---

## 使用示例

```
turtle-investment 600887
turtle-investment 00700.HK
turtle-investment AAPL
```

> 注意：在运行龟龟策略之前，必须先通过 `business-analysis` skill 完成定性分析和数据采集。
