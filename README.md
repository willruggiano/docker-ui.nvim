# docker-ui.nvim

A UI for Docker, in Neovim.

NOTE THAT THIS PLUGIN IS REALLY JUST A POC!
See below "Inspiration" for an explanation.

< insert image >

## Setup

```lua
-- Using Packer
use {
  "willruggiano/docker-ui.nvim",
  config = function()
    vim.keymap.set("n", "<leader>do", function()
      require("docker-ui").open()
    end, { desc = "Docker" })
  end,
  requires = "nvim-lua/plenary.nvim",
  rocks = ["date", "rapidjson"]
}
```

### Dependencies

- plenary.nvim
- The "date" luarocks package
- The "rapidjson" luarocks package

## Inspiration, and the plan moving forward

I wanted to make this plugin a lot like [vim-dadbod][dadbod] and the associated [vim-dadbod-ui][dadbod-ui].
It is supposed to be simple, yet highly configurable to allow you to make it work for you.

In these (super!) early stages of development, I've spent the majority of my time finding a simple but useful ui layout. I have that, for the most part, now.
Really, this project started as an excuse to create a Lua API for Docker, ala [docker-py][docker-py]. Now that the UI is somewhat intact and usable, I am going to shift focus to that project. In truth, I am not really a UI guy anyways; I hate building UIs. That means that I _hope_ someone else comes along who _does_ like UIs and wants to take over this project and make it super nice.

Note that currently the UI uses a "stub" of the eventual docker-lua API. By "stub", I mean that it has the interfaces that I needed to get the UI up and running, but makes system calls to get the data (via the `docker` cli). It isn't pretty, but the docker cli lets you output data in json format which makes it easy to ingest in Lua and, eventually, easy to switch from the stub library to the official sdk.

[dadbod]: https://github.com/tpope/vim-dadbod
[dadbod-ui]: https://github.com/kristijanhusak/vim-dadbod-ui
[docker-py]: https://github.com/docker/docker-py
