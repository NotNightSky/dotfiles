-- custom colorscheme: haimiya
-- light theme built from the house palette (hyprland / quickshell / wofi /
-- snappy-switcher) with the Nord hues from the kitty terminal
--   :colorscheme haimiya        light
--   :colorscheme haimiya-dark   dark
--   :Haimiya [light|dark]       switch between them
return {
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "haimiya-dark",
    },
  },
  {
    "LazyVim/LazyVim",
    init = function()
      vim.api.nvim_create_user_command("Haimiya", function(cmd)
        local variant = cmd.args
        if variant ~= "light" and variant ~= "dark" then
          variant = require("haimiya").current() == "dark" and "light" or "dark"
        end
        require("haimiya").load({ variant = variant })
        vim.notify("haimiya: " .. variant, vim.log.levels.INFO, { title = "colorscheme" })
      end, {
        desc = "Switch the haimiya colorscheme (light|dark)",
        nargs = "?",
        complete = function()
          return { "light", "dark" }
        end,
      })
    end,
    keys = {
      { "<leader>cs", "<cmd>Haimiya<cr>", desc = "Toggle haimiya colorscheme (light/dark)" },
    },
  },
}
