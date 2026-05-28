# 年报 PDF 下载 (Download Annual Report) — WorkBuddy Skill

> 搜索并下载 A股/港股上市公司年报 PDF。
> 优先从巨潮资讯网（cninfo.com.cn）、雪球（stockn.xueqiu.com）、
> 同花顺（notice.10jqka.com.cn）搜索。

---

## 输入格式

```
download-annual-report <股票代码> [年份] [报告类型]
```

- **股票代码**（必需）：如 `600887`、`00700.HK`、`AAPL`
- **年份**（可选）：如 `2025`，默认搜索最新
- **报告类型**（可选）：`年报`（默认）、`中报`、`一季报`、`三季报`

---

## 执行流程

### Step 0: 解析输入

代码格式标准化：
- 6位数字以 `6` 开头 → 上海 A股（`SH600887`）
- 6位数字以 `0`/`3` 开头 → 深圳 A股（`SZ000001`）
- 1-5位数字 → 港股，补零到5位（`700` → `00700`）

### Step 1: 搜索 PDF

未指定年份时，计算最新财年 = 当前年份 − 1。

按优先级搜索（找到一个即停止）：

**Round 1 — 巨潮资讯网（官方平台，最可靠）：**
- 年报：`site:cninfo.com.cn {公司名} {年份} 年度报告`
- 中报：`site:cninfo.com.cn {公司名} {年份} 半年度报告`

**Round 2 — 雪球：**
- A股：`site:stockn.xueqiu.com {代码} 年度报告 {年份}`
- 港股：`site:stockn.xueqiu.com {代码} annual report {年份}`

**Round 3 — 同花顺：**
- `site:notice.10jqka.com.cn {公司名} {年份} 年度报告`

**Round 4 — 无限制搜索（最后手段）：**
- `{公司名} {代码} {年份} 年度报告 PDF`

### Step 2: 提取 PDF 链接

从搜索结果中筛选 PDF 链接：
- `https://static.cninfo.com.cn/*.pdf`
- `https://stockn.xueqiu.com/*.pdf`
- `https://notice.10jqka.com.cn/*.pdf`

### Step 3: 排除干扰项

排除含以下关键词的结果：
```
摘要, 审计报告, 公告, 利润分配, 可持续发展, 股东大会, ESG, summary, auditor
```

### Step 4: 下载 PDF

```bash
python scripts/download_report.py \
  --url "<PDF_URL>" \
  --stock-code "<代码>" \
  --report-type "<报告类型>" \
  --year "<年份>" \
  --save-dir "output/{code}_{company}/"
```

---

## 输出

下载成功 → 报告文件路径和大小
下载失败 → 错误信息和替代方案建议

---

## 使用示例

```
download-annual-report 600887
download-annual-report 00700.HK 2025
download-annual-report 600887 2025 中报
```
