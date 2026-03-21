# 场外基金实时估值监控 v1.0 | Off-site Fund Real-time Valuation Monitor v1.0

基于**两步式架构**的基金实时估值系统，数据源使用天天基金网（主）+ 东方财富网（备用）。 | A fund real-time valuation system based on a **two-step architecture**, using East Money (primary) + Orient Securities (backup) as data sources.

## 核心架构 | Core Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         基金实时估值系统 v1.0                            │
│                    Fund Real-time Valuation System v1.0                  │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  ┌──────────────────┐         ┌──────────────────┐         ┌──────────┐ │
│  │  funds_list.txt  │ ──────> │   category.txt   │ ──────> │ outputs/ │ │
│  │  (基金代码列表)   │  第一步 │  (分类配置文件)   │  第二步 │ (估值结果)│ │
│  │  (Fund Codes)    │  Step 1 │  (Category File) │  Step 2 │ (Results)│ │
│  └──────────────────┘         └──────────────────┘         └──────────┘ │
│         │                            │                          │       │
│         ▼                            ▼                          ▼       │
│  ┌──────────────────┐         ┌──────────────────┐         ┌──────────┐ │
│  │ fund_classifier  │         │fund_valuation_   │         │  多格式  │ │
│  │    .py           │         │    runner.py     │         │  报告   │ │
│  │  (基金分类器)     │         │  (估值执行器)     │         │         │ │
│  │  (Classifier)    │         │  (Runner)        │         │  Multi-  │ │
│  │                  │         │                  │         │  format  │ │
│  └──────────────────┘         └──────────────────┘         └──────────┘ │
│                                                                          │
│  数据源: 天天基金网(主) + 东方财富网(备用)                                  │
│  Data Sources: East Money (Primary) + Orient Securities (Backup)           │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

## 项目结构 | Project Structure

```
.                                   | .
├── fund_valuation.py               | ├── fund_valuation.py
│   核心估值模块（数据源接口）        | │   Core Valuation Module (Data Source Interface)
├── fund_monitor.py                 | ├── fund_monitor.py
│   监控程序（一键模式）              | │   Monitor Program (One-click Mode)
├── fund_classifier.py              | ├── fund_classifier.py
│   第一步：基金分类模块              | │   Step 1: Fund Classification Module
├── fund_valuation_runner.py        | ├── fund_valuation_runner.py
│   第二步：估值执行模块              | │   Step 2: Valuation Execution Module
├── requirements.txt                | ├── requirements.txt
│   依赖包                          | │   Dependencies
├── README.md                       | ├── README.md
│   说明文档                        | │   Documentation
└── funds_list.txt                  | └── funds_list.txt
    基金代码列表（输入）              |     Fund Code List (Input)
```

## 安装依赖 | Install Dependencies

```bash
pip install -r requirements.txt     | pip install -r requirements.txt
```

## 使用方法 | Usage

### 方式一：两步式工作流（推荐） | Method 1: Two-Step Workflow (Recommended)

**第一步：基金分类** | **Step 1: Fund Classification**

```bash
python fund_classifier.py -i funds_list.txt -o category.txt
```
这一步会： | This step will:
- 获取每只基金的基本信息（名称、类型） | - Fetch basic information for each fund (name, type)
- 判断基金类型（普通型、QDII型、指数型、债券型、货币型） | - Determine fund type (General, QDII, Index, Bond, Money Market)
- 生成标准化的 `category.txt` 配置文件 | - Generate standardized `category.txt` configuration file

**第二步：执行估值** | **Step 2: Execute Valuation**

```bash
python fund_valuation_runner.py -i category.txt -o outputs/
```
这一步会： | This step will:
- 根据分类文件并行获取基金实时估值 | - Fetch real-time fund valuations in parallel based on category file
- 生成文本/JSON/CSV三种格式的报告 | - Generate reports in three formats: Text/JSON/CSV

### 方式二：一键监控模式 | Method 2: One-Click Monitor Mode

```bash
# 基本用法                          | # Basic Usage
python fund_monitor.py -f funds_list.txt

# 自定义输出文件和刷新间隔            | # Custom Output File and Refresh Interval
python fund_monitor.py -f funds.txt -o result.txt -i 30

# 单次执行模式                      | # One-time Execution Mode
python fund_monitor.py -f funds.txt --once
```

## 参数说明 | Parameter Reference

### fund_classifier.py 参数 | fund_classifier.py Parameters

| 参数 | 说明 | 默认值 | | Parameter | Description | Default |
|------|------|--------|-|-----------|-------------|---------|
| `-i, --input` | 输入基金代码文件 | funds_list.txt | | `-i, --input` | Input fund code file | funds_list.txt |
| `-o, --output` | 输出分类文件 | category.txt | | `-o, --output` | Output category file | category.txt |
| `--codes` | 直接指定基金代码 | - | | `--codes` | Specify fund codes directly | - |
| `--verbose` | 显示详细日志 | False | | `--verbose` | Show detailed logs | False |

### fund_valuation_runner.py 参数 | fund_valuation_runner.py Parameters

| 参数 | 说明 | 默认值 | | Parameter | Description | Default |
|------|------|--------|-|-----------|-------------|---------|
| `-i, --input` | 输入分类文件 | category.txt | | `-i, --input` | Input category file | category.txt |
| `-o, --output` | 输出目录 | outputs | | `-o, --output` | Output directory | outputs |
| `--sequential` | 串行执行 | False | | `--sequential` | Sequential execution | False |
| `--workers` | 并行线程数 | 10 | | `--workers` | Parallel worker threads | 10 |
| `--monitor` | 监控模式 | False | | `--monitor` | Monitor mode | False |
| `-t, --interval` | 刷新间隔（秒） | 60 | | `-t, --interval` | Refresh interval (seconds) | 60 |

### fund_monitor.py 参数 | fund_monitor.py Parameters

| 参数 | 说明 | 默认值 | | Parameter | Description | Default |
|------|------|--------|-|-----------|-------------|---------|
| `-f, --fund-file` | 基金代码文件 | funds_list.txt | | `-f, --fund-file` | Fund code file | funds_list.txt |
| `-o, --output` | 输出文件 | fund_valuation_result.txt | | `-o, --output` | Output file | fund_valuation_result.txt |
| `-i, --interval` | 刷新间隔（秒） | 60 | | `-i, --interval` | Refresh interval (seconds) | 60 |
| `--once` | 只执行一次 | False | | `--once` | Execute once only | False |

## 数据源 | Data Sources

| 数据源 | 用途 | 优先级 | | Data Source | Purpose | Priority |
|--------|------|--------|-|-------------|---------|----------|
| 天天基金网 (fund123.cn) | 基金信息、估值数据 | 主数据源 | | East Money (fund123.cn) | Fund info, valuation data | Primary |
| 东方财富网 (fund.eastmoney.com) | 基金信息、估值数据 | 备用数据源 | | Orient Securities (fund.eastmoney.com) | Fund info, valuation data | Backup |

## 输出示例 | Output Example

```
======================================================================
  场外基金实时估值                      | Off-site Fund Real-time Valuation
  更新时间: 2026-02-25 15:30:25        | Update Time: 2026-02-25 15:30:25
======================================================================

【统计信息】                            | [Statistics]
  基金总数: 8                           |   Total Funds: 8
  QDII基金: 2                           |   QDII Funds: 2
  有效估值: 8                           |   Valid Valuations: 8
  获取失败: 0                           |   Failed: 0
  平均估值涨幅: +0.85%                  |   Avg. Valuation Change: +0.85%

【涨跌分布】                            | [Rise/Fall Distribution]
  上涨: 5  下跌: 2  持平: 1             |   Up: 5  Down: 2  Flat: 1

【基金详情】                            | [Fund Details]
----------------------------------------------------------------------

[1] [017174] 招商中证白酒指数C         | [1] [017174] China Merchants CSI Liquor Index C
  净值: 1.2345 (2026-02-24)            |   NAV: 1.2345 (2026-02-24)
  日涨幅: +1.20%                        |   Daily Change: +1.20%
  估值: 1.2537 (15:30)                  |   Valuation: 1.2537 (15:30)
  估值涨幅: +1.56%                      |   Valuation Change: +1.56%

...

======================================================================
数据来源: 东方财富网/天天基金网          | Data Source: Orient Securities/East Money
======================================================================
```

## 完整工作流示例 | Complete Workflow Example

```bash
# 1. 准备基金代码列表                  | # 1. Prepare Fund Code List
cat > funds_list.txt << 'EOF'
# 我的基金列表                        | # My Fund List
017174
023537
019449
513260
016533
EOF

# 2. 第一步：基金分类                  | # 2. Step 1: Fund Classification
python fund_classifier.py -i funds_list.txt -o category.txt

# 3. 第二步：执行估值                  | # 3. Step 2: Execute Valuation
python fund_valuation_runner.py -i category.txt -o outputs/

# 4. 查看结果                          | # 4. View Results
cat outputs/fund_valuation_latest.txt
```

## 输出文件 | Output Files

第二步会在 `outputs/` 目录生成： | Step 2 generates in the `outputs/` directory:
- `fund_valuation_latest.txt` - 最新估值报告 | - `fund_valuation_latest.txt` - Latest valuation report
- `fund_valuation_YYYYMMDD_HHMMSS.txt` - 历史文本报告 | - `fund_valuation_YYYYMMDD_HHMMSS.txt` - Historical text report
- `fund_valuation_YYYYMMDD_HHMMSS.json` - JSON格式数据 | - `fund_valuation_YYYYMMDD_HHMMSS.json` - JSON format data
- `fund_valuation_YYYYMMDD_HHMMSS.csv` - CSV格式表格 | - `fund_valuation_YYYYMMDD_HHMMSS.csv` - CSV format table

## 常见问题 | FAQ

### Q: 为什么某些基金获取失败？ | Q: Why do some funds fail to fetch?

A: 可能原因： | A: Possible reasons:
- 基金代码错误或基金不存在 | - Incorrect fund code or fund does not exist
- 网络连接问题 | - Network connection issues
- 数据源暂时不可用 | - Data source temporarily unavailable

**解决方案：** 检查基金代码，稍后重试。 | **Solution:** Check fund codes and retry later.

### Q: QDII基金支持如何？ | Q: How is QDII fund support?

A: QDII基金完全支持，程序会自动识别基金名称中的"QDII"标记。 | A: QDII funds are fully supported; the program automatically identifies "QDII" markers in fund names.

### Q: 监控模式如何使用？ | Q: How to use monitor mode?

A: 使用 `--monitor` 参数： | A: Use the `--monitor` parameter:
```bash
python fund_valuation_runner.py --monitor -t 60
```
程序会每60秒自动刷新一次估值结果，按 `Ctrl+C` 停止。 | The program automatically refreshes valuation results every 60 seconds; press `Ctrl+C` to stop.

## 许可证 | License

This project is licensed under the GNU General Public License v3.0 (GPL-3.0).  
本项目采用 GNU 通用公共许可证 v3.0 (GPL-3.0) 授权。  
See the [LICENSE](LICENSE) file for details. | 详见 [LICENSE](LICENSE) 文件。

SPDX-License-Identifier: GPL-3.0-or-later
