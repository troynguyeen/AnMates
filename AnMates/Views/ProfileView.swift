import SwiftUI

struct ProfileView: View {
    @State private var vibePoints = 1240
    @State private var checkins = 12
    @State private var matches = 8
    @State private var reviews = 5

    let badges: [(emoji: String, name: String, unlocked: Bool)] = [
        ("🍜", "Foodie Explorer", true),
        ("🦋", "Social Butterfly", true),
        ("🌙", "Night Owl", false),
        ("💎", "Hidden Gem Hunter", false),
        ("⭐", "Super Reviewer", true),
        ("🔥", "Streak Master", false),
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0f0f1a").ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {

                        // Profile hero
                        ZStack(alignment: .bottom) {
                            // Background gradient
                            RoundedRectangle(cornerRadius: 28)
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "6C5CE7"), Color(hex: "fd79a8")],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(height: 220)

                            // Decorative circles
                            Circle()
                                .fill(.white.opacity(0.05))
                                .frame(width: 180, height: 180)
                                .offset(x: 80, y: -60)

                            Circle()
                                .fill(.white.opacity(0.05))
                                .frame(width: 120, height: 120)
                                .offset(x: -90, y: -20)

                            VStack(spacing: 10) {
                                // Avatar
                                ZStack {
                                    Circle()
                                        .fill(.white.opacity(0.2))
                                        .frame(width: 80, height: 80)
                                    Text("🙋")
                                        .font(.system(size: 44))
                                }
                                .overlay(
                                    Circle()
                                        .stroke(.white.opacity(0.4), lineWidth: 3)
                                )

                                VStack(spacing: 4) {
                                    HStack(spacing: 6) {
                                        Text("Bạn ơi")
                                            .font(.title3.bold())
                                            .foregroundColor(.white)
                                        Image(systemName: "checkmark.seal.fill")
                                            .foregroundColor(.yellow)
                                    }
                                    Text("UX Designer · TP.HCM")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.8))
                                }
                            }
                            .padding(.bottom, 20)
                        }
                        .padding(.horizontal)

                        // Stats row
                        HStack(spacing: 0) {
                            StatItem(value: "\(checkins)", label: "Check-ins")
                            Divider().background(Color(hex: "2a2a4a")).frame(height: 40)
                            StatItem(value: "\(matches)", label: "Matches")
                            Divider().background(Color(hex: "2a2a4a")).frame(height: 40)
                            StatItem(value: "\(reviews)", label: "Reviews")
                        }
                        .padding(.vertical, 16)
                        .background(Color(hex: "1a1a2e"))
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .padding(.horizontal)

                        // AnPoints card
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                HStack(spacing: 8) {
                                    Image(systemName: "bolt.fill")
                                        .foregroundColor(.yellow)
                                    Text("AnPoints")
                                        .font(.headline.bold())
                                        .foregroundColor(.white)
                                }
                                Spacer()
                                Text("\(vibePoints) pts")
                                    .font(.title3.bold())
                                    .foregroundStyle(
                                        LinearGradient(colors: [Color(hex: "fdcb6e"), Color(hex: "e17055")], startPoint: .leading, endPoint: .trailing)
                                    )
                            }

                            // Progress to next reward
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text("Còn \(2000 - vibePoints) pts để đổi Voucher 50k")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    Spacer()
                                    Text("Lv.3")
                                        .font(.caption.bold())
                                        .foregroundColor(Color(hex: "fdcb6e"))
                                }

                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color(hex: "2a2a4a"))
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(
                                                LinearGradient(colors: [Color(hex: "fdcb6e"), Color(hex: "e17055")], startPoint: .leading, endPoint: .trailing)
                                            )
                                            .frame(width: geo.size.width * CGFloat(vibePoints) / 2000.0)
                                    }
                                }
                                .frame(height: 8)
                            }

                            // Quick earn actions
                            HStack(spacing: 10) {
                                QuickEarnButton(emoji: "📍", label: "Check-in", pts: "+50")
                                QuickEarnButton(emoji: "⭐", label: "Review", pts: "+30")
                                QuickEarnButton(emoji: "👥", label: "Invite", pts: "+100")
                            }
                        }
                        .padding(18)
                        .background(Color(hex: "1a1a2e"))
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .padding(.horizontal)

                        // Vibe Tags
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Vibe Tags của bạn")
                                .font(.headline.bold())
                                .foregroundColor(.white)

                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                                ForEach(["☕ Coffee Addict", "📸 Photography", "🍜 Foodie", "🎵 Music", "🌏 Traveler", "🎮 Gamer"], id: \.self) { tag in
                                    Text(tag)
                                        .font(.caption.bold())
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 8)
                                        .frame(maxWidth: .infinity)
                                        .background(Color(hex: "6C5CE7").opacity(0.2))
                                        .foregroundColor(Color(hex: "a29bfe"))
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: "6C5CE7").opacity(0.4), lineWidth: 1))
                                }
                            }
                        }
                        .padding(18)
                        .background(Color(hex: "1a1a2e"))
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .padding(.horizontal)

                        // Badges
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                Text("Thành tích")
                                    .font(.headline.bold())
                                    .foregroundColor(.white)
                                Spacer()
                                Text("\(badges.filter { $0.unlocked }.count)/\(badges.count)")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }

                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                                ForEach(badges, id: \.name) { badge in
                                    BadgeItem(emoji: badge.emoji, name: badge.name, unlocked: badge.unlocked)
                                }
                            }
                        }
                        .padding(18)
                        .background(Color(hex: "1a1a2e"))
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .padding(.horizontal)

                        // Premium banner
                        HStack(spacing: 14) {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(spacing: 6) {
                                    Image(systemName: "crown.fill")
                                        .foregroundColor(.yellow)
                                    Text("AnMates+")
                                        .font(.headline.bold())
                                        .foregroundColor(.white)
                                }
                                Text("Unlimited swipes · See who liked you · Ad-free")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.75))
                            }
                            Spacer()
                            Button {
                            } label: {
                                Text("Nâng cấp")
                                    .font(.caption.bold())
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(.white)
                                    .foregroundColor(Color(hex: "6C5CE7"))
                                    .clipShape(Capsule())
                            }
                        }
                        .padding(18)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "6C5CE7"), Color(hex: "fd79a8")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .padding(.horizontal)

                        // Settings
                        VStack(spacing: 0) {
                            ForEach([
                                ("person.fill", "Chỉnh sửa hồ sơ"),
                                ("shield.fill", "Quyền riêng tư & An toàn"),
                                ("bell.fill", "Thông báo"),
                                ("creditcard.fill", "Thanh toán"),
                                ("questionmark.circle.fill", "Trợ giúp"),
                            ], id: \.1) { icon, label in
                                HStack {
                                    Image(systemName: icon)
                                        .foregroundColor(Color(hex: "a29bfe"))
                                        .frame(width: 24)
                                    Text(label)
                                        .font(.subheadline)
                                        .foregroundColor(.white)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray)
                                        .font(.caption)
                                }
                                .padding(.horizontal, 18)
                                .padding(.vertical, 14)

                                if label != "Trợ giúp" {
                                    Divider().background(Color(hex: "2a2a4a")).padding(.leading, 56)
                                }
                            }
                        }
                        .background(Color(hex: "1a1a2e"))
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .padding(.horizontal)
                        .padding(.bottom, 32)
                    }
                    .padding(.top, 8)
                }
            }
            .navigationTitle("Hồ sơ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color(hex: "0f0f1a"), for: .navigationBar)
        }
    }
}

struct StatItem: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(
                    LinearGradient(colors: [Color(hex: "6C5CE7"), Color(hex: "fd79a8")], startPoint: .leading, endPoint: .trailing)
                )
            Text(label)
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
    }
}

struct QuickEarnButton: View {
    let emoji: String
    let label: String
    let pts: String

    var body: some View {
        VStack(spacing: 4) {
            Text(emoji)
                .font(.title3)
            Text(label)
                .font(.caption2)
                .foregroundColor(.white)
            Text(pts)
                .font(.caption2.bold())
                .foregroundColor(Color(hex: "fdcb6e"))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color(hex: "2a2a4a"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct BadgeItem: View {
    let emoji: String
    let name: String
    let unlocked: Bool

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(unlocked ? Color(hex: "6C5CE7").opacity(0.2) : Color(hex: "2a2a4a"))
                    .frame(width: 54, height: 54)
                Text(emoji)
                    .font(.title2)
                    .opacity(unlocked ? 1.0 : 0.3)
                if !unlocked {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.gray)
                        .font(.caption)
                        .offset(x: 14, y: 14)
                }
            }
            Text(name)
                .font(.caption2)
                .foregroundColor(unlocked ? .white : .gray)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
