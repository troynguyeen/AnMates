import SwiftUI

struct AIFoodSuggestionView: View {
    let place: Place?
    @State var groupSize: Int = 2
    @State var mood: Mood = .hungry
    @State private var priceLevel: String = "Trung bình"   // Thấp | Trung bình
    @State private var isGenerating = false
    @State private var suggestions: [FoodSuggestion] = []

    @Environment(\.dismiss) private var dismiss

    private let priceOptions = ["Thấp", "Trung bình"]

    init(place: Place? = nil, groupSize: Int = 2, mood: Mood = .hungry) {
        self.place = place
        self._groupSize = State(initialValue: groupSize)
        self._mood = State(initialValue: mood)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0f0f1a").ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {

                        // Header
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(LinearGradient(colors: [Color(hex: "00b894"), Color(hex: "00cec9")],
                                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 56, height: 56)
                                Image(systemName: "sparkles")
                                    .font(.title2)
                                    .foregroundColor(.white)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text("AI Gợi Ý Món Ăn")
                                    .font(.title3.bold())
                                    .foregroundColor(.white)
                                Text("Dựa trên nhóm, mood & ngân sách")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                        }

                        // Group size selector
                        Text("Số người").font(.headline.bold()).foregroundColor(.white)
                        HStack(spacing: 10) {
                            ForEach([2, 4], id: \.self) { n in
                                Button {
                                    groupSize = n
                                } label: {
                                    VStack(spacing: 4) {
                                        Text("\(n)").font(.title2.bold())
                                        Text("người").font(.caption2)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(groupSize == n ?
                                                Color(hex: "6C5CE7").opacity(0.3) : Color(hex: "1a1a2e"))
                                    .foregroundColor(groupSize == n ? Color(hex: "a29bfe") : .gray)
                                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(
                                        groupSize == n ? Color(hex: "6C5CE7") : .clear, lineWidth: 1.5))
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                }
                            }
                        }

                        // Mood
                        Text("Mood").font(.headline.bold()).foregroundColor(.white)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(Mood.allCases, id: \.self) { m in
                                    Button {
                                        mood = m
                                    } label: {
                                        HStack(spacing: 4) {
                                            Text(m.emoji)
                                            Text(m.rawValue).font(.caption.bold())
                                        }
                                        .padding(.horizontal, 12).padding(.vertical, 8)
                                        .background(mood == m ? m.color.opacity(0.3) : Color(hex: "1a1a2e"))
                                        .foregroundColor(mood == m ? m.color : .gray)
                                        .clipShape(Capsule())
                                    }
                                }
                            }
                        }

                        // Price level
                        Text("Mức giá").font(.headline.bold()).foregroundColor(.white)
                        HStack(spacing: 10) {
                            ForEach(priceOptions, id: \.self) { opt in
                                Button {
                                    priceLevel = opt
                                } label: {
                                    HStack {
                                        Text(opt == "Thấp" ? "💰" : "💰💰")
                                        Text(opt).font(.subheadline.bold())
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(priceLevel == opt ?
                                                Color(hex: "00b894").opacity(0.3) : Color(hex: "1a1a2e"))
                                    .foregroundColor(priceLevel == opt ? Color(hex: "00b894") : .gray)
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(
                                        priceLevel == opt ? Color(hex: "00b894") : .clear, lineWidth: 1.5))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                            }
                        }

                        // Generate button
                        Button {
                            generate()
                        } label: {
                            HStack {
                                if isGenerating {
                                    ProgressView().tint(.white)
                                } else {
                                    Image(systemName: "wand.and.stars")
                                }
                                Text(isGenerating ? "Đang gợi ý..." : "Gợi ý cho tôi")
                            }
                            .font(.headline.bold())
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(16)
                            .background(LinearGradient(colors: [Color(hex: "00b894"), Color(hex: "00cec9")],
                                                       startPoint: .leading, endPoint: .trailing))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .disabled(isGenerating)

                        // Suggestions list
                        if !suggestions.isEmpty {
                            Text("Top \(suggestions.count) gợi ý")
                                .font(.headline.bold())
                                .foregroundColor(.white)
                                .padding(.top, 8)

                            ForEach(suggestions) { s in
                                SuggestionCard(suggestion: s)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("AI Gợi Ý")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Đóng") { dismiss() }.foregroundColor(.white)
                }
            }
            .onAppear { generate() }
        }
    }

    private func generate() {
        isGenerating = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            let base = FoodSuggestion.suggestions(forGroupSize: groupSize, mood: mood)
            // Filter by price level
            suggestions = base.filter { $0.priceLevel == priceLevel || priceLevel == "Trung bình" }
            isGenerating = false
        }
    }
}

struct SuggestionCard: View {
    let suggestion: FoodSuggestion

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(suggestion.emoji)
                .font(.system(size: 44))
                .frame(width: 64, height: 64)
                .background(Color(hex: "2a2a4a"))
                .clipShape(RoundedRectangle(cornerRadius: 14))

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(suggestion.name)
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "bolt.fill").font(.caption2)
                        Text("\(suggestion.matchScore)%").font(.caption.bold())
                    }
                    .foregroundColor(.yellow)
                }
                Text(suggestion.reason)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(2)
                HStack(spacing: 6) {
                    Text(suggestion.priceLevel == "Thấp" ? "💰" : "💰💰")
                        .font(.caption2)
                    Text(suggestion.estimatedPrice)
                        .font(.caption.bold())
                        .foregroundColor(Color(hex: "00b894"))
                    Text("·").foregroundColor(.gray)
                    Text("\(suggestion.suitableFor) người").font(.caption).foregroundColor(.gray)
                }
            }
        }
        .padding(12)
        .background(Color(hex: "1a1a2e"))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
