---
title: Pandas数据展示
categories:
- Python
---
inplace=True 表示会对原式数据进行修改

###一、创建表格
>#####创建普通数据集
>s = pd.Series([1, 3, 6, np.nan, 44, 1])  # 创建一个包含指定元素的数据集
**结果：**
s：
0     1.0
1     3.0
2     6.0
3     NaN
4    44.0
5     1.0
dtype: float64

>#####创建日期数据集
>dates = pd.date_range('20200101', periods=6)  # 创建一个从20200101开始的连续六天日期的数据集
**结果：**
dates：
DatetimeIndex(['2020-01-01', '2020-01-02', '2020-01-03', '2020-01-04',
               '2020-01-05', '2020-01-06'],
              dtype='datetime64[ns]', freq='D')


>#####不指定行列，创建表格
>df1 = pd.DataFrame(np.arange(12).reshape(3, 4))  # 不指定行列，默认为[0,1,2,...]
**结果：**
df1：
>```excel
>    0  1   2   3
>0  0  1   2   3
>1  4  5   6   7
>2  8  9  10  11
>```

>#####指定行列，创建表格
>df2 = pd.DataFrame(np.random.randn(6, 4), index=dates, columns=['a', 'b', 'c', 'd'])  #创建一个以dates数组为行索引，columns数组为列的，元素是6*4的随机数的表格
df3 = pd.DataFrame({'A': 1., 'B': pd.Timestamp('20200101'), 'C': pd.Series(1, index=list(range(4)), dtype='float32'),
                    'D': np.array([3] * 4, dtype='int32'), 'E': pd.Categorical(['test', 'train', 'test', 'train']),
                    'F': 'foo'})  * 指定行列元素创建表格
**结果：**
df2：
>```excel
>                   a         b         c         d
>2020-01-01 -0.228392  0.077015  0.537306  0.280577
>2020-01-02 -0.397267 -0.745263  0.824229  0.573031
>2020-01-03 -1.336801  1.184091  0.126590 -0.094719
>2020-01-04 -1.297588 -1.125798  1.737450 -0.140771
>2020-01-05  1.030765 -0.113649  0.006699  0.671004
>2020-01-06 -0.516947  0.156746  0.253333 -1.554820
>```
>df3：
>```excel
>     A          B    C  D      E    F
>0  1.0 2020-01-01  1.0  3   test  foo
>1  1.0 2020-01-01  1.0  3  train  foo
>2  1.0 2020-01-01  1.0  3   test  foo
>3  1.0 2020-01-01  1.0  3  train  foo
>```


>#####获取表格的基本信息
>print(df3.dtypes)  # 获取表格的每列的元素类型
print(df3.index)  # 获取表格的列
print(df3.columns)  # 获取表格的行
print(df3.describe())  # 对表格中的数据进行分析(求总数，和，平均数，最大最小值等)
**结果：**
***df3.dtypes：***
A           float64
B    datetime64[ns]
C           float32
D             int32
E          category
F            object
>dtype: object
>
>***df3.index：***
Int64Index([0, 1, 2, 3], dtype='int64')
>
>***df3.columns：***
Index(['A', 'B', 'C', 'D', 'E', 'F'], dtype='object')
>
>***df3.describe()：***
A           float64
B    datetime64[ns]
C           float32
D             int32
E          category
F            object
dtype: object



>#####对表格的基本操作
>print(df3.T)  # 可以对表格进行转置
print(df3.sort_index(axis=0,ascending=True))  # 根据行索引的名称进行顺序排序
print(df3.sort_index(axis=1,ascending=False))  # 根据列索引的名称对列进行倒序排序
print(df3.sort_values(by='E'))  # 根据列索引为'E'的列中的元素进行顺序排序
**结果：**
***df3.T：***
>```excel
>                     0  ...                    3
>A                    1  ...                    1
>B  2020-01-01 00:00:00  ...  2020-01-01 00:00:00
>C                    1  ...                    1
>D                    3  ...                    3
>E                 test  ...                train
>F                  foo  ...                  foo
>```
>[6 rows x 4 columns]
>***df3.sort_index(axis=0,ascending=True)：***
>```excel
>     A          B    C  D      E    F
>0  1.0 2020-01-01  1.0  3   test  foo
>1  1.0 2020-01-01  1.0  3  train  foo
>2  1.0 2020-01-01  1.0  3   test  foo
>3  1.0 2020-01-01  1.0  3  train  foo
>```
>***df3.sort_index(axis=1,ascending=False)：***
>```excel
>     F      E  D    C          B    A
>0  foo   test  3  1.0 2020-01-01  1.0
>1  foo  train  3  1.0 2020-01-01  1.0
>2  foo   test  3  1.0 2020-01-01  1.0
>3  foo  train  3  1.0 2020-01-01  1.0
>```
>***df3.sort_values(by='E')：***
>```excel
>     A          B    C  D      E    F
>0  1.0 2020-01-01  1.0  3   test  foo
>2  1.0 2020-01-01  1.0  3   test  foo
>1  1.0 2020-01-01  1.0  3  train  foo
>3  1.0 2020-01-01  1.0  3  train  foo
>```


###二、截取表格
>#####截取表格
>print(df3[0:3],df3.A)  #获取表格中行索引从0到3，列索引为A的元素
>***①根据行列索引名称进行选择***
>print(df3.loc[1])  # 获取表格中的行索引为'1'的子表格
print(df3.loc[1:3, ['A', 'B']])  # 获取表格中的行索引为1到3，列索引为'A'和'B'的子表格。
>***②根据行列索引序号进行选择***
print(df3.iloc[1])  # 获取表格中的行顺序为1(从0开始)的子表格
print(df3.iloc[1:3,0:2])  # 获取表格中的行顺序为1到3，列顺序为0到2的子表格
>***③根据元素大小进行筛选***
print(df3[df3.A >= 1])  # 获取表格中A列中元素大于等于1的所有行组成的子表格
>***④使用条件表达式筛选***
>df.loc[lambda df : (df["bWendu"]<=30) & (df["yWendu"]) >=15), :]
>***⑤使用函数筛选***
>```py
>def query_my_data(df):
>  return df.index.str.startswith("2018-09") & df["aqiLevel"]==1
>df.loc[query_my_data, :]
>```

>
>**结果：**
>***df3[0:3],df3.A：***
>```excel
>     A          B    C  D      E    F
>0  1.0 2020-01-01  1.0  3   test  foo
>1  1.0 2020-01-01  1.0  3  train  foo
>2  1.0 2020-01-01  1.0  3   test  foo 0    1.0
>1    1.0
>2    1.0
>3    1.0
>Name: A, dtype: float64
>```
>***df3.loc[1]：***
>```excel
>A                      1
>B    2020-01-01 00:00:00
>C                      1
>D                      3
>E                  train
>F                    foo
>Name: 1, dtype: object
>```
>***df3.loc[1:3, ['A', 'B']]：***
>```excel
>     A          B
>1  1.0 2020-01-01
>2  1.0 2020-01-01
>3  1.0 2020-01-01
>```
>***df3.iloc[1]***
>```excel
>A                      1
>B    2020-01-01 00:00:00
>C                      1
>D                      3
>E                  train
>F                    foo
>Name: 1, dtype: object
>```
>***df3.iloc[1:3,0:2]***
>```excel
>     A          B
>1  1.0 2020-01-01
>2  1.0 2020-01-01
>```
>***df3[df3.A >= 1]***
>```excel
>     A          B    C  D      E    F
>0  1.0 2020-01-01  1.0  3   test  foo
>1  1.0 2020-01-01  1.0  3  train  foo
>2  1.0 2020-01-01  1.0  3   test  foo
>3  1.0 2020-01-01  1.0  3  train  foo
>```

<br>
### 新增列
①方式一：
```
# 新增一列，值是最高温度减去最低温度
df.loc[:, "wencha"] = df["bWendu"] - df["yWendu"]
```
②方式二：
使用apply函数，axis = 1表示是列，axis=0表示是行
```
def get_wendu_type(x):
  if x["bWendu"] > 33:
    return "高温"
  if x["yWendu"] < -10:
    return "低温"
df.loc[:, "wendu_type"] = df.apply(get_wendu_type, axis = 1) # 根据温度判断是高温还是低温并添加为新的列
```
查看温度类型计数
df["wendu_type"].value_counts()

③方法三：
assign函数会保留原来的列，将得到的新列插入到矩阵中
```
df.assign(
  # 摄氏温度转华氏温度
  yWendu_huashi = lambda x : x["yWendu"] * 9 / 5 + 32,
  bWendu_huashi = lambda x : x["bWendu"] * 9 / 5 + 32
)
```


<br>
### 常用函数
mean、min、max
**①unique唯一性去重**
df["fengxiang"].unique()
**②value_counts按值计数**
df["fengxiang"].value_counts()
**③corr相关系数和cov协方差**
df["aqi"].cov(df["bWendu"])  #协方差矩阵
df["aqi"].corr(df["yWendu"])  #相关系数矩阵


<br>
###三、修改表格中的值

>#####修改表格中的值
>***指定索引位置修改值***
①df4.loc['20200102', 'B'] = 1111  # 将行索引为20200102，列索引为B的元素的值改为1111
>②df4.iloc[2, 2] = 2222  # 将行列位置为2，2的元素的值改为2222
***修改满足条件的元素的值***
③df4[df4.A > 10] = 3333  # 修改A列元素大于10的行的所有元素修改为3333
④df4.A[df4.A > 10] = 4444  # 修改A列元素大于10的所有元素为4444
***添加或修改列***
⑤df4['F'] = np.nan  # 添加或修改F列元素为nan
⑥df4['E'] = pd.Series([1,2,3,4,5,6],index=[pd.Timestamp('20200103'),pd.Timestamp('20200101'),pd.Timestamp('20200102'),pd.Timestamp('20200105'),pd.Timestamp('20200106'),pd.Timestamp('20200104')])
**结果：**
>①
>```excel
>             A     B   C   D
>2020-01-01   0     1   2   3
>2020-01-02   4  1111   6   7
>2020-01-03   8     9  10  11
>2020-01-04  12    13  14  15
>2020-01-05  16    17  18  19
>2020-01-06  20    21  22  23
>```
>②
>```excel
>             A     B     C   D
>2020-01-01   0     1     2   3
>2020-01-02   4  1111     6   7
>2020-01-03   8     9  2222  11
>2020-01-04  12    13    14  15
>2020-01-05  16    17    18  19
>2020-01-06  20    21    22  23
>```
>③
>```excel
>               A     B     C     D
>2020-01-01     0     1     2     3
>2020-01-02     4  1111     6     7
>2020-01-03     8     9  2222    11
>2020-01-04  3333  3333  3333  3333
>2020-01-05  3333  3333  3333  3333
>2020-01-06  3333  3333  3333  3333
>```
>④
>```excel
>               A     B     C     D
>2020-01-01     0     1     2     3
>2020-01-02     4  1111     6     7
>2020-01-03     8     9  2222    11
>2020-01-04  4444  3333  3333  3333
>2020-01-05  4444  3333  3333  3333
>2020-01-06  4444  3333  3333  3333
>```
>⑤
>```excel
>               A     B     C     D   F
>2020-01-01     0     1     2     3 NaN
>2020-01-02     4  1111     6     7 NaN
>2020-01-03     8     9  2222    11 NaN
>2020-01-04  4444  3333  3333  3333 NaN
>2020-01-05  4444  3333  3333  3333 NaN
>2020-01-06  4444  3333  3333  3333 NaN
>```
>⑥
>```excel
>               A     B     C     D   F  E
>2020-01-01     0     1     2     3 NaN  2
>2020-01-02     4  1111     6     7 NaN  3
>2020-01-03     8     9  2222    11 NaN  1
>2020-01-04  4444  3333  3333  3333 NaN  6
>2020-01-05  4444  3333  3333  3333 NaN  4
>2020-01-06  4444  3333  3333  3333 NaN  5
>```

<br>
###四、处理丢失数据NaN
dates = pd.date_range('20200101',periods=6)
df5 = pd.DataFrame(data=np.arange(24).reshape(6,4),index=dates,columns=['A','B','C','D'])

df5.iloc[1,2] = np.nan
df5.iloc[2,3] = np.nan

>#####检查NaN值 （isnull和notnull）
>①print(df5.isna())  # 判断表格中的数据是否为NaN
print(df5.isnull())  # 同上
②print(np.any(df5.isnull() == True))  # 判断表中是否有NaN值
>**结果：**
①
>```excel
>                A      B      C      D
>2020-01-01  False  False  False  False
>2020-01-02  False  False   True  False
>2020-01-03  False  False  False   True
>2020-01-04  False  False  False  False
>2020-01-05  False  False  False  False
>2020-01-06  False  False  False  False
>```
>② True

>#####丢弃有NaN值的行 （dropna）
>①df5.dropna(axis=0,how='any',inplace=True)  # 有一个数据为NaN时丢弃该行(缺省为0和any)
>②print(df5.dropna(axis=1,how='all'))  # 所有数据为NaN时丢弃该列
>**结果：**
①
>```excel
>             A   B     C     D
>2020-01-01   0   1   2.0   3.0
>2020-01-04  12  13  14.0  15.0
>2020-01-05  16  17  18.0  19.0
>2020-01-06  20  21  22.0  23.0
>```
>②
>```excel
>             A   B     C     D
>2020-01-01   0   1   2.0   3.0
>2020-01-02   4   5   NaN   7.0
>2020-01-03   8   9  10.0   NaN
>2020-01-04  12  13  14.0  15.0
>2020-01-05  16  17  18.0  19.0
>2020-01-06  20  21  22.0  23.0
>```

>#####填充NaN （fillna）
>df5.fillna(value= -1) # 将所有为nan的值填充为-1
>df5['C'].fillna(0) # 将C列所有为nan的值填充为-1
>**结果：**
>```excel
>             A   B     C     D
>2020-01-01   0   1   2.0   3.0
>2020-01-02   4   5  -1.0   7.0
>2020-01-03   8   9  10.0  -1.0
>2020-01-04  12  13  14.0  15.0
>2020-01-05  16  17  18.0  19.0
>2020-01-06  20  21  22.0  23.0
>```
<br>
**使用前面的有效值进行填充，用ffill: forward fill**
studf.loc[:, '姓名'] = studf['姓名'].fillna(method="ffill")


<br>
###五、导入导出文件
read_csv/read_excel/read_hdf/read_sql/read_json/read_msgpack/read_html/read_gbq/read_stata/read_sas/read_clipboard/read_pickle

>#####导入文件
>grade = pd.read_csv("grade.csv",sikiprows=2)  # 如果放在同一目录下则直接写文件名，否则全路径或相对路径(sikiprows=2表示跳过头两行，从第三行开始读取)
print(grade)
>**结果：**
>```excel
>   id name  grade
>0   1   张三     88
>1   2   李四     90
>2   3   王五     78
>3   4   赵六     80
>4   5   田七     85
>```

>#####to_pickle导出文件
>grade.to_pickle('grade.pickle')
**结果：**
在同目录下生成grade.pickle文件

>to_excel保存为excel
studf.to_excel("./target.xlsx", index=False)

<br>
###六、合并表格
>#####列名称相同的表格合并（concat）
>A = pd.DataFrame(np.ones((3, 4)) * 0, columns=['a', 'b', 'c', 'd'])
B = pd.DataFrame(np.ones((3, 4)) * 1, columns=['a', 'b', 'c', 'd'])
C = pd.DataFrame(np.ones((3, 4)) * 2, columns=['a', 'b', 'c', 'd'])
vres = pd.concat([A,B,C],axis=0,ignore_index=True)  # 上下合并表格ABC，且重置行索引
hres = pd.concat([A,B,C],axis=1)  # 左右合并表格ABC
**结果：**
>```excel
>vres：
>    a    b    c    d
>0  0.0  0.0  0.0  0.0
>1  0.0  0.0  0.0  0.0
>2  0.0  0.0  0.0  0.0
>3  1.0  1.0  1.0  1.0
>4  1.0  1.0  1.0  1.0
>5  1.0  1.0  1.0  1.0
>6  2.0  2.0  2.0  2.0
>7  2.0  2.0  2.0  2.0
>8  2.0  2.0  2.0  2.0
>```
>hres：
>```excel
>    a    b    c    d    a    b    c    d    a    b    c    d
>0  0.0  0.0  0.0  0.0  1.0  1.0  1.0  1.0  2.0  2.0  2.0  2.0
>1  0.0  0.0  0.0  0.0  1.0  1.0  1.0  1.0  2.0  2.0  2.0  2.0
>2  0.0  0.0  0.0  0.0  1.0  1.0  1.0  1.0  2.0  2.0  2.0  2.0
>```

>#####部分列名相同的表格合并（concat）
>outerjoin = pd.concat([D, E], axis=0, join='outer')  # 进行上下合并，采用outer模式，保留所有数据，没有的数据用NaN代替
innerjoin = pd.concat([D, E], axis=0, join='inner')  # 进行上下合并，采用inner模式，保留公有的列数据
outerjoin2 = pd.concat([D, E], axis=1, join='outer')  # 进行左右合并采用outer模式
innerjoin2 = pd.concat([D, E], axis=1, join='inner')  # 采用inner模式，保留公有的列数据
leftjoin = pd.concat([D, E.reindex_like(D)], axis=1)  # 相当于左外链接
>**结果：**
>outerjoin：
>```excel
>     a    b    c    d    e
>1  0.0  0.0  0.0  0.0  NaN
>2  0.0  0.0  0.0  0.0  NaN
>3  0.0  0.0  0.0  0.0  NaN
>2  NaN  0.0  0.0  0.0  0.0
>3  NaN  0.0  0.0  0.0  0.0
>4  NaN  0.0  0.0  0.0  0.0
>```
>innerjoin：
>```excel
>     b    c    d
>1  0.0  0.0  0.0
>2  0.0  0.0  0.0
>3  0.0  0.0  0.0
>2  0.0  0.0  0.0
>3  0.0  0.0  0.0
>4  0.0  0.0  0.0
>```
>outerjoin2：
>```excel
>     a    b    c    d    b    c    d    e
>1  0.0  0.0  0.0  0.0  NaN  NaN  NaN  NaN
>2  0.0  0.0  0.0  0.0  0.0  0.0  0.0  0.0
>3  0.0  0.0  0.0  0.0  0.0  0.0  0.0  0.0
>4  NaN  NaN  NaN  NaN  0.0  0.0  0.0  0.0
>```
>innerjoin2：
>```excel
>     a    b    c    d    b    c    d    e
>2  0.0  0.0  0.0  0.0  0.0  0.0  0.0  0.0
>3  0.0  0.0  0.0  0.0  0.0  0.0  0.0  0.0
>```
>leftjoin：
>```excel
>     a    b    c    d   a    b    c    d
>1  0.0  0.0  0.0  0.0 NaN  NaN  NaN  NaN
>2  0.0  0.0  0.0  0.0 NaN  0.0  0.0  0.0
>3  0.0  0.0  0.0  0.0 NaN  0.0  0.0  0.0
>```

>#####使用append合并
>①D.append(E, ignore_index=True)  # 向表格D纵向附加表格E，表效果同concat
②D.append(series,ignore_index=True)  #  向表格D纵向附加Series
**结果：**
①
>```excel
>     a    b    c    d    e
>0  0.0  0.0  0.0  0.0  NaN
>1  0.0  0.0  0.0  0.0  NaN
>2  0.0  0.0  0.0  0.0  NaN
>3  NaN  0.0  0.0  0.0  0.0
>4  NaN  0.0  0.0  0.0  0.0
>5  NaN  0.0  0.0  0.0  0.0
>```
>②
>```excel
>     a    b    c    d
>0  0.0  0.0  0.0  0.0
>1  0.0  0.0  0.0  0.0
>2  0.0  0.0  0.0  0.0
>3  1.0  2.0  3.0  4.0
>```


<br>
###七、合并merge
left = pd.DataFrame({'key1': ['K0', 'K0', 'K1', 'K2'], 'key2': ['K0', 'K1', 'K0', 'K1'], 'A': ['A0', 'A1', 'A2', 'A3'],
                     'B': ['B0', 'B1', 'B2', 'B3']})
right = pd.DataFrame({'key1': ['K0', 'K1', 'K1', 'K2'], 'key2': ['K0', 'K0', 'K0', 'K0'], 'C': ['C0', 'C1', 'C2', 'C3'],
                      'D': ['D0', 'D1', 'D2', 'D3']})
```excel
  key1 key2   A   B
0   K0   K0  A0  B0
1   K0   K1  A1  B1
2   K1   K0  A2  B2
3   K2   K1  A3  B3
```
```excel
  key1 key2   C   D
0   K0   K0  C0  D0
1   K1   K0  C1  D1
2   K1   K0  C2  D2
3   K2   K0  C3  D3
```

>#####按列的元素进行合并（内/满外/左/右连接）
>①pd.merge(left, right, on=['key1', 'key2'],how='inner')  # 合并两个表格，将两表中key1和key2相同的行组成新表格。缺省是inner，可以使用inner，outer，left，right
②res3 = pd.merge(left, right, on=['key1', 'key2'],how='outer',indicator=True)  # 采用满外连接，同时使用indicator增加一列显示合并方式
③pd.merge(left, right, on=['key1', 'key2'],how='left')  # 采用左连接
④res3 = pd.merge(left, right, on=['key1', 'key2'],how='right')  # 采用右连接
>**结果：**
>①
>```excel
>  key1 key2   A   B   C   D
>0   K0   K0  A0  B0  C0  D0
>1   K1   K0  A2  B2  C1  D1
>2   K1   K0  A2  B2  C2  D2
>```
>②
>```excel
>  key1 key2    A    B    C    D      _merge
>0   K0   K0   A0   B0   C0   D0        both
>1   K0   K1   A1   B1  NaN  NaN   left_only
>2   K1   K0   A2   B2   C1   D1        both
>3   K1   K0   A2   B2   C2   D2        both
>4   K2   K1   A3   B3  NaN  NaN   left_only
>5   K2   K0  NaN  NaN   C3   D3  right_only
>```
>③
>```excel
>  key1 key2   A   B    C    D
>0   K0   K0  A0  B0   C0   D0
>1   K0   K1  A1  B1  NaN  NaN
>2   K1   K0  A2  B2   C1   D1
>3   K1   K0  A2  B2   C2   D2
>4   K2   K1  A3  B3  NaN  NaN
>```
>④
>```excel
>  key1 key2    A    B   C   D
>0   K0   K0   A0   B0  C0  D0
>1   K1   K0   A2   B2  C1  D1
>2   K1   K0   A2   B2  C2  D2
>3   K2   K0  NaN  NaN  C3  D3
>```

<br>
df1 = pd.DataFrame({'A':['A0','A1','A2'],'B':['B0','B1','B2']},index=['K0','K1','K2'])
df2 = pd.DataFrame({'C':['C0','C2','C3'],'D':['D0','D2','D3']},index=['K0','K2','K3'])
```excel
     A   B
K0  A0  B0
K1  A1  B1
K2  A2  B2
```
```excel
     C   D
K0  C0  D0
K2  C2  D2
K3  C3  D3
```

>#####按行索引的索引名合并
>①pd.merge(df1, df2, left_index=True, right_index=True, how='inner')
②pd.merge(df1, df2, left_index=True, right_index=True, how='outer')
③pd.merge(df1, df2, left_index=True, right_index=True, how='left')
④pd.merge(df1, df2, left_index=True, right_index=True, how='right')
>**结果：**
>①
>```excel
>     A   B   C   D
>K0  A0  B0  C0  D0
>K2  A2  B2  C2  D2
>```
>②
>```excel
>      A    B    C    D
>K0   A0   B0   C0   D0
>K1   A1   B1  NaN  NaN
>K2   A2   B2   C2   D2
>K3  NaN  NaN   C3   D3
>```
>③
>```excel
>     A   B    C    D
>K0  A0  B0   C0   D0
>K1  A1  B1  NaN  NaN
>K2  A2  B2   C2   D2
>```
>④
>```excel
>      A    B   C   D
>K0   A0   B0  C0  D0
>K2   A2   B2  C2  D2
>K3  NaN  NaN  C3  D3
>```

<br>
boy = pd.DataFrame({'k':['K0','K1','K2'],'age':[4,5,6]})
girl = pd.DataFrame({'k':['K0','K0','K3'],'age':[7,8,9]})
```excel
    k  age
0  K0    4
1  K1    5
2  K2    6
```
```excel
    k  age
0  K0    7
1  K0    8
2  K3    9
```
>#####suffix为列名添加后缀
>①res = pd.merge(boy, girl, on=['k'], how='inner')
②res = pd.merge(boy, girl, on=['k'], how='inner', suffixes=['_boy', '_girl'])
>**结果：**
>①
>```excel
>    k  age_x  age_y
>0  K0      4      7
>1  K0      4      8
>```
>②
>```excel
>    k  age_boy  age_girl
>0  K0        4         7
>1  K0        4         8
>```


<br>
###八、pandas plot 画图
引入包
import matplotlib.pyplot as plt

>#####Series数据生成图像
>data = pd.Series(np.random.randn(1000),index=np.arange(1000))
data = data.cumsum()  # 将数据进行累加
data.plot()  # 将数据放到plt中
plt.show()  # 以图像形式展示
**结果：**
>![image.png](Pandas数据展示.assets0eed40cc3a14c8a82d4a0567601ca0f.png)

>#####DataFrame数据生成图像
>data = pd.DataFrame(np.random.randn(1000,4),index=np.arange(1000),columns=list('ABCD'))
data = data.cumsum()
data.plot()
plt.show()  #以图像形式展示
>**结果：**
>![image.png](Pandas数据展示.assets 94b89d391254653a4087497284e7a25.png)

>#####生成图像的展示效果（plot methods: 'bar','hist','box','kde','area','scatter','hexbin','pie'）
>data = pd.DataFrame(np.random.randn(1000, 4), index=np.arange(1000), columns=list('ABCD'))
data = data.cumsum()
ax = data.plot.scatter(x='A', y='B', color='DarkBlue', label='Class 1') #使用数据点scatter
data.plot.scatter(x='A', y='C', color='DarkGreen', label='Class 2', ax=ax)
plt.show()
>**结果：**
>![image.png](Pandas数据展示.assets