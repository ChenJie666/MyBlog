---
title: Python爬虫Selenium(encode和decode没搞懂)
categories:
- Python
---
### 简单概念
PhantomJS是一个机遇Webkit的无界面浏览器，会把网站加载到内存并执行页面上的JavaScript。下载地址：https://phantomjs.org/download.html

Chromedriver与PhantomJS不同的是，Chromedriver是有界面的浏览器。下载地址(必须与chrome版本对应)  ：https://npm.taobao.org/mirrors/chromedriver/

###准备
>需要安装requests selenium beautifulsoup4 pandas，pandas导出为excel需要安装xlrd和openpyxl
>**安装模块：**
pip install requests selenium pandas xlrd openpyxl  -i https://pypi.tuna.tsinghua.edu.cn/simple --trusted-host pypi.tuna.tsinghua.edu.cn

**引入模块：**
import pandas as pd
import requests
from bs4 import BeautifulSoup
import selenium

注查看网页的html源码(在网址前添加view-source)
view-source:https://www.bilibili.com/



###最简单的爬虫
```py
# -*- coding:utf-8 -*-

from bs4 import BeautifulSoup
import time
from selenium import webdriver
import pandas as pd
import openpyxl
import os

# 参数设置
target_year = 2019
target_province = '浙江'
start_code = 30
end_code = 2701
target_file = "C:\Users\Administrator\Desktop\Univerties{}.xlsx".format(target_year)
sheet_data = str(target_year)
sheet_err = str(target_year) + '_err'
page_interval_sleep = 0.5
click_interval_sleep = 0.1

# 创建excel文件和sheet表
if os.path.exists(target_file):
    wb = openpyxl.load_workbook(target_file)
    sheets = wb.sheetnames
    if sheet_data not in sheets:
        print('创建sheet_data:' + sheet_data)
        wb.create_sheet(sheet_data)
        wb.save(target_file)
    if sheet_err not in sheets:
        wb.create_sheet(sheet_err)
        wb.save(target_file)
        print('创建sheet_err:' + sheet_err)
else:
    wb = openpyxl.Workbook()
    ws = wb.create_sheet(sheet_data)
    wb.create_sheet(sheet_err)
    ws.append(['学校', 'code', '学校位置', '招生年份', '招生省份', '专业名称', '最高分', '平均分', '最低分', '最低位次', '录取批次'])
    wb.save(target_file)

# 计算程序运行时长
startTime = time.perf_counter()

if __name__ == '__main__':
    # TODO 创建浏览器对象
    # executable_path = "F:\Google Chrome x86\chromedriver.exe"
    # driver = webdriver.Chrome(executable_path=executable_path)
    executable_path = "E:\miniconda3\phantomjs-2.1.1-windows\bin\phantomjs.exe"
    driver = webdriver.PhantomJS(executable_path=executable_path)

    # TODO 遍历院校
    for code in range(start_code, end_code):
        try:
            url = "https://gkcx.eol.cn/school/{}/provinceline".format(code)
            print("***url:" + url)
            driver.get(url)

            # TODO 选择年份和省份
            # 年份
            element = driver.find_element_by_id('form3').find_element_by_class_name('ant-select-selection--single')
            driver.execute_script("arguments[0].click()", element)
            time.sleep(click_interval_sleep)
            element = driver.find_element_by_class_name('ant-select-dropdown-menu-vertical').find_element_by_xpath(
                '//li[text()="{}"]'.format(target_year))
            driver.execute_script("arguments[0].click()", element)

            time.sleep(click_interval_sleep)

            # 省份
            element = driver.find_element_by_xpath('//div[@class="schoolLine clearfix"][3]').find_element_by_class_name(
                'ant-select-selection--single')
            driver.execute_script("arguments[0].click()", element)
            time.sleep(click_interval_sleep)
            element = driver.find_element_by_class_name('ant-select-dropdown-menu-vertical').find_element_by_xpath(
                '//li[text()="{}"]'.format(target_province))
            driver.execute_script("arguments[0].click()", element)

            # TODO 解析内容
            soup = BeautifulSoup(driver.page_source, 'html.parser')
            schoolName = soup.find('span', {'class': 'line1-schoolName'}).text
            location = soup.find('span', {'class': 'line1-province'}).text
            year = soup.find('form', {'id': 'form3'}).find('div',
                                                           {'class', 'ant-select-selection-selected-value'}).text
            province = soup.find_all('div', 'content-top content_top_1_4')[2] \
                .find('div', {'class': 'ant-select-selection-selected-value'}).text
            item = soup.find('div', {'class': 'line_table_box major_score_table'})

            datas = [[schoolName, str(code), location, year, province]]
            df = pd.DataFrame(
                columns=('学校', 'code', '学校位置', '招生年份', '招生省份', '专业名称', '最高分', '平均分', '最低分', '最低位次', '录取批次'))
            hasNext = True
            while hasNext:
                # TODO 隐式等待
                driver.implicitly_wait(10)
                time.sleep(page_interval_sleep)

                # TODO 判断是否有下一页
                element = driver.find_element_by_xpath(
                    '//div[@class="schoolLine clearfix"][3]').find_element_by_class_name(
                    'ant-pagination-next')
                clazz = element.get_attribute('class')
                if 'ant-pagination-disabled' in clazz:
                    hasNext = False

                # # TODO 解析内容
                soup = BeautifulSoup(driver.page_source, 'html.parser')
                item = soup.find('div', {'class': 'line_table_box major_score_table'})

                print("学校为：{},位于：{}，信息为： {}".format(schoolName, location, item))

                for tr in item.findAll('tr')[1:]:
                    data = [schoolName, str(code), location, year, province]
                    for td in tr.findAll('td'):
                        data.append(td.text)
                    datas.append(data)

                # TODO 下一页
                driver.execute_script("arguments[0].click()", element)

            datas.append([''])
            print(datas)

            # TODO 爬取的信息追加到excel表格中
            wb = openpyxl.load_workbook(target_file)
            ws = wb[sheet_data]
            for index in range(len(datas)):
                ws.append(datas[index])
            wb.save(target_file)

        except Exception:
        #     # TODO 将院校信息和错误信息追加到excel表格中
            wb = openpyxl.load_workbook(target_file)
            ws = wb[sheet_data]
            ws.append(['', code])
            ws.append([''])

            wb = openpyxl.load_workbook(target_file)
            ws = wb[sheet_err]
            ws.append([code])
            wb.save(target_file)

endTime = time.perf_counter()
print("Done!!!")
print("The function run time is : %.03f seconds" % (endTime - startTime))
```
>在跑自动化时，页面上有2个下拉框，两个下拉框无论屏蔽哪一段都会成功，但是同时放开跑时会报错，百度给的解释是上面的下拉框元素覆盖了下面下拉框的元素定位，才会抛出ElementClickInterceptedException异常;解决方案如下
>```py
># 方案一
>element = driver.find_element_by_css('div[class*="loadingWhiteBox"]')
>driver.execute_script("arguments[0].click();", element)
># 方案二
>element = driver.find_element_by_css('div[class*="loadingWhiteBox"]')
>webdriver.ActionChains(driver).move_to_element(element ).click(element ).perform()
>```

船新版本
```py
# -*- coding:utf-8 -*-

import time
from selenium import webdriver
import pandas as pd
import openpyxl
import os
from selenium.webdriver.support.wait import WebDriverWait
from selenium.webdriver.common.desired_capabilities import DesiredCapabilities

# 参数设置
target_year = 2017
target_province = '浙江'
start_code = 30
end_code = 3600
target_file = "C:\Users\CJ\Desktop\Univerties{}-2.xlsx".format(target_year)
sheet_data = str(target_year)
sheet_err = str(target_year) + '_err'
page_interval_sleep = 0.5
click_interval_sleep = 0.1
timeout_sec = 5

school_not_find_err = "获取校名超时"
location_not_find_err = "获取所在位置超时"
school_not_find_code = "0"
info_not_find_code = "1"

# 创建excel文件和sheet表
if os.path.exists(target_file):
    wb = openpyxl.load_workbook(target_file)
    sheets = wb.sheetnames
    if sheet_data not in sheets:
        print('创建sheet_data:' + sheet_data)
        wb.create_sheet(sheet_data)
        wb.save(target_file)
    if sheet_err not in sheets:
        wb.create_sheet(sheet_err)
        wb.save(target_file)
        print('创建sheet_err:' + sheet_err)
else:
    wb = openpyxl.Workbook()
    ws1 = wb.create_sheet(sheet_data)
    ws2 = wb.create_sheet(sheet_err)
    ws1.append(['学校', 'code', '学校位置', '招生年份', '招生省份', '专业名称', '最高分', '平均分', '最低分', '最低位次', '录取批次'])
    ws2.append(['学校', 'code', '错误类型', '错误信息', '原因推断', '详细信息'])
    wb.save(target_file)

# 计算程序运行时长
startTime = time.perf_counter()

if __name__ == '__main__':
    # TODO 创建浏览器对象
    # # 使用chromedriver浏览器(推荐)
    # executable_path = "E:\Google Chrome x86\chromedriver.exe"
    # options = webdriver.ChromeOptions()
    # options.add_argument('--headless')
    # # options.add_argument('--proxy-server=http://ip:port')
    # driver = webdriver.Chrome(executable_path=executable_path, chrome_options=options)
    # # 设置加载超时时间
    # desired_capabilities = DesiredCapabilities().CHROME
    # desired_capabilities['pageLoadStrategy'] = 'none'
    # driver.implicitly_wait(timeout_sec)

    # 使用phantomjs浏览器(已停止维护)
    executable_path = "E:\miniconda3\envs\spider\phantomjs-2.1.1-windows\bin\phantomjs.exe"
    driver = webdriver.PhantomJS(executable_path=executable_path)

    # TODO 遍历院校
    for code in range(start_code, end_code):
        url = "https://gkcx.eol.cn/school/{}/provinceline".format(code)
        print("***url:" + url)
        driver.get(url)
        # print(driver.page_source)

        schoolName = ''
        try:
            # TODO 解析内容
            # schoolName = driver.find_element_by_class_name('line1-schoolName').text
            # location = driver.find_element_by_class_name('line1-province').text
            schoolName = WebDriverWait(driver, timeout_sec, poll_frequency=1).until(
                lambda d: driver.find_element_by_class_name('line1-schoolName').text,
                message=school_not_find_err)
            location = WebDriverWait(driver, timeout_sec, poll_frequency=1).until(
                lambda d: driver.find_element_by_class_name('line1-province').text,
                message=location_not_find_err)

            # WebDriverWait(driver, timeout_sec, poll_frequency=1).until(
            #     lambda d: driver.find_element_by_link_text('专业分数线')
            # )

            # TODO 选择年份和省份
            element = driver.find_element_by_xpath('//div[@class="schoolLine clearfix"][3]')
            # 年份
            year_select = element.find_element_by_xpath('//div[@class="dropdown-box"][3]').find_element_by_class_name(
                'ant-select-selection--single')
            driver.execute_script("arguments[0].click()", year_select)
            time.sleep(click_interval_sleep)
            year_element = driver.find_element_by_class_name('ant-select-dropdown-menu-vertical').find_element_by_xpath(
                '//li[text()="{}"]'.format(target_year))
            driver.execute_script("arguments[0].click()", year_element)

            # 省份
            pro_select = element.find_element_by_xpath('//div[@class="dropdown-box"][1]').find_element_by_class_name(
                'ant-select-selection--single')
            driver.execute_script("arguments[0].click()", pro_select)
            time.sleep(click_interval_sleep)
            pro_element = driver.find_element_by_class_name('ant-select-dropdown-menu-vertical').find_element_by_xpath(
                '//li[text()="{}"]'.format(target_province))
            driver.execute_script("arguments[0].click()", pro_element)

            datas = [[]]
            df = pd.DataFrame(
                columns=('学校', 'code', '学校位置', '招生年份', '招生省份', '专业名称', '最高分', '平均分', '最低分', '最低位次', '录取批次'))
            hasNext = True
            while hasNext:
                # TODO 等待
                time.sleep(page_interval_sleep)

                element = driver.find_element_by_xpath('//div[@class="schoolLine clearfix"][3]')

                # # TODO 解析内容
                year = element.find_element_by_xpath('//div[@class="dropdown-box"][3]').find_element_by_class_name(
                    'ant-select-selection-selected-value').text
                province = element.find_element_by_xpath('//div[@class="dropdown-box"][1]').find_element_by_class_name(
                    'ant-select-selection-selected-value').text
                item = element.find_element_by_class_name('province_score_line_table').find_element_by_tag_name('tbody')

                print("学校为：{},位于：{}，信息数量为： {}".format(schoolName, location, "|".join(item.text.split('
'))))

                for tr in item.find_elements_by_tag_name('tr')[1:]:
                    data = [schoolName, str(code), location, year, province]
                    for td in tr.find_elements_by_tag_name('td'):
                        data.append(td.text)
                    datas.append(data)

                # TODO 判断是否有下一页
                page_next = element.find_element_by_class_name(
                    'ant-pagination-next')
                clazz = page_next.get_attribute('class')
                if 'ant-pagination-disabled' in clazz:
                    hasNext = False
                driver.execute_script("arguments[0].click()", page_next)

            print(datas)

            # TODO 爬取的信息追加到excel表格中
            wb = openpyxl.load_workbook(target_file)
            ws = wb[sheet_data]
            for index in range(len(datas)):
                ws.append(datas[index])
            wb.save(target_file)

        except Exception as e:
            # TODO 将院校信息和错误信息追加到excel表格中
            wb = openpyxl.load_workbook(target_file)
            ws = wb[sheet_data]
            err_code = ''
            err_type = ''
            error_msg = str(e).split(' ')[1].strip()
            print('***error_msg:' + error_msg)
            print(repr(e))
            if [school_not_find_err, location_not_find_err].__contains__(error_msg):
                err_code = school_not_find_code
                err_type = 'code无对应院校'
            else:
                err_code = info_not_find_code
                err_type = '院校无专业信息'

            ws.append([''])
            ws.append([schoolName, str(code), err_code, error_msg, err_type, repr(e)])
            ws.append([''])
            wb.save(target_file)

            wb = openpyxl.load_workbook(target_file)
            ws = wb[sheet_err]
            ws.append([schoolName, str(code), err_code, error_msg, err_type, repr(e)])
            wb.save(target_file)

endTime = time.perf_counter()
print("Done!!!")
print("The function run time is : %.03f seconds" % (endTime - startTime))

```
>设置元素获取超时时间
①driver=webdriver.Chrome()
driver.set_page_load_timeout(5)
driver.set_script_timeout(5)#这两种设置都进行才有效
try:
    d.get(s)
except:
    d.execute_script('window.stop()')
缺点：如果set_page_load_timeout超时，那么html源码未加载，会导致driver失效。不推荐使用。
②隐式等待(implicit)
driver.implicitly_wait(time)
显示等待(explicit)
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.support.wait import WebDriverWait
from selenium.webdriver.common.by import By
from selenium import webdriver
driver = webdriver.Chrome()
WebDriverWait(driver, 3).until(EC.presence_of_element_located((By.ID, 'wrapper'))) #until用来检测指定元素是否出现
WebDriverWait(driver, 3).until_not(EC.presence_of_element_located((By.ID, 'wrapper1'))) #until_not用于检测指定元素是否消失
```

<br>
<br>
Selenium 4.3 爬取百度图片
```

```
