return {
	"ray-x/go.nvim",
	event = "VeryLazy", -- load on demand
	dependencies = { -- optional packages
		"ray-x/guihua.lua",
		"neovim/nvim-lspconfig",
		"theHamsta/nvim-dap-virtual-text",
	},
	opts = {
		-- lsp_keymaps = false,
		-- other options
		linter = "golangci-lint",
		-- textobjects are provided by nvim-treesitter-textobjects (we use
		-- arborist.nvim, not nvim-treesitter), so disable go.nvim's redundant
		-- copy to avoid a spurious "nvim-treesitter module not loaded" notice.
		textobjects = false,
	},
	config = function(_, opts)
		require("go").setup(opts)
		local format_sync_grp = vim.api.nvim_create_augroup("GoFormat", {})
		vim.api.nvim_create_autocmd("BufWritePre", {
			pattern = "*.go",
			callback = function()
				require("go.format").goimports()
			end,
			group = format_sync_grp,
		})
	end,
	ft = { "go", "gomod" },
	build = ':lua require("go.install").update_all_sync()', -- if you need to install/update all binaries
}
