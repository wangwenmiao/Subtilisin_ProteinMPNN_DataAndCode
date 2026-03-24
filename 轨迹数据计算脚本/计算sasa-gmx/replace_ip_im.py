import os

# 定义函数来替换 .top 文件中的 'IM' 为 'Na+' 和 'IP' 为 'Cl-'
def replace_im_ip_with_na_cl_in_all_top_files():
    try:
        # 获取当前目录下所有的 .top 文件
        current_dir = os.getcwd()
        top_files = [f for f in os.listdir(current_dir) if f.endswith('.top')]

        # 如果没有找到任何 .top 文件，给出提示
        if not top_files:
            print("当前目录下没有找到任何 .top 文件")
            return

        # 遍历每个 .top 文件并进行替换
        for top_file in top_files:
            file_path = os.path.join(current_dir, top_file)
            
            # 打开原始文件并读取内容
            with open(file_path, 'r') as file:
                lines = file.readlines()

            # 替换每一行中的 'IM' 为 'Na+' 和 'IP' 为 'Cl-'
            modified_lines = [line.replace(' IP ', ' Na+ ').replace(' IM ', ' Cl- ') for line in lines]

            # 将修改后的内容覆盖写回到原文件
            with open(file_path, 'w') as file:
                file.writelines(modified_lines)

            print(f"文件 {top_file} 的 'IP' 替换为 'Na+' 和 'IM' 替换为 'Cl-' 完成！")

    except Exception as e:
        print(f"发生错误: {e}")

# 执行函数
replace_im_ip_with_na_cl_in_all_top_files()

