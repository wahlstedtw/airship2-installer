#!/usr/bin/env bash

set -xe

GO_VERS="1.17.1"

if [[! -f go"$GO_VERS".linux-amd64.tar.gz ]]; then
    curl -L -O https://golang.org/dl/go"$GO_VERS".linux-amd64.tar.gz
    sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf go"$GO_VERS".linux-amd64.tar.gz
fi
export PATH=$PATH:/usr/local/go/bin

go version

sudo apt-get update && sudo apt-get upgrade -y
sudo apt-get install -y git-all

cd ..

if [[! -d airshipctl ]]; then
    git clone https://opendev.org/airship/airshipctl.git
fi

cd airshipctl

./tools/gate/00_setup.sh

echo ""
echo "====================================================================================="
echo "==                                                                                 =="
echo "== Read here for next steps: https://docs.airshipit.org/airshipctl/developers.html =="
echo "==                                                                                 =="
echo "====================================================================================="