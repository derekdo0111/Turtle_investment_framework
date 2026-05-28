# 估值分析 (Valuation Analysis) — WorkBuddy Skill

> 独立估值分析管线：Python 确定性计算 + LLM 定性调整。
> 由 WorkBuddy 工具链驱动，基于 DeepSeek V4 Flash API 推理。

---

## 输入格式

```
valuation <股票代码>
```

支持代码格式：
- A股：`600887`、`000858`、`300750` → 自动补全 `.SH` / `.SZ`
- 港股：`00700`、`00700.HK`
- 美股：`AAPL`、`AAPL.US`

---

## 前置条件检查

在执行前确认以下文件存在：

```
{output_dir} = output/{code}_{company}
```

- `{output_dir}/qualitative_report.md` — 必须
- `{output_dir}/data_pack_market.md` — 必须

若缺少，提示用户先运行 `business-analysis` skill。

---

## 执行管线

### Step 1: Python 估值计算

```bash
python scripts/valuation_engine.py --code {code} --output-dir output/{code}_{company}/
```

执行内容：
- 通过 Tushare 采集最新财务数据
- 计算公司分类（蓝筹价值/成长/混合型）
- 计算 WACC
- 执行多种估值方法：DCF（三情景）、DDM、PEG、PE Band、PS
- 输出 5×5 敏感性分析表
- 交叉验证各方法结果
- **输出**：`output/{code}_{company}/valuation_computed.md`

### Step 2: LLM 定性调整 + 报告生成

读取以下指令和参考文档：
- `strategies/valuation/phase2_valuation.md` — 定性调整指令
- `strategies/valuation/references/valuation_methods.md` — 方法论参考
- `strategies/valuation/references/report_template.md` — 报告模板
- `strategies/valuation/references/classification_rules.md` — 分类规则
- `strategies/valuation/references/valuation_examples.md` — 判断示例

输入文件：
- `output/{code}_{company}/qualitative_report.md` — 定性洞察（D1-D6 结构化参数）
- `output/{code}_{company}/valuation_computed.md` — Python 计算结果

定性调整映射规则：
| 定性维度 | 影响参数 |
|---------|---------|
| D1 收入质量 | 增长率（growth rate）调整 |
| D2 护城河 | 终端增长率（terminal growth）调整 |
| D3 周期位置 | 情景权重（scenario weights）调整 |
| D4 管理层 | 治理折扣（governance discount）调整 |

输出：`output/{code}_{company}/{company}_{code}_估值报告.md`

---

## 错误处理

| 异常 | 处理方式 |
|------|---------|
| qualitative_report.md 不存在 | 停止，提示先运行 business-analysis |
| valuation_engine.py 失败 | 检查 TUSHARE_TOKEN，重试 |
| 分类模糊 | Python 默认 "混合型" |
| 某估值方法失败 | Python 跳过该方法，权重重新分配 |
| 无结构化参数 | 跳过定性调整，使用 Python 默认值 |

---

## 使用示例

```
valuation 600887
valuation 00700.HK
valuation AAPL
```
