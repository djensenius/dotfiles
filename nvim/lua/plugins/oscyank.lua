return {
	"ojroques/vim-oscyank",
	init = function()
		---@diagnostic disable-next-line: inject-field
		vim.g.oscyank_trim = 0
	end,
	config = function()
		-- Single autocmd with a combined callback function
		vim.api.nvim_create_autocmd("TextYankPost", {
			callback = function()
				-- Handle both default and '+' register cases in a single function
				if vim.v.event.operator ~= "y" then
					return
				end

				local register = vim.v.event.regname
				if register == "" or register == "+" then
					vim.cmd(string.format("OSCYankRegister %s", register == "" and '"' or "+"))
				end
			end,
		})
	end,
}
