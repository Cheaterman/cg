# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

PYTHON_COMPAT=( python{3_5,3_6,3_7} )

inherit cmake-utils python-single-r1 xdg-utils git-r3

GIT_REPO_OBS="https://github.com/obsproject/obs-studio.git"
GIT_REPO_IO="https://github.com/univrsal/input-overlay.git"
EGIT_SUBMODULES=(ccl)

DESCRIPTION="Software for Recording and Streaming Live Video Content"
HOMEPAGE="https://obsproject.com"

LICENSE="GPL-2"
SLOT="0"
IUSE="+alsa fdk imagemagick jack luajit nvenc pulseaudio python speex truetype v4l +input-overlay"
REQUIRED_USE="python? ( ${PYTHON_REQUIRED_USE} )"

BDEPEND="
	luajit? ( dev-lang/swig )
	python? ( dev-lang/swig )
"
DEPEND="
	>=dev-libs/jansson-2.5
	dev-qt/qtcore:5
	dev-qt/qtdeclarative:5
	dev-qt/qtgui:5
	dev-qt/qtmultimedia:5
	dev-qt/qtnetwork:5
	dev-qt/qtquickcontrols:5
	dev-qt/qtsql:5
	dev-qt/qtsvg:5
	dev-qt/qttest:5
	dev-qt/qtwidgets:5
	dev-qt/qtx11extras:5
	media-video/ffmpeg:=[x264]
	net-misc/curl
	x11-libs/libXcomposite
	x11-libs/libXinerama
	x11-libs/libXrandr
	alsa? ( media-libs/alsa-lib )
	fdk? ( media-libs/fdk-aac:= )
	imagemagick? ( media-gfx/imagemagick:= )
	jack? ( virtual/jack )
	luajit? ( dev-lang/luajit:2 )
	nvenc? (
		|| (
			<media-video/ffmpeg-4[nvenc]
			>=media-video/ffmpeg-4[video_cards_nvidia]
		)
	)
	pulseaudio? ( media-sound/pulseaudio )
	python? ( ${PYTHON_DEPS} )
	speex? ( media-libs/speexdsp )
	truetype? (
		media-libs/fontconfig
		media-libs/freetype
	)
	v4l? ( media-libs/libv4l )
	input-overlay? ( media-libs/sdl2-ttf )
	input-overlay? ( media-libs/sdl2-image )
	input-overlay? ( media-libs/vxl )
	input-overlay? ( media-libs/libuiohook )
"
RDEPEND="${DEPEND}"
CMAKE_BUILD_TYPE=Release
CMAKE_REMOVE_MODULES_LIST=( FindFreetype )
S="${WORKDIR}/${PN}"

src_unpack() {
	git-r3_fetch ${GIT_REPO_OBS} refs/heads/master
	git-r3_checkout ${GIT_REPO_OBS} "${S}"
    if use input-overlay ; then
        git-r3_fetch ${GIT_REPO_IO} refs/heads/master
        git-r3_checkout ${GIT_REPO_IO} "${S}/plugins/input-overlay/"
        sed -i '/add_subdirectory(image-source)/a add_subdirectory(input-overlay)' ${S}/plugins/CMakeLists.txt || die
    fi
}

pkg_setup() {
	use python && python-single-r1_pkg_setup
}

src_configure() {
	local libdir=$(get_libdir)
	local mycmakeargs=(
		-DDISABLE_ALSA=$(usex !alsa)
		-DDISABLE_FREETYPE=$(usex !truetype)
		-DDISABLE_JACK=$(usex !jack)
		-DDISABLE_LIBFDK=$(usex !fdk)
		-DDISABLE_PULSEAUDIO=$(usex !pulseaudio)
		-DDISABLE_SPEEXDSP=$(usex !speex)
		-DDISABLE_V4L2=$(usex !v4l)
		-DLIBOBS_PREFER_IMAGEMAGICK=$(usex imagemagick)
		-DOBS_MULTIARCH_SUFFIX=${libdir#lib}
		-DUNIX_STRUCTURE=1
	)

	if use luajit || use python; then
		mycmakeargs+=(
			-DDISABLE_LUA=$(usex !luajit)
			-DDISABLE_PYTHON=$(usex !python)
			-DENABLE_SCRIPTING=yes
		)
	else
		mycmakeargs+=( -DENABLE_SCRIPTING=no )
	fi

	cmake-utils_src_configure
}

pkg_postinst() {
	xdg_icon_cache_update

	if ! use alsa && ! use pulseaudio; then
		elog
		elog "For the audio capture features to be available,"
		elog "either the 'alsa' or the 'pulseaudio' USE-flag needs to"
		elog "be enabled."
		elog
	fi

	if ! has_version "sys-apps/dbus"; then
		elog
		elog "The 'sys-apps/dbus' package is not installed, but"
		elog "could be used for disabling hibernating, screensaving,"
		elog "and sleeping.  Where it is not installed,"
		elog "'xdg-screensaver reset' is used instead"
		elog "(if 'x11-misc/xdg-utils' is installed)."
		elog
	fi
}

pkg_postrm() {
	xdg_icon_cache_update
}
