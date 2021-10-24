## Building

```
docker build --tag dlse-external-builder .
mkdir --parent install/gcc/{10,11} install/clang/{12,13}
docker run --rm --interactive --tty --mount "type=bind,src=${PWD}/install/gcc/10,dst=/work/install" --env CC=/usr/bin/gcc-10 --env CXX=/usr/bin/g++-10 dlse-external-builder
docker run --rm --interactive --tty --mount "type=bind,src=${PWD}/install/gcc/11,dst=/work/install" --env CC=/usr/bin/gcc-11 --env CXX=/usr/bin/g++-11 dlse-external-builder
docker run --rm --interactive --tty --mount "type=bind,src=${PWD}/install/clang/12,dst=/work/install" --env CC=/usr/bin/clang-12 --env CXX=/usr/bin/clang++-12 dlse-external-builder
docker run --rm --interactive --tty --mount "type=bind,src=${PWD}/install/clang/13,dst=/work/install" --env CC=/usr/bin/clang-13 --env CXX=/usr/bin/clang++-13 dlse-external-builder
```
