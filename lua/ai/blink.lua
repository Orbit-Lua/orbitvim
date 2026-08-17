local M = {}

local Source = {}
Source.__index = Source

function Source:delegate()
  if not self.source then
    self.source = require("minuet.blink").new()
  end
  return self.source
end

function Source:get_trigger_characters()
  return self:delegate():get_trigger_characters()
end

function Source:get_completions(context, callback)
  return self:delegate():get_completions(context, callback)
end

function M.new()
  return setmetatable({}, Source)
end

return M
