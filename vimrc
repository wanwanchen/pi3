"################### Magic vimrc (no mouse toggle, safe mappings) ###################
" ctrl+b Switch to text/binary
" ctrl+j To utf-8 file
" ctrl+t Convert tab to spaces
" ctrl+l Toggle line breaking
" ctrl+f Switch to full/simple  (won't touch mouse)
" <Space>ff :Files, <Space>fg :Rg
" <Space>cr Toggle Rainbow+IndentLine (safe function), <Space><Space> clear hlsearch
" <Space>rn Toggle relativenumber, <Space>cs Toggle spell (en)

"=============================================================
" 基本
set nocompatible
syntax enable

set number
set relativenumber
set noruler
set ignorecase
set smartcase
set incsearch
set cindent
set expandtab
set tabstop=4
" set noexpandtab          " 若要用硬 Tab 再打開這行
set softtabstop=4
set shiftwidth=4
set smarttab
set confirm
set backspace=indent,eol,start
set history=500
set showcmd
set showmode
set nowrap
set autowrite
set mouse=a               " 固定啟用；不再提供任何切換

"=============================================================
" 顏色（保留你的原始風格）
set t_Co=256
colo torte
set cursorline
set cursorcolumn
set hlsearch
hi CursorLine   cterm=none ctermbg=DarkMagenta ctermfg=White
hi CursorColumn cterm=none ctermbg=DarkMagenta ctermfg=White
hi Search       cterm=reverse ctermbg=none ctermfg=none

"=============================================================
" 狀態列（保留）
set laststatus=2
set statusline=%#filepath#[%{expand('%:p')}]%#filetype#[%{strlen(&fenc)?&fenc:&enc},\ %{&ff},\ %{strlen(&filetype)?&filetype:'plain'}]%#filesize#%{FileSize()}%{IsBinary()}%=%#position#%c,%l/%L\ [%3p%%]
hi filepath cterm=none ctermbg=238 ctermfg=40
hi filetype cterm=none ctermbg=238 ctermfg=45
hi filesize cterm=none ctermbg=238 ctermfg=225
hi position cterm=none ctermbg=238 ctermfg=228

function IsBinary()
    if (&binary == 0)
        return ""
    else
        return "[Binary]"
    endif
endfunction

function FileSize()
    let bytes = getfsize(expand("%:p"))
    if bytes <= 0
        return "[Empty]"
    endif
    if bytes < 1024
        return "[" . bytes . "B]"
    elseif bytes < 1048576
        return "[" . (bytes / 1024) . "KB]"
    else
        return "[" . (bytes / 1048576) . "MB]"
    endif
endfunction

"=============================================================
" 編碼偵測
if has("multi_byte")
    set fileencodings=utf-8,utf-16,big5,gb2312,gbk,gb18030,euc-jp,euc-kr,latin1
else
    echoerr "If +multi_byte is not included, you should compile Vim with big features."
endif

"=============================================================
" 你的 Ctrl 系列快捷鍵（保留）
" Toggle text/binary
map  <C-b> :call SwitchTextBinaryMode()<CR>
map! <C-b> <Esc>:call SwitchTextBinaryMode()<CR>
function SwitchTextBinaryMode()
    if (&binary == 0)
        set binary | set noeol
        echo "Switch to binary mode."
    else
        set nobinary | set eol
        echo "Switch to text mode."
    endif
endfunction

" To utf-8 file
map  <C-j> :call ToUTF8()<CR>
map! <C-j> <Esc>:call ToUTF8()<CR>
function ToUTF8()
    if (&fileencoding == "utf-8")
        echo "It is already UTF-8."
    else
        let &fileencoding="utf-8"
        echo "Convert to UTF-8."
    endif
    let &ff="unix"
endfunction

" Convert tab to spaces
map  <C-t> :call TabToSpaces()<CR>
map! <C-t> <Esc>:call TabToSpaces()<CR>
function TabToSpaces()
    retab
    echo "Convert tab to spaces."
endfunction

" Toggle line breaking
map  <C-l> :call SwitchLineBreakingMode()<CR>
map! <C-l> <Esc>:call SwitchLineBreakingMode()<CR>
function SwitchLineBreakingMode()
    if (&wrap == 0)
        set wrap | echo "Switch to line breaking mode."
    else
        set nowrap | echo "Switch to one line mode."
    endif
endfunction

" Switch to full/simple —— 不動 mouse
map  <C-f> :call SwitchFullSimpleMode()<CR>
map! <C-f> <Esc>:call SwitchFullSimpleMode()<CR>
function SwitchFullSimpleMode()
    if (&number == 1 && &cindent == 1 && &wrap == 0)
        " 簡潔模式
        set nonumber
        set nocindent
        set wrap
        echo "Switch to simple mode.(nonumber, nocindent, wrap)"
    else
        " 完整模式
        set number
        set cindent
        set nowrap
        echo "Switch to full mode.(number, cindent, nowrap)"
    endif
endfunction

"=============================================================
" 外掛（不改你的配色，只加功能）
" 先安裝 plug.vim 後，進 Vim 執行 :PlugInstall
call plug#begin('~/.vim/plugged')
  " 編輯效率
  Plug 'tpope/vim-surround'        " cs / ds / ysiw)
  Plug 'tpope/vim-commentary'      " gcc / gc{motion}
  Plug 'tpope/vim-repeat'          " 讓 . 能重播外掛動作

  " 視覺可讀性
  Plug 'luochen1990/rainbow'       " 彩虹括號
  Plug 'Yggdroot/indentLine'       " 縮排欄
  Plug 'RRethy/vim-illuminate'     " 游標下相同單字高亮
  Plug 'machakann/vim-highlightedyank' " yank 閃爍回饋
  Plug 'chrisbra/Colorizer'        " #RRGGBB/rgba() 色碼直顯
  Plug 'mechatroner/rainbow_csv'   " CSV/TSV 欄位跳色

  " 快速檔案/全文搜尋
  Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
  Plug 'junegunn/fzf.vim'
call plug#end()

" 外掛細部（安全寫法，避免啟動順序造成錯誤）
let g:rainbow_active = 1
let g:indentLine_char = '│'
let g:Illuminate_delay = 120
let g:highlightedyank_highlight_duration = 180

" Colorizer 自動啟用
autocmd BufRead,BufNewFile * silent! ColorHighlight

" CSV/TSV 啟用 rainbow_csv（拆成兩行避免 | 在貼上時被斷行）
autocmd FileType csv,tsv RainbowDelim
autocmd FileType csv,tsv RainbowDelim!

"=============================================================
" Leader 快捷與安全版彩虹切換
let mapleader="\<Space>"
nnoremap <leader><space> :nohlsearch<CR>
nnoremap <leader>ff :Files<CR>
nnoremap <leader>fg :Rg<Space>
nnoremap <leader>rn :set invrelativenumber<CR>
nnoremap <leader>cs :set invspell<CR>

" —— 用函式避免你之前遇到的 E492（單行映射在貼上時被換行）——
function! s:ToggleRainbow() abort
  " 確認外掛命令存在（第一次裝好外掛前不報錯）
  let has_rainbow = exists(':RainbowToggleOn')
  let has_indent  = exists(':IndentLinesEnable')

  if has_rainbow && has_indent
    if get(g:, 'rainbow_active', 0)
      let g:rainbow_active = 0
      silent! RainbowToggleOff
      silent! IndentLinesDisable
      echo 'Rainbow OFF'
    else
      let g:rainbow_active = 1
      silent! RainbowToggleOn
      silent! IndentLinesEnable
      echo 'Rainbow ON'
    endif
  else
    echo 'Rainbow/IndentLine not installed yet (:PlugInstall)'
  endif
endfunction
nnoremap <leader>cr :call <SID>ToggleRainbow()<CR>

