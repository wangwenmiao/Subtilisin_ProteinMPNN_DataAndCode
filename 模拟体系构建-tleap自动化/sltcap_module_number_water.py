# sltcap_module.py

from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
import time
import re


# 初始化Chrome浏览器（无头）
def init_browser():
    chrome_options = Options()
    chrome_options.add_argument("--headless")  # 可根据需要启用无头模式
    chrome_driver_path = "/home/yons/softwares/chromedriver-linux64/chromedriver"
    service = Service(executable_path=chrome_driver_path)
    return webdriver.Chrome(service=service, options=chrome_options)


# 提交表单并抓取结果
def run_sltcap(input_mass, input_conc, input_charge, num_water, save_to_file=False, output_file="sltcap_result.txt"):
    url = "https://www.phys.ksu.edu/personal/schmit/SLTCAP/SLTCAP.html"
    driver = init_browser()
    result_text = ""
    
    try:
        driver.get(url)

        # 填写表单
        driver.find_element(By.NAME, "ProteinMass").send_keys(input_mass)
        driver.find_element(By.NAME, "Concentration").clear()
        driver.find_element(By.NAME, "Concentration").send_keys(input_conc)
        driver.find_element(By.NAME, "SoluteCharges").send_keys(input_charge)

        driver.find_element(By.NAME, "Molecules").send_keys(num_water)

        #driver.find_element(By.NAME, "BoxLengthX").send_keys(box_x)
        #driver.find_element(By.NAME, "BoxLengthY").send_keys(box_y)
        #driver.find_element(By.NAME, "BoxLengthZ").send_keys(box_z)


        # 点击提交
        driver.find_element(By.XPATH, '//input[@type="submit" and @value="Calculate"]').click()

        # 等待结果加载
        WebDriverWait(driver, 10).until(EC.presence_of_element_located((By.TAG_NAME, "body")))
        time.sleep(2)  # 等待渲染完成

        # 获取页面内容
        result_text = driver.find_element(By.TAG_NAME, "body").text

        # 使用正则表达式提取离子数目
        match = re.search(r"Your system requires ([\d.]+) anions and ([\d.]+) cations", result_text)
        if match:
            anions = float(match.group(1))  # 提取并转换为浮动数值
            cations = float(match.group(2))  # 提取并转换为浮动数值
            print(f"阴离子数量: {anions}")
            print(f"阳离子数量: {cations}")
        else:
            print("未能提取到离子数量。")


    except Exception as e:
        print(f"❌ 发生错误：{e}")

    finally:
        driver.quit()

    return result_text, round(anions), round(cations)

