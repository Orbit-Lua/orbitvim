local M = {}

local terms = {}

local pos_data = {
  sp = { resize = "height", area = "lines" },
  vsp = { resize = "width", area = "columns" },
}

local function config()
  return require("nvconfig").term
end

local function shell_name()
  return vim.fn.fnamemodify(vim.o.shell, ":t"):lower():gsub("%.exe$", "")
end

local function terminal_cmd(opts)
  if opts.cmd then
    local cmd = { vim.o.shell }
    vim.list_extend(
      cmd,
      vim.split(vim.o.shellcmdflag, "%s+", { trimempty = true })
    )
    table.insert(cmd, type(opts.cmd) == "function" and opts.cmd() or opts.cmd)
    return cmd
  end

  if
    vim.fn.has("win32") == 1
    and vim.tbl_contains({ "powershell", "pwsh" }, shell_name())
  then
    return { vim.o.shell, "-NoLogo" }
  end

  return { vim.o.shell }
end

local function open_float(buf, float_opts)
  local opts = vim.tbl_deep_extend("force", config().float, float_opts or {})
  opts.width = math.ceil(opts.width * vim.o.columns)
  opts.height = math.ceil(opts.height * vim.o.lines)
  opts.row = math.ceil(opts.row * vim.o.lines)
  opts.col = math.ceil(opts.col * vim.o.columns)
  vim.api.nvim_open_win(buf, true, opts)
end

function M.display(opts)
  local term_config = config()

  if opts.pos == "float" then
    open_float(opts.buf, opts.float_opts)
  else
    vim.cmd(opts.pos)
  end

  local win = vim.api.nvim_get_current_win()
  opts.win = win

  vim.bo[opts.buf].buflisted = false
  vim.bo[opts.buf].filetype = "Term_" .. opts.pos:gsub(" ", "")
  vim.api.nvim_win_set_buf(win, opts.buf)

  if opts.pos ~= "float" then
    local pos_type = pos_data[opts.pos]
    if pos_type then
      local size = opts.size or term_config.sizes[opts.pos]
      vim.api["nvim_win_set_" .. pos_type.resize](
        win,
        math.floor(vim.o[pos_type.area] * size)
      )
    end
  end

  for key, value in pairs(term_config.winopts or {}) do
    vim.wo[win][key] = value
  end

  if term_config.startinsert then
    vim.cmd("startinsert")
  end

  if opts.id then
    terms[opts.id] = opts
  end
end

local function create(opts)
  opts.buf = opts.buf or vim.api.nvim_create_buf(false, true)
  M.display(opts)

  if not vim.b[opts.buf].terminal_job_id then
    vim.fn.jobstart(terminal_cmd(opts), { detach = false, term = true })
  end
end

function M.new(opts)
  create(opts)
end

function M.toggle(opts)
  local current = opts.id and terms[opts.id]
  if current and vim.api.nvim_buf_is_valid(current.buf) then
    opts.buf = current.buf
  end

  local win = opts.buf and vim.fn.bufwinid(opts.buf) or -1
  if win == -1 then
    create(opts)
  else
    vim.api.nvim_win_close(win, true)
  end
end

return M
