# BatteryRank

一款 macOS 菜单栏应用，基于 CPU 时间归因算法监控并排名各应用的电池消耗。

## 系统要求

- macOS 13.0+
- Swift 5.9+

## 构建

```bash
# 构建 .app 包
./build.sh

# 构建 DMG 安装包
./dmg.sh

# 仅编译
swift build -c release
```

## 许可证

MIT
