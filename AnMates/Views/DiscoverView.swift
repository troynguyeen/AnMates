import SwiftUI

struct DiscoverView: View {
    @State private var selectedMood: Mood? = nil
    @State private var places = Place.sampleData
    @State private var currentIndex = 0
    @State private var dragOffset = CGSize.zero
    @State private var showMatchAlert = false
    @State private var matchedPlace: Place? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0f0f1a").ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Khám phá")
                                .font(.title.bold())
                                .foregroundStyle(.white)
                            Text("TP. Hồ Chí Minh · Hôm nay")
                                .font(.caption)
                                .foregroundColor(Color(hex: "a29bfe"))
                        }
                        Spacer()
                        Button {
                        } label: {
                            Image(systemName: "slider.horizontal.3")
                                .foregroundColor(.white)
                                .padding(10)
                                .background(Color(hex: "1a1a2e"))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)

                    // Mood selector
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(Mood.allCases, id: \.self) { mood in
                                MoodChip(mood: mood, isSelected: selectedMood == mood) {
                                    withAnimation(.spring()) {
                                        selectedMood = selectedMood == mood ? nil : mood
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 12)
                    }

                    // Swipe cards
                    if currentIndex < places.count {
                        ZStack {
                            ForEach(Array(places.enumerated().reversed()), id: \.element.id) { i, place in
                                if i >= currentIndex && i < currentIndex + 3 {
                                    PlaceCard(place: place)
                                        .offset(x: i == currentIndex ? dragOffset.width : 0,
                                                y: i == currentIndex ? dragOffset.height * 0.2 : CGFloat(i - currentIndex) * 8)
                                        .scaleEffect(i == currentIndex ? 1.0 : max(0.92, 1.0 - CGFloat(i - currentIndex) * 0.04))
                                        .rotationEffect(.degrees(i == currentIndex ? Double(dragOffset.width) / 20 : 0))
                                        .zIndex(Double(places.count - i))
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
                        HStack(spacing: 28) {
                            ActionButton(icon: "xmark", color: Color(hex: "e17055"), size: 52) {
                                swipeLeft()
                            }
                            ActionButton(icon: "star.fill", color: Color(hex: "fdcb6e"), size: 44) {
                            }
                            ActionButton(icon: "heart.fill", color: Color(hex: "6C5CE7"), size: 52) {
                                swipeRight()
                            }
                        }
                        .padding(.top, 16)
                        .padding(.bottom, 8)
                    } else {
                        Spacer()
                        VStack(spacing: 12) {
                            Text("🎉")
                                .font(.system(size: 64))
                            Text("Bạn đã xem hết!")
                                .font(.title3.bold())
                                .foregroundColor(.white)
                            Text("Kéo xuống để tải thêm địa điểm")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Button("Xem lại") {
                                withAnimation { currentIndex = 0 }
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 10)
                            .background(Color(hex: "6C5CE7"))
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                        }
                        Spacer()
                    }
                }
            }
        }
        .overlay {
            if showMatchAlert, let place = matchedPlace {
                LikedToast(place: place)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation { showMatchAlert = false }
                        }
                    }
            }
        }
        .animation(.spring(), value: showMatchAlert)
    }

    private func handleSwipe(_ translation: CGSize) {
        let threshold: CGFloat = 100
        if translation.width > threshold {
            swipeRight()
        } else if translation.width < -threshold {
            swipeLeft()
        } else {
            withAnimation(.spring()) { dragOffset = .zero }
        }
    }

    private func swipeRight() {
        withAnimation(.spring()) {
            dragOffset = CGSize(width: 500, height: 0)
        }
        matchedPlace = places[currentIndex]
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            currentIndex += 1
            dragOffset = .zero
            withAnimation { showMatchAlert = true }
        }
    }

    private func swipeLeft() {
        withAnimation(.spring()) {
            dragOffset = CGSize(width: -500, height: 0)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            currentIndex += 1
            dragOffset = .zero
        }
    }
}

// MARK: - Subviews

struct MoodChip: View {
    let mood: Mood
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(mood.emoji)
                Text(mood.rawValue)
                    .font(.caption.bold())
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? mood.color.opacity(0.3) : Color(hex: "1a1a2e"))
            .foregroundColor(isSelected ? mood.color : .gray)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isSelected ? mood.color : Color.clear, lineWidth: 1.5)
            )
        }
    }
}

struct PlaceCard: View {
    let place: Place

    var body: some View {
        RoundedRectangle(cornerRadius: 24)
            .fill(
                LinearGradient(colors: place.gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .frame(height: 420)
            .overlay(alignment: .bottomLeading) {
                VStack(alignment: .leading, spacing: 8) {
                    // Vibe tags
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(place.vibeTags, id: \.self) { tag in
                                Text(tag)
                                    .font(.caption2.bold())
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Capsule())
                            }
                        }
                    }

                    Text(place.emoji + " " + place.name)
                        .font(.title2.bold())
                        .foregroundColor(.white)

                    HStack(spacing: 12) {
                        Label(String(format: "%.1f", place.rating), systemImage: "star.fill")
                            .foregroundColor(.yellow)
                        Text("·")
                        Text(place.priceRange)
                        Text("·")
                        Label(place.distance, systemImage: "location.fill")
                    }
                    .font(.caption.bold())
                    .foregroundColor(.white.opacity(0.9))

                    Text(place.address)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))

                    HStack(spacing: 12) {
                        Button {
                        } label: {
                            Label("Đi ngay", systemImage: "arrow.triangle.turn.up.right.circle.fill")
                                .font(.caption.bold())
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(.white)
                                .foregroundColor(place.gradient.first ?? .purple)
                                .clipShape(Capsule())
                        }

                        Button {
                        } label: {
                            Label("Rủ ai đi?", systemImage: "person.2.fill")
                                .font(.caption.bold())
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(.ultraThinMaterial)
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding(20)
            }
            .shadow(color: (place.gradient.first ?? .purple).opacity(0.4), radius: 20, y: 10)
    }
}

struct ActionButton: View {
    let icon: String
    let color: Color
    let size: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size * 0.4, weight: .bold))
                .foregroundColor(color)
                .frame(width: size, height: size)
                .background(color.opacity(0.15))
                .clipShape(Circle())
                .overlay(Circle().stroke(color.opacity(0.3), lineWidth: 1.5))
        }
    }
}

struct LikedToast: View {
    let place: Place

    var body: some View {
        HStack(spacing: 10) {
            Text("❤️")
            Text("Đã lưu \(place.name)!")
                .font(.subheadline.bold())
                .foregroundColor(.white)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            LinearGradient(colors: place.gradient, startPoint: .leading, endPoint: .trailing)
        )
        .clipShape(Capsule())
        .shadow(radius: 10)
        .padding(.top, 60)
        .frame(maxHeight: .infinity, alignment: .top)
    }
}
