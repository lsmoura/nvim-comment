---@text
--- A simple way to add and remove comments from your codebase, without multi cursors

local M = {}

---@type table
local default_comments = {
  c   = "//",
  cpp = "//",
  go  = "//",
  h   = "//",
  hpp = "//",
  js  = "//",
  jsx = "//",
  lua = "--",
  sh  = "#",
  sql = "--",
  ts  = "//",
  tsx = "//",
}

---@class comment.config
---@field comments table? comment style for each file extension
---@field trailing_space boolean? should try to add or remove a trailing space after the comment block

---@type comment.config
local config = {
  comments = default_comments,
  trailing_space = true,
}

M.setup = function(opts)
  opts = opts or {}
  config.comments = opts.comments or config.comments
  config.trailing_space = opts.trailing_space or config.trailing_space
end

local function indentation_level(line_no)
  local line = vim.api.nvim_buf_get_lines(0, line_no - 1, line_no, false)[1]
  if not line then
    return -1
  end

  if line:match("^%s*$") then
    return -1
  end

  local leading = line:match("^[ \t]*")
  return #leading + 1
end

--- Inserts the comment string into the given coordinates, unless the line is empty
---@param line_no number
---@param col_no number
---@param comment string
local function insert_comment_at_position(line_no, col_no, comment)
  local line = vim.api.nvim_buf_get_lines(0, line_no - 1, line_no, false)[1]
  if not line then
    return
  end

  if line:match("^%s*$") then
    return
  end

  local col = math.min(col_no, #line + 1)

  if config.trailing_space then
    comment = comment .. " "
  end

  local new_line = line:sub(1, col - 1) .. comment .. line:sub(col)
  vim.api.nvim_buf_set_lines(0, line_no - 1, line_no, false, { new_line })
end

--- Comment the given line number
---@param line_no number: the line to comment
---@param comment string: the string used to comment
local function comment_line(line_no, comment)
  local col_pos = indentation_level(line_no)
  if col_pos < 0 then
    -- TODO: output message?
    return
  end

  insert_comment_at_position(line_no, col_pos, comment)
end

--- Removes the comment from the beginning of the line, if it exists
---@param line_no number
---@param comment string
local function uncomment_line(line_no, comment)
  local col_no = indentation_level(line_no)
  if col_no < 0 then
    return
  end

  local line = vim.api.nvim_buf_get_lines(0, line_no - 1, line_no, false)[1]
  if line:match("^[ \t]*" .. comment) then
    local tail = line:sub(col_no + #comment)
    -- if trailing_space is true and there is a space on the beginning of the tail,
    -- remove it as well.
    local first = tail:sub(1,1)
    if config.trailing_space and first == " " then
      tail = tail:sub(2)
    end

    local new_line = line:sub(0, col_no - 1) .. tail
    vim.api.nvim_buf_set_lines(0, line_no - 1, line_no, false, { new_line })
  end
end

--- Detects the minimum indentation level on a range of lines
---@param start_line number
---@param end_line number
---@return number: minimum indentation level, -1 if all lines are empty
local function get_min_indentation_level(start_line, end_line)
  local min_level = -1

  for cur_line = start_line, end_line do
    local cur_level = indentation_level(cur_line)
    if cur_level >= 0 then
      if min_level < 0 then
        min_level = cur_level
      else
        min_level = math.min(min_level, cur_level)
      end
    end
    if min_level == 0 then
      return min_level
    end
  end

  return min_level
end

local function toggle_line(line_no, comment)
  local line = vim.api.nvim_buf_get_lines(0, line_no - 1, line_no, false)[1]
  if not line then
    return
  end

  if line:match("^%s*$") then
    return
  end

  local pattern = "^%s*" .. vim.pesc(comment)
  if line:match(pattern) then
    uncomment_line(line_no, comment)
  else
    comment_line(line_no, comment)
  end
end

------ end of helper functions ------

local function comment_current_line()
  local ft = vim.bo.filetype
  local comment = config.comments[ft]
  if not comment then
    vim.notify("unsupported file type: " .. ft)
    return
  end

  local line_no = vim.api.nvim_win_get_cursor(0)
  comment_line(line_no[1], comment)
end

local function uncomment_current_line()
  local ft = vim.bo.filetype
  local comment = config.comments[ft]
  if not comment then
    vim.notify("unsupported file type: " .. ft)
    return
  end

  local line_no = vim.api.nvim_win_get_cursor(0)
  uncomment_line(line_no[1], comment)
end

local function toggle_current_line()
  local ft = vim.bo.filetype
  local comment = config.comments[ft]
  if not comment then
    vim.notify("unsupported file type: " .. ft)
    return
  end

  local line_no = vim.api.nvim_win_get_cursor(0)
  toggle_line(line_no[1], comment)
end


local function comment_block()
  local ft = vim.bo.filetype
  local comment = config.comments[ft]
  if not comment then
    vim.notify("unsupported file type: " .. ft)
    return
  end

  local start_pos = vim.fn.getpos(".")
  local end_pos = vim.fn.getpos("v")

  local start_line = start_pos[2]
  local end_line = end_pos[2]

  if start_line > end_line then
    start_line, end_line = end_line, start_line
  end

  local ident_level = get_min_indentation_level(start_line, end_line)
  if ident_level < 0 then
     -- no lines to comment
    return
  end

  for cur_line = start_line, end_line do
    insert_comment_at_position(cur_line, ident_level, comment)
  end
end

local function uncomment_block()
  local ft = vim.bo.filetype
  local comment = config.comments[ft]
  if not comment then
    vim.notify("unsupported file type: " .. ft)
    return
  end

  local start_pos = vim.fn.getpos(".")
  local end_pos = vim.fn.getpos("v")

  local start_line = start_pos[2]
  local end_line = end_pos[2]

  if start_line > end_line then
    start_line, end_line = end_line, start_line
  end

  for cur_line = start_line, end_line do
    uncomment_line(cur_line, comment)
  end
end

local function toggle_block()
  local ft = vim.bo.filetype
  local comment = config.comments[ft]
  if not comment then
    vim.notify("unsupported file type: " .. ft)
    return
  end

  local start_pos = vim.fn.getpos(".")
  local end_pos = vim.fn.getpos("v")

  local start_line = start_pos[2]
  local end_line = end_pos[2]

  if start_line > end_line then
    start_line, end_line = end_line, start_line
  end

  local should_comment = false

  for cur_line = start_line, end_line do
    local line = vim.api.nvim_buf_get_lines(0, cur_line - 1, cur_line, false)[1]
    if not line:match("^%s*$") then
      local pattern = "^%s*" .. vim.pesc(comment)
      --if line:match(pattern) then
      --  should_comment = false
      --else
      --  should_comment = true
      --end
      should_comment = not line:match(pattern)

      break
    end
  end

  if should_comment then
    comment_block()
  else
    uncomment_block()
  end
end

local function comment()
  local mode = vim.api.nvim_get_mode().mode

  if mode == "n" then
    comment_current_line()
  elseif mode == "v" or mode == "V" then
    comment_block()
  else
    vim.notify("unsupported mode: " .. mode)
    return
  end
end

local function uncomment()
  local mode = vim.api.nvim_get_mode().mode

  if mode == "n" then
    uncomment_current_line()
  elseif mode == "v" or mode == "V" then
    uncomment_block()
  else
    vim.notify("unsupported mode: " .. mode)
    return
  end
end

--- Detects the current mode and the existence of comments, then adds the comment if not present
--- or removes it if not present.
--- When triggering on multiple lines, uses the first non-empty line to determine if a comment
--- should be added or removed
local function toggle()
  local mode = vim.api.nvim_get_mode().mode

  if mode == "n" then
    toggle_current_line()
  elseif mode == "v" or mode == "V" then
    toggle_block()
  else
    vim.notify("unsupported mode: " .. mode)
    return
  end
end

M.comment_line = comment_current_line
M.uncomment_line = uncomment_current_line
M.toggle_line = toggle_current_line
M.comment_block = comment_block
M.uncomment_block = uncomment_block
M.toggle_block = toggle_block
M.comment = comment
M.uncomment = uncomment
M.toggle = toggle

M.default_comments = default_comments

-- vim.keymap.set({ 'n', 'v' }, '<leader>/', toggle, {})

return M

