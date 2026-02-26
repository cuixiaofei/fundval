# -*- coding: UTF-8 -*-
"""
场外基金实时估值监控程序 v1.0
定时刷新基金估值数据并保存到文件
"""

import argparse
import datetime
import os
import sys
import threading
import time
from typing import List

from loguru import logger

from fund_valuation import FundValuation, generate_report, read_fund_codes_from_file


class FundMonitor:
    """基金估值监控器"""

    def __init__(
        self,
        fund_codes: List[str],
        output_file: str = "fund_valuation_result.txt",
        interval: int = 60,
        max_retries: int = 3
    ):
        """
        初始化监控器

        Args:
            fund_codes: 要监控的基金代码列表
            output_file: 输出文件路径
            interval: 刷新间隔（秒），默认60秒
            max_retries: 最大重试次数
        """
        self.fund_codes = fund_codes
        self.output_file = output_file
        self.interval = interval
        self.max_retries = max_retries

        self.fund_valuation = FundValuation()
        self.is_running = False
        self.monitor_thread = None
        self.last_update_time = None
        self.update_count = 0

        self.stats = {
            "total_updates": 0,
            "successful_updates": 0,
            "failed_updates": 0,
            "start_time": None
        }

    def fetch_and_save(self) -> bool:
        """
        获取基金数据并保存到文件

        Returns:
            是否成功
        """
        try:
            logger.info(f"正在获取 {len(self.fund_codes)} 个基金的数据...")

            funds_data = self.fund_valuation.get_multiple_funds_data(self.fund_codes)

            if not funds_data:
                logger.warning("未获取到任何基金数据")
                return False

            report = generate_report(funds_data)

            with open(self.output_file, 'w', encoding='utf-8') as f:
                f.write(report)

            self.last_update_time = datetime.datetime.now()
            self.update_count += 1
            self.stats["successful_updates"] += 1

            logger.info(f"数据已保存到: {self.output_file}")
            logger.info(f"本次更新基金数: {len(funds_data)}")

            return True

        except Exception as e:
            logger.error(f"获取或保存数据失败: {e}")
            self.stats["failed_updates"] += 1
            return False

    def monitor_loop(self):
        """监控主循环"""
        logger.info("=" * 60)
        logger.info("场外基金实时估值监控已启动")
        logger.info(f"监控基金数: {len(self.fund_codes)}")
        logger.info(f"刷新间隔: {self.interval} 秒")
        logger.info(f"输出文件: {self.output_file}")
        logger.info("=" * 60)

        self.fetch_and_save()

        while self.is_running:
            next_run = time.time() + self.interval

            while self.is_running and time.time() < next_run:
                time.sleep(1)

            if not self.is_running:
                break

            self.stats["total_updates"] += 1

            for attempt in range(self.max_retries):
                if self.fetch_and_save():
                    break
                else:
                    if attempt < self.max_retries - 1:
                        logger.warning(f"第 {attempt + 1} 次尝试失败，{5 * (attempt + 1)} 秒后重试...")
                        time.sleep(5 * (attempt + 1))
                    else:
                        logger.error(f"已达到最大重试次数 ({self.max_retries})，跳过本次更新")

    def start(self):
        """启动监控"""
        if self.is_running:
            logger.warning("监控已在运行中")
            return

        self.is_running = True
        self.stats["start_time"] = datetime.datetime.now()

        self.monitor_thread = threading.Thread(target=self.monitor_loop)
        self.monitor_thread.daemon = True
        self.monitor_thread.start()

        logger.info("监控线程已启动")

    def stop(self):
        """停止监控"""
        if not self.is_running:
            logger.warning("监控未在运行")
            return

        self.is_running = False

        if self.monitor_thread and self.monitor_thread.is_alive():
            self.monitor_thread.join(timeout=5)

        self.print_stats()

        logger.info("监控已停止")

    def print_stats(self):
        """打印统计信息"""
        if self.stats["start_time"]:
            duration = datetime.datetime.now() - self.stats["start_time"]
            logger.info("=" * 60)
            logger.info("监控统计信息")
            logger.info("=" * 60)
            logger.info(f"运行时长: {duration}")
            logger.info(f"总更新次数: {self.stats['total_updates']}")
            logger.info(f"成功更新: {self.stats['successful_updates']}")
            logger.info(f"失败更新: {self.stats['failed_updates']}")
            if self.stats['total_updates'] > 0:
                success_rate = (self.stats['successful_updates'] / self.stats['total_updates']) * 100
                logger.info(f"成功率: {success_rate:.2f}%")
            logger.info("=" * 60)

    def run_once(self) -> bool:
        """
        执行单次更新

        Returns:
            是否成功
        """
        return self.fetch_and_save()


def create_sample_fund_file(file_path: str):
    """创建示例基金代码文件"""
    sample_content = """# 场外基金代码列表
# 每行一个基金代码，支持注释行（以#开头）
# 支持混合普通基金和QDII基金

# 普通基金示例
017174
023537
019449
000628
009226
025196

# QDII基金示例
513260
016533
"""

    try:
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(sample_content)
        logger.info(f"已创建示例基金代码文件: {file_path}")
        return True
    except Exception as e:
        logger.error(f"创建示例文件失败: {e}")
        return False


def main():
    """主函数"""
    parser = argparse.ArgumentParser(
        description="场外基金实时估值监控程序",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
使用示例:
  python fund_monitor.py -f funds_list.txt          # 使用默认配置运行
  python fund_monitor.py -f funds.txt -o result.txt -i 30  # 自定义输出文件和刷新间隔
  python fund_monitor.py -f funds.txt --once        # 只执行一次
  python fund_monitor.py --create-sample            # 创建示例基金代码文件
        """
    )

    parser.add_argument(
        "-f", "--fund-file",
        type=str,
        default="funds_list.txt",
        help="基金代码文件路径 (默认: funds_list.txt)"
    )

    parser.add_argument(
        "-o", "--output",
        type=str,
        default="fund_valuation_result.txt",
        help="输出文件路径 (默认: fund_valuation_result.txt)"
    )

    parser.add_argument(
        "-i", "--interval",
        type=int,
        default=60,
        help="刷新间隔秒数 (默认: 60)"
    )

    parser.add_argument(
        "--once",
        action="store_true",
        help="只执行一次，不进入循环监控模式"
    )

    parser.add_argument(
        "--create-sample",
        action="store_true",
        help="创建示例基金代码文件并退出"
    )

    parser.add_argument(
        "--codes",
        type=str,
        help="直接指定基金代码，逗号分隔（如: 017174,023537,513260）"
    )

    args = parser.parse_args()

    if args.create_sample:
        create_sample_fund_file("funds_list.txt")
        return

    fund_codes = []

    if args.codes:
        fund_codes = [code.strip() for code in args.codes.split(",") if code.strip()]
        logger.info(f"从命令行参数获取了 {len(fund_codes)} 个基金代码")
    elif os.path.exists(args.fund_file):
        fund_codes = read_fund_codes_from_file(args.fund_file)
    else:
        logger.error(f"基金代码文件不存在: {args.fund_file}")
        logger.info("使用 --create-sample 参数创建示例文件")
        return

    if not fund_codes:
        logger.error("没有有效的基金代码，程序退出")
        return

    monitor = FundMonitor(
        fund_codes=fund_codes,
        output_file=args.output,
        interval=args.interval
    )

    if args.once:
        logger.info("执行单次更新...")
        if monitor.run_once():
            logger.info(f"数据已保存到: {args.output}")
        else:
            logger.error("更新失败")
    else:
        monitor.start()

        try:
            while monitor.is_running:
                time.sleep(1)
        except KeyboardInterrupt:
            logger.info("\n检测到中断信号，正在停止监控...")
            monitor.stop()


if __name__ == "__main__":
    main()
