{vimUtils}:
vimUtils.buildVimPluginFrom2Nix {
  name = "docker-nvim";
  src = ./.;
}
