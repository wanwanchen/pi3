讚，給你一份**精練但夠用的 Vim 指令小抄**（含你目前 vimrc 的快捷鍵與我幫你加的外掛指令）。建議收藏。

# 0) 你這份 vimrc 的快捷鍵（先記這些最常用）

| 快捷               | 作用                                                                |
| ---------------- | ----------------------------------------------------------------- |
| `Ctrl+h/j/k/l`   | 切到左/下/上/右邊視窗                                                      |
| `Ctrl+b`         | 文字↔二進位模式切換（binary/noeol ↔ nobinary/eol）                           |
| `Ctrl+j`         | 將檔案編碼轉為 UTF-8，行尾改成 UNIX                                           |
| `Ctrl+t`         | `retab`：把檔內 Tab 轉空白                                               |
| `Ctrl+l`         | 換行顯示 wrap ↔ nowrap                                                |
| `Ctrl+f`         | full/simple 佈局切換（number/cindent/nowrap ↔ nonumber/nocindent/wrap） |
| `<Space>ff`      | fzf 開檔（`:Files`）                                                  |
| `<Space>fg`      | fzf 全文搜尋（`:Rg`）                                                   |
| `<Space>cr`      | 彩虹括號＋縮排欄 ON/OFF（安全函式版）                                            |
| `<Space><Space>` | 清除搜尋高亮（`:nohlsearch`）                                             |
| `<Space>rn`      | 相對行號 ON/OFF                                                       |
| `<Space>cs`      | 拼字檢查 ON/OFF                                                       |

---

# 1) 游標移動 & 捲動

| 指令                     | 功能                                     |
| ---------------------- | -------------------------------------- |
| `h j k l`              | 左下上右                                   |
| `w / e / b / ge`       | 單字前進 / 到字尾 / 後退 / 到前一字尾（`W/E/B` 以空白為界） |
| `0 ^ $ g_`             | 行首 / 首非空白 / 行尾 / 行尾最後非空白               |
| `gg / G / {N}G / :{N}` | 檔頭 / 檔尾 / 第 N 行                        |
| `H / M / L`            | 視窗上/中/下 的那一行                           |
| `Ctrl+u / Ctrl+d`      | 向上/下半頁；`Ctrl+b / Ctrl+f` 整頁            |
| `zz / zt / zb`         | 當前行置中 / 置頂 / 置底                        |

---

# 2) 視窗/分頁/緩衝區

| 指令                          | 功能                          |
| --------------------------- | --------------------------- |
| `:vsplit` / `:split`        | 垂直 / 水平分割                   |
| `Ctrl+w h/j/k/l`            | 視窗間移動（或用你綁的 `Ctrl+h/j/k/l`） |
| `Ctrl+w w`                  | 循環切換窗格                      |
| `Ctrl+w =`                  | 等寬等高                        |
| `:ls`                       | 列出 buffers                  |
| `:bnext` / `:bprev` / `:b#` | 下個 / 上個 / 切回上一個 buffer      |
| `:b {編號/前綴}`                | 跳到指定 buffer                 |
| `:tabnew` / `gt` / `gT`     | 新分頁 / 下一分頁 / 上一分頁           |

---

# 3) 搜尋 & 取代

| 指令                      | 功能                                                 |
| ----------------------- | -------------------------------------------------- |
| `/pattern` / `?pattern` | 向下 / 向上搜尋；`n`/`N` 巡覽                               |
| `* / #`                 | 以游標下的字向下/上搜尋                                       |
| `:%s/old/new/gc`        | 全檔替換（`c` 每次確認）                                     |
| `:'<,'>s/x/y/g`         | 僅替換視覺選取範圍                                          |
| `\v` / `\< \>`          | very magic（少打反斜線）/ 單字邊界                            |
| 範例                      | `:%s/\<oldName\>/newName/gc`（只改整個字，不誤傷 `oldNameX`） |

**跨檔批次：**

* 針對 **arglist**（你指定的一組檔）：
  `:argdo %s/\<old\>/new/gc | update`
* 針對 **quickfix**（先用 `:vimgrep` 或 fzf→Ctrl-q 匯入）：
  `:cfdo %s/\<old\>/new/gc | update`

---

# 4) 編輯操作（operator + motion / 文字物件）

| 指令                          | 功能                                           |
| --------------------------- | -------------------------------------------- |
| `d{動作}` / `c{動作}` / `y{動作}` | 刪 / 改 / 複製 指定範圍                              |
| 例                           | `dw`、`c$`、`y3j`                              |
| 文字物件                        | `iw/aw`（字）、`i(`/`a(`（括號內/含括號）、`i"`/`a"`（引號）等 |
| 例                           | `ciw` 改字、`da"` 刪含外層雙引號、`ci(` 改括號內文           |
| `.`                         | 重播上一步可重放的編輯動作（搭配外掛 `vim-repeat` 更強）          |

---

# 5) 複製貼上 & 寄存器

| 指令             | 功能                                                  |
| -------------- | --------------------------------------------------- |
| `p / P`        | 游標後 / 前貼上                                           |
| `"ayy` / `"ap` | 指定寄存器 `a` 複製/貼上                                     |
| `"+y / "+p`    | 系統剪貼簿（你的 vimrc 有 `clipboard=unnamedplus`，可直接 `y/p`） |
| `"_d`          | 丟進黑洞，不汙染預設寄存器                                       |

---

# 6) 標記與跳轉

| 指令                | 功能             |
| ----------------- | -------------- |
| `m{a}`            | 在當前位置設本檔標記 `a` |
| `` `{a}` / `'{a}` | 精確跳到標記 / 行首跳   |
| `''`              | 回到上一次跳轉前的位置    |

---

# 7) 巨集（批次重複）

| 指令            | 功能                 |
| ------------- | ------------------ |
| `q{r}`…`q`    | 錄到登錄 `{r}`（如 `qa`） |
| `@{r}` / `@@` | 執行該巨集 / 重播上次巨集     |

---

# 8) 折疊/對齊/格式化

| 指令             | 功能                                           |
| -------------- | -------------------------------------------- |
| `zc / zo / za` | 收合 / 展開 / 切換折疊                               |
| `gq` / `gw`    | 依 `textwidth/formatoptions` 重排段落（`gw` 不移動游標） |

---

# 9) 你的外掛（已在 vimrc）

**註解** `vim-commentary`

* `gcc` 單行，`gc` 視覺選取，`gc{motion}` 範圍註解

**成對符號** `vim-surround`

* `ysiw)` 以 `()` 包字，`cs"'` 把 `"` 換 `'`，`ds"` 刪外層 `"`

**重播外掛動作** `vim-repeat`

* 做完一次外掛動作後按 `.` 可重播

**彩虹 & 縮排欄** `rainbow` / `indentLine`

* `<Space>cr` 一鍵開關（我做成安全函式）

**同字高亮** `vim-illuminate`

* 游標下的單字在全檔同步高亮

**複製高亮** `vim-highlightedyank`

* `y` 後閃一下，確認已複製

**色碼直顯** `Colorizer`

* #RRGGBB / rgba() 直接顯色

**CSV 彩色欄位** `rainbow_csv`

* 開 CSV/TSV 會自動上色

**快搜** `fzf` / `fzf.vim`

* `<Space>ff`→`:Files` 開檔
* `<Space>fg`→`:Rg` 全文搜尋（要有 ripgrep）
* 在 fzf 視窗 **Tab 多選** → **Ctrl-q** 匯入 quickfix → `:cfdo ...` 批次處理

---

# 10) 多檔案實戰範例

**同時處理三檔：**

```vim
:args a.c b.c c.h     " 指定三個檔
:vsplit a.c | split b.c | vsplit c.h   " 三窗格併排
" 在三檔間切：:bn / :bp / :b# 或 fzf :Files
```

**把函式名 `do_work` 改成 `run_task`（僅三檔）：**

```vim
:argdo %s/\<do_work\>/run_task/gc | update
```

**先找出所有出現再批次改（更安全）：**

```vim
:vimgrep /\<do_work\>/gj **/*.{c,h,cpp}
:copen
:cfdo %s/\<do_work\>/run_task/gc | update
```

---

# 11) 實用一行招

* 用游標下的字當搜尋目標替換：
  `:%s/\<<C-r><C-w>\>/new/gc`
* 清除搜尋高亮：
  `<Space><Space>` 或 `:nohlsearch`
* 所有視窗等寬高：
  `Ctrl+w =`

---

需要我把 **「專案改名」** 封成指令嗎？例如：

```vim
:ProjectRename oldName newName      " 對整個專案（以 glob/quickfix）安全執行
:QuickfixRename oldName newName     " 只對 quickfix 內的檔執行
```

我可以直接把函式與命令定義加進你的 vimrc，之後就打這兩個命令即可。
