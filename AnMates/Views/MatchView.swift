import SwiftUI

struct MatchView: View {
    @State private var users = AppUser.sampleData
    @State private var currentIndex = 0
    @State private var dragOffset = CGSize.zero
    @State private var showMatchOverlay = false
    @State private var matchedUser: AppUser? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0f0f1a").ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Match & Meet")
                                .font(.title.bold())
                                .foregroundStyle(.white)
                            Text("Tìm người đồng hành")
                                .font(.caption)
                                .foregroundColor(Color(hex: "fd79a8"))
                        }
                        Spacer()
                        Button {
                        } label: {
                            Image(systemName: "flame.fill")
                                .foregroundColor(Color(hex: "fd79a8"))
                                .padding(10)
                                .background(Color(hex: "fd79a8").opacity(0.15))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 8)

                    // Matching modes
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(["🎲 Random Vibe", "🎯 Activity", "👥 Group", "💕 Date"], id: \.self) { mode in
                                Text(mode)
                                    .font(.caption.bold())
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(mode == "🎲 Random Vibe" ? Color(hex: "6C5CE7").opacity(0.3) : Color(hex: "1a1a2e"))
                                    .foregroundColor(mode == "🎲 Random Vibe" ? Color(hex: "a29bfe") : .gray)
                                    .clipShape(Capsule())
                                    .overlay(Capsule().stroke(mode == "🎲 Random Vibe" ? Color(hex: "6C5CE7") : .clear, lineWidth: 1.5))
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 12)

                    // User cards
                    if currentIndex < users.count {
                        ZStack {
                            ForEach(Array(users.enumerated().reversed()), id: \.element.id) { i, user in
                                if i >= currentIndex && i < currentIndex + 3 {
                                    UserCard(user: user)
                                        .offset(x: i == currentIndex ? dragOffset.width : 0,
                                                y: i == currentIndex ? dragOffset.height * 0.15 : CGFloat(i - currentIndex) * 10)
                                        .scaleEffect(i == currentIndex ? 1.0 : max(0.90, 1.0 - CGFloat(i - currentIndex) * 0.05))
                                        .rotationEffect(.degrees(i == currentIndex ? Double(dragOffset.width) / 18 : 0))
                                        .zIndex(Double(users.count - i))
                                        .overlay(alignment: .topLeading) {
                                            if i == currentIndex && dragOffset.width > 40 {
                                                Text("💕 LIKE")
                                                    .font(.title2.bold())
                                                    .foregroundColor(.green)
                                                    .padding(12)
                                                    .background(.green.opacity(0.2))
                                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                                    .rotationEffect(.degrees(-20))
                                                    .padding(28)
                                                    .opacity(Double(dragOffset.width / 100))
                                            }
                                        }
                                        .overlay(alignment: .topTrailing) {
                                            if i == currentIndex && dragOffset.width < -40 {
                                                Text("NOPE ❌")
                                                    .font(.title2.bold())
                                                    .foregroundColor(.red)
                                                    .padding(12)
                                                    .background(.red.opacity(0.2))
                                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                                    .rotationEffect(.degrees(20))
                                                    .padding(28)
                                                    .opacity(Double(-dragOffset.width / 100))
                                            }
                                        }
                                        .gesture(
                                            i == currentIndex ?
                                            DragGesture()
                                                .onChanged { v in dragOffset = v.translation }
                                                .onEnded { v in handleSwipe(v.translation) }
                                            : nil
                                        )
                                        .animation(.spring(response: 0.4), value: dragOffset)
                                }
                            }
                        }
                        .padding(.horizontal)

                        // Action buttons
                        HStack(spacing: 32) {
                            ActionButton(icon: "xmark", color: Color(hex: "e17055"), size: 56) {
                                swipeCard(liked: false)
                            }
                            ActionButton(icon: "bolt.fill", color: Color(hex: "fdcb6e"), size: 44) {
                            }
                            ActionButton(icon: "heart.fill", color: Color(hex: "fd79a8"), size: 56) {
                                swipeCard(liked: true)
                            }
                        }
                        .padding(.top, 16)
                        .padding(.bottom, 8)
                    } else {
                        Spacer()
                        VStack(spacing: 12) {
                            Text("✨")
                                .font(.system(size: 64))
                            Text("Hết người rồi!")
                                .font(.title3.bold())
                                .foregroundColor(.white)
                            Text("Quay lại sau để xem người mới")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Button("Xem lại") {
                                withAnimation { currentIndex = 0 }
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 10)
                            .background(LinearGradient(colors: [Color(hex: "6C5CE7"), Color(hex: "fd79a8")], startPoint: .leading, endPoint: .trailing))
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                        }
                        Spacer()
                    }
                }
            }
            // Match overlay
            .overlay {
                if showMatchOverlay, let user = matchedUser {
                    MatchSuccessOverlay(user: user) {
                        withAnimation { showMatchOverlay = false }
                    }
                    .transition(.opacity)
                }
            }
            .animation(.easeInOut, value: showMatchOverlay)
        }
    }

    private func handleSwipe(_ translation: CGSize) {
        let threshold: CGFloat = 100
        if translation.width > threshold {
            swipeCard(liked: true)
        } else if translation.width < -threshold {
            swipeCard(liked: false)
        } else {
            withAnimation(.spring()) { dragOffset = .zero }
        }
    }

    private func swipeCard(liked: Bool) {
        withAnimation(.spring()) {
            dragOffset = CGSize(width: liked ? 600 : -600, height: 0)
        }
        if liked {
            matchedUser = users[currentIndex]
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            currentIndex += 1
            dragOffset = .zero
            if liked {
                withAnimation { showMatchOverlay = true }
            }
        }
    }
}

// MARK: - User Card
struct UserCard: View {
    let user: AppUser

    var body: some View {
        RoundedRectangle(cornerRadius: 24)
            .fill(LinearGradient(colors: user.gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
            .frame(height: 440)
            .overlay(alignment: .center) {
                Text(user.emoji)
                    .font(.system(size: 80))
                    .shadow(radius: 10)
            }
            .overlay(alignment: .bottomLeading) {
                VStack(alignment: .leading, spacing: 8) {
                    // Vibe score
                    HStack {
                        Spacer()
                        HStack(spacing: 4) {
                            Image(systemName: "bolt.fill")
                                .foregroundColor(.yellow)
                            Text("\(user.vibeScore)% Match")
                                .font(.caption.bold())
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                    }

                    Text("\(user.name), \(user.age)")
                        .font(.title2.bold())
                        .foregroundColor(.white)

                    Text(user.occupation)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.85))

                    Text(user.bio)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(2)

                    // Vibe tags
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(user.vibeTags, id: \.self) { tag in
                                Text(tag)
                                    .font(.caption2.bold())
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Capsule())
                                    .foregroundColor(.white)
                            }
                        }
                    }
                }
                .padding(20)
            }
            .shadow(color: (user.gradient.first ?? .purple).opacity(0.4), radius: 20, y: 10)
    }
}

// MARK: - Match Success Overlay
struct MatchSuccessOverlay: View {
    let user: AppUser
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.9).ignoresSafeArea()

            VStack(spacing: 24) {
                Text("🎉")
                    .font(.system(size: 80))

                Text("It's a Match!")
                    .font(.largeTitle.bold())
                    .foregroundStyle(
                        LinearGradient(colors: [Color(hex: "6C5CE7"), Color(hex: "fd79a8")], startPoint: .leading, endPoint: .trailing)
                    )

                HStack(spacing: 20) {
                    Circle()
                        .fill(LinearGradient(colors: [Color(hex: "6C5CE7"), Color(hex: "fd79a8")], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 80, height: 80)
                        .overlay(Text("🙋").font(.system(size: 36)))

                    Image(systemName: "heart.fill")
                        .foregroundColor(Color(hex: "fd79a8"))
                        .font(.title)

                    Circle()
                        .fill(LinearGradient(colors: user.gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 80, height: 80)
                        .overlay(Text(user.emoji).font(.system(size: 36)))
                }

                Text("Bạn và \(user.name) đã match!\nHãy bắt đầu cuộc trò chuyện 💬")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white.opacity(0.85))
                    .font(.subheadline)

                VStack(spacing: 12) {
                    Button {
                        onDismiss()
                    } label: {
                        Text("💬 Nhắn tin ngay")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(LinearGradient(colors: [Color(hex: "6C5CE7"), Color(hex: "fd79a8")], startPoint: .leading, endPoint: .trailing))
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    Button("Tiếp tục xem", action: onDismiss)
                        .foregroundColor(.gray)
                        .font(.subheadline)
                }
                .padding(.horizontal, 32)
            }
        }
    }
}
