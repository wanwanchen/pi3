-----------------------------------------------------------
-- 基本設定
-----------------------------------------------------------
vim.g.mapleader = " "

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.termguicolors = true
vim.opt.mouse = "a"
vim.o.showtabline = 2

-- 每個視窗上方顯示該視窗的檔名
vim.o.winbar = "%=%m %f"

-- Normal mode：按 <Leader>x 就等於輸入 :xa
-- 功能：全部存檔 + 關掉所有視窗 + 退出 Neovim
vim.keymap.set("n", "<leader>x", ":xa<CR>", {
  noremap = true,
  silent = true,
  desc = "Save all files and exit Neovim",
})

--（可選）Normal mode：按 <Leader>q 強制關掉所有，不存檔
vim.keymap.set("n", "<leader>q", ":qa!<CR>", {
  noremap = true,
  silent = true,
  desc = "Quit all without saving",
})


-----------------------------------------------------------
-- <leader>*：在 Git root 全專案搜尋游標單字（fzf + rg）
-- - 固定字串搜尋（不當 regex）
-- - 以 git root 當搜尋根目錄
-- - 沒找到也不會噴 command failed（|| true）
-----------------------------------------------------------
vim.keymap.set("n", "<leader>*", function()
  local word = vim.fn.expand("<cword>")
  if word == "" then return end

  -- 找 git root（找不到就用目前 cwd）
  local git_dir = vim.fs.find(".git", { upward = true })[1]
  local root = git_dir and vim.fs.dirname(git_dir) or vim.fn.getcwd()

  -- rg 指令：注意最後的 || true
  local cmd =
    "rg --column --line-number --no-heading --color=always --smart-case --fixed-strings "
    .. vim.fn.shellescape(word)
    .. " . || true"

  -- fzf 的 options：把 dir 指到 root，讓 rg 在那個目錄跑
  local opts = vim.fn["fzf#vim#with_preview"]()
  opts.dir = root

  vim.fn["fzf#vim#grep"](cmd, 1, opts, 0)
end, { noremap = true, silent = true, desc = "Rg word under cursor (git root)" })




-- 用寄存器 0 的內容取代目前這個 word
-- 用法：
--   1. 在來源字上按 yiw
--   2. 移到目標字，按 <leader>r  （預設 <leader> 是 \ ，所以就是 \r）
--   3. 下一個目標字直接按 . 重複
vim.keymap.set("n", "<leader>r", 'ciw<C-r>0<Esc>', { noremap = true, silent = true })

-- 用 <leader>gg 開啟 LazyGit
vim.keymap.set("n", "<leader>gg", ":LazyGit<CR>", {
  noremap = true,
  silent = true,
  desc = "Open LazyGit",
})
local ok, wk = pcall(require, "which-key")
if ok then
  wk.register({
    g = {
      name = "Git",
      g = "Open LazyGit",
    },
    j = {
      name = "JSON",
      j = "Check & format JSON",
    },
    x = {
      name = "XML",
      x = "Check & format XML",
    },

  }, { prefix = "<leader>" })
end

-----------------------------------------------------------
-- lazy.nvim 外掛管理器 bootstrapping
-----------------------------------------------------------
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-----------------------------------------------------------
-- lazy.nvim 設定要安裝的外掛
-----------------------------------------------------------
require("lazy").setup({
  -- LSP 預設 server config（提供各語言的預設設定）
  { "neovim/nvim-lspconfig" },

  -- Treesitter：語法高亮 + LSP hover 用的 markdown parser
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
  },

  -- icon（給 nvim-tree / bufferline 用）
  { "nvim-tree/nvim-web-devicons" },

  -- VS Code 風格主題
  {
    "Mofiqul/vscode.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      vim.o.background = "dark"  -- VS Code 深色風格
      local vscode = require("vscode")
      vscode.setup({
        -- 這邊可以調整你喜歡的細節
        style = "dark",          -- "dark", "light"
        transparent = false,     -- 是否透明背景
        italic_comments = true,  -- 註解斜體，挺有 VS Code 味道
        disable_nvimtree_bg = true, -- 讓 nvim-tree 背景跟編輯區一致
      })
      vscode.load()
    end,
  },
  -- fzf 核心
  {
    "junegunn/fzf",
    build = "./install --bin",
  },

  -- fzf.vim：:Files / :Rg / :Buffers ...
  {
    "junegunn/fzf.vim",
    dependencies = { "junegunn/fzf" },
    event = "VimEnter",
    config = function()
      local opts = { noremap = true, silent = true }
      vim.keymap.set("n", "<leader>ff", ":Files<CR>", opts)    -- 尋找檔案
      vim.keymap.set("n", "<leader>fg", ":Rg<CR>", opts)       -- 全專案關鍵字搜
      vim.keymap.set("n", "<leader>fb", ":Buffers<CR>", opts)  -- 切換 buffer
      vim.keymap.set("n", "<leader>fh", ":Helptags<CR>", opts) -- 搜尋 help
    end,
  },

{
  "nvim-tree/nvim-tree.lua",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  config = function()
    require("nvim-tree").setup({
      view = {
        side = "left",   -- 目錄樹在左邊
        width = 30,
      },
      actions = {
        open_file = {
          quit_on_open = false,  -- 開檔案時不要把樹關掉
        },
      },
      git = { enable = true },
      filters = { dotfiles = false },
    })

    local opts = { noremap = true, silent = true }
    -- 切換檔案總管
    vim.keymap.set("n", "<leader>e", ":NvimTreeToggle<CR>", opts)

    -- 啟動 Neovim 時自動打開檔案總管
    vim.api.nvim_create_autocmd("VimEnter", {
      callback = function()
        require("nvim-tree.api").tree.open()
      end,
    })
  end,
},
 {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {},
 },
  -- ⭐ LazyGit 插件
  {
    "kdheepak/lazygit.nvim",
    cmd = "LazyGit",
    dependencies = { "nvim-lua/plenary.nvim" },
  },
    -- 縮排垂直線（像 VS Code 的 indent guides）
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    opts = {
      indent = {
        char = "│",   -- 垂直線樣式，可以改成 "┆" "┊" 等
        tab_char = "│",
      },
      scope = {
        enabled = true,  -- 高亮目前縮排層級
      },
    },
  },
  -- 縮排垂直線（像 VS Code 的 indent guides）
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    opts = {
      indent = {
        char = "│",
        tab_char = "│",
      },
      scope = {
        enabled = true,
      },
    },
  },

  -- 自動補全（像 VS Code 的提示選單）
{
  "hrsh7th/nvim-cmp",
  event = "InsertEnter",
  dependencies = {
    "hrsh7th/cmp-nvim-lsp",
    "hrsh7th/cmp-buffer",
    "hrsh7th/cmp-path",
    "hrsh7th/cmp-cmdline",
    "L3MON4D3/LuaSnip",
    "saadparwaiz1/cmp_luasnip",
    "rafamadriz/friendly-snippets",
  },
  config = function()
    local cmp = require("cmp")
    local luasnip = require("luasnip")
    require("luasnip.loaders.from_vscode").lazy_load()

    cmp.setup({
      snippet = {
        expand = function(args)
          luasnip.lsp_expand(args.body)
        end,
      },
      mapping = cmp.mapping.preset.insert({
        ["<C-Space>"] = cmp.mapping.complete(),        -- 手動叫出提示
        ["<CR>"] = cmp.mapping.confirm({ select = true }), -- Enter 確認
        ["<Tab>"] = cmp.mapping(function(fallback)     -- Tab 選下一個
          if cmp.visible() then
            cmp.select_next_item()
          elseif luasnip.expand_or_jumpable() then
            luasnip.expand_or_jump()
          else
            fallback()
          end
        end, { "i", "s" }),
        ["<S-Tab>"] = cmp.mapping(function(fallback)   -- Shift-Tab 選上一個
          if cmp.visible() then
            cmp.select_prev_item()
          elseif luasnip.jumpable(-1) then
            luasnip.jump(-1)
          else
            fallback()
          end
        end, { "i", "s" }),
      }),
      sources = cmp.config.sources({
        { name = "nvim_lsp" }, -- LSP 補全（變數/函數/型別）
        { name = "luasnip" },  -- snippet
        { name = "path" },     -- 路徑補全
        { name = "buffer" },   -- 目前檔案文字補全
      }),
      window = {
        completion = cmp.config.window.bordered(),
        documentation = cmp.config.window.bordered(),
      },
      experimental = { ghost_text = true }, -- 會出現淡淡的預測字（很像 VS Code）
    })

    -- cmdline 補全（可選，但很好用）
    cmp.setup.cmdline(":", {
      mapping = cmp.mapping.preset.cmdline(),
      sources = cmp.config.sources({ { name = "path" } }, { { name = "cmdline" } }),
    })
  end,
},

  -- 上方 tab 樣式的 buffer 列：bufferline
  {
    "akinsho/bufferline.nvim",
    version = "*",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("bufferline").setup({
        options = {
          mode = "buffers",
          diagnostics = "nvim_lsp",
          show_buffer_close_icons = false,
          show_close_icon = false,
          separator_style = "slant",
          always_show_bufferline = true,
          -- ⭐ 檔案「有修改未存」時顯示的圖示
          modified_icon = "●",   -- 也可以改成 "" 或你喜歡的符號
        },
      })

      vim.opt.termguicolors = true

      local opts = { noremap = true, silent = true }
      -- 用 Tab / Shift-Tab 在檔案之間切換
      vim.keymap.set("n", "<Tab>", "<Cmd>BufferLineCycleNext<CR>", opts)
      vim.keymap.set("n", "<S-Tab>", "<Cmd>BufferLineCyclePrev<CR>", opts)

      -- 也可以用 <leader>1..9 直接跳到第 N 個 buffer
      for i = 1, 9 do
        vim.keymap.set("n", "<leader>" .. i, "<Cmd>BufferLineGoToBuffer " .. i .. "<CR>", opts)
      end
    end,
  },
})

-----------------------------------------------------------
-- Treesitter 設定
-----------------------------------------------------------
local ok_ts, ts_configs = pcall(require, "nvim-treesitter.configs")
if ok_ts then
  ts_configs.setup({
    ensure_installed = {
      "c",
      "cpp",
      "python",
      "lua",
      "vim",
      "vimdoc",
      "markdown",
      "markdown_inline",
      "json",
      "jsonc",
      "xml",
    },
    highlight = {
      enable = true,
    },
  })
end

-----------------------------------------------------------
-- LSP 設定（使用 Neovim 0.11+ 新 API）
-----------------------------------------------------------

-- 1. 全部 LSP 共用的預設設定
vim.lsp.config("*", {
  capabilities = vim.lsp.protocol.make_client_capabilities(),
})

-- 2. pyright：指定你系統上的 pyright-langserver 路徑
vim.lsp.config("pyright", {
  cmd = { "/usr/local/bin/pyright-langserver", "--stdio" },
})

-- 3. clangd：用預設即可；要改再另外寫 vim.lsp.config("clangd", {...})
-- vim.lsp.config("clangd", {
--   cmd = { "clangd" },
-- })

-- 4. 有 LSP attach 時，綁定常用快捷鍵（gr/K 等都在這裡）
local lsp_group = vim.api.nvim_create_augroup("UserLspKeymaps", {})

vim.api.nvim_create_autocmd("LspAttach", {
  group = lsp_group,
  callback = function(ev)
    local bufnr = ev.buf
    local opts = { buffer = bufnr, noremap = true, silent = true }
    local map = function(mode, lhs, rhs)
      vim.keymap.set(mode, lhs, rhs, opts)
    end

    -- 常用 LSP 快捷鍵
    map("n", "K", vim.lsp.buf.hover)                  -- 顯示說明
    map("n", "gd", vim.lsp.buf.definition)            -- 跳到定義
    map("n", "gD", vim.lsp.buf.declaration)           -- 跳到宣告
    map("n", "gr", vim.lsp.buf.references)            -- 找所有參考
    map("n", "<leader>rn", vim.lsp.buf.rename)        -- 重新命名
    map("n", "<leader>ca", vim.lsp.buf.code_action)   -- code action
    map("n", "<leader>f", function()                  -- 格式化
      vim.lsp.buf.format({ async = true })
    end)
  end,
})

-- 5. 啟用要用的 LSP（名字跟 nvim-lspconfig server 名稱一樣）
vim.lsp.enable({
  "pyright",  -- Python
  "clangd",   -- C / C++
})

-----------------------------------------------------------
-- Neovim 啟動提示一下設定有載入
-----------------------------------------------------------
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    vim.notify("init.lua (LSP + Treesitter + fzf + nvim-tree + bufferline) 已載入")
  end,
})


-----------------------------------------------------------
-- JSON 檢查 + 格式化（用 jq）
-----------------------------------------------------------
local function format_and_check_json()
  -- 讀取整個 buffer 內容
  local buf = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local content = table.concat(lines, "\n")

  -- 用 jq 檢查＋格式化
  local output = vim.fn.systemlist("jq .", content)
  local status = vim.v.shell_error

  if status ~= 0 then
    -- jq 回傳錯誤，顯示錯誤訊息（不改你的檔案）
    vim.notify("JSON 格式錯誤:\n" .. table.concat(output, "\n"),
      vim.log.levels.ERROR)
  else
    -- 成功就把排版好的結果寫回 buffer
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, output)
    vim.notify("JSON OK，已格式化", vim.log.levels.INFO)
  end
end

vim.api.nvim_create_user_command("JsonCheck", format_and_check_json, {})

-- 快捷鍵：<leader>jj 檢查＋格式化 JSON
vim.keymap.set("n", "<leader>jj", format_and_check_json, {
  noremap = true,
  silent = true,
  desc = "Check & format JSON with jq",
})


-----------------------------------------------------------
-- XML 檢查 + 格式化（用 xmllint）
-----------------------------------------------------------
local function format_and_check_xml()
  local buf = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local content = table.concat(lines, "\n")

  -- 用 xmllint 做格式檢查＋排版
  local output = vim.fn.systemlist("xmllint --format -", content)
  local status = vim.v.shell_error

  if status ~= 0 then
    vim.notify("XML 格式錯誤:\n" .. table.concat(output, "\n"),
      vim.log.levels.ERROR)
  else
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, output)
    vim.notify("XML OK，已格式化", vim.log.levels.INFO)
  end
end

vim.api.nvim_create_user_command("XmlCheck", format_and_check_xml, {})

-- 快捷鍵：<leader>xx 檢查＋格式化 XML
vim.keymap.set("n", "<leader>xx", format_and_check_xml, {
  noremap = true,
  silent = true,
  desc = "Check & format XML with xmllint",
})

