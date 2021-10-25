#!/usr/bin/env bash

script_dir=$(dirname "$(realpath "${BASH_SOURCE[0]}")")
source_dir=${script_dir}/source
build_dir=${script_dir}/build
install_dir=${script_dir}/install
vcpkg_commit=2169ab765b49cfc5cd7eddfc8ff3e579326776f8
wxwidgets_version=3.1.5

for dir in "${source_dir}" "${build_dir}" "${install_dir}"; do
    if [[ ! -d "${dir}" ]]; then
        mkdir --parents "${dir}" || exit 1
        echo "*" > "${dir}/.gitignore"
    fi
done

function build_vcpkg {
    if [[ ! -d "./vcpkg-${vcpkg_commit}" ]]; then
        curl -sSL "https://github.com/microsoft/vcpkg/archive/${vcpkg_commit}.tar.gz" | tar -xz || return 1
    fi
    cd "./vcpkg-${vcpkg_commit}" || return 1
    if [[ ! -f ./vcpkg ]]; then
        ./bootstrap-vcpkg.sh -disableMetrics || return 1
    fi
    ./vcpkg install Catch2 palsigslot sqlite3 zlib || return 1
    if [[ "${OSTYPE}" == "linux-gnu" ]]; then
        ./vcpkg install libuuid || return 1
    fi
    ./vcpkg upgrade --no-dry-run || return 1
    ./vcpkg export --x-all-installed --zip --output=vcpkg-export || return 1
    if [[ -d "${install_dir}/vcpkg" ]]; then
        rm -rf "${install_dir}/vcpkg" || return 1
    fi
    if [[ -d "${install_dir}/vcpkg-export" ]]; then
        rm -rf "${install_dir}/vcpkg-export" || return 1
    fi
    unzip -d "${install_dir}" ./vcpkg-export.zip || return 1
    mv "${install_dir}/vcpkg-export" "${install_dir}/vcpkg" || return 1
}

function build_wxwidgets {
    if [[ ! -d "./wxWidgets-${wxwidgets_version}" ]]; then
        curl -sSL "https://github.com/wxWidgets/wxWidgets/releases/download/v${wxwidgets_version}/wxWidgets-${wxwidgets_version}.tar.bz2" | tar -xj || return 1
    fi
    cd "./wxWidgets-${wxwidgets_version}" || return 1
    for config in Debug Release; do
        wxwidgets_install_prefix="${install_dir}/wxwidgets/${config,,}"
        cmake -G Ninja -B "${build_dir}/wxwidgets/${config,,}" -S . \
            "-DCMAKE_BUILD_TYPE=${config}" \
            "-DCMAKE_INSTALL_PREFIX=${wxwidgets_install_prefix}" \
            -DCMAKE_CXX_FLAGS="-DG_DISABLE_ASSERT" \
            -DwxBUILD_COMPATIBILITY=3.1 \
            -DwxBUILD_DEBUG_LEVEL=0 \
            -DwxUSE_AUI=OFF \
            -DwxUSE_CRASHREPORT=OFF \
            -DwxUSE_DEBUGREPORT=OFF \
            -DwxUSE_FS_INET=OFF \
            -DwxUSE_HTML=OFF \
            -DwxUSE_LIBJPEG=OFF \
            -DwxUSE_LIBTIFF=OFF \
            -DwxUSE_LOG=OFF \
            -DwxUSE_LOG_DIALOG=OFF \
            -DwxUSE_LOGGUI=OFF \
            -DwxUSE_LOGWINDOW=OFF \
            -DwxUSE_MEDIACTRL=OFF \
            -DwxUSE_MS_HTML_HELP=OFF \
            -DwxUSE_OPENGL=OFF \
            -DwxUSE_REGEX=OFF \
            -DwxUSE_PROPGRID=OFF \
            -DwxUSE_PROTOCOL=OFF \
            -DwxUSE_RIBBON=OFF \
            -DwxUSE_RICHTEXT=OFF \
            -DwxUSE_SOCKETS=OFF \
            -DwxUSE_SECRETSTORE=OFF \
            -DwxUSE_SOUND=OFF \
            -DwxUSE_STC=OFF \
            -DwxUSE_URL=OFF \
            -DwxUSE_WEBVIEW=OFF \
            -DwxUSE_WEBREQUEST=OFF \
            -DwxUSE_WXHTML_HELP=OFF \
            -DwxUSE_XML=OFF \
            -DwxUSE_XRC=OFF \
            || return 1
        if [[ -d "${wxwidgets_install_prefix}" ]]; then
            rm -rf "${wxwidgets_install_prefix}" || return 1
        fi
        cmake --build "${build_dir}/wxwidgets/${config,,}" --target install || return 1
        # Recreate symlinks to use relative paths instead of absolute paths
        if [[ -d "${wxwidgets_install_prefix}/bin" ]]; then
            find "${wxwidgets_install_prefix}/bin" -type l | while read f; do
                ln --force --relative --symbolic "$(readlink "${f}")" "${f}" || return 1
            done || return 1
        fi
        # Remove wxINSTALL_PREFIX definition because it hardcodes an absolute path in the build environment
        # Instead the library consumer should specify this
        # This doesn't change RPATH information embedded in binaries
        find "${wxwidgets_install_prefix}/lib/" -name "setup.h" | while read f; do
            sed -i 's/#define wxINSTALL_PREFIX .*/\/\/#define wxINSTALL_PREFIX ""/' "${f}" || return 1
        done || return 1
    done
}

function build_all {
    for fn in build_vcpkg build_wxwidgets; do
        (cd "${source_dir}" && ${fn}) || return 1
    done
}

function main {
    cd "${source_dir}" || return 1
    case "$1" in
        all)
            build_all || return 1
            ;;
        vcpkg)
            build_vcpkg || return 1
            ;;
        wxwidgets)
            build_wxwidgets || return 1
            ;;
        *)
            echo "Script invoked incorrectly."
            return 1
            ;;
    esac
}

(main $@) || exit 1
