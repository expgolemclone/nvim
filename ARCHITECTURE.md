# Architecture

## 概要

このリポジトリは Windows 向けの Neovim 設定を管理する。`init.lua` が起点になり、基本オプション、lazy.nvim の bootstrap、グローバル keymap を設定する。

## Plugin 構成

Plugin 定義は `lua/plugins/*.lua` に分割する。各ファイルは lazy.nvim の spec を返し、補完、LSP、Markdown、Git、UI などの領域ごとに設定を持つ。

## Markdown Enter

`lua/markdown_enter.lua` は Markdown バッファの挿入モード Enter 継続処理を管理する。`blink.cmp` の `<CR>` keymap はまず補完候補の確定を試し、確定しない場合だけ Markdown マーカーの継続処理を行い、それにも該当しない場合は通常の Enter に戻す。

継続対象は行頭の Markdown マーカーに限定する。箇条書き、タスク、番号付きリスト、引用、見出しで Enter を押すと、次の行にも同種のマーカーを挿入する。番号付きリストは常に連番にし、同じ indent、引用 prefix、区切り文字を持つ直後の item も raw バッファ上で連番へ補正する。

## 検証

`test/markdown_enter.lua` は headless Neovim で Markdown バッファを作り、実際に `<CR>` を入力してマーカー継続を検証する。

実行コマンド:

```powershell
nvim --headless -u .\init.lua -c "luafile .\test\markdown_enter.lua"
```
