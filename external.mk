# Pull in the .mk files for project-specific Buildroot packages added
# under package/. Sourced automatically by nerves_system_br's
# external.mk via `-include $(NERVES_DEFCONFIG_DIR)/external.mk`.
include $(sort $(wildcard $(NERVES_DEFCONFIG_DIR)/package/*/*.mk))
