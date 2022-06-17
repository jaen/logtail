{ pkgs, bundlerApp, git, lib, flakeRevision, ... }:
  let
    repoRoot = ./../../..;
    ruby = pkgs.jaen.ruby_3_1;
    imageBuilderRuntimeDependencies = [
      git
    ];
    logtail-gems = pkgs.bundlerEnv {
      inherit ruby;

      name      = "logtail-gems";
      gemdir    = repoRoot;
      gemset    = ./gemset.nix;
      # Bundix still hates me (more to the point, has issues when you try to install
      # just the production gems for example)
      groups    = [ "default" "development" "test" ];

      gemConfig = pkgs.defaultGemConfig // {
        nokogiri = attrs: ((pkgs.defaultGemConfig.nokogiri attrs) // {
          buildInputs = [ pkgs.zlib ];
        });
        rugged   = attrs: ((pkgs.defaultGemConfig.rugged attrs) // {
          postInstall = ''
            # clean up after build
            rm -rf $GEM_HOME/gems/rugged-${ attrs.version }/vendor;
            rm -rf $GEM_HOME/gems/rugged-${ attrs.version }/ext;
          '';
        });
      };
    };
    wrappedGit = (pkgs.writeShellScriptBin "git" ''
      cd "${ repoRoot }"
      ${ pkgs.git }/bin/git "$@"
    '');
  in
    pkgs.stdenv.mkDerivation {
      name = "logtail";
      src = lib.gitignoreSource repoRoot;

      buildInputs = with pkgs; [
        makeWrapper
        rsync
        wrappedGit
        logtail-gems.wrappedRuby
      ];

      # I would expect doing `patchShebangs` on the `logtail` executable would work,
      # but apparently MacOS ignores shebangs with interpreters that are scripts (such as
      # Ruby `makeWrapper`'d to have gems on it's `RUBYLIB` path). Instead we put the 
      # Ruby at the front of the path and expect `#!/usr/bin/env ruby` to find that
      rubyPath = lib.makeBinPath [ logtail-gems.wrappedRuby ];

      depsPath = lib.makeBinPath imageBuilderRuntimeDependencies;

      # This probably should be smarter than just listing out what you want to
      # copy and what to skip (as it's easy to bug out the build that way), but
      # I'm not sure what's correct to do here
      installPhase = ''
        sed -i -E \
          's/^(\s*)COMMIT(\s*)=(\s*)"<unknown>"\s*$/\1COMMIT\2=\3"${ flakeRevision }"/g' \
          lib/image_builder/version.rb

        mkdir -p "$out/gem";
        rsync -a "$PWD/" "$out/gem" --include lib/image_builder/docker/ \
                                    --exclude docker/ \
                                    --exclude ci/ \
                                    --exclude bin/ \
                                    --exclude nix/ \
                                    --exclude '/*.nix' \
                                    --exclude flake.lock \
                                    --exclude .tool-versions \
                                    --exclude .dockerignore \
                                    --exclude .gitignore \
                                    --exclude .envrc \
                                    --exclude README.md \
                                    --exclude logtail.gemspec \
                                    --exclude examples/ \
                                    --exclude mkdocs.yml \
                                    --exclude spec/ \
                                    --exclude Rakefile \
                                    --exclude Guardfile \
                                    --exclude docs/;

        chmod +w "$out/gem/exe";
        chmod +x "$out/gem/exe/logtail";
        # patchShebangs --host "$out/gem/exe/logtail";
      '';

      fixupPhase = ''
        makeWrapper \
          "$out/gem/exe/logtail" \
          "$out/bin/logtail" \
          --argv0 logtail \
          --set BUNDLE_FROZEN 1 \
          --prefix RUBYLIB : "$out/gem/lib" \
          --prefix PATH : "$depsPath" \
          --prefix PATH : "$rubyPath";
      '';
    }
