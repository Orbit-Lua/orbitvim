local endpoint = require("ai.endpoint")

local title = "Minuet"
local add_endpoint = {}

local function notify(message, level)
  vim.notify(message, level or vim.log.levels.INFO, { title = title })
end

local function load_minuet()
  if package.loaded.minuet and package.loaded.minuet.config then
    return
  end

  local ok, lazy = pcall(require, "lazy")
  if ok then
    lazy.load({ plugins = { "minuet-ai.nvim" } })
  end
end

local function apply(value)
  load_minuet()
  return endpoint.apply(value)
end

local function select_endpoint(value)
  local normalized, error_message = endpoint.set(value)
  if not normalized then
    notify(error_message, vim.log.levels.ERROR)
    return
  end

  if apply(normalized) then
    notify("Completion endpoint: " .. normalized)
  else
    notify("Saved endpoint; Minuet will use it when loaded: " .. normalized)
  end
end

local function forget_endpoint(value)
  local current, error_message = endpoint.remove(value)
  if not current then
    notify(error_message, vim.log.levels.ERROR)
    return
  end

  if apply(current) then
    notify("Removed endpoint. Current endpoint: " .. current)
  else
    notify("Removed endpoint. Minuet will use this when loaded: " .. current)
  end
end

local function prompt_for_endpoint()
  vim.ui.input({
    prompt = "Completion endpoint (IP, hostname, or URL): ",
    default = endpoint.current(),
  }, function(value)
    if value then
      select_endpoint(value)
    end
  end)
end

local function choose_endpoint()
  local choices = endpoint.list()
  choices[#choices + 1] = add_endpoint

  vim.ui.select(choices, {
    prompt = "Select completion endpoint",
    format_item = function(item)
      if item == add_endpoint then
        return "+ Add endpoint"
      end
      if item == endpoint.current() then
        return item .. " (current)"
      end
      return item
    end,
  }, function(choice)
    if choice == add_endpoint then
      prompt_for_endpoint()
    elseif choice then
      select_endpoint(choice)
    end
  end)
end

local function choose_endpoint_to_forget()
  local choices = vim.tbl_filter(function(value)
    return value ~= endpoint.default_url()
  end, endpoint.list())

  if vim.tbl_isempty(choices) then
    notify("There are no remote endpoints to remove")
    return
  end

  vim.ui.select(choices, {
    prompt = "Remove completion endpoint",
    format_item = function(item)
      if item == endpoint.current() then
        return item .. " (current)"
      end
      return item
    end,
  }, function(choice)
    if choice then
      forget_endpoint(choice)
    end
  end)
end

vim.api.nvim_create_user_command("MinuetEndpoint", function(args)
  if args.bang then
    if args.args ~= "" then
      forget_endpoint(args.args)
    else
      choose_endpoint_to_forget()
    end
  elseif args.args ~= "" then
    select_endpoint(args.args)
  else
    choose_endpoint()
  end
end, {
  nargs = "?",
  bang = true,
  complete = function(arg_lead)
    return vim.tbl_filter(function(value)
      return vim.startswith(value, arg_lead)
    end, endpoint.list())
  end,
  desc = "Select the Minuet completion API endpoint",
})
