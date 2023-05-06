---
title: Elasticsearch自定义分析器（下）
categories:
- ELK
---
书接上回 [Elasticsearch自定义分析器（上）](https://www.jianshu.com/writer#/notebooks/44681488/notes/88245470)


<br>
# 四、相关性算分

Elasticsearch 提供了一个最重要的功能就是相关性。它可以帮我们按照我们搜索的条件进行相关性计算。每个文档有一个叫做 _score 的分数。在默认没有 sort 的情况下，返回的文档是按照分数的大小从大到小进行排列的。

## 4.1 分数计算

### 4.1.1 计算公式

Lucene采用布尔模型（Boolean model）、词频/逆向文档频率（TF/IDF）、以及向量空间模型（Vector Space Model）进行算分，然后将他们合并到单个包中来收集匹配文档和分数计算。 只要一个文档与查询匹配，Lucene就会为查询计算分数，然后合并每个匹配术语的分数。这里使用的分数计算公式叫做 实用计分函数（practical scoring function）。

```text
score(q,d)  =  #1
            queryNorm(q)  #2
          · coord(q,d)    #3
          · ∑ (           #4
                tf(t in d)   #5
              · idf(t)²      #6
              · t.getBoost() #7
              · norm(t,d)    #8
            ) (t in q)    #9
```

- \#1 score(q, d) 是文档 d 与 查询 q 的相关度分数
- \#2 queryNorm(q) 是查询正则因子（query normalization factor）
- \#3 coord(q, d) 是协调因子（coordination factor）
- \#4 #9 查询 q 中每个术语 t 对于文档 d 的权重和
- \#5 tf(t in d) 是术语 t 在文档 d 中的词频
- \#6 idf(t) 是术语 t 的逆向文档频次
- \#7 t.getBoost() 是查询中使用的 boost
- \#8 norm(t,d) 是字段长度正则值，与索引时字段级的boost的和（如果存在）



**_score 分数的计算影响因素:**

- 1）**TF（Term Frequency）**：词频，即单词在文档中出现的次数，词频越高，相关度越高。TF 的计算永远是100%的精确，这是因为它是一个文档级的计算，文档内容可以在本地分片中获取。公式为`tf(t in d) = √frequency`，即term在文件 d 的词频（tf）是这个术语在文档中出现次数的平方根)![image.png](Elasticsearch自定义分析器（下）.assets\95cbce91ffa04335bb3311e23960fb9d.png)
- 2）**IDF（Inverse Document Frequency）**：逆向文档词频 ，计算公式为 term/document ，即单词出现的文档数越少，相关度越高。公式为`idf(t) = 1 + log ( numDocs / (docFreq + 1)) `，即术语t的逆向文档频率（Inverse document frequency）是：索引中文档数量除以所有包含该术语文档数量后的对数值。![image.png](Elasticsearch自定义分析器（下）.assets\35eca5d165bf40cb849a56870d313b68.png)
- 3）**Field-length Norm**：字段长度正则值，较短的字段比较长的字段更相关。`norm(d) = 1 / √numTerms`，即字段长度正则值是字段中术语数平方根的倒数。
- 4）**Query Normalization Factor**：查询正则因子（queryNorm）试图将查询正则化，这样就能比较两个不同查询结果。尽管查询正则值的目的是为了使查询结果之间能够相互比较，但是它并不十分有效，因为相关度分数_score 的目的是为了将当前查询的结果进行排序，比较不同查询结果的相关度分数没有太大意义。
- 5）**Query Coordination**：协调因子（coord）可以为那些查询术语包含度高的文档提供“奖励”，文档里出现的查询术语越多，它越有机会成为一个好的匹配结果。
- 6）**Query-Time Boosting：**查询时权重提升，在搜索时使用权重提升参数让一个查询语句比其他语句更重要。查询时的权重提升是我们可以用来影响相关度的主要工具，任意一种类型的查询都能接受权重提升（boost）参数。将权重提升值设置为2，并不代表最终的分数会是原值的2倍；权重提升值会经过正则化和一些其他内部优化过程。

<br>

### 4.1.2 计算模型

4.x之前的计算模型如下
![image.png](Elasticsearch自定义分析器（下）.assets37447804db44da09ef64763fc3d2822.png)

5.x之后的计算模型优化了BM25算法：优化了词频很大时对打分的影响过大。
原理：当f()，即词频无限大时，该文档的打分无限接近平稳，即(k+1)。而TF模型，词频无限大时打分也无限大。



### 4.1.3 IDF的计算方式分类

IDF的计算方式分为两类，在默认的 query-then-fetch 计算中，IDF 的计算不一定是100%的精确，它是在本地针对每个 shard 来计算的。而第二种会预查询首先从每个分片中检索本地 IDF，以计算全局 IDF。

**两种计算方式具体实现如下**

1. **query-then-fetch(默认搜索类型)：**
   默认情况下，Elasticsearch 将使用一种称为“先查询后取”的搜索类型。其工作方式如下：
   ①将查询发送到每个分片
   ②查找所有匹配的文档并使用本地 Term/Frequency 计算分数
   ③建立结果优先级队列（排序，from/to 分页等）
   ④将有关结果的元数据返回到请求节点。注意，实际文件还没有发送，只是分数
   ⑤来自所有分片的分数在请求节点上合并并排序，根据查询条件选择文档
   ⑥最后，从文档所在的各个分片中检索实际文档，结果返回给客户。
   该系统通常运行良好。在大多数情况下，您的索引具有足够的文档，可以使 term/document 文档频率统计数据变得平滑。因此，尽管每个碎片可能不完全了解整个群集的频率，但结果“足够好”，使用本地 IDF 很少出现问题，尤其是对于大型数据集，如果文档在各个分片之间分布良好，则本地分片之间的 IDF 将基本相同。
2. **DFS Query Then Fetch：**
   如果遇到这种评分差异有问题的情况，则ES提供一种称为 “DFS Query Then Fetch” 的搜索类型。除了执行预查询以计算全局文档频率外，该过程几乎与 “Query-then-Fetch” 相同。
   为了使得 IDF 100%精确，在分片可以计算每个匹配的 _score 之前，必须全局计算其值。那么问题来了：为什么我们不为每一个搜索都计算全局的 IDF 呢？答案是这样的计算会增加很多的开销。
   ①预查询每个分片，询问术语和文档频率；
   ②将查询发送到每个分片；
   ③查找所有匹配的文档并使用从预查询中计算出的全局 term/document 频率来计算分数；
   ④建立结果优先级队列（排序，从/到分页等）；
   ⑤将有关结果的元数据返回到请求节点。注意，实际文件还没有发送，只是分数；
   ⑥来自所有分片的分数在请求节点上合并并排序，根据查询条件选择文档；
   ⑦；最后，从文档所在的各个分片中检索实际文档，结果返回给客户。

**结论：**DFS Query Then Fetch获得的更好的准确性并非免费提供。 预查询会导致分片之间的额外往返，这可能会导致性能下降，具体取决于索引的大小，分片的数量，查询率等。在大多数情况下，完全没有必要……拥有“足够的”数据 为您解决问题。但是有时你会遇到奇怪的评分情况，在这种情况下，了解如何使用 DFS 查询和获取来调整搜索执行计划很有用。

<br>



## 4.2 自定义算分

相关性通常是通过类似 TF-IDF 的算法来实现的，该算法试图找出文本上与提交的查询最相似的文档。尽管 TF-IDF 及其相近的算法（例如BM25）非常棒，但有时必须通过其他算法或通过其他评分启发式方法来解决相关性问题。在这里，Elasticsearch 的script_score 和 function_score 功能变得非常有用。

> 例如：需要检索附近的咖啡店，则按文本相似度进行排序并没有意义，而应该按地理位置的距离由近到远进行排序。
>
> 再如视频网站，用户检索视频时，并不能单纯从文本相似度进行排序，而应该考虑视频的热度，热度高的排序靠前。
>
> 再如某度需要将广告置顶，给的越多得分越高，就需要自定义算分。



### 4.2.1 Constant score query

当我们不关心检索词频率TF（Term Frequency）对搜索结果排序的影响时，可以使用constant_score将查询语句query或者过滤语句filter包装起来。

constant_score 查询中，它可以包含一个查询或一个过滤，为任意一个匹配的文档指定分数，忽略TF/IDF信息。boost为指定的评分，缺省为1。

```
GET http://chenjie.asia:9200/article/_search
{
	"query": {
		"constant_score": {
			"filter": {
				"match": {
					"name": "西红柿"
				}
			},
			"boost": 1.2
		}
	}
}
```

可以配合其他语法一起使用，如bool。

```
GET http://chenjie.asia:9200/article/_search
{
	"query": {
		"bool": {
			"should": [{
				"constant_score": {
					"filter": {
						"term": {
							"name": "西红柿"
						}
					},
					"boost": 1.2
				}
			}]
		}
	}
}
```

### 4.2.2 Negative boost query

搜索包含西红柿，不包含鸡蛋的文档，使用negative boost来降低包含筛选词的得分，而不是直接过滤掉。

```
GET http://chenjie.asia:9200/article/_search
{
  "query": {
    "boosting": {
      "positive": {
        "match": {
          "name": "西红柿"
        }
      },
      "negative": {
        "match": {
          "name": "面"
        }
      }, 
      "negative_boost": 0.2
    }
  }
}
```



### 4.2.3 Script score query（7.x新特性）

`script_score`可以使用我们自己的算法对_score进行重新计算。



**如某视频网站需要对视频进行检索**

创建索引

```json
PUT http://chenjie.asia:9200/article/
{
    "mappings": {
        "properties": {
            "name": {
                "type": "text",
                "analyzer": "ik_max_word"
            },
            "sub_num": {
                "type": "long"
            },
            "read_num": {
                "type": "long"
            }
        }
    }
}
```

插入数据

```
POST http://chenjie.asia:9200/article/_doc/1
{
    "name": "西红柿鸡蛋面",
    "sub_num": "1",
    "read_num": "10"
}
POST http://chenjie.asia:9200/article/_doc/2
{
    "name": "西红柿鸡蛋盖饭",
    "sub_num": "100",
    "read_num": "10000"
}
POST http://chenjie.asia:9200/article/_doc/3
{
    "name": "西红柿鸡蛋",
    "sub_num": "10",
    "read_num": "100"
}
```

普通查询

```
GET http://chenjie.asia:9200/article/_search
{
    "query": {
    	"match": {
            "name": "西红柿鸡蛋面"
    	}
    }
}

# 得到
[
	{
        "_index": "article",
        "_type": "_doc",
        "_id": "1",
        "_score": 1.1871837,
        "_source": {
            "name": "西红柿鸡蛋面",
            "sub_num": "1",
            "read_num": "10"
        }
    },
    {
        "_index": "article",
        "_type": "_doc",
        "_id": "3",
        "_score": 0.29748765,
        "_source": {
            "name": "西红柿鸡蛋",
            "sub_num": "10",
            "read_num": "100"
        }
    },
    {
        "_index": "article",
        "_type": "_doc",
        "_id": "2",
        "_score": 0.25407052,
        "_source": {
            "name": "西红柿鸡蛋盖饭",
            "sub_num": "100",
            "read_num": "10000"
        }
    }
]
```

自定义算法查询

```
GET http://chenjie.asia:9200/article/_search
{
	"query": {
		"script_score": {
			"query": {
				"match": {
					"name": "西红柿鸡蛋面"
				}
			},
			"script": {
				"source": "_score * (doc['sub_num'].value*8+doc['read_num'].value*2)/10/100"
			}
		}
	}
}

# 得到
[
    {
        "_index": "article",
        "_type": "_doc",
        "_id": "2",
        "_score": 5.284667,
        "_source": {
            "name": "西红柿鸡蛋盖饭",
            "sub_num": "100",
            "read_num": "10000"
		}
    },
    {
        "_index": "article",
        "_type": "_doc",
        "_id": "3",
        "_score": 0.08329654,
        "_source": {
            "name": "西红柿鸡蛋",
            "sub_num": "10",
            "read_num": "100"
        }
    },
    {
        "_index": "article",
        "_type": "_doc",
        "_id": "1",
        "_score": 0.033241145,
        "_source": {
            "name": "西红柿鸡蛋面",
            "sub_num": "1",
            "read_num": "10"
        }
    }
]
```

> 自定义算法`_score * (doc['sub_num'].value*8+doc['read_num'].value*2)/10/100`对得分进行二次计算，考虑了点赞和点击量。



针对 script 的运算，有一些预定义好的函数可以供我们调用，它们可以帮我们加速我们的计算。

- [Saturation](https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-script-score-query.html#script-score-saturation)
- [Sigmoid](https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-script-score-query.html#script-score-sigmoid)
- [Random score function](https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-script-score-query.html#random-score-function)
- [Decay functions for numeric fields](https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-script-score-query.html#decay-functions-numeric-fields)
- [Decay functions for geo fields](https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-script-score-query.html#decay-functions-geo-fields)
- [Decay functions for date fields](https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-script-score-query.html#decay-functions-date-fields)
- [Functions for vector fields](https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-script-score-query.html#script-score-functions-vector-fields)



### 4.4.4 Function score query

[function_score](https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-function-score-query.html) 允许您修改查询检索的文档分数。 

要使用`function_score`，用户必须定义一个查询和一个或多个函数，这些函数为查询返回的每个文档计算一个新分数。

`function_score` 只能与以下一种功能一起使用：



- `weight`：为每个文档应用一个简单的而不被正则化的权重提升值：当 weight 为 2 时，最终结果为 2 * _score；
- `random_score`：为每个用户都使用一个不同的随机分数来对结果排序，但对某一具体用户来说，看到的顺序始终是一致的。
- `field_value_factor`：使用这个值来修改 _score，如将流行度或评分作为考虑因素。
- `script_score`：如果需求超出以上范围时，用自定义脚本完全控制分数计算的逻辑。 它还有一个属性boost_mode可以指定计算后的分数与原始的_score如何合并。
- 衰变函数(Decay function): `gauss`, `linear`, exp





#### Script_score

原理同`Script score query`

```json
GET http://chenjie.asia:9200/article/_search
{
  "query": {
    "function_score": {
      "query": {
        "match": {
          "name": "西红柿鸡蛋面"
        }
      },
      "script_score": {
        "script": "_score * (doc['sub_num'].value*8+doc['read_num'].value*2)/10/100"
      }
    }
  }
}
```

在上面的 script 的写法中，我们使用了硬编码，也就是把8和2硬写入到 script 中了。假如有一种情况，我将来想修改这个值为20或其它的值，重新看看查询的结果。由于 script 的改变，需要重新进行编译，这样的效率并不高。一种较好的办法是如下的写法：

```json
GET http://chenjie.asia:9200/article/_search
{
	"query": {
		"function_score": {
			"query": {
				"match": {
					"name": "西红柿鸡蛋面"
				}
			},
			"script_score": {
				"script": {
					"params": {
						"sub_multiplier": 8,
						"read_multiplier": 2
					},
					"source": "_score * (doc['sub_num'].value*params.sub_multiplier+doc['read_num'].value*params.read_multiplier)/10/100"
				}
			}
		}
	}
}
```

> 脚本编译被缓存以加快执行速度。 如果脚本中有可能需要修改的参数，则最好将参数写到params中，script可以重用预编译的脚本并为其动态赋值。



**可以灵活的编写脚本进行算分**

```
GET http://chenjie.asia:9200/article/_search
{
	"query": {
		"function_score": {
			"query": {
				"match": {
					"name": "西红柿鸡蛋面"
				}
			},
			"script_score": {
				"script": {
					"params": {
						"read_number": 100
					},
					"source": "return doc['read_num'].value > params.read_number ? 9:0"
				}
			}
		}
	}
}
```




#### Field_value_factor

`field_value_factor `函数使您可以使用文档中的字段来影响得分。 与使用 `script_score` 函数类似，但是它避免了脚本编写的开销。 如果用于多值字段，则在计算中仅使用该字段的第一个值。

```
GET http://chenjie.asia:9200/article/_search
{
  "query": {
    "function_score": {
      "query": {
    	 "match": {
    	   "name": "西红柿鸡蛋面"
    	 }
      },
      "field_value_factor": {
        "field": "sub_num",
        "factor": 1.2,
        "modifier": "sqrt",
        "missing": 1
      },
      "boost_mode": "multiply"
    }
  }
}
```

它将转化为以下得分公式：

```
_score = _score * sqrt(1.2 * doc['sub_num'].value)
```



**field_value_factor属性介绍**

| 属性       | 说明                                                         | 默认值 |
| ---------- | ------------------------------------------------------------ | ------ |
| `field`    | 从文档中提取的字段。                                         |        |
| `factor`   | 字段值相乘的值。                                             | 1      |
| `modifier` | 修改适用于该字段的值，可以是一个：`none`，`log`， `log1p`，`log2p`，`ln`，`ln1p`，`ln2p`，`square`，`sqrt`，或`reciprocal`。 | none   |
| `missing`  | 如果文档没有该字段，则使用该值作为字段的值进行计算。         |        |

**modifier取值的说明**

| **Modifier** | 意义                                                         |
| ------------ | ------------------------------------------------------------ |
| `none`       | 不进行操作                                                   |
| `log`        | 取字段值的对数。由于此函数参数在0到1之间将返回负值，会抛出error，因此建议改用`log1p`。 |
| `log1p`      | 加1并取对数                                                  |
| `log2p`      | 加2并取对数                                                  |
| `ln`         | 取字段值的自然对数。由于此函数参数在0到1之间将返回负值，会抛出error，因此建议改用`ln1p`。 |
| `ln1p`       | 加1并取自然对数                                              |
| `ln2p`       | 加2并取自然对数                                              |
| `square`     | 对字段值求平方                                               |
| `sqrt`       | 取字段值的平方根                                             |
| `reciprocal` | 取倒数                                                       |

> note：该`field_value_score`函数产生的分数必须为非负数，否则将抛出error。如果Modifier使用`log`和`ln`，需要注意是否在0和1之间，一定要用范围过滤器来限制字段的值以避免错误发送。推荐使用`log1p`和 `ln1p`。



`boost_mode`属性，`boost_mode`是用来定义最新计算出来的分数如何和查询的分数来相结合的。

| boost_mode的值 | 说明                             |
| -------------- | -------------------------------- |
| mulitply       | 查询分数和功能分数相乘（缺省）   |
| replace        | 仅使用功能分数，查询分数将被忽略 |
| sum            | 查询分数和功能分数相加           |
| avg            | 平均值                           |
| max            | 查询分数和功能分数的最大值       |
| min            | 查询分数和功能分数的最小值       |





#### Weight

有时候我们需要对不同的 doc 采用不同的权重，而不是每一个 doc 乘以相同的系数。这时可以使用weight功能，可以让不同的文档乘上提供的 `weight`。

为每个文档应用一个简单的而不被正则化的权重提升值：当 weight 为 2 时，最终结果为 2 * _score。

```
GET http://chenjie.asia:9200/article/_search
{
  "query": {
    "function_score": {
      "query": { 
        "term": { 
          "name": "西红柿"
        }
      },
      "functions": [ 
        {
          "filter": { "term": { "name": "盖饭" }}, 
          "weight": 1
        },
        {
          "filter": { "term": { "name": "鸡蛋" }}, 
          "weight": 1
        },
        {
          "filter": { "term": { "name": "面" }}, 
          "weight": 2 
        }
      ],
      "score_mode": "sum",
      "boost_mode": "multiply",
    }
  }
}

# 得到结果
{
    "took": 4,
    "timed_out": false,
    "_shards": {
        "total": 1,
        "successful": 1,
        "skipped": 0,
        "failed": 0
    },
    "hits": {
        "total": {
            "value": 3,
            "relation": "eq"
        },
        "max_score": 0.38110578,
        "hits": [
            {
                "_index": "article",
                "_type": "_doc",
                "_id": "1",
                "_score": 0.38110578,
                "_source": {
                    "name": "西红柿鸡蛋面",
                    "sub_num": "1",
                    "read_num": "10"
                }
            },
            {
                "_index": "article",
                "_type": "_doc",
                "_id": "2",
                "_score": 0.25407052,
                "_source": {
                    "name": "西红柿鸡蛋盖饭",
                    "sub_num": "100",
                    "read_num": "10000"
                }
            },
            {
                "_index": "article",
                "_type": "_doc",
                "_id": "3",
                "_score": 0.14874382,
                "_source": {
                    "name": "西红柿鸡蛋",
                    "sub_num": "10",
                    "read_num": "100"
                }
            }
        ]
    }
}
```



#### Random_score

可以通过该功能对每个文档进行随机打分，使得搜索会出现不同的文档排序。

`random_score`被均匀地分布到0-1之间。如果希望每次查询分数是不变的，可以指定`seed` 和`field`。然后将基于该种子计算最终分数。请注意，位于相同分片内且具有相同值的文档`field` 将获得相同的分数，因此通常希望使用对所有文档都具有唯一值的字段。一个很好的默认选择是使用该 `_seq_no`字段，其唯一的缺点是，如果文档被更新，则分数会改变，因为更新操作也会更新`_seq_no`字段的值。

```
GET http://chenjie.asia:9200/article/_search
# 不指定随机数种子，那么每次查询得分不同，即文档排序不同
{
  "query": {
    "function_score": {
      "query": {
        "match": {
          "name": "西红柿"
        }
      },
      "boost": "5",
      "random_score": {},
      "boost_mode": "multiply"
    }
  }
}

# 指定随机数种子，每次查询得分相同
{
  "query": {
    "function_score": {
      "query": {
        "match": {
          "name": "西红柿"
        }
      },
      "boost": "5",
      "random_score": {
      	"seed": 10,
      	"field": "_seq_no"
      },
      "boost_mode": "multiply"
    }
  }
}
```



#### Decay functions
衰减函数（Decay Function）提供了一个更为复杂的公式，它描述了这样一种情况：对于一个字段，它有一个理想的值，而字段实际的值越偏离这个理想值（无论是增大还是减小），就越不符合期望。 有三种衰减函数——线性（linear）、指数（exp）和高斯（gauss）函数，它们可以操作数值、时间以及 经纬度地理坐标点这样的字段。常见的Decay function有以下三种：

  ![20191221164124868.png](Elasticsearch自定义分析器（下）.assets 8f2c2eb07ae4b8e89bd4f1044e1ddc8.png)

- **gauss**

  正常衰减，计算如下：

   ![image](Elasticsearch自定义分析器（下）.assets\77c08b6ca4204b2c944880998627d18f.png)

  其中西格玛被再次计算以确保得分取值`decay`在距离`scale`从`origin`+ -`offset`

  [图片上传失败...(image-f002c2-1622023404557)]

  See [Normal decay, keyword `gauss`](https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-function-score-query.html#gauss-decay) for graphs demonstrating the curve generated by the `gauss` function.


- **exp**

  指数衰减，计算如下：

  [图片上传失败...(image-8d59da-1622023404557)]
  其中参数拉姆达被再次计算，以确保该得分取值`decay`在距离`scale`从`origin`+ -`offset`

  ![image](Elasticsearch自定义分析器（下）.assets4a7e0f1080a4e2abd4d99fcd6c21a20.png)

  See [Exponential decay, keyword `exp`](https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-function-score-query.html#exp-decay) for graphs demonstrating the curve generated by the `exp` function.

  

- **linear**

  线性衰减，计算如下：

   ![image](Elasticsearch自定义分析器（下）.assets016e7f09c7e4e66bf9732a12c11b02e.png)

  其中参数`s`被再次计算，以确保该得分取值`decay`在距离`scale`从`origin`+ -`offset`

   ![image](Elasticsearch自定义分析器（下）.assetsff5e3d015d41168543ae09bda27ebc.png)


  与正常和指数衰减相反，如果字段值超过用户给定标度值的两倍，则此函数实际上将分数设置为0。



三个都能接受以下参数：

| 属性     | 说明                                                         |
| -------- | ------------------------------------------------------------ |
| `origin` | 用于计算距离的原点。对于数字字段，必须指定为数字；对于日期字段，必须指定为日期；对于地理字段，必须指定为地理点。地理位置和数字字段必填。对于日期字段，默认值为`now`。支持日期计算如`now-1h`。 |
| `scale`  | 所有函数都不能缺省。表示到origin距离为offset+scale的位置，该位置的分数为decay的值。对于地理字段：可以定义为数字+单位，如"1km"，"12m"，默认单位是米。对于日期字段：可以定义为数字+单位，如"1h"，"10d"等，默认单位是毫秒。对于数字字段：可以是任何数字。 |
| `offset` | 如果`offset`定义了，那么衰减函数仅计算到origin的距离大于offset的值`。默认值为0。 |
| `decay`  | 该`decay`参数定义了在距离origin为offset+scale处的score的值。默认值为0.5。 |

[图片上传失败...(image-42f8db-1622023404557)]


**如下是数字、地理和日期的写法示例**

```
# 数字
"gauss": { 
    "price": {
          "origin": "0",
          "scale": "20"
    }
}

# 地理
"gauss": { 
    "location": {
          "origin": "11, 12",
          "scale": "2km"
    }
}

#日期
"gauss": { 
    "location": {
          "origin": "2021-05-24T16:00:00",
          "scale": "2km"
    }
}
```



我们现在以 gauss 来为例展示如何使用这个衰变函数的。曲线的形状可以通过 orgin，scale，offset 和 decay 来控制。 这三个变量是控制曲线形状的主要工具。如果我们希望菜谱列表涵盖一整天，则最好将原点定义为当前时间戳，比例尺定义为24小时。 offset 可用于在开始时将曲线完全平坦，例如将其设置为1h，可消除最近视频的所有惩罚，也即最近1个小时里的发布的菜谱不受影响 。最后，衰减选项会根据文档的位置更改文档降级的严重程度。 默认的衰减值是0.5，较大的值会使曲线更陡峭，其效果也更明显。

**示例一：**

添加菜谱的发布日期

```
PUT http://chenjie.asia:9200/article/_doc/1
{
    "name": "西红柿鸡蛋面",
    "sub_num": "1",
    "read_num": "10",
    "public_time": "2021-05-24T16:00:00"
}
PUT http://chenjie.asia:9200/article/_doc/2
{
    "name": "西红柿鸡蛋盖饭",
    "sub_num": "100",
    "read_num": "10000",
    "public_time": "2021-05-24T00:00:00"
}
PUT http://chenjie.asia:9200/article/_doc/3
{
    "name": "西红柿鸡蛋",
    "sub_num": "10",
    "read_num": "100",
    "public_time": "2021-05-23T00:00:00"
}
POST http://chenjie.asia:9200/article/_doc/4
{
    "name": "西红柿鸡蛋面",
    "sub_num": "1",
    "read_num": "10",
    "public_time": "2021-05-23T00:00:00"
}
```

搜索

```
GET http://chenjie.asia:9200/article/_search
{
  "query": {
    "function_score": {
      "query": {
        "match": {
          "name": "西红柿"
        }
      },
      "functions": [
        {
          "gauss": {
            "public_time": {
              "origin": "2021-05-24T16:00:00",
              "scale": "1h",
              "offset": "1h",
              "decay": 0.5
            }
          }
        }
      ],
      "boost_mode": "multiply"
    }
  }
}

# 验证了如下结论①在origin的offset范围内不衰减。②在距离origin的offset+scala处的衰减是decay
{
    "took": 2,
    "timed_out": false,
    "_shards": {
        "total": 1,
        "successful": 1,
        "skipped": 0,
        "failed": 0
    },
    "hits": {
        "total": {
            "value": 4,
            "relation": "eq"
        },
        "max_score": 0.050498735,
        "hits": [
            {
                "_index": "article",
                "_type": "_doc",
                "_id": "2",
                "_score": 0.050498735,
                "_source": {
                    "name": "西红柿鸡蛋盖饭",
                    "sub_num": "100",
                    "read_num": "10000",
                    "public_time": "2021-05-24T00:00:00"
                }
            },
            {
                "_index": "article",
                "_type": "_doc",
                "_id": "1",
                "_score": 0.050498735,
                "_source": {
                    "name": "西红柿鸡蛋面",
                    "sub_num": "1",
                    "read_num": "10",
                    "public_time": "2021-05-24T16:00:00"
                }
            },
            {
                "_index": "article",
                "_type": "_doc",
                "_id": "3",
                "_score": 0.029339764,
                "_source": {
                    "name": "西红柿鸡蛋",
                    "sub_num": "10",
                    "read_num": "100",
                    "public_time": "2021-05-23T00:00:00"
                }
            },
            {
                "_index": "article",
                "_type": "_doc",
                "_id": "4",
                "_score": 0.025249368,
                "_source": {
                    "name": "西红柿鸡蛋面",
                    "sub_num": "1",
                    "read_num": "10",
                    "public_time": "2021-05-23T00:00:00"
                }
            }
        ]
    }
}
```



**示例二**

如果我们想找一家游泳馆，我们希望游泳馆的位置在(31.227817, 121.358775)坐标附近，5km以内是满意的距离，15km以内是可以接受的距离，超过15km就不再考虑。

```
{
	"query": {
		"function_score": {
			"query": {
				"match": {
					"name": "游泳馆"
				}
			},
			"gauss": {
				"location": {
					"origin": {
						"lat": 31.227817,
						"lon": 121.358775
					},
					"offset": "5km",
					"scale": "10km"
				}
			},
			"boost_mode": "sum"
		}
	}
}
```



### 4.4.5 Functions

上面的例子都只是调用某一个函数并与查询得到的_score进行合并处理，而在实际应用中肯定会出现在多个点上计算分值并合并，虽然脚本也许可以解决这个问题，但是应该没人愿意维护一个复杂的脚本。

这时候通过多个函数将每个分值都计算出再合并才是更好的选择。 在function_score中可以使用functions属性指定多个函数。它是一个数组，所以原有函数不需要发生改动。同时还可以通过score_mode指定各个函数分值之间的合并处理，值跟boost_mode相同。

**属性说明**

| 属性         | 说明                                                         |
| ------------ | ------------------------------------------------------------ |
| `boost`      | 所有文档的加权值                                             |
| `min_score`  | 过滤所有的低于该得分的文档                                   |
| `max_boost`  | 每个function中weight/boost的最大值，如果超过按max_boost的值进行计算 |
| `boost_mode` | 将原始分数合并成最终的分数                                   |
| `score_mode` | 将各个function的分值合并成一个综合的分值                     |

**score_mode和boost_mode的参数相同如下**

| score_mode/boost_mode | 说明                             |
| --------------------- | -------------------------------- |
| mulitply              | 查询分数和功能分数相乘（缺省）   |
| replace               | 仅使用功能分数，查询分数将被忽略 |
| sum                   | 查询分数和功能分数相加           |
| avg                   | 平均值                           |
| max                   | 查询分数和功能分数的最大值       |
| min                   | 查询分数和功能分数的最小值       |



**示例一**

```
GET http://chenjie.asia:9200/article/_search
{
  "query": {
    "function_score": {
      "query": { 
        "term": { 
          "name": "西红柿"
        }
      },
      "boost": "5",
      "functions": [ 
        {
          "filter": {
          	"term": { 
          		"name": "盖饭" 
          	}
          }, 
          "random_score": {},
          "weight": 2
        },
        {
          "filter": { 
          	"term": { 
          		"name": "鸡蛋" 
          	}
          }, 
          "weight": 1.5
        },
        {
          "filter": { 
          	"term": { 
          		"name": "面"
          	}
          }, 
          "weight": 5
        }
      ],
      "score_mode": "sum",
      "boost_mode": "multiply",
      "min_score": 0.1,
      "max_boost": 3
    }
  }
}
```



**示例二**

```
# 创建索引
PUT http://chenjie.asia:9200/gym/
{
    "mappings": {
        "properties": {
            "name": {
                "type": "text",
                "analyzer": "ik_max_word"
            },
            "comment_score": {
                "type": "float"
            },
            "location": {
                "type": "geo_point"
            }
        }
    }
}

# 添加文档
POST http://chenjie.asia:9200/gym/_doc/1
{
    "name": "健身游泳池",
    "comment_score": "3.5",
    "location": {
        "lat": 30.321970,
        "lon": 120.167054
    }
}

POST http://chenjie.asia:9200/gym/_doc/2
{
    "name": "儿童游泳池",  // 与健身游泳池距离为1.2km
    "comment_score": "4.0",
    "location": {
        "lat": 30.321970,
        "lon": 120.180227
    }
}

POST http://chenjie.asia:9200/gym/_doc/3
{
    "name": "市游泳池",  // 与健身游泳池距离为5.6km
    "comment_score": "4.5",
    "location": {
        "lat": 30.272867,
        "lon": 120.167054
    }
}

# 查询
{
	"query": {
		"function_score": {
			"query": {
				"match": {
					"name": "游泳池"
				}
			},
			"functions": [
				{
					"gauss": {
						"location": {
							"origin": "30.32197,120.167054",
							"scale": "5km",
							"offset": "0",
							"decay": 0.1
						}
						
					},
					"weight": 5
				},
				{
					"field_value_factor": {
						"field": "comment_score",
						"factor": 1.5
					}
				},
				{
					"random_score": {
						"seed": "$id"
					},
					"weight": 1
				}
			],
			"score_mode": "sum",
			"boost_mode": "multiply"
		}
	}
}

# 结果
{
    "took": 4,
    "timed_out": false,
    "_shards": {
        "total": 1,
        "successful": 1,
        "skipped": 0,
        "failed": 0
    },
    "hits": {
        "total": {
            "value": 3,
            "relation": "eq"
        },
        "max_score": 4.2184434,
        "hits": [
            {
                "_index": "gym",
                "_type": "_doc",
                "_id": "2",
                "_score": 4.2184434,
                "_source": {
                    "name": "儿童游泳池",
                    "comment_score": "4.0",
                    "location": {
                        "lat": 30.32197,
                        "lon": 120.180227
                    }
                }
            },
            {
                "_index": "gym",
                "_type": "_doc",
                "_id": "1",
                "_score": 2.9460847,
                "_source": {
                    "name": "健身游泳池",
                    "comment_score": "3.5",
                    "location": {
                        "lat": 30.32197,
                        "lon": 120.167054
                    }
                }
            },
            {
                "_index": "gym",
                "_type": "_doc",
                "_id": "3",
                "_score": 2.5065584,
                "_source": {
                    "name": "市游泳池",
                    "comment_score": "4.5",
                    "location": {
                        "lat": 30.272867,
                        "lon": 120.167054
                    }
                }
            }
        ]
    }
}
```

> 这样一个场馆的最高得分应该是5分 + 7.5分（评分5分 * 1.5）+ 1分（随机评分）。这样就将距离、评分考虑进去，并添加了随机评分。





<br>
# 五、项目

## 5.1 官方小项目

### 5.1.1 项目介绍

有一个音乐库文档，包含了艺术家的 id，艺术家的名字，以及艺术家的 ranking，也就是排名。现在需要实现对这个音乐库的搜索功能。

**我们需要做到**

1. 当我们输入c时，需要检索出所有的c开头的音乐家名字列表。
2. 音乐家的顺序应当考虑热度和评分。

### 5.1.2 项目梳理

#### 存储

1. 对文档进行普通分词即可，选择`standard`分词器；
2. 需要将如`Hélène Ségara`的名字转换为`Helene Segara`，可以使用[asciifolding](https://www.elastic.co/guide/en/elasticsearch/reference/current/analysis-asciifolding-tokenfilter.html)过滤器；
3. 需要存储所有的文档的前n个分词(n=1,2....max_gram)，可以使用`edge_ngram`后过滤器；
4. 将所有的token小写，使用`lowercase`后过滤器

#### 检索

1. 检索词也进行普通分词，选择`standard`分词器；
2. 同样需要将`Hélène Ségara`的转换为`Helene Segara`，使用[asciifolding](https://www.elastic.co/guide/en/elasticsearch/reference/current/analysis-asciifolding-tokenfilter.html)过滤器；
3. 将所有的token小写，使用`lowercase`后过滤器；
4. 不同的是，不需要使用`edge_ngram`后过滤器；



### 5.1.3 项目代码

#### 创建索引

我们接着使用如下的命令来创建 content 索引：

```
PUT content
{
  "settings": {
    "analysis": {
      "filter": {
        "front_ngram": {
          "type": "edge_ngram",
          "min_gram": "1",
          "max_gram": "12"
        }
      },
      "analyzer": {
        "i_prefix": {
          "filter": [
            "lowercase",
            "asciifolding",
            "front_ngram"
          ],
          "tokenizer": "standard"
        },
        "q_prefix": {
          "filter": [
            "lowercase",
            "asciifolding"
          ],
          "tokenizer": "standard"
        }
      }
    }
  },
  "mappings": {
    "properties": {
      "type": {
        "type": "keyword"
      },
      "artist_id": {
        "type": "keyword"
      },
      "ranking": {
        "type": "double"
      },
      "artist_name": {
        "type": "text",
        "analyzer": "standard",
        "index_options": "offsets",
        "fields": {
          "prefix": {
            "type": "text",
            "term_vector": "with_positions_offsets",
            "index_options": "docs",
            "analyzer": "i_prefix",
            "search_analyzer": "q_prefix"
          }
        },
        "position_increment_gap": 100
      }
    }
  }
}
```

> 在上面，有两个部分：settings 及 mappings。在 settings 的部分，它定义两个分词器： i_prefix 及 q_prefix。它们分别是 input，也就是导入文档时要使用的分词器，而 q_prefix 则指的是在 query，也就是在搜索时使用的分词器。在 mappings 里，针对 content，它是一个 multi-field 的字段。除了 content 可以被正常搜索以外，我们添加 content.prefix 字段。针对这个字段，在导入时使用 i_prefix 分词器，而对搜索文字来说，它使用 q_prefix 分词器。

#### 存储文档

```
POST content/_bulk
{"index":{"_id":"a1"}}
{"type":"ARTIST","artist_id":"a1","artist_name":"Sezen Aksu","ranking":10}
{"index":{"_id":"a2"}}
{"type":"ARTIST","artist_id":"a2","artist_name":"Selena Gomez","ranking":100}
{"index":{"_id":"a3"}}
{"type":"ARTIST","artist_id":"a3","artist_name":"Shakira","ranking":10}
{"index":{"_id":"a4"}}
{"type":"ARTIST","artist_id":"a4","artist_name":"Hélène Ségara","ranking":1000}
```

#### 文档检索

```
POST content/_search
{
  "query": {
    "multi_match": {
      "query": "s",
      "fields": [
        "artist_name.prefix"
      ]
    }
  }
}


```

> 通过s可以检索到全部的四条文档。

```
POST content/_search
{
  "query": {
    "multi_match": {
      "query": "se",
      "fields": [
        "artist_name.prefix"
      ]
    }
  }
}
```

> 通过se可以检索到["Sezen Aksu", "Selena Gomez", "Hélène Ségara"]



### 5.1.4 相关性优化

从上面的返回结果来看，索引以 se 开头的艺术家的名字都被正确地搜索到了，并返回。但是也有一些不如意的地方，比如 Sezen Aksu 的得分最高，但是他的 ranking 却只有 10，相反 Hélène Ségara 的得分最低，但是它的  ranking 却非常高。这个返回结果的 score 显然和我们的需求不太一样。

> 因为 Sezen 的字符串长度比 Ségara 要短，所以它的评分比较高。

我们可通过 [function_score ](https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-function-score-query.html)来定制相关性。为了能够让分数和 rangking 这个字段能有效地结合起来。我们希望 ranking 的值越高，能够在最终的得分钟起到一定的影响。我们可以通过这样的写法：

```json
POST content/_search
{
  "from": 0,
  "size": 10,
  "query": {
    "function_score": {
      "query": {
        "multi_match": {
          "query": "se",
          "fields": [
            "artist_name.prefix"
          ]
        }
      },
      "functions": [
        {
          "filter": {
            "match_all": {
              "boost": 1
            }
          },
          "script_score": {
            "script": {
              "source": "Math.max(((!doc['ranking'].empty)? Math.log10(doc['ranking'].value) : 1), 1)",   // 我们针对 ranking 使用了自己的一个算法并得出来一个分数
              "lang": "painless"
            }
          }
        }
      ],
      "boost": 1,
      "boost_mode": "multiply",
      "score_mode": "multiply"  //我们使用刚才得到的分数和之前搜索得到得分进行相乘，并得出来最后的分数。基于这种算法，ranking 越高，给搜索匹配得出来的分数的加权值就越高。从某种程度上讲，ranking 的大小会影响最终的排名。
    }
  },
  "sort": [
    {
      "_score": {
        "order": "desc"
      }
    }
  ]
}
```

经过上面的改造之后，最后的排名为：

```json
{
  "took" : 4,
  "timed_out" : false,
  "_shards" : {
    "total" : 1,
    "successful" : 1,
    "skipped" : 0,
    "failed" : 0
  },
  "hits" : {
    "total" : {
      "value" : 3,
      "relation" : "eq"
    },
    "max_score" : 0.9777223,
    "hits" : [
      {
        "_index" : "content",
        "_type" : "_doc",
        "_id" : "a4",
        "_score" : 0.9777223,
        "_source" : {
          "type" : "ARTIST",
          "artist_id" : "a4",
          "artist_name" : "Hélène Ségara",
          "ranking" : 1000
        }
      },
      {
        "_index" : "content",
        "_type" : "_doc",
        "_id" : "a2",
        "_score" : 0.6778009,
        "_source" : {
          "type" : "ARTIST",
          "artist_id" : "a2",
          "artist_name" : "Selena Gomez",
          "ranking" : 100
        }
      },
      {
        "_index" : "content",
        "_type" : "_doc",
        "_id" : "a1",
        "_score" : 0.36826363,
        "_source" : {
          "type" : "ARTIST",
          "artist_id" : "a1",
          "artist_name" : "Sezen Aksu",
          "ranking" : 10
        }
      }
    ]
  }
}
```

这一次，我们看到 Hélène Ségara 排到了第一名。

在实际的使用中，由于有海量的数据，scripts 的计算会影响搜索的速度。我们可以针对一个用所关心的歌曲进行过滤：

```json
POST /content/_search
{
  "from": 0,
  "size": 10,
  "query": {
    "function_score": {
      "query": {
        "multi_match": {
          "query": "s",
          "fields": [
            "artist_name.prefix"
          ]
        }
      },
      "functions": [
        {
          "filter": {
            "terms": {
              "artist_id": [
                "a4",
                "a3"
              ]
            }
          },
          "script_score": {
            "script": {
              "source": "params.boosts.get(doc[params.artistIdFieldName].value)",
              "lang": "painless",
              "params": {
                "artistIdFieldName": "artist_id",
                "boosts": {
                  "a4": 5,
                  "a3": 2
                }
              }
            }
          }
        }
      ],
      "boost": 1,
      "boost_mode": "multiply",
      "score_mode": "multiply"
    }
  },
  "sort": [
    {
      "_score": {
        "order": "desc"
      }
    }
  ]
}
```

在上面，比如针对不同的用户，这里的 artist_id 的列表将会发送改变。这样修改的结果可以节省 script 的运算，从而提高搜索的速度。


<br>
## 5.2 项目二
<!--
### 5.1.1 单机部署es 5.6.3
#### 编辑Dockerfile
**vim elasticsearch.dockerfile**
```
FROM elasticsearch:5.6.3-alpine
ENV VERSION=5.6.3
RUN echo vm.max_map_count=262144 >> /etc/sysctl.conf
ADD https://github.com/medcl/elasticsearch-analysis-ik/releases/download/v$VERSION/elasticsearch-analysis-ik-$VERSION.zip /tmp/
RUN /usr/share/elasticsearch/bin/elasticsearch-plugin install file:///tmp/elasticsearch-analysis-ik-$VERSION.zip
ADD https://github.com/medcl/elasticsearch-analysis-pinyin/releases/download/v$VERSION/elasticsearch-analysis-pinyin-$VERSION.zip /tmp/
RUN /usr/share/elasticsearch/bin/elasticsearch-plugin install file:///tmp/elasticsearch-analysis-pinyin-$VERSION.zip
RUN rm -rf /tmp/*
```
#### 创建镜像es_ik_py
```
docker build -t es_ik_py:5.6.3 . -f elasticsearch.dockerfile
```
-->

### 5.2.1 单机部署es 7.8.0
#### 编辑Dockerfile
**vim elasticsearch.dockerfile**
```
FROM elasticsearch:7.8.0
ENV VERSION=7.8.0
RUN sh -c '/bin/echo -e "y" | /usr/share/elasticsearch/bin/elasticsearch-plugin install https://github.com/medcl/elasticsearch-analysis-ik/releases/download/v${VERSION}/elasticsearch-analysis-ik-$VERSION.zip'
RUN sh -c '/bin/echo -e "y" | /usr/share/elasticsearch/bin/elasticsearch-plugin install https://github.com/medcl/elasticsearch-analysis-pinyin/releases/download/v$VERSION/elasticsearch-analysis-pinyin-$VERSION.zip'
```
>如果出现socker异常，大多是网络问题，多试几次就行

#### 创建镜像es_ik_py
```
docker build -t es_ik_py:7.8.0 . -f elasticsearch.dockerfile
```

<!--
#### 配置文件 5.x
**vim /root/docker/es/conf/es1.yml**
```
cluster.name: elasticsearch-cluster
node.name: node-1
network.host: 0.0.0.0
http.port: 9200
transport.tcp.port: 9300
#开启允许跨域请求资源
http.cors.enabled: true
http.cors.allow-origin: "*"
```
-->

#### 配置文件7.x
```properties
#节点 1 的配置信息：
#集群名称，节点之间要保持一致
cluster.name: my-elasticsearch
#节点名称，集群内要唯一
node.name: node-1
node.master: true
node.data: true
#允许访问的ip地址
network.host: 0.0.0.0
#http 端口
http.port: 9200
#tcp 监听端口
transport.tcp.port: 9300
#discovery.seed_hosts: ["localhost:9301", "localhost:9302","localhost:9303"]
#discovery.zen.fd.ping_timeout: 1m
#discovery.zen.fd.ping_retries: 5
#集群内的可以被选为主节点的节点列表
cluster.initial_master_nodes: ["node-1", "node-2","node-3"]
#跨域配置
#action.destructive_requires_name: true
#开启允许跨域请求资源
http.cors.enabled: true
http.cors.allow-origin: "*"

# 控制fielddata允许内存大小，达到HEAP 20% 自动清理旧cache。不配置就不回收。
indices.fielddata.cache.size: 20%
indices.breaker.total.use_real_memory: false
# fielddata 断路器限制fileddata的堆大小上限，默认设置堆的 60%
indices.breaker.fielddata.limit: 40%
# request 断路器估算需要完成其他请求部分的结构大小，例如创建一个聚合桶，默认限制是堆内存的 40%。
indices.breaker.request.limit: 40%
# total 揉合 request 和 fielddata 断路器保证两者组合起来不会使用超过堆内存的 70%(默认值)。
indices.breaker.total.limit: 95%
```

#### 启动es容器
```
docker run -d --privileged -e ES_JAVA_OPTS="-Xms512m -Xmx512m" --name es1 -p 9200:9200 -p 9300:9300 -v /root/docker/es/config:/usr/share/elasticsearch/config  -v /root/docker/es/data/es1data:/usr/share/elasticsearch/data -v  /root/docker/es/logs:/usr/share/elasticsearch/logs -v /root/docker/es/analysis-ik:/usr/share/elasticsearch/config/analysis-ik es_ik_py:7.8.0
```
>1. 如果启动异常，可能是挂载文件没有写权限，执行`chmod -R 777 /root/docker/es/data/es1data /root/docker/es/logs`;
>2. 如果报错[max virtual memory areas vm.max_map_count [65530] is too low], 则在宿主机上修改文件 `echo 'vm.max_map_count=262144' >> /etc/sysctl.conf;sysctl -p`;
>3. 如果是单机启动，还需要添加参数 `-e "discovery.type=single-node" `


<br>
### 5.2.2 配置同义词
**①直接配置同义词**
```
GET http://chenjie.asia:9200/article/_analyze
{
	"tokenizer": "ik_smart",
	"filter": {
		"type": "synonym",
		"synonyms": ["西红柿,番茄 => 番茄"]
	},
	"text": "西红柿 番茄"
}

# 结果如下
{
    "tokens": [
        {
            "token": "番茄",
            "start_offset": 0,
            "end_offset": 3,
            "type": "SYNONYM",
            "position": 0
        },
        {
            "token": "番茄",
            "start_offset": 4,
            "end_offset": 6,
            "type": "SYNONYM",
            "position": 1
        }
    ]
}
```

**②使用同义词文件**
创建同义词文件
`vim /root/docker/es/logs/synonym.txt`
写入"西红柿,番茄 => 西红柿"
>该文件会被映射到容器中，容器中的位置是`/usr/share/elasticsearch/logs/synonym.txt`
```
GET http://chenjie.asia:9200/article/_analyze
{
	"tokenizer": "ik_smart",
	"filter": {
		"type": "synonym",
		"synonyms_path": "/usr/share/elasticsearch/logs/synonym.txt"
	},
	"text": "西红柿 番茄"
}

# 结果如下
{
    "tokens": [
        {
            "token": "西红柿",
            "start_offset": 0,
            "end_offset": 3,
            "type": "SYNONYM",
            "position": 0
        },
        {
            "token": "西红柿",
            "start_offset": 4,
            "end_offset": 6,
            "type": "SYNONYM",
            "position": 1
        }
    ]
}
```

<br>
### 5.2.3 配置停用词
#### 使用stop后过滤器
**①直接配置停用词**
```
GET http://chenjie.asia:9200/smartcook/_analyze
{
	"tokenizer": "ik_smart",
	"filter": {
		"type": "stop",
		"stopwords": "西红柿"
	},
	"text": "西红柿 番茄"
}

# 结果如下
{
    "tokens": [
        {
            "token": "番茄",
            "start_offset": 4,
            "end_offset": 6,
            "type": "CN_WORD",
            "position": 1
        }
    ]
}
```

**②使用停用词文件**
创建停用词文件
`vim /root/docker/es/logs/stopword.txt`
写入"番茄"
```
GET http://chenjie.asia:9200/smartcook/_analyze
{
	"tokenizer": "ik_smart",
	"filter": {
		"type": "stop",
		"stopwords_path": "/usr/share/elasticsearch/logs/stopword.txt"
	},
	"text": "西红柿 番茄"
}

# 结果如下
{
    "tokens": [
        {
            "token": "西红柿",
            "start_offset": 0,
            "end_offset": 3,
            "type": "CN_WORD",
            "position": 0
        }
    ]
}
```

#### 使用ik分析器停用词配置
修改`/usr/share/elasticsearch/config/analysis-ik/IKAnalyzer.cfg.xml`
```
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE properties SYSTEM "http://java.sun.com/dtd/properties.dtd">
<properties>
        <comment>IK Analyzer 扩展配置</comment>
        <!--用户可以在这里配置自己的扩展字典 -->
        <entry key="ext_dict"></entry>
         <!--用户可以在这里配置自己的扩展停止词字典-->
        <entry key="ext_stopwords">../../logs/stopword.txt</entry>
        <!--用户可以在这里配置远程扩展字典 -->
        <!-- <entry key="remote_ext_dict">words_location</entry> -->
        <!--用户可以在这里配置远程扩展停止词字典-->
        <entry key="remote_ext_stopwords">http://chenjie.asia/es/stopword.dic</entry>
</properties>
```
>配置文件中扩展停用词字典配置项放开，并修改文件所在路径，这里访问的是本地目录，但是不支持热更新。所以我们这里配置remote_ext_stopwords，将文件放在nginx上通过http远程访问，这样是支持热更新的，IK源码中有两个任务每隔1分钟来请求一次，即每分钟扩展字典都会热更新一次。
>1. 如果中文乱码，输入`:set encoding=utf-8`调整编码格式。
>2. 如果使用ext_dict配置停用词不生效，查看日志`docker logs -f es1`，看该停用词文件是否加载成功，有个坑就是路径是/usr/share/elasticsearch/config/analysis-ik加上配置的路径，使用绝对路径都不管用，需要注意。
>3. 我试过用remote_ext_stopwords来访问本地文件file:///usr/share/elasticsearch/logs/stopword.txt，这样即读取了本地文件又支持热更新，但是报错`URI does not specify a valid host name`！
>4. 需要注意热更新的禁用词不要和配置的同义词出现相同的词汇。

**修改完成后重启es，然后发现停用词配置文件生效。**
测试一下，修改在nginx上的停用词文件stopword.dic，添加"国民党"
```
GET http://chenjie.asia:9200/smartcook/_analyze
{
	"tokenizer": "ik_smart",
	"text": "共产党 国民党"
}

# 我们在本地配置了禁用词"共产党"，在热更新还未生效时，分词结果为
{
    "tokens": [
        {
            "token": "国民党",
            "start_offset": 4,
            "end_offset": 7,
            "type": "CN_WORD",
            "position": 0
        }
    ]
}
# 1分钟内就会完成热更新，再次分词，结果为
{
    "tokens": []
}
```

>注：`/usr/share/elasticsearch/config/analysis-ik/stopword.dic`文件是ik默认读取的停用词文件，也可以直接将停用词写在这里。但是不会进行热更新，需要重启才能生效。如果有单词如these、that等不希望被禁用，可以在stopword.dic中删除。


<br>
### 5.2.4 项目介绍

**自定义分析器实现对菜谱的搜索。**

- **要求一：**多样的搜索方式。
  如搜索<火星人的西红柿鸡蛋>这道菜，可以通过如下方式搜索：
  ①可以通过拼音首字母搜索，如hxr，xhs等。要求是有意义的词语首字母。
  ②可以通过全拼搜索，如 huoxingren，xihongshi。
  ③可以通过菜谱名的前n个字搜索，如 火星。
  ④可以通过有意义的中文名搜索，如 西红柿。
  ⑤可以通过拼音首字母、全拼和中文混搭搜索，如 hxr的西红柿chaodan。
- **要求二：**对敏感词进行停用处理。
- **要求三：**考虑同义词，如番茄和西红柿是同义词。
- **要求四：**搜索打分需要考虑菜谱的热度和评分。



### 5.2.4.1 项目梳理 

①和②先使用ik_max_word分出有意义的中文词组，再通过pinyin filter转换为拼音首字母和全拼。

```
# 索引分词，需要存储分词后的中文，中文全拼，中文拼音首字母，
{
	"tokenizer": "ik_max_word",
	"filter": {
		"type": "pinyin",
		"keep_first_letter": true,
		"keep_separate_first_letter": false,
		"limit_first_letter_length": 16,
		"keep_full_pinyin": true,
		"keep_joined_full_pinyin": true,
		"keep_none_chinese": true,
		"keep_none_chinese_together": true,
		"keep_none_chinese_in_first_letter": false,
		"keep_none_chinese_in_joined_full_pinyin": false,
		"none_chinese_pinyin_tokenize": true,
		"keep_original": true,
		"lowercase": true,
		"trim_whitespace": true,
		"remove_duplicated_term": true
	},
	"text": "Hxrdexihongshi鸡蛋"
}
# [h x r de xi hong shi hxrdexihongshi ji dan jidan jd 鸡蛋]
```

③使用edge_ngram tokenizer进行分词，min_gram = 2；搜索不能进行分词

```
GET http://chenjie.asia:9200/gym/_analyze
# 索引分词
{
	"tokenizer": {
		"type": "edge_ngram",
		"min_gram": 2,
		"max_gram": 16
	},
	"filter": ["lowercase"],
	"text": "Hxr的西红柿鸡蛋"
}
# [hx hxr hxr的 hxr的西 hxr的西红 hxr的西红柿 hxr的西红柿鸡 hxr的西红柿鸡蛋]

# 搜索词分词
{
	"tokenizer": "whitespace",
	"filter": ["lowercase"],
	"text": "Hxr的西红柿 炒蛋"
}
# [hxr的西红柿 炒蛋]
```

④使用ik_max_word分出有意义的中文词组；

```
GET http://chenjie.asia:9200/gym/_analyze
# 索引分词
{
	"tokenizer": "ik_max_word",
	"text": "Hxr的西红柿"
}
# [hxr 的 西红柿 炒蛋]

# 搜索分词
{
	"tokenizer": "ik_smart",
	"text": "Hxr的西红柿炒蛋"
}
# [hxr 的 西红柿 炒蛋]
```

⑤使用pinyin对搜索分词，索引需要存储全拼分词和拼音首字母分词；

```
GET http://chenjie.asia:9200/gym/_analyze
# 搜索分词
{
	"tokenizer": "ik_smart",
	"filter": {
		"type": "pinyin",
		"keep_first_letter": true,
		"keep_separate_first_letter": false,
		"limit_first_letter_length": 16,
		"keep_full_pinyin": false,
		"keep_joined_full_pinyin": false,
		"keep_none_chinese": true,
		"keep_none_chinese_together": true,
		"keep_none_chinese_in_first_letter": false,
		"keep_none_chinese_in_joined_full_pinyin": false,
		"none_chinese_pinyin_tokenize": true,
		"keep_original": true,
		"lowercase": true,
		"trim_whitespace": true,
		"remove_duplicated_term": true
	},
	"text": "Hxrdexihongshi鸡蛋"
}
# [h x r de xi hong shi hxrdexihongshi 鸡蛋 jd]
```



## 5.2.4.2 项目代码
**①创建索引**

```
PUT http://chenjie.asia:9200/smartcook
# 创建索引
{
	"settings": {
		"analysis": {
			"analyzer": {
				"ngramIndexAnalyzer": {
					"type": "custom",
					"tokenizer": "edge_ngram_tokenizer",
					"filter": ["lowercase"]
				},
				"ngramSearchAnalyzer": {
					"type": "custom",
					"tokenizer": "whitespace",
					"filter": ["lowercase"]
				},
				"pinyinIkmIndexAnalyzer": {
					"type": "custom",
					"tokenizer": "ik_max_word",
					"filter": ["my_synonym","pinyinIndexFilter"]
				},
				"pinyinIksSearchAnalyzer": {
					"type": "custom",
					"tokenizer": "ik_smart",
					"filter": ["my_synonym","pinyinSearchFilter"]
				}
			},
			"tokenizer": {
				"edge_ngram_tokenizer": {
					"type": "edge_ngram",
					"min_gram": 2,
					"max_gram": 16
				}
			},
			"filter": {
				"pinyinIndexFilter": {
					"type": "pinyin",
					"keep_first_letter": true,
					"keep_separate_first_letter": false,
					"limit_first_letter_length": 16,
					"keep_full_pinyin": true,
					"keep_joined_full_pinyin": true,
					"keep_none_chinese": true,
					"keep_none_chinese_together": true,
					"keep_none_chinese_in_first_letter": false,
					"keep_none_chinese_in_joined_full_pinyin": false,
					"none_chinese_pinyin_tokenize": true,
					"keep_original": true,
					"lowercase": true,
					"trim_whitespace": true,
					"remove_duplicated_term": true
				},
				"pinyinSearchFilter": {
					"type": "pinyin",
					"keep_first_letter": true,
					"keep_separate_first_letter": false,
					"limit_first_letter_length": 16,
					"keep_full_pinyin": false,
					"keep_joined_full_pinyin": false,
					"keep_none_chinese": true,
					"keep_none_chinese_together": true,
					"keep_none_chinese_in_first_letter": false,
					"keep_none_chinese_in_joined_full_pinyin": false,
					"none_chinese_pinyin_tokenize": true,
					"keep_original": true,
					"lowercase": true,
					"trim_whitespace": true,
					"remove_duplicated_term": true
				},
				"my_synonym": {
					"type": "synonym",
					"synonyms_path": "/usr/share/elasticsearch/logs/synonym.txt"
				}
			}
		},
		"index":{
            "number_of_shards":3,
            "number_of_replicas":1
        }
	},
	"mappings": {
		"properties": {
			"id": {
				"type": "long"
			},
			"name": {
				"type": "text",
				"index": true,
				"analyzer": "ngramIndexAnalyzer",
				"search_analyzer": "ngramSearchAnalyzer",
				"fields": {
					"PI": {
						"type": "text",
						"index": true,
						"analyzer": "pinyinIkmIndexAnalyzer",
						"search_analyzer": "pinyinIksSearchAnalyzer"
					}
				}
			},
			"score": {
				"type": "float"
			},
			"sub_num": {
				"type": "long"
			}
		}
	}
}
```

**②添加document**

```
POST http://chenjie.asia:9200/smartcook/_doc/1
{
    "name": "hxr的西红柿鸡蛋",
    "score": 4.5,
    "sub_num": 100
}
POST http://chenjie.asia:9200/smartcook/_doc/2
{
    "name": "hxrdexihongshi鸡蛋",
    "score": 3.5,
    "sub_num": 10
}
POST http://chenjie.asia:9200/smartcook/_doc/3
{
	"name": "hxr的西红柿jidan",
	"score": 4.0,
	"sub_num": 150
}
```

**③根据中文汉字、全拼或拼音首字母查找相关document**

```
GET http://chenjie.asia:9200/smartcook/_search
# 检索
{
	"query": {
		"multi_match": {
			"query": "hxrdxhsjd",
			"fields": ["name","name.PI"],
			"type": "best_fields"
		}
	}
}
# 可以检索到所有的文档
```

```
GET http://chenjie.asia:9200/smartcook/_search
# 检索
{
	"query": {
		"multi_match": {
			"query": "hxr的西红柿鸡蛋",
			"fields": ["name^2","name.PI"],
			"type": "best_fields"
		}
	}
}
# 也可以检索到所有的文档
```

```
GET http://chenjie.asia:9200/smartcook/_search
{
	"query": {
		"multi_match": {
			"query": "西红柿鸡d",
			"fields": ["name^2","name.PI"],
			"type": "best_fields"
		}
	}
}
# 可以检索到两条文档 [hxr的西红柿鸡蛋  hxr的西红柿jidan]
```

```
GET http://chenjie.asia:9200/smartcook/_search
# 通过同义词番茄进行检索
{
    "query": {
        "multi_match": {
            "query": "番茄",
            "fields": ["name^2","name.PI"],
            "type": "best_fields"
        }
    }
}
# 可以检索到两条文档 [hxr的西红柿鸡蛋  hxr的西红柿jidan]
```

**可以查看每个字段的文本分词效果**

```
GET http://chenjie.asia:9200/smartcook/_analyze
{
    "field":"name",
    "text":"hxr的西红柿jidan"
}

# 获得分词： [hx hxr hxr的 hxr的西 hxr的西红 hxr的西红柿 hxr的西红柿j hxr的西红柿ji hxr的西红柿jid hxr的西红柿jida  hxr的西红柿jidan]
```

```
GET http://chenjie.asia:9200/smartcook/_analyze
{
    "field":"name.PI",
    "text":"hxr的西红柿jidan"
}

# 获得分词： [h x r hxr de 的 d xi hong shi xihongshi 西红柿 xhs ji dan jidan]
```


<br>
### 5.2.4.3 相关性优化
除了文档匹配度之外，我们需要考量菜谱评分和热度，将其作为影响评分因素。
```
{
	"query": {
		"function_score": {
			"query": {
				"multi_match": {
					"query": "西红柿",
					"fields": ["name","name.PI"],
					"type": "best_fields"
				}
			},
			"functions": [{
				"filter": {
            		"match_all": {
            			"boost": 1
					}
            	},
				"script_score": {
                    "script": {
                        "source": "Math.max(((!doc['score'].empty)? Math.log10(doc['sub_num'].value) : 1), 1)"
                    }
				}
			},
			{
				"field_value_factor": {
                        "field": "score",
                        "factor": "0.1",
                        "modifier": "sqrt",
                        "missing": 1
                }
			}],
			"score_mode": "sum",
            "boost_mode": "multiply"
		}
	}
}
```
>这个相关性优化是瞎弄的，具体项目还得具体讨论。后面如果有时间或者地理信息，还可以引入decay函数。

<br>
# 六、参考

[分析器官网](https://www.elastic.co/guide/en/elasticsearch/reference/current/analysis-analyzers.html)  
[分析器官博](https://elasticstack.blog.csdn.net/article/details/100392478)  
[自定义分析器官博](https://elasticstack.blog.csdn.net/article/details/114278163)

[分布式计分官博](https://elasticstack.blog.csdn.net/article/details/104132454)

[ik分词器官博](https://blog.csdn.net/UbuntuTouch/article/details/100516428)  
[ik分词器Github](https://github.com/medcl/elasticsearch-analysis-ik)  
[pinyin分词器官博](https://blog.csdn.net/UbuntuTouch/article/details/100697156)  
[pinyin分词器Github](https://github.com/medcl/elasticsearch-analysis-pinyin)

[相关性算分Function score query官网](https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-function-score-query.html#query-dsl-function-score-query)  
[相关性算分Script score query官网](https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-script-score-query.html#script-score-sigmoid)  
[相关性算分官博](https://blog.csdn.net/UbuntuTouch/article/details/103643910?ops_request_misc=%257B%2522request%255Fid%2522%253A%2522162149934616780269886619%2522%252C%2522scm%2522%253A%252220140713.130102334.pc%255Fblog.%2522%257D&request_id=162149934616780269886619&biz_id=0&utm_medium=distribute.pc_search_result.none-task-blog-2~blog~first_rank_v2~rank_v29-1-103643910.pc_v2_rank_blog_default&utm_term=function)
