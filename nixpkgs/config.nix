{
  allowBroken = true;
  allowUnfree = true;
  zathura.useMupdf = true;

  packageOverrides = super: let pkgs = super.pkgs; in
  rec {
    haskellEnv = pkgs.buildEnv {
      name = "haskellEnv";
      paths = with pkgs.haskellPackages; [
        (ghcWithHoogle myHaskellPackages)

        cabal2nix
        hindent
        hlint
        #ghc-mod
        #hdevtools
        ghc-core
        structured-haskell-mode
        hasktags
        pointfree
        cabal-install
        alex happy
      ];
    };

    myHaskellPackages = hp: with hp; [
      # fixplate
      # orgmode-parse
      Boolean
      # CC-delcont
      HTTP
      HUnit
      MissingH
      QuickCheck
      aeson
      # arithmoi
      async
      attoparsec
      bifunctors
      blaze-builder
      blaze-builder-conduit
      blaze-builder-enumerator
      blaze-html
      blaze-markup
      blaze-textual
      cased
      cereal
      comonad
      comonad-transformers
      # compdata
      dlist
      dlist-instances
      doctest
      # errors
      exceptions
      fingertree
      foldl
      folds
      free
      hamlet
      hashable
      hspec
      hspec-expectations
      html
      http-client
      http-date
      http-types
      io-memoize
      language-c
      language-javascript
      lens
      lens-action
      lens-aeson
      lens-datetime
      lens-family
      lens-family-core
      lifted-async
      lifted-base
      linear
      # linearscan
      # linearscan-hoopl
      list-extras
      list-t
      logict
      # machines
      mime-mail
      mime-types
      mmorph
      monad-control
      monad-coroutine
      monad-loops
      monad-par
      monad-par-extras
      monad-stm
      monadloc
      monoid-extras
      network
      newtype
      numbers
      optparse-applicative
      # pandoc
      parsec
      parsers
      pipes
      pipes-attoparsec
      pipes-binary
      pipes-bytestring
      pipes-concurrency
      pipes-csv
      pipes-mongodb
      pipes-extras
      pipes-group
      pipes-http
      pipes-network
      pipes-parse
      pipes-safe
      pipes-shell
      pipes-text
      posix-paths
      #postgresql-simple
      pretty-show
      profunctors
      random
      # recursion-schemes
      reducers
      reflection
      regex-applicative
      regex-base
      regex-compat
      regex-posix
      regular
      resourcet
      retry
      rex
      SafeSemaphore
      safe
      sbv
      scotty
      semigroupoids
      semigroups
      shake
      shakespeare
      shelly
      simple-reflect
      # singletons
      speculation
      split
      spoon
      stm
      stm-chans
      stm-stats
      streaming
      streaming-bytestring
      strict
      stringsearch
      strptime
      syb
      system-fileio
      system-filepath
      tagged
      tar
      tardis
      tasty
      tasty-hspec
      tasty-hunit
      tasty-quickcheck
      tasty-smallcheck
      temporary
      text
      text-format
      # these
      # thyme
      time
      # time-recurrence
      # timeparsers
      transformers
      transformers-base
      turtle
      uniplate
      # units
      unix-compat
      unordered-containers
      uuid
      vector
      void
      wai
      warp
      xhtml
      yaml
      zippers
      zlib
    ];

    # haskellPackages = super.haskellPackages.override {
    #   overrides = self: super: {
    #     "ghc-mod" = super."ghc-mod".overrideDerivation (attrs: {
    #       src = pkgs.fetchFromGitHub {
    #         owner = "kazu-yamamoto";
    #         repo = "ghc-mod";
    #         rev = "2c90e7a700d4c0ee4905647f0644b842813dac2b";
    #         sha256 = "1223xq80k49862s8m1908iiz9k0kph2vqzk3vf0980hkbz096rjy";
    #       };
    #       libraryHaskellDepends = [ super.pipes super."cabal-helper" super.cereal ];
    #       jailbreak = true;
    #       #nativeBuildInputs = [ super."cabal-helper" super.cereal ] ++ attrs.nativeBuildInputs;
    #       postInstall = "";
    #     });
    #   };
    # };

#   haskellPackages = super.haskellPackages.override {
#     overrides = self: super: {
#       hierarchy = self.callPackage ~/dev/haskell/hierarchy {};
#     };
#   };

#   haskell = super.haskell // {
#     packages = super.haskell.packages // {
#       ghc784 = super.haskell.packages.ghc784.override {
#         overrides = self: super: {
#           hierarchy = self.callPackage ~/dev/haskell/hierarchy {};
#         };
#       };
#     };
#   };
  };
}
