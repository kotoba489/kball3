##　kball3ファームウェア構築

. 概要
本メモは、自作トラックボールキーボード「**kball3**」（最新基板 `kball3.kicad_pcb` 準拠）における ZMK ファームウェアの構築仕様、ピン割り当て、カスタムレイヤー構成（コンボ機能・Bluetooth切替含む）、Bluetooth 接続安定化対策、および将来の ZMK バージョンアップ手順についてまとめた保存用記録です。

- **GitHub リポジトリ**: `https://github.com/kotoba489/kball3`
- **使用 MCU**: Seeed Studio XIAO nRF52840 (`seeeduino_xiao_ble`)
- **使用 センサー**: PMW3610 ブレイクアウト基板（PMW3610 + レンズ付き, JP1 ジャンパ 1-2 ショート VIO=VIN）
- **キー構成**: 3 ボタン（縦並び配置） + 光学式トラックボール

---

## 2. ハードウェア配線およびレイヤーキーマップ仕様

`kball3.kicad_pcb` のパターンレイアウトに基づき、MCU（XIAO nRF52840）への全ピン割り当て（3個のスイッチボタンおよび PMW3610 センサー）と、多層レイヤー構成を以下のように定義しています。

### 2.1 スイッチボタンのピン割当 & レイヤー機能表

| ボタン位置       | XIAO ピン名   | MCU 内部ピン | 信号種別        | Layer 0 (デフォルト)       | Layer 1 (矢印キー)        | Layer 2 (コンボ 1+2)              | Layer 3 (コンボ 2+3)              |
| :---------- | :--------- | :------- | :---------- | :-------------------- | :-------------------- | :----------------------------- | :----------------------------- |
| **1番目 (上)** | Pad 2 / D1 | `P0.03`  | Direct GPIO | 右クリック (`&mkp RCLK`)   | 右矢印 (`&kp RIGHT`)     | BT情報全消去 (`&bt BT_CLR_ALL`)     | BTプロファイル 1 選択 (`&bt BT_SEL 1`) |
| **2番目 (中)** | Pad 3 / D2 | `P0.28`  | Direct GPIO | 左クリック (`&mkp LCLK`)   | 左矢印 (`&kp LEFT`)      | BTプロファイル 0 選択 (`&bt BT_SEL 0`) | BTプロファイル 2選択 (`&bt BT_SEL 3`)  |
| **3番目 (下)** | Pad 4 / D3 | `P0.29`  | Direct GPIO | Layer 1 へ移行 (`&to 1`) | Layer 0 へ復帰 (`&to 0`) | Layer 0 へ復帰 (`&to 0`)          | Layer 0 へ復帰 (`&to 0`)          |

#### コンボ（同時押し）操作仕様
- **L2 コンボ** (ボタン 1 + ボタン 2 同時押し) ➔ **Layer 2 へ移行** (`&to 2`：Bluetooth プロファイル 0 選択 / ペアリング全消去)
- **L3 コンボ** (ボタン 2 + ボタン 3 同時押し) ➔ **Layer 3 へ移行** (`&to 3`：Bluetooth プロファイル 1 & 3 選択)

---

### 2.2 PMW3610 トラックボールセンサーのピン割り当て表

| センサー信号 | XIAO ピン名 | MCU 内部ピン | 信号種別 | 役割 / 備考 |
| :--- | :--- | :--- | :--- | :--- |
| **SCLK** | Pad 6 / D5 | `P0.05` | SPI Clock | PMW3610 クロック信号 (`spi0_default`) |
| **SDIO** | Pad 5 / D4 | `P0.04` | SPI MOSI / MISO | PMW3610 データ信号（3線式双方向通信） |
| **nCS** | Pad 8 / D7 | `P1.12` | GPIO (Active Low) | PMW3610 チップセレクト (`cs-gpios`) |
| **MOTION** | Pad 11 / D10 | `P1.15` | GPIO (IRQ) | PMW3610 モーション検出割り込み (`irq-gpios`) |
| **VCC** | Pad 12 | `3V3` | Power Supply | 3.3V 電源供給 (JP1 1-2 ショート VIO=VIN) |
| **GND** | Pad 13 | `GND` | Ground | グランド |

---

## 3. ディレクトリ構成と主要ファイル

Keymap Editor 連携および ZMK 公式推奨構成（User Config Format）に完全対応した構成です。

```
kball3/
├── .github/
│   └── workflows/
│       └── build.yml                 # ZMK v0.3.0 対応ビルドワークフロー
├── config/
│   ├── west.yml                      # ZMK v0.3.0 & badjeff センサードライバ定義 (zmk-0.3)
│   ├── kball3.json                   # Keymap Editor 用縦並びレイアウト定義
│   ├── kball3.keymap                 # ルート層キーマップ（レイヤー0~3 & コンボ定義）
│   └── boards/
│       └── shields/
│           └── kball3/
│               ├── Kconfig.defconfig # キーボード識別名定義 (kball3)
│               ├── Kconfig.shield    # シールド有効化フラグ
│               ├── kball3.conf       # BLE接続安定化・指向制御設定
│               ├── kball3.keymap     # シールド用キーマップ（ルートと同期）
│               ├── kball3.overlay    # Devicetree (SPI & Direct Kscan)
│               ├── kball3.json       # シールド用レイアウト定義
│               └── kball3.zmk.yml    # ZMK メタデータ
├── build.yaml                        # kball3.uf2 + settings_reset.uf2 並列ビルド設定
├── LICENSE                           # MIT License
```

---

## 4. Bluetooth 再接続安定化設定 (`kball3.conf`)

Mac や Android スマホで「電源スイッチを OFF から ON に戻した際に自動接続されず、ペアリング解除操作が必要になる現象」を回避するための最適化設定です。

```properties
# ---------------------------------------------------------
# 1. トラックボール・ポインティング設定 (ZMK v0.3.0 対応)
# ---------------------------------------------------------
CONFIG_SPI=y
CONFIG_INPUT=y
CONFIG_ZMK_POINTING=y
CONFIG_PMW3610=y

# ---------------------------------------------------------
# 2. Bluetooth 接続安定化・電波強度設定（macOS / Mobile 対応）
# ---------------------------------------------------------
# 送信電波強度の最大化 (+8dBm)
CONFIG_BT_CTLR_TX_PWR_PLUS_8=y

# 実験的 BLE 接続改善（高速自動再接続アルゴリズム）
CONFIG_ZMK_BLE_EXPERIMENTAL_CONN=y

# macOS に最適化した BLE 接続インターバル設定 (7.5ms ~ 15ms)
CONFIG_BT_PERIPHERAL_PREF_MIN_INT=6
CONFIG_BT_PERIPHERAL_PREF_MAX_INT=12
CONFIG_BT_PERIPHERAL_PREF_LATENCY=0
CONFIG_BT_PERIPHERAL_PREF_TIMEOUT=400

# ---------------------------------------------------------
# 3. 電源管理（スリープ設定）
# ---------------------------------------------------------
# 深いスリープ（Deep Sleep）からの復帰時のBLE不整合を回避するため無効化
# （使用しない時は物理電源スイッチでOFFにする運用）
CONFIG_ZMK_SLEEP=n
```

---

## 5. ZMK のバージョンアップと将来のメンテナンスについて

### 現状のバージョン整合性
- **ZMK 本体**: **`v0.3.0`** (`revision: v0.3.0`)
- **センサードライバ**: **`badjeff/zmk-pmw3610-driver`** の **`zmk-0.3` ブランチ** (`revision: zmk-0.3`)

センサードライバ作者（badjeff 氏）によって ZMK `v0.3.0` 専用の修正ブランチ（`zmk-0.3`）が用意されており、両者の規格が100%合致した状態で稼働しています。
### バージョンアップについては以下を参照しました

https://github.com/snize/zmk-keyboard-suzuri

テンプレートも公開されています
https://github.com/snize/zmk-suzuri-config-template

### 将来 ZMK をバージョンアップする際の手順（例: `v0.4.0` や最新安定版へ移行時）
将来、ZMK 公式およびドライバが新しいバージョンへ移行した場合は、以下の2箇所のファイルを更新して GitHub へプッシュします。

1. **`config/west.yml` の変更**:
   ```yaml
   projects:
     - name: zmk
       remote: zmkfirmware
       revision: v0.4.0  # ← 新バージョンに変更
       import: app/west.yml
     - name: zmk-pmw3610-driver
       remote: badjeff
       revision: zmk-0.4 # ← 対応するドライバブランチに変更
   ```
2. **`.github/workflows/build.yml` の変更**:
   ```yaml
   jobs:
     build:
       uses: zmkfirmware/zmk/.github/workflows/build-user-config.yml@v0.4.0  # ← リビジョンを合わせる
   ```

---
