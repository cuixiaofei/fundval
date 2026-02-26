# -*- coding: UTF-8 -*-
"""
基金估值执行模块 v1.0
第二步：根据 category.txt 并行执行获取基金的实时估值
输入：category.txt
输出：outputs/ 文件夹中的估值结果和分析报告
"""

import argparse
import json
import os
import sys
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from datetime import datetime
from typing import Dict, List, Optional

from loguru import logger

from fund_valuation import FundValuation, generate_report


class CategoryParser:
    """分类文件解析器"""

    @staticmethod
    def parse(category_file: str) -> List[Dict]:
        """解析 category.txt 文件"""
        funds = []

        if not os.path.exists(category_file):
            logger.error(f"分类文件不存在: {category_file}")
            return funds

        try:
            with open(category_file, 'r', encoding='utf-8') as f:
                for line in f:
                    line = line.strip()
                    if not line or line.startswith('#'):
                        continue

                    parts = line.split('|')
                    if parts[0] == 'FUND' and len(parts) >= 5:
                        funds.append({
                            'fund_code': parts[1],
                            'fund_name': parts[2],
                            'fund_type': parts[3],
                            'status': parts[4]
                        })

            logger.info(f"从分类文件解析了 {len(funds)} 只基金")
            return funds

        except Exception as e:
            logger.error(f"解析分类文件失败: {e}")
            return []


class FundValuationRunner:
    """基金估值执行器"""

    def __init__(
        self,
        category_file: str = "category.txt",
        output_dir: str = "outputs",
        max_workers: int = 4
    ):
        self.category_file = category_file
        self.output_dir = output_dir
        self.max_workers = max_workers

        os.makedirs(output_dir, exist_ok=True)

        self.funds = CategoryParser.parse(category_file)

        self.valuation = FundValuation()

    def run_single(self, fund_info: Dict) -> Dict:
        """单线程执行单只基金估值"""
        return self.valuation.get_single_fund_data(fund_info['fund_code'])

    def run_parallel(self) -> List[Dict]:
        """并行执行所有基金估值"""
        logger.info(f"开始并行估值 {len(self.funds)} 只基金 (线程数: {self.max_workers})...")

        results = []

        with ThreadPoolExecutor(max_workers=self.max_workers) as executor:
            future_to_fund = {
                executor.submit(self.run_single, fund): fund 
                for fund in self.funds
            }

            for future in as_completed(future_to_fund):
                fund = future_to_fund[future]
                try:
                    result = future.result()
                    results.append(result)
                except Exception as e:
                    logger.error(f"基金 {fund['fund_code']} 估值失败: {e}")
                    results.append({
                        'fund_code': fund['fund_code'],
                        'fund_name': '获取失败',
                        'status': 'failed',
                        'error': str(e),
                        'update_time': datetime.now().strftime('%Y-%m-%d %H:%M:%S')
                    })

        # 按基金代码排序
        code_order = {fund['fund_code']: i for i, fund in enumerate(self.funds)}
        results.sort(key=lambda x: code_order.get(x.get('fund_code', ''), 999))

        return results

    def run_sequential(self) -> List[Dict]:
        """串行执行所有基金估值"""
        logger.info(f"开始串行估值 {len(self.funds)} 只基金...")

        results = []
        for i, fund in enumerate(self.funds, 1):
            logger.info(f"[{i}/{len(self.funds)}] 估值基金 {fund['fund_code']}...")
            result = self.run_single(fund)
            results.append(result)
            time.sleep(0.2)

        return results

    def save_reports(self, results: List[Dict]):
        """保存各种格式的报告"""
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')

        # 1. 文本报告
        text_report = generate_report(results)
        text_file = os.path.join(self.output_dir, f"fund_valuation_{timestamp}.txt")
        with open(text_file, 'w', encoding='utf-8') as f:
            f.write(text_report)
        logger.info(f"文本报告已保存: {text_file}")

        # 2. JSON报告
        json_report = {
            'generated_at': datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
            'summary': {
                'total_funds': len(results),
                'valid_estimates': sum(1 for r in results if r and r.get('fund_name') != '获取失败'),
            },
            'funds': results
        }
        json_file = os.path.join(self.output_dir, f"fund_valuation_{timestamp}.json")
        with open(json_file, 'w', encoding='utf-8') as f:
            json.dump(json_report, ensure_ascii=False, indent=2, fp=f)
        logger.info(f"JSON报告已保存: {json_file}")

        # 3. CSV报告
        lines = ['基金代码,基金名称,净值,日涨幅,估值,估值涨幅,更新时间']
        for r in results:
            if r:
                line = f"{r.get('fund_code','')},{r.get('fund_name','')},{r.get('net_value','N/A')},{r.get('day_of_growth','N/A')},{r.get('forecast_net_value',0)},{r.get('forecast_growth',0):.2f}%,{r.get('update_time','')}"
                lines.append(line)
        csv_file = os.path.join(self.output_dir, f"fund_valuation_{timestamp}.csv")
        with open(csv_file, 'w', encoding='utf-8') as f:
            f.write('\n'.join(lines))
        logger.info(f"CSV报告已保存: {csv_file}")

        # 4. 最新报告
        latest_text = os.path.join(self.output_dir, "fund_valuation_latest.txt")
        with open(latest_text, 'w', encoding='utf-8') as f:
            f.write(text_report)

        return {
            'text': text_file,
            'json': json_file,
            'csv': csv_file,
            'latest': latest_text
        }

    def print_summary(self, results: List[Dict]):
        """打印估值摘要"""
        print("\n" + "=" * 80)
        print("基金估值执行摘要")
        print("=" * 80)

        total = len(results)
        success = sum(1 for r in results if r and r.get('fund_name') != '获取失败')
        failed = total - success

        print(f"\n总计: {total} 只基金")
        print(f"成功: {success} 只")
        print(f"失败: {failed} 只")

        if success > 0:
            valid_results = [r for r in results if r and r.get('fund_name') != '获取失败']

            valid_growths = [r.get('forecast_growth', 0) for r in valid_results 
                           if isinstance(r.get('forecast_growth'), (int, float))]

            if valid_growths:
                avg_growth = sum(valid_growths) / len(valid_growths)
                print(f"\n平均估值涨幅: {avg_growth:+.2f}%")

                rise = sum(1 for g in valid_growths if g > 0)
                fall = sum(1 for g in valid_growths if g < 0)
                flat = sum(1 for g in valid_growths if g == 0)

                print(f"涨跌分布: 涨{rise} 跌{fall} 平{flat}")

                print("\n涨幅前五:")
                sorted_results = sorted(valid_results, key=lambda x: x.get('forecast_growth', 0), reverse=True)
                for r in sorted_results[:5]:
                    print(f"  {r['fund_code']} {r['fund_name']}:        {r.get('forecast_growth', 0):+.2f}%")

                print("\n跌幅前五:")
                for r in sorted_results[-5:]:
                    print(f"  {r['fund_code']} {r['fund_name']}:        {r.get('forecast_growth', 0):+.2f}%")

        failed_funds = [r for r in results if r and r.get('fund_name') == '获取失败']
        if failed_funds:
            print("\n估值失败的基金:")
            for r in failed_funds:
                print(f"  {r['fund_code']}: {r.get('error', '未知错误')}")

        print("\n" + "=" * 80)


def main():
    """主函数"""
    parser = argparse.ArgumentParser(
        description="基金估值执行工具 - 第二步：根据分类文件执行实时估值",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
使用示例:
  # 基本用法（从 category.txt 读取，输出到 outputs/）
  python fund_valuation_runner.py

  # 指定输入输出
  python fund_valuation_runner.py -i category.txt -o outputs/

  # 串行执行（不使用并行）
  python fund_valuation_runner.py --sequential

  # 指定并行线程数
  python fund_valuation_runner.py --workers 3

  # 监控模式（定时刷新）
  python fund_valuation_runner.py --monitor -t 60
        """
    )

    parser.add_argument("-i", "--input", type=str, default="category.txt",
                        help="输入分类文件路径 (默认: category.txt)")
    parser.add_argument("-o", "--output", type=str, default="outputs",
                        help="输出目录路径 (默认: outputs)")
    parser.add_argument("--sequential", action="store_true",
                        help="串行执行（不使用并行）")
    parser.add_argument("--workers", type=int, default=4,
                        help="并行线程数 (默认: 4)")
    parser.add_argument("--monitor", action="store_true",
                        help="监控模式（定时刷新）")
    parser.add_argument("-t", "--interval", type=int, default=60,
                        help="监控模式刷新间隔秒数 (默认: 60)")

    args = parser.parse_args()

    runner = FundValuationRunner(
        category_file=args.input,
        output_dir=args.output,
        max_workers=args.workers
    )

    if not runner.funds:
        logger.error("没有可估值的基金，程序退出")
        return

    def run_once():
        """执行单次估值"""
        if args.sequential:
            results = runner.run_sequential()
        else:
            results = runner.run_parallel()

        report_files = runner.save_reports(results)
        runner.print_summary(results)

        logger.info("")
        logger.info(f"估值完成！请查看报告，已保存到 {args.output} 目录")

    if args.monitor:
        logger.info(f"启动监控模式，刷新间隔: {args.interval}秒")
        logger.info("按 Ctrl+C 停止监控")

        try:
            while True:
                run_once()
                logger.info(f"\n等待 {args.interval} 秒后下次刷新...")
                time.sleep(args.interval)
        except KeyboardInterrupt:
            logger.info("\n监控已停止")
    else:
        run_once()


if __name__ == "__main__":
    main()
