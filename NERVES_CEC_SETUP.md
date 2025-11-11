# Nerves RPi4 CEC Setup - Working Configuration

## Overview
Custom Nerves system for Raspberry Pi 4 with HDMI-CEC support, tested and working on v1.32.0-cec.6.

## Repository
https://github.com/codestorm1/nerves_system_rpi4_cec

## Key Configuration Files

### 1. config.txt (root directory)
Location: `/config.txt` (root of nerves_system_rpi4_cec)

```
# SPDX-FileCopyrightText: 2025 Bryan Green
# SPDX-License-Identifier: CC0-1.0

dtoverlay=vc4-kms-v3d,cec
hdmi_force_hotplug=1
disable_overscan=1
gpu_mem=192
```

**Critical points:**
- `,cec` parameter on `dtoverlay=vc4-kms-v3d` enables CEC
- This file goes in the ROOT directory, NOT in `rootfs_overlay/boot/`
- Gets copied to images/ via BR2_NERVES_ADDITIONAL_IMAGE_FILES
- Written to boot partition by fwup.conf

### 2. nerves_defconfig
Key additions:

```bash
# HDMI-CEC and utilities
BR2_PACKAGE_LIBCEC=y
BR2_PACKAGE_LIBCEC_UTILS=y
BR2_PACKAGE_LIBV4L=y
BR2_PACKAGE_LIBV4L_UTILS=y

# Audio tools
BR2_PACKAGE_ALSA_UTILS_ARECORD=y
BR2_PACKAGE_SOX=y
BR2_PACKAGE_FFTW=y

# Audio fingerprinting
BR2_PACKAGE_CHROMAPRINT=y

# Image files to include
BR2_NERVES_ADDITIONAL_IMAGE_FILES="${NERVES_DEFCONFIG_DIR}/fwup.conf ${NERVES_DEFCONFIG_DIR}/cmdline.txt ${NERVES_DEFCONFIG_DIR}/config.txt"
```

### 3. fwup.conf
Standard configuration - references config.txt:

```
file-resource config.txt {
    host-path = "${NERVES_SYSTEM}/images/config.txt"
}
```

### 4. mix.exs
Using older nerves_system_br due to compatibility:

```elixir
{:nerves_system_br, "1.31.7", runtime: false}
```

## Building the System

### Initial Setup
```bash
cd ~/projects/nerves_system_rpi4_cec
```

### Build Process
```bash
# Clean build
rm -rf _build deps
mix deps.get
mix compile

# Create distributable artifact
mix nerves.artifact
```

**Build time:** 30-60 minutes on first build

**Output:** 
- Artifact: `.nerves/artifacts/nerves_system_rpi4-portable-1.32.0-cec.X/*.tar.gz`
- Size: ~294MB

### Releasing
```bash
# Tag version
echo "1.32.0-cec.9" > VERSION
git add -A
git commit -m "v1.32.0-cec.9 release"
git tag v1.32.0-cec.9
git push origin main
git push origin v1.32.0-cec.9

# Manual release (GitHub Actions not configured)
gh release create v1.32.0-cec.9 \
  --repo codestorm1/nerves_system_rpi4_cec \
  --title "v1.32.0-cec.9 - CEC-enabled RPi4" \
  --notes "Audio support via kernel driver."

# Upload artifact
gh release upload v1.32.0-cec.9 \
  --repo codestorm1/nerves_system_rpi4_cec \
  .nerves/artifacts/nerves_system_rpi4-portable-1.32.0-cec.9/*.tar.gz

# Create and upload checksum
cd .nerves/artifacts/nerves_system_rpi4-portable-1.32.0-cec.9/
sha256sum *.tar.gz > *.tar.gz.sha256
gh release upload v1.32.0-cec.9 \
  --repo codestorm1/nerves_system_rpi4_cec \
  *.sha256
```

## Using in a Nerves Project

### In your project's mix.exs
```elixir
{:nerves_system_rpi4_cec, 
  github: "codestorm1/nerves_system_rpi4_cec",
  tag: "v1.32.0-cec.9",
  runtime: false,
  targets: :rpi4}
```

### Build your project
```bash
cd ~/projects/your_project
export MIX_TARGET=rpi4
mix deps.get
mix firmware
mix upload nerves.local  # or mix burn
```

## Testing CEC

### From IEx Shell
```elixir
# Verify CEC devices exist
File.exists?("/dev/cec0")
# => true

File.ls!("/dev") |> Enum.filter(&String.starts_with?(&1, "cec"))
# => ["cec0", "cec1"]

# Check cec-ctl is available
File.exists?("/usr/bin/cec-ctl")
# => true

# Initialize CEC with device name
System.cmd("cec-ctl", ["-d0", "--cec-version-1.4", "--playback", "--osd-name", "MyDevice"])

# Show CEC topology (all devices on bus)
System.cmd("cec-ctl", ["-d0", "--show-topology"])
```

### Example Output
```
System Information for device 0 (TV):
    CEC Version    : 1.4
    Physical Addr  : 0.0.0.0
    Device Type    : TV
    Vendor ID      : 0x00e091 (LG)
    Power Status   : On

System Information for device 5 (Audio System):
    CEC Version    : 1.4
    Physical Addr  : 2.0.0.0
    Device Type    : Audio System
    Vendor ID      : 0x00a0de (Yamaha)
    OSD Name       : 'RX-V685'
    Power Status   : On

Topology:
    0.0.0.0: TV
        2.0.0.0: Audio System
            2.2.0.0: Playback Device 2
    3.0.0.0: Playback Device 1 (Your Device)
```

## Common CEC Commands

### Power Control
```elixir
# Turn TV on
System.cmd("cec-ctl", ["-d0", "-t0", "--image-view-on"])

# Turn TV off (standby)
System.cmd("cec-ctl", ["-d0", "-t0", "--standby"])

# Turn receiver on
System.cmd("cec-ctl", ["-d0", "-t5", "--image-view-on"])

# Turn receiver off
System.cmd("cec-ctl", ["-d0", "-t5", "--standby"])
```

### Audio Control
```elixir
# Mute receiver (address 5)
System.cmd("cec-ctl", ["-d0", "-t5", "--user-control-pressed", "ui-cmd=mute"])

# Mute TV (address 0)
System.cmd("cec-ctl", ["-d0", "-t0", "--user-control-pressed", "ui-cmd=mute"])

# Volume up
System.cmd("cec-ctl", ["-d0", "-t5", "--user-control-pressed", "ui-cmd=volume-up"])

# Volume down
System.cmd("cec-ctl", ["-d0", "-t5", "--user-control-pressed", "ui-cmd=volume-down"])
```

### Device Information
```elixir
# Get physical address
System.cmd("cec-ctl", ["-d0", "--phys-addr-from-edid-poll", "hdmi0"])

# Show all capabilities
System.cmd("cec-ctl", ["-d0"])
```

## Troubleshooting

### Issue: `/dev/cec0` doesn't exist
**Solution:** Check that `dtoverlay=vc4-kms-v3d,cec` is in config.txt (note the `,cec` parameter)

### Issue: cec-ctl command not found
**Solution:** Verify `BR2_PACKAGE_LIBV4L_UTILS=y` is in nerves_defconfig

### Issue: Build fails with config.txt not found
**Solution:** Ensure config.txt is in ROOT directory, not in `rootfs_overlay/boot/`

### Issue: Build fails during glibc/localedef
**Solution:** Clean build artifacts and retry:
```bash
rm -rf _build deps .nerves/artifacts
mix deps.get
mix compile
```

### Issue: CEC device exists but commands fail
**Solution:** May need `hdmi_ignore_cec_init=1` in config.txt if GPU firmware is blocking access

## Architecture Notes

### CEC Device Tree
- Kernel driver: `vc4_hdmi_cec`
- Device nodes: `/dev/cec0` (HDMI0), `/dev/cec1` (HDMI1)
- Driver version: 6.6.74

### CEC Utilities Included
- `cec-ctl`: Control utility from v4l-utils (kernel CEC interface)
- `libcec`: Library support
- Physical address detection from EDID

### Boot Process
1. GPU firmware reads `config.txt` from boot FAT partition
2. Applies `dtoverlay=vc4-kms-v3d,cec` to enable CEC in kernel
3. Kernel loads `vc4_hdmi_cec` driver
4. Creates `/dev/cec0` and `/dev/cec1` device nodes
5. Applications can use `cec-ctl` to send CEC commands

## Lessons Learned

### What Didn't Work
1. **Using rootfs_overlay/boot/config.txt** - Boot partition is separate FAT, not part of rootfs
2. **Downgrading nerves_system_br** - Probably unnecessary, but 1.31.7 works
3. **Using dtparam=cec=off** - This disables CEC entirely

### What Works
1. **config.txt in root directory** - Gets copied to images/ and written to boot partition
2. **dtoverlay=vc4-kms-v3d,cec** - Enables kernel CEC driver
3. **BR2_PACKAGE_LIBV4L_UTILS=y** - Provides cec-ctl command

## References
- Official nerves_system_rpi4: https://github.com/nerves-project/nerves_system_rpi4
- Raspberry Pi config.txt docs: https://www.raspberrypi.com/documentation/computers/config_txt.html
- CEC-CTL documentation: https://www.mankier.com/1/cec-ctl
- V4L2 CEC API: https://www.kernel.org/doc/html/latest/userspace-api/media/cec/cec-api.html

## Version History
- **v1.32.0-cec.6** - Working release, config.txt in root directory

## Next Steps for Integration
1. Create Elixir module to wrap CEC commands
2. Implement device discovery on boot
3. Handle CEC errors gracefully
4. Add configuration for device-specific addresses
5. Monitor CEC events for remote control input
