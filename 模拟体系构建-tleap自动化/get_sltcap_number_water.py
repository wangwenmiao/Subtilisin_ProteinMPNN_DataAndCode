from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
import time


# 初始化Chrome浏览器（无头）
def init_browser():
    chrome_options = Options()
    #chrome_options.add_argument("--headless")
    chrome_driver_path = "/home/lab/wwm/predict_protein_para/crawler/chromedriver_135/chromedriver-linux64/chromedriver"
    service = Service(executable_path=chrome_driver_path)
    return webdriver.Chrome(service=service, options=chrome_options)


# 提交表单并抓取结果
def run_sltcap(input_mass, input_conc, input_charge, num_water, output_file="sltcap_result.txt"):
    #url = "https://www.phys.ksu.edu/personal/schmit/SLTCAP.html"
    url = "https://www.phys.ksu.edu/personal/schmit/SLTCAP/SLTCAP.html"
    driver = init_browser()
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

        # 保存结果
        with open(output_file, "w", encoding="utf-8") as f:
            f.write(result_text)
        print(f"✅ 结果已保存到：{output_file}")

    except Exception as e:
        print(f"❌ 发生错误：{e}")

    finally:
        driver.quit()


# 示例调用
run_sltcap(
    input_mass="50",
    input_conc="150",
    input_charge="-5",
    num_water="1000",
    output_file="sltcap_result.txt"
)

