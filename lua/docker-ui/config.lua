local default_bo = {
  bufhidden = "wipe",
  buflisted = false,
  buftype = "nofile",
  modeline = false,
  swapfile = false,
}
local default_wo = {
  number = false,
  relativenumber = false,
  signcolumn = "no",
}

local default = vim.tbl_deep_extend("force", {
  style = {
    scratch = {
      bo = default_bo,
      wo = default_wo,
    },
    term = {
      bo = default_bo,
      wo = default_wo,
    },
    image = {
      bo = default_bo,
      wo = default_wo,
    },
    container = {
      bo = default_bo,
      wo = default_wo,
    },
  },
}, {
  style = {
    scratch = {
      bo = { filetype = "docker-scratch" },
    },
    term = {
      bo = { filetype = "log" },
    },
    image = {
      bo = { filetype = "docker-images" },
    },
    container = {
      bo = { filetype = "docker-containers" },
    },
  },
})

local M = {
  config = default,
}

function M.set_config(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts)
end

return M
