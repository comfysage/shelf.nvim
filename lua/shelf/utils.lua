local utils = {}

utils.reorder = function(bufnr, nbufnr) end

utils.simplify = function() end

local function _getids(layout)
  local _layout = layout
  if layout[1] == 'leaf' then
    return { layout[2] }
  elseif layout[1] == 'row' then
    return { layout[2][1][2] }
  end
  local ids = {}
  for _, l in ipairs(layout[2]) do
    local _ids = _getids(l)
    local j = #ids
    for i, id in ipairs(_ids) do
      ids[i+j] = id
    end
  end
  return ids
end

utils.getheight = function()
  local layout = vim.fn.winlayout()
  local id = _getids(layout)
  local sum = 0
  vim.tbl_map(function(_id)
    local height = vim.api.nvim_win_get_height(_id)
    sum = sum + height
  end, id)

  return sum
end

return utils
