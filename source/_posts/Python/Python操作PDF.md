---
title: Python操作PDF
categories:
- Python
---
安装模组
pip install pdfplumber -i 

###提取PDF中的几页
```py
from PyPDF2 import PdfFileReader, PdfFileWriter

readPath = "C:\Users\CJ\Desktop\2017.pdf"
savePath = "C:\Users\CJ\Desktop\2017普通类.pdf"

pdf = PdfFileReader(readPath)
writerStream = PdfFileWriter()
for pageNum in range(10,323):
    writerStream.addPage(pdf.getPage(pageNum))
with open(savePath, 'wb') as newPdf:
    writerStream.write(newPdf)
```

###将PDF保存为Excel


###解析无法识别表格的PDF文件
```py
# -*- coding: utf-8 -*-

import pdfplumber
import os
import openpyxl


# 函数
def getDatas(schoolName, code, profession, subject, scores):
    if len(scores) == 5:  # 正常
        data = [schoolName, code, profession, subject, scores[0], scores[1], scores[2], scores[3], scores[4]]
        datas.append(data)
    elif len(scores) == 6:  # 去掉第四个数
        data = [schoolName, code, profession, subject, scores[0], scores[1], scores[2], scores[4], scores[5]]
        datas.append(data)
    elif len(scores) == 7:  # 分两条
        data1 = [schoolName, code, profession, subject, scores[0], scores[1], scores[2], scores[3], scores[4]]
        data2 = [schoolName, code, profession, subject, scores[0], scores[1], scores[2], scores[5], scores[6]]
        datas.append(data1)
        datas.append(data2)
    elif len(scores) == 8:  # 去掉第四个数，分两条
        data1 = [schoolName, code, profession, subject, scores[0], scores[1], scores[2], scores[4], scores[5]]
        data2 = [schoolName, code, profession, subject, scores[0], scores[1], scores[2], scores[6], scores[7]]
        datas.append(data1)
        datas.append(data2)
    elif len(scores) == 9:  # 后三条分开
        data1 = [schoolName, code, profession, subject, scores[0], scores[1], scores[2], scores[3], scores[4]]
        data2 = [schoolName, code, profession, subject, scores[0], scores[1], scores[2], scores[5], scores[6]]
        data3 = [schoolName, code, profession, subject, scores[0], scores[1], scores[2], scores[7], scores[8]]
        datas.append(data1)
        datas.append(data2)
        datas.append(data3)
    return datas


# 定义保存Excel的位置
readPath = "C:\Users\Administrator\Desktop\2019普通类.pdf"
savePath = "C:\Users\Administrator\Desktop\2019普通类.xlsx"
sheetName = '2019'

if os.path.exists(savePath):
    wb = openpyxl.load_workbook(savePath)
    sheets = wb.sheetnames
    if sheetName not in sheets:
        wb.create_sheet(sheetName)
        ws = wb[sheetName]
        ws.append(['院校(所在地)', '代码', '院校（专业） 名称', '选考科目 范围要求', '录取人数', '学制', '平均分', '最低分', '位次'])
        wb.save(savePath)
else:
    wb = openpyxl.Workbook()  # 定义workbook
    ws = wb.create_sheet(sheetName)  # 添加sheet
    ws.append(['院校(所在地)', '代码', '院校（专业） 名称', '选考科目 范围要求', '录取人数', '学制', '平均分', '最低分', '位次'])
    wb.save(savePath)

pdf = pdfplumber.open(readPath)
print('
')
print('开始读取数据')
print('
')
index = 0
schoolInfo = []
for page in pdf.pages:
    print("***page.page_number:" + str(page.page_number))
    # print("*****page.extract_text():
" + page.extract_text())
    lines = page.extract_text().split('
')
    newLines = list(
        filter(lambda x: not x.startswith(('［', '二、', '年浙江省', '２０１９', '一、二、三', '录 一段', '院校代名', '·')), lines))
    index = 0
    for i in range(len(newLines)):
        print(newLines[i])
    datas = []
    while index < (len(newLines)):
        # print(newLines[index])
        # 1、将学校和学校编码组合为一个数组
        if newLines[index].endswith('）'):
            schoolInfo = [newLines[index], newLines[index + 1]]
            index += 2
        else:
            # 2、将专业、选考科目和信息组合为一个数组
            # 2.1、数据分两行的情况
            if newLines[index].endswith(('不限', '物理', '化学', '生物', '技术', '地理', '政治', '历史')):
                split1 = newLines[index].split(' ')
                profession = ''
                subject = ''
                if split1[0].__contains__("“"):
                    profession = split1[0] + split1[1]
                    subject = '/'.join(split1[2:])
                else:
                    profession = split1[0]
                    subject = '/'.join(split1[1:])
                scores = []
                if newLines[index + 1].__contains__('／'):
                    split2 = newLines[index + 1].split('／')[-1].strip()
                    scores = split2.split(' ')
                else:
                    scores = newLines[index + 1].split(' ')[1:]

                datas = getDatas(schoolInfo[0], schoolInfo[1], profession, subject, scores)
                index += 2
            elif len(newLines[index].split(' ')) >= 6:
                # 2.2、数据为一行的情况
                split = newLines[index].split(' ')
                profession = split[1]
                subject = split[2]
                scores = split[3:]
                datas = getDatas(schoolInfo[0], schoolInfo[1], profession, subject, scores)
                index += 1
            elif len(newLines[index + 1].split(' ')) <= 4:
                # 2.2、数据分三行的情况
                scores = []
                if newLines[index + 2].__contains__('／'):
                    split = newLines[index + 2].split('／')
                    scores = split[-1].strip().split(' ')
                else:
                    split = newLines[index + 2].split(' ')
                    scores = split[1:]
                profession = newLines[index] + split[0]
                subject = '/'.join(newLines[index + 1].strip().split(' '))
                datas = getDatas(schoolInfo[0], schoolInfo[1], profession, subject, scores)
                index += 3
    print(datas)
    wb = openpyxl.load_workbook(savePath)
    ws = wb[sheetName]
    for i in range(len(datas)):
        ws.append(datas[i])
    wb.save(savePath)

pdf.close()
wb.close()

# 保存Excel表
print('
')
print('写入excel成功')
print('保存位置：')
print(savePath)
print('
')
input('PDF取读完毕，按任意键退出')
```
>目前还存在问题：
①一条记录有2行，选修的学科为一个或不限，且专业中有数字
②一条记录有2行，专业中有字母
