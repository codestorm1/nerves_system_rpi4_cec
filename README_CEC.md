<!-- SPDX-FileCopyrightText: 2025 Bryan Green -->
<!-- SPDX-License-Identifier: Apache-2.0 -->
# Nerves System: Raspberry Pi 4 with HDMI-CEC Support

This is a **custom Nerves system** for the Raspberry Pi 4 that enables reliable
HDMI and CEC (Consumer Electronics Control) support out of the box.

It’s based on the official [`nerves_system_rpi4`](https://github.com/nerves-project/nerves_system_rpi4)
with kernel and Buildroot tweaks to make `/dev/cec0` and `cec-ctl` available at boot.

---

## 🔧 Features

- **HDMI CEC enabled** (`vc4_hdmi_cec` built-in, not as module)
- **KMS driver active** (`dtoverlay=vc4-kms-v3d`)
- **HDMI hotplug forced** (so video stays up even without EDID)
- **`v4l-utils`** included → provides the `cec-ctl` command
- **`hdmi_ignore_cec_init=1`** prevents unwanted input switching on boot
- Console output on HDMI (`tty1`)

---

## 🧰 Kernel Config Highlights

```
CONFIG_DRM_VC4=y
CONFIG_DRM_VC4_HDMI_CEC=y
CONFIG_MEDIA_CEC_SUPPORT=y
CONFIG_CEC_CORE=y
CONFIG_CEC_NOTIFIER=y
```

---

## ⚙️ Boot Configuration (`boot/config.txt`)

```
# Force HDMI output
hdmi_force_hotplug=1
hdmi_drive=2

# Enable KMS + CEC
dtoverlay=vc4-kms-v3d

# Prevent auto input switch during firmware init
hdmi_ignore_cec_init=1
```

---

## 🧩 Buildroot Additions

```
BR2_PACKAGE_V4L_UTILS=y   # provides cec-ctl
BR2_PACKAGE_TZDATA=y      # optional: time zone data
```

---

## 🚀 Using in a Nerves App

In your application’s `mix.exs`:

```
{:nerves_system_rpi4_cec,
  github: "codestorm1/nerves_system_rpi4_cec",
  tag: "v1.0.0",
  runtime: false,
  targets: :rpi4}
```

Then:

```
MIX_TARGET=rpi4 mix deps.get
MIX_TARGET=rpi4 mix firmware
mix upload nerves.local
```

After boot, test CEC:

```
ssh nerves.local
cec-ctl -d0 --cec-version-1.4 --playback --osd-name Mutebox
cec-ctl -d0 --show-topology
```

---

## 🧹 Notes

- Artifacts like `.tar.gz`, `.img`, and Buildroot outputs are ignored to keep the repo small.
- To share pre-built images, attach them to GitHub **Releases** instead of committing them.
- Buildroot caches (`buildroot/dl`, `output/`, etc.) are intentionally untracked.

---

## 🏷 Versioning

- **v1.0.0** — initial release with CEC/HDMI/KMS support

---

Maintained by **codestorm1** ·  
Based on the official Nerves Raspberry Pi 4 system.
