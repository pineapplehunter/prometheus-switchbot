{
  description = "prometheus switchbot prober";

  inputs.nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  inputs.flake-parts.url = "github:hercules-ci/flake-parts";
  inputs.treefmt-nix = {
    url = "github:numtide/treefmt-nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    { flake-parts, ... }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "aarch64-linux"
        "x86_64-linux"
      ];

      perSystem =
        { pkgs, ... }:
        {
          packages = rec {
            default = docker;
            docker = pkgs.dockerTools.streamLayeredImage {
              name = "prometheus-switchbot";
              tag = "latest";

              contents = [
                (pkgs.python3.withPackages (ps: [
                  ps.fastapi
                  ps.jinja2
                  ps.requests
                  ps.uvicorn
                ]))
                (pkgs.runCommand "app-dir" { } ''
                  mkdir -p $out/app
                  cp -r ${./src} $out/app/src
                '')
              ];

              config = {
                Cmd = [
                  "uvicorn"
                  "--host"
                  "0.0.0.0"
                  "src.main:app"
                ];
                WorkingDir = "/app";
              };
            };
          };

          devShells = {
            default = pkgs.mkShell {
              packages = [
                (pkgs.python3.withPackages (ps: [
                  ps.fastapi
                  ps.jinja2
                  ps.requests
                  ps.uvicorn
                ]))
              ];
            };
          };

          # Use nixfmt for all nix files
          formatter =
            (inputs.treefmt-nix.lib.evalModule pkgs {
              projectRootFile = "flake.nix";
              programs.ruff-format.enable = true;
              programs.nixfmt.enable = true;
            }).config.build.wrapper;
        };
    };
}
