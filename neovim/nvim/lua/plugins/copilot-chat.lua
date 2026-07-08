return {
  "CopilotC-Nvim/CopilotChat.nvim",
  keys = {
    {
      "<leader>ac",
      function()
        return require("CopilotChat").toggle()
      end,
      desc = "Toggle (CopilotChat)",
      mode = { "n", "x" },
    },
    {
      "<leader>aa",
      false,
    },
  },
}
