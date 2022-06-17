{ lib, system, pkgs, inputs, flakeRevision, ... }:
  let
    dream2nix = inputs.dream2nix.lib.init {
      inherit pkgs;

      config ={
        disableIfdWarning = true;
        projectRoot = ./../..;
      };
    };

    rust-nightly = pkgs.callPackage ./rust-nightly {};

    dream2nixOutputs = (dream2nix.makeOutputs {
      source = ./../..;
      settings = [
        {
          builder = "crane";
          translator = "cargo-lock";
        }
      ];
      packageOverrides = {
        "^.*".set-toolchain.overrideRustToolchain = _: { cargo = rust-nightly; };
      };
    });
  in
    {
      inherit rust-nightly;
    } // dream2nixOutputs.packages
