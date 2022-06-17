{
  description = "A simple log tailer for loki";

  inputs = {
    nixpkgs          = { url = "nixpkgs/nixpkgs-unstable"; };
    crane            = { url = "github:ipetkov/crane"; inputs.nixpkgs.follows = "nixpkgs"; };
    fenix            = { url = "github:nix-community/fenix"; inputs.nixpkgs.follows = "nixpkgs"; };
    # dream2nix        = { url = "github:nix-community/dream2nix"; inputs.nixpkgs.follows = "nixpkgs"; inputs.crane.follows = "crane"; };
    dream2nix        = { url = "github:nix-community/dream2nix/feat/override-rust-toolchain"; inputs.nixpkgs.follows = "nixpkgs"; inputs.crane.follows = "crane"; };
    flake-utils-plus = { url = "github:gytis-ivaskevicius/flake-utils-plus"; inputs.nixpkgs.follows = "nixpkgs"; };
    nix-gitignore    = { url = "github:hercules-ci/gitignore.nix"; flake = false; };
    devshell         = { url = "github:numtide/devshell"; inputs.nixpkgs.follows = "nixpkgs"; };
    # For https://github.com/edolstra/flake-compat/pull/18 as a part of solution to https://github.com/NixOS/nix/issues/3978
    flake-compat     = { url = "github:BBBSnowball/flake-compat?rev=a565cb46bee9fa856a6c15bc9c3bb947fbb784ec"; flake = false; };
  };

  outputs = args: import ./nix/outputs.nix args;
}
