################################################################################
#
# whispercpp
#
################################################################################

WHISPERCPP_VERSION = 1.9.2
WHISPERCPP_SITE = $(call github,ggml-org,whisper.cpp,v$(WHISPERCPP_VERSION))
WHISPERCPP_LICENSE = MIT
WHISPERCPP_LICENSE_FILES = LICENSE

# Build only the pieces Mutebox needs: libwhisper/libggml shared libs and
# the whisper-cli example binary. Cross-compiling means GGML_NATIVE is
# already forced off by ggml's own CMakeLists, but we pass it explicitly
# for reproducibility and pin the CPU arch to the RPi4's Cortex-A72
# (armv8-a, no dotprod/i8mm) instead of letting ggml probe the build host.
WHISPERCPP_CONF_OPTS = \
	-DBUILD_SHARED_LIBS=ON \
	-DGGML_NATIVE=OFF \
	-DGGML_CPU_ARM_ARCH=armv8-a \
	-DGGML_OPENMP=OFF \
	-DWHISPER_BUILD_EXAMPLES=ON \
	-DWHISPER_BUILD_TESTS=OFF \
	-DWHISPER_SDL2=OFF \
	-DWHISPER_CURL=OFF

# Only ship the runtime bits Mutebox actually calls (whisper-cli) plus the
# shared libs it needs. Skip headers/cmake/pkgconfig dev files and the
# unused parakeet/whisper-server/whisper-bench/quantize binaries to keep
# the rootfs lean.
define WHISPERCPP_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/bin/whisper-cli $(TARGET_DIR)/usr/bin/whisper-cli
	mkdir -p $(TARGET_DIR)/usr/lib
	cp -dpf $(@D)/bin/libggml*.so* $(TARGET_DIR)/usr/lib/
	cp -dpf $(@D)/bin/libwhisper.so* $(TARGET_DIR)/usr/lib/
endef

$(eval $(cmake-package))
