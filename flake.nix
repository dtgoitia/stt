{
  description = "stt - speech to text transcription utilities";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    lagun = {
      url = "github:dtgoitia/lagun?ref=main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    lagun,
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        name = "stt";

        pkgs = nixpkgs.legacyPackages.${system};
        lagunShell = lagun.devShells.${system}.createShell {
          inherit name;
          extraDockerfileLines = ''
            RUN apt-get update                               \
              && apt-get install -y --no-install-recommends  \
                python3                                      \
                python3-pip                                  \
                python3-venv                                 \
              && rm -rf /var/lib/apt/lists/*                 \
              && ln -s /usr/bin/python3 /usr/bin/python
          '';
        };
        # lagunPkgs = lagun.packages.${system};
        # lagunLib = lagun.lib.${system};
      in {
        packages = {
          record = pkgs.symlinkJoin {
            name = "record";
            paths = [(pkgs.writeScriptBin "record" (builtins.readFile ./bin/record))];
            buildInputs = [pkgs.makeWrapper];
            postBuild = ''
              wrapProgram $out/bin/record \
                --prefix PATH : ${pkgs.lib.makeBinPath [pkgs.ffmpeg]}
            '';
          };

          transcribe = pkgs.writeShellApplication {
            name = "transcribe";
            text = builtins.readFile ./bin/transcribe;
          };
        };

        devShells.default = pkgs.mkShell {
          inputsFrom = [lagunShell]; # bring in lagun's shell

          packages = [
            # add more packages
          ];
        };
      }
    );
}
