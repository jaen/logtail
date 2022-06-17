{ lib, pkgs, fenix, ... }:
  fenix.fromToolchainFile { 
    file = ../../../rust-toolchain.toml;
    sha256 = "sha256-JggKeGlUbx4gzFAIFi7z1/iRd6ECVP/WQ/6pVgYmUYE=";
  }
