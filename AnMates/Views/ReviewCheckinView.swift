import SwiftUI

struct ReviewCheckinView: View {
    let place: Place
    @Environment(\.dismiss) private var dismiss

    @State private var rating: Int = 5
    @State private var content: String = ""
    @State private var selectedVibes: Set<String> = []
    @State private var checkedIn: Bool = false
    @State private var showSuccess = false

    private let vibeOptions = ["Romantic 💕", "Instagrammable 📸", "Quiet 🤫",
                               "Lively 🎉", "Cozy 🤗", "Foodie 🍜",
                               "Chill ☕", "Premium ✨"]

    var earnedPoints: Int {
        var pts = 0
        if checkedIn { pts += 50 }
        if !content.isEmpty { pts += 30 }
        if !selectedVibes.isEmpty { pts += 10 }
        return pts
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0f0f1a").ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {

                        // Place hero
                        RoundedRectangle(cornerRadius: 16)
                            .fill(LinearGradient(colors: place.gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(height: 120)
                            .overlay(alignment: .leading) {
                                HStack(spacing: 12) {
                                    Text(place.emoji).font(.system(size: 50))
                                    VStack(alignment: .leading) {
                                        Text(place.name).font(.title3.bold()).foregroundColor(.white)
                                        Text(place.address).font(.caption).foregroundColor(.white.opacity(0.8)).lineLimit(2)
                                    }
                                }
                                .padding()
                            }

                        // Check-in toggle
                        Button {
                            withAnimation(.spring()) { checkedIn.toggle() }
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: checkedIn ? "checkmark.seal.fill" : "mappin.circle")
                                    .font(.title2)
                                    .foregroundColor(checkedIn ? Color(hex: "00b894") : Color(hex: "a29bfe"))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(checkedIn ? "Đã Check-in" : "Check-in tại đây")
                                        .font(.subheadline.bold()).foregroundColor(.white)
                                    Text(checkedIn ? "+50 AnPoints 🎉" : "Bấm để xác nhận bạn đang ở đây")
                                        .font(.caption).foregroundColor(.gray)
                                }
                                Spacer()
                            }
                            .padding(14)
                            .background(Color(hex: "1a1a2e"))
                            .overlay(RoundedRectangle(cornerRadius: 14)
                                .stroke(checkedIn ? Color(hex: "00b894") : Color.clear, lineWidth: 2))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }

                        // Rating
                        Text("Bạn đánh giá thế nào?")
                            .font(.headline.bold())
                            .foregroundColor(.white)
                        HStack(spacing: 8) {
                            ForEach(1...5, id: \.self) { i in
                                Button {
                                    withAnimation { rating = i }
                                } label: {
                                    Image(systemName: i <= rating ? "star.fill" : "star")
                                        .font(.system(size: 36))
                                        .foregroundColor(.yellow)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .center)

                        // Vibe tags
                        Text("Vibe của địa điểm này?")
                            .font(.headline.bold())
                            .foregroundColor(.white)
                        FlowLayout(spacing: 8) {
                            ForEach(vibeOptions, id: \.self) { tag in
                                Button {
                                    if selectedVibes.contains(tag) {
                                        selectedVibes.remove(tag)
                                    } else {
                                        selectedVibes.insert(tag)
                                    }
                                } label: {
                                    Text(tag)
                                        .font(.caption.bold())
                                        .padding(.horizontal, 12).padding(.vertical, 8)
                                        .background(selectedVibes.contains(tag) ?
                                                    Color(hex: "6C5CE7").opacity(0.3) : Color(hex: "1a1a2e"))
                                        .foregroundColor(selectedVibes.contains(tag) ?
                                                         Color(hex: "a29bfe") : .gray)
                                        .overlay(Capsule().stroke(
                                            selectedVibes.contains(tag) ? Color(hex: "6C5CE7") : .clear,
                                            lineWidth: 1.5))
                                        .clipShape(Capsule())
                                }
                            }
                        }

                        // Review content
                        Text("Cảm nhận của bạn")
                            .font(.headline.bold())
                            .foregroundColor(.white)
                        TextField("Chia sẻ trải nghiệm để giúp người khác...",
                                  text: $content, axis: .vertical)
                            .foregroundColor(.white)
                            .padding(12)
                            .lineLimit(4...8)
                            .background(Color(hex: "1a1a2e"))
                            .clipShape(RoundedRectangle(cornerRadius: 14))

                        // Earned points preview
                        HStack {
                            Image(systemName: "bolt.fill").foregroundColor(.yellow)
                            Text("Bạn sẽ kiếm").foregroundColor(.gray).font(.caption)
                            Text("+\(earnedPoints) AnPoints")
                                .font(.headline.bold())
                                .foregroundStyle(LinearGradient(colors: [Color(hex: "fdcb6e"), Color(hex: "e17055")],
                                                                startPoint: .leading, endPoint: .trailing))
                            Spacer()
                        }
                        .padding(14)
                        .background(Color(hex: "1a1a2e"))
                        .clipShape(RoundedRectangle(cornerRadius: 14))

                        // Submit
                        Button {
                            showSuccess = true
                        } label: {
                            Text("📝 Đăng Review")
                                .font(.headline.bold())
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(16)
                                .background(LinearGradient(colors: [Color(hex: "fdcb6e"), Color(hex: "e17055")],
                                                           startPoint: .leading, endPoint: .trailing))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .disabled(rating == 0 || !checkedIn)
                        .opacity((rating == 0 || !checkedIn) ? 0.5 : 1)
                    }
                    .padding()
                }
            }
            .navigationTitle("Check-in & Review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Đóng") { dismiss() }.foregroundColor(.white)
                }
            }
            .alert("Đã đăng! +\(earnedPoints) AnPoints 🎉", isPresented: $showSuccess) {
                Button("Tuyệt!") { dismiss() }
            } message: {
                Text("Cảm ơn bạn đã chia sẻ trải nghiệm.")
            }
        }
    }
}

// MARK: - FlowLayout (wrap tags)
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0, maxX: CGFloat = 0
        for s in subviews {
            let size = s.sizeThatFits(.unspecified)
            if x + size.width > maxWidth {
                x = 0; y += rowHeight + spacing; rowHeight = 0
            }
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            maxX = max(maxX, x)
        }
        return CGSize(width: maxX, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x: CGFloat = bounds.minX, y: CGFloat = bounds.minY, rowHeight: CGFloat = 0
        for s in subviews {
            let size = s.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX {
                x = bounds.minX; y += rowHeight + spacing; rowHeight = 0
            }
            s.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }
    }
}
