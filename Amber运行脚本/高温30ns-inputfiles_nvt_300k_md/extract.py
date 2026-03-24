import os

def extract_and_combine_text_files(output_filename="combined_content.txt"):
    """
    提取当前目录下所有文本文件的内容，并将其合并保存到一个结果文件中。

    Args:
        output_filename (str): 结果文件的名称。
    """
    current_directory = os.getcwd()
    print(f"正在扫描目录: {current_directory}")
    print(f"所有文本内容将保存到: {output_filename}\n")

    combined_content = []
    processed_files_count = 0
    skipped_files_count = 0

    # 遍历当前目录下的所有文件
    for filename in os.listdir(current_directory):
        filepath = os.path.join(current_directory, filename)

        # 检查是否是文件且不是输出文件本身
        if os.path.isfile(filepath) and filename != output_filename:
            try:
                with open(filepath, 'r', encoding='utf-8') as f:
                    content = f.read()
                    combined_content.append(f"--- 文件开始: {filename} ---\n")
                    combined_content.append(content)
                    combined_content.append(f"\n--- 文件结束: {filename} ---\n\n")
                print(f"已处理文件: {filename}")
                processed_files_count += 1
            except UnicodeDecodeError:
                print(f"跳过非文本文件或编码错误的文件: {filename}")
                skipped_files_count += 1
            except Exception as e:
                print(f"处理文件 {filename} 时发生错误: {e}")
                skipped_files_count += 1

    # 将所有内容写入结果文件
    if combined_content:
        with open(output_filename, 'w', encoding='utf-8') as outfile:
            outfile.writelines(combined_content)
        print(f"\n操作完成！")
        print(f"成功处理了 {processed_files_count} 个文本文件。")
        print(f"跳过了 {skipped_files_count} 个文件 (非文本或错误)。")
    else:
        print("\n当前目录中没有找到可处理的文本文件。")

# 运行函数
if __name__ == "__main__":
    extract_and_combine_text_files()