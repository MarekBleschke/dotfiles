return {
  "folke/snacks.nvim",
  opts = {
    picker = {
      sources = {
        explorer = {
          -- Use a function to enable width persistence between toggles
          layout = function()
            return {
              preset = "sidebar",
              preview = false,
              layout = {
                -- Use saved width from previous session, or default to 50
                width = (vim.g.explorer_size or {}).width or 60,
                min_width = 40,
              },
            }
          end,
          -- Save width when explorer closes (persists within nvim session)
          on_close = function(picker)
            vim.g.explorer_size = picker.layout.root:size()
          end,
        },
      },
    },
  },
}
