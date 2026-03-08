# GKID Kernel

[![Build Status](https://github.com/ahmed-alnassif/GKI-Duchamp/actions/workflows/build.yml/badge.svg)](https://github.com/ahmed-alnassif/GKI-Duchamp/actions/workflows/build.yml)
[![Latest Release](https://img.shields.io/github/v/release/ahmed-alnassif/GKI-Duchamp?label=Latest%20Release&color=#00aa00)](https://github.com/ahmed-alnassif/GKI-Duchamp/releases)
[![Downloads](https://img.shields.io/github/downloads/ahmed-alnassif/GKI-Duchamp/total?label=Downloads&color=#00aa00)](https://github.com/ahmed-alnassif/GKI-Duchamp/releases)
[![SukiSU Ultra](https://img.shields.io/badge/SukiSU--Ultra-built--in-success)](https://github.com/SukiSU-Ultra/SukiSU-Ultra)
![Wild KSU](https://img.shields.io/badge/Wild--KSU-built--in-success)
![KernelSU Next](https://img.shields.io/badge/KernelSU--Next-built--in-success)
![Managers](https://img.shields.io/badge/Managers-multiple-success)
[![SUSFS](https://img.shields.io/badge/SUSFS-Integrated-orange)](https://gitlab.com/simonpunk/susfs4ksu)

A feature-rich Generic Kernel Image (GKI) kernel built for the **Poco X6 Pro (Duchamp)** and compatible with any device running a **6.1.xx-android14** GKI kernel. Designed to offer maximum flexibility, it provides multiple variants to suit your specific needs, whether you prioritize root management, system integrity, or performance.

## ✨ Key Features
*   **⚡ Performance & Efficiency Tweaks:** Extensively optimized for the Poco X6 Pro (and similar 6.1.xx-android14 devices):

    - Timer frequency set to **300Hz** for noticeably lower input lag and snappier feel

    - **Multi-Gen LRU (MGLRU)** enabled for better multitasking and battery efficiency

    - Optimized **zRAM** with LZ4 compression + writeback + tracking for more and faster usable RAM under heavy loads

    - CPU governors: **schedutil + ondemand** for efficient yet responsive scaling

    - **mq-deadline I/O scheduler** tuned for low latency on UFS 4.0 storage

    - Network stack with **TCP BBRv3 + FQ + ECN** for reduced latency and faster WiFi/mobile data speeds

    - **F2FS** filesystem support included

*   **🔧 Multiple Root Solutions:** Choose your preferred manager with variants featuring **KernelSU Next**, **SukiSU Ultra**, or **Wild KSU** and more in **Wild-KSU+Multiple-Managers** variant.

*   **🛡️ Enhanced System Integrity:** Integrated **SUSFS** (available in dedicated variants) for advanced kernel-level hiding and spoofing.

## 📱 Compatibility
*   **Primary Device:** Poco X6 Pro (codenamed `duchamp`)

*   **GKI Requirement:** Flashes on any device with a **6.1.xx-android14** kernel.  
    *(Note: Only tested on the Poco X6 Pro. Please exercise caution on other devices.)*

## ⬇️ Downloads
Find the latest builds for all variants in the [Releases](https://github.com/ahmed-alnassif/GKI-Duchamp/releases) section.