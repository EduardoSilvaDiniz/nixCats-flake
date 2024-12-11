{
  description = "Um flake Lua-natic para o neovim, com gatos extras! nixCats!";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nixCats.url = "github:BirdeeHub/nixCats-nvim";
  };

  # veja :help nixCats.flake.outputs
  outputs = {
    self,
    nixpkgs,
    nixCats,
    ...
  } @ inputs: let
    inherit (nixCats) utils;
    luaPath = "${./.}";
    forEachSystem = utils.eachSystem nixpkgs.lib.platforms.all;
    # a seguinte extra_pkg_config contém quaisquer valores
    # que você queira passar para o conjunto de configurações do nixpkgs
    # importar nixpkgs { config = extra_pkg_config; inherit system; }
    # não se aplicará a imports de módulo
    # pois isso terá seus valores de sistema
    extra_pkg_config = {
      #allowUnfree = true;
    };
    # o gerenciamento da variável de sistema é uma das partes mais difíceis de usar flakes.

    # então eu fiz isso de uma maneira interessante para mantê-la fora do caminho.
    # Ela é resolvida dentro do próprio construtor, e depois passada para suas
    # categoryDefinitions e packageDefinitions.

    # isso permite que você use ${pkgs.system} sempre que quiser nessas seções
    # sem medo.

    # às vezes nossos overlays exigem um ${system} para acessar o overlay.
    # Seus dependencyOverlays podem ser listas
    # em um conjunto de ${system}, ou simplesmente uma lista.
    # a função do construtor nixCats aceitará ambos.
    # veja :help nixCats.flake.outputs.overlays
    dependencyOverlays =
      /*
      (import ./overlays inputs) ++
      */
      [
        # Este overlay captura todos os inputs nomeados no formato
        # `plugins-<pluginName>`
        # Uma vez que adicionamos esse overlay ao nosso nixpkgs, podemos
        # usar `pkgs.neovimPlugins`, que é um conjunto dos nossos plugins.
        (utils.standardPluginOverlay inputs)
        # adicione quaisquer outros overlays de flake aqui.

        # quando outras pessoas estragam seus overlays ao envolvê-los com system,
        # você pode em vez disso chamar essa função no overlay delas.
        # ela verificará se ele tem o sistema no conjunto, e se sim, retornará o overlay desejado
        # (utils.fixSystemizedOverlay inputs.codeium.overlays
        #   (system: inputs.codeium.overlays.${system}.default)
        # )
      ];

    # veja :help nixCats.flake.outputs.categories
    # e
    # :help nixCats.flake.outputs.categoryDefinitions.scheme
    categoryDefinitions = {
      pkgs,
      settings,
      categories,
      extra,
      name,
      mkNvimPlugin,
      ...
    } @ packageDef: {
      # para definir e usar uma nova categoria, basta adicionar uma nova lista a um conjunto aqui,
      # e mais tarde, você incluirá categoryname = true; no conjunto que você
      # fornecer quando construir o pacote usando esta função do construtor.
      # veja :help nixCats.flake.outputs.packageDefinitions para mais informações sobre essa seção.

      # lspsAndRuntimeDeps:
      # esta seção é para dependências que devem estar disponíveis
      # em TEMPO DE EXECUÇÃO para plugins. Estarão disponíveis no PATH dentro do terminal do neovim
      # isso inclui LSPs
      lspsAndRuntimeDeps = {
        general = with pkgs; [
          ripgrep
          fd
        ];

        java = with pkgs; [
          jdt-language-server # LSP
          lombok # extra
          graalvm-ce # Extra
        ];

        # these names are arbitrary.
        lint = with pkgs; {
          java = [checkstyle pmd];
        };

        # but you can choose which ones you want
        # per nvim package you export
        debug = with pkgs; {
          go = [delve];
          java = [
            vscode-extensions.vscjava.vscode-java-test
            vscode-extensions.vscjava.vscode-java-debug
            vscode-extensions.vscjava.vscode-gradle
          ];
        };

        go = with pkgs; [
          gopls
          gotools
          go-tools
          gccgo
        ];

        # and easily check if they are included in lua
        format = with pkgs; {
          java = [google-java-format];
        };

        neonixdev = {
          # also you can do this.
          inherit (pkgs) nix-doc lua-language-server nixd;
          # and each will be its own sub category
        };
      };

      startupPlugins = {
        # debug = with pkgs.vimPlugins; [
        #   nvim-nio
        # ];
        general = with pkgs.vimPlugins; {
          # you can make subcategories!!!
          # (always isnt a special name, just the one I chose for this subcategory)
          always = [
            rocks-nvim
            # vim-repeat
            # plenary-nvim
          ];
          # extra = [
          #   oil-nvim
          #   nvim-web-devicons
          # ];
        };
        themer = with pkgs.vimPlugins; (
          builtins.getAttr (categories.colorscheme or "onedark") {
            "onedark" = onedark-nvim;
            "everforest" = everforest;
          }
        );
      };

      # não carregados automaticamente na inicialização.
      # use com packadd e um autocomando na configuração para alcançar carregamento preguiçoso
      optionalPlugins = {
        # debug = with pkgs.vimPlugins; {
        #   # it is possible to add default values.
        #   # there is nothing special about the word "default"
        #   # but we have turned this subcategory into a default value
        #   # via the extraCats section at the bottom of categoryDefinitions.
        #   default = [
        #     nvim-dap
        #     nvim-dap-ui
        #     nvim-dap-virtual-text
        #   ];
        #   go = [nvim-dap-go];
        # };
        # lint = with pkgs.vimPlugins; [
        #   nvim-lint
        # ];
        # format = with pkgs.vimPlugins; [
        #   conform-nvim
        # ];
        # markdown = with pkgs.vimPlugins; [
        #   markdown-preview-nvim
        # ];
        # neonixdev = with pkgs.vimPlugins; [
        #   lazydev-nvim
        # ];
        # general = {
        #   cmp = with pkgs.vimPlugins; [
        #     # cmp stuff
        #     nvim-cmp
        #     luasnip
        #     friendly-snippets
        #     cmp_luasnip
        #     cmp-buffer
        #     cmp-path
        #     cmp-nvim-lua
        #     cmp-nvim-lsp
        #     cmp-cmdline
        #     cmp-nvim-lsp-signature-help
        #     cmp-cmdline-history
        #     lspkind-nvim
        #   ];
        treesitter = with pkgs.vimPlugins; [
          nvim-treesitter-textobjects
          nvim-treesitter.withAllGrammars
          # This is for if you only want some of the grammars
          # (nvim-treesitter.withPlugins (
          #   plugins: with plugins; [
          #     nix
          #     lua
          #   ]
          # ))
        ];
        # telescope = with pkgs.vimPlugins; [
        #   telescope-fzf-native-nvim
        #   telescope-ui-select-nvim
        #   telescope-nvim
        # ];
        # always = with pkgs.vimPlugins; [
        #   nvim-lspconfig
        #   lualine-nvim
        #   gitsigns-nvim
        #   vim-sleuth
        #   vim-fugitive
        #   vim-rhubarb
        #   nvim-surround
        # ];
        # extra = with pkgs.vimPlugins; [
        #   fidget-nvim
        #   # lualine-lsp-progress
        #   which-key-nvim
        #   comment-nvim
        #   undotree
        #   indent-blankline-nvim
        #   vim-startuptime
        #   # If it was included in your flake inputs as plugins-hlargs,
        #   # this would be how to add that plugin in your config.
        #   # pkgs.neovimPlugins.hlargs
        # ];
      };
    };

    # bibliotecas compartilhadas a serem adicionadas ao LD_LIBRARY_PATH
    # variável disponível para o tempo de execução do nvim
    # sharedLibraries = {
    #   general = with pkgs; [
    #     # libgit2
    #   ];
    # };

    # environmentVariables:
    # esta seção é para variáveis de ambiente que devem estar disponíveis
    # em TEMPO DE EXECUÇÃO para plugins. Estarão disponíveis no path dentro do terminal do neovim
    environmentVariables = {
      test = {
        CATTESTVAR = "Funcionou!";
      };
    };

    # Se você souber o que são, pode fornecer personalizados por categoria aqui.
    # Se não souber, confira este link:
    # https://github.com/NixOS/nixpkgs/blob/master/pkgs/build-support/setup-hooks/make-wrapper.sh
    extraWrapperArgs = {
      test = [
        ''--set CATTESTVAR2 "Funcionou novamente!"''
      ];
    };

    # listas das funções que você teria passado para
    # python.withPackages ou lua.withPackages

    # obter o caminho para este ambiente python
    # no seu config lua via
    # vim.g.python3_host_prog
    # ou execute a partir do terminal nvim via :!<nome-do-pacote>-python3
    extraPython3Packages = {
      test = _: [];
    };
    # preenche $LUA_PATH e $LUA_CPATH
    extraLuaPackages = {
      test = [(_: [])];
      # };
    };

    # E então construa um pacote com categorias específicas de cima aqui:
    # Todas as categorias que você deseja incluir devem ser marcadas como verdadeiras,
    # mas falsas podem ser omitidas.
    # Todo esse conjunto também é passado para o nixCats para consulta dentro do lua.

    # veja :help nixCats.flake.outputs.packageDefinitions
    packageDefinitions = {
      # Estes são os nomes dos seus pacotes
      # você pode incluir quantos quiser.
      nvim = {pkgs, ...}: {
        # eles contêm um conjunto de configurações definidas acima
        # veja :help nixCats.flake.outputs.settings
        settings = {
          wrapRc = true;
          # IMPORTANTE:
          # seu alias pode não conflitar com seus outros pacotes.
          aliases = ["vim"];
          # neovim-unwrapped = inputs.neovim-nightly-overlay.packages.${pkgs.system}.neovim;
        };
        # e um conjunto de categorias que você deseja
        # (e outras informações a passar para lua)
        categories = {
          general = true;
          lint = true;
          format = true;
          gitPlugins = true;
          customPlugins = true;
          test = true;
          themer = true;
          colorscheme = "everforest";
          example = {
            youCan = "adicionar mais do que apenas booleans";
            toThisSet = [
              "e o conteúdo deste conjunto de categorias"
              "será acessível ao seu lua com"
              "nixCats('caminho.para.valor')"
              "veja :help nixCats"
            ];
          };
        };
      };
    };
    # Nesta seção, a principal coisa que você precisará fazer é mudar o nome do pacote padrão
    # para o nome da entrada do packageDefinitions que você deseja usar como padrão.
    defaultPackageName = "nvim";
  in
    # veja :help nixCats.flake.outputs.exports
    forEachSystem (system: let
      nixCatsBuilder =
        utils.baseBuilder luaPath {
          inherit nixpkgs system dependencyOverlays extra_pkg_config;
        }
        categoryDefinitions
        packageDefinitions;
      defaultPackage = nixCatsBuilder defaultPackageName;
      # isso é só para usar funções como pkgs.mkShell
      # A usada para construir o neovim é resolvida dentro do construtor
      # e é passada para nossas categoryDefinitions e packageDefinitions
      pkgs = import nixpkgs {inherit system;};
    in {
      # essas saídas serão envoltas com ${system} por utils.eachSystem

      # isso criará um pacote a partir de cada um dos packageDefinitions definidos acima
      # e definirá o pacote padrão para o que for passado aqui.
      packages = utils.mkAllWithDefault defaultPackage;

      # escolha seu pacote para devShell
      # e adicione o que mais quiser nele.
      devShells = {
        default = pkgs.mkShell {
          name = defaultPackageName;
          packages = [defaultPackage];
          inputsFrom = [];
          shellHook = ''
          '';
        };
      };
    })
    // (let
      # também exportamos um módulo do nixos para permitir reconfiguração a partir do configuration.nix
      nixosModule = utils.mkNixosModules {
        inherit
          defaultPackageName
          dependencyOverlays
          luaPath
          categoryDefinitions
          packageDefinitions
          extra_pkg_config
          nixpkgs
          ;
      };
      # e o mesmo para o home manager
      homeModule = utils.mkHomeModules {
        inherit
          defaultPackageName
          dependencyOverlays
          luaPath
          categoryDefinitions
          packageDefinitions
          extra_pkg_config
          nixpkgs
          ;
      };
    in {
      # essas saídas NÃO serão envoltas com ${system}

      # isso criará um overlay a partir de cada um dos packageDefinitions definidos acima
      # e definirá o overlay padrão para o nome aqui.
      overlays =
        utils.makeOverlays luaPath {
          inherit nixpkgs dependencyOverlays extra_pkg_config;
        }
        categoryDefinitions
        packageDefinitions
        defaultPackageName;

      nixosModules.default = nixosModule;
      homeModules.default = homeModule;

      inherit utils nixosModule homeModule;
      inherit (utils) templates;
    });
}
