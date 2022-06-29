local docker = R "docker"

local State = {}
State.__index = State

function State:new(obj)
  obj = obj or {}
  obj.items = {}
  obj.mapping = {}
  obj.show_all = false
  return setmetatable(obj, self)
end

local M = {}
M.__index = M

--- The namespace used for extmarks
M.ns = vim.api.nvim_create_namespace "docker-ui"

function M.create(opts)
  vim.cmd "tabnew"
  local bufnr = vim.api.nvim_get_current_buf()
  return M:new(bufnr)
end

function M:new(bufnr)
  vim.api.nvim_buf_set_name(bufnr, "Docker")
  vim.api.nvim_buf_set_var(bufnr, "docker", { type = "scratch" })

  local winid = vim.api.nvim_get_current_win()
  local height = vim.api.nvim_win_get_height(winid)
  local width = vim.api.nvim_win_get_width(winid)

  vim.cmd "new"
  local term_bufnr = vim.api.nvim_get_current_buf()
  local term_winid = vim.api.nvim_get_current_win()
  vim.api.nvim_buf_set_name(term_bufnr, "Output")
  vim.api.nvim_buf_set_var(term_bufnr, "docker", { type = "term" })
  vim.api.nvim_win_set_height(term_winid, math.floor(height / 4))

  local obj = {
    state = {
      scratch = State:new { bufnr = bufnr, winid = winid },
      term = State:new { bufnr = term_bufnr, winid = term_winid },
      image = State:new {
        sort_by = "Repository",
        make_header = function(s)
          return "Images (" .. #s.items .. "; " .. (s.show_all and "all" or "non-intermediate") .. ")"
        end,
      },
      container = State:new {
        sort_by = "Names",
        make_header = function(s)
          return "Containers (" .. #s.items .. "; " .. (s.show_all and "all" or "active") .. ")"
        end,
      },
    },
  }

  -- FIXME: This shit is ugly
  vim.cmd "top vnew"
  obj.state.image.bufnr = vim.api.nvim_get_current_buf()
  obj.state.image.winid = vim.api.nvim_get_current_win()
  vim.api.nvim_buf_set_name(obj.state.image.bufnr, "Images")
  vim.api.nvim_buf_set_var(obj.state.image.bufnr, "docker", { type = "image" })
  vim.api.nvim_win_set_width(obj.state.image.winid, math.floor(width / 5))

  vim.cmd "new"
  obj.state.container.bufnr = vim.api.nvim_get_current_buf()
  obj.state.container.winid = vim.api.nvim_get_current_win()
  vim.api.nvim_buf_set_name(obj.state.container.bufnr, "Containers")
  vim.api.nvim_buf_set_var(obj.state.container.bufnr, "docker", { type = "container" })
  vim.api.nvim_win_set_width(obj.state.container.winid, math.floor(width / 5))
  vim.api.nvim_win_set_height(obj.state.container.winid, math.floor(height / 2))
  -- END: ugly shit

  local config = require("docker-ui.config").config

  for name, t in pairs(config.style) do
    for k, v in pairs(t.bo) do
      vim.bo[obj.state[name].bufnr][k] = v
    end
    for k, v in pairs(t.wo) do
      vim.wo[obj.state[name].winid][k] = v
    end
  end

  vim.api.nvim_set_current_win(winid)

  return setmetatable(obj, self)
end

function M:init()
  self:apply_mappings()
  self:show_welcome_message()
  self:reload "all"
end

local default_keymap = {
  scratch = {
    -- TODO: What should these be?
  },
  container = {
    n = {
      ["?"] = {
        function(self)
          print "Would open container help"
        end,
        { desc = "Show help" },
      },
      ["."] = {
        function(self)
          self.state.container.show_all = not self.state.container.show_all
          self:_reload "container"
        end,
        { desc = "Toggle showing stopped containers" },
      },
      dd = {
        function(self)
          self:delete_item_at_cursor()
        end,
        { desc = "Delete container under cursor" },
      },
      sc = {
        function(self)
          self:_reload("container", { extmark = true, sort_by = "CreatedAt" })
        end,
        { desc = "Sort containers by created date" },
      },
      si = {
        function(self)
          self:_reload("container", { extmark = true, sort_by = "Image" })
        end,
        { desc = "Sort containers by image" },
      },
      ss = {
        function(self)
          self:_reload("container", { extmark = true, sort_by = "State" })
        end,
        { desc = "Sort containers by state" },
      },
      sz = {
        function(self)
          self:_reload("container", { extmark = true, sort_by = "Size" })
        end,
        { desc = "Sort containers by Size" },
      },
      K = {
        function(self)
          self:hover()
        end,
        { desc = "Open container detail popup" },
      },
      R = {
        function(self)
          self:_reload "container"
        end,
        { desc = "Reload containers" },
      },
    },
    v = {
      d = {
        function(self)
          self:delete_visually_selected_items()
        end,
        { desc = "Delete selected containers" },
      },
    },
  },
  image = {
    n = {
      ["?"] = {
        function(self)
          print "Would open image help"
        end,
        { desc = "Show help" },
      },
      ["."] = {
        function(self)
          self.state.image.show_all = not self.state.image.show_all
          self:_reload "image"
        end,
        { desc = "Toggle showing intermediate images" },
      },
      dd = {
        function(self)
          self:delete_item_at_cursor()
        end,
        { desc = "Delete image under cursor" },
      },
      r = {
        function(self)
          self:run_image_under_cursor()
        end,
        { desc = "Run image under cursor" },
      },
      sc = {
        function(self)
          self:_reload("image", { extmark = true, sort_by = "CreatedAt" })
        end,
        { desc = "Sort images by created date" },
      },
      st = {
        function(self)
          self:_reload("image", { extmark = true, sort_by = "Tag" })
        end,
        { desc = "Sort images by tag" },
      },
      sz = {
        function(self)
          self:_reload("image", { extmark = true, sort_by = "Size" })
        end,
        { desc = "Sort images by size" },
      },
      K = {
        function(self)
          self:hover()
        end,
        { desc = "Open image detail popup" },
      },
      P = {
        function(self)
          self:pull_image(vim.fn.input "> ")
        end,
        { desc = "Pull an image" },
      },
      R = {
        function(self)
          self:_reload "image"
        end,
        { desc = "Reload images" },
      },
    },
    v = {
      d = {
        function(self)
          self:delete_visually_selected_items()
        end,
        { desc = "Delete selected images" },
      },
    },
  },
}

function M:apply_mappings()
  local config = require("docker-ui.config").config
  local keymap = vim.tbl_deep_extend("force", config.keymap or {}, default_keymap)

  for buf, bufmaps in pairs(keymap) do
    for mode, modemaps in pairs(bufmaps) do
      for lhs, map in pairs(modemaps) do
        vim.keymap.set(mode, lhs, function()
          map[1](self)
        end, vim.tbl_deep_extend("force", map[2], { buffer = self.state[buf].bufnr }))
      end
    end
  end
end

function M:show_welcome_message()
  local lines = {
    "Welcome to docker-ui.nvim!",
    "-----",
    "In the top left you will find a list of (non-intermediate) images.",
    "In the bottom left you will find a list of (active) containers.",
    "The bottom pane will show any output from, for example, running an image.",
    "You can see more help for each pane by using the help keybind ('?') in normal mode.",
  }
  vim.api.nvim_buf_set_lines(self.state.scratch.bufnr, 0, -1, false, lines)
end

function M:reload(what, opts)
  opts = opts or {}
  if what == "all" then
    for _, k in ipairs { "container", "image" } do
      self:_reload(k, opts)
    end
  else
    self:_reload(what, opts)
  end
end

function M:_reload(what, opts)
  opts = opts or {}
  self.state[what].items = docker[what].ls(vim.tbl_deep_extend("force", { all = self.state[what].show_all }, opts))
  self:render(self.state[what], opts)
end

function M:render(state, opts)
  opts = opts or {}
  local sort_by = opts.sort_by or state.sort_by

  local items = state.items
  table.sort(items, function(a, b)
    return a.base[sort_by] < b.base[sort_by]
  end)

  local lines = {}
  local extmarks = {}
  table.insert(lines, state:make_header())
  for _, item in ipairs(items) do
    table.insert(lines, item:make_line())
    state.mapping[#lines] = item

    if opts.extmark then
      table.insert(extmarks, {
        virt_text = { { item:make_extmark { property = sort_by }, "Comment" } },
        virt_text_pos = "right_align",
      })
    end
  end

  vim.api.nvim_buf_set_lines(state.bufnr, 0, -1, false, lines)
  for i, extmark in ipairs(extmarks) do
    vim.api.nvim_buf_set_extmark(state.bufnr, M.ns, i, 0, extmark)
  end
end

function M:hover()
  local item = self:_item_at_cursor()
  local lines = string.split(item:make_line { verbose = true }, "\n")

  local width = 500
  local height = #lines
  local opts = vim.lsp.util.make_floating_popup_options(width, height, { border = "single" })

  vim.lsp.util.open_floating_preview(lines, item.syntax, opts)
end

function M:delete_item_at_cursor(opts)
  self:_reset_term_buffer()
  local item = self:_item_at_cursor()
  opts = vim.tbl_deep_extend("force", opts or {}, {
    on_stdout = function(_, data)
      vim.schedule(function()
        self:_write_term_lines { data }
      end)
    end,
    on_exit = function()
      vim.schedule(function()
        self:reload(vim.b.docker.type, opts)
      end)
    end,
  })
  docker[vim.b.docker.type].rm(item, opts)
end

local function exit_visual_mode()
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<esc>", true, false, true), "x", true)
end

function M:delete_visually_selected_items(opts)
  local line1 = vim.fn.getpos "'<"
  local line2 = vim.fn.getpos "'>"
  local items = self:_items_for_selection(line1[2], line2[2])

  self:_reset_term_buffer()
  opts = vim.tbl_deep_extend("force", opts or {}, {
    on_stdout = function(_, data)
      vim.schedule(function()
        self:_write_term_lines { data }
      end)
    end,
    on_exit = function()
      self:reload(vim.b.docker.type, opts)
    end,
  })

  for _, item in pairs(items) do
    docker[vim.b.docker.type].rm(item, opts)
  end

  exit_visual_mode()
end

function M:run_item_at_cursor(opts)
  local item = self:_item_at_cursor()
  docker.run(item, opts)
  self:reload("all", opts)
end

function M:_item_at_cursor()
  local line = vim.fn.line "."
  return self.state[vim.b.docker.type].mapping[line]
end

function M:_items_for_selection(line1, line2)
  return table.slice(self.state[vim.b.docker.type].mapping, line1, line2)
end

-- Image-related functions

function M:pull_image(name, opts)
  self:_reset_term_buffer()
  opts = vim.tbl_deep_extend("force", opts or {}, {
    on_stdout = function(_, data)
      vim.schedule(function()
        self:_write_term_lines { data }
      end)
    end,
    on_exit = function()
      vim.schedule(function()
        self:_reload("image", opts)
      end)
    end,
  })
  docker.image.pull(name, opts)
end

function M:run_image_under_cursor(opts)
  self:_reset_term_buffer()
  local item = self:_item_at_cursor()
  docker.run(item.base, {
    on_stdout = function(_, data)
      vim.schedule(function()
        self:_write_term_lines { data }
      end)
    end,
  })
  self:_reload("container", opts)
end

function M:_reset_term_buffer()
  vim.api.nvim_buf_set_lines(self.state.term.bufnr, 0, -1, false, {})
end

function M:_write_term_lines(lines)
  local oldlines = vim.api.nvim_buf_get_lines(self.state.term.bufnr, 0, -1, false)
  vim.api.nvim_buf_set_lines(self.state.term.bufnr, #oldlines, -1, false, lines)
end

return M
