local date = require "date"
local json = require "rapidjson"

local Job = require "plenary.job"

local function parse_date(str_date)
  return date(str_date:sub(0, #str_date - 3))
end

local Image = {}
Image.__index = Image

function Image:new(base)
  local obj = {
    type = "image",
    base = base,
    created_at = parse_date(base.CreatedAt),
    name = base.Repository .. ":" .. base.Tag,
    syntax = "docker-image",
  }
  return setmetatable(obj, self)
end

function Image:make_line(opts)
  opts = opts or {}
  if opts.verbose then
    return vim.inspect(self.base)
  else
    return self.name
  end
end

function Image:make_extmark(opts)
  local property = opts.property
  if property == "CreatedAt" then
    return self.created_at:fmt "%b %d, %H:%M:%S"
  else
    return self.base[property]
  end
end

local M = {}

function M.ls(opts)
  opts = opts or {}

  local cmd = { "docker", "image", "ls", "--format", "{{json .}}" }
  if opts.all then
    table.insert(cmd, "--all")
  end
  local lines = vim.fn.systemlist(cmd)

  local images = {}

  for _, line in ipairs(lines) do
    local image, e = json.decode(line)
    if image ~= nil then
      assert(type(image) == "table")
      table.insert(images, Image:new(image))
    else
      assert(e ~= nil)
      error(e)
    end
  end

  return images
end

function M.pull(name, opts)
  local args = {
    command = "docker",
    args = { "image", "pull", name },
  }
  args = vim.tbl_deep_extend("force", args, opts)
  local job = Job:new(args)
  job:start()
end

function M.rm(image, opts)
  local args = {
    command = "docker",
    args = { "image", "rm", image.name },
  }
  args = vim.tbl_deep_extend("force", args, opts)
  local job = Job:new(args)
  job:start()
end

return M
