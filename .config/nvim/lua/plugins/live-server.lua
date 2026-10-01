return {
  {
    "selimacerbas/live-server.nvim",
    -- Lazy load the plugin so it doesn't slow down startup;
    -- it will automatically load when you call any of these keymaps.
    keys = {
      { "<leader>ls", "<cmd>LiveServerStart<cr>", desc = "Start Live Server" },
      { "<leader>lx", "<cmd>LiveServerStop<cr>", desc = "Stop Live Server" },
      { "<leader>lt", "<cmd>LiveServerToggle<cr>", desc = "Toggle Live Server" },
    },
    opts = {}, -- This runs require("live-server").setup({}) automatically
  },
}
