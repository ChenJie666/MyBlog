---
title: Elasticsearch自定义分析器（上）
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
      "pattern": "[^\s\p{L}\p{N}]",
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
1. 下载与es版本对应的分词器，这里使用的是7.6.2版本
```
https://github.com/medcl/elasticsearch-analysis-ik/releases/download/v7.6.2/elasticsearch-analysis-ik-7.6.2.zip   # ik分词器
https://github.com/medcl/elasticsearch-analysis-pinyin/releases/download/v7.6.2/elasticsearch-analysis-pinyin-7.6.2.zip   # pinyin分词器
```
2. 将分词器进行安装
```
elasticsearch/bin/elasticsearch-plugin install elasticsearch-analysis-ik-7.6.2.zip
elasticsearch/bin/elasticsearch-plugin install elasticsearch-analysis-pinyin-7.6.2.zip
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

### 2.2.2 同义词（TODO）
```
PUT http://chenjie.asia:9200/ik_synonym
{
	"setting": {
		"analysis": {
			"analyzer": {
				"ik_synonym_analyzer": {
					"tokenizer": "",
					"filter": ""
				}
			},
			"filter": {
				"ik_synonym_filter": {
					"type": "synonym",
					"synonyms_path": "/"
				}
			}
		}
		
	},
	"mappings": {
		"properties": {
			"content": {
				"type": "text",
				"analyzer": "ik_smart"
			},
			"author": {
				"type": "keyword"
        	}
    	}
	}
}
```

### 2.2.3 停用词



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
| `keep_full_pinyin`                        | 保留全拼                                              | `刘德华`> [`liu`,`de`,`hua`]                                       | true   |
| `keep_joined_full_pinyin`                 | 保留全拼组合                                                  | `刘德华`> [`liudehua`]                                 | false  |
| `keep_none_chinese`                       | 过滤掉中文和数字                                |                                                              | true   |
| `keep_none_chinese_together`              | 不切分非中文字母                                             | **当设为true时：**`DJ音乐家` -> `DJ`,`yin`,`yue`,`jia`<br />**当设为false时：**`DJ音乐家` -> `D`,`J`,`yin`,`yue`,`jia` ；**NOTE：**keep_none_chinese需要为true | true   |
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
	"settings": {
		"analysis": {
			"analyzer": {
				"pinyin_analyzer": {
					"tokenizer": "my_pinyin"
				}
			},
			"tokenizer": {
				"my_pinyin": {
					"type": "pinyin",
					"keep_separate_first_letter": false,
					"keep_full_pinyin": true,
					"keep_original": true,
					"limit_first_letter_length": 16,
					"lowercase": true,
					"remove_duplicated_term": true
				}
			}
		}
	},
	"mappings": {
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

# 测试该分词器
GET http://chenjie.asia:9200/diypytest/_analyze
{
	"analyzer": "pinyin_analyzer",
	"text": "西红柿鸡蛋" 
}

# 插入数据
PUT http://chenjie.asia:9200/diypytest/_doc/1
{
	"menu":"西红柿鸡蛋"
}
PUT http://chenjie.asia:9200/diypytest/_doc/2
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

GET http://chenjie.asia:9200/test1/_search
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
	  "properties": {
        "content": {
          "type": "text",
          "analyzer": "ik_smart"
        },
        "author": {
          "type": "keyword"
        }
    }
  }
}


# 插入数据
POST http://chenjie.asia:9200/test2/_doc/1
{
	"content": "I am good!",
	"author": "cj"
}
POST http://chenjie.asia:9200/test2/_doc/2
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

# 插入数据
POST http://chenjie.asia:9200/test3/_doc/1
{
	"content": "我胡汉三又回来了"
}

# 使用拼音和中文都可以检索到这条文档
GET http://chenjie.asia:9200/test3/_search
{
	"query": {
		"multi_match": {
			"query": "huhansan",
			"fields": ["content","content.py"]
		}
	}
}

GET http://chenjie.asia:9200/test3/_search
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
`文章字数受限，下篇请看` [Elasticsearch自定义分析器（下）](https://www.jianshu.com/writer#/notebooks/44681488/notes/88245198)
