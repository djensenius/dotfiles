return {
	"oribarilan/lensline.nvim",
	branch = "release/2.x",
	event = "LspAttach",
	config = function()
		require("lensline").setup({
			-- Profile definitions, first is default
			limits = {
				exclude_gitignored = false,
			},
			profiles = {
				{
					name = "basic",
					providers = {
						{ name = "usages", enabled = true, include = { "refs", "defs", "impls" }, breakdown = true },
						{ name = "diagnostics", enabled = true, min_level = "HINT" },
						{ name = "complexity", enabled = true },
						{ name = "last_author", enabled = true },
					},
					style = { render = "all", placement = "inline" },
				},
				{
					name = "informative",
					providers = {
						{ name = "usages", enabled = true, include = { "refs", "defs", "impls" }, breakdown = true },
						{ name = "diagnostics", enabled = true, min_level = "HINT" },
						{ name = "complexity", enabled = true },
						{ name = "last_author", enabled = true },
					},
					style = { render = "all", placement = "above" },
				},
			},
		})
	end,
}
