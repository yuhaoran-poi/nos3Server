import argparse
import pandas as pd
from pathlib import Path
import logging
import sys

def convert_xls_to_xlsx(input_dir, output_dir):
    """
    批量转换.xls到.xlsx
    :param input_dir: 输入目录路径
    :param output_dir: 输出目录路径
    """
    input_path = Path(input_dir)
    output_path = Path(output_dir)
    
    # 创建输出目录
    output_path.mkdir(parents=True, exist_ok=True)
    
    # 遍历所有.xls文件
    for xls_file in input_path.glob("*.xls"):
        try:
            # 构建输出路径
            xlsx_file = output_path / f"{xls_file.stem}.xlsx"
            
            # 使用pandas转换格式
            df = pd.read_excel(xls_file, engine="xlrd")
            df.to_excel(xlsx_file, index=False, engine="openpyxl")
            
            logging.info(f"成功转换: {xls_file.name} -> {xlsx_file.name}")
            
        except Exception as e:
            logging.error(f"文件 {xls_file.name} 转换失败: {str(e)}")
            continue
excel_path = "D:\\code\\nos3-dev\\nos3-config"        
 

if __name__ == "__main__":
    # 配置日志格式
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s [%(levelname)s] %(message)s",
        handlers=[logging.StreamHandler(sys.stdout)]
    )
    
    # 设置命令行参数
    parser = argparse.ArgumentParser(description="Excel格式转换工具")
    parser.add_argument("-i", "--input", 
                        default=excel_path,
                        help="输入目录（包含.xls文件），默认./input")
    parser.add_argument("-o", "--output",
                        default=excel_path,
                        help="输出目录，默认./output")
    
    args = parser.parse_args()
    
    # 检查输入目录是否存在
    if not Path(args.input).exists():
        logging.error(f"输入目录不存在: {args.input}")
        sys.exit(1)
    
    # 执行转换
    convert_xls_to_xlsx(args.input, args.output)