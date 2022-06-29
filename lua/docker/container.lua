local date = require "date"
local json = require "rapidjson"

local Job = require "plenary.job"

local function parse_date(str_date)
  return date(str_date:sub(0, #str_date - 3))
end

local Container = {}
Container.__index = Container

function Container:new(base)
  local obj = {
    type = "container",
    base = base,
    created_at = parse_date(base.CreatedAt),
    name = base.Names,
    syntax = "docker-container",
  }
  return setmetatable(obj, self)
end

function Container:make_line(opts)
  opts = opts or {}
  if opts.verbose then
    return vim.inspect(self.base)
  else
    return self.name
  end
end

function Container:make_extmark(opts)
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

  local cmd = { "docker", "container", "ls", "--format", "{{json .}}" }
  if opts.all then
    table.insert(cmd, "--all")
  end
  local lines = vim.fn.systemlist(cmd)

  local containers = {}
  for _, line in ipairs(lines) do
    local container, e = json.decode(line)
    if container ~= nil then
      assert(type(container) == "table")
      table.insert(containers, Container:new(container))
    else
      assert(e ~= nil)
      error(e)
    end
  end

  return containers
end

function M.rm(container, opts)
  local args = {
    command = "docker",
    args = { "container", "rm", container.name },
  }
  args = vim.tbl_deep_extend("force", args, opts or {})

  local job = Job:new(args)
  job:start()
end

return M
