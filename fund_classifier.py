# -*- coding: UTF-8 -*-
"""
基金分类模块 v1.0
第一步：对基金代码进行分类，获取基金基本信息
输入：funds_list.txt
输出：category.txt（标准化分类文件）
数据源：东方财富网/天天基金网
"""

import argparse
import json
import os
import re
import sys
import threading
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from datetime import datetime
from typing import Dict, List, Optional

import requests
import urllib3
from loguru import logger

urllib3.disable_warnings()


class FundClassifier:
    """基金分类器"""

    def __init__(self, max_workers: int = 4):
        self.session = requests.Session()
        self.fund_cache = {}
        self.max_workers = max_workers

    def read_fund_codes(self, file_path: str) -> List[str]:
        """从文件读取基金代码列表"""
        fund_codes = []

        if not os.path.exists(file_path):
            logger.error(f"基金代码文件不存在: {file_path}")
            return fund_codes

        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                for line in f:
                    line = line.strip()
                    if not line or line.startswith('#'):
                        continue
                    codes = re.findall(r'\d{6}', line)
                    fund_codes.extend(codes)

            seen = set()
            unique_codes = []
            for code in fund_codes:
                if code not in seen:
                    seen.add(code)
                    unique_codes.append(code)

            logger.info(f"从文件读取了 {len(unique_codes)} 个基金代码")
            return unique_codes

        except Exception as e:
            logger.error(f"读取基金代码文件失败: {e}")
            return []

    def get_fund_info_from_eastmoney(self, fund_code: str) -> Optional[Dict]:
        """从东方财富网获取基金基本信息"""
        try:
            url = f"http://fund.eastmoney.com/pingzhongdata/{fund_code}.js"
            headers = {
                "Referer": f"http://fund.eastmoney.com/{fund_code}.html",
                "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
            }

            response = self.session.get(url, headers=headers, timeout=10, verify=False)
            response.encoding = 'utf-8'

            name_match = re.search(r'var fS_name = "(.*?)"', response.text)
            fund_name = name_match.group(1) if name_match else f"基金{fund_code}"

            code_match = re.search(r'var fS_code = "(.*?)"', response.text)
            fund_code_actual = code_match.group(1) if code_match else fund_code

            # 判断基金类型
            fund_type = "普通型"
            if "QDII" in fund_name.upper():
                fund_type = "QDII型"
            elif "指数" in fund_name or "ETF" in fund_name.upper():
                fund_type = "指数型"
            elif "债券" in fund_name:
                fund_type = "债券型"
            elif "货币" in fund_name:
                fund_type = "货币型"

            return {
                "fund_code": fund_code_actual,
                "fund_name": fund_name,
                "fund_type": fund_type
            }

        except Exception as e:
            logger.error(f"从东方财富网获取基金{fund_code}信息失败: {e}")
            return None

    def analyze_fund(self, fund_code: str) -> Optional[Dict]:
        """分析单只基金"""
        fund_info = self.get_fund_info_from_eastmoney(fund_code)

        if not fund_info:
            return {
                "fund_code": fund_code,
                "fund_name": "未知",
                "fund_type": "未知型",
                "status": "failed",
                "error": "无法获取基金信息"
            }

        return {
            "fund_code": fund_code,
            "fund_name": fund_info["fund_name"],
            "fund_type": fund_info["fund_type"],
            "status": "success"
        }

    def analyze_all_funds(self, fund_codes: List[str]) -> List[Dict]:
        """批量分析多只基金（并行化）"""
        results = []
        result_lock = threading.Lock()

        def fetch_fund_data(code: str):
            result = self.analyze_fund(code)
            with result_lock:
                results.append(result)

        logger.info(f"开始并行分析 {len(fund_codes)} 只基金 (线程数: {self.max_workers})...")

        with ThreadPoolExecutor(max_workers=self.max_workers) as executor:
            futures = [executor.submit(fetch_fund_data, code) for code in fund_codes]
            for future in as_completed(futures):
                future.result()

        # 按原始顺序排序
        code_order = {code: i for i, code in enumerate(fund_codes)}
        results.sort(key=lambda x: code_order.get(x.get("fund_code", ""), 999))

        return results

    def generate_category_file(self, results: List[Dict], output_file: str = "category.txt"):
        """生成标准化的分类文件"""
        lines = []

        now = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        lines.append("# 基金分类配置文件")
        lines.append(f"# 生成时间: {now}")
        lines.append("#")
        lines.append("# 格式说明:")
        lines.append("# 每行一个基金，字段用 | 分隔")
        lines.append("# 字段: FUND|基金代码|基金名称|基金类型|状态")
        lines.append("")

        total = len(results)
        success = sum(1 for r in results if r['status'] == 'success')
        failed = total - success

        type_count = {}
        for r in results:
            t = r['fund_type']
            type_count[t] = type_count.get(t, 0) + 1

        lines.append("# ============ 统计概览 ============")
        lines.append(f"# 基金总数: {total}")
        lines.append(f"# 成功分析: {success}")
        lines.append(f"# 分析失败: {failed}")
        lines.append("# 类型分布:")
        for t, count in sorted(type_count.items(), key=lambda x: -x[1]):
            lines.append(f"#   {t}: {count}")
        lines.append("# ==================================")
        lines.append("")

        for r in results:
            line = f"FUND|{r['fund_code']}|{r['fund_name']}|{r['fund_type']}|{r['status']}"
            lines.append(line)
            lines.append("")

        with open(output_file, 'w', encoding='utf-8') as f:
            f.write('\n'.join(lines))

        logger.info(f"分类文件已生成: {output_file}")
        logger.info(f"  - 基金总数: {total}")
        logger.info(f"  - 成功分析: {success}")
        logger.info(f"  - 分析失败: {failed}")

        return output_file

    def print_summary(self, results: List[Dict]):
        """打印分析摘要"""
        print("\n" + "=" * 80)
        print("基金分类分析摘要")
        print("=" * 80)

        total = len(results)
        success = sum(1 for r in results if r['status'] == 'success')

        print(f"\n总计: {total} 只基金")
        print(f"成功: {success} 只")
        print(f"失败: {total - success} 只")

        type_count = {}
        for r in results:
            t = r['fund_type']
            type_count[t] = type_count.get(t, 0) + 1

        print("\n基金类型分布:")
        for t, count in sorted(type_count.items(), key=lambda x: -x[1]):
            pct = count / total * 100
            print(f"  {t}: {count} 只 ({pct:.1f}%)")

        failed_funds = [r for r in results if r['status'] == 'failed']
        if failed_funds:
            print("\n分析失败的基金:")
            for r in failed_funds:
                print(f"  {r['fund_code']}: {r.get('error', '未知错误')}")

        print("\n" + "=" * 80)


def main():
    """主函数"""
    parser = argparse.ArgumentParser(
        description="基金分类工具 - 第一步：分析基金并生成分类配置文件",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
使用示例:
  # 基本用法（从 funds_list.txt 读取，输出到 category.txt）
  python fund_classifier.py

  # 指定输入输出文件
  python fund_classifier.py -i funds_list.txt -o category.txt

  # 指定基金代码（逗号分隔）
  python fund_classifier.py --codes 017174,023537,513260
        """
    )

    parser.add_argument("-i", "--input", type=str, default="funds_list.txt",
                        help="输入基金代码文件路径 (默认: funds_list.txt)")
    parser.add_argument("-o", "--output", type=str, default="category.txt",
                        help="输出分类文件路径 (默认: category.txt)")
    parser.add_argument("--codes", type=str, help="直接指定基金代码，逗号分隔")
    parser.add_argument("--workers", type=int, default=4,
                        help="并行线程数 (默认: 4)")
    parser.add_argument("--verbose", action="store_true", help="显示详细日志")

    args = parser.parse_args()

    if args.verbose:
        logger.remove()
        logger.add(sys.stderr, level="DEBUG")

    classifier = FundClassifier(max_workers=args.workers)

    fund_codes = []

    if args.codes:
        fund_codes = [code.strip() for code in args.codes.split(",") if code.strip()]
        logger.info(f"从命令行参数获取了 {len(fund_codes)} 个基金代码")
    else:
        fund_codes = classifier.read_fund_codes(args.input)

    if not fund_codes:
        logger.error("没有有效的基金代码，程序退出")
        return

    logger.info(f"开始分析 {len(fund_codes)} 只基金...")
    results = classifier.analyze_all_funds(fund_codes)

    classifier.generate_category_file(results, args.output)
    classifier.print_summary(results)

    logger.info(f"\n分类完成！请查看 {args.output} 文件")


if __name__ == "__main__":
    main()
