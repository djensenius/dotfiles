-- Seamless <C-h/j/k/l> movement between editor splits and the surrounding
-- multiplexer.
--
-- vim-tmux-navigator still handles tmux, but its own mappings are disabled in
-- favour of the vim-herdr-navigation editor module, which is a superset: it
-- targets herdr when $HERDR_PANE_ID is set, falls back to tmux when $TMUX is
-- set, and otherwise does a plain wincmd. One set of mappings, both
-- multiplexers.
--
-- The herdr side of the plugin is installed with:
--   herdr plugin install paulbkim-dev/vim-herdr-navigation
local function herdr_nav_module()
	local matches =
		vim.fn.glob(vim.fn.expand("~/.config/herdr/plugins/github/vim-herdr-navigation-*/editor/nvim.lua"), true, true)
	return matches[1]
end

return {
	"christoomey/vim-tmux-navigator",
	lazy = false,
	init = function()
		vim.g.tmux_navigator_no_mappings = 1
	end,
	config = function()
		local module = herdr_nav_module()
		if module and vim.fn.filereadable(module) == 1 then
			dofile(module)
			return
		end

		-- herdr plugin not installed: fall back to vim-tmux-navigator's own
		-- commands so tmux keeps working.
		local map = vim.keymap.set
		map("n", "<c-h>", "<cmd>TmuxNavigateLeft<cr>", { desc = "Window Left" })
		map("n", "<c-j>", "<cmd>TmuxNavigateDown<cr>", { desc = "Window Down" })
		map("n", "<c-k>", "<cmd>TmuxNavigateUp<cr>", { desc = "Window Up" })
		map("n", "<c-l>", "<cmd>TmuxNavigateRight<cr>", { desc = "Window Right" })
	end,
}
