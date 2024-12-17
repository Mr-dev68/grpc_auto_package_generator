#!/bin/bash
set -e
echo " make sure user has W/R  access in current directory"
echo "installing cmake 3.29 and adding the path to .bashrc"
sudo apt update
sudo apt install build-essential 
sudo apt install libssl-dev
export OPENSSL_ROOT_DIR=/usr/include/openssl
wget https://cmake.org/files/v3.29/cmake-3.29.2.tar.gz
tar -xzvf cmake-3.29.2.tar.gz
cd cmake-3.29.2
./bootstrap 
make -j$(nproc)
sudo make install
which cmake
/usr/local/bin/cmake
export PATH=/usr/local/bin/cmake:$PATH
source ~/.bashrc
cmake --version
rm -rf cmake-3.29.2.tar.gz && rm -rf cmake-3.29.2
echo "Installing Protocol Buffers..."
mkdir packages && cd packages
PROTOBUF_VERSION="23.4" # check with the protobuf git repo if newer version is available and you want to switch
git clone --branch v$PROTOBUF_VERSION https://github.com/protocolbuffers/protobuf.git && cd protobuf
git submodule update --init --recursive
cmake .
cmake --build . --parallel $(nproc)
sudo cmake --install . 
cd ..
echo "Installing gRPC..."
GRPC_VERSION="v1.57.0"   # check with the https://github.com/grpc/grpc.git repo if newer version is available and you want to switch
git clone --branch $GRPC_VERSION https://github.com/grpc/grpc.git
cd grpc
git submodule update --init --recursive
mkdir -p cmake/build
cd cmake/build
cmake ../.. -DgRPC_INSTALL=ON -DgRPC_BUILD_TESTS=OFF -DCMAKE_INSTALL_PREFIX=/usr/local
make -j$(nproc)
sudo make install
sudo ldconfig  
cd ../../..
