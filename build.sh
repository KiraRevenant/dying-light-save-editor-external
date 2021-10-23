#!/usr/bin/env bash

export CC=/usr/bin/gcc-10 CXX=/usr/bin/g++-10

# Build vcpkg
(cd vcpkg && ./bootstrap-vcpkg.sh -disableMetrics) || exit 1
# Install libraries with vcpkg
(cd vcpkg && ./vcpkg install Catch2 palsigslot sqlite3 zlib) || exit 1

if [[ "${OSTYPE}" == "linux-gnu" ]]; then
    (cd vcpkg && ./vcpkg install libuuid) || exit 1
fi

(cd vcpkg && ./vcpkg upgrade --no-dry-run) || exit 1

# Install Debian packages
# wxWidgets requires GTK
if [[ "${OSTYPE}" == "linux-gnu" ]]; then
    for dpkg_name in libgtk-3-dev; do
        dpkg_status=$(dpkg-query --show --showformat='${db:Status-Status}' "${dpkg_name}") || exit 1
        if [[ "${dpkg_status}" != "installed" ]]; then
            sudo apt install "${dpkg_name}" || exit 1
        fi
    done
fi

# Build wxWidgets
for config in Debug Release; do
    cmake -G Ninja -B "wxWidgets-build/${config}" -S wxWidgets \
        "-DCMAKE_BUILD_TYPE=${config}" \
        "-DCMAKE_INSTALL_PREFIX=wxWidgets-install/${config}" \
        -DwxBUILD_COMPATIBILITY=3.1 -DwxUSE_LIBJPEG=OFF -DwxUSE_LIBTIFF=OFF -DwxBUILD_DEMOS=OFF || exit 1
    cmake --build "wxWidgets-build/${config}" || exit 1
    cmake --install "wxWidgets-build/${config}" || exit 1
done
