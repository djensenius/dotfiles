return {
	"apple/pkl-neovim",
	lazy = true,
	ft = "pkl",
	config = function()
		vim.g.pkl_neovim = {
			start_command = { "pkl-lsp" },
			pkl_cli_path = vim.fn.exepath("pkl"),
		}
	end,
}
