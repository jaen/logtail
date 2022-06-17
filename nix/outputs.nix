inputs@{
  self,
  nixpkgs,
  crane,
  fenix,
  dream2nix,
  flake-utils-plus,
  nix-gitignore,
  devshell,
  flake-compat,
  ...
}:
  let
    inherit (flake-utils-plus.lib) defaultSystems eachDefaultSystem;
    inherit (nixpkgs) lib;

    flakeRevision = if (self ? rev) then self.rev else "<unknown>";

    gitignoreSrcOverlay = final: prev:
      { lib = prev.lib.extend (self: super: { inherit (import nix-gitignore { lib = super; }) gitignoreSource gitignoreFilter; }); };

    pkgImport = { pkgs, system, overlays ? [], config ? {} }:
      import pkgs {
        inherit system;

        overlays = [
          devshell.overlay
          fenix.overlay
          gitignoreSrcOverlay
        ] ++ overlays;

        config = { allowUnfree = true; } // config;
      };
  in
    eachDefaultSystem
      (system:
        let
          inherit (pkgs.dockerTools) buildImage buildLayeredImage buildLayeredImageWithNixDb;

          packagesOverlay = final: prev:
            { jaen = (prev.jaen or {}) // packages; };

          pkgs = pkgImport { inherit system; overlays = [ packagesOverlay ]; pkgs = nixpkgs; };

          packages = pkgs.callPackages ./packages { inherit inputs flakeRevision; };
        in
          {
            inherit packages;

            defaultPackage = packages.logtail-cli;

            devShell = pkgs.mkShell {
              buildInputs = with pkgs; [
                cmake
                pkg-config

                jaen.rust-nightly 

                # nixUnstable

                # jaen.ruby_3_1.devEnv

                # # # A slim git so that you know what it does
                # # slimGit
                # git

                # # Dependencies for `bundle install` should you want to use it
                # # Compilation
                # cmake
                # pkg-config

                # # deps for rugged
                # openssl

                # # deps for libxml
                # libxml2
                # libxml2.dev
                # libxslt
                # libxslt.dev
                # zlib

                # # Inspecting the docker image
                # dive

                # fresha.logtail
              ];
            };
          })
