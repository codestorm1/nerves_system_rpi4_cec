################################################################################
#
# whisper-model-base-en-q5-1
#
################################################################################

# Pinned to a specific HF repo commit (not "main") so the download stays
# reproducible even if the model repo is updated later.
WHISPER_MODEL_BASE_EN_Q5_1_VERSION = 5359861c739e955e79d9a303bcbc70fb988958b1
WHISPER_MODEL_BASE_EN_Q5_1_SITE = https://huggingface.co/ggerganov/whisper.cpp/resolve/$(WHISPER_MODEL_BASE_EN_Q5_1_VERSION)
WHISPER_MODEL_BASE_EN_Q5_1_SITE_METHOD = wget
WHISPER_MODEL_BASE_EN_Q5_1_SOURCE = ggml-base.en-q5_1.bin
WHISPER_MODEL_BASE_EN_Q5_1_LICENSE = MIT

# The model is a single binary blob, not an archive - skip tar extraction
# and just stage it as-is.
define WHISPER_MODEL_BASE_EN_Q5_1_EXTRACT_CMDS
	mkdir -p $(@D)
	cp $(WHISPER_MODEL_BASE_EN_Q5_1_DL_DIR)/$(WHISPER_MODEL_BASE_EN_Q5_1_SOURCE) $(@D)/ggml-base.en-q5_1.bin
endef

define WHISPER_MODEL_BASE_EN_Q5_1_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0644 $(@D)/ggml-base.en-q5_1.bin \
		$(TARGET_DIR)/usr/share/whisper-models/ggml-base.en-q5_1.bin
endef

$(eval $(generic-package))
