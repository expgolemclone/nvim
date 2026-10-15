# Markdown rendering fixture

日本語と inline `code`, ==highlight==, and [a link](https://example.com).

- A bullet
- [ ] Unchecked
- [x] Checked
- [-] In progress

1. First item
2. Second item

> A quotation.

> [!NOTE]
> A callout.

---

| Name | Value |
| --- | --- |
| Example | 42 |

![image](https://example.com/image.png)
<https://example.com>
<reader@example.com>
[reference][target]

[target]: https://example.com

A footnote[^1] and a footnote link[^2].

[^1]: Footnote text.

[^2]: https://example.com/footnote

<!-- A concealed comment. -->

<div>HTML content</div>

<details>
<summary>Details</summary>
Additional content.
</details>

```javascript
const double = (value) => {
  // Preserve semantic colors.
  return value * 2 + "sample".length;
};
console.log(double(21));
```

```python
# Preserve semantic colors.
def double(value: int) -> int:
    label = "sample"
    return value * 2 + len(label)

print(double(21))
```

```bash
# Preserve semantic colors.
count=21
if [ "$count" -gt 0 ]; then
  printf '%s\n' "sample: $count"
fi
```

Inline math $e^{i\pi} + 1 = 0$ and a fraction $\frac{1}{2}$.

$$
\sum_{n=1}^{\infty} \frac{1}{n^2} = \frac{\pi^2}{6}
$$
