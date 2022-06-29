local config = require "docker-ui.config"
local ui = require "docker-ui.ui"

local M = {}

function M.setup(opts)
  vim.validate {
    opts = { opts, "table", true },
  }

  config.set_config(opts)
end

function M.open(opts)
  opts = opts or {}
  vim.validate {
    opts = { opts, "table" },
  }

  M.ui = ui.create(opts)
  M.ui:init()
end

return M
