{ pkgs, ... }:
let
  patchedSystemd = (pkgs.systemd.overrideAttrs (oldAttrs: {
    patches = oldAttrs.patches ++ [
      # Enable setting a deterministic verity seed for systemd-repart. Remove when upgrading to systemd 255.
      (pkgs.fetchpatch {
        url = "https://github.com/systemd/systemd/commit/81e04781106e3db24e9cf63c1d5fdd8215dc3f42.patch";
        hash = "sha256-KO3poIsvdeepPmXWQXNaJJCPpmBb4sVmO+ur4om9f5k=";
      })
      # Propagate SOURCE_DATE_EPOCH to mcopy. Remove when upgrading to systemd 255.
      (pkgs.fetchpatch {
        url = "https://github.com/systemd/systemd/commit/4947de275a5553399854cc748f4f13e4ae2ba069.patch";
        hash = "sha256-YIZZyc3f8pQO9fMAxiNhDdV8TtL4pXoh+hwHBzRWtfo=";
      })
      # repart: make sure rewinddir() is called before readdir() when performing rm -rf. Remove when upgrading to systemd 255.
      (pkgs.fetchpatch {
        url = "https://github.com/systemd/systemd/commit/4262a3f82a399118aa2ccfcf12c3ebc149194ca2.patch";
        hash = "sha256-A6cF2QAeYHGc0u0V1JMxIcV5shzf5x3Q6K+blZOWSn4=";
      })
    ];
  })).override {
    withRepart = true;
  };
in
pkgs.mkShell {
  nativeBuildInputs = with pkgs; [
    patchedSystemd
    squashfsTools
  ];
}
