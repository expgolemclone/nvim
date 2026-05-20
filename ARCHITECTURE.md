# Architecture

## 概要

このリポジトリは Neovim 設定を管理する。`init.lua` が起点になり、基本オプション、lazy.nvim の bootstrap、グローバル keymap を設定する。

## Plugin 構成

Plugin 定義は `lua/plugins/*.lua` に分割する。各ファイルは lazy.nvim の spec を返し、補完、LSP、Markdown、Git、UI などの領域ごとに設定を持つ。

## Raw Markdown 編集

`lua/plugins/blink-cmp.lua` は `blink.cmp` の補完設定と挿入モードの `<CR>` 挙動を管理する。`<CR>` はまず補完候補の確定を試し、確定しない場合は ordered list の継続処理を行う。

Ordered list の途中で Enter を押した場合は、新しい番号行を挿入した後、同じインデントかつ同じ区切り文字の後続 item を raw バッファ上で連番に直す。expr keymap の実行中は Neovim が直接のバッファ変更を許可しないため、後続 item の採番更新は keymap の返すキー列が処理された後に `vim.defer_fn` で実行する。

## 検証

`test/ordered_list_enter.lua` は headless Neovim で raw Markdown バッファを作り、実際に `a<CR><Esc>` を入力して ordered list の採番を検証する。

実行コマンド:

```powershell
nvim --headless -u .\init.lua -c "luafile .\test\ordered_list_enter.lua"
```
