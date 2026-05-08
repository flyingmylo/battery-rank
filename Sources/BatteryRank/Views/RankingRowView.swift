import SwiftUI

struct RankingRowView: View {
    let ranking: AppRanking
    let rank: Int

    var body: some View {
        HStack(spacing: 10) {
            Text("\(rank)")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(.secondary)
                .frame(width: 20)

            if let icon = ranking.icon {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 24, height: 24)
            } else {
                Text(String(ranking.appName.prefix(1)).uppercased())
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(width: 24, height: 24)
                    .background {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(colorForName(ranking.appName))
                    }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(ranking.appName)
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(1)

                if let subtitle = ranking.subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(.quaternary)
                            .frame(height: 4)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(colorForPercentage(ranking.percentage))
                            .frame(
                                width: max(geo.size.width * min(ranking.percentage, 100) / 100, 2),
                                height: 4
                            )
                    }
                }
                .frame(height: 4)
            }

            Text(String(format: "%.1f%%", ranking.percentage))
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(colorForPercentage(ranking.percentage))
                .frame(width: 44, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
    }

    private func colorForPercentage(_ pct: Double) -> Color {
        pct > 30 ? NotionColor.coral : pct > 15 ? NotionColor.blue : NotionColor.green
    }

    private func colorForName(_ name: String) -> Color {
        let palette: [Color] = [NotionColor.blue, NotionColor.coral, NotionColor.green, NotionColor.purple]
        let hash = abs(name.hashValue)
        return palette[hash % palette.count]
    }
}
