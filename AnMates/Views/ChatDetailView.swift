import SwiftUI

struct ChatDetailView: View {
    let conversation: ChatConversation

    @State private var messages: [ChatMessage]
    @State private var inputText = ""
    @State private var showViewOnceViewer = false
    @State private var viewerMessageId: UUID? = nil
    @State private var viewerCountdown = 8
    @State private var viewerTimer: Timer? = nil

    init(conversation: ChatConversation) {
        self.conversation = conversation
        _messages = State(initialValue: conversation.messages)
    }

    var body: some View {
        ZStack {
            Color(hex: "0f0f1a").ignoresSafeArea()

            VStack(spacing: 0) {
                // Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 4) {
                            ForEach(messages) { message in
                                MessageBubbleView(
                                    message: message,
                                    isMe: message.senderId == "me",
                                    onViewOnceTap: { openViewOnce(messageId: message.id) }
                                )
                                .id(message.id)
                            }
                        }
                        .padding(.vertical, 12)
                    }
                    .onChange(of: messages.count) {
                        if let last = messages.last {
                            withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                        }
                    }
                }

                // Input bar
                VStack(spacing: 0) {
                    Divider().background(Color(hex: "2a2a4a"))

                    HStack(spacing: 10) {
                        // View Once button
                        Button {
                            sendViewOnce()
                        } label: {
                            ZStack(alignment: .topTrailing) {
                                Image(systemName: "camera.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundStyle(
                                        LinearGradient(colors: [Color(hex: "6C5CE7"), Color(hex: "fd79a8")], startPoint: .topLeading, endPoint: .bottomTrailing)
                                    )
                                Circle()
                                    .fill(Color(hex: "fd79a8"))
                                    .frame(width: 8, height: 8)
                                    .offset(x: 2, y: -2)
                            }
                        }

                        Button {
                        } label: {
                            Image(systemName: "paperclip")
                                .font(.system(size: 20))
                                .foregroundColor(.gray)
                        }

                        // Text field
                        TextField("Nhắn tin...", text: $inputText)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(Color(hex: "1a1a2e"))
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 22))
                            .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color(hex: "2a2a4a"), lineWidth: 1))

                        Button {
                            sendText()
                        } label: {
                            Image(systemName: inputText.isEmpty ? "mic.fill" : "paperplane.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 38, height: 38)
                                .background(
                                    LinearGradient(colors: [Color(hex: "6C5CE7"), Color(hex: "fd79a8")], startPoint: .topLeading, endPoint: .bottomTrailing)
                                )
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color(hex: "0f0f1a"))
                }
            }
        }
        .navigationTitle(conversation.user.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color(hex: "0f0f1a"), for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(LinearGradient(colors: conversation.user.gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 34, height: 34)
                        .overlay(Text(conversation.user.emoji).font(.caption))
                    VStack(alignment: .leading, spacing: 1) {
                        Text(conversation.user.name)
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                        Text("Đang hoạt động")
                            .font(.caption2)
                            .foregroundColor(Color(hex: "00b894"))
                    }
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 14) {
                    Button { } label: {
                        Image(systemName: "phone.fill")
                            .foregroundColor(Color(hex: "a29bfe"))
                    }
                    Button { } label: {
                        Image(systemName: "video.fill")
                            .foregroundColor(Color(hex: "a29bfe"))
                    }
                }
            }
        }
        // VIEW ONCE FULLSCREEN OVERLAY
        .overlay {
            if showViewOnceViewer, let msgId = viewerMessageId,
               let idx = messages.firstIndex(where: { $0.id == msgId }) {
                ViewOnceViewerOverlay(
                    user: conversation.user,
                    countdown: viewerCountdown,
                    onClose: { closeViewOnce(messageIndex: idx) }
                )
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: showViewOnceViewer)
    }

    private func sendText() {
        guard !inputText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let msg = ChatMessage(senderId: "me", content: inputText, type: .text, timestamp: Date())
        withAnimation { messages.append(msg) }
        inputText = ""
    }

    private func sendViewOnce() {
        let msg = ChatMessage(senderId: "me", content: "📸 Ảnh xem 1 lần", type: .viewOnce, timestamp: Date(), viewOnceState: .unseen)
        withAnimation { messages.append(msg) }
    }

    private func openViewOnce(messageId: UUID) {
        guard let idx = messages.firstIndex(where: { $0.id == messageId }),
              messages[idx].senderId != "me",
              messages[idx].viewOnceState == .unseen else { return }
        viewerMessageId = messageId
        viewerCountdown = 8
        showViewOnceViewer = true

        viewerTimer?.invalidate()
        viewerTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            viewerCountdown -= 1
            if viewerCountdown <= 0 {
                viewerTimer?.invalidate()
                closeViewOnce(messageIndex: idx)
            }
        }
    }

    private func closeViewOnce(messageIndex: Int) {
        viewerTimer?.invalidate()
        showViewOnceViewer = false
        viewerMessageId = nil
        if messageIndex < messages.count {
            messages[messageIndex].viewOnceState = .seen
        }
    }
}

// MARK: - Message Bubble View
struct MessageBubbleView: View {
    let message: ChatMessage
    let isMe: Bool
    let onViewOnceTap: () -> Void

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isMe { Spacer(minLength: 60) }

            VStack(alignment: isMe ? .trailing : .leading, spacing: 2) {
                switch message.type {
                case .text:
                    TextBubble(text: message.content, isMe: isMe, time: timeString(message.timestamp))

                case .viewOnce:
                    ViewOnceBubble(
                        isMe: isMe,
                        state: message.viewOnceState,
                        time: timeString(message.timestamp),
                        onTap: onViewOnceTap
                    )

                case .emoji:
                    Text(message.content)
                        .font(.system(size: 44))
                }
            }

            if !isMe { Spacer(minLength: 60) }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 2)
    }

    private func timeString(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: date)
    }
}

struct TextBubble: View {
    let text: String
    let isMe: Bool
    let time: String

    var body: some View {
        VStack(alignment: isMe ? .trailing : .leading, spacing: 2) {
            Text(text)
                .font(.subheadline)
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    isMe
                    ? AnyView(LinearGradient(colors: [Color(hex: "6C5CE7"), Color(hex: "fd79a8")], startPoint: .topLeading, endPoint: .bottomTrailing))
                    : AnyView(Color(hex: "1e1e35"))
                )
                .clipShape(
                    RoundedRectangle(cornerRadius: 18)
                )

            Text(time)
                .font(.caption2)
                .foregroundColor(.gray)
                .padding(.horizontal, 4)
        }
    }
}

// MARK: - View Once Bubble
struct ViewOnceBubble: View {
    let isMe: Bool
    let state: ChatMessage.ViewOnceState
    let time: String
    let onTap: () -> Void

    var body: some View {
        VStack(alignment: isMe ? .trailing : .leading, spacing: 4) {
            switch state {
            case .unseen:
                // Chưa xem
                Button(action: isMe ? {} : onTap) {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "6C5CE7").opacity(0.3), Color(hex: "fd79a8").opacity(0.3)],
                                        startPoint: .topLeading, endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 44, height: 44)
                            Image(systemName: isMe ? "arrow.up.circle.fill" : "eye.circle.fill")
                                .font(.system(size: 22))
                                .foregroundStyle(
                                    LinearGradient(colors: [Color(hex: "6C5CE7"), Color(hex: "fd79a8")], startPoint: .topLeading, endPoint: .bottomTrailing)
                                )
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(isMe ? "Đã gửi ảnh 1 lần" : "Ảnh xem 1 lần")
                                .font(.subheadline.bold())
                                .foregroundColor(.white)
                            Text(isMe ? "Đang chờ xem..." : "Nhấn để mở • Xem 1 lần duy nhất")
                                .font(.caption2)
                                .foregroundColor(Color(hex: "a29bfe"))
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color(hex: "1e1e35"))
                            .overlay(
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(
                                        LinearGradient(colors: [Color(hex: "6C5CE7"), Color(hex: "fd79a8")], startPoint: .leading, endPoint: .trailing),
                                        lineWidth: 1.5
                                    )
                            )
                    )
                }
                .disabled(isMe)

            case .seen:
                // Đã xem
                HStack(spacing: 10) {
                    Image(systemName: "lock.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.gray.opacity(0.5))
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Ảnh đã xem")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        Text("Không thể mở lại")
                            .font(.caption2)
                            .foregroundColor(.gray.opacity(0.6))
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color(hex: "1a1a2e"))
                        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color(hex: "2a2a4a"), lineWidth: 1))
                )

            case .na:
                EmptyView()
            }

            HStack(spacing: 4) {
                Text(time)
                    .font(.caption2)
                    .foregroundColor(.gray)
                if isMe && state == .unseen {
                    Image(systemName: "checkmark")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, 4)
        }
    }
}

// MARK: - View Once Viewer Overlay
struct ViewOnceViewerOverlay: View {
    let user: AppUser
    let countdown: Int
    let onClose: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.95).ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar
                HStack {
                    Circle()
                        .fill(LinearGradient(colors: user.gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 36, height: 36)
                        .overlay(Text(user.emoji).font(.subheadline))

                    VStack(alignment: .leading, spacing: 1) {
                        Text(user.name)
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                        Text("Ảnh xem 1 lần")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                            .padding(10)
                            .background(.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
                .padding()

                Spacer()

                // Photo placeholder (gradient art)
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: user.gradient + [Color(hex: "0f0f1a")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 320, height: 380)
                    .overlay {
                        VStack(spacing: 16) {
                            Text(user.emoji)
                                .font(.system(size: 72))
                            Text("📍 Đang ở một nơi đẹp lắm!")
                                .font(.subheadline.bold())
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .shadow(color: (user.gradient.first ?? .purple).opacity(0.5), radius: 30)

                Spacer()

                // Timer bar
                VStack(spacing: 8) {
                    // Warning
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(Color(hex: "fdcb6e"))
                            .font(.caption)
                        Text("\(user.name) sẽ biết nếu bạn chụp màn hình")
                            .font(.caption)
                            .foregroundColor(Color(hex: "fdcb6e"))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color(hex: "fdcb6e").opacity(0.1))
                    .clipShape(Capsule())

                    HStack {
                        Image(systemName: "timer")
                            .foregroundColor(.gray)
                            .font(.caption)
                        Text("Biến mất sau \(countdown) giây")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Spacer()
                        Text("Chỉ xem 1 lần")
                            .font(.caption2)
                            .foregroundColor(.gray.opacity(0.6))
                    }
                    .padding(.horizontal, 32)

                    // Progress bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white.opacity(0.1))
                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "6C5CE7"), Color(hex: "fd79a8")],
                                        startPoint: .leading, endPoint: .trailing
                                    )
                                )
                                .frame(width: geo.size.width * CGFloat(countdown) / 8.0)
                                .animation(.linear(duration: 1), value: countdown)
                        }
                        .frame(height: 4)
                    }
                    .frame(height: 4)
                    .padding(.horizontal, 32)

                    Button("Đóng ngay", action: onClose)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding(.bottom, 8)
                }
                .padding(.bottom, 32)
            }
        }
    }
}
