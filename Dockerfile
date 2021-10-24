FROM ubuntu:21.10
# Requirements:
#   wxWidgets: libgtk-3-dev
#   vcpkg: curl zip unzip tar
RUN apt-get update && apt-get upgrade -y \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y \
        clang-12 \
        clang-13 \
        cmake \
        curl \
        gcc-10 g++-10 \
        gcc-11 g++-11 \
        git \
        libgtk-3-dev \
        ninja-build \
        tar \
        unzip \
        zip \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /work
COPY build.sh ./
CMD ./build.sh all
