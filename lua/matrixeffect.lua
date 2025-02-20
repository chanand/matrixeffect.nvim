---@diagnostic disable: undefined-field
local M = {}

local state = {
  floats = {},
  timer = nil,
  columns = {},
  highlights_created = false,
  original_bg = nil,
}

local matrix_chars = "abcdefghijklmnopqrstuvwxyz1234567890!@#$%^&*()-+_"

local function get_random_char()
  local index = math.random(1, #matrix_chars)
  return string.sub(matrix_chars, index, index)
end

local function setup_highlights()
  if state.highlights_created then
    return
  end

  vim.api.nvim_set_hl(0, "MatrixBright", { fg = "#00FF00", bold = true })
  vim.api.nvim_set_hl(0, "MatrixMedium", { fg = "#00CC00" })
  vim.api.nvim_set_hl(0, "MatrixDim", { fg = "#009900" })
  vim.api.nvim_set_hl(0, "MatrixVeryDim", { fg = "#006600" })

  state.highlights_created = true
end

local function create_column(buf, width, height, col)
  local length = math.random(5, height / 2)
  local chars = {}

  for i = 1, length do
    chars[i] = get_random_char()
  end

  return {
    pos = -math.random(1, height),
    speed = math.random(10, 30) / 10,
    chars = chars,
    length = length,
    last_update = 0,
    col = col,
    change_counter = 0,
  }
end

local function update_matrix()
  if not state.floats.main or not state.floats.main.buf then
    if state.timer then
      state.timer:stop()
      state.timer = nil
    end
    return
  end

  local buf = state.floats.main.buf
  local width = vim.api.nvim_win_get_width(state.floats.main.win)
  local height = vim.api.nvim_win_get_height(state.floats.main.win)

  if #state.columns == 0 then
    for i = 0, width - 1 do
      state.columns[i] = create_column(buf, width, height, i)
    end
  end

  for i = 0, width - 1 do
    local col = state.columns[i]
    col.last_update = col.last_update + col.speed

    if col.last_update >= 1 then
      col.last_update = 0
      col.pos = col.pos + 1

      if col.pos - col.length > height then
        col.pos = -math.random(1, height / 2)
        col.length = math.random(5, height / 2)
        col.speed = math.random(10, 30) / 10

        col.chars = {}
        for i = 1, col.length do
          col.chars[i] = get_random_char()
        end
      end

      col.change_counter = col.change_counter + 1
      if col.change_counter >= 3 then -- Change every 3 updates
        col.change_counter = 0
        col.chars[1] = get_random_char()
      end

      for j = 0, col.length - 1 do
        local row = math.floor(col.pos) - j
        if row >= 0 and row < height then
          local char_index = j + 1
          if char_index > #col.chars then
            char_index = #col.chars
          end
          local char = col.chars[char_index]

          vim.api.nvim_buf_set_text(buf, row, col.col, row, col.col + 1, { char })

          if j == 0 then
            vim.api.nvim_buf_add_highlight(buf, -1, "MatrixBright", row, col.col, col.col + 1)
          elseif j < 3 then
            vim.api.nvim_buf_add_highlight(buf, -1, "MatrixMedium", row, col.col, col.col + 1)
          elseif j < 6 then
            vim.api.nvim_buf_add_highlight(buf, -1, "MatrixDim", row, col.col, col.col + 1)
          else
            vim.api.nvim_buf_add_highlight(buf, -1, "MatrixVeryDim", row, col.col, col.col + 1)
          end
        end
      end

      local clear_row = math.floor(col.pos) - col.length
      if clear_row >= 0 and clear_row < height then
        vim.api.nvim_buf_set_text(buf, clear_row, col.col, clear_row, col.col + 1, { " " })
      end
    end
  end
end

local function create_floating_window(config, enter)
  if enter == nil then
    enter = false
  end

  local buf = vim.api.nvim_create_buf(false, true)
  local win = vim.api.nvim_open_win(buf, enter or false, config)

  return { buf = buf, win = win }
end

local present_keymap = function(mode, key, callback)
  vim.keymap.set(mode, key, callback, {
    buffer = state.floats.main.buf,
  })
end

M.setup = function()
  -- nothing
end

local function cleanup()
  if state.timer then
    state.timer:stop()
    state.timer:close()
    state.timer = nil
  end

  if state.floats.main and state.floats.main.win and vim.api.nvim_win_is_valid(state.floats.main.win) then
    vim.api.nvim_win_close(state.floats.main.win, true)
  end

  state.columns = {}

  vim.api.nvim_set_hl(0, "Normal", { bg = state.original_bg })
  state.original_bg = nil

  state.floats.main = nil
end

M.start_matrix = function()
  cleanup()

  local width = vim.o.columns
  local height = vim.o.lines

  local win_config = {
    relative = "editor",
    width = width,
    height = height,
    style = "minimal",
    border = "none",
    col = 0,
    row = 0,
  }

  local original_hl = vim.api.nvim_get_hl(0, { name = "Normal" })
  state.original_bg = original_hl.bg
  print(original_hl)

  state.floats.main = create_floating_window(win_config, true)

  vim.api.nvim_set_hl(0, "Normal", { bg = "#000000" })

  setup_highlights()

  local lines = {}
  for i = 1, height do
    lines[i] = string.rep(" ", width)
  end
  vim.api.nvim_buf_set_lines(state.floats.main.buf, 0, -1, false, lines)

  state.columns = {}

  if state.timer then
    state.timer:stop()
  end
  state.timer = vim.loop.new_timer()
  state.timer:start(0, 80, vim.schedule_wrap(update_matrix))

  present_keymap("n", "q", cleanup)

  vim.api.nvim_create_autocmd({ "BufWipeout", "BufDelete" }, {
    buffer = state.floats.main.buf,
    callback = function()
      cleanup()
    end,
    once = true,
  })
end

vim.api.nvim_create_user_command("StartMatrixEffect", M.start_matrix, {})

return M
