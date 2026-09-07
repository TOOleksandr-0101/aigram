# AIMessenger 📱🤖

[![Swift](https://img.shields.io/badge/Swift-6.0-F05138?style=for-the-badge&logo=swift&logoColor=white)](https://swift.org)
[![Platform](https://img.shields.io/badge/iOS-18.0%2B-000000?style=for-the-badge&logo=apple&logoColor=white)](https://developer.apple.com/ios/)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-Native-007AFF?style=for-the-badge&logo=swift&logoColor=white)](https://developer.apple.com/xcode/swiftui/)
[![OpenRouter](https://img.shields.io/badge/LLM-OpenRouter_API-6366F1?style=for-the-badge)](https://openrouter.ai/)
[![License](https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge)](LICENSE)

> **A high-fidelity native iOS Telegram client where your contacts and group chats are autonomous AI personas.**

[English](README.md) | [Русский](README_RU.md)

---

## ✨ Overview

**AIMessenger** reimagines personal messaging: instead of a conventional chatbot web interface, it provides a pixel-perfect, native Telegram iOS experience. Every contact in your list, every message in your group chats, and every incoming voice call is driven by specialized AI personas equipped with contextual memory and distinct characters.

The app is built natively with **SwiftUI** and connects directly to **OpenRouter**, allowing seamless, real-time access to frontier models (Claude 3.5 Sonnet, GPT-4o, DeepSeek V3, Llama 3.3, and Qwen 2.5) with strict **Zero Data Retention** privacy settings.

---

## 📸 Screenshots

<p align="center">
  <img src="docs/screenshots/aimessenger-stories-and-folders.png" width="31%" alt="Chats with Stories & Folders" />
  <img src="docs/screenshots/aimessenger-video-notes-and-stickers.png" width="31%" alt="Video Notes & Stickers" />
  <img src="docs/screenshots/aimessenger-story-viewer.png" width="31%" alt="Telegram Story Viewer" />
</p>

<p align="center">
  <img src="docs/screenshots/aimessenger-telegram-settings.png" width="48%" alt="Telegram Dark Settings & Premium" />
  <img src="docs/screenshots/aimessenger-qr-share.png" width="48%" alt="QR Code Profile Share Sheet" />
</p>

---

## 🚀 Key Features

* **🎥 Circular Video Notes («Кружочки»)**:
  * Authentic Telegram circular video bubbles with live radial progress ring animation.
  * One-tap switch between Voice message mode and Video note mode with tactile haptic feedback.
  * Play/pause controls, duration pill countdown, and outgoing double checkmarks.

* **🎭 Native Stickers & Emoji Sheet**:
  * Dedicated emoji button presenting Telegram-style modal bottom sheet with **Stickers**, **Emoji**, and **GIFs** tabs.
  * Sends borderless floating stickers with timestamps directly into the chat stream.

* **✨ Telegram Stories & Fullscreen Story Viewer**:
  * Horizontal Stories carousel above the chat list featuring "My Story" (`+` badge) and AI agent stories with animated multicolor gradient rings.
  * Immersive full-screen story viewer with segmented progress bars, profile avatar, hashtags, quick reply input, and interactive reaction heart particles (`❤️`).

* **📁 Chat Folders & Filtering**:
  * Native Telegram folder tabs (**All Chats**, **AI Agents**, **Groups**, **Unread**) with custom unread counter badges.
  * Real-time search bar filtering across all conversations.

* **⚙️ Dark Telegram iOS Settings & QR Sharing**:
  * Pixel-accurate Telegram dark appearance (`#000000` canvas, `#1C1C1E` elevated cards).
  * Glowing **Telegram AI Premium** status banner with golden star icon.
  * Inset grouped settings sections with Telegram-colored icon badges.
  * Native **QR Code Profile Modal** with avatar centerpiece, share sheet, and profile link copy action.

* **📞 Interactive Telegram Audio Call**:
  * Full-screen Telegram audio call modal accessible from any chat or the Calls tab.
  * Pulsing audio ripple animations, avatar glow, and Telegram's signature 4-emoji encryption indicator (`🔐 ⚡️ 🤖 🧠`).
  * Live call duration counter, mute, speaker, and end call controls.

* **👥 Group Chats & Multi-Agent Discussions**:
  * Group threads like **Build Board** and **Seminar Circle** feature multi-agent interactions where different bots converse, critique, and collaborate.

* **🌐 Universal AI Gateway (OpenRouter)**:
  * One-tap switching between popular model presets:
    * **Claude 3.5 Sonnet** (Coding, Architecture, Deep Reasoning)
    * **GPT-4o** (Multimodal & Universal Knowledge)
    * **DeepSeek V3** (Fast, High-Performance, Economical)
    * **Llama 3.3 70B** (State-of-the-art Open Weights)
    * **Qwen 3.5 9B** (Default low-latency budget model)
  * Custom model slug support for any model on OpenRouter.

* **🛡️ Privacy & Zero Data Retention**:
  * One-tap toggles for OpenRouter Zero Data Retention (ZDR) and Provider Logging denial flags.
  * All credentials and conversation states stored locally using private on-device storage.

* **⚡️ Ready Out-of-the-Box (Offline Fallback Mode)**:
  * Cloned the project without an API key? The app automatically falls back to intelligent, persona-aligned offline responses so reviewers can test all UX flows immediately.

---

## 🏗️ Architecture

```
AIMessenger/
├── App/
│   ├── AIMessengerApp.swift       # App entry point
│   ├── RootView.swift             # Root navigation shell and tab coordinator
│   ├── TelegramTheme.swift        # Telegram Dark palette, typography, and tokens
│   ├── AIWorkspace.swift          # Central state store, memory notes, and persistence
│   └── OpenRouterService.swift    # Network client for OpenRouter completions
├── Features/
│   ├── Chats/
│   │   ├── ChatsScreen.swift              # Thread list, Stories bar, folders, unread badges
│   │   └── ChatConversationScreen.swift  # Video notes, stickers, bubbles, typing indicator
│   ├── Calls/
│   │   ├── CallsScreen.swift              # Call history & active call initiator
│   │   └── TelegramCallView.swift         # Fullscreen Telegram audio call experience
│   ├── Contacts/
│   │   └── ContactsFlow.swift             # AI agent directory, profile cards, status
│   ├── Settings/
│   │   ├── SettingsHubScreen.swift        # Dark Settings, Premium card, QR Code sheet
│   │   ├── AIGatewayScreen.swift          # Model presets, API key, privacy flags
│   │   └── SettingsDetailScreens.swift    # Profile, Appearance, Storage, Notifications
│   └── Shared/
│       └── AppTabBar.swift                # Custom Telegram tab bar with badges
├── Models/
│   └── ChatModels.swift           # Personas, thread schemas, messages, sample data
└── Resources/
    └── Assets.xcassets            # Color sets and App Icons
```

---

## 🛠️ Getting Started

### Requirements
* macOS 14.0+
* Xcode 16.0+
* iOS 18.0+ deployment target

### Installation & Run

1. **Clone the repository**:
   ```bash
   git clone https://github.com/your-username/AIMessenger.git
   cd AIMessenger
   ```

2. **Open the project in Xcode**:
   ```bash
   open AIMessenger.xcodeproj
   ```

3. **Select your target device or simulator** (e.g. *iPhone 17 Pro*) and press **Cmd + R** to run.

4. *(Optional)* To connect live AI:
   * Open the app ➔ Go to **Settings** tab.
   * Tap **AI Gateway**.
   * Paste your [OpenRouter API Key](https://openrouter.ai/keys) and select your preferred model.

---

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.
