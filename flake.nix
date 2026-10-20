{
  description = "Pure buildRustPackage WASM static generator for GitHub Pages";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
  };

  outputs = { self, nixpkgs }:
    let
      system = "aarch64-darwin"; # Adjust to your development machine architecture
      pkgs = import nixpkgs { inherit system; };
    in {
      packages.${system}.default = let
        # 1. Compile the Rust source code into a raw WebAssembly asset
        raw-wasm = pkgs.rustPlatform.buildRustPackage {
          pname = "frontend-raw-wasm";
          version = "0.1.0";
          src = ./.;

          cargoLock.lockFile = ./Cargo.lock;
          auditable = false; 

          # Build flag manual override (Prevents Nix directory redirection bugs)
          cargoBuildFlags = [ "--target" "wasm32-unknown-unknown" ];
          doCheck = false;

          # Provide LLVM environment variables for linking WASM objects
          depsBuildBuild = [ pkgs.buildPackages.stdenv.cc pkgs.lld ];
          env.RUSTFLAGS = "-C linker=wasm-ld";

          # Robust installPhase using a wildcard lookup
          installPhase = ''
            mkdir -p $out/lib
            # Find the binary wherever Cargo put it and copy it out safely
            find target -name "frontend.wasm" -exec cp {} $out/lib/ \;
          '';
        };


      in pkgs.stdenv.mkDerivation {
        # 2. Extract index.html and generate JS glue logic for production deployment
        name = "github-pages-static-assets";
        src = ./.;
        nativeBuildInputs = [ pkgs.wasm-bindgen-cli ];

        buildPhase = ''
          # Process the binary asset into web-readable js chunks
          wasm-bindgen ${raw-wasm}/lib/frontend.wasm --target web --out-dir .
        '';

        installPhase = ''
          mkdir -p $out
          cp frontend.js frontend_bg.wasm $out/
        '';
      };
    };
}

