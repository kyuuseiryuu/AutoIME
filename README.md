# AutoIME

Automatic Input Method Switcher for Windows based on AutoHotkey v2.

[ English | [简体中文](README_zh.md) | [日本語](README_ja.md) ]

[![AutoHotkey v2](https://img.shields.io/badge/AutoHotkey-v2.0%2B-334455.svg?style=flat-square)](https://www.autohotkey.com/)
[![Platform](https://img.shields.io/badge/Platform-Windows%2010%20%2F%2011-0078D6.svg?style=flat-square)](https://microsoft.com/windows)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg?style=flat-square)](LICENSE)

---

## Overview

AutoIME is a background utility for Windows that automatically switches input method editors (IMEs) and keyboard layouts based on the focused application window. It listens directly to Windows foreground activation events (`EVENT_SYSTEM_FOREGROUND`) via native Win32 event hooks—delivering instantaneous, zero-polling, zero-latency layout switching with zero idle CPU overhead.

## Screenshots

### Configuration Window

![Configuration Window](screenshots/ui-config.png)

### System Tray Menu

![System Tray Menu](screenshots/ui-tray.png)

## Features

- **Process-Based Layout Switching**: Automatically applies the configured IME or keyboard layout when a target executable gains focus.
- **System Layout Enumeration**: Dynamically retrieves installed system keyboard layouts and IMEs from the Win32 API and registry, generating individual tabs for each layout.
- **Window Capture Mode**: Inspects the window under the mouse cursor in real time to capture process names and titles, allowing direct rule creation by clicking or pressing confirmation keys.
- **Interactive Hotkey Configuration**: Dedicated dialog that captures physical key combinations (`Ctrl`, `Alt`, `Shift`, `Win` + any key) to set the global activation hotkey (default: `Ctrl+Alt+I`).
- **Trilingual User Interface & i18n Architecture**: Built-in support for English, Simplified Chinese, and Japanese with instant runtime switching. AutoIME includes embedded English fallbacks and allows adding new languages simply by dropping an INI file under the `lang/` directory (see [Localization Guide](lang/README.md)).
- **System Tray Integration**: Operates in the system tray with quick access to configuration, reloading rules, toggling ToolTip hints, startup management, GitHub updates, and one-click process restart.
- **Windows Startup Support**: Toggles automatic execution on user login by managing a shortcut in the standard Windows Startup directory (`shell:startup`) without modifying registry entries.
- **Conflict Handling**: Prompts for confirmation when attempting to assign a process that is already registered under another layout.

## Requirements

- **Operating System**: Windows 10 / Windows 11 (64-bit or 32-bit)
- **Runtime**: [AutoHotkey v2.0+](https://www.autohotkey.com/) (required to run script directly)

## Installation & Execution

### Running from Script

1. Clone or download the repository:
   ```bash
   git clone https://github.com/kyuuseiryuu/AutoIME.git
   cd AutoIME
   ```
2. Run `AutoIME.ahk` with AutoHotkey v2 installed.

### Compiling to Executable

To generate a standalone `.exe`:
1. Open `Ahk2Exe` (included with standard AutoHotkey installations).
2. Set **Source (script)** to `AutoIME.ahk`.
3. Set **Destination (.exe)** to `AutoIME.exe`.
4. Set **Base File** to `AutoHotkey64.exe` (v2).
5. Click **Convert**.

## Usage

### Adding Process Rules

1. Open the configuration window by pressing <kbd>Ctrl</kbd> + <kbd>Alt</kbd> + <kbd>I</kbd> or double-clicking the system tray icon.
2. Select the target IME tab.
3. Add processes using any of the following methods:
   - **Capture Window**: Click **Capture Window**, point the cursor at the target application, and left-click (or press <kbd>Space</kbd> / <kbd>Enter</kbd> / <kbd>F8</kbd>). Press <kbd>Esc</kbd> to cancel.
   - **Browse EXE**: Click **Browse EXE** to select an executable file through the file dialog.
   - **Add Manual**: Click **Add Manual** and input the process name (e.g., `code.exe`).
4. Click **Save & Apply** to persist the changes.

### Default Shortcuts

| Shortcut / Action | Function |
| :--- | :--- |
| <kbd>Ctrl</kbd> + <kbd>Alt</kbd> + <kbd>I</kbd> | Open or hide the configuration window (customizable) |
| Tray Icon Double-Click | Open the configuration window |
| <kbd>Esc</kbd> (in capture mode) | Exit window capture mode |
| <kbd>Space</kbd> / <kbd>Enter</kbd> / <kbd>F8</kbd> (in capture mode) | Capture the hovered window |

## Configuration File

Settings are saved in `AutoIME_config.ini` in the script directory (encoded in UTF-16 LE). If the file is absent on launch, default settings and initial rules are generated automatically.

```ini
[Settings]
DebugMode=0        ; 0 = disabled, 1 = show ToolTip notifications on switch
Language=en        ; en = English, zh = Simplified Chinese, ja = Japanese
Hotkey=^!i         ; Hotkey format (^ = Ctrl, ! = Alt, + = Shift, # = Win)

[IME_0x04090409]   ; Layout HKL identifier (e.g., US English)
DisplayName=English (United States) - US
code.exe=Visual Studio Code
windowsterminal.exe=Windows Terminal

[IME_0x08040804]   ; Layout HKL identifier (e.g., Chinese Simplified)
DisplayName=Chinese (Simplified) - Microsoft Pinyin
weixin.exe=WeChat
```

An example configuration file is provided in [`AutoIME_config.example.ini`](AutoIME_config.example.ini).

## Repository Structure

```text
AutoIME/
├── screenshots/
│   ├── ui-tray.png               # System tray menu screenshot
│   └── ui-config.png             # Configuration window screenshot
├── lang/
│   ├── README.md                 # Localization & language guide
│   ├── en.ini                    # English language file
│   ├── ja.ini                    # Japanese language file
│   └── zh.ini                    # Simplified Chinese language file
├── core/                         # Core logic layer
│   ├── Globals.ahk               # Global variables and configurations
│   ├── Logger.ahk                # Debug logging helper
│   ├── I18n.ahk                  # Localization & dictionary manager
│   ├── ImeEngine.ahk             # System IME enumeration & IMM32 activation
│   ├── Config.ahk                # INI reading/writing, rule persistence & hotkey
│   └── WindowWatcher.ahk         # WinEventHook event-driven window listener
├── ui/                           # User interface layer
│   ├── HotkeyDialog.ahk          # Interactive hotkey configuration dialog
│   ├── WindowCapture.ahk         # 🎯 Window target capture mode & mouse hook
│   ├── TrayMenu.ahk              # System tray menu & toggle checks
│   └── ConfigGui.ahk             # Main settings GUI (Native Tab3 architecture)
├── AutoIME.ahk                   # Main entrypoint script
├── AutoIME_config.example.ini    # Example configuration template
├── LICENSE                       # MIT License
├── README.md                     # Documentation (English)
├── README_ja.md                  # Documentation (Japanese)
└── README_zh.md                  # Documentation (Simplified Chinese)
```

## Technical Implementation

- **Event-Driven Hooking**: Window focus is tracked through a global out-of-context Win32 hook (`SetWinEventHook` listening to `EVENT_SYSTEM_FOREGROUND = 0x0003` with `WINEVENT_SKIPOWNPROCESS`). This replaces traditional polling timers, eliminating wake-up overhead and achieving instant response.
- **Switching Mechanism**: The tool issues `WM_INPUTLANGCHANGEREQUEST` (`0x0050`) via `PostMessageW` to the target window. For Chinese (0x0804) and US English (0x0409) layouts, IMM32 messages (`ImmGetDefaultIMEWnd`, `0x0283`) are sent to ensure conversion states are set accordingly.
- **Privilege Boundaries**: Due to Windows User Interface Privilege Isolation (UIPI), windows running with elevated privileges (Administrator) cannot receive window messages from non-elevated processes. To control elevated windows, run AutoIME as Administrator.

## License

This project is distributed under the [MIT License](LICENSE).
