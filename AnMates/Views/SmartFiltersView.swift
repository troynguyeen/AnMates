import SwiftUI

struct SmartFiltersView: View {
    @Binding var filter: PlaceFilter
    @Environment(\.dismiss) private var dismiss
    let onApply: () -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0f0f1a").ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        // Distance
                        SectionLabel("📍 Khoảng cách",
                                     value: "\(Int(filter.distance)) km")
                        Slider(value: $filter.distance, in: 1...20, step: 1)
                            .accentColor(Color(hex: "6C5CE7"))

                        // Budget
                        SectionLabel("💰 Ngân sách tối đa",
                                     value: "\(Int(filter.maxPrice))k")
                        Slider(value: $filter.maxPrice, in: 50...1000, step: 50)
                            .accentColor(Color(hex: "fdcb6e"))

                        // Rating
                        SectionLabel("⭐ Rating tối thiểu",
                                     value: String(format: "%.1f+", filter.minRating))
                        HStack(spacing: 8) {
                            ForEach([3.5, 4.0, 4.5, 4.8], id: \.self) { r in
                                Button {
                                    filter.minRating = r
                                } label: {
                                    Text(String(format: "%.1f+", r))
                                        .font(.caption.bold())
                                        .padding(.horizontal, 14).padding(.vertical, 8)
                                        .background(abs(filter.minRating - r) < 0.01 ?
                                                    Color(hex: "fdcb6e").opacity(0.3) : Color(hex: "1a1a2e"))
                                        .foregroundColor(abs(filter.minRating - r) < 0.01 ?
                                                         Color(hex: "fdcb6e") : .gray)
                                        .clipShape(Capsule())
                                }
                            }
                        }

                        // Open now
                        Toggle(isOn: $filter.openNow) {
                            HStack {
                                Text("🕐").font(.title3)
                                VStack(alignment: .leading) {
                                    Text("Đang mở cửa").font(.subheadline.bold()).foregroundColor(.white)
                                    Text("Chỉ hiện địa điểm đang mở").font(.caption2).foregroundColor(.gray)
                                }
                            }
                        }
                        .tint(Color(hex: "00b894"))
                        .padding(14)
                        .background(Color(hex: "1a1a2e"))
                        .clipShape(RoundedRectangle(cornerRadius: 14))

                        // Suitable for
                        Text("👥 Phù hợp cho").font(.headline.bold()).foregroundColor(.white)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(PlaceFilter.suitableOptions, id: \.self) { opt in
                                    Button {
                                        filter.suitableFor = opt
                                    } label: {
                                        Text(opt)
                                            .font(.caption.bold())
                                            .padding(.horizontal, 14).padding(.vertical, 8)
                                            .background(filter.suitableFor == opt ?
                                                        Color(hex: "fd79a8").opacity(0.3) : Color(hex: "1a1a2e"))
                                            .foregroundColor(filter.suitableFor == opt ?
                                                             Color(hex: "fd79a8") : .gray)
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                        }

                        Spacer()
                    }
                    .padding()
                }

                // Apply button
                VStack {
                    Spacer()
                    HStack(spacing: 10) {
                        Button {
                            filter = PlaceFilter()
                        } label: {
                            Text("Đặt lại")
                                .font(.subheadline.bold())
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity).padding(.vertical, 14)
                                .background(Color(hex: "2a2a4a"))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        Button {
                            onApply(); dismiss()
                        } label: {
                            Text("Áp dụng")
                                .font(.subheadline.bold())
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity).padding(.vertical, 14)
                                .background(LinearGradient(colors: [Color(hex: "6C5CE7"), Color(hex: "fd79a8")],
                                                           startPoint: .leading, endPoint: .trailing))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    }
                    .padding()
                    .background(Color(hex: "0f0f1a"))
                }
            }
            .navigationTitle("Bộ lọc thông minh")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Đóng") { dismiss() }.foregroundColor(.white)
                }
            }
        }
        .presentationDetents([.large])
    }
}

private struct SectionLabel: View {
    let title: String
    let value: String

    init(_ title: String, value: String) {
        self.title = title; self.value = value
    }

    var body: some View {
        HStack {
            Text(title).font(.headline.bold()).foregroundColor(.white)
            Spacer()
            Text(value).font(.subheadline.bold()).foregroundColor(Color(hex: "a29bfe"))
        }
    }
}
