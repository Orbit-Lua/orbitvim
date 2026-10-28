---@type RoslynNvimConfig
return {
  filewatching = "roslyn",
  silent = true,
  choose_target = function(targets)
    local root = targets[1] and vim.fs.root(targets[1], ".git")
    if not root then
      return nil
    end

    local solution
    for name, kind in vim.fs.dir(root) do
      if kind == "file" and name:match("%.sln$") then
        if solution then
          return nil
        end
        solution = vim.fs.joinpath(root, name)
      end
    end

    -- Roslyn has already filtered candidates by project membership.
    for _, target in ipairs(targets) do
      if vim.fs.normalize(target) == solution then
        return target
      end
    end
  end,
}
