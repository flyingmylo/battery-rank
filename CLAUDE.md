# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

BatteryRank 是一个 macOS 菜单栏应用，用于监控和排名各应用的电池消耗。基于 CPU 时间归因算法，将电池消耗分配到各个应用。UI 语言为简体中文。

## Build & Run Commands

```bash
# 构建并生成 .app 包
./build.sh

# 构建并生成 DMG 安装包
./dmg.sh

# 仅编译（不打包）
swift build -c release

# Debug 编译
swift build

# 运行
open BatteryRank.app
```

纯 SPM 项目，无 Xcode 工程，无外部依赖。目标平台 macOS 13.0+。

## Architecture

**MVVM 架构**，SwiftUI + AppKit 混合：

- **App 入口** (`BatteryRankApp.swift`): `AppDelegate` 管理菜单栏 `NSStatusItem` 和 `NSPopover`，延迟 1 秒启动监控
- **ViewModels** (`RankingViewModel`): `@MainActor` 类，持有 `@Published` 状态，协调各 Service
- **Services**: 核心业务逻辑
  - `ProcessMonitor` — 通过 libproc（C 互操作）采集进程 CPU 时间
  - `BatteryMonitor` — 通过 IOKit.ps 读取电池状态
  - `EnergyAttributor` — 基于 CPU 时间差将电池消耗归因到各应用
  - `DataStore` — JSON 文件持久化（`~/Library/Application Support/BatteryRank/`）
- **Views**: SwiftUI 视图（PopoverView → RankingListView → RankingRowView）
- **CLibProc**: C 系统库包装（`module.modulemap` + 头文件），提供 `proc_pidpath` 等 C 函数的 Swift 接口

## Key Technical Details

- 菜单栏应用：`LSUIElement = true`，无 Dock 图标
- `CLibProc` 是 SPM system library target，通过 modulemap 桥接 C 的 libproc
- 没有测试目标，没有测试文件
- CI：GitHub Actions，tag push（`v*`）触发构建和 DMG 发布
