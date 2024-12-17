# Idea

the idea is to have a utility to edit, integrate and update the grpc interfaces used by a C++ project(s).

# Introduction

this is a utility project usefull for C++ devlopers working with grpc and want to automatically build their interfaces. this project can be added as a sub package to a Cmake project or used as standalone app. this cmake project will automatically generate the source and header files plus the static/dynamic libraries from Protocol Buffers proto files.

# pre-requirements

following softwares are required:
grpc
protobuf
protobuf-compiler
cmake

## notes

CMakeLists.txt is well commented and can be adopted to your needs easily.
install_packages is a simple bash script that installs cmake, protobuf and grpc with superuser privileges(root)! (Root access is needed.) It is well commented and can be easily adapted to your needs.
tested with following tools versions:
Ubuntu 22.04
cmake 3.29
protobuf 23.4
gRPC 1.57

common.cmake file is taken from https://github.com/grpc/grpc/blob/master/examples/cpp/cmake/common.cmake and is from grpc project!

# How to use

easy !

1. make sure all pre requirements are met
2. for each inteface(applciation interface(s)) that you have, create a folder(acts as library name) in protos folder and put your proto file(s) there
3.

```bash
mkdir build  && cd build
```

4.

```bash
cmake .. (or cmake -DCMAKE_INSTALL_PREFIX= /install/path)
```

5. make (or make install)

this repo already include an "ready to go" example, without touching anything and running install_packages.sh (in a docker container, VN or directly on your system) you will get all pre-requirements, then by building the project two samples will be created. it will get you the idea how to use it in your projects :D

# using this utility as sub cmake project

if you want to add this as part of your main project follow these steps

1. add the project path to your main cmake.
2. for each application that has dependencies to any grpc interfaces generated by this tool, add the following to its CMakeLists.txt file:

```bash
    target_link_libraries("your project name indicated in your cmakelist.txt" gRPC::grpc++   (name of your protos folder)_protobuf )
    add_dependencies("your project name indicated in your cmakelist.txt" (name of your protos folder)_protobuf)
```

example:

```bash
    target_link_libraries(test gRPC::grpc++   example1_protobuf )
    add_dependencies(test example1_protobuf)
```

by this, you make sure before your application is compiled, the Grpc interface it uses will be build and compiled

# what if?

1. when using install_packages.sh if you faced:

   -- Could NOT find OpenSSL, try to set the path to OpenSSL root folder in the system variable OPENSSL_ROOT_DIR (missing: OPENSSL_CRYPTO_LIBRARY)
   CMake Error at Utilities/cmcurl/CMakeLists.txt:644 (message):
   Could not find OpenSSL. Install an OpenSSL development package or
   configure CMake with -DCMAKE_USE_OPENSSL=OFF to build without OpenSSL.

   do replace ./bootstrap with
   ./bootstrap -- -DOPENSSL_ROOT_DIR=/usr \
    -DOPENSSL_INCLUDE_DIR=/usr/include \
    -DOPENSSL_CRYPTO_LIBRARY=/usr/lib/x86_64-linux-gnu/libcrypto.so \
    -DOPENSSL_SSL_LIBRARY=/usr/lib/x86_64-linux-gnu/libssl.so

   you might need to change x86_64-linux-gnu to the architect of your system
