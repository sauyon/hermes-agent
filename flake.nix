{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = { nixpkgs, ... }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      packages = forAllSystems (pkgs:
        let
          # Pin to main which includes pre_tool_call blocking hooks (not yet in v0.9.0 release).
          # See: https://github.com/NousResearch/hermes-agent/issues/9388
          hermesSrc = pkgs.fetchFromGitHub {
            owner = "NousResearch";
            repo = "hermes-agent";
            rev = "677f1227c37db376ed12136e286772e5cc65605a";
            hash = "sha256-yB8MPM5qgXD3ur+qdkwnJoDCuazugL7sKWMfzptGlR0=";
          };

          exa-py = pkgs.python3Packages.buildPythonPackage {
            pname = "exa-py";
            version = "2.11.0";
            pyproject = true;
            src = pkgs.fetchPypi {
              pname = "exa_py";
              version = "2.11.0";
              hash = "sha256-mJEDy9g6rm2+iMtw4RUipLsGAm/bVLhlnjp5ItpB/JM=";
            };
            build-system = [ pkgs.python3Packages.poetry-core ];
            dependencies = with pkgs.python3Packages; [
              requests typing-extensions openai pydantic httpx httpcore python-dotenv
            ];
            pythonRelaxDeps = true;
            doCheck = false;
          };

          parallel-web = pkgs.python3Packages.buildPythonPackage {
            pname = "parallel-web";
            version = "0.4.2";
            pyproject = true;
            src = pkgs.fetchPypi {
              pname = "parallel_web";
              version = "0.4.2";
              hash = "sha256-WZtajzh9w1x9yMgeNy6t9pWKQKys6li/Fw38ZjwAPac=";
            };
            postPatch = ''
              sed -i 's/hatchling==1.26.3/hatchling>=1.26.3/' pyproject.toml
            '';
            build-system = with pkgs.python3Packages; [ hatchling hatch-fancy-pypi-readme ];
            dependencies = with pkgs.python3Packages; [
              httpx pydantic typing-extensions anyio distro sniffio
            ];
            pythonRelaxDeps = true;
            doCheck = false;
          };

          fal-client = pkgs.python3Packages.buildPythonPackage {
            pname = "fal-client";
            version = "0.13.2";
            pyproject = true;
            src = pkgs.fetchPypi {
              pname = "fal_client";
              version = "0.13.2";
              hash = "sha256-1UPU/0nyfYS8A4Ur0caqNDYE4H1e0xud941iXgEDCMs=";
            };
            build-system = with pkgs.python3Packages; [ setuptools setuptools-scm ];
            dependencies = with pkgs.python3Packages; [
              httpx httpx-sse msgpack websockets
            ];
            env.SETUPTOOLS_SCM_PRETEND_VERSION = "0.13.2";
            pythonRelaxDeps = true;
            doCheck = false;
          };
        in
        {
          default = pkgs.python3Packages.buildPythonApplication {
            pname = "hermes-agent";
            version = "0.9.0-pre+blocking-hooks";
            pyproject = true;
            src = hermesSrc;

            build-system = [ pkgs.python3Packages.setuptools ];

            dependencies = with pkgs.python3Packages; [
              openai
              anthropic
              httpx
              pydantic
              python-dotenv
              pyyaml
              jinja2
              rich
              prompt-toolkit
              fire
              tenacity
              toml
              tiktoken
              firecrawl-py
              edge-tts
              pyjwt
            ] ++ [
              exa-py
              parallel-web
              fal-client
            ];

            pythonRelaxDeps = true;
            doCheck = false;

            meta = {
              description = "Hermes Agent — the self-improving AI agent (with pre_tool_call blocking hooks)";
              homepage = "https://github.com/NousResearch/hermes-agent";
              license = pkgs.lib.licenses.mit;
            };
          };
        }
      );
    };
}
