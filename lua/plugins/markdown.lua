return {
  "brianhuster/live-preview.nvim",
  cmd = "LivePreview",
  keys = {
    { "<leader>mp", "<cmd>LivePreview start<CR>", desc = "MD プレビュー" },
  },
  config = function()
    require("livepreview.config").set({ dynamic_root = true })
  end,
}
