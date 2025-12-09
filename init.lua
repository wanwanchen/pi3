--------------------------------------------------
-- 基本設定 & 編碼
--------------------------------------------------
vim.g.mapleader = " "              -- <leader> 用空白鍵
vim.o.encoding = "utf-8"
vim.o.fileencoding = "utf-8"

vim.o.number = true
vim.o.relativenumber = true
vim.o.tabstop = 4
vim.o.shiftwidth = 4
vim.o.expandtab = true
vim.o.termguicolors = true
vim.o.cursorline = true

--------------------------------------------------
-- lazy.nvim bootstrap
--------------------------------------------------
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

--------------------------------------------------
-- Plugins
--------------------------------------------------
require("lazy").setup({
  -- 狀態列 + icon
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
  },

  -- 左側檔案樹
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
  },

  -- Telescope + fzf 加速
  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      {
        "nvim-telescope/telescope-fzf-native.nvim",
        build = "make",
      },
    },
  },

  -- Treesitter：C 語法高亮 / 縮排
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
  },

  -- Git 標記
  "lewis6991/gitsigns.nvim",

  -- LSP 設定（新 API 會用到這個 plugin）
  "neovim/nvim-lspconfig",

  -- ===== 自動補齊相關 =====
  "hrsh7th/nvim-cmp",         -- 主體
  "hrsh7th/cmp-nvim-lsp",     -- 從 LSP 來的補齊來源
  "hrsh7th/cmp-buffer",       -- 從 buffer 裡面來的字
  "hrsh7th/cmp-path",         -- 路徑補齊

  "L3MON4D3/LuaSnip",         -- snippet 引擎
  "saadparwaiz1/cmp_luasnip", -- snippet 當補齊來源
  "rafamadriz/friendly-snippets", -- 常用 snippets 集合（可選）
})

--------------------------------------------------
-- Plugin 設定
--------------------------------------------------

-- lualine
require("lualine").setup()

-- gitsigns
require("gitsigns").setup()

-- nvim-tree
require("nvim-tree").setup({})
vim.keymap.set("n", "<leader>e", ":NvimTreeToggle<CR>",
  { silent = true, desc = "Toggle file tree" })

-- Treesitter
require("nvim-treesitter.configs").setup({
  ensure_installed = { "c", "cpp", "lua", "vim", "vimdoc", "query" },
  highlight = { enable = true },
  indent    = { enable = true },
})

-- Telescope + fzf-native
local telescope = require("telescope")
local builtin = require("telescope.builtin")

telescope.setup({
  defaults = {
    -- 想調整預設 UI 可以放這裡
  },
  extensions = {
    fzf = {
      fuzzy = true,
      override_generic_sorter = true,
      override_file_sorter = true,
      case_mode = "smart_case",
    },
  },
})
telescope.load_extension("fzf")

vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Find files" })
vim.keymap.set("n", "<leader>fg", builtin.live_grep,  { desc = "Live grep" })
vim.keymap.set("n", "<leader>fb", builtin.buffers,    { desc = "List buffers" })
vim.keymap.set("n", "<leader>fh", builtin.help_tags,  { desc = "Help tags" })

--------------------------------------------------
-- nvim-cmp 自動補齊設定
--------------------------------------------------
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
    ["<C-Space>"] = cmp.mapping.complete(),  -- 手動叫出補齊
    ["<CR>"] = cmp.mapping.confirm({ select = true }), -- Enter 接受建議
    ["<Tab>"] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      elseif luasnip.expand_or_jumpable() then
        luasnip.expand_or_jump()
      else
        fallback()
      end
    end, { "i", "s" }),
    ["<S-Tab>"] = cmp.mapping(function(fallback)
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
    { name = "nvim_lsp" },
    { name = "luasnip" },
  }, {
    { name = "buffer" },
    { name = "path" },
  }),
})

--------------------------------------------------
-- LSP for C/C++：使用 Neovim 0.11 的新 API
-- 不需要 require('lspconfig')，也不需要 nvim-lspconfig 外掛
--------------------------------------------------
local cmp_lsp = require("cmp_nvim_lsp")
local capabilities = cmp_lsp.default_capabilities()

-- 每個有 LSP 的 buffer 都套用的 keymap
local function on_attach(client, bufnr)
  local bufmap = function(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
  end

  bufmap("n", "K",  vim.lsp.buf.hover,          "LSP Hover")
  bufmap("n", "gd", vim.lsp.buf.definition,     "Go to definition")
  bufmap("n", "gD", vim.lsp.buf.declaration,    "Go to declaration")
  bufmap("n", "gi", vim.lsp.buf.implementation, "Go to implementation")
  bufmap("n", "gr", vim.lsp.buf.references,     "List references")

  bufmap("n", "<leader>rn", vim.lsp.buf.rename,      "Rename symbol")
  bufmap("n", "<leader>ca", vim.lsp.buf.code_action, "Code action")

  bufmap("n", "[d", vim.diagnostic.goto_prev, "Prev diagnostic")
  bufmap("n", "]d", vim.diagnostic.goto_next, "Next diagnostic")
  bufmap("n", "<leader>q", vim.diagnostic.setloclist, "Diagnostic list")

  bufmap("n", "<leader>f", function()
    vim.lsp.buf.format({ async = true })
  end, "Format buffer")
end

-- 定義 clangd 的設定（寫在 vim.lsp.config 上，而不是 lspconfig）
vim.lsp.config.clangd = {
  cmd = { "clangd" },  -- 用系統的 /usr/bin/clangd
  filetypes = { "c", "cpp", "objc", "objcpp" },
  -- 這邊 root_markers 決定專案根目錄（可依自己習慣調整）
  root_markers = { "compile_commands.json", "compile_flags.txt", ".git" },

  capabilities = capabilities,
  on_attach = on_attach,
}

-- 啟用 clangd LSP
vim.lsp.enable({ "clangd" })


vim.lsp.enable({ "clangd" })
