{
  description = "OpenHarmony LLVM development shell";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { nixpkgs, ... }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      forAllSystems = nixpkgs.lib.genAttrs systems;

      mkScripts = pkgs: [
        (pkgs.writeShellApplication {
          name = "ohos-fetch-source";
          runtimeInputs = [ pkgs.bash pkgs.git pkgs.git-lfs ];
          text = builtins.readFile ./scripts/ohos-fetch-source.sh;
        })

        (pkgs.writeShellApplication {
          name = "ohos-env-prepare";
          runtimeInputs = [ pkgs.bash ];
          text = builtins.readFile ./scripts/ohos-env-prepare.sh;
        })

        (pkgs.writeShellApplication {
          name = "ohos-clean-out";
          runtimeInputs = [ pkgs.coreutils ];
          text = builtins.readFile ./scripts/ohos-clean-out.sh;
        })

        (pkgs.writeShellApplication {
          name = "ohos-clean-all";
          runtimeInputs = [ pkgs.coreutils ];
          text = builtins.readFile ./scripts/ohos-clean-all.sh;
        })
      ];

      mkPackages = pkgs:
        with pkgs; [
          # Host-side source sync and prebuilt preparation. Compilation happens
          # inside docker/Dockerfile.ubuntu22.
          bash
          cacert
          curl
          git
          python3
          wget
          unzip
          gnutar
          gawk
          gnugrep
          gnused
          diffutils

          # project helper tools
          just
          coreutils
          git-lfs
          clang-tools
          lldb
        ] ++ mkScripts pkgs;

      shellHook = ''
        mkdir -p .nix-dev/bin

        if [ ! -x .nix-dev/bin/repo ]; then
          curl -L https://gitee.com/oschina/repo/raw/fork_flow/repo-py3 \
            -o .nix-dev/bin/repo
          chmod +x .nix-dev/bin/repo
        fi

        export PATH="$PWD/.nix-dev/bin:$PATH"

        echo ""
        echo "Helper commands:"
        echo "  ohos-fetch-source [branch]"
        echo "  ohos-env-prepare"
        echo "  ohos-clean-out --force"
        echo "  ohos-clean-all --force"
        echo ""
      '';

      mkDevShell = system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        pkgs.mkShell {
          packages = mkPackages pkgs;
          LANG = "C.UTF-8";
          LC_ALL = "C.UTF-8";
          inherit shellHook;
        };
    in
    {
      devShells = forAllSystems (system: {
        default = mkDevShell system;
      });
    };
}
