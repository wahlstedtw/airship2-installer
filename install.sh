#!/usr/bin/env bash

set -xe

GO_VERS="1.17.1"

check_resource_mem() {
    memory="$(grep MemTotal /proc/meminfo | awk '{print $2}')"

    if [[ '$memory' < 31457280 ]]; then
        echo " Not enough Memory. Need minimum of 30GB."
        echo " You have '$(free -h | grep Mem | awk '{print $2}')'"
        exit 1
    else
        echo " Minimum amount of Memory (8GB) met. You have '$(free -h | grep Mem | awk '{print $2}')'"
    fi
}

check_resource_disk() {
    disk="$(sudo fdisk -l | grep Disk | grep sda | awk '{print $3}')"

    if [[ "$disk" < 100 ]]; then
        echo " Not enough Disk Space. Need a minimum of 100GB."
        echo " You have '$disk'"
        exit 1
    else
        echo " Minimum amount of disk (100GB) met. You have '$disk'"
    fi
}

check_resource_cpu() {
    cores_socket="$(lscpu | grep socket | awk '{print $4}')"
    num_socket="$(lscpu | grep Socket | awk '{print $2}')"
    echo "$cores_socket : Cores/socket"
    echo "$num_socket : Num of sockets"
    CPUS="$(($cores_socket * $num_socket))"
    echo "$CPUS : Total number of cpus"

    if [[ $CPUS < 8 ]]; then
        echo " Not enough CPU cores. Minimum required is 8."
        echo " You have $CPUS"
        exit 1
    else
        echo " Minimum number of cpus (8) met. You have '$CPUS'"
    fi
}

install_go() {
if [[ ! -f go"$GO_VERS".linux-amd64.tar.gz ]]; then
    curl -L -O https://golang.org/dl/go"$GO_VERS".linux-amd64.tar.gz
    sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf go"$GO_VERS".linux-amd64.tar.gz
fi
sudo bash -c 'echo "export PATH=$PATH:/usr/local/go/bin" >> /etc/profile'
export PATH=$PATH:/usr/local/go/bin

go version
}

import_test_encryption_keys() {
    echo "Configure test encryption keys."
    curl -fsSL -o /tmp/key.asc https://raw.githubusercontent.com/mozilla/sops/master/pgp/sops_functional_tests_key.asc
    export SOPS_IMPORT_PGP="$(cat /tmp/key.asc)"
    export SOPS_PGP_FP="FBC7B9E2A4F9289AC0C1D4843D16CEE4A27381B4"
}

check_resource_mem
check_resource_disk
check_resource_cpu
install_go


sudo apt-get update && sudo apt-get upgrade -y
sudo apt-get install -y git-all

cd ..

if [[ ! -d airshipctl ]]; then
    git clone https://opendev.org/airship/airshipctl.git
fi

cd airshipctl

import_test_encryption_keys

echo "======================================================================================"
echo "==  Initial VM Setup                                                                =="
echo "======================================================================================"
time ./tools/gate/00_setup.sh

sudo usermod -a -G docker $USER

echo "======================================================================================"
echo "==  Build Gate - KVM server: 'virsh list --all' should show 3 images                =="
echo "==  air-ephemeral, air-target-1, air-worker1                                        =="
echo "======================================================================================"
time ./tools/gate/10_build_gate.sh
read -p "Press any key to continue."

echo "======================================================================================"
echo "==  Generate test configs                                                                =="
echo "======================================================================================"
time ./tools/deployment/22_test_configs.sh
read -p "Press any key to continue."

echo "======================================================================================"
echo "==  Pull documents                                                                  =="
echo "======================================================================================"
time ./tools/deployment/23_pull_documents.sh
read -p "Press any key to continue."


echo "======================================================================================"
echo "==  Generate Secrets                                                                =="
echo "======================================================================================"
time ./tools/deployment/23_generate_secrets.sh
read -p "Press any key to continue."


echo "======================================================================================"
echo "==  Build Images                                                                    =="
echo "======================================================================================"
time ./tools/deployment/24_build_images.sh
read -p "Press any key to continue."


echo "======================================================================================"
echo "==  This might take a while to deploy gating, potentially hours.                    =="
echo "==  Message: '# Retrying to reach the apiserver'                                    =="
echo "======================================================================================"
time ./tools/deployment/25_deploy_gating.sh
read -p "Press any key to continue."

echo ""
echo "======================================================================================"
echo "==                                                                                  =="
echo "== Read here for next steps: https://docs.airshipit.org/airshipctl/environment.html =="
echo "==                                                                                  =="
echo "== This might take a while to 'install airshipctl', potentially hours.              =="
echo "== Run: cd ../airshipctl && ./tools/gate/10_build_gate.sh                           =="
echo "==                                                                                  =="
echo "======================================================================================"