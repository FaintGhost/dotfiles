return {
  -- 1. 语法高亮 (让代码变漂亮)
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = { "lua", "vim", "bash", "python", "javascript", "typescript" }, -- 自动安装常用语言
        highlight = { enable = true },
      })
    end,
  },

  -- 2. 模糊搜索 (找文件神器)
  {
    'nvim-telescope/telescope.nvim', tag = '0.1.8',
    dependencies = { 'nvim-lua/plenary.nvim' },
    keys = {
      { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "查找文件" },
      { "<leader>fg", "<cmd>Telescope live_grep<cr>", desc = "全局搜索文字" },
    }
  },

  -- 3. 文件树
  {
    "nvim-tree/nvim-tree.lua",
    config = function()
      require("nvim-tree").setup()
    end,
    keys = {
      { "<leader>e", "<cmd>NvimTreeToggle<cr>", desc = "开关文件树" },
    }
  },

  -- 4. 自动补全括号
  {
    "windwp/nvim-autocomplete", -- 或者 "windwp/nvim-ts-autotag"
    config = function() require("nvim-autopairs").setup {} end
  }
}