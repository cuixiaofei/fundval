# -*- coding: UTF-8 -*-
"""
场外基金实时估值模块 v1.0
支持普通基金和QDII基金的实时估值获取
数据源: 天天基金网(主) + 东方财富网(备用)
"""

import datetime
import json
import os
import re
import threading
import time
from typing import Dict, List, Optional

import requests
import urllib3
from loguru import logger

urllib3.disable_warnings()


class FundValuation:
    """场外基金实时估值获取类"""

    FUND123_BASE_URL = "https://www.fund123.cn"
    EASTMONEY_BASE_URL = "https://fund.eastmoney.com"

    def __init__(self):
        self.session = requests.Session()
        self._csrf = ""
        self.fund_cache = {}
        self.use_eastmoney = False
        self.init_session()

    def init_session(self):
        """初始化会话，获取CSRF令牌"""
        try:
            headers = {
                "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
                "Accept-Language": "zh-CN,zh;q=0.9",
                "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
            }
            response = self.session.get(
                f"{self.FUND123_BASE_URL}/fund",
                headers=headers,
                timeout=10,
                verify=False
            )
            csrf_match = re.search(r'"csrf":"(.*?)"', response.text)
            if csrf_match:
                self._csrf = csrf_match.group(1)
                logger.debug(f"CSRF令牌获取成功: {self._csrf[:10]}...")
        except Exception as e:
            logger.warning(f"初始化天天基金会话失败，将使用东方财富网: {e}")
            self.use_eastmoney = True

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

            fund_info = {
                "fund_key": fund_code_actual,
                "fund_name": fund_name
            }

            self.fund_cache[fund_code] = fund_info
            return fund_info

        except Exception as e:
            logger.error(f"从东方财富网获取基金{fund_code}信息失败: {e}")
            return None

    def get_fund_info(self, fund_code: str) -> Optional[Dict]:
        """获取基金基本信息"""
        if fund_code in self.fund_cache:
            return self.fund_cache[fund_code]

        if self.use_eastmoney:
            return self.get_fund_info_from_eastmoney(fund_code)

        try:
            headers = {
                "Accept-Language": "zh-CN,zh;q=0.9",
                "Content-Type": "application/json",
                "Origin": "https://www.fund123.cn",
                "Referer": "https://www.fund123.cn/fund",
                "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
                "X-API-Key": "foobar",
                "accept": "json"
            }

            url = f"{self.FUND123_BASE_URL}/api/fund/searchFund"
            params = {"_csrf": self._csrf}
            data = {"fundCode": fund_code}

            response = self.session.post(
                url,
                headers=headers,
                params=params,
                json=data,
                timeout=10,
                verify=False
            )

            result = response.json()
            if result.get("success"):
                fund_info = {
                    "fund_key": result["fundInfo"]["key"],
                    "fund_name": result["fundInfo"]["fundName"]
                }
                self.fund_cache[fund_code] = fund_info
                return fund_info
            else:
                logger.warning(f"从天天基金获取基金{fund_code}信息失败，尝试东方财富网")
                return self.get_fund_info_from_eastmoney(fund_code)

        except Exception as e:
            logger.warning(f"从天天基金获取基金{fund_code}信息异常，尝试东方财富网: {e}")
            return self.get_fund_info_from_eastmoney(fund_code)

    def get_fund_detail_from_eastmoney(self, fund_code: str) -> Optional[Dict]:
        """从东方财富网获取基金详细数据"""
        try:
            url = "http://fundgz.1234567.com.cn/js/" + fund_code + ".js"
            headers = {
                "Referer": "http://fund.eastmoney.com/",
                "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
            }

            response = self.session.get(url, headers=headers, timeout=10, verify=False)
            response.encoding = 'utf-8'

            jsonp_match = re.search(r'jsonpgz((.*?));', response.text)
            if jsonp_match:
                data = json.loads(jsonp_match.group(1))

                net_value = data.get("dwjz", "N/A")
                net_value_date = data.get("jzrq", "N/A")
                estimate_value = data.get("gsz", "N/A")
                estimate_growth = data.get("gszzl", "N/A")
                estimate_time = data.get("gztime", "N/A")

                day_growth = "N/A"
                try:
                    if net_value != "N/A" and estimate_value != "N/A":
                        nv = float(net_value)
                        ev = float(estimate_value)
                        day_growth = str(round((ev - nv) / nv * 100, 2))
                except:
                    pass

                return {
                    "net_value": net_value,
                    "net_value_date": net_value_date,
                    "day_of_growth": day_growth,
                    "estimate_value": estimate_value,
                    "estimate_growth": estimate_growth,
                    "estimate_time": estimate_time
                }
            else:
                logger.warning(f"无法解析基金{fund_code}的估值数据")
                return None

        except Exception as e:
            logger.error(f"从东方财富网获取基金{fund_code}详情失败: {e}")
            return None

    def get_fund_detail(self, fund_code: str, fund_key: str = None) -> Optional[Dict]:
        """获取基金详细数据"""
        if self.use_eastmoney:
            return self.get_fund_detail_from_eastmoney(fund_code)

        try:
            headers = {
                "Accept-Language": "zh-CN,zh;q=0.9",
                "Content-Type": "application/json",
                "Origin": "https://www.fund123.cn",
                "Referer": f"https://www.fund123.cn/matiaria?fundCode={fund_code}",
                "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
                "X-API-Key": "foobar",
                "accept": "json"
            }

            url = f"{self.FUND123_BASE_URL}/matiaria?fundCode={fund_code}"
            response = self.session.get(url, headers=headers, timeout=10, verify=False)

            day_of_growth_match = re.search(r'"dayOfGrowth":"(.*?)"', response.text)
            day_of_growth = day_of_growth_match.group(1) if day_of_growth_match else "N/A"

            net_value_match = re.search(r'"netValue":"(.*?)"', response.text)
            net_value = net_value_match.group(1) if net_value_match else "N/A"

            net_value_date_match = re.search(r'"netValueDate":"(.*?)"', response.text)
            net_value_date = net_value_date_match.group(1) if net_value_date_match else "N/A"

            return {
                "day_of_growth": day_of_growth,
                "net_value": net_value,
                "net_value_date": net_value_date
            }

        except Exception as e:
            logger.warning(f"从天天基金获取基金{fund_code}详情失败，尝试东方财富网: {e}")
            return self.get_fund_detail_from_eastmoney(fund_code)

    def get_fund_estimate(self, fund_code: str, fund_key: str) -> Optional[Dict]:
        """获取基金实时估值数据"""
        if self.use_eastmoney:
            return None

        try:
            headers = {
                "Accept-Language": "zh-CN,zh;q=0.9",
                "Content-Type": "application/json",
                "Origin": "https://www.fund123.cn",
                "Referer": f"https://www.fund123.cn/matiaria?fundCode={fund_code}",
                "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
                "X-API-Key": "foobar",
                "accept": "json"
            }

            url = f"{self.FUND123_BASE_URL}/api/fund/queryFundEstimateIntraday"
            params = {"_csrf": self._csrf}

            today = datetime.datetime.now().strftime("%Y-%m-%d")
            tomorrow = (datetime.datetime.now() + datetime.timedelta(days=1)).strftime("%Y-%m-%d")

            data = {
                "startTime": today,
                "endTime": tomorrow,
                "limit": 200,
                "productId": fund_key,
                "format": True,
                "source": "WEALTHBFFWEB"
            }

            response = self.session.post(
                url,
                headers=headers,
                params=params,
                json=data,
                timeout=10,
                verify=False
            )

            result = response.json()
            if result.get("success"):
                estimate_list = result.get("list", [])
                if estimate_list:
                    latest = estimate_list[-1]
                    estimate_time = datetime.datetime.fromtimestamp(
                        latest["time"] / 1000
                    ).strftime("%H:%M")

                    forecast_growth = latest.get("forecastGrowth", 0)
                    forecast_net_value = latest.get("forecastNetValue", 0)

                    return {
                        "estimate_time": estimate_time,
                        "forecast_growth": round(float(forecast_growth) * 100, 2) if forecast_growth else 0,
                        "forecast_net_value": round(float(forecast_net_value), 4) if forecast_net_value else 0
                    }
                else:
                    return {
                        "estimate_time": "N/A",
                        "forecast_growth": 0,
                        "forecast_net_value": 0,
                        "is_qdii": True
                    }
            else:
                logger.warning(f"获取基金{fund_code}估值失败: {result}")
                return None

        except Exception as e:
            logger.warning(f"获取基金{fund_code}估值异常: {e}")
            return None

    def get_single_fund_data(self, fund_code: str) -> Optional[Dict]:
        """获取单个基金的完整数据"""
        fund_info = self.get_fund_info(fund_code)
        if not fund_info:
            return None

        if self.use_eastmoney:
            detail = self.get_fund_detail_from_eastmoney(fund_code)
            if not detail:
                return None

            is_qdii = "QDII" in fund_info["fund_name"].upper()

            forecast_growth = 0
            try:
                estimate_growth = detail.get("estimate_growth", "0")
                forecast_growth = float(estimate_growth) if estimate_growth != "N/A" else 0
            except:
                pass

            forecast_net_value = 0
            try:
                estimate_value = detail.get("estimate_value", "0")
                forecast_net_value = float(estimate_value) if estimate_value != "N/A" else 0
            except:
                pass

            return {
                "fund_code": fund_code,
                "fund_name": fund_info["fund_name"],
                "fund_key": fund_info["fund_key"],
                "net_value": detail.get("net_value", "N/A"),
                "net_value_date": detail.get("net_value_date", "N/A"),
                "day_of_growth": detail.get("day_of_growth", "N/A"),
                "estimate_time": detail.get("estimate_time", "N/A"),
                "forecast_growth": forecast_growth,
                "forecast_net_value": forecast_net_value,
                "is_qdii": is_qdii,
                "update_time": datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            }

        fund_detail = self.get_fund_detail(fund_code, fund_info["fund_key"])
        if not fund_detail:
            return None

        fund_estimate = self.get_fund_estimate(fund_code, fund_info["fund_key"])
        if not fund_estimate:
            fund_estimate = {
                "estimate_time": "N/A",
                "forecast_growth": 0,
                "forecast_net_value": 0
            }

        is_qdii = "QDII" in fund_info["fund_name"].upper() or fund_estimate.get("is_qdii", False)

        return {
            "fund_code": fund_code,
            "fund_name": fund_info["fund_name"],
            "fund_key": fund_info["fund_key"],
            "net_value": fund_detail["net_value"],
            "net_value_date": fund_detail["net_value_date"],
            "day_of_growth": fund_detail["day_of_growth"],
            "estimate_time": fund_estimate["estimate_time"],
            "forecast_growth": fund_estimate["forecast_growth"],
            "forecast_net_value": fund_estimate["forecast_net_value"],
            "is_qdii": is_qdii,
            "update_time": datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        }

    def get_multiple_funds_data(self, fund_codes: List[str]) -> List[Dict]:
        """批量获取多个基金的数据（使用多线程）"""
        results = []
        result_lock = threading.Lock()

        def fetch_fund_data(code: str):
            data = self.get_single_fund_data(code)
            with result_lock:
                if data:
                    results.append(data)
                else:
                    results.append({
                        "fund_code": code,
                        "fund_name": "获取失败",
                        "net_value": "N/A",
                        "day_of_growth": "N/A",
                        "estimate_time": "N/A",
                        "forecast_growth": 0,
                        "forecast_net_value": 0,
                        "is_qdii": False,
                        "update_time": datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
                    })

        max_workers = min(4, len(fund_codes))
        threads = []

        for code in fund_codes:
            t = threading.Thread(target=fetch_fund_data, args=(code,))
            threads.append(t)
            t.start()

            while len([t for t in threads if t.is_alive()]) >= max_workers:
                time.sleep(0.1)

        for t in threads:
            t.join()

        code_order = {code: i for i, code in enumerate(fund_codes)}
        results.sort(key=lambda x: code_order.get(x.get("fund_code", ""), 999))

        return results


def format_fund_data(fund_data: Dict) -> str:
    """格式化单个基金数据为字符串"""
    code = fund_data.get("fund_code", "N/A")
    name = fund_data.get("fund_name", "N/A")
    net_value = fund_data.get("net_value", "N/A")
    net_value_date = fund_data.get("net_value_date", "N/A")
    day_growth = fund_data.get("day_of_growth", "N/A")
    estimate_time = fund_data.get("estimate_time", "N/A")
    forecast_growth = fund_data.get("forecast_growth", 0)
    forecast_net_value = fund_data.get("forecast_net_value", 0)
    is_qdii = fund_data.get("is_qdii", False)

    if isinstance(forecast_growth, (int, float)):
        growth_str = f"{forecast_growth:+.2f}%"
    else:
        growth_str = str(forecast_growth)

    if isinstance(day_growth, (int, float)):
        day_growth_str = f"{day_growth:+.2f}%"
    else:
        # 尝试转换为浮点数并保留两位小数
        try:
            day_growth_float = float(day_growth)
            day_growth_str = f"{day_growth_float:+.2f}%"
        except (ValueError, TypeError):
            day_growth_str = str(day_growth)

    qdii_mark = " [QDII]" if is_qdii else ""

    return (
        f"[{code}] {name}{qdii_mark}\n"
        f"  净值: {net_value} ({net_value_date})\n"
        f"  日涨幅: {day_growth_str}\n"
        f"  估值: {forecast_net_value} ({estimate_time})\n"
        f"  估值涨幅: {growth_str}\n"
    )


def generate_report(funds_data: List[Dict], title: str = "场外基金实时估值") -> str:
    """生成完整的估值报告"""
    now = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    lines = []
    lines.append("=" * 70)
    lines.append(f"  {title}")
    lines.append(f"  更新时间: {now}")
    lines.append("=" * 70)
    lines.append("")

    if not funds_data:
        lines.append("暂无基金数据")
        return "\n".join(lines)

    total_count = len(funds_data)
    qdii_count = sum(1 for f in funds_data if f.get("is_qdii", False))
    valid_estimate_count = sum(1 for f in funds_data if f.get("estimate_time") != "N/A")
    failed_count = sum(1 for f in funds_data if f.get("fund_name") == "获取失败")

    valid_growths = [f.get("forecast_growth", 0) for f in funds_data 
                     if isinstance(f.get("forecast_growth"), (int, float)) and f.get("fund_name") != "获取失败"]
    avg_growth = sum(valid_growths) / len(valid_growths) if valid_growths else 0

    lines.append(f"【统计信息】")
    lines.append(f"  基金总数: {total_count}")
    lines.append(f"  QDII基金: {qdii_count}")
    lines.append(f"  有效估值: {valid_estimate_count}")
    lines.append(f"  获取失败: {failed_count}")
    lines.append(f"  平均估值涨幅: {avg_growth:+.2f}%")
    lines.append("")

    rise_count = sum(1 for g in valid_growths if g > 0)
    fall_count = sum(1 for g in valid_growths if g < 0)
    flat_count = sum(1 for g in valid_growths if g == 0)

    lines.append(f"【涨跌分布】")
    lines.append(f"  上涨: {rise_count}  下跌: {fall_count}  持平: {flat_count}")
    lines.append("")

    lines.append("【基金详情】")
    lines.append("-" * 70)

    for i, fund in enumerate(funds_data, 1):
        lines.append(f"\n[{i}] {format_fund_data(fund)}")

    lines.append("")
    lines.append("=" * 70)
    lines.append("数据来源: 东方财富网/天天基金网")
    lines.append("=" * 70)

    return "\n".join(lines)


def read_fund_codes_from_file(file_path: str) -> List[str]:
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


if __name__ == "__main__":
    fv = FundValuation()

    test_code = "017174"
    print(f"\n测试获取基金 {test_code} 的数据:")
    data = fv.get_single_fund_data(test_code)
    if data:
        print(format_fund_data(data))
    else:
        print("获取失败")
