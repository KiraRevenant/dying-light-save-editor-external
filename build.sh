export CC=/usr/bin/gcc-10 CXX=/usr/bin/g++-10

# Build vcpkg
(cd vcpkg && ./bootstrap-vcpkg.sh -disableMetrics) || exit 1
# Install libraries with vcpkg
(cd vcpkg && ./vcpkg install Catch2 docopt libuuid nlohmann-json palsigslot sqlite3 zlib && ./vcpkg upgrade --no-dry-run) || exit 1

# Install Debian packages
# wxWidgets requires GTK
for dpkg_name in libgtk-3-dev; do
    dpkg_status=$(dpkg-query --show --showformat='${db:Status-Status}' "${dpkg_name}") || exit 1
    if [[ "${dpkg_status}" != "installed" ]]; then
        sudo apt install "${dpkg_name}" || exit 1
    fi
done

# Build wxWidgets
cmake -G Ninja -B "wxWidgets-build" -S wxWidgets "-DCMAKE_INSTALL_PREFIX=wxWidgets-install" \
    -DwxBUILD_COMPATIBILITY=3.1 -DwxUSE_LIBJPEG=OFF -DwxUSE_LIBTIFF=OFF -DwxBUILD_DEMOS=OFF || exit 1
cmake --build "wxWidgets-build" || exit 1
cmake --install "wxWidgets-build" || exit 1
