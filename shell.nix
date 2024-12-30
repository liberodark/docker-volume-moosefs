{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    go
    git
    gcc
    docker
    moosefs
  ];

  shellHook = ''
    echo "MooseFS Docker Volume Plugin development environment"
    echo "Go version: $(go version)"
    echo "Docker version: $(docker --version)"
  '';
}
