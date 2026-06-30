# kball3

ZMK firmware config for kball3, a standalone trackball + 3-button device using
Seeed XIAO nRF52840 / XIAO BLE.

The planned personal repository name is `kotobo3`, following the same naming
idea as `kotobo18` for the customized `kgrid18` firmware.

## Current PCB Pin Plan

Keys are direct GPIO switches:

```text
BTN1 -> XIAO D3 -> switch -> GND
BTN2 -> XIAO D4 -> switch -> GND
BTN3 -> XIAO D5 -> switch -> GND
```

Mouse sensor FPC pin order on this PCB:

```text
FPC pin 1: GND
FPC pin 2: SCLK   -> XIAO D9
FPC pin 3: SDIO   -> XIAO D8
FPC pin 4: MOTION -> XIAO D6
FPC pin 5: CS     -> XIAO D7
FPC pin 6: 3V3
```

The first firmware scaffold builds the 3 direct keys.

PAW3222 support is planned through the author's ZMK driver:

```text
https://github.com/sekigon-gonnoc/zmk-driver-paw3222
```

The module has been added to `config/west.yml`, and `PAW3222` is enabled in the
shield Kconfig. The actual SPI overlay is intentionally left disabled until the
XIAO BLE D6/D7/D8/D9 aliases are resolved to nRF GPIO port/pin numbers for
`NRF_PSEL(...)`.
