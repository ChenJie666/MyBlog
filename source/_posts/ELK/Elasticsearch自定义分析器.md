---
title: Elasticsearch自定义分析器
categories:
- ELK
---
`注：代码基于Elasticsearch 7.x，低版本语法稍有不同，需指定type！且低版本可能无法使用相关性计算的一些新特性。`

# 一、分析器
## 1.1 概念：
**分析器包括：**
1. 字符过滤器(CharacterFilters)：首先，字符串按顺序通过每个 字符过滤器 。他们的任务是在分词前整理字符串。一个字符过滤器可以用来去掉HTML，或者将 & 转化成 and；
2. 分词器(Tokenizer)：字符串被 分词器 分为单个的词条。得到分词，标记每个分词的顺序或位置（用于邻近查询），标记分词的起始和结束的偏移量（用于突出显示搜索片段），标记分词的类型；
3. 后过滤器(TokenFilter)：最后，词条按顺序通过每个 token 过滤器 。这个过程可能会改变词条（例如，小写化 Quick ），删除词条（例如， 像 a， and， the 等无用词），或者增加词条（例如，像 jump 和 leap 这种同义词）。

<br>
## 1.2 字符过滤器CharacterFilters
| 字符过滤器类型 | 说明 |
|------------|-----------------|
|  HTML Strip Character Filter(去除html标签和转换html实体)  | The `html_strip` character filter strips out HTML elements like `<b>` and decodes HTML entities like `&amp;`. |
|  Mapping Character Filter(字符串替换操作)  | The `mapping` character filter replaces any occurrences of the specified strings with the specified replacements. |
|  Pattern Replace Character Filter(正则匹配替换)  | The `pattern_replace` character filter replaces any characters matching a regular expression with the specified replacement. |

#### ①使用html_strip字符过滤器
过滤掉文本中的html标签。

| 参数 | 说明 |
|----------|---------|
|escaped_tags|不进行过滤的标签名，多个标签用数组表示|

**默认过滤器配置**
```
GET _analyze
{
  "tokenizer": "keyword",
  "char_filter": [
    "html_strip"
  ],
  "text": "<p>I&apos;m so <b>happy</b>!</p>"
}

# 得到结果 [ 
I'm so happy!
 ]
```

**定制过滤器配置**
```
PUT my-index-000001
{
  "settings": {
    "analysis": {
      "analyzer": {
        "my_analyzer": {
          "tokenizer": "keyword",
          "char_filter": [
            "my_custom_html_strip_char_filter"
          ]
        }
      },
      "char_filter": {
        "my_custom_html_strip_char_filter": {
          "type": "html_strip",
          "escaped_tags": [
            "b"
          ]
        }
      }
    }
  }
}
```

#### ②使用mapping 字符过滤器
对文本进行替换。
| 参数 | 说明 |
|----------|---------|
| mappings | 使用key => value来指定映射关系，多种映射关系用数组表示 |
| mappings_path | 指定配置了mappings映射关系的文件的路径，文件使用UTF-8格式编码，每个映射关系使用换行符分割 |

**默认过滤器配置**
```
GET /_analyze
{
  "tokenizer": "keyword",
  "char_filter": [
    {
      "type": "mapping",
      "mappings": [
        "٠ => 0",
        "١ => 1",
        "٢ => 2",
        "٣ => 3",
        "٤ => 4",
        "٥ => 5",
        "٦ => 6",
        "٧ => 7",
        "٨ => 8",
        "٩ => 9"
      ]
    }
  ],
  "text": "My license plate is ٢٥٠١٥"
}

# 得到结果 [ My license plate is 25015 ]
```

**定制过滤器配置**
```
PUT /my-index-000001
{
  "settings": {
    "analysis": {
      "analyzer": {
        "my_analyzer": {
          "tokenizer": "standard",
          "char_filter": [
            "my_mappings_char_filter"
          ]
        }
      },
      "char_filter": {
        "my_mappings_char_filter": {
          "type": "mapping",
          "mappings": [
            ":) => _happy_",
            ":( => _sad_"
          ]
        }
      }
    }
  }
}
```
测试过滤器
```
GET /my-index-000001/_analyze
{
  "tokenizer": "keyword",
  "char_filter": [ "my_mappings_char_filter" ],
  "text": "I'm delighted about it :("
}

# 结果  [ I'm delighted about it _sad_ ]
```


#### ③使用pattern_replace 字符过滤器
对文本进行正则匹配，对匹配的字符串进行替换。

| 参数 | 说明 |
|----------|---------|
|pattern|java正则表达式|
|replacement|替换字符串, 使用 $1..$9 来对应替换位置|
|flags|Java regular expression [flags](https://docs.oracle.com/javase/8/docs/api/java/util/regex/Pattern.html#field.summary). Flags should be pipe-separated, eg `"CASE_INSENSITIVE\|COMMENTS"`. |

**定制过滤器配置**
```
PUT my-index-00001
{
  "settings": {
    "analysis": {
      "analyzer": {
        "my_analyzer": {
          "tokenizer": "standard",
          "char_filter": [
            "my_char_filter"
          ]
        }
      },
      "char_filter": {
        "my_char_filter": {
          "type": "pattern_replace",
          "pattern": "(\d+)-(?=\d)",
          "replacement": "$1_"
        }
      }
    }
  }
}
```
测试过滤器
```
POST my-index-00001/_analyze
{
  "analyzer": "my_analyzer",
  "text": "My credit card is 123-456-789"
}

# [ My, credit, card, is, 123_456_789 ]
```

<br>
## 1.3 分词器Tokenizer
### 1.3.1 Word Oriented Tokenizers
| 分词器类型 | 说明 |
|------------|-----------------|
|Standard Tokenizer|The `standard` tokenizer divides text into terms on word boundaries, as defined by the Unicode Text Segmentation algorithm. It removes most punctuation symbols. It is the best choice for most languages.|
|Letter Tokenizer|The `letter` tokenizer divides text into terms whenever it encounters a character which is not a letter.|
|Lowercase Tokenizer|The `lowercase` tokenizer, like the `letter `tokenizer, divides text into terms whenever it encounters a character which is not a letter, but it also lowercases all terms.|
|Whitespace Tokenizer|The `whitespace` tokenizer divides text into terms whenever it encounters any whitespace character.|
|UAX URL Email Tokenizer|The `uax_url_email` tokenizer is like the `standard` tokenizer except that it recognises URLs and email addresses as single tokens.|
|Classic Tokenizer|The `classic` tokenizer is a grammar based tokenizer for the English Language.|
|Thai Tokenizer|The `thai` tokenizer segments Thai text into words.|

#### ① Standard
Standard tokenizer是基于<Unicode标准附录#29>中指定的算法进行切分的，如whitespace，‘-’等符号都会进行切分。

| 参数 | 说明 | 默认值 |
|------------|-----------------|---------|
|max_token_length|切分后得到的token的长度如果超过最大token长度，以最大长度间隔拆分 | 默认255|

```
POST _analyze
{
  "tokenizer": "standard",
  "text": "The 2 QUICK Brown-Foxes jumped over the lazy dog's bone."
}

# [ The, 2, QUICK, Brown, Foxes, jumped, over, the, lazy, dog's, bone ]
```

**定制**
```
PUT my-index-000001
{
  "settings": {
    "analysis": {
      "analyzer": {
        "my_analyzer": {
          "tokenizer": "my_tokenizer"
        }
      },
      "tokenizer": {
        "my_tokenizer": {
          "type": "standard",
          "max_token_length": 5
        }
      }
    }
  }
}

POST my-index-000001/_analyze
{
  "analyzer": "my_analyzer",
  "text": "The 2 QUICK Brown-Foxes jumped over the lazy dog's bone."
}

# [ The, 2, QUICK, Brown, Foxes, jumpe, d, over, the, lazy, dog's, bone ]
```

#### ②Letter 
Letter tokenizer遇到非字母时就会进行分词。也就是说，这个分词的结果可以是一整块的的连续的数据内容 。对欧洲语言友好，但是不适用于亚洲语言。

无参数

#### ③Lowercase
Lowercase tokenizer可以看做Letter Tokenizer分词和Lower case Token Filter的结合体。即先用Letter Tokenizer分词，然后再把分词结果全部换成小写格式。

无参数

#### ④Whitespace
Whitespace tokenizer 将文本通过空格进行分词。

| 参数  | 说明                                               |  默认值            |
| ------------------ | -------------------------------------------------- |----------------|
| `max_token_length` | 经过此分词器后所得的数据的最大长度。 |   默认 255  |

#### ⑤UAX Email URL
Uax_url_email tokenizer和standard tokenizer类似，不同的是Uax_url_email tokenizer会将url和邮箱分为单独一个token。而standard tokenizer会将url和邮箱进行切分。

| 参数  | 说明                                               |  默认值            |
| ------------------ | -------------------------------------------------- |----------------|
| `max_token_length` | 经过此分词器后所得的数据的最大长度。 |   默认 255  |


#### ⑥Classic
Classic tokenizer很适合英语编写的文档。 这个分词器对于英文的首字符缩写、 公司名字、 email 、 大部分网站域名都能很好的解决。 但是，对于除了英语之外的其他语言都不好用。
- 会在大部分的标点符号处进行切分并移除标点符号，但是不在空格后的点不会被切分。
- 会在连字符处切分，除非在这个token中有数字，那么整个token会被理解为产品编号而不切分。
- 可以将邮件地址和节点主机名分割为一个token。

| 参数 | 说明                                               |  默认值            |
| ------------------ | -------------------------------------------------- |----------------|
| `max_token_length` | 经过此分词器后所得的数据的最大长度。 |   默认 255  |

```
POST _analyze
{
  "tokenizer": "classic",
  "text": "The 2 QUICK Brown-Foxes jumped over the lazy dog's bone."
}

# [ The, 2, QUICK, Brown, Foxes, jumped, over, the, lazy, dog's, bone ]
```

#### ⑦Thai 
泰语分词器

无参数

### 1.3.2 Partial Word Tokenizers
| 分词器类型 | 说明 |
|------------|-----------------|
|N-Gram Tokenizer|The `ngram` tokenizer can break up text into words when it encounters any of a list of specified characters (e.g. whitespace or punctuation), then it returns n-grams of each word: a sliding window of continuous letters, e.g. `quick → [qu, ui, ic, ck]`.|
|Edge N-Gram Tokenizer|The `edge_ngram` tokenizer can break up text into words when it encounters any of a list of specified characters (e.g. whitespace or punctuation), then it returns n-grams of each word which are anchored to the start of the word, e.g. `quick → [q, qu, qui, quic, quick]`.|

#### ①Ngram 
一个nGram.类型的分词器。
以下是 nGram tokenizer  的设置:
| 参数 | 说明                                                         | 默认值                     |
| -------------- | ------------------------------------------------------------ | -------------------------- |
| `min_gram`     | 分词后词语的最小长度                                         | `1`                       |
| `max_gram`     | 分词后数据的最大长度                                         | `2`                       |
| `token_chars ` | 设置分词的形式，例如数字还是文字。elasticsearch将根据分词的形式对文本进行分词。 | `[]` (Keep all characters) |
token_chars 所接受以下的形式：
| token_chars | 举例 |
| ------------- | -------------------------- |
| `letter     ` | 例如 `a`, `b`, `ï` or `京` |
| `digit`       | 例如`3` or `7`           |
| `whitespace`  | 例如 `" "` or `"
"`       |
| `punctuation` | 例如 `!` or `"`            |
| `symbol `     | 例如 `$` or `√`            |
| `custom`   | custom characters which need to be set using the `custom_token_chars` setting.            |

```
PUT my-index-000001
{
  "settings": {
    "analysis": {
      "analyzer": {
        "my_analyzer": {
          "tokenizer": "my_tokenizer"
        }
      },
      "tokenizer": {
        "my_tokenizer": {
          "type": "ngram",
          "min_gram": 3,
          "max_gram": 3,
          "token_chars": [
            "letter",
            "digit"
          ]
        }
      }
    }
  }
}

POST my-index-000001/_analyze
{
  "analyzer": "my_analyzer",
  "text": "2 Quick Foxes."
}

# [ Qui, uic, ick, Fox, oxe, xes ]
```

#### ②Edge NGram
这个分词和 nGram 非常的类似。但是只是相当于 n-grams 的分词的方式，只保留了“从头至尾”的分词。
以下是 edgeNGram 分词的设置：
| 参数 | 说明 | 默认值 |
|------------|-----------------|---------|
|min_gram|分词后词语的最小长度|1|
|max_gram|分词后词语的最大长度|2|
|token_chars|设置分词的形式，例如，是数字还是文字；将根据分词的形式对文本进行分词|[] (Keep all characters)|

token_chars 所接受以下的形式：
| token_chars | 举例 |
| ------------- | -------------------------- |
| `letter     ` | 例如 `a`, `b`, `ï` or `京` |
| `digit`       | 例如`3` or `7`           |
| `whitespace`  | 例如 `" "` or `"
"`       |
| `punctuation` | 例如 `!` or `"`            |
| `symbol `     | 例如 `$` or `√`            |
| `custom`   | custom characters which need to be set using the `custom_token_chars` setting.            |

```
POST _analyze
{
  "text": "Hélène Ségara it's !<>#",
  "char_filter": [
    {
      "type": "pattern_replace",
      "pattern": """[^\s\p{L}\p{N}]""",
      "replacement": ""
    }
  ],
  "tokenizer": "standard",
  "filter": [
    "lowercase",
    "asciifolding",
    {
      "type": "edge_ngram",
      "min_gram": "1",
      "max_gram": "12"
    }
  ]
}

# [h]  [he]  [hel]  [hele]  [helen]  [s]  [se]  [seg]  [sega]  [segar] [Segara ]  [i]  [it]  [its]  
```


### 1.3.3 Structured Text Tokenizers
| 分词器类型 | 说明 |
|------------|-----------------|
|Keyword Tokenizer|The `keyword` tokenizer is a “noop” tokenizer that accepts whatever text it is given and outputs the exact same text as a single term. It can be combined with token filters like `lowercase` to normalise the analysed terms.|
|Pattern Tokenizer|The pattern `tokenizer` uses a regular expression to either split text into terms whenever it matches a word separator, or to capture matching text as terms.|
|Simple Pattern Tokenizer|The `simple_pattern` tokenizer uses a regular expression to capture matching text as terms. It uses a restricted subset of regular expression features and is generally faster than the `pattern` tokenizer.|
|Char Group Tokenizer|The `char_group` tokenizer is configurable through sets of characters to split on, which is usually less expensive than running regular expressions.|
|Simple Pattern Split Tokenizer|The `simple_pattern_split`  tokenizer uses the same restricted regular expression subset as the `simple_pattern` tokenizer, but splits the input at matches rather than returning the matches as terms.|
|Path Tokenizer|The `path_hierarchy` tokenizer takes a hierarchical value like a filesystem path, splits on the path separator, and emits a term for each component in the tree, e.g. `/foo/bar/baz → [/foo, /foo/bar, /foo/bar/baz ]`.|

#### ①Simple Pattern
Simple Pattern Tokenizer使用正则表达式来匹配符合文本，然后将匹配的文本提取出来作为token，其他部分舍弃。

| 参数 | 说明 | 默认值 |
|--------|--------|----------|
|simple_pattern | [Lucene正则表达式](https://lucene.apache.org/core/8_8_0/core/org/apache/lucene/util/automaton/RegExp.html) | empty string |

```
PUT my-index-000001
{
  "settings": {
    "analysis": {
      "analyzer": {
        "my_analyzer": {
          "tokenizer": "my_tokenizer"
        }
      },
      "tokenizer": {
        "my_tokenizer": {
          "type": "simple_pattern",
          "pattern": "[0123456789]{3}"
        }
      }
    }
  }
}

POST my-index-000001/_analyze
{
  "analyzer": "my_analyzer",
  "text": "fd-786-335-514-x"
}

# [ 786, 335, 514 ]
```

#### ②Simple Pattern Split 
Simple Pattern Split Tokenizer使用Lucene正则表达式来匹配符合文本，将匹配的文本作为分隔符进行切分。它使用的Lucene正则语法没有pattern tokenizer使用的Java正则语法强大，但是效率更高。


| 参数 | 说明 | 默认值 |
|--------|--------|----------|
|`simple_pattern_split` | [Lucene正则表达式](https://lucene.apache.org/core/8_8_0/core/org/apache/lucene/util/automaton/RegExp.html) | empty string |

```
PUT my-index-000001
{
  "settings": {
    "analysis": {
      "analyzer": {
        "my_analyzer": {
          "tokenizer": "my_tokenizer"
        }
      },
      "tokenizer": {
        "my_tokenizer": {
          "type": "simple_pattern_split",
          "pattern": "_"
        }
      }
    }
  }
}

POST my-index-000001/_analyze
{
  "analyzer": "my_analyzer",
  "text": "an_underscored_phrase"
}

# [ an, underscored, phrase ]
```

#### ③Pattern 
Pattern  Tokenizer使用Java正则表达式来匹配符合文本，将匹配的文本作为分隔符进行切分。 

| 参数 | 说明                                          | 默认值   |
| --------- | --------------------------------------------- |------|
| `pattern` | 正则表达式的pattern  |  `\W+`            |
| `flags`   | 正则表达式的 flags. Flags should be pipe-separated, eg "CASE_INSENSITIVE\|COMMENTS"     |           |
| `group`   | 哪个group去抽取数据。 |   `-1` |

```
PUT my-index-000001
{
  "settings": {
    "analysis": {
      "analyzer": {
        "my_analyzer": {
          "tokenizer": "my_tokenizer"
        }
      },
      "tokenizer": {
        "my_tokenizer": {
          "type": "pattern",
          "pattern": ","
        }
      }
    }
  }
}

POST my-index-000001/_analyze
{
  "analyzer": "my_analyzer",
  "text": "comma,separated,values"
}

# [ comma, separated, values ]
```


#### ④Keyword
Keyword Tokenizer 不会对文本进行操作，会将一整块的输入数据作为一个token。

| 设置  |  说明  |  默认值  |
|---------|---------|---|
| `buffer_size` | term buffer 的大小。不建议修改 | 默认256 |


#### ⑤Path Hierarchy
Path_hierarchy Tokenizer会对路径进行逐级划分。示例如下：

>`/something/something/else`
**经过该分词器后会得到如下数据 tokens**
`/something`，`/something/something`，`/something/something/else`

| 参数 | 说明             |    默认值                             |
| ------------- | ----------------------|--------------------------- |
| `delimiter`   | 分隔符 | `/`                               |
| `replacement` | 替代符用于替换分隔符 |  默认与`delimiter`的值相同              |
| `buffer_size` | 缓存buffer的大小  |   `1024`               |
| `reverse`     | 是否将分词后的tokens反转  | `false`        |
| `skip`        | The number of initial tokens to skip |  `0` |

```
PUT my-index-000001
{
  "settings": {
    "analysis": {
      "analyzer": {
        "my_analyzer": {
          "tokenizer": "my_tokenizer"
        }
      },
      "tokenizer": {
        "my_tokenizer": {
          "type": "path_hierarchy",
          "delimiter": "-",
          "replacement": "/",
          "skip": 2
        }
      }
    }
  }
}

POST my-index-000001/_analyze
{
  "analyzer": "my_analyzer",
  "text": "one-two-three-four-five"
}

# [ /three, /three/four, /three/four/five ]

# 如果reverse设置为true，得到如下token
# [ one/two/three/, two/three/, three/ ]
```

#### ⑥Character group 
`char_group` Tokenizer通过字符进行切分，可以在参数中指定字符进行切分。

| 参数 | 说明             |    默认值                             |
| ------------- | ----------------------|--------------------------- |
| `tokenize_on_chars`   | 分隔符或分隔符组成的数组，like e.g. `-`, or character groups: `whitespace`, `letter`, `digit`, `punctuation`, `symbol`|                             |
| `max_token_length` | token最大长度，超过后按最大长度再次切分 |  `255`        |

```
POST _analyze
{
  "tokenizer": {
    "type": "char_group",
    "tokenize_on_chars": [
      "whitespace",
      "-",
      "
"
    ]
  },
  "text": "The QUICK brown-fox"
}

# [ The, QUICK, brown, fox ]
```


<br>
## 1.4 后过滤器TokenFilter
**后过滤器是有顺序的，所以需要注意数组中的顺序。**

太多了，需要的话直接点进官网看吧，常用的做下说明：
| 后过滤器类型 | 说明 |
|------------|-----------------|
| [Apostrophe](https://www.elastic.co/guide/en/elasticsearch/reference/current/analysis-apostrophe-tokenfilter.html)||
|[ASCII folding](https://www.elastic.co/guide/en/elasticsearch/reference/current/analysis-asciifolding-tokenfilter.html)|Converts alphabetic, numeric, and symbolic characters that are not in the Basic Latin Unicode block (first 127 ASCII characters) to their ASCII equivalent, if one exists. For example, the filter changes à to a.|
|[CJK bigram](https://www.elastic.co/guide/en/elasticsearch/reference/current/analysis-cjk-bigram-tokenfilter.html)||
|[CJK width](https://www.elastic.co/guide/en/elasticsearch/reference/current/analysis-cjk-width-tokenfilter.html)||
|[Classic](https://www.elastic.co/guide/en/elasticsearch/reference/current/analysis-classic-tokenfilter.html)||
|[Common grams](https://www.elastic.co/guide/en/elasticsearch/reference/current/analysis-common-grams-tokenfilter.html)||
|[Conditional](https://www.elastic.co/guide/en/elasticsearch/reference/current/analysis-condition-tokenfilter.html)||
|[Decimal digit](https://www.elastic.co/guide/en/elasticsearch/reference/current/analysis-decimal-digit-tokenfilter.html)||
|[Delimited payload](https://www.elastic.co/guide/en/elasticsearch/reference/current/analysis-delimited-payload-tokenfilter.html)||
|[Dictionary decompounder](https://www.elastic.co/guide/en/elasticsearch/reference/current/analysis-dict-decomp-tokenfilter.html)||
|[Edge n-gram](https://www.elastic.co/guide/en/elasticsearch/reference/current/analysis-edgengram-tokenfilter.html)|Forms an [n-gram](https://en.wikipedia.org/wiki/N-gram) of a specified length from the beginning of a token. |
|[Elision](https://www.elastic.co/guide/en/elasticsearch/reference/current/analysis-elision-tokenfilter.html)||
|[Fingerprint](https://www.elastic.co/guide/en/elasticsearch/reference/current/analysis-fingerprint-tokenfilter.html)|Sorts and removes duplicate tokens from a token stream, then concatenates the stream into a single output token.|
|[Flatten graph](https://www.elastic.co/guide/en/elasticsearch/reference/current/analysis-flatten-graph-tokenfilter.html)||
|[Hunspell](https://www.elastic.co/guide/en/elasticsearch/reference/current/analysis-hunspell-tokenfilter.html)||
|[Hyphenation decompounder](https://www.elastic.co/guide/en/elasticsearch/reference/current/analysis-hyp-decomp-tokenfilter.html)||
|[Keep types](https://www.elastic.co/guide/en/elasticsearch/reference/current/analysis-keep-types-tokenfilter.html)||
|[Keep words](https://www.elastic.co/guide/en/elasticsearch/reference/current/analysis-keep-words-tokenfilter.html)||
|[Keyword marker](https://www.elastic.co/guide/en/elasticsearch/reference/current/analysis-keyword-marker-tokenfilter.html)||
|[Keyword repeat](https://www.elastic.co/guide/en/elasticsearch/reference/current/analysis-keyword-repeat-tokenfilter.html)|Outputs a keyword version of each token in a stream. These keyword tokens are not stemmed.|
|[KStem](https://www.elastic.co/guide/en/elasticsearch/reference/current/analysis-kstem-tokenfilter.html)||
| [Length](https://www.elastic.co/guide/en/elasticsearch/reference/current/analysis-length-tokenfilter.html) ||
| [Limit token count](https://www.elastic.co/guide/en/elasticsearch/reference/current/analysis-limit-token-count-tokenfilter.html)||
| [Lowercase](https://www.elastic.co/guide/en/elasticsearch/reference/current/analysis-lowercase-tokenfilter.html)|Changes token text to lowercase. For example, you can use the lowercase filter to change THE Lazy DoG to the lazy dog.|
| [MinHash](https://www.elastic.co/guide/en/elasticsearch/reference/current/analysis-minhash-tokenfilter.html)||
| [Multiplexer](https://www.elastic.co/guide/en/elasticsearch/reference/current/analysis-multiplexer-tokenfilter.html)||
| [N-gram](https://www.elastic.co/guide/en/elasticsearch/reference/current/analysis-ngram-tokenfilter.html)|Forms [n-grams](https://en.wikipedia.org/wiki/N-gram) of specified lengths from a token.|
| [Normalization](https://www.elastic.co/guide/en/elasticsearch/reference/current/analysis-normalization-tokenfilter.html)||
| [Pattern capture](https://www.elastic.co/guide/en/elasticsearch/reference/current/analysis-pattern-capture-tokenfilter.html)||
| [Pattern replace](https://www.elastic.co/guide/en/elasticsearch/reference/current/analysis-pattern_replace-tokenfilter.html)||
| [Phonetic](https://www.elastic.co/guide/en/elasticsearch/reference/current/analysis-phonetic-tokenfilter.html)||
| [Porter stem](https://www.elastic.co/guide/en/elasticsearch/reference/current/analysis-porterstem-tokenfilter.html)||
| [Predicate script](https://www.elastic.co/guide/en/elasticsearch/reference/current/analysis-predicatefilter-tokenfilter.html)||
| [Remove duplicates](https://www.elastic.co/guide/en/elasticsearch/reference/current/analysis-remove-duplicates-tokenfilter.html)|Removes duplicate tokens in the same position.|
| [Reverse](https://www.elastic.co/guide/en/elasticsearch/reference/current/analysis-reverse-tokenfilter.html)|Reverses each token in a stream. For example, you can use the reverse filter to change cat to tac.|
| [Shingle](https://www.elastic.co/guide/en/elasticsearch/reference/current/analysis-shingle-tokenfilter.html)||
| [Snowball](https://www.elastic.co/guide/en/elasticsearch/reference/current/analysis-snowball-tokenfilter.html)||
| [Stemmer](https://www.elastic.co/guide/en/elasticsearch/reference/current/analysis-stemmer-tokenfilter.html)|Provides [algorithmic stemming](https://www.elastic.co/guide/en/elasticsearch/reference/current/stemming.html#algorithmic-stemmers "Algorithmic stemmers") for several languages, some with additional variants. For a list of supported languages, see the [`language`](https://www.elastic.co/guide/en/elasticsearch/reference/current/analysis-stemmer-tokenfilter.html#analysis-stemmer-tokenfilter-language-parm) parameter.|
| [Stemmer override](https://www.elastic.co/guide/en/elasticsearch/reference/current/analysis-stemmer-override-tokenfilter.html)||
| [Stop](https://www.elastic.co/guide/en/elasticsearch/reference/current/analysis-stop-tokenfilter.html)|Removes [stop words](https://en.wikipedia.org/wiki/Stop_words) from a token stream.|
| [Synonym](https://www.elastic.co/guide/en/elasticsearch/reference/current/analysis-synonym-tokenfilter.html)|The synonym token filter allows to easily handle synonyms during the analysis process. Synonyms are configured using a configuration file.|
| [Synonym graph](https://www.elastic.co/guide/en/elasticsearch/reference/current/analysis-synonym-graph-tokenfilter.html)||
| [Trim](https://www.elastic.co/guide/en/elasticsearch/reference/current/analysis-trim-tokenfilter.html)|Removes leading and trailing whitespace from each token in a stream. While this can change the length of a token, the trim filter does not change a token’s offsets.|
| [Truncate](https://www.elastic.co/guide/en/elasticsearch/reference/current/analysis-truncate-tokenfilter.html)||
| [Unique](https://www.elastic.co/guide/en/elasticsearch/reference/current/analysis-unique-tokenfilter.html)|Removes duplicate tokens from a stream. For example, you can use the unique filter to change the lazy lazy dog to the lazy dog.|
| [Uppercase](https://www.elastic.co/guide/en/elasticsearch/reference/current/analysis-uppercase-tokenfilter.html)|Changes token text to uppercase. For example, you can use the uppercase filter to change the Lazy DoG to THE LAZY DOG.|
| [Word delimiter](https://www.elastic.co/guide/en/elasticsearch/reference/current/analysis-word-delimiter-tokenfilter.html)||
| [Word delimiter graph](https://www.elastic.co/guide/en/elasticsearch/reference/current/analysis-word-delimiter-graph-tokenfilter.html)||


#### ①Edge n-gram
`edge_ngram`效果同`ngram`，区别是`edge_ngram`只会从头开始切分，同样是fox，拆成[ f, fo ]

| 参数              | 说明                                              | 默认值 |
| ----------------- | ------------------------------------------------- | ------ |
| `min_gram`        | 拆分的最小长度                                    | 1      |
| `max_gram`        | 拆分的最大长度                                    | 2      |
| preserve_original | Emits original token when set to `true`.          | false  |
| side              | 已废弃. 指定从token的 `front` 或是 `back`开始截取 | front  |

```
GET _analyze
{
  "tokenizer": "standard",
  "filter": [
    { "type": "edge_ngram",
      "min_gram": 1,
      "max_gram": 2
    }
  ],
  "text": "the quick brown fox jumps"
}

# [ t, th, q, qu, b, br, f, fo, j, ju ]
```


#### ②N-gram
可以使用`ngram`将fox拆成[ f, fo, o, ox, x ]。

| 参数              | 说明                                              | 默认值 |
| ----------------- | ------------------------------------------------- | ------ |
| `min_gram`        | 拆分的最小长度                                    | 1      |
| `max_gram`        | 拆分的最大长度                                    | 2      |
| preserve_original | Emits original token when set to `true`.          | false  |

**具体演示如下**
```
GET _analyze
{
  "tokenizer": "standard",
  "filter": [ "ngram" ],
  "text": "Quick fox"
}

# [ Q, Qu, u, ui, i, ic, c, ck, k, f, fo, o, ox, x ]
```

#### ③Stop 
Stop后过滤器用于过滤掉停用词。

| 参数              | 说明                                    | 默认值     |
| ----------------- | --------------------------------------- | ---------- |
| `stopwords`       | 预先定义的停用词或停用词组成的数组      | \_english_ |
| `stopwords_path`  | 停用词文件的路径                        |            |
| `ignore_case`     | 是否大小写敏感                          | false      |
| `remove_trailing` | 如果流的最后一个token是停用词，是否删除 | true       |

**默认的\_english_过滤词组用于过滤掉**`a, an, and, are, as, at, be, but, by, for, if, in, into, is, it, no, not, of, on, or, such, that, the, their, then, there, these, they, this, to, was, will,  with`

```
GET /_analyze
{
  "tokenizer": "standard",
  "filter": [ "stop" ],
  "text": "a quick fox jumps over the lazy dog"
}

# [ quick, fox, jumps, over, lazy, dog ]
```

#### ④Stemmer
为部分语言提供了[algorithmic stemming](https://www.elastic.co/guide/en/elasticsearch/reference/current/stemming.html#algorithmic-stemmers "Algorithmic stemmers")。
获得token的词源并替换该token。

```
GET /_analyze
{
  "tokenizer": "standard",
  "filter": [ "stemmer" ],
  "text": "the foxes jumping quickly"
}

# [ the, fox, jump, quickli ]
```

#### ⑤Keyword repeat
对每个token进行复制并返回。一般配合Stemmer和Remove duplicates。Stemmer获取词源时不会保留原token，在Stemmer之前加Keyword repeat就可以同时获取词源和原词。但是有些token的词源就是原token，造成同一位置上有重复的token，则可以通过Remove duplicates进行去重。

```
GET _analyze
{
  "tokenizer": "whitespace",
  "filter": [
    "keyword_repeat",
    "stemmer"
  ],
  "text": "fox running"
}

{
    "tokens": [
        {
            "token": "fox",
            "start_offset": 0,
            "end_offset": 3,
            "type": "word",
            "position": 0
        },
        {
            "token": "fox",
            "start_offset": 0,
            "end_offset": 3,
            "type": "word",
            "position": 0
        },
        {
            "token": "running",
            "start_offset": 4,
            "end_offset": 11,
            "type": "word",
            "position": 1
        },
        {
            "token": "run",
            "start_offset": 4,
            "end_offset": 11,
            "type": "word",
            "position": 1
        }
    ]
}
```

#### ⑥Remove duplicates
删除同一位置(start_offset)上的相同的token。一般配合Stemmer和使用。

**如下同一位置出现了重复的token**
```
GET _analyze
{
  "tokenizer": "whitespace",
  "filter": [
    "keyword_repeat",
    "stemmer"
  ],
  "text": "jumping dog"
}

{
  "tokens": [
    {
      "token": "jumping",
      "start_offset": 0,
      "end_offset": 7,
      "type": "word",
      "position": 0
    },
    {
      "token": "jump",
      "start_offset": 0,
      "end_offset": 7,
      "type": "word",
      "position": 0
    },
    {
      "token": "dog",
      "start_offset": 8,
      "end_offset": 11,
      "type": "word",
      "position": 1
    },
    {
      "token": "dog",
      "start_offset": 8,
      "end_offset": 11,
      "type": "word",
      "position": 1
    }
  ]
}
```
**使用remove_duplicates**
```
GET _analyze
{
  "tokenizer": "whitespace",
  "filter": [
    "keyword_repeat",
    "stemmer",
    "remove_duplicates"
  ],
  "text": "jumping dog"
}

{
  "tokens": [
    {
      "token": "jumping",
      "start_offset": 0,
      "end_offset": 7,
      "type": "word",
      "position": 0
    },
    {
      "token": "jump",
      "start_offset": 0,
      "end_offset": 7,
      "type": "word",
      "position": 0
    },
    {
      "token": "dog",
      "start_offset": 8,
      "end_offset": 11,
      "type": "word",
      "position": 1
    }
  ]
}
```

#### ⑦Uppercase
将token都转变为大写。
如将 `The Lazy DoG` 转变为 `THE LAZY DOG`。

#### ⑧Lowercase
将token都转变为小写。
如将 `The Lazy DoG` 转变为 `the lazy dog`。

#### ⑨ASCII folding
`asciifolding`将不在基本拉丁Unicode块中的字母、数字和符号字符（前127个ASCII字符）转换为其ASCII等效字符（如果存在）。例如更改à 到a。

```
GET /_analyze
{
  "tokenizer" : "standard",
  "filter" : ["asciifolding"],
  "text" : "açaí à la carte"
}

# [ acai, a, la, carte ]
```

#### ⑩Fingerprint
删除重复的token，并对token进行排序，然后将排序后的token作为一个token输出。

如使用Fingerprint过滤 [ the, fox, was, very, very, quick ] 步骤如下：
1）先进行排序 [ fox, quick, the, very, very, was ]
2）删除重复的token
3）变成一个token输出 [fox quick the very was ]

```
GET _analyze
{
  "tokenizer" : "whitespace",
  "filter" : ["fingerprint"],
  "text" : "zebra jumps over resting resting dog"
}

# [ dog jumps over resting zebra ]
```

#### ⑪Trim
删除每个token的最前和最后面的空格符，但是不会改变token的offset位置。
`standard`和`whitespace` tokenizer默认使用Trim，当使用这两个时可以不用添加Trim后过滤器。

#### ⑫Unique
过滤掉重复的token，如the lazy lazy dog进行过滤后得到the lazy dog。
对比Remove duplicates，Unique只需要token相同即可。

#### ⑬Synonym
同义词标记过滤器允许在分析过程中处理同义词。同义词是使用配置文件配置的。

| 参数            | 说明                                                         | 默认值 |
| --------------- | ------------------------------------------------------------ | ------ |
| `expand`        | If the mapping was "bar, foo, baz" and `expand` was set to `false` no mapping would get added as when `expand=false` the target mapping is the first word. However, if `expand=true` then the mappings added would be equivalent to `foo, baz => foo, baz` i.e, all mappings other than the stop word. | true   |
| `lenient`       | If `true` ignores exceptions while parsing the synonym configuration. It is important to note that only those synonym rules which cannot get parsed are ignored. | false  |
| `synonyms`      | 指定同义词，如 [ "foo, bar => baz" ]                         |        |
| `synonyms_path` | 同义词文件的路径                                             |        |
| `tokenizer`     | The `tokenizer` parameter controls the tokenizers that will be used to tokenize the synonym, this parameter is for backwards compatibility for indices that created before 6.0. |        |
| `ignore_case`   | The `ignore_case` parameter works with `tokenizer` parameter only. |        |

注：如果目标同义词(=>符号后的词)是停用词，那么这个同义词映射就会失效。如果查询的词(=>符号前的词)是停用词，那么这个词就会失效。

```
PUT /test_index
{
  "settings": {
    "index": {
      "analysis": {
        "analyzer": {
          "synonym": {
            "tokenizer": "standard",
            "filter": [ "my_stop", "synonym" ]
          }
        },
        "filter": {
          "my_stop": {
            "type": "stop",
            "stopwords": [ "bar" ]
          },
          "synonym": {
            "type": "synonym",
            "lenient": true,
            "synonyms": [ "foo, bar => baz" ]
          }
        }
      }
    }
  }
}
```
**使用同义词配置文件**
```
PUT /test_index
{
  "settings": {
    "index": {
      "analysis": {
        "analyzer": {
          "synonym": {
            "tokenizer": "whitespace",
            "filter": [ "synonym" ]
          }
        },
        "filter": {
          "synonym": {
            "type": "synonym",
            "synonyms_path": "analysis/synonym.txt"
          }
        }
      }
    }
  }
}
```

文件格式如下
```
# Blank lines and lines starting with pound are comments.

# Explicit mappings match any token sequence on the LHS of "=>"
# and replace with all alternatives on the RHS.  These types of mappings
# ignore the expand parameter in the schema.
# Examples:
i-pod, i pod => ipod
sea biscuit, sea biscit => seabiscuit

# Equivalent synonyms may be separated with commas and give
# no explicit mapping.  In this case the mapping behavior will
# be taken from the expand parameter in the schema.  This allows
# the same synonym file to be used in different synonym handling strategies.
# Examples:
ipod, i-pod, i pod
foozball , foosball
universe , cosmos
lol, laughing out loud

# If expand==true, "ipod, i-pod, i pod" is equivalent
# to the explicit mapping:
ipod, i-pod, i pod => ipod, i-pod, i pod
# If expand==false, "ipod, i-pod, i pod" is equivalent
# to the explicit mapping:
ipod, i-pod, i pod => ipod

# Multiple synonym mapping entries are merged.
foo => foo bar
foo => baz
# is equivalent to
foo => foo bar, baz
```

注：经验所得，带有 synonym 的 analyzer 适用于 search 而不适用于存储 index。
- synonym 增加了field 的 term 数量(导致评分参数 avgdl 变大)， 还有重要的是 如果使用 match query 的话，会导致 匹配的 termFreq 增加到 synonym 的数量，影响评分。
- 如果 同义词变化的话，需要同步更新所有的关系到同义词的文档。
- 对于匹配原词 和 他的同义词，往往原词的 评分应该更高。但是 ES 中却一视同仁。没有区别。虽然可以通过定义不同的 field ，一个 field 使用 完全切分，一个field 使用同义词，并且在search时，给 全完且分词field 一个较高的权重。但是又带来了怎加了term 存储的容量扩大问题。

#### ⑭Reverse
将每个token翻转，如将cat替换为tac。


11. asciifolding
```
POST _analyze
{
  "text": "Hélène Ségara it's !<>#",
  "char_filter": [
    {
      "type": "pattern_replace",
      "pattern": "[^\s\p{L}\p{N}]",
      "replacement": ""
    }
  ], 
  "tokenizer": "standard",
  "filter": [
    "lowercase",
    "asciifolding"
  ]  
}

# [helene]  [segara]  [its]
```

<br>
## 1.5 分析器Analyzer
以下是es自带的分析器，绝大多数的分析器我们可以通过以上介绍的CharFilter，Tokenizer和TokenFilter自己组合实现相同的功能。
| 分析器类型 | 说明 |
|----------------|--------|
| Standard Analyzer | The `standard` analyzer divides text into terms on word boundaries, as defined by the Unicode Text Segmentation algorithm. It removes most punctuation, lowercases terms, and supports removing stop words. |
| Simple Analyzer | The `simple` analyzer divides text into terms whenever it encounters a character which is not a letter. It lowercases all terms. |
| Whitespace Analyzer | The `whitespace` analyzer divides text into terms whenever it encounters any whitespace character. It does not lowercase terms. |
| Stop Analyzer | The `stop` analyzer is like the simple analyzer, but also supports removal of stop words. |
| Keyword Analyzer | The `keyword` analyzer is a “noop” analyzer that accepts whatever text it is given and outputs the exact same text as a single term. |
| Pattern Analyzer | The `pattern` analyzer uses a regular expression to split the text into terms. It supports lower-casing and stop words. |
| Language Analyzer |Elasticsearch provides many language-specific analyzers like `english` or `french`.|
| Fingerprint Analyzer | The `fingerprint` analyzer is a specialist analyzer which creates a fingerprint which can be used for duplicate detection. |

#### ①Standard Analyzer
standard analyzer 是 Elasticsearch 的缺省分析器：
- 没有 Char Filter
- 使用 standard tokonizer
- 使用lowercase filter和stop token filter。默认的情况下 stop words 为 _none_，也即不过滤任何 stop words。

| 参数 | 说明 | 默认值 |
| ------------------ | -----------------------------------|------------------------- |
| `max_token_length` | 分词后单个token的最大长度，如果超过最大长度，按最大长度分词 | Defaults to `255`. |
| `stopwords`        | 预先定义的停用词或停用词组成的数组   | Defaults to `_none_`. |
| `stopwords_path`   | 停用词文件的路径                    |   |


**直接使用**
```
POST _analyze
{
  "analyzer": "standard",
  "text": "The 2 QUICK Brown-Foxes jumped over the lazy dog's bone."
}

# [ the, 2, quick, brown, foxes, jumped, over, the, lazy, dog's, bone ]
```

**指定参数**
```
PUT my-index-000001
{
  "settings": {
    "analysis": {
      "analyzer": {
        "my_english_analyzer": {
          "type": "standard",
          "max_token_length": 5,
          "stopwords": "_english_"
        }
      }
    }
  }
}

POST my-index-000001/_analyze
{
  "analyzer": "my_english_analyzer",
  "text": "The 2 QUICK Brown-Foxes jumped over the lazy dog's bone."
}

# [ 2, quick, brown, foxes, jumpe, d, over, lazy, dog's, bone ]
```


#### ②Simple Analyzer
简单分析器
- 没有Char Filter
- 使用Lowercase Tokenier
- 没有TokenFilter

#### ③Whitespace Analyzer
空格分析器，遇到空格
- 没有Char Filter
- 使用Whitespace Tokenier
- 没有TokenFilter


#### ④Stop Analyzer
与简单分析器类似，但是添加了停用词，默认使用的是`_english_`停用词。
- 没有Char Filter
- 使用Lowercase Tokenier
- 使用Stop token filter，默认为`_english_`

|  参数  | 说明  |  默认值  |
| ------------------ | ---------------------------------------------------|--------- |
| `stopwords`        | 预先定义的停用词或停用词组成的数组   | `_none_` |
| `stopwords_path`   | 停用词文件的路径                    |  |

**直接使用**
```
POST _analyze
{
  "analyzer": "stop",
  "text": "The 2 QUICK Brown-Foxes jumped over the lazy dog's bone."
}

# [ quick, brown, foxes, jumped, over, lazy, dog, s, bone ]
```

**指定参数**
```
PUT my-index-000001
{
  "settings": {
    "analysis": {
      "analyzer": {
        "my_stop_analyzer": {
          "type": "stop",
          "stopwords": ["the", "over"]
        }
      }
    }
  }
}

POST my-index-000001/_analyze
{
  "analyzer": "my_stop_analyzer",
  "text": "The 2 QUICK Brown-Foxes jumped over the lazy dog's bone."
}

# [ quick, brown, foxes, jumped, lazy, dog, s, bone ]
```

#### ⑤Keyword Analyzer
keyword分析器
- 没有Char Filter
- 使用Keyword Tokenier
- 没有TokenFilter


#### ⑥Language Analyzer
语言分析器，支持如下类型：`arabic`, `armenian`, `basque`, `bengali`, `brazilian`, `bulgarian`, `catalan`, `cjk`, `czech`, `danish`, `dutch`, `english`, `estonian`, `finnish`, `french`, `galician`, `german`, `greek`, `hindi`, `hungarian`, `indonesian`, `irish`, `italian`, `latvian`, `lithuanian`, `norwegian`, `persian`, `portuguese`, `romanian`, `russian`, `sorani`, `spanish`, `swedish`, `turkish`, `thai`.

**我们只会用到type为english的分析器吧**
- 没有Char Filter
- 使用Standard Tokenizer
- 使用Stemmer过滤器

|  参数  | 说明  |  默认值  |
| ------------------ | ---------------------------------------------------|--------- |
| `stopwords`        | 预先定义的停用词或停用词组成的数组   | Defaults to `_english_`. |
| `stopwords_path`   | 停用词文件的路径                   |  |

**直接使用**
```
GET _analyze
{
  "analyzer": "english",
  "text": "Running Apps in a Phone"
}

# [run]  [app]  [phone]
```

**创建一个自定义分析器实现english分析器的功能**
```
PUT /english_example
{
  "settings": {
    "analysis": {
      "filter": {
        "english_stop": {
          "type":       "stop",
          "stopwords":  "_english_" 
        },
        "english_keywords": {
          "type":       "keyword_marker",
          "keywords":   ["example"] 
        },
        "english_stemmer": {
          "type":       "stemmer",
          "language":   "english"
        },
        "english_possessive_stemmer": {
          "type":       "stemmer",
          "language":   "possessive_english"
        }
      },
      "analyzer": {
        "rebuilt_english": {
          "tokenizer":  "standard",
          "filter": [
            "english_possessive_stemmer",
            "lowercase",
            "english_stop",
            "english_keywords",
            "english_stemmer"
          ]
        }
      }
    }
  }
}
```

#### ⑦Pattern Analyzer
- 没有CharFilter
- 分词器使用Pattern Tokenizer
- Token Filters使用Lower Case Token Filter和Stop Token Filter (disabled by default)

| 参数 | 说明 | 默认值 |
| ---------------- | ------------------------------------------------------------ | ------- |
| `pattern`        | Java正则表达式 |  `\W+`  |
| `flags`          | Java regular expression flags. Flags should be pipe-separated, eg `"CASE_INSENSITIVE\|COMMENTS"`. |  |
| `lowercase`      | Should terms be lowercased or not. Defaults to `true`.       | true    |
| `stopwords`      | 预先定义的停用词或停用词组成的数组                           | \_none_ |
| `stopwords_path` | 停用词文件的路径                                             |         |

**直接使用**
```
POST _analyze
{
  "analyzer": "pattern",
  "text": "The 2 QUICK Brown-Foxes jumped over the lazy dog's bone."
}

# [ the, 2, quick, brown, foxes, jumped, over, the, lazy, dog, s, bone ]
```

**指定参数**
```
PUT my-index-000001
{
  "settings": {
    "analysis": {
      "analyzer": {
        "my_email_analyzer": {
          "type":      "pattern",
          "pattern":   "\W|_", 
          "lowercase": true
        }
      }
    }
  }
}

POST my-index-000001/_analyze
{
  "analyzer": "my_email_analyzer",
  "text": "John_Smith@foo-bar.com"
}

# [ john, smith, foo, bar, com ]
```

#### ⑧Fingerprint Analyzer
Fingerprint Analyzer实现了[fingerprinting](https://github.com/OpenRefine/OpenRefine/wiki/Clustering-In-Depth#fingerprint)
算法。文本会被转为小写格式，经过规范化处理后移除扩展字符，然后再经过排序，删除重复数据组合为单个token；

- 没有CharFilter
- Tokenizer使用Standard Tokenizer
- Token Filters 使用Lower Case Token Filter、ASCII folding、Stop Token Filter (disabled by default)、Fingerprint

| 参数              | 说明                                                         | 默认值               |
| ----------------- | ------------------------------------------------------------ | -------------------- |
| `separator`       | The character to use to concatenate the terms.               | Defaults to a space. |
| `max_output_size` | token允许的最大值就，超过该值直接丢弃 | 255                  |
| `stopwords`       | 预先定义的停用词或停用词组成的数组                           | _none_               |
| `stopwords_path`  | 停用词文件的路径                                             |                      |

**直接使用**
```
POST _analyze
{
  "analyzer": "fingerprint",
  "text": "Yes yes, Gödel said this sentence is consistent and."
}

# [ and consistent godel is said sentence this yes ]
```

**指定参数**
```
PUT my-index-000001
{
  "settings": {
    "analysis": {
      "analyzer": {
        "my_fingerprint_analyzer": {
          "type": "fingerprint",
          "stopwords": "_english_"
        }
      }
    }
  }
}

POST my-index-000001/_analyze
{
  "analyzer": "my_fingerprint_analyzer",
  "text": "Yes yes, Gödel said this sentence is consistent and."
}

# [ consistent godel said sentence yes ]
```

<br>
## 1.6 自定义分析器示例
#### 示例一
```
PUT chenjie.asia:9200/analyzetest
{
    "settings":{
        "analysis":{
            "analyzer":{
                "my":{                //分析器
                    "tokenizer":"punctuation",    //指定所用的分词器
                    "type":"custom",        //自定义类型的分析器
                    "char_filter":["emoticons"],    //指定所用的字符过滤器
                    "filter":["lowercase","english_stop"]
                }
            },
            "char_filter":{        //字符过滤器
                "emoticons":{        //字符过滤器的名字
                    "type":"mapping",    //匹配模式
                    "mappings":[
                        ":)=>_happy_",        //如果匹配上:)，那么替换为_happy_
                        ":(=>_sad_"            //如果匹配上:(，那么替换为_sad_
                    ]
                }
            },
            "tokenizer":{        //分词器
                "punctuation":{    //分词器的名字
                    "type":"pattern",    //正则匹配分词器
                    "pattern":"[.,!?]"    //通过正则匹配方式匹配需要作为分隔符的字符，此处为 . , ! ? ，作为分隔符进行分词
                }
            },
            "filter":{        //后过滤器
                "english_stop":{    //后过滤器的名字
                    "type":"stop",       //停用词
                    "stopwords":"_english_"    //指定停用词，过滤掉停用词
                }
            }
        }
    }
}

# GET chenjie.asia:9200/analyzetest/_analyze
{
	"analyzer": "my",
	"text": "I am a  :)  person,and you"
}
```
>上述自定义分析器对文本  "I am a  :)  person,and you"  进行分词 ，最终得到两个分词   "I am a  _happy_  person" 和 "and you"  ;
> 第一步：用字符过滤器将 :) 替换为 _happy_
> 第二步：用分词器，通过正则表达式匹配到逗号，在逗号处进行分词
> 第三步：过滤停用词

#### 示例二
```
{
  "settings": {
    "analysis": {
      "analyzer": {
        "my_content_analyzer": {
          "type": "custom",
          "char_filter": [
            "xschool_filter"
          ],
          "tokenizer": "standard",
          "filter": [
            "lowercase",
            "my_stop"
          ]
        }
      },
      "char_filter": {
        "xschool_filter": {
          "type": "mapping",
          "mappings": [
            "X-School => XSchool"
          ]
        }
      },
      "filter": {
        "my_stop": {
          "type": "stop",
          "stopwords": ["so", "to", "the"]
        }
      }
    }
  },
  "mappings": {
  	"type":{
	  "properties": {
	    "content": {
	      "type": "text",
	      "analyzer": "my_content_analyzer",
	      "search_analyzer": "standard"
	    }
	  }
    }
  }
}
```
>可以指定搜索时，搜索进行制定具体的搜索词分析器 `search_analyzer`。




<br>
# 二、ik和pinyin分词器
## 2.1 安装ik和pinyin分词器
1. 下载与es版本对应的分词器，这里使用的是5.6.3版本
```
https://github.com/medcl/elasticsearch-analysis-ik/releases/download/v5.6.3/elasticsearch-analysis-ik-5.6.3.zip   # ik分词器
https://github.com/medcl/elasticsearch-analysis-pinyin/releases/download/v5.6.3/elasticsearch-analysis-pinyin-5.6.3.zip   # pinyin分词器
```
2. 将分词器进行安装
```
elasticsearch/bin/elasticsearch-plugin install elasticsearch-analysis-ik-5.6.3.zip
elasticsearch/bin/elasticsearch-plugin install elasticsearch-analysis-pinyin-5.6.3.zip
```

**如何扩展ik分词器库**
添加自定义的词到ik分词器库，使得分词器可以切割出指定的词。
进入到plugins中的ik分词器的config文件夹下，创建文件myword.dic，在该文件中添加自定义词，然后将该文件配置到IKAnalyzer.conf.xml中的扩展字典中<entry key="ext_dict">myword.dic</entry>。然后重启。
```
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE properties SYSTEM "http://java.sun.com/dtd/properties.dtd">
<properties>
	<comment>IK Analyzer 扩展配置</comment>
	<!--用户可以在这里配置自己的扩展字典 -->
	<entry key="ext_dict">custom/mydict.dic;custom/single_word_low_freq.dic</entry>
	 <!--用户可以在这里配置自己的扩展停止词字典-->
	<entry key="ext_stopwords">custom/ext_stopword.dic</entry>
 	<!--用户可以在这里配置远程扩展字典 -->
	<entry key="remote_ext_dict">location</entry>
 	<!--用户可以在这里配置远程扩展停止词字典-->
	<entry key="remote_ext_stopwords">http://xxx.com/xxx.dic</entry>
</properties>
```

**热更新 IK 分词使用方法**
目前该插件支持热更新 IK 分词，通过上文在 IK 配置文件中提到的如下配置
```
 	<!--用户可以在这里配置远程扩展字典 -->
	<entry key="remote_ext_dict">location</entry>
 	<!--用户可以在这里配置远程扩展停止词字典-->
	<entry key="remote_ext_stopwords">location</entry>
```
其中 location 是指一个 url，比如 http://yoursite.com/getCustomDict，该请求只需满足以下两点即可完成分词热更新。
1. 该 http 请求需要返回两个头部(header)，一个是 Last-Modified，一个是 ETag，这两者都是字符串类型，只要有一个发生变化，该插件就会去抓取新的分词进而更新词库。
2. 该 http 请求返回的内容格式是一行一个分词，换行符用 
 即可。

满足上面两点要求就可以实现热更新分词了，不需要重启 ES 实例。
可以将需自动更新的热词放在一个 UTF-8 编码的 .txt 文件里，放在 nginx 或其他简易 http server 下，当 .txt 文件修改时，http server 会在客户端请求该文件时自动返回相应的 Last-Modified 和 ETag。可以另外做一个工具来从业务系统提取相关词汇，并更新这个 .txt 文件。

<br>
## 2.2 ik分词器
### 2.2.1 ik分词器
Elasticsearch 内置的分词器对中文不友好，只会一个字一个字的分，无法形成词语，因此引入ik分词器。

**ik分词器包括**
- 分析器Analyzer：ik_smart , ik_max_word
- 分词器Tokenizer: ik_smart , ik_max_word

>**ik_max_word 和 ik_smart 什么区别?**
>- ik_max_word: 会将文本做最细粒度的拆分，比如会将“中华人民共和国国歌”拆分为“中华人民共和国,中华人民,中华,华人,人民共和国,人民,人,民,共和国,共和,和,国国,国歌”，会穷尽各种可能的组合，适合 Term Query；
>- ik_smart: 会做最粗粒度的拆分，比如会将“中华人民共和国国歌”拆分为“中华人民共和国,国歌”，适合 Phrase 查询。

### 2.2.2 定制ik分词器



<br>
## 2.3 pinyin分词器
### 2.3.1 pinyin分词器
该拼音分析插件用于汉字与拼音的转换，集成了[NLP工具](https://github.com/NLPchina/nlp-lang)。

**插件包括：**
- 分析器Analyzer: pinyin 
- 分词器Tokenizer: pinyin
- 后过滤器Token-filter:  pinyin

| 参数                                      | 说明                                                         | 示例                                                         | 默认值 |
| ----------------------------------------- | ------------------------------------------------------------ | ------------------------------------------------------------ | ------ |
| `keep_first_letter`                       | 保留拼音首字母组合                                           | `刘德华`>`ldh`                                               | true   |
| `keep_separate_first_letter`              | 保留拼音首字母                                               | `刘德华`>`l`,`d`,`h`                                         | false  |
| `limit_first_letter_length`               | 设置最长拼音首字母组合                                       |                                                              | 16     |
| `keep_full_pinyin`                        | 保留全拼组合                                                 | `刘德华`> [`liudehua`]                                       | true   |
| `keep_joined_full_pinyin`                 | 保留全拼                                                     | `刘德华`> [`liu`,`de`,`hua`]                                 | false  |
| `keep_none_chinese`                       | `keep_none_chinese`需要为true                                |                                                              | true   |
| `keep_none_chinese_together`              | 不切分非中文字母                                             | **当设为true时：**`DJ音乐家` -> `DJ`,`yin`,`yue`,`jia`<br />**当设为false时：**`DJ音乐家` -> `D`,`J`,`yin`,`yue`,`jia` | true   |
| `keep_none_chinese_in_first_letter`       | 中文转为拼音首字母，并将非中文字母与拼音合并                 | `刘德华AT2016`->`ldhat2016`                                  | true   |
| `keep_none_chinese_in_joined_full_pinyin` | 中文转为全拼，并将非中文字母与拼音合并                       | `刘德华2016`->`liudehua2016`                                 | false  |
| `none_chinese_pinyin_tokenize`            | 如果非中文字母是拼音，则将它们分成单独的拼音词。`keep_none_chinese` 和`keep_none_chinese_together` 需要为true。 | `liudehuaalibaba13zhuanghan` -> `liu`,`de`,`hua`,`a`,`li`,`ba`,`ba`,`13`,`zhuang`,`han` | true   |
| `keep_original`                           | 是否保留原输入                                               |                                                              | false  |
| `lowercase`                               | 是否小写非中文字母                                           |                                                              | true   |
| `trim_whitespace`                         | 首位去空格                                                   |                                                              | true   |
| `remove_duplicated_term`                  | 会移除重复的短语，可能会影响位置相关的查询结果。             | `de的`>`de`                                                  | false  |
| `ignore_pinyin_offset`                    | after 6.0, offset is strictly constrained, overlapped tokens are not allowed, with this parameter, overlapped token will allowed by ignore offset, please note, all position related query or highlight will become incorrect, you should use multi fields and specify different settings for different query purpose. if you need offset, please set it to false. |                                                              | true   |



### 2.3.2 使用示例
#### 使用pinyin分词器
创建一个名为diypytest的索引，该索引中使用了一个pinyin tokenizer。

```
# 创建索引
PUT http://chenjie.asia:9200/diypytest
{
	"settings" : {
        "analysis" : {
            "analyzer" : {
                "pinyin_analyzer" : {
                    "tokenizer" : "my_pinyin"
                    }
            },
            "tokenizer" : {
                "my_pinyin" : {
                    "type" : "pinyin",
                    "keep_separate_first_letter" : false,
                    "keep_full_pinyin" : true,
                    "keep_original" : true,
                    "limit_first_letter_length" : 16,
                    "lowercase" : true,
                    "remove_duplicated_term" : true
                }
            }
        }
    },
	"mappings":{
		"type":{
			"properties": {
		        "menu": {
		      		"type": "keyword",
		      		"fields": {
		        		"pinyin": {
		        	  		"type": "text",
		        	  		"store": false,
		        	  		"term_vector": "with_offsets",
		        	  		"analyzer": "pinyin_analyzer",
		        	  		"boost": 10
		        		}
		      		}
		    	}
		  	}
		}
	}
}

# 测试该分词器
GET http://chenjie.asia:9200/diypytest/_analyze
{
	"analyzer": "pinyin_analyzer",
	"text": "西红柿鸡蛋" 
}

# 插入数据
put http://chenjie.asia:9200/diypytest/1
{
	"menu":"西红柿鸡蛋"
}
put http://chenjie.asia:9200/diypytest/2
{
	"menu":"韭菜鸡蛋"
}

# 查询数据
GET http://chenjie.asia:9200/diypytest/_search?q=menu:xhsjd  // 查询为空
GET http://chenjie.asia:9200/diypytest/_search?q=menu.pinyin:xhsjd  // 查询得到结果
```


#### 使用pinyin-tokenFilter
创建一个名为diypytest2的索引，该索引中使用了一个pinyin后过滤器。

```
# 创建索引
http://chenjie.asia:9200/diypytest2
{
    "settings" : {
        "analysis" : {
            "analyzer" : {
                "menu_analyzer" : {
                    "tokenizer" : "whitespace",
                    "filter" : "pinyin_first_letter_and_full_pinyin_filter"
                }
            },
            "filter" : {
                "pinyin_first_letter_and_full_pinyin_filter" : {
                    "type" : "pinyin",
                    "keep_first_letter" : true,
                    "keep_full_pinyin" : false,
                    "keep_none_chinese" : true,
                    "keep_original" : false,
                    "limit_first_letter_length" : 16,
                    "lowercase" : true,
                    "trim_whitespace" : true,
                    "keep_none_chinese_in_first_letter" : true
                }
            }
        }
    }
}

# 测试分词器
http://chenjie.asia:9200/diypytest2/_analyze
{
	"analyzer":"menu_analyzer",
	"text":"西红柿鸡蛋 韭菜鸡蛋 糖醋里脊"
}

# 结果如下
{
    "tokens": [
        {
            "token": "xhsjd",
            "start_offset": 0,
            "end_offset": 5,
            "type": "word",
            "position": 0
        },
        {
            "token": "jcjd",
            "start_offset": 6,
            "end_offset": 10,
            "type": "word",
            "position": 1
        },
        {
            "token": "tclj",
            "start_offset": 11,
            "end_offset": 15,
            "type": "word",
            "position": 2
        }
    ]
}
```

#### 为索引添加自定义分词器
```
PUT  my_analyzer
{
    "settings":{
        "analysis":{
            "analyzer":{
                "my":{                //分析器
                    "tokenizer":"punctuation",    //指定所用的分词器
                    "type":"custom",        //自定义类型的分析器
                    "char_filter":["emoticons"],    //指定所用的字符过滤器
                    "filter":["lowercase","english_stop"]
                },
                "char_filter":{        //字符过滤器
                    "emoticons":{        //字符过滤器的名字
                        "type":"mapping",    //匹配模式
                        "mapping":[
                            ":)=>_happy_",        //如果匹配上:)，那么替换为_happy_
                            ":(=>_sad_"            //如果匹配上:(，那么替换为_sad_
                        ]
                    }
                },
                "tokenizer":{        //分词器
                    "punctuation":{    //分词器的名字
                        "type":"pattern",    //正则匹配分词器
                        "pattern":"[.,!?]"    //通过正则匹配方式匹配需要作为分隔符的字符，此处为 . , ! ? ，作为分隔符进行分词
                    }
                },
                "filter":{        //后过滤器
                    "english_stop":{    //后过滤器的名字
                        "type":"stop",       //停用词
                        "stopwords":"_english_"    //指定停用词，不影响分词，但不允许查询
                    }
                }
            }
        }
    }
}
```

> 例如用上述自定义分析器对文本  "I am a  :)  person,and you"  进行分词 ，最终得到两个分词   "I am a  _happy_  person" 和 "and you"  ;
> 第一步：用字符过滤器将 :) 替换为 _happy_
> 第二步：用分词器，通过正则表达式匹配到逗号，在逗号处进行分词
> 第三步：不查询停用词



<br>
# 三、检索

## 3.1 Field的配置

定义一个字段的时候，可以选择如下属性进行配置。

```json
"field": {  
         "type":  "text", //文本类型  ，指定类型
      
         "index": "analyzed", //该属性共有三个有效值：analyzed、no和not_analyzed，默认是analyzed；analyzed：表示该字段被分析，编入索引，产生的token能被搜索到；not_analyzed：表示该字段不会被分析，使用原始值编入索引，在索引中作为单个词；no：不编入索引，无法搜索该字段；
         
         "analyzer":"ik"//指定分词器  
         
         "boost":1.23//字段级别的分数加权  
         
         "doc_values":false//对not_analyzed字段，默认都是开启，analyzed字段不能使用，对排序和聚合能提升较大性能，节约内存,如果您确定不需要对字段进行排序或聚合，或者从script访问字段值，则可以禁用doc值以节省磁盘空间：
         
         "fielddata":{"loading" : "eager" }//Elasticsearch 加载内存 fielddata 的默认行为是 延迟 加载 。 当 Elasticsearch 第一次查询某个字段时，它将会完整加载这个字段所有 Segment 中的倒排索引到内存中，以便于以后的查询能够获取更好的性能。
         
         "fields":{"keyword": {"type": "keyword","ignore_above": 256}} //可以对一个字段提供多种索引模式，同一个字段的值，一个分词，一个不分词  
         
         "ignore_above":100 //超过100个字符的文本，将会被忽略，不被索引
           
         "include_in_all":ture//设置是否此字段包含在_all字段中，默认是true，除非index设置成no选项  
         
         "index_options":"docs"//4个可选参数docs（索引文档号） ,freqs（文档号+词频），positions（文档号+词频+位置，通常用来距离查询），offsets（文档号+词频+位置+偏移量，通常被使用在高亮字段）分词字段默认是position，其他的默认是docs  
         
         "norms":{"enable":true,"loading":"lazy"}//分词字段默认配置，不分词字段：默认{"enable":false}，存储长度因子和索引时boost，建议对需要参与评分字段使用 ，会额外增加内存消耗量  
         
         "null_value":"NULL"//设置一些缺失字段的初始化值，只有string可以使用，分词字段的null值也会被分词  
         
         "position_increament_gap":0//影响距离查询或近似查询，可以设置在多值字段的数据上火分词字段上，查询时可指定slop间隔，默认值是100  
         
         "store":false//是否单独设置此字段的是否存储而从_source字段中分离，默认是false，只能搜索，不能获取值  
         
         "search_analyzer":"ik"//设置搜索时的分词器，默认跟ananlyzer是一致的，比如index时用standard+ngram，搜索时用standard用来完成自动提示功能  
         
         "similarity":"BM25"//默认是TF/IDF算法，指定一个字段评分策略，仅仅对字符串型和分词类型有效  
         
         "term_vector":"no"//默认不存储向量信息，支持参数yes（term存储），with_positions（term+位置）,with_offsets（term+偏移量），with_positions_offsets(term+位置+偏移量) 对快速高亮fast vector highlighter能提升性能，但开启又会加大索引体积，不适合大数据量用  
} 
```



## 3.2 检索

### 3.2.1 搜索词的分词

每当一个文档在被录入到 Elasticsearch中 时，需要一个叫做 index 的过程。在 index 的过程中，它会为该字符串进行分词，并最终形成一个一个的 token，并存于数据库。但是，每当我们搜索一个字符串时，在搜索时，我们同样也要对该字符串进行分词，也会建立token，但不会存于数据库。

①当你查询一个 全文 域时(match)， 会对查询字符串应用相同的分析器(或使用指定的分析器`search_analyzer`)，以产生正确的搜索词条列表。
②当你查询一个 精确值 域时(term)，不会分析查询字符串，而是搜索你指定的精确值。



**示例：**

```
PUT http://chenjie.asia:9200/test1
{
  "mappings": {
    "properties": {
      "content": {
        "type": "text",
        "analyzer": "standard",
        "search_analyzer": "english"
      }
    }
  }
}

GET /chinese/_search
{
  "query": {
    "match": {
      "content": "Happy a birthday"
    }
  }
}
```

> 对于这个搜索来说，我们在默认的情况下，会把 "Happy a birthday" 使用同样的 `standard analyzer` 进行分词。如果我们指定`search_analyzer`为`english analyzer` 过滤器，它就会把字母 “a” 过滤掉，那么直剩下 “happy” 及 “birthday” 这两个词，而 “a” 将不进入搜索之中。



### 3.2.2 单字段检索

如上所示，使用match进行检索。



### 3.2.3 多字段检索

#### 检索多个field

```
PUT http://chenjie.asia:9200/test2
{
  "mappings": {
  	"type": {
	  "properties": {
        "content": {
          "type": "text",
          "analyzer": "ik_smart"
          }
        },
        "author": {
          "type": "keyword"
        }
      }
    }
  }
}


# 插入数据
POST http://chenjie.asia:9200/test2/type/1
{
	"content": "I am good!",
	"author": "cj"
}
POST http://chenjie.asia:9200/test2/type/2
{
	"content": "CJ is good!",
	"author": "zs"
}

# 进行检索，以上两条都可以检索到，因为字段中有匹配的分词
{
	"query": {
		"multi_match": {
			"query": "cj",
			"fields": ["content","author"]
		}
	}
}
```





#### 检索一个字段的多种索引模式

当我们需要对某个字段进行多种方式的分词，使用多个不同的 anaylzer 来提高我们的搜索，就可以使用fields定义多种分析方式，使用不同的分析器来分析同样的一个字符串。

```
PUT http://chenjie.asia:9200/test3
{
  "mappings": {
  	"type": {
	  "properties": {
        "content": {
          "type": "text",
          "analyzer": "ik_smart", 
          "fields": {
            "py": {
              "type": "text",
              "analyzer": "pinyin"
            }
          }
        }
      }
    }
  }
}

# 插入数据
POST http://chenjie.asia:9200/test3/type/1
{
	"content": "我胡汉三又回来了"
}

# 使用拼音和中文都可以检索到这条文档
GET http://chenjie.asia:9200/test4/_search
{
	"query": {
		"multi_match": {
			"query": "huhansan",
			"fields": ["content","content.py"]
		}
	}
}

GET http://chenjie.asia:9200/test4/_search
{
	"query": {
		"multi_match": {
			"query": "胡汉三",
			"fields": ["content","content.py"]
		}
	}
}
```



#### 五种类型的multi match query

1. best_fields: (default) Finds documents which match any field, but uses the _score from the best field.
2. most_fields: Finds documents which match any field and combines the _score from each field.(与best_fields不同之处在于相关性评分，best_fields取最大匹配得分（max计算），而most_fields取所有匹配之和（sum计算）)
3. cross_fields: Treats fields with the same analyzer as though they were one big field. Looks for each word in any field.(所有输入的Token必须在同一组的字段上全部匹配,)
4. phrase: Runs a match_phrase query on each field and combines the _score from each field.
5. phrase_prefix: Runs a match_phrase_prefix query on each field and combines the _score from each field.

```
GET http://chenjie.asia:9200/article/_search
{
    "query": {
        "multi_match": {
            "query": "hxr",
            "fields": [
                "name^5",
                "name.FPY",
                "name.SPY",
                "name.IKS^0.8"
            ],
            "type": "best_fields"
        }
    }
}
```


<br>

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

- 1）**TF（Term Frequency）**：词频，即单词在文档中出现的次数，词频越高，相关度越高。TF 的计算永远是100%的精确，这是因为它是一个文档级的计算，文档内容可以在本地分片中获取。公式为`tf(t in d) = √frequency`，即term在文件 d 的词频（tf）是这个术语在文档中出现次数的平方根)![image.png](Elasticsearch自定义分析器.assets\8291da9706434ca7818183f225ebaf15.png)
- 2）**IDF（Inverse Document Frequency）**：逆向文档词频 ，计算公式为 term/document ，即单词出现的文档数越少，相关度越高。公式为`idf(t) = 1 + log ( numDocs / (docFreq + 1)) `，即术语t的逆向文档频率（Inverse document frequency）是：索引中文档数量除以所有包含该术语文档数量后的对数值。![image.png](Elasticsearch自定义分析器.assets\d980c99a75794dba9d8c0276b3c56479.png)
- 3）**Field-length Norm**：字段长度正则值，较短的字段比较长的字段更相关。`norm(d) = 1 / √numTerms`，即字段长度正则值是字段中术语数平方根的倒数。
- 4）**Query Normalization Factor**：查询正则因子（queryNorm）试图将查询正则化，这样就能比较两个不同查询结果。尽管查询正则值的目的是为了使查询结果之间能够相互比较，但是它并不十分有效，因为相关度分数_score 的目的是为了将当前查询的结果进行排序，比较不同查询结果的相关度分数没有太大意义。
- 5）**Query Coordination**：协调因子（coord）可以为那些查询术语包含度高的文档提供“奖励”，文档里出现的查询术语越多，它越有机会成为一个好的匹配结果。
- 6）**Query-Time Boosting：**查询时权重提升，在搜索时使用权重提升参数让一个查询语句比其他语句更重要。查询时的权重提升是我们可以用来影响相关度的主要工具，任意一种类型的查询都能接受权重提升（boost）参数。将权重提升值设置为2，并不代表最终的分数会是原值的2倍；权重提升值会经过正则化和一些其他内部优化过程。

<br>

### 4.1.2 计算模型

4.x之前的计算模型如下
![image.png](Elasticsearch自定义分析器.assetse31bb67ad45417c8b567d50e0952268.png)

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

衰减函数对文档进行评分，该函数的衰减取决于文档的数字字段值距用户给定原点的距离。这类似于范围查询，但具有平滑的边缘而不是框。

要在具有数字字段的查询上使用距离计分，用户必须为每个字段定义an`origin`和a `scale`。的`origin` 需要，以限定从该计算出的距离的“中心点”，并且`scale`定义衰减率。衰减函数指定为



衰减函数（Decay Function）提供了一个更为复杂的公式，它描述了这样一种情况：对于一个字段，它有一个理想的值，而字段实际的值越偏离这个理想值（无论是增大还是减小），就越不符合期望。 有三种衰减函数——线性（linear）、指数（exp）和高斯（gauss）函数，它们可以操作数值、时间以及 经纬度地理坐标点这样的字段。常见的Decay function有以下三种：

![img](三、es分词器tmp.assets/20191221164124868.png)

- **gauss**

  正常衰减，计算如下：

    ![高斯型](三、es分词器tmp.assets/Gaussian-1621841975571.png)

  其中西格玛被计算以确保得分取值`decay`在距离`scale`从`origin`+ -`offset`

    ![sigma calc](三、es分词器tmp.assets/sigma_calc-1621842004438.png)

  See [Normal decay, keyword `gauss`](https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-function-score-query.html#gauss-decay) for graphs demonstrating the curve generated by the `gauss` function.

  

- **exp**

  指数衰减，计算如下：

    ![指数的](三、es分词器tmp.assets/Exponential-1621842014436.png)

  其中再次参数拉姆达被计算，以确保该得分取值`decay`在距离`scale`从`origin`+ -`offset`

    ![λ计算](三、es分词器tmp.assets/lambda_calc-1621842020804.png)

  See [Exponential decay, keyword `exp`](https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-function-score-query.html#exp-decay) for graphs demonstrating the curve generated by the `exp` function.

  

- **linear**

  线性衰减，计算如下：

    ![线性的](三、es分词器tmp.assets/Linear-1621842032402.png)

  其中再次参数`s`被计算，以确保该得分取值`decay`在距离`scale`从`origin`+ -`offset`

    ![计算](三、es分词器tmp.assets/s_calc-1621842041501.png)

  与正常和指数衰减相反，如果字段值超过用户给定标度值的两倍，则此函数实际上将分数设置为0。



三个都能接受以下参数：

| 属性     | 说明                                                         |
| -------- | ------------------------------------------------------------ |
| `origin` | 用于计算距离的原点。对于数字字段，必须指定为数字；对于日期字段，必须指定为日期；对于地理字段，必须指定为地理点。地理位置和数字字段必填。对于日期字段，默认值为`now`。支持日期计算如`now-1h`。 |
| `scale`  | 所有函数都不能缺省。表示到origin距离为offset+scale的位置，该位置的分数为decay的值。对于地理字段：可以定义为数字+单位，如"1km"，"12m"，默认单位是米。对于日期字段：可以定义为数字+单位，如"1h"，"10d"等，默认单位是毫秒。对于数字字段：可以是任何数字。 |
| `offset` | 如果`offset`定义了，那么衰减函数仅计算到origin的距离大于offset的值`。默认值为0。 |
| `decay`  | 该`decay`参数定义了在距离origin为offset+scale处的score的值。默认值为0.5。 |

![高斯](三、es分词器tmp.assets/decay_2d.png)

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
# 五、小项目
## 5.1 项目准备
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

### 5.1.1 单机部署es 7.8.0
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
```
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
```

#### 启动es容器
```
docker run -d --privileged -e ES_JAVA_OPTS="-Xms256m -Xmx256m" --name es1 -p 9200:9200 -p 9300:9300 -v /root/docker/es/conf/es1.yml:/usr/share/elasticsearch/config/elasticsearch.yml  -v /root/docker/es/data/es1data:/usr/share/elasticsearch/data -v  /root/docker/es/logs:/usr/share/elasticsearch/logs es_ik_py:7.8.0
```
>如果启动异常，可能是没有挂载文件没有写权限，执行`chmod -R 777 /root/docker/es/data/es1data /root/docker/es/logs`

<br>
### 5.1.3 配置同义词和停用词


<br>
## 5.2 项目目标
**自定义分析器实现对菜谱的搜索。**

- **要求一：**多样的搜索方式。
如搜索<火星人的西红柿鸡蛋>这道菜，可以通过如下方式搜索：
①可以通过拼音首字母搜索，如hxr，xhs等。要求是有意义的词语首字母。
②可以通过全拼搜索，如 huoxingren，xihongshi。
③可以通过菜谱名的前n个字搜索，如 火星。
④可以通过有意义的中文名搜索，如 西红柿。
⑤可以通过全拼与拼音首字母混搭搜索，如 hxrdexihongshi。
⑥可以通过拼音首字母与中文混搭搜索，如 hxr的西红柿。
⑦可以通过全拼与中文混搭搜索，如 火星人的xihongshi。

- **要求二：**对敏感词进行停用处理。
- **要求三：**考虑同义词，如番茄和西红柿是同义词。
- **要求四：**搜索打分需要考虑菜谱的热度和评分。


**分析：**
①和②先使用ik_max_word分出有意义的中文词组，再通过pinyin filter转换为拼音首字母和全拼。搜索时需要输入
③使用edge_ngram tokenizer进行分词，min_gram = 2
④使用ik_max_word分出有意义的中文词组。
⑤
⑦使用edge_ngram tokenizer进行分词


## 5.3 项目代码
```
PUT http://chenjie.asia:9200/smartcook

{
	"settings": {
		"analysis": {
			"filter": {
				"edge_ngram_filter": {
					"type": "edge_ngram",
					"min_gram": 1,
					"max_gram": 50
				},
				"pinyin_simple_filter": {
					"type": "pinyin",
					"keep_first_letter": true,
					"keep_separate_first_letter": false,
					"keep_full_pinyin": false,
					"keep_original": false,
					"limit_first_letter_length": 50,
					"lowercase": true
				},
				"pinyin_full_filter": {
					"type": "pinyin",
					"keep_first_letter": false,
					"keep_separate_first_letter": false,
					"keep_full_pinyin": true,
					"none_chinese_pinyin_tokenize": true,
					"keep_original": false,
					"limit_first_letter_length": 50,
					"lowercase": true
				}
			},
			"analyzer": {
				"ngramIndexAnalyzer": {
					"type": "custom",
					"tokenizer": "keyword",
					"filter": ["edge_ngram_filter", "lowercase"]
				},
				"ngramSearchAnalyzer": {
					"type": "custom",
					"tokenizer": "keyword",
					"filter": ["lowercase"]
				},
				"pinyinSimpleIndexAnalyzer": {
					"tokenizer": "keyword",
					"filter": ["pinyin_simple_filter", "edge_ngram_filter", "lowercase"]
				},
				"pinyinSimpleSearchAnalyzer": {
					"tokenizer": "keyword",
					"filter": ["pinyin_simple_filter", "lowercase"]
				},
				"pinyinFullIndexAnalyzer": {
					"tokenizer": "keyword",
					"filter": ["pinyin_full_filter", "lowercase"]
				},
				"pinyinFullSearchAnalyzer": {
					"tokenizer": "keyword",
					"filter": ["pinyin_full_filter", "lowercase"]
				}
			}
		},
		"index": {
			"number_of_shards": 3,
			"number_of_replicas": 1
		}
	},
	"mappings": {
		"smartmenu": {
			"properties": {
				"id": {
					"type": "long"
				},
				"name": {
					"type": "text",
					"index": "analyzed",
					"analyzer": "ngramIndexAnalyzer",
					"search_analyzer": "ngramSearchAnalyzer",
					"fields": {
						"SPY": {
							"type": "text",
							"index": "analyzed",
							"analyzer": "pinyinSimpleIndexAnalyzer",
							"search_analyzer": "pinyinSimpleIndexAnalyzer"
						},
						"FPY": {
							"type": "text",
							"index": "analyzed",
							"analyzer": "pinyinFullIndexAnalyzer",
							"search_analyzer": "pinyinFullIndexAnalyzer"
						},
						"IKS": {
							"type": "text",
							"index": "analyzed",
							"analyzer": "ik_smart",
							"search_analyzer": "ik_smart"
						}
					}
				},
				"author": {
					"type": "text",
					"index": "no"
				},
				"url": {
					"type": "text",
					"index": "no"
				},
				"subscribe": {
					"type": "long",
					"index": "not_analyzed"
				},
				"create_time": {
					"type": "date",
					"format": "yyyy-MM-dd",
					"index": "not_analyzed"
				}
			}
		}
	}
}
```

③添加document

```
POST http://chenjie.asia:9200/smartcook/menus/5

{
    "id":5,
    "name":"火星人的西红柿炒蛋",
    "author":"火星人官方",
    "url":"www.xxx.com/xxx.jpg",
    "subscribe":99,
    "create_time":"2020-02-21"
}
```

④根据中文汉字、全拼或拼音首字母查找相关document

```
GET http://chenjie.asia:9200/smartcook/menus/_search

{
    "query": {
        "multi_match": {
            "query": "xhs",
            "fields": [
                "name^5",
                "name.FPY",
                "name.SPY",
                "name.IKS^0.8"
            ],
            "type": "best_fields"
        }
    }
}
```

⑤删除索引

```
DELETE http://192.168.32.225:9201/smartcook

简易自定义拼音中文分词器：

PUT http://116.62.148.11:9100/blog_ik_py

{

    "settings":{

        "analysis":{

            "analyzer":{

                "ik_smart_pinyin":{

                    "type":"custom",

                    "tokenizer":"ik_smart",

                    "filter":["my_pinyin","word_delimiter"]

                },

                "ik_max_word_pinyin":{

                    "type":"custom",

                    "tokenizer":"ik_max_word",

                    "filter":["my_pinyin","word_delimiter"]

                }

            },

            "filter":{

                "my_pinyin":{

                    "type":"pinyin",

                    "keep_separate_first_letter":true,

                    "keep_full_pinyin":true,

                    "keep_original":true,

                    "limit_first_letter_length":16,

                    "lowercase":true,

                    "remove_duplicated_term":true

                }

            }

        },

        "index":{

            "number_of_shards":3,

            "number_of_replicas":1

        }

    }

}
```



**文本分词效果：**
http://192.168.32.225:9201/smartcooktest/_analyze

```
GET http://chenjie.asia:9200/smartcooktest/_analyze

{
"field":"name",
"text":"鸡蛋 辣椒"
}

获得四个分词：  [鸡]   [鸡蛋]   [鸡蛋 ]   [鸡蛋 辣]   [鸡蛋 辣椒]
```

```
GET http://chenjie.asia:9200/smartcooktest/_analyze

{
"field":"name.FPY",
"text":"鸡蛋 辣椒"
}

# 获得四个分词：  [ji]   [dan]   [la]   [jiao]
```

```
GET http://chenjie.asia:9200/smartcooktest/_analyze

{
"field":"name.SPY",
"text":"鸡蛋 辣椒"
}

# 获得四个分词：  [j]   [jd]   [jdl]   [jdlj]
```

```
GET http://chenjie.asia:9200/smartcooktest/_analyze

{
"field":"name.IKS",
"text":"鸡蛋 辣椒"
}

# 获得两个分词：  [鸡蛋]   [辣椒]
```





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
