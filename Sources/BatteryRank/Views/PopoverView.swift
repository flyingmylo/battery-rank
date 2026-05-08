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
        .frame(width: 340)
    }

    // MARK: - Main Content

    private var mainContent: some View {
        VStack(spacing: 0) {
            headerBar
                .padding(.bottom, 12)

            groupingTabs
                .padding(.bottom, 8)

            timePeriodTabs
                .padding(.bottom, 12)

            if vm.rankings.isEmpty {
                Spacer()
                emptyState
                Spacer()
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
            HStack(spacing: 6) {
                Image(systemName: "bolt.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(NotionColor.blue)
                Text("BatteryRank")
                    .font(.system(size: 15, weight: .bold))
            }
            Spacer()
            HStack(spacing: 6) {
                Circle()
                    .fill(vm.isOnBatteryPower ? NotionColor.coral : NotionColor.green)
                    .frame(width: 8, height: 8)
                Text(String(format: "%.0f%%", vm.currentBatteryLevel))
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(vm.currentBatteryLevel > 50 ? NotionColor.green : vm.currentBatteryLevel > 20 ? NotionColor.blue : NotionColor.coral)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(vm.isOnBatteryPower ? NotionColor.coralBg : NotionColor.greenBg)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }

    // MARK: - Time Period Tabs

    private var timePeriodTabs: some View {
        MaterialSegmentedPicker(
            items: TimePeriod.allCases.filter { $0 != .custom }.map { ($0.rawValue, $0) },
            selection: periodBinding
        )
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
    }

    private var periodBinding: Binding<TimePeriod> {
        Binding(
            get: { vm.selectedPeriod },
            set: { newPeriod in
                vm.selectedPeriod = newPeriod
                vm.refreshRankings()
            }
        )
    }

    // MARK: - Grouping Tabs

    private var groupingTabs: some View {
        MaterialSegmentedPicker(
            items: RankingGrouping.allCases.map { ($0.rawValue, $0) },
            selection: groupingBinding
        )
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "battery.25")
                .font(.system(size: 32))
                .foregroundColor(NotionColor.blue.opacity(0.4))
            Text("正在收集数据...")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.secondary)
            Text("请在使用电池时等待几分钟")
                .font(.system(size: 11))
                .foregroundColor(.secondary.opacity(0.7))
        }
        .frame(maxHeight: .infinity)
    }

    // MARK: - Action Bar

    private var actionBar: some View {
        HStack(spacing: 12) {
            Button {
                vm.refreshRankings()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.clockwise")
                    Text("刷新")
                }
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .hoverCursor(.pointingHand)

            Spacer()

            Button {
                showSettings = true
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "gearshape")
                    Text("设置")
                }
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .hoverCursor(.pointingHand)

            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "power")
                    Text("退出")
                }
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
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
                    .foregroundColor(NotionColor.blue)
                    .padding(.vertical, 4)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .hoverCursor(.pointingHand)
                Spacer()
                Text("设置")
                    .font(.system(size: 13, weight: .bold))
                Spacer()
                Spacer().frame(width: 48)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    sectionHeader("采样间隔")
                    MaterialSegmentedPicker(
                        items: [("10 秒", 10), ("30 秒", 30), ("60 秒", 60)],
                        selection: $pollingInterval
                    )
                    .onChange(of: pollingInterval) { newValue in
                        vm.updatePollingInterval(newValue)
                    }

                    Divider()

                    sectionHeader("数据保留")
                    MaterialSegmentedPicker(
                        items: [("3 天", 3), ("7 天", 7), ("14 天", 14), ("30 天", 30)],
                        selection: $retentionDays
                    )
                    .onChange(of: retentionDays) { newValue in
                        vm.updateRetentionDays(newValue)
                    }

                    Divider()

                    Button {
                        vm.resetData()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "trash")
                            Text("清除所有数据")
                        }
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(NotionColor.coral)
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
