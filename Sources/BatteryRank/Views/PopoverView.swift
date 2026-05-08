import SwiftUI

struct PopoverView: View {
    @ObservedObject var vm: RankingViewModel
    @State private var showSettings = false

    var body: some View {
        Group {
            if showSettings {
                settingsContent
            } else {
                mainContent
            }
        }
        .frame(width: 320)
    }

    // MARK: - Main Content

    private var mainContent: some View {
        VStack(spacing: 0) {
            headerBar
            groupingTabs

            if vm.rankings.isEmpty {
                Spacer().frame(height: 32)
                emptyState
                Spacer().frame(height: 32)
            } else {
                RankingListView(rankings: vm.rankings)
            }

            Divider()
            actionBar
        }
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack {
            Text("BatteryRank")
                .font(.system(size: 14, weight: .bold))
            Spacer()
            HStack(spacing: 4) {
                Circle()
                    .fill(vm.isOnBatteryPower ? Color.orange : Color.green)
                    .frame(width: 8, height: 8)
                Text(String(format: "%.0f%%", vm.currentBatteryLevel))
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private var groupingTabs: some View {
        Picker("", selection: groupingBinding) {
            ForEach(RankingGrouping.allCases, id: \.self) { grouping in
                Text(grouping.rawValue).tag(grouping)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 16)
        .padding(.bottom, 10)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "battery.25")
                .font(.system(size: 28))
                .foregroundColor(.secondary.opacity(0.5))
            Text("正在收集数据...")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
            Text("请在使用电池时等待几分钟")
                .font(.system(size: 11))
                .foregroundColor(.secondary.opacity(0.7))
        }
    }

    // MARK: - Action Bar

    private var actionBar: some View {
        HStack {
            Button {
                vm.refreshRankings()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.clockwise")
                    Text("刷新")
                }
                .font(.system(size: 11))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundColor(.secondary)
            .hoverCursor(.pointingHand)

            Spacer()

            Button {
                showSettings = true
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "gearshape")
                    Text("设置")
                }
                .font(.system(size: 11))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundColor(.secondary)
            .hoverCursor(.pointingHand)

            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "power")
                    Text("退出")
                }
                .font(.system(size: 11))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundColor(.secondary)
            .hoverCursor(.pointingHand)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    // MARK: - Settings

    private var settingsContent: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    showSettings = false
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 11, weight: .semibold))
                        Text("返回")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(.primary)
                    .padding(.vertical, 4)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .hoverCursor(.pointingHand)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    sectionHeader("采样间隔")
                    Picker("", selection: $pollingInterval) {
                        Text("10 秒").tag(10)
                        Text("30 秒").tag(30)
                        Text("60 秒").tag(60)
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: pollingInterval) { newValue in
                        vm.updatePollingInterval(newValue)
                    }

                    Divider()

                    sectionHeader("数据保留")
                    Picker("", selection: $retentionDays) {
                        Text("3 天").tag(3)
                        Text("7 天").tag(7)
                        Text("14 天").tag(14)
                        Text("30 天").tag(30)
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: retentionDays) { newValue in
                        vm.updateRetentionDays(newValue)
                    }

                    Divider()

                    Button {
                        vm.resetData()
                    } label: {
                        Text("清除所有数据")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                    .hoverCursor(.pointingHand)
                }
                .padding(16)
            }
        }
    }

    @State private var pollingInterval: Int = 30
    @State private var retentionDays: Int = 7

    private var groupingBinding: Binding<RankingGrouping> {
        Binding(
            get: { vm.grouping },
            set: { vm.updateGrouping($0) }
        )
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(.secondary)
            .textCase(.uppercase)
    }
}
