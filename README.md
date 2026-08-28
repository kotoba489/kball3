# kball3

自作トラックボールキーボード「**kball3**」（最新基板 `kball3.kicad_pcb` 準拠）における ZMK ファームウェアの構築仕様、ピン割り当て、カスタムレイヤー構成（コンボ機能・Bluetooth切替含む）、Bluetooth 接続安定化対策、および3Dプリントパーツ仕様（トラックボール受け皿等）の記録です。

- **GitHub リポジトリ**: `https://github.com/kotoba489/kball3`
- **使用 MCU**: Seeed Studio XIAO nRF52840 (`seeeduino_xiao_ble`)
- **使用 センサー**: PMW3610 ブレイクアウト基板（PMW3610 + レンズ付き, JP1 ジャンパ 1-2 ショート VIO=VIN）
- **キー構成**: 3 ボタン（縦並び配置） + 光学式トラックボール（25 mm 球）
- **トラックボール受け皿（最終採用）**: `trackball_25mm_receiver_v13.stl` (`3D/trackball_25mm_receiver_v13.stl`)

---

## 2. ハードウェア配線およびレイヤーキーマップ仕様

`kball3.kicad_pcb` のパターンレイアウトに基づき、MCU（XIAO nRF52840）への全ピン割り当て（3個のスイッチボタンおよび PMW3610 センサー）と、多層レイヤー構成を以下のように定義しています。

### 2.1 スイッチボタンのピン割当 & レイヤー機能表

| ボタン位置       | XIAO ピン名   | MCU 内部ピン | 信号種別        | Layer 0 (デフォルト)       | Layer 1 (矢印キー)        | Layer 2 (コンボ 1+2)              | Layer 3 (コンボ 2+3)              | Layer 4 (コンボ 1+3) |
| :---------- | :--------- | :------- | :---------- | :-------------------- | :-------------------- | :----------------------------- | :----------------------------- | :----------------- |
| **1番目 (上)** | Pad 2 / D1 | `P0.03`  | Direct GPIO | 右クリック (`&mkp RCLK`)   | 右矢印 (`&kp RIGHT`)     | BT情報全消去 (`&bt BT_CLR_ALL`)     | BTプロファイル 1 選択 (`&bt BT_SEL 1`) | ブートローダー起動 (`&bootloader`) |
| **2番目 (中)** | Pad 3 / D2 | `P0.28`  | Direct GPIO | 左クリック (`&mkp LCLK`)   | 左矢印 (`&kp LEFT`)      | BTプロファイル 0 選択 (`&bt BT_SEL 0`) | BTプロファイル 2 選択 (`&bt BT_SEL 2`) | 選択中プロファイルのペアリング解除 (`&bt BT_CLR`) |
| **3番目 (下)** | Pad 4 / D3 | `P0.29`  | Direct GPIO | Layer 1 へ移行 (`&to 1`) | Layer 0 へ復帰 (`&to 0`) | Layer 0 へ復帰 (`&to 0`)          | Layer 0 へ復帰 (`&to 0`)          | Layer 0 へ復帰 (`&to 0`) |

#### コンボ（同時押し）操作仕様
- **L2 コンボ** (ボタン 1 + ボタン 2 同時押し) ➔ **Layer 2 へ移行** (`&to 2`：Bluetooth プロファイル 0 選択 / ペアリング全消去)
- **L3 コンボ** (ボタン 2 + ボタン 3 同時押し) ➔ **Layer 3 へ移行** (`&to 3`：Bluetooth プロファイル 1 & 2 選択)
- **L4 コンボ** (ボタン 1 + ボタン 3 同時押し) ➔ **Layer 4 へ移行** (`&to 4`：ブートローダー起動 / 選択中プロファイルのペアリング解除)

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
├── 3D/                               # トラックボール受け皿 3Dモデル (STL / SCAD)
│   ├── trackball_25mm_receiver_v13.stl # ★最終採用モデル (スライドイン&限界高支持)
│   ├── trackball_25mm_receiver_v13.scad
│   └── ...                           # 過去の試作モデル (v6 ~ v12)
├── config/
│   ├── west.yml                      # ZMK v0.3.0 & badjeff センサードライバ定義 (zmk-0.3)
│   ├── kball3.conf                   # BLE接続安定化・指向制御設定 (ルート配置)
│   ├── kball3.json                   # Keymap Editor 用縦並びレイアウト定義
│   ├── kball3.keymap                 # ルート層キーマップ（レイヤー0~4 & コンボ定義）
│   └── boards/
│       └── shields/
│           └── kball3/
│               ├── Kconfig.defconfig # キーボード識別名定義 (kball3)
│               ├── Kconfig.shield    # シールド有効化フラグ
│               ├── kball3.conf       # BLE接続安定化設定
│               ├── kball3.keymap     # シールド用キーマップ（ルートと同期）
│               ├── kball3.overlay    # Devicetree (SPI & Direct Kscan)
│               ├── kball3.json       # シールド用レイアウト定義
│               └── kball3.zmk.yml    # ZMK メタデータ
├── build.yaml                        # kball3.uf2 + settings_reset.uf2 並列ビルド設定
├── LICENSE                           # MIT License
└── README.md
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

### PALM2向け 接続安定性確認

GitHub Actions の `kball3.uf2` は、`CONFIG_ZMK_BLE_EXPERIMENTAL_CONN=y` と、PMW3610 の最小レポート間隔を 12 ms にする `CONFIG_PMW3610_REPORT_INTERVAL_MIN=12` を有効にしたファームウェアです。書き込み後は PALM2 で、低速の直線、細かい停止、円軌跡を順に確認してください。設定はコンパイル時に反映されるため、変更を使うにはこの UF2 の書き込みが必要です。

---

## 5. ZMK のバージョンアップと将来のメンテナンスについて

### 現状のバージョン整合性
- **ZMK 本体**: **`v0.3.0`** (`revision: v0.3.0`)
- **センサードライバ**: **`badjeff/zmk-pmw3610-driver`** の **`zmk-0.3` ブランチ** (`revision: zmk-0.3`)

センサードライバ作者（badjeff 氏）によって ZMK `v0.3.0` 専用の修正ブランチ（`zmk-0.3`）が用意されており、両者の規格が100%合致した状態で稼働しています。

- 参考: [snize/zmk-keyboard-suzuri](https://github.com/snize/zmk-keyboard-suzuri)
- テンプレート: [snize/zmk-suzuri-config-template](https://github.com/snize/zmk-suzuri-config-template)

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

## 6. トラックボール受け皿（3Dプリント用 STL モデル）の仕様と履歴

物理構造上の干渉や組み立て性を改善するため、トラックボール受け皿（球径 25 mm / 支持球 1.5 mm × 3点）の 3D データを改善してきました。

### 3D モデルファイルの概要

- **格納先**: `3D/`
- **対象モデル**: 25 mm球トラックボールホルダー
- **最終採用モデル**: **`trackball_25mm_receiver_v13.stl`**

### 主要バージョンの特徴

- **`trackball_25mm_receiver_v13.stl` (17.0mmハイト・スライドイン＆限界高支持モデル) ★最終採用・最新**
  - **安定性と脱着性の究極の融合**: センサー基板の脱着を容易にするため、配線が出る前面（Yマイナス側）を完全開口し、底面の左右のフチに厚さ 1.0 mm・幅 1.5 mm の棚（レール）を設けて、横からスライドインして奥の壁で止まる構造を採用。
  - **光学ピント距離 2.4 mm の厳密な維持**: `cavity_h` は `6.7 mm`、球中心 Z座標は `21.6 mm` （ボール底面 Z = 9.1 mm）とし、推奨ピント距離 2.4 mm をキープ。
  - **限界支持角 55度**: 支持球位置は 接触角55度（Z = 15.00 mm） の限界高支持を継承し、ボールの横ブレを徹底排除。
  - **天板厚の大幅な引き上げによる強度補強**: 台座高さ（`pedestal_h`）を `8.8 mm` へと肉厚化し、耳の部分の天板厚みを 0.8 mm ➔ `2.1 mm` へ大幅補強。全体の高さは `17.0 mm`。

- **`trackball_25mm_receiver_v12.stl` (17.0mmハイト・限界高支持・カップ深化モデル)**
  - コップの深さ 17.0 mm、接触角55度（Z = 14.00 mm 超ハイマウント）を採用したブレ低減モデル。

- **`trackball_25mm_receiver_v11.stl` (17.0mmハイト・支持球高支持・カップ深化モデル)**
  - 深さ 17.0 mm × 接触角50度（Z = 13.08 mm）のハイマウントモデル。

- **`trackball_25mm_receiver_v10.stl` (15.5mmハイト・支持球高支持モデル)**
  - 高さ 15.5 mm、接触角50度モデル。

---

## 7. トッププレートのカバー方式（ザグリ加工）と物理設計の工夫

キーボード全体の低背化（薄型化）とスマートな美観を両立させるため、以下の物理設計と3Dプリントの工夫を行っています。

### 7.1 トップカバーと受け皿の取り合い（カバー方式）
- **美観重視の設計**: 受け皿のフチを露出させるツライチ仕上げではなく、トッププレートで受け皿のフチ（外径 30.0 mm）を覆い隠す「カバー方式」を採用。丸穴からボールだけが覗くスマートな美観を実現。
- **ボトムケースの沈み込み構造**: ボトムケースの台座受け部分をあらかじめ **`1 mm 深く設計（沈み込み）`** 。受け皿全体が下がり、トップカバーとの干渉防止クリアランスを自動確保。
- **トップカバー裏のザグリ（逃げ加工）**: 厚さ 2.0 mm のトップカバー裏面に対し、**`直径 32 mm 、深さ 1.0 mm の円形ザグリ穴（凹み）`** を設けることで、全体の高さをさらに **1.5 mm 低く（ボトムケース全体高さ 20.5 mm）** 抑制。
- **ボール露出用のアパチャ（穴）**: 表側の貫通穴は **`25.5 mm 〜 26.0 mm`** に設定し、ボール（25.0 mm）を上から簡単に取り出して支持球（ジルコニア球）をメンテナンス可能。

### 7.2 3Dプリント時のスライサー設定（Bambu Studio / OrcaSlicer）
- **天面上向き印刷**: トップカバーの天面の美観を最優先するため、天面を上向きにして印刷。
- **サポートなしでのザグリ天井ブリッジ**:
  - ザグリ穴部分（直径 30.4 mm、深さ 1.0 mm）は、スライスすると幅約 `2.2 mm` の細い「同心円状のひさし（コンセントリック・ウォール）」として積層。
  - スパン距離が短く沈み込みマージンもあるため、サポート材なし（サポート「オフ」）で綺麗に印刷可能。

---

## 8. トラックボールの組み立てと動作検証結果

### 8.1 物理マウントと光学ピント
- **`trackball_25mm_receiver_v13.stl`**（最終採用モデル）をボトムケースの受け皿座に固定した状態で、センサー基板をコップ底面のキャビティへ下から密着（スライドイン・サンドイッチ構造で支持）させることで、設計通りピッタリ 2.4 mm のピント距離が確保され、トラッキングが極めて安定。

### 8.2 ソフトウェア軸補正 & 初期化ディレイ
- **軸補正 (`kball3.overlay`)**: `kball3.overlay` 内の `&trackball` ノードで左右反転のみ（`invert-x;`）を適用。
- **解像度**: `400 CPI` に設定し、スムーズで直感的な操作感に調整。
- **コールドブート対策 (`kball3.conf`)**:
  ```conf
  CONFIG_PMW3610_INIT_POWER_UP_EXTRA_DELAY_MS=1000
  ```
  バッテリー給電時にスイッチON直後のセンサー電源立ち上がりを待つため、1000ms（1秒）のディレイを挿入して100%安定起動を実現。
