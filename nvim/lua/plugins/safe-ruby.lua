return {
	name = "ruby-safe-path-bootstrap",
	dir = vim.fn.stdpath("config") .. "/lua/plugins",
	event = { "BufReadPre", "BufNewFile" },
	priority = 1000,
	config = function()
		local ORIGINAL_PATH = vim.env.PATH
		local PROJECT_BINS = {} -- set-like: project bin dirs already added
		local VENDOR_BINS = {} -- set-like: vendor ruby bin dirs already added
		local sep = package.config:sub(1, 1)

		---------------------------------------------------------------------------
		-- Root detection (unchanged logic with fallback)
		---------------------------------------------------------------------------
		local function detect_root(bufnr)
			local fname = vim.api.nvim_buf_get_name(bufnr)
			if fname == "" then
				return vim.loop.cwd()
			end
			local markers = { "sorbet" .. sep .. "config", "Gemfile", ".git" }
			-- Use vim.fs.root (Neovim 0.10+)
			local root = vim.fs.root(bufnr, markers)
			if root then
				return root
			end
			-- Fallback to file directory if no root marker found
			return vim.fn.fnamemodify(fname, ":p:h")
		end

		---------------------------------------------------------------------------
		-- Resolve Ruby SHA via config/ruby-version
		---------------------------------------------------------------------------
		local ruby_version_cache = {} -- root_dir -> sha (or false if none)
		local function read_ruby_sha(root)
			if ruby_version_cache[root] ~= nil then
				return ruby_version_cache[root] or nil
			end

			local script = root .. sep .. "config" .. sep .. "ruby-version"
			if vim.fn.filereadable(script) ~= 1 then
				ruby_version_cache[root] = false
				return nil
			end

			-- Execute script (it uses env switching logic for NEXT / override vars)
			-- NOTE: If security is a concern, you can parse lines instead of executing;
			-- executing respects RUBY_NEXT / JANKY_ENV_RUBY_SHA which you likely want.
			local output = vim.fn.system({ "bash", script })
			if vim.v.shell_error ~= 0 then
				ruby_version_cache[root] = false
				return nil
			end

			local sha = (output or ""):gsub("%s+", "")
			if not sha:match("^[0-9a-fA-F]+$") then
				ruby_version_cache[root] = false
				return nil
			end

			ruby_version_cache[root] = sha
			return sha
		end

		---------------------------------------------------------------------------
		-- Compute vendor ruby bin dir for a root (if any)
		---------------------------------------------------------------------------
		local function vendor_bin_for_root(root)
			local sha = read_ruby_sha(root)
			if not sha then
				return nil
			end
			local candidate = root .. sep .. "vendor" .. sep .. "ruby" .. sep .. sha .. sep .. "bin"
			if vim.fn.isdirectory(candidate) == 1 and vim.fn.executable(candidate .. sep .. "ruby") == 1 then
				return candidate
			end
			return nil
		end

		---------------------------------------------------------------------------
		-- PATH Rebuilder
		--
		-- Order currently:
		--   1. ALL project bins that (had safe-ruby) encountered (most recent first)
		--   2. ALL vendor ruby bins (most recent first)
		--   3. ORIGINAL_PATH
		--
		-- If you want vendor bins to outrank project bins, flip the append order.
		---------------------------------------------------------------------------
		local function rebuild_path()
			local ordered = {}

			-- Collect project bins (PROJECT_BINS keys) - ensure deterministic order:
			for bin, _ in pairs(PROJECT_BINS) do
				table.insert(ordered, bin)
			end
			table.sort(ordered, function(a, b)
				return PROJECT_BINS[a] > PROJECT_BINS[b]
			end) -- newer first by timestamp token

			local proj_list = ordered
			ordered = {}

			for bin, _ in pairs(VENDOR_BINS) do
				table.insert(ordered, bin)
			end
			table.sort(ordered, function(a, b)
				return VENDOR_BINS[a] > VENDOR_BINS[b]
			end)

			local vendor_list = ordered
			ordered = {}

			-- CURRENT ORDER: project bins then vendor bins
			for _, p in ipairs(proj_list) do
				table.insert(ordered, p)
			end
			for _, v in ipairs(vendor_list) do
				table.insert(ordered, v)
			end

			vim.env.PATH = table.concat(ordered, ":") .. ":" .. ORIGINAL_PATH
		end

		local monotonic = 0
		local function mark_time(tbl, key)
			monotonic = monotonic + 1
			tbl[key] = monotonic
		end

		---------------------------------------------------------------------------
		-- Add project bin if safe-ruby exists
		---------------------------------------------------------------------------
		local function add_project_bin(root)
			local bin_dir = root .. sep .. "bin"
			local safe_ruby = bin_dir .. sep .. "safe-ruby"
			if vim.fn.executable(safe_ruby) ~= 1 then
				return
			end
			if not PROJECT_BINS[bin_dir] then
				mark_time(PROJECT_BINS, bin_dir)
				rebuild_path()
			end
		end

		---------------------------------------------------------------------------
		-- Add vendor ruby bin if config/ruby-version resolves
		---------------------------------------------------------------------------
		local function add_vendor_bin(root)
			local vbin = vendor_bin_for_root(root)
			if not vbin then
				return
			end
			if not VENDOR_BINS[vbin] then
				mark_time(VENDOR_BINS, vbin)
				rebuild_path()
			end
		end

		---------------------------------------------------------------------------
		-- Main autocommand
		---------------------------------------------------------------------------
		vim.api.nvim_create_autocmd("BufEnter", {
			desc = "Prefer project vendor Ruby + bin/safe-ruby",
			callback = function(args)
				local root = detect_root(args.buf)
				if not root or root == "" then
					return
				end
				add_vendor_bin(root)
				add_project_bin(root)
			end,
		})

		---------------------------------------------------------------------------
		-- (Optional) Immediate attempt for the current CWD (helps if you open nvim
		-- without an initial file and start running Ruby commands)
		---------------------------------------------------------------------------
		local startup_root = detect_root(0)
		if startup_root then
			add_vendor_bin(startup_root)
			add_project_bin(startup_root)
		end
	end,
}
