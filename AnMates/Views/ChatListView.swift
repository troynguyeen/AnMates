import SwiftUI

struct ChatListView: View {
    @State private var conversations = ChatConversation.sampleData
    @State private var searchText = ""
    @State private var selectedConversation: ChatConversation? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0f0f1a").ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("AnMates Chat")
                                .font(.title.bold())
                                .foregroundStyle(.white)
                            Text("\(conversations.filter { $0.unreadCount > 0 }.count) tin chưa đọc")
                                .font(.caption)
                                .foregroundColor(Color(hex: "a29bfe"))
                        }
                        Spacer()
                        Button {
                        } label: {
                            Image(systemName: "square.and.pencil")
                                .foregroundColor(.white)
                                .padding(10)
                                .background(Color(hex: "1a1a2e"))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)

                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Tìm cuộc trò chuyện...", text: $searchText)
                            .foregroundColor(.white)
                    }
                    .padding(12)
                    .background(Color(hex: "1a1a2e"))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal)
                    .padding(.vertical, 12)

                    // Stories row
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 14) {
                            // Add story button
                            VStack(spacing: 4) {
                                ZStack {
                                    Circle()
                                        .fill(Color(hex: "1a1a2e"))
                                        .frame(width: 60, height: 60)
                                    Image(systemName: "plus")
                                        .foregroundColor(Color(hex: "6C5CE7"))
                                        .font(.title2)
                                }
                                .overlay(
                                    Circle()
                                        .stroke(Color(hex: "6C5CE7"), lineWidth: 2)
                                )
                                Text("Story")
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                            }

                            ForEach(conversations) { conv in
                                VStack(spacing: 4) {
                                    Circle()
                                        .fill(LinearGradient(colors: conv.user.gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                                        .frame(width: 60, height: 60)
                                        .overlay(Text(conv.user.emoji).font(.title2))
                                        .overlay(
                                            Circle()
                                                .stroke(
                                                    LinearGradient(colors: conv.user.gradient, startPoint: .topLeading, endPoint: .bottomTrailing),
                                                    lineWidth: 2.5
                                                )
                                                .padding(-3)
                                        )
                                    Text(conv.user.name.components(separatedBy: " ").last ?? conv.user.name)
                                        .font(.caption2)
                                        .foregroundColor(.white)
                                        .lineLimit(1)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 12)

                    // Divider
                    Divider()
                        .background(Color(hex: "2a2a4a"))

                    // Conversations list
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(conversations) { conv in
                                NavigationLink(destination: ChatDetailView(conversation: conv)) {
                                    ConversationRow(conversation: conv)
                                }
                                .buttonStyle(.plain)

                                Divider()
                                    .background(Color(hex: "1a1a2e"))
                                    .padding(.leading, 76)
                            }
                        }
                    }
                }
            }
        }
    }
}

struct ConversationRow: View {
    let conversation: ChatConversation

    var body: some View {
        HStack(spacing: 14) {
            // Avatar
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(LinearGradient(colors: conversation.user.gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 52, height: 52)
                    .overlay(Text(conversation.user.emoji).font(.title3))

                Circle()
                    .fill(Color(hex: "00b894"))
                    .frame(width: 12, height: 12)
                    .overlay(Circle().stroke(Color(hex: "0f0f1a"), lineWidth: 2))
            }

            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(conversation.user.name)
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                    Spacer()
                    Text(conversation.lastTime)
                        .font(.caption2)
                        .foregroundColor(.gray)
                }

                HStack {
                    Text(conversation.lastMessage)
                        .font(.caption)
                        .foregroundColor(conversation.unreadCount > 0 ? .white.opacity(0.85) : .gray)
                        .lineLimit(1)
                    Spacer()
                    if conversation.unreadCount > 0 {
                        Text("\(conversation.unreadCount)")
                            .font(.caption2.bold())
                            .foregroundColor(.white)
                            .frame(width: 18, height: 18)
                            .background(Color(hex: "6C5CE7"))
                            .clipShape(Circle())
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(Color(hex: "0f0f1a"))
    }
}
