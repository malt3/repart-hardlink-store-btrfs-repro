{ pkgs, ... }:
pkgs.mkShell {
  nativeBuildInputs = with pkgs; [
    systemd
    squashfsTools
  ];
}
