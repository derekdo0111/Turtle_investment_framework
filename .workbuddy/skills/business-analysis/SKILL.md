# 商业模式与护城河定性分析 (Business Analysis) — WorkBuddy Skill

> 完整执行 6 维度定性分析管线，输出定性评估报告和结构化参数。
> 此 Skill 由 WorkBuddy 工具链驱动，数据采集用 Bash 调 Python 脚本，分析用 LLM 推理。

---

## 输入格式

```
business-analysis <股票代码>
```

支持代码格式：
- A股：`600887`、`000858`、`300750` → 自动补全 `.SH` / `.SZ`
- 港股：`00700`、`00700.HK`
- 美股：`AAPL`、`AAPL.US`

---

## 执行管线

### Step 1: 数据采集（并行）

#### 1A: Tushare 结构化数据采集

```bash
mkdir -p output/{code}_{company}
python scripts/tushare_collector.py --code {code} --output output/{code}_{company}/data_pack_market.md
```

#### 1B: 年报 PDF 获取

1. 确定最新财年 = 当前年份 − 1
2. 检查 `output/{code}_{company}/` 下是否已有 PDF（glob 匹配 `*{latest_fiscal_year}*年报*.pdf` 或 `*年度报告*.pdf`）
3. 若有 → 直接使用；若无 → 使用 `download-annual-report` skill 下载
4. 使用 Read 工具读取 PDF：先读目录（前5页），再按优先级读关键章节

#### 1C: WebSearch 补充（仅 PDF 下载失败时）

使用 WebSearch 工具查找年报信息，追加到 data_pack_market.md 中。

#### 1D: PDF 附注提取（有 PDF 时执行）

读取 `strategies/turtle/phase2_PDF解析.md` 提取格式规范。
提取章节：P2(受限货币资金)、P3(应收账款账龄)、P4(关联交易)、P6(或有负债)、P13(非经常性损益)、SUB(子公司)

输出：`output/{code}_{company}/data_pack_report.md`（供龟龟策略使用）

### Step 2: 6维度定性分析（单 Agent）

读取 `shared/qualitative/qualitative_assessment_v2.md` 作为完整分析框架。

同时加载的参考文件：
- `shared/qualitative/references/judgment_examples.md` — 判断锚点
- `shared/qualitative/references/framework_guide.md` — 框架定义
- `shared/qualitative/agents/writing_style.md` — 写作风格
- `shared/qualitative/references/output_schema.md` — 结构化参数 schema

条件加载：
- 港股 → `shared/qualitative/references/market_rules_hk.md`
- 美股 → `shared/qualitative/references/market_rules_us.md`

数据输入：
- `output/{code}_{company}/data_pack_market.md`
- PDF 年报内容（已读取到上下文中）

输出：`output/{code}_{company}/qualitative_report.md`
- 包含：执行摘要 + 6维度 + 交叉验证 + 深度结论 + 结构化参数表

### Step 3: HTML 报告生成（可选，仅用户要求时）

```bash
python scripts/report_to_html.py --input output/{code}_{company}/qualitative_report.md --output output/{code}_{company}/qualitative_report.html --standalone
```

---

## 6 个分析维度

1. 商业模式与资本特征
2. 竞争优势与护城河
3. 外部环境
4. 管理层与治理
5. MD&A 解读
6. 控股结构分析（条件执行）

---

## 错误处理

| 异常 | 处理方式 |
|------|---------|
| PDF 下载失败 | 降级到 WebSearch 补充 |
| PDF 为扫描件 | 使用 `python scripts/pdf_preprocessor.py` 处理 |
| Tushare 失败 | 使用 yfinance fallback |
| PDF 与 Tushare 数据冲突 | 以 PDF 为准，标注差异 |
| 数据不完整 | 标注 "⚠️ 数据不可用"，降级该维度分析 |

---

## 文件输出约定

```
output/{code}_{company}/
├── data_pack_market.md      ← Tushare 数据包（Step 1A）
├── data_pack_report.md      ← PDF 附注数据（Step 1D，可选）
├── qualitative_report.md    ← 6维度定性分析报告（Step 2）
└── qualitative_report.html  ← HTML 仪表盘（Step 3，可选）
```

---

## 使用示例

```
business-analysis 600887
business-analysis 00700.HK
business-analysis AAPL
```
