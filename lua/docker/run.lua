local Job = require "plenary.job"

return function(image, opts)
  local args = {
    command = "docker",
    args = { "run", image.Repository .. ":" .. image.Tag },
  }
  args = vim.tbl_deep_extend("force", args, opts)

  local job = Job:new(args)
  job:start()
end
