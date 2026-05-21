import SwiftUI

struct PlaceDetailView: View {
    let place: Place
    @Environment(\.dismiss) private var dismiss
    @State private var showScheduling = false
    @State private var showReview = false
    @State private var showGroupCreate = false
    @State private var showAISuggest = false
    @State private var showInviteSheet = false

    var body: some View {
        ZStack {
            Color(hex: "0f0f1a").ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {

                    // Hero
                    ZStack(alignment: .bottomLeading) {
                        RoundedRectangle(cornerRadius: 0)
                            .fill(LinearGradient(colors: place.gradient,
                                                 startPoint: .topLeading,
                                                 endPoint: .bottomTrailing))
                            .frame(height: 280)
                            .overlay(
                                Text(place.emoji)
                                    .font(.system(size: 100))
                                    .opacity(0.9)
                            )

                        // Title overlay
                        VStack(alignment: .leading, spacing: 8) {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack {
                                    ForEach(place.vibeTags, id: \.self) { tag in
                                        Text(tag)
                                            .font(.caption2.bold())
                                            .padding(.horizontal, 10).padding(.vertical, 4)
                                            .background(.ultraThinMaterial)
                                            .clipShape(Capsule())
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                            Text(place.name)
                                .font(.title.bold())
                                .foregroundColor(.white)
                            HStack(spacing: 10) {
                                Label(String(format: "%.1f", place.rating), systemImage: "star.fill")
                                    .foregroundColor(.yellow)
                                Text("·")
                                Text("\(place.reviewCount) đánh giá")
                                Text("·")
                                Text(place.priceRange)
                            }
                            .font(.caption.bold())
                            .foregroundColor(.white.opacity(0.9))
                        }
                        .padding(20)
                    }

                    // Quick action row
                    HStack(spacing: 10) {
                        QuickActionBtn(icon: "map.fill", label: "Chỉ đường",
                                       color: Color(hex: "00b894")) { openInMaps() }
                        QuickActionBtn(icon: "phone.fill", label: "Gọi",
                                       color: Color(hex: "0984e3")) { callPlace() }
                        QuickActionBtn(icon: "person.2.fill", label: "Rủ bạn",
                                       color: Color(hex: "fd79a8")) { showInviteSheet = true }
                        QuickActionBtn(icon: "calendar.badge.plus", label: "Đặt hẹn",
                                       color: Color(hex: "6C5CE7")) { showScheduling = true }
                    }
                    .padding(.horizontal)

                    // Info card
                    VStack(alignment: .leading, spacing: 12) {
                        InfoRow(icon: "mappin.and.ellipse",
                                label: "Địa chỉ", value: place.address)
                        Divider().background(Color(hex: "2a2a4a"))
                        InfoRow(icon: "phone.fill",
                                label: "Số điện thoại", value: place.phone)
                        Divider().background(Color(hex: "2a2a4a"))
                        InfoRow(icon: "clock.fill",
                                label: "Giờ mở cửa", value: place.openingHours)
                        Divider().background(Color(hex: "2a2a4a"))
                        InfoRow(icon: "tag.fill",
                                label: "Loại", value: place.category.rawValue)
                    }
                    .padding(16)
                    .background(Color(hex: "1a1a2e"))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)

                    // Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Giới thiệu")
                            .font(.headline.bold())
                            .foregroundColor(.white)
                        Text(place.detailDescription)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal)

                    // Vibe Check (emoji aggregates)
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Vibe Check")
                            .font(.headline.bold())
                            .foregroundColor(.white)
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                            VibeStat(emoji: "💕", label: "Romantic", count: 42)
                            VibeStat(emoji: "📸", label: "Instagrammable", count: 67)
                            VibeStat(emoji: "🎉", label: "Lively", count: 28)
                            VibeStat(emoji: "🤫", label: "Quiet", count: 12)
                        }
                    }
                    .padding(.horizontal)

                    // CTA buttons
                    VStack(spacing: 10) {
                        CTAButton(title: "📝 Check-in & Viết Review",
                                  subtitle: "Kiếm +30 AnPoints",
                                  gradient: [Color(hex: "fdcb6e"), Color(hex: "e17055")]) {
                            showReview = true
                        }
                        CTAButton(title: "👥 Tạo Nhóm Đi Ăn",
                                  subtitle: "Tối đa 4 người · Mời thêm bạn",
                                  gradient: [Color(hex: "6C5CE7"), Color(hex: "a29bfe")]) {
                            showGroupCreate = true
                        }
                        CTAButton(title: "🤖 AI Gợi Ý Món",
                                  subtitle: "Dựa trên nhóm, mood & ngân sách",
                                  gradient: [Color(hex: "00b894"), Color(hex: "00cec9")]) {
                            showAISuggest = true
                        }
                    }
                    .padding(.horizontal)

                    // Reviews
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Đánh giá (\(place.reviewCount))")
                                .font(.headline.bold())
                                .foregroundColor(.white)
                            Spacer()
                            Button("Xem tất cả") {}
                                .font(.caption.bold())
                                .foregroundColor(Color(hex: "a29bfe"))
                        }
                        ForEach(place.reviews) { rv in
                            ReviewRow(review: rv)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 40)
                }
            }

            // Top bar
            VStack {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .padding(10)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                            .foregroundColor(.white)
                    }
                    Spacer()
                    Menu {
                        Button("Chia sẻ", systemImage: "square.and.arrow.up") {}
                        Button("Báo cáo", systemImage: "flag", role: .destructive) {}
                    } label: {
                        Image(systemName: "ellipsis")
                            .padding(10)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal)
                Spacer()
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showScheduling) {
            DateSchedulingView(place: place)
        }
        .sheet(isPresented: $showReview) {
            ReviewCheckinView(place: place)
        }
        .sheet(isPresented: $showGroupCreate) {
            DiningGroupView(place: place)
        }
        .sheet(isPresented: $showAISuggest) {
            AIFoodSuggestionView(place: place)
        }
        .sheet(isPresented: $showInviteSheet) {
            InvitePartnerSheet(place: place)
        }
    }

    // MARK: - Actions
    private func openInMaps() {
        let query = place.address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? place.address
        // Try Google Maps first, fallback to Apple Maps
        if let gURL = URL(string: "comgooglemaps://?q=\(query)"),
           UIApplication.shared.canOpenURL(gURL) {
            UIApplication.shared.open(gURL)
        } else if let webURL = URL(string: "https://www.google.com/maps/search/?api=1&query=\(query)") {
            UIApplication.shared.open(webURL)
        }
    }

    private func callPlace() {
        let digits = place.phone.filter { "+0123456789".contains($0) }
        if let url = URL(string: "tel://\(digits)"), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Subviews

struct QuickActionBtn: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(color)
                    .frame(width: 44, height: 44)
                    .background(color.opacity(0.15))
                    .clipShape(Circle())
                Text(label)
                    .font(.caption2.bold())
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

struct InfoRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(Color(hex: "a29bfe"))
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.caption).foregroundColor(.gray)
                Text(value).font(.subheadline).foregroundColor(.white)
            }
            Spacer()
        }
    }
}

struct VibeStat: View {
    let emoji: String
    let label: String
    let count: Int

    var body: some View {
        HStack {
            Text(emoji).font(.title3)
            VStack(alignment: .leading, spacing: 0) {
                Text(label).font(.caption.bold()).foregroundColor(.white)
                Text("\(count) lượt").font(.caption2).foregroundColor(.gray)
            }
            Spacer()
        }
        .padding(10)
        .background(Color(hex: "1a1a2e"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct CTAButton: View {
    let title: String
    let subtitle: String
    let gradient: [Color]
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.subheadline.bold()).foregroundColor(.white)
                    Text(subtitle).font(.caption).foregroundColor(.white.opacity(0.85))
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundColor(.white)
            }
            .padding(14)
            .frame(maxWidth: .infinity)
            .background(LinearGradient(colors: gradient, startPoint: .leading, endPoint: .trailing))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }
}

struct ReviewRow: View {
    let review: PlaceReview

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(review.authorEmoji).font(.title3)
                VStack(alignment: .leading, spacing: 0) {
                    Text(review.authorName).font(.subheadline.bold()).foregroundColor(.white)
                    Text(review.timeAgo).font(.caption2).foregroundColor(.gray)
                }
                Spacer()
                HStack(spacing: 2) {
                    ForEach(0..<5) { i in
                        Image(systemName: i < review.rating ? "star.fill" : "star")
                            .foregroundColor(.yellow).font(.caption2)
                    }
                }
            }
            Text(review.content)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.85))
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(review.vibeTags, id: \.self) { tag in
                        Text(tag)
                            .font(.caption2.bold())
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(Color(hex: "2a2a4a"))
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(14)
        .background(Color(hex: "1a1a2e"))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Invite Sheet
struct InvitePartnerSheet: View {
    let place: Place
    @Environment(\.dismiss) private var dismiss
    private let users = AppUser.sampleData

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0f0f1a").ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 10) {
                        Text("Rủ ai đi \(place.emoji) \(place.name)?")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.top)

                        ForEach(users) { user in
                            HStack {
                                Circle()
                                    .fill(LinearGradient(colors: user.gradient,
                                                         startPoint: .topLeading,
                                                         endPoint: .bottomTrailing))
                                    .frame(width: 50, height: 50)
                                    .overlay(Text(user.emoji).font(.title3))
                                VStack(alignment: .leading) {
                                    Text(user.name).font(.subheadline.bold()).foregroundColor(.white)
                                    Text("\(user.vibeScore)% Vibe Match").font(.caption2).foregroundColor(.gray)
                                }
                                Spacer()
                                Button("Mời") { dismiss() }
                                    .font(.caption.bold())
                                    .padding(.horizontal, 14).padding(.vertical, 8)
                                    .background(Color(hex: "6C5CE7"))
                                    .foregroundColor(.white)
                                    .clipShape(Capsule())
                            }
                            .padding(12)
                            .background(Color(hex: "1a1a2e"))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Mời đi cùng")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Đóng") { dismiss() }.foregroundColor(.white)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
