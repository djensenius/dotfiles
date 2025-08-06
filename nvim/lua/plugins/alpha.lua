return {
	"goolord/alpha-nvim",
	event = "VimEnter",
	config = function()
		local opts = { noremap = true, silent = true }
		vim.keymap.set("n", "<leader>aA", ":Alpha<CR>", opts)
		local dashboard = require("alpha.themes.dashboard")
		local logo = [[
    (q\_/p)
.-.  |. .|                            (\
   \ =\,/=                           (\_\_^__o
    )/ _ \                 ___        `-'/ `_/
   (/\):(/\               '`--\________/   |
    \_   _/          '        /            |
    `""^""`      `    .  ' `-`/.----------'\^-'
    ]]

		local status_ok, alpha = pcall(require, "alpha")
		if not status_ok then
			return
		end

		dashboard.section.header.val = vim.split(logo, "\n")
		dashboard.section.buttons.val = {
			dashboard.button("f", " " .. " Find file", ":lua require('fzf-lua').frecency({ cwd_only = true }) <CR>"),
			dashboard.button("r", " " .. " Recent files", ":lua  require('fzf-lua').frecency() <CR>"),
			dashboard.button("R", " " .. " Restore session", ":so Session.vim<CR>"),
			dashboard.button("g", " " .. " Find text", ":lua require('fzf-lua').live_grep() <CR>"),
			dashboard.button("G", " " .. " Git Status", ":lua require('fzf-lua').git_status() <CR>"),
			dashboard.button("t", " " .. " Open file tree", ":Neotree<CR>"),
			dashboard.button("l", "󰒲 " .. " Lazy", ":Lazy<CR>"),
			dashboard.button(
				"d",
				" " .. " Git Graph",
				":lua require('gitgraph').draw({}, { all = true, max_count = 5000 })<CR>"
			),
			dashboard.button("q", " " .. " Quit", ":qa<CR>"),
		}
		dashboard.section.buttons.opts.spacing = 0
		local f = io.popen("/bin/hostname")
		if f == nil then
			return
		end
		local hostname = f:read("*a") or ""
		f:close()
		hostname = string.gsub(hostname, "\n$", "")
		hostname = string.gsub(hostname, ".lan$", "")

		local v = vim.version()
		local version = " v" .. v.major .. "." .. v.minor .. "." .. v.patch
		local machine = "󰌢  " .. vim.fn.expand("$USER") .. "@" .. hostname

		vim.api.nvim_create_autocmd("User", {
			pattern = "LazyVimStarted",
			callback = function()
				local stats = require("lazy").stats()
				local ms = (math.floor(stats.startuptime * 100 + 0.5) / 100)
				dashboard.section.footer.val = {
					"",
					version,
					"",
					machine,
					"",
					"⚡ Neovim loaded " .. stats.count .. " plugins in " .. ms .. "ms",
				}
				pcall(vim.cmd.AlphaRedraw)
			end,
		})

		dashboard.section.footer.val = {}

		dashboard.section.footer.opts.hl = "Type"
		dashboard.section.header.opts.hl = "Include"
		dashboard.section.buttons.opts.hl = "Keyword"

		dashboard.opts.opts.noautocmd = true
		alpha.setup(dashboard.opts)

		dashboard.section.header.opts.hl = "AlphaHeader"
		dashboard.opts.layout[1].val = 6
		return dashboard
	end,
}
