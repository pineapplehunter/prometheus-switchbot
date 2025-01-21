{
  description = "A basic shell";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    systems.url = "github:nix-systems/default";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      systems,
      treefmt-nix,
    }:
    let
      eachSystem = nixpkgs.lib.genAttrs (import systems);
      pkgsFor = system: import nixpkgs { inherit system; };
    in
    {
      devShells = eachSystem (
        system:
        let
          pkgs = pkgsFor system;
        in
        {
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
        }
      );

      packages = eachSystem (
        system:
        let
          pkgs = pkgsFor system;
        in
        rec {
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

        }
      );

      formatter = eachSystem (
        system:
        (treefmt-nix.lib.evalModule (pkgsFor system) {
          projectRootFile = "flake.nix";
          programs.nixfmt.enable = true;
        }).config.build.wrapper
      );

      legacyPackages = eachSystem pkgsFor;
    };
}
