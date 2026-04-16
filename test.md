# Markdown 表示テスト

## 見出し (Headings)

# H1 見出し
## H2 見出し
### H3 見出し
#### H4 見出し
##### H5 見出し
###### H6 見出し

---

## テキスト装飾

**太字 (Bold)**
*斜体 (Italic)*
***太字斜体 (Bold Italic)***
~~取り消し線 (Strikethrough)~~
`インラインコード (Inline Code)`

---

## リスト

### 順序なしリスト
- アイテム 1
  - ネスト 1-1
    - さらにネスト 1-1-1
  - ネスト 1-2
- アイテム 2
- アイテム 3

### 順序付きリスト
1. 最初のアイテム
2. 2番目のアイテム
   1. ネスト 2-1
   2. ネスト 2-2
3. 3番目のアイテム

### チェックリスト
- [x] 完了したタスク
- [x] これも完了
- [ ] 未完了のタスク
- [ ] これも未完了

---

## リンクと画像

[プレーンテキストリンク](https://example.com)

[タイトル付きリンク](https://example.com "リンクタイトル")

<https://example.com>

![代替テキスト付き画像](https://via.placeholder.com/150 "画像タイトル")

---

## テーブル

| 左寄せ | 中央寄せ | 右寄せ |
| :--- | :---: | ---: |
| 左 | 中央 | 右 |
| Apple | Banana | Cherry |
| 100 | 200 | 300 |
| 長いテキストの例 | 短い | 中くらい |

---

## コードブロック

### JavaScript
```javascript
function fibonacci(n) {
  if (n <= 1) return n;
  return fibonacci(n - 1) + fibonacci(n - 2);
}

const result = fibonacci(10);
console.log(`Fibonacci(10) = ${result}`);
```

### Python
```python
class Animal:
    def __init__(self, name: str, sound: str):
        self.name = name
        self.sound = sound

    def speak(self) -> str:
        return f"{self.name} says {self.sound}!"

dog = Animal("Dog", "Woof")
print(dog.speak())
```

### Bash
```bash
#!/bin/bash
echo "Hello, World!"
for i in {1..5}; do
  echo "Count: $i"
done
```

### インラインコード
コマンドは `npm install` を実行してください。変数名は `user_name` です。

---

## 引用 (Blockquote)

> これは引用文です。
> 複数行にわたる引用も可能です。
>
> > ネストされた引用です。
> > 引用の中の引用。
>
> 引用に戻ります。

---

## 水平線

---

***

___

（3種類の水平線記法: `---`, `***`, `___`）

---

## 数式 (Math)

### インライン数式
円の面積は $A = \pi r^2$ です。オイラーの等式 $e^{i\pi} + 1 = 0$ も有名です。

### ブロック数式
$$
\int_{-\infty}^{\infty} e^{-x^2} dx = \sqrt{\pi}
$$

$$
\sum_{n=1}^{\infty} \frac{1}{n^2} = \frac{\pi^2}{6}
$$

---

## エスケープ文字

\*アスタリスクをエスケープ\*
\_アンダースコアをエスケープ\_
\# ハッシュをエスケープ

---

## HTML インライン

<div align="center">
  中央寄せテキスト (HTML)
</div>

<details>
<summary>クリックして展開 (Details/Summary)</summary>

隠されたコンテンツがここに表示されます。

- リスト項目 A
- リスト項目 B

</details>

---

## 脚注 (Footnote)

本文中に脚注を付けます[^1]。複数の脚注も可能です[^2]。

[^1]: これは1つ目の脚注です。
[^2]: これは2つ目の脚注です。**太字**も使えます。

---

## 定義リスト (対応環境のみ)

用語
: 定義の説明文

別の用語
: 別の定義

---

## 絵文字

:smile: :heart: :thumbsup: :rocket: :coffee:

---

## タスクリスト付き表

| タスク | 優先度 | 状態 |
| :--- | :---: | :---: |
| フロントエンド実装 | High | :white_check_mark: |
| バックエンド API | Medium | :hourglass: |
| テスト作成 | Low | :x: |

---

## ネストされた構造

1. **第一階層**
   - 箇条書きアイテム
   - もう一つのアイテム
     > ネストされた引用
     > - 引用内のリスト
2. **第二階層**
   - [ ] タスク1
   - [ ] タスク2
     ```js
     console.log("ネストされたコードブロック");
     ```
3. **第三階層**

---

## 特殊文字テスト

| 記号 | 表示 | 記号 | 表示 |
|:---:|:---:|:---:|:---:|
| &amp; | & | &lt; | < |
| &gt; | > | &quot; | " |
| &copy; | © | &reg; | ® |
| &trade; | ™ | &mdash; | — |

---

*最終更新: 2026-04-16*
