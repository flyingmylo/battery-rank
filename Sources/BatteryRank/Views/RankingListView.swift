import SwiftUI

struct RankingListView: View {
    let rankings: [AppRanking]

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(Array(rankings.prefix(20).enumerated()), id: \.element.id) { index, ranking in
                    RankingRowView(ranking: ranking, rank: index + 1)
                    if index < min(rankings.count, 20) - 1 {
                        Divider().padding(.horizontal, 16)
                    }
                }
            }
        }
        .frame(maxHeight: 400)
    }
}
