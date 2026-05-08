import SwiftUI

enum NotionColor {
    static let blue = Color(red: 82/255, green: 156/255, blue: 202/255)
    static let blueBg = Color(red: 211/255, green: 229/255, blue: 239/255)
    static let coral = Color(red: 228/255, green: 117/255, blue: 107/255)
    static let coralBg = Color(red: 255/255, green: 226/255, blue: 221/255)
    static let green = Color(red: 77/255, green: 171/255, blue: 154/255)
    static let greenBg = Color(red: 219/255, green: 237/255, blue: 219/255)
    static let purple = Color(red: 144/255, green: 101/255, blue: 176/255)
    static let purpleBg = Color(red: 232/255, green: 222/255, blue: 238/255)
    static let surface = Color(red: 247/255, green: 247/255, blue: 245/255)
}

struct MaterialSegmentedPicker<T: Hashable>: View {
    let items: [(String, T)]
    @Binding var selection: T

    var body: some View {
        HStack(spacing: 2) {
            ForEach(items.indices, id: \.self) { index in
                let (title, tag) = items[index]
                let isSelected = selection == tag

                Text(title)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .medium))
                    .foregroundColor(isSelected ? NotionColor.blue : .secondary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background {
                        if isSelected {
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(NotionColor.blueBg)
                        }
                    }
                    .contentShape(Rectangle())
                    .hoverCursor(.pointingHand)
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selection = tag
                        }
                    }
            }
        }
        .padding(3)
        .background {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(NotionColor.surface)
        }
    }
}

extension View {
    func hoverCursor(_ cursor: NSCursor) -> some View {
        self.onHover { hovering in
            if hovering {
                cursor.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}
