import SwiftUI

struct TimePickerView: View {
    @Binding var selectedPeriod: TimePeriod
    @Binding var customStartDate: Date
    @Binding var customEndDate: Date

    var body: some View {
        VStack(spacing: 8) {
            Picker("时间段", selection: $selectedPeriod) {
                ForEach(TimePeriod.allCases, id: \.self) { period in
                    Text(period.rawValue).tag(period)
                }
            }
            .pickerStyle(.segmented)
            .frame(height: 28)

            if selectedPeriod == .custom {
                HStack {
                    DatePicker("从", selection: $customStartDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .labelsHidden()
                    Text("–")
                    DatePicker("到", selection: $customEndDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .labelsHidden()
                }
                .font(.system(size: 11))
            }
        }
    }
}
