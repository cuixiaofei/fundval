# 场外基金实时估值监控 v1.0

基于**两步式架构**的基金实时估值系统，数据源使用天天基金网（主）+ 东方财富网（备用）。

## 核心架构

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         基金实时估值系统 v1.0                            │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  ┌──────────────────┐         ┌──────────────────┐         ┌──────────┐ │
│  │  funds_list.txt  │ ──────> │   category.txt   │ ──────> │ outputs/ │ │
│  │  (基金代码列表)   │  第一步 │  (分类配置文件)   │  第二步 │ (估值结果)│ │
│  └──────────────────┘         └──────────────────┘         └──────────┘ │
│         │                            │                          │       │
│         ▼                            ▼                          ▼       │
│  ┌──────────────────┐         ┌──────────────────┐         ┌──────────┐ │
│  │ fund_classifier  │         │fund_valuation_   │         │  多格式  │ │
│  │    .py           │         │    runner.py     │         │  报告   │ │
│  │  (基金分类器)     │         │  (估值执行器)     │         │         │ │
│  └──────────────────┘         └──────────────────┘         └──────────┘ │
│                                                                          │
│  数据源: 天天基金网(主) + 东方财富网(备用)                                  │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

## 项目结构

```
.
├── fund_valuation.py           # 核心估值模块（数据源接口）
├── fund_monitor.py             # 监控程序（一键模式）
├── fund_classifier.py          # 第一步：基金分类模块
├── fund_valuation_runner.py    # 第二步：估值执行模块
├── requirements.txt            # 依赖包
├── README.md                   # 说明文档
└── funds_list.txt              # 基金代码列表（输入）
```

## 安装依赖

```bash
pip install -r requirements.txt
```

## 使用方法

### 方式一：两步式工作流（推荐）

**第一步：基金分类**

```bash
python fund_classifier.py -i funds_list.txt -o category.txt
```

这一步会：
- 获取每只基金的基本信息（名称、类型）
- 判断基金类型（普通型、QDII型、指数型、债券型、货币型）
- 生成标准化的 `category.txt` 配置文件

**第二步：执行估值**

```bash
python fund_valuation_runner.py -i category.txt -o outputs/
```

这一步会：
- 根据分类文件并行获取基金实时估值
- 生成文本/JSON/CSV三种格式的报告

### 方式二：一键监控模式

```bash
# 基本用法
python fund_monitor.py -f funds_list.txt

# 自定义输出文件和刷新间隔
python fund_monitor.py -f funds.txt -o result.txt -i 30

# 单次执行模式
python fund_monitor.py -f funds.txt --once
```

## 参数说明

### fund_classifier.py 参数

| 参数 | 说明 | 默认值 |
|------|------|--------|
| `-i, --input` | 输入基金代码文件 | funds_list.txt |
| `-o, --output` | 输出分类文件 | category.txt |
| `--codes` | 直接指定基金代码 | - |
| `--verbose` | 显示详细日志 | False |

### fund_valuation_runner.py 参数

| 参数 | 说明 | 默认值 |
|------|------|--------|
| `-i, --input` | 输入分类文件 | category.txt |
| `-o, --output` | 输出目录 | outputs |
| `--sequential` | 串行执行 | False |
| `--workers` | 并行线程数 | 10 |
| `--monitor` | 监控模式 | False |
| `-t, --interval` | 刷新间隔（秒） | 60 |

### fund_monitor.py 参数

| 参数 | 说明 | 默认值 |
|------|------|--------|
| `-f, --fund-file` | 基金代码文件 | funds_list.txt |
| `-o, --output` | 输出文件 | fund_valuation_result.txt |
| `-i, --interval` | 刷新间隔（秒） | 60 |
| `--once` | 只执行一次 | False |

## 数据源

| 数据源 | 用途 | 优先级 |
|--------|------|--------|
| 天天基金网 (fund123.cn) | 基金信息、估值数据 | 主数据源 |
| 东方财富网 (fund.eastmoney.com) | 基金信息、估值数据 | 备用数据源 |

## 输出示例

```
======================================================================
  场外基金实时估值
  更新时间: 2026-02-25 15:30:25
======================================================================

【统计信息】
  基金总数: 8
  QDII基金: 2
  有效估值: 8
  获取失败: 0
  平均估值涨幅: +0.85%

【涨跌分布】
  上涨: 5  下跌: 2  持平: 1

【基金详情】
----------------------------------------------------------------------

[1] [017174] 招商中证白酒指数C
  净值: 1.2345 (2026-02-24)
  日涨幅: +1.20%
  估值: 1.2537 (15:30)
  估值涨幅: +1.56%

...

======================================================================
数据来源: 东方财富网/天天基金网
======================================================================
```

## 完整工作流示例

```bash
# 1. 准备基金代码列表
cat > funds_list.txt << 'EOF'
# 我的基金列表
017174
023537
019449
513260
016533
EOF

# 2. 第一步：基金分类
python fund_classifier.py -i funds_list.txt -o category.txt

# 3. 第二步：执行估值
python fund_valuation_runner.py -i category.txt -o outputs/

# 4. 查看结果
cat outputs/fund_valuation_latest.txt
```

## 输出文件

第二步会在 `outputs/` 目录生成：
- `fund_valuation_latest.txt` - 最新估值报告
- `fund_valuation_YYYYMMDD_HHMMSS.txt` - 历史文本报告
- `fund_valuation_YYYYMMDD_HHMMSS.json` - JSON格式数据
- `fund_valuation_YYYYMMDD_HHMMSS.csv` - CSV格式表格

## 常见问题

### Q: 为什么某些基金获取失败？

A: 可能原因：
- 基金代码错误或基金不存在
- 网络连接问题
- 数据源暂时不可用

**解决方案：** 检查基金代码，稍后重试。

### Q: QDII基金支持如何？

A: QDII基金完全支持，程序会自动识别基金名称中的"QDII"标记。

### Q: 监控模式如何使用？

A: 使用 `--monitor` 参数：
```bash
python fund_valuation_runner.py --monitor -t 60
```
程序会每60秒自动刷新一次估值结果，按 `Ctrl+C` 停止。

## 许可证

## License

This project is licensed under the GNU General Public License v3.0 (GPL-3.0).  
See the [LICENSE](LICENSE) file for details.

SPDX-License-Identifier: GPL-3.0-or-later
