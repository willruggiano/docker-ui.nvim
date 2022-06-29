{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    pre-commit.url = "github:cachix/pre-commit-hooks.nix";
  };

  outputs = {
    self,
    nixpkgs,
    pre-commit,
    utils,
    ...
  } @ inputs:
    utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {inherit system;};
    in {
      checks = {
        pre-commit = pre-commit.lib."${system}".run {
          src = ./.;
          hooks = let
            pre-commit-hooks = "${pkgs.python3Packages.pre-commit-hooks}/bin";
          in {
            alejandra.enable = true;
            check-merge-conflict = {
              enable = true;
              entry = "${pre-commit-hooks}/check-merge-conflict";
              types = ["text"];
            };
            end-of-file-fixer = {
              enable = true;
              entry = "${pre-commit-hooks}/end-of-file-fixer";
              types = ["text"];
            };
            stylua = {
              enable = true;
              entry = "${pkgs.stylua}/bin/stylua";
              types = ["file" "lua"];
            };
            trailing-whitespace = {
              enable = true;
              entry = "${pre-commit-hooks}/trailing-whitespace-fixer";
              types = ["text"];
            };
          };
        };
      };

      devShell = pkgs.mkShell {
        name = "docker-nvim";
        inherit (self.checks."${system}".pre-commit) shellHook;
      };

      packages.docker-ui-nvim = pkgs.callPackage ./default.nix {};

      overlays.default = final: prev: {
        docker-ui-nvim = prev.callPackage ./default.nix {};
      };
    });
}
