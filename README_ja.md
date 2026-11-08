# AutoIME

AutoHotkey v2 + Microsoft Edge WebView2 + React で構築された、モダンな Windows 向け入力方式（IME）・キーボードレイアウト自動切替ツール。

[ [English](README.md) | [简体中文](README_zh.md) | 日本語 ]

[![AutoHotkey v2](https://img.shields.io/badge/AutoHotkey-v2.0%2B-334455.svg?style=flat-square)](https://www.autohotkey.com/)
[![React 19](https://img.shields.io/badge/React-19-61dafb.svg?style=flat-square)](https://react.dev/)
[![Platform](https://img.shields.io/badge/Platform-Windows%2010%20%2F%2011-0078D6.svg?style=flat-square)](https://microsoft.com/windows)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg?style=flat-square)](LICENSE)

---

## 概要

AutoIME は、アクティブな最前面ウィンドウに応じて入力方式（IME）やキーボード配列を自動的に切り替える Windows バックグラウンド常駐ユーティリティです。Win32 グローバルイベントフック（`SetWinEventHook`）により、ポーリング不要でゼロ遅延・低負荷な自動切り替えを実現します。

最新バージョンでは **Microsoft Edge WebView2** と **React 19** を採用して UI を全面リニューアル。角丸カード、柔らかな多層シャドウ、ライト・ダーク・システム連動の3ステートテーマに対応しています。

## スクリーンショット

| ダークモード | ライトモード |
| :---: | :---: |
| ![ダークモード](screenshots/autoime_react.png) | ![ライトモード](screenshots/autoime_light.png) |

---

## 主な機能

- **プロセス単位の自動切替**：対象アプリがアクティブになると同時に指定 IME へ自動切り替え。
- **モダンな React UI**：WebView2 を利用した完全オフライン・高速動作のインターフェース。
- **3つのテーマモード**：☀️ ライト、🌙 ダーク、💻 システム連動（Windows のテーマ変更をリアルタイム反映）。
- **Git コミットハッシュ版番号とオンライン更新**：
  - バージョン番号は GitHub の短縮コミットハッシュ（例：`v2.0 #896a76b`）を自動取得。
  - ワンクリックでのアップデート確認と自動適用に対応（ユーザー設定 `AutoIME_config.ini` を保持）。
- **システム IME の自動検出**：インストールされている言語とキーボードを自動列挙。
- **ウィンドウキャプチャモード**：十字カーソルで目的のウィンドウをクリックするだけでルール追加。
- **ショートカットキー録音**：物理キーの入力（Ctrl/Alt/Shift/Win＋任意キー）を直接検出して設定。
- **一括操作と検索**：プロセス名検索、複数選択削除、タブ全消去に対応。
- **多言語対応**：日本語、英語、簡体字中国語を標準搭載。
- **GitHub Actions CI/CD**：push 時に実行に必要なファイルのみを厳選した Release zip を自動生成。

---

## インストールと起動

### 方法 1: リリース Zip をダウンロード (推奨)

1. GitHub Releases または Actions ページから最新の `AutoIME-<commit-hash>.zip` をダウンロードします。
2. 任意のフォルダに展開し、`AutoIME.ahk` をダブルクリックして起動します。

### 方法 2: ソースコードから実行

1. リポジトリをクローン：
   ```bash
   git clone https://github.com/kyuuseiryuu/AutoIME.git
   cd AutoIME
   ```
2. 依存関係と WebView2Loader.dll の取得：
   ```bash
   npm install
   ```
3. React バンドルをビルド：
   ```bash
   npm run build
   ```
4. `AutoIME.ahk` を実行します。

---

## 使い方

1. **設定画面を開く**：<kbd>Ctrl</kbd> + <kbd>Alt</kbd> + <kbd>I</kbd> を押すか、タスクトレイアイコンをダブルクリックします。
2. **ルールの追加**：
   - 対象 IME のタブを選択します。
   - 【🎯 窗口捕获】（キャプチャ）、【📁 浏览EXE】（ファイル選択）、【➕ 手动添加】（手動入力）のいずれかで追加します。
   - 【💾 保存并应用】をクリックして保存します。
3. **テーマ変更**：右上の `☀️` / `🌙` / `💻` ボタンで切り替えます。
4. **アップデート確認**：画面上のバージョンバッジ（例：`v2.0 #896a76b`）をクリックするか、トレイメニューの【🔄 アップデートを確認...】を選択します。

---

## ライセンス

本ソフトウェアは [MIT License](LICENSE) の下で公開されています。
