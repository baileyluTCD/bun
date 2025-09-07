{
  description = "An unoffical development flake for bun";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs.follows = "nixpkgs";

    zig.url = "github:mitchellh/zig-overlay";
    zig.inputs.nixpkgs.follows = "nixpkgs";

    # Used for as a nix formatting check when commiting.
    pre-commit-hooks.url = "github:cachix/git-hooks.nix";
    pre-commit-hooks.inputs.nixpkgs.follows = "nixpkgs";

    # Used for Shell.nix and default.nix compat
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
  };

  outputs =
    inputs@{ nixpkgs, flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = nixpkgs.lib.systems.flakeExposed;
      perSystem =
        {
          config,
          self',
          pkgs,
          system,
          ...
        }: let
          inherit (pkgs) lib;

          llvmPackages = pkgs.llvmPackages_19.override {
            nativeBuildInputs = with pkgs; [
              zstd
            ];
            devExtraCmakeFlags = [
              (lib.cmakeBool "LLVM_USE_STATIC_ZSTD" true)
            ];
          };
        in
        {
          formatter = pkgs.nixfmt-rfc-style;
          _module.args.pkgs = import nixpkgs {
            inherit system;
            overlays = [
              (final: prev: {
                zig = inputs.zig.packages.${prev.system};
              })
            ];
          };

          checks = {
            pre-commit-check = inputs.pre-commit-hooks.lib.${system}.run {
              src = ./.;
              hooks = {
                nixfmt-rfc-style.enable = true;
              };
            };
          };

          devShells.default = pkgs.mkShell {
            nativeBuildInputs =
              with pkgs;
              [
                zstd
                automake
                zig."0.14.0"
                ccache
                cmake
                coreutils-full
                gnused
                go
                libiconv
                libtool
                ninja
                pkg-config
                ruby
                rustc
                cargo
                bun
                llvmPackages.lldb
                llvmPackages.libstdcxxClang
                llvmPackages.libllvm
                llvmPackages.libcxx
                llvmPackages.lld
                clang-tools
                clang
                autoconf
                icu
              ]
              ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
                pkgs.apple-sdk_15
              ];
          };
        };
    };
}
