---
title: Python爬取百度图库和上传百度图库
categories:
- Python
---
```
from tkinter import Tk, constants, Scrollbar, Canvas, Label, Button, Frame, Entry, Spinbox, messagebox, StringVar, \
    IntVar, BooleanVar, Checkbutton
from tkinter.ttk import Progressbar
from tkinter.filedialog import askdirectory
from uuid import uuid4
from os import path, mkdir, startfile, walk
import sys
import time
import random
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.edge.options import Options
from threading import Thread, Lock
from concurrent.futures import ThreadPoolExecutor
from urllib.request import urlretrieve
from logging import basicConfig, getLogger
from datetime import datetime
from time import strftime, localtime
from PIL import Image
from PIL.ImageTk import PhotoImage
import imghdr
from requests import post, request
from urllib.parse import quote
from base64 import b64encode
import os

"""
1. 多线程和锁
2. tkinter
3. selenium
4. 打包exe文件
"""


def clear_constants():
    global button_running
    global progressbar
    global progressbar_percent
    global keyword_urls_complete_num
    global keyword_progress_text
    global logfile_name
    global upload_progress_text_dict
    global upload_img_complete_num
    # 定义全局变量
    button_running = None
    progressbar = None
    progressbar_percent = None
    keyword_urls_complete_num = {}
    keyword_progress_text = {}
    logfile_name = ''
    upload_progress_text_dict = {}
    upload_img_complete_num = {}


def initGui():
    # window.iconbitmap(path_to_icon + '/lighting64.ico')
    win_width = 550
    win_height = 140
    window.geometry(f"{win_width}x{win_height}")

    frame = Frame(window, relief=constants.GROOVE, bd=0)
    frame.pack(side=constants.TOP, fill=constants.BOTH)

    def startDownload():
        # 清空页面
        frame.grid_forget()
        frame.pack_forget()
        startDownloadGui()
        # try:
        #     startDownloadGui()
        # except Exception as exception:
        #     messagebox.showinfo("提示", str(exception))

    button_spider = Button(frame, text="爬取图片", height=20, width=12, anchor='center', relief=constants.GROOVE,
                           font=('楷体', 20), state=constants.NORMAL, command=startDownload)
    button_spider.pack(side=constants.LEFT, fill=constants.BOTH, pady=15, padx=(30, 15))

    def startUpload():
        # 清空页面
        frame.grid_forget()
        frame.pack_forget()
        startUploadGui()
        # try:
        #     startUploadGui()
        # except Exception as exception:
        #     messagebox.showinfo("提示", str(exception))

    button_upload = Button(frame, text="上传图片", height=20, width=12, anchor='center', relief=constants.GROOVE,
                           font=('楷体', 20), state=constants.NORMAL, command=startUpload)
    button_upload.pack(side=constants.RIGHT, fill=constants.BOTH, pady=15, padx=(15, 30))


def startUploadGui():
    global win_width
    global win_height
    global read_path
    global username
    global password
    global upload_progress_text_dict

    win_width = 550
    win_height = 470
    # g_screenwidth = int((window.winfo_screenwidth() - win_width) / 2)
    # g_screenheight = int((window.winfo_screenheight() - win_height) / 2)
    window.geometry(f"{win_width}x{win_height}")

    frame = Frame(window, relief=constants.GROOVE, bd=0)
    frame.pack(side=constants.TOP, fill=constants.BOTH, expand=constants.TRUE)

    frame2 = Frame(window, relief=constants.GROOVE, bd=0)
    frame2.pack(side=constants.BOTTOM, fill=constants.X, expand=constants.TRUE)
    # 新建字典，存储文件夹和文件夹下的图片
    dir_pic_dict = {}

    # 添加滚动条
    # 为了滚动条创建画布
    canvas = Canvas(frame)
    # canvas.grid(column=0, row=0, sticky=constants.NSEW)
    canvas.pack(side=constants.LEFT, fill=constants.BOTH, expand=constants.TRUE)

    sub_frame = Frame(canvas, bg="white")
    # sub_frame.grid(column=1, row=0, sticky=constants.NSEW)
    sub_frame.pack(side=constants.TOP, fill=constants.BOTH, expand=constants.TRUE)

    # 窗口展示的是frame的左上角
    canvas.create_window(0, 0, window=sub_frame, anchor=constants.NW)

    # 为最外层的Frame创建滚动条，用于滚动画布中的元素
    scrollV = Scrollbar(frame, orient=constants.VERTICAL, command=canvas.yview)
    # scrollV.grid(column=1, row=0, sticky=constants.NSEW)
    scrollV.pack(side=constants.RIGHT, fill=constants.Y)

    def scroll_bar(event):
        canvas.configure(yscrollcommand=scrollV.set, scrollregion=canvas.bbox("all"))

    def process_wheel(event):
        canvas.yview_scroll(-1 * (round(event.delta / 60)), "units")

    # 绑定滚动条
    sub_frame.bind("<Configure>", scroll_bar)
    # 绑定滚轮事件
    sub_frame.bind("<MouseWheel>", process_wheel)

    # 第一行
    lbl00 = Label(frame2, text='读取路径:')
    lbl00.grid(row=0, column=0)
    var00 = StringVar()

    if read_path is not None and read_path != '':
        var00.set(read_path)
    entry_path = Entry(frame2, width=44, textvariable=var00, state=constants.DISABLED)
    entry_path.grid(row=0, column=1, columnspan=4, sticky=constants.W + constants.E)

    def select_dir():
        global read_path
        global all_dir_dict
        global upload_select_dict
        read_path = askdirectory(initialdir=path.abspath('.'))
        var00.set(read_path)

        all_dir_dict.clear()
        upload_select_dict.clear()

        def all_chk():
            for value in upload_select_dict.values():
                value.set(constants.TRUE)

        def non_chk():
            for value in upload_select_dict.values():
                value.set(constants.FALSE)

        def inv_chk():
            for value in upload_select_dict.values():
                value.set(1 - value.get())

        # 显示选择按钮
        all_chk_btn = Button(sub_frame, text="全选", width='10', font=("SimSun", 8), command=all_chk, bg='#D2CDCD')
        all_chk_btn.grid(row=0, column=0, sticky=constants.W, padx="2")
        non_chk_btn = Button(sub_frame, text="全不选", width='10', font=("SimSun", 8), command=non_chk, bg='#D2CDCD')
        non_chk_btn.grid(row=0, column=1, sticky=constants.W, padx="2")
        inv_btn = Button(sub_frame, text="反选", width='10', font=("SimSun", 8), command=inv_chk, bg='#D2CDCD')
        inv_btn.grid(row=0, column=2, sticky=constants.W, padx="2")
        # 为了下面排版，扩充一个空白单元格
        blank_label = Label(sub_frame, width=18, bg='white')
        blank_label.grid(row=0, column=3)

        # 分两种情况：1.如果文件夹下还有文件夹，则将所有文件夹下的文件上传；2.如果文件夹下没有文件夹，则将该文件夹下文件上传
        ## 遍历文件夹下所有的文件
        global img_type_list
        upload_row_index = 0
        for root, dirs, files in walk(read_path):
            # 筛掉不符合命名规范的
            if len(path.basename(root).split('-')) != 3:
                continue
            file_list = []
            for file in files:
                if imghdr.what(path.join(root, file)) in img_type_list:
                    file_list.append(file)
            if len(file_list) > 0:
                all_dir_dict[root] = file_list

                # 显示选择的文件夹和文件夹下的图片数
                upload_select_dict[root] = BooleanVar(sub_frame)
                upload_select_dict[root].set(constants.TRUE)
                chk = Checkbutton(sub_frame, text=root[len(path.dirname(read_path)) + 1:], var=upload_select_dict[root],
                                  bg="white")
                chk.grid(row=upload_row_index + 2, column=0, columnspan=10, sticky=constants.W, padx=(10, 10))

                # 用于填充白色
                Label(sub_frame, bg="white").grid(row=upload_row_index + 2, column=10, sticky=constants.EW,
                                                  ipadx=win_width)

                # 显示进度文本
                progress_text = f'0/{len(file_list)}'
                progress_label = Label(sub_frame, text=progress_text, width=12, anchor=constants.CENTER, fg='black',
                                       bg='white')
                progress_label.grid(row=upload_row_index + 2, column=5)
                upload_progress_text_dict[root] = progress_label

                upload_row_index += 1

    button = Button(frame2, text='选择路径', command=select_dir)
    button.grid(row=0, column=5, sticky=constants.E, padx=(3, 1))

    # 第二行
    lbl0 = Label(frame2, text='Key:')
    lbl0.grid(row=1, column=0)
    var10 = StringVar()
    var10.set('')
    if username is not None:
        var10.set(username)
    entry_username = Entry(frame2, width=30, textvariable=var10)
    entry_username.grid(row=1, column=1, columnspan=4, sticky=constants.W + constants.E)
    entry_username.focus()

    # 第三行
    lbl0 = Label(frame2, text='Secret:')
    lbl0.grid(row=2, column=0)
    var20 = StringVar()
    var20.set('')
    if password is not None:
        var20.set(password)
    entry_password = Entry(frame2, width=30, textvariable=var20, show='*')
    entry_password.grid(row=2, column=1, columnspan=4, sticky=constants.W + constants.E)
    entry_password.focus()

    def eye_transfor():
        if entry_password['show'] == '*':
            entry_password['show'] = ''
            button_eye['image'] = img_eye_close
        else:
            entry_password['show'] = '*'
            button_eye['image'] = img_eye_open

    button_eye = Button(frame2, image=img_eye_open, command=eye_transfor)
    button_eye.grid(row=2, column=5, sticky=constants.W)

    # 第四行
    def click_run():
        global read_path
        global username
        global password

        read_path = entry_path.get()
        username = entry_username.get()
        password = entry_password.get()

        # 对参数进行校验
        # if not path.exists(read_path):
        #     messagebox.showinfo("提示", "该路径不存在!")
        #     return
        if username == '':
            messagebox.showinfo("提示", "请输入key!")
            return
        if password == '':
            messagebox.showinfo("提示", "请输入secret!")
            return

        """
        使用 AK，SK 生成鉴权签名（Access Token）,返回 access_token，或是None(如果错误)
        """
        global access_token
        url = "https://aip.baidubce.com/oauth/2.0/token"
        params = {"grant_type": "client_credentials", "client_id": username, "client_secret": password}
        try:
            access_token = str(post(url, params=params).json().get("access_token"))
        except Exception as e:
            logger.error(repr(e))
            messagebox.showinfo("异常", repr(e))

        if access_token == 'None':
            messagebox.showinfo("提示", "获取用户token异常")
            return

        if not path.exists(read_path):
            messagebox.showinfo("提示", "该路径不存在")
            return

        # 获取勾选上传的文件
        upload_chosen_dict = {}
        for root, value in upload_select_dict.items():
            if not value.get():
                continue
            upload_chosen_dict[root] = all_dir_dict[root]

        if len(upload_chosen_dict) == 0:
            messagebox.showinfo("提示", "不存在上传文件")
            return

        # 先清理再跳转
        for widget in sub_frame.winfo_children():
            widget.destroy()
        frame2.grid_forget()
        frame2.pack_forget()
        for widget in frame2.winfo_children():
            widget.destroy()

        executeUploadGui(frame, sub_frame, upload_chosen_dict)

    button_run = Button(frame2, text='开始', command=click_run)
    button_run.grid(row=3, column=2, columnspan=4, sticky=constants.W + constants.E, pady=10)

    def click_back():
        # 先清理再跳转
        frame.grid_forget()
        frame.pack_forget()
        frame2.grid_forget()
        frame2.pack_forget()
        clear_constants()
        initGui()

    button_back = Button(frame2, text='返回', command=click_back)
    button_back.grid(row=3, column=0, columnspan=2, sticky=constants.W + constants.E, pady=10, padx=5)


def executeUploadGui(frame, sub_frame, upload_chosen_dict):
    global read_path
    # 修改UI
    frame3 = Frame(window, relief=constants.GROOVE, bd=0)
    frame3.pack(side=constants.BOTTOM, fill=constants.X, expand=constants.TRUE)

    upload_index = 0
    for root, img_list in upload_chosen_dict.items():
        name_label = Label(sub_frame, text=root[len(path.dirname(read_path)) + 1:], width=45, anchor=constants.W,
                           compound=constants.LEFT, bg="white")
        name_label.grid(column=0, columnspan=3, row=upload_index, sticky=constants.W)
        # 初始化 - 修改GUI界面
        progress_text = f'0/{len(img_list)}'
        progress_label = Label(sub_frame, text=progress_text, width=12, anchor=constants.CENTER, fg='black', bg='white')
        progress_label.grid(column=4, row=upload_index)
        upload_progress_text_dict[root] = progress_label

        # 用于填充白色
        Label(sub_frame, bg="white").grid(row=upload_index, column=10, sticky=constants.EW, ipadx=win_width)

        upload_index += 1

    # 设置进度条
    global progressbar
    global progressbar_percent

    progressbar_percent = Label(frame3, text="0%", font=("Arial Bold", 10))
    progressbar_percent["text"] = "0%"
    progressbar_percent.pack(side=constants.TOP, pady=(0, 0))
    # progressbar = Progressbar(window, length=200, mode="determinate", maximum=100, name="完成进度",
    #                           orient=constants.HORIZONTAL, value=0, variable=0)
    progressbar = Progressbar(frame3, length=200, mode="determinate", maximum=100, name="完成进度",
                              orient=constants.HORIZONTAL, value=0, variable=0)
    progressbar.pack(side=constants.TOP, fill=constants.X, pady=(0, 12), padx=5)

    progressbar["value"] = 0
    progressbar_percent.pack(side=constants.TOP, fill=constants.X, pady=(0, 12))
    progressbar_percent["text"] = "0%"
    progressbar_percent.pack(side=constants.TOP, pady=(12, 0))

    # 日志按钮
    global logfile_name
    logfile_name = f'Upload_{int(time.time())}.log'

    def open_log():
        startfile(path.join(read_path, logfile_name))

    # button_log = Button(window, text='查看日志', width=15, state=constants.NORMAL, command=open_log)
    button_log = Button(frame3, text='查看日志', state=constants.NORMAL, width=25, command=open_log)
    button_log.pack(side=constants.LEFT, fill=constants.X, anchor=constants.CENTER, padx=5)

    # 运行按钮
    def jump_init():
        # 先清理再跳转
        frame.pack_forget()
        frame3.pack_forget()
        frame.grid_forget()
        frame3.grid_forget()
        clear_constants()
        startUploadGui()

    global button_running
    # button_running = Button(window, text='运行中...', width=15, state=constants.NORMAL)
    button_running = Button(frame3, text='运行中...', state=constants.NORMAL, width=25, command=jump_init)
    button_running["state"] = constants.DISABLED
    button_running.pack(side=constants.RIGHT, fill=constants.X, anchor=constants.CENTER, padx=5)

    args = [access_token, upload_chosen_dict]
    th = Thread(target=executeUpload, args=(args))
    th.setDaemon(True)
    th.start()


def executeUpload(access_token, upload_chosen_dict):
    # access_token = args[0]
    # upload_chosen_dict = args[1]
    global lock
    global upload_img_complete_num
    global upload_progress_text_dict
    # tags = "大类ID,小类ID"    brief = {"name": "食材名称", "id": UUID}

    url = "https://aip.baidubce.com/rest/2.0/image-classify/v1/realtime_search/similar/add?access_token=" + access_token

    with open(path.join(read_path, logfile_name), 'w', encoding='utf-8') as log:
        log.buffer.write(f'任务开始 -- {strftime("%Y-%m-%d %H:%M:%S", localtime())} 
'.encode())
        log.buffer.write(f'上传文件夹为: [{upload_chosen_dict.keys()}]  
'.encode())

    # 选择文件夹
    def uploadImg():
        total_task_num = 0
        for value in upload_chosen_dict.values():
            total_task_num += len(value)

        for root, img_list in upload_chosen_dict.items():
            # 开始执行 - 进度文字改为橙色
            global upload_progress_text_dict
            progress_label = upload_progress_text_dict.get(root)
            progress_label['fg'] = 'orange'

            fclass, sclass, name = path.basename(root).split('-')
            for img_name in img_list:
                try:
                    img = open(path.join(root, img_name), "rb")
                    image = str(b64encode(img.read()), 'utf-8')
                    # brief = '{"name":"' + name + '","id":"' + img_name.split('.')[0] + '"}'
                    brief = f'{name}'
                    tags = f'{fclass},{sclass}'
                    payload = f'image={quote(image)}&brief={quote(brief)}&tags={quote(tags)}'
                    headers = {'Content-Type': 'application/x-www-form-urlencoded'}
                    response = request("POST", url, headers=headers, data=payload)
                    if response.status_code != 200:
                        with open(path.join(read_path, logfile_name), 'a', encoding='utf-8') as log:
                            log.buffer.write(
                                f'上传图片失败 [{path.join(root, img_name)}]  状态码[{response.status_code}] 原因[{response.reason}]  
'.encode())
                            progress_label = upload_progress_text_dict.get(root)
                            progress_label['fg'] = 'red'
                    else:
                        with open(path.join(read_path, logfile_name), 'a', encoding='utf-8') as log:
                            log.buffer.write(
                                f'上传图片成功 [{path.join(root, img_name)}]  状态码[{response.status_code}] 原因[{response.reason}]  
'.encode())
                            progress_label = upload_progress_text_dict.get(root)

                    (success_num, complete_num) = upload_img_complete_num.get(root, (0, 0))
                    success_num = success_num + 1
                except Exception as exception:
                    logger.error(f"Error: {exception}")
                    with open(path.join(read_path, logfile_name), 'a', encoding='utf-8') as log:
                        log.buffer.write(f'上传图片失败 [{path.join(root, img_name)}]   原因[{repr(exception)}  
]'.encode())
                    progress_label = upload_progress_text_dict.get(root)
                    progress_label['fg'] = 'red'
                    (success_num, complete_num) = keyword_urls_complete_num.get(root, (0, 0))

                complete_num += 1
                upload_img_complete_num[root] = (success_num, complete_num)

                progress_label['text'] = f'{success_num}/{len(upload_chosen_dict[root])}'

                success_num
                if success_num == len(upload_chosen_dict[root]):
                    progress_label['fg'] = 'green'

                # 修改进度条
                complete_task_num = 0
                for value in upload_img_complete_num.values():
                    complete_task_num += value[1]
                progressbar_percent['text'] = str(round(100 * complete_task_num / total_task_num)) + '%'
                progressbar['value'] = 100 * complete_task_num / total_task_num

    uploadImg()

    global button_running
    button_running['text'] = '完成'
    button_running["state"] = constants.NORMAL

    with open(path.join(read_path, logfile_name), 'a', encoding='utf-8') as log:
        log.buffer.write(f'任务完成 -- {strftime("%Y-%m-%d %H:%M:%S", localtime())} 
'.encode())


def startDownloadGui():
    global keywords
    global cnt_start
    global cnt_end
    global win_width
    global win_height
    global save_path
    global max_sleep_ms
    global thread_num
    win_width = 550
    win_height = 170
    # g_screenwidth = int((window.winfo_screenwidth() - win_width) / 2)
    # g_screenheight = int((window.winfo_screenheight() - win_height) / 2)
    window.geometry(f"{win_width}x{win_height}")

    frame = Frame(window, relief=constants.GROOVE, bd=0)
    frame.pack(side=constants.TOP, fill=constants.BOTH, expand=constants.TRUE)

    # 第一行
    lbl0 = Label(frame, text='输入关键字:')
    lbl0.grid(row=0, column=0)
    var00 = StringVar()
    var00.set('')
    if keywords is not None:
        var00.set(keywords)
    entry_keyword = Entry(frame, width=30, textvariable=var00)
    entry_keyword.grid(row=0, column=1, columnspan=5, sticky=constants.W + constants.E)
    entry_keyword.focus()

    # 第二行
    lbl10 = Label(frame, text='开始位置:')
    lbl10.grid(row=1, column=0, sticky=constants.E)
    var10 = IntVar()
    var10.set(1)
    if cnt_start is not None:
        var10.set(cnt_start)
    spin_start = Spinbox(frame, from_=0, to=10000, textvariable=var10)
    spin_start.grid(row=1, column=1, columnspan=2, sticky=constants.W + constants.E)
    lbl11 = Label(frame, text='结束位置:')
    lbl11.grid(row=1, column=3, sticky=constants.E)
    var01 = IntVar()
    var01.set(20)
    if cnt_start is not None:
        var01.set(cnt_end)
    spin_end = Spinbox(frame, from_=0, to=10000, textvariable=var01)
    spin_end.grid(row=1, column=4, columnspan=2, sticky=constants.W + constants.E)

    # 第三行
    lbl20 = Label(frame, text='保存路径:')
    lbl20.grid(row=2, column=0, sticky=constants.E)
    var20 = StringVar()
    var20.set(path.abspath('.'))
    if save_path is not None:
        var20.set(save_path)
    entry_path = Entry(frame, width=42, textvariable=var20)
    entry_path.grid(row=2, column=1, columnspan=4, sticky=constants.W + constants.E)

    def click_path():
        file = askdirectory(initialdir=path.abspath('.'))
        var20.set(file)

    button = Button(frame, text='选择路径', command=click_path)
    button.grid(row=2, column=5, sticky=constants.E)

    # 第四行
    lbl30 = Label(frame, text='睡眠(ms):')
    lbl30.grid(row=3, column=0, sticky=constants.E)
    var30 = IntVar()
    var30.set(500)
    if max_sleep_ms is not None:
        var30.set(max_sleep_ms)
    spin_max_sleep_ms = Spinbox(frame, from_=0, to=10000, textvariable=var30)
    spin_max_sleep_ms.grid(row=3, column=1, columnspan=2, sticky=constants.W + constants.E)
    lbl31 = Label(frame, text='线程数:')
    lbl31.grid(row=3, column=3, sticky=constants.E)
    var31 = IntVar()
    var31.set(8)
    if thread_num is not None:
        var31.set(thread_num)
    spin_thread_num = Spinbox(frame, from_=0, to=10000, textvariable=var31)
    spin_thread_num.grid(row=3, column=4, columnspan=2, sticky=constants.W)

    # 第五行
    def click_run():
        global cnt_start
        global cnt_end
        global save_path
        global keywords
        global max_sleep_ms
        global thread_num

        keywords = entry_keyword.get()
        save_path = entry_path.get()

        # 对参数进行校验
        if entry_keyword.get() == '':
            messagebox.showinfo("提示", "请输入搜索关键词")
            return
        if not path.exists(save_path):
            messagebox.showinfo("提示", "该路径不存在")
            return
        try:
            cnt_start = int(spin_start.get())
            cnt_end = int(spin_end.get())
            max_sleep_ms = int(spin_max_sleep_ms.get())
            thread_num = int(spin_thread_num.get())
        except Exception as exception:
            messagebox.showinfo("提示", "信息需要填写整数")
            return

        # 先清理再跳转
        frame.grid_forget()
        frame.pack_forget()
        clear_constants()
        execDownloadGui()

    button_run = Button(frame, text='开始', command=click_run)
    button_run.grid(row=4, column=2, columnspan=4, sticky=constants.W + constants.E, pady=10, padx=5)

    def click_back():
        # 先清理再跳转
        frame.grid_forget()
        frame.pack_forget()
        clear_constants()
        initGui()

    button_back = Button(frame, text='返回', command=click_back)
    button_back.grid(row=4, column=0, columnspan=2, sticky=constants.W + constants.E, pady=10, padx=5)


def execDownloadGui():
    global win_width
    global win_height
    win_width = 502
    win_height = 480
    # g_screenwidth = int((window.winfo_screenwidth() - win_width) / 2)
    # g_screenheight = int((window.winfo_screenheight() - win_height) / 2)
    window.geometry(f"{win_width}x{win_height}")

    frame = Frame(window, relief=constants.GROOVE, bd=0)
    frame.pack(side=constants.TOP, fill=constants.BOTH, expand=constants.TRUE)

    frame2 = Frame(window, relief=constants.GROOVE, bd=0)
    frame2.pack(side=constants.BOTTOM, fill=constants.X, expand=constants.TRUE)
    # 新建字典，存储文件名和label
    files_label_dict = {}

    # 为了滚动条创建画布
    canvas = Canvas(frame)
    # canvas.grid(column=0, row=0, sticky=constants.NSEW)
    canvas.pack(side=constants.LEFT, fill=constants.BOTH, expand=constants.TRUE)

    sub_frame = Frame(canvas, bg="white")
    # sub_frame.grid(column=1, row=0, sticky=constants.NSEW)
    sub_frame.pack(side=constants.TOP, fill=constants.BOTH, expand=constants.TRUE)

    # 窗口展示的是frame的左上角
    canvas.create_window(0, 0, window=sub_frame, anchor=constants.NW)

    # 为最外层的Frame创建滚动条，用于滚动画布中的元素
    scrollV = Scrollbar(frame, orient=constants.VERTICAL, command=canvas.yview)
    # scrollV.grid(column=1, row=0, sticky=constants.NSEW)
    scrollV.pack(side=constants.RIGHT, fill=constants.Y)

    def scroll_bar(event):
        canvas.configure(yscrollcommand=scrollV.set, scrollregion=canvas.bbox("all"))

    def process_wheel(event):
        canvas.yview_scroll(-1 * (round(event.delta / 60)), "units")

    # 绑定滚动条
    sub_frame.bind("<Configure>", scroll_bar)
    # 绑定滚轮事件
    sub_frame.bind("<MouseWheel>", process_wheel)

    # 添加进度条
    global progressbar_percent
    global progressbar
    # progressbar_percent = Label(window, text="0%", font=("Arial Bold", 10))
    progressbar_percent = Label(frame2, text="0%", font=("Arial Bold", 10))
    progressbar_percent["text"] = "0%"
    progressbar_percent.pack(side=constants.TOP, pady=(0, 0))
    progressbar = Progressbar(frame2, length=200, mode="determinate", maximum=100, name="完成进度",
                              orient=constants.HORIZONTAL, value=0, variable=0)
    progressbar.pack(side=constants.TOP, fill=constants.X, pady=(0, 12), padx=5)

    # 日志按钮
    def open_log():
        startfile(path.join(save_path, 'Imgs', logfile_name))

    # button_log = Button(window, text='查看日志', width=15, state=constants.NORMAL, command=open_log)
    button_log = Button(frame2, text='查看日志', state=constants.NORMAL, width=25, command=open_log)
    button_log.pack(side=constants.LEFT, fill=constants.X, anchor=constants.CENTER, padx=5)

    # 运行按钮
    def jump_init():
        # 先清理再跳转
        frame.pack_forget()
        frame2.pack_forget()
        frame.grid_forget()
        frame2.grid_forget()
        clear_constants()
        startDownloadGui()

    global button_running
    # button_running = Button(window, text='运行中...', width=15, state=constants.NORMAL)
    button_running = Button(frame2, text='运行中...', state=constants.NORMAL, width=25, command=jump_init)
    button_running["state"] = constants.DISABLED
    button_running.pack(side=constants.RIGHT, fill=constants.X, anchor=constants.CENTER, padx=5)

    # 执行任务
    for index, keyword in enumerate(keywords.split(';')):
        name_label = Label(sub_frame, text=keyword, width=40, anchor=constants.W, compound=constants.LEFT, bg="white")
        name_label.grid(column=0, row=index, sticky=constants.W)
        # 初始化 - 修改GUI界面
        progress_text = f'0/{cnt_end - cnt_start + 1}'
        progress_label = Label(sub_frame, text=progress_text, width=12, anchor=constants.CENTER, fg='black', bg='white')
        progress_label.grid(column=5, row=index)
        global keyword_progress_text
        keyword_progress_text[keyword] = progress_label

    th = Thread(target=executeDownload, args=())
    th.setDaemon(True)
    th.start()

    # 写入日志
    global logfile_name
    logfile_name = f'Download_{int(time.time())}.log'
    logger.info("=" * 15 + f" 任 务 开 始 ({str(datetime.now())}) " + "=" * 15)

    imgs_path = path.join(save_path, 'Imgs')
    if not path.exists(imgs_path):
        mkdir(imgs_path)
    with open(path.join(save_path, 'Imgs', logfile_name), 'w', encoding='utf-8') as log:
        log.buffer.write(f'任务开始 -- {strftime("%Y-%m-%d %H:%M:%S", localtime())} 
'.encode())
        log.buffer.write(f'关键字为: [{keywords}]   范围为: [{cnt_start}-{cnt_end}] 
'.encode())


def executeDownload():
    with ThreadPoolExecutor(max_workers=8) as executor:
        def getImgUrls(keyword):
            # logger.info(f'正在处理：{file}')

            keyword = keyword[0]
            # 开始执行 - 进度文字改为蓝色
            global keyword_progress_text
            progress_label = keyword_progress_text.get(keyword)
            progress_label['fg'] = 'orange'

            keyword_url_encode = quote(keyword)
            web_url = search_ori_url + keyword_url_encode

            # 爬虫程序
            try:
                # 打开chrome无头浏览器
                edge_options = Options()
                edge_options.add_argument('--headless')
                edge_options.add_argument('--disable-gpu')

                # 反侦测，开启开发者模式
                edge_options.add_experimental_option('excludeSwitches', ['enable-automation'])
                # 禁用启动Blink运行时功能
                edge_options.add_argument('--disable-blink-features=AutomationControlled')
                driver = webdriver.Edge(options=edge_options)
                executor_url = driver.command_executor._url
                session_id = driver.session_id

                # 将打开的浏览区url和session_id存储起来，提供给下一次应用
                # file = open('browserMsg.txt', 'w')
                # file.writelines([executor_url, 'n', session_id])
                # file.close()
                driver.implicitly_wait(20)
                driver.set_window_size(1000, 800)

                driver.get(web_url)

                # 如果图片数量不够，则向下滚动一页
                current_num = 0

                img_urls = []
                while current_num < int(cnt_end):
                    elements = driver.find_elements(by=By.CLASS_NAME, value='main_img.img-hover')
                    print('获取到' + keyword + '元素个数为 ', len(elements), '  线程号为:' + str(os.getpid()))
                    current_num = len(elements)
                    if current_num < cnt_end:
                        # js = 'return document.body.scrollHeight;'
                        driver.execute_script('window.scrollTo(0, document.body.scrollHeight)')
                        # time.sleep(random.randint(1, 5) / 10)
                    else:
                        for element in elements:
                            img_urls.append(element.get_attribute('data-imgurl'))

                img_urls = img_urls[cnt_start - 1:cnt_end]

                return keyword, img_urls
            except Exception as exception:
                # traceback.print_exc()
                logger.error(f"Error: {exception}")
                with open(path.join(save_path, 'Imgs', logfile_name), 'a', encoding='utf-8') as log:
                    log.buffer.write(f'Error: 爬取图片失败 [{keyword}] 错误信息 [{repr(exception)}] 
'.encode())
                # 爬取页面失败，进度文字改为红色
                progress_label = keyword_progress_text.get(keyword)
                progress_label['fg'] = 'red'

        def downloadImgs(future):
            keyword, img_urls = future.result()

            def downloadImg(args3):
                keyword, img_url, index = args3
                imgs_path = path.join(save_path, 'Imgs')
                if not path.exists(imgs_path):
                    mkdir(imgs_path)
                if not path.exists(path.join(imgs_path, keyword)):
                    mkdir(path.join(imgs_path, keyword))

                img_name = f'{uuid4().hex}.png'
                img_abspath = path.join(path.join(imgs_path, keyword), img_name)

                # 添加异常处理
                global lock
                global keyword_urls_complete_num
                global keyword_progress_text
                try:
                    # TODO 设置睡眠时间
                    # time.sleep(random.randint(1, 5) / 10)
                    print(f'关键字:[{keyword}]  序号:[{index + 1}]  网址:{img_url}')
                    urlretrieve(img_url, img_abspath)

                    # 设置公共变量词典，key为keyword，value为tuple类型，存储 (成功数,处理数)
                    lock.acquire()
                    (success_num, complete_num) = keyword_urls_complete_num.get(keyword, (0, 0))
                    success_num = success_num + 1
                except Exception as exception:
                    # traceback.print_exc()
                    logger.error(f"Error: {exception}")
                    with open(path.join(save_path, 'Imgs', logfile_name), 'a', encoding='utf-8') as log:
                        log.buffer.write(f'Error: 图片下载失败 [{keyword}] [{img_url}] 错误信息 {repr(exception)} 
'.encode())
                    # 下载图片失败 - 修改进度文字颜色为红色
                    progress_label = keyword_progress_text.get(keyword)
                    progress_label['fg'] = 'red'
                    (success_num, complete_num) = keyword_urls_complete_num.get(keyword, (0, 0))

                # 修改
                complete_num = complete_num + 1
                keyword_urls_complete_num[keyword] = (success_num, complete_num)

                # 执行中 - 修改进度文字文本
                progress_label = keyword_progress_text.get(keyword)
                progress_label['text'] = f'{success_num}/{cnt_end - cnt_start + 1}'

                lock.release()

                if success_num == cnt_end - cnt_start + 1:
                    progress_label['fg'] = 'green'

                # 修改进度条
                complete_task_num = 0
                for value in keyword_urls_complete_num.values():
                    complete_task_num += value[1]
                total_task_num = len(keyword_progress_text.keys()) * (cnt_end - cnt_start + 1)
                progressbar_percent["text"] = str(round(100 * complete_task_num / total_task_num)) + "%"
                progressbar["value"] = 100 * complete_task_num / total_task_num

                with open(path.join(save_path, 'Imgs', logfile_name), 'a', encoding='utf-8') as log:
                    log.buffer.write(f'Success: 处理完成 关键字:[{keyword}]  序号:[{index + 1}]  网址:{img_url} 
'.encode())

            global thread_num
            with ThreadPoolExecutor(max_workers=thread_num) as executor2:
                for index, img_url in enumerate(img_urls):
                    global max_sleep_ms
                    time.sleep(random.randint(1, max_sleep_ms) / 1000)
                    args3 = [keyword, img_url, index]
                    executor2.submit(downloadImg, args3)
                # downloadImg(keyword,img_url)

        for keyword in keywords.split(';'):
            args = [keyword]
            get_url_task = executor.submit(getImgUrls, args)
            get_url_task.add_done_callback(downloadImgs)

        # # 通过回调add_done_callback来处理结果
        # for index, img_url in enumerate(img_urls):
        #     args = [keyword, img_url]
        #     tasks = executor.submit(downloadImgs, args)

    global button_running
    button_running['text'] = '完成'
    button_running["state"] = constants.NORMAL

    with open(path.join(save_path, 'Imgs', logfile_name), 'a', encoding='utf-8') as log:
        log.buffer.write(f'任务完成 -- {strftime("%Y-%m-%d %H:%M:%S", localtime())} 
'.encode())


if __name__ == '__main__':
    basicConfig(level="INFO")
    logger = getLogger()

    # 下载功能的全局变量
    search_ori_url = f'https://image.baidu.com/search/index?tn=baiduimage&ie=utf-8&word='
    save_path = None
    cnt_start = 1
    cnt_end = 20
    keywords = None
    keyword_urls_complete_num = {}
    keyword_progress_text = {}
    thread_num = 10
    max_sleep_ms = 500

    # 上传功能的全局变量
    read_path = None
    all_dir_dict = {}
    upload_select_dict = {}
    upload_progress_text_dict = {}
    upload_img_complete_num = {}
    username = ''
    password = ''
    access_token = None
    img_type_list = {'jpg', 'bmp', 'png', 'jpeg', 'jfif', 'webp'}

    # 公共全局变量
    lock = Lock()
    logfile_name = ''
    button_running = None
    progressbar = None
    progressbar_percent = None

    # 引入图片
    bundle_dir = getattr(sys, '_MEIPASS', path.abspath(path.dirname(__file__)))
    path_to_icon = path.join(bundle_dir, 'ppicon')

    window = Tk()
    window.title("Tool For PaddlePaddle                                      Authored By CJ")

    img_eye_open = PhotoImage(Image.open(path_to_icon + "/eye_open.png").resize((16, 16)))
    img_eye_close = PhotoImage(Image.open(path_to_icon + "/eye_close.png").resize((16, 16)))

    # startDownloadGui()
    win_width = 550
    win_height = 140
    g_screenwidth = int((window.winfo_screenwidth() - win_width) / 2)
    g_screenheight = int((window.winfo_screenheight() - win_height) / 2)
    window.geometry(f"{win_width}x{win_height}+{g_screenwidth}+{g_screenheight}")
    window.iconbitmap(path_to_icon + '/favicon.ico')

    try:
        initGui()
    except Exception as e:
        messagebox.showinfo("提示", str(e))

    window.mainloop()
```
>需要将 edge的无头浏览器(msedgedriver.exe) 程序放到系统路径中

**打包**
安装打包工具 `pip install `
`pyinstaller -F -w -i C:\Users\CJ\Downloads\python_downimg-master