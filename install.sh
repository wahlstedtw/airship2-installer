#!/usr/bin/env bash

set -xe

GO_VERS="1.17.1"

if [[ ! -f go"$GO_VERS".linux-amd64.tar.gz ]]; then
    curl -L -O https://golang.org/dl/go"$GO_VERS".linux-amd64.tar.gz
    sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf go"$GO_VERS".linux-amd64.tar.gz
fi
export PATH=$PATH:/usr/local/go/bin

go version

sudo apt-get update && sudo apt-get upgrade -y
sudo apt-get install -y git-all

cd ..

if [[ ! -d airshipctl ]]; then
    git clone https://opendev.org/airship/airshipctl.git
fi


cd airshipctl

echo "Configure test encryption keys."
curl -fsSL -o /tmp/key.asc https://raw.githubusercontent.com/mozilla/sops/master/pgp/sops_functional_tests_key.asc
export SOPS_IMPORT_PGP="$(cat /tmp/key.asc)"
export SOPS_PGP_FP="FBC7B9E2A4F9289AC0C1D4843D16CEE4A27381B4"

./tools/gate/00_setup.sh

sudo usermod -a -G docker $USER

./tools/gate/10_build_gate.sh
read -p Press any key to continue the backup.

./tools/deployment/22_test_configs.sh
read -p Press any key to continue the backup.

./tools/deployment/23_pull_documents.sh
read -p Press any key to continue the backup.

./tools/deployment/23_generate_secrets.sh
read -p Press any key to continue the backup.

./tools/deployment/24_build_images.sh
read -p Press any key to continue the backup.

./tools/deployment/25_deploy_gating.sh
read -p Press any key to continue the backup.



echo ""
echo "======================================================================================"
echo "==                                                                                  =="
echo "== Read here for next steps: https://docs.airshipit.org/airshipctl/environment.html =="
echo "==                                                                                  =="
echo "== This might take a while to 'install airshipctl', potentially hours.              =="
echo "== Run: cd ../airshipctl && ./tools/gate/10_build_gate.sh                           =="
echo "==                                                                                  =="
echo "======================================================================================"