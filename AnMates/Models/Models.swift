import Foundation
import SwiftUI

// MARK: - Place Model
struct Place: Identifiable {
    let id = UUID()
    let name: String
    let category: PlaceCategory
    let emoji: String
    let rating: Double
    let priceRange: String
    let distance: String
    let address: String
    let vibeTags: [String]
    let gradient: [Color]
    var isLiked: Bool = false
}

enum PlaceCategory: String, CaseIterable {
    case food = "Ăn uống"
    case cafe = "Cà phê"
    case bar = "Bar & Nightlife"
    case cinema = "Xem phim"
    case karaoke = "Karaoke"
    case spa = "Spa & Wellness"
    case outdoor = "Ngoài trời"
}

enum Mood: String, CaseIterable {
    case hungry = "Đói bụng"
    case chill = "Chill"
    case active = "Năng động"
    case relax = "Thư giãn"
    case party = "Party"

    var emoji: String {
        switch self {
        case .hungry: return "🍜"
        case .chill: return "☕"
        case .active: return "🎮"
        case .relax: return "🌿"
        case .party: return "🎉"
        }
    }

    var color: Color {
        switch self {
        case .hungry: return .orange
        case .chill: return .blue
        case .active: return .green
        case .relax: return .mint
        case .party: return .purple
        }
    }
}

// MARK: - User/Profile Model
struct AppUser: Identifiable {
    let id = UUID()
    let name: String
    let age: Int
    let occupation: String
    let bio: String
    let emoji: String
    let vibeTags: [String]
    let vibeScore: Int
    var isMatched: Bool = false
    let gradient: [Color]
}

// MARK: - Chat Models
struct ChatMessage: Identifiable {
    let id = UUID()
    let senderId: String
    let content: String
    let type: MessageType
    let timestamp: Date
    var viewOnceState: ViewOnceState = .na

    enum MessageType {
        case text, viewOnce, emoji
    }

    enum ViewOnceState {
        case na, unseen, seen
    }
}

struct ChatConversation: Identifiable {
    let id = UUID()
    let user: AppUser
    var lastMessage: String
    var lastTime: String
    var unreadCount: Int
    var messages: [ChatMessage]
}

// MARK: - Sample Data
extension Place {
    static let sampleData: [Place] = [
        Place(
            name: "Astra Rooftop Bar",
            category: .bar,
            emoji: "🌃",
            rating: 4.8,
            priceRange: "300-500k",
            distance: "0.8km",
            address: "123 Nguyễn Huệ, Q.1",
            vibeTags: ["Romantic 💕", "Instagrammable 📸", "Lively 🎉"],
            gradient: [Color(hex: "6C5CE7"), Color(hex: "a29bfe")]
        ),
        Place(
            name: "Ramen House Saigon",
            category: .food,
            emoji: "🍜",
            rating: 4.6,
            priceRange: "100-200k",
            distance: "1.2km",
            address: "45 Lê Lợi, Q.1",
            vibeTags: ["Cozy 🤫", "Foodie 🍜", "Local 🏠"],
            gradient: [Color(hex: "e17055"), Color(hex: "fdcb6e")]
        ),
        Place(
            name: "Chill Corner Cafe",
            category: .cafe,
            emoji: "☕",
            rating: 4.5,
            priceRange: "50-150k",
            distance: "0.5km",
            address: "78 Bùi Viện, Q.1",
            vibeTags: ["Quiet 🤫", "Work-friendly 💻", "Aesthetic 📸"],
            gradient: [Color(hex: "00b894"), Color(hex: "55efc4")]
        ),
        Place(
            name: "Galaxy Karaoke VIP",
            category: .karaoke,
            emoji: "🎤",
            rating: 4.3,
            priceRange: "200-400k",
            distance: "2.1km",
            address: "99 Trần Hưng Đạo, Q.5",
            vibeTags: ["Lively 🎉", "Group 👥", "Fun 🎵"],
            gradient: [Color(hex: "fd79a8"), Color(hex: "e84393")]
        ),
        Place(
            name: "Zen Spa & Wellness",
            category: .spa,
            emoji: "🧘",
            rating: 4.9,
            priceRange: "400-700k",
            distance: "1.5km",
            address: "12 Đồng Khởi, Q.1",
            vibeTags: ["Relaxing 🌿", "Premium ✨", "Quiet 🤫"],
            gradient: [Color(hex: "00cec9"), Color(hex: "81ecec")]
        ),
        Place(
            name: "CGV Cinema Vincom",
            category: .cinema,
            emoji: "🎬",
            rating: 4.4,
            priceRange: "100-200k",
            distance: "0.3km",
            address: "Vincom Center, Q.1",
            vibeTags: ["Date 💕", "Chill ☕", "Indoor 🏢"],
            gradient: [Color(hex: "2d3436"), Color(hex: "636e72")]
        ),
    ]
}

extension AppUser {
    static let sampleData: [AppUser] = [
        AppUser(
            name: "Linh Nguyễn",
            age: 24,
            occupation: "UI/UX Designer",
            bio: "Thích khám phá quán cà phê mới, mê chụp ảnh và ăn ramen 🍜 Tìm bạn đi chill cuối tuần!",
            emoji: "👩‍🎨",
            vibeTags: ["☕ Coffee Addict", "📸 Photographer", "🍜 Foodie", "🎵 Music Lover"],
            vibeScore: 92,
            gradient: [Color(hex: "fd79a8"), Color(hex: "6C5CE7")]
        ),
        AppUser(
            name: "Minh Trần",
            age: 27,
            occupation: "Software Engineer",
            bio: "Code by day, game by night 🎮 Muốn tìm teammate đi ăn sau giờ làm. Thích khám phá ẩm thực đường phố.",
            emoji: "👨‍💻",
            vibeTags: ["🎮 Gamer", "🍕 Foodie", "☕ Coffee", "🌏 Explorer"],
            vibeScore: 85,
            gradient: [Color(hex: "00b894"), Color(hex: "00cec9")]
        ),
        AppUser(
            name: "Hà Phạm",
            age: 23,
            occupation: "Marketing Executive",
            bio: "Yêu âm nhạc và sống về đêm 🌃 Hay đi bar, rooftop, live music. DM nếu muốn chill cùng!",
            emoji: "👩‍💼",
            vibeTags: ["🎵 Music Lover", "🍺 Social", "🌃 Night Owl", "📸 Insta"],
            vibeScore: 78,
            gradient: [Color(hex: "fdcb6e"), Color(hex: "e17055")]
        ),
        AppUser(
            name: "Khoa Lê",
            age: 26,
            occupation: "Freelancer",
            bio: "Traveler & coffee lover ✈️ Đang sống ở Sài Gòn, tìm bạn khám phá hidden gems của thành phố.",
            emoji: "🧑‍🚀",
            vibeTags: ["🌏 Traveler", "☕ Coffee", "📚 Bookworm", "🏃 Active"],
            vibeScore: 88,
            gradient: [Color(hex: "a29bfe"), Color(hex: "6C5CE7")]
        ),
    ]
}

extension ChatConversation {
    static let sampleData: [ChatConversation] = [
        ChatConversation(
            user: AppUser.sampleData[0],
            lastMessage: "Tối nay mày có rảnh không? 😊",
            lastTime: "20:17",
            unreadCount: 2,
            messages: [
                ChatMessage(senderId: "other", content: "Ê! Tối nay mày có rảnh không? 😊", type: .text, timestamp: Date()),
                ChatMessage(senderId: "me", content: "Rảnh nè! Định đi đâu không?", type: .text, timestamp: Date()),
                ChatMessage(senderId: "other", content: "Tao đang ở Rooftop Bar A, view đẹp lắm 🌃", type: .text, timestamp: Date()),
                ChatMessage(senderId: "other", content: "", type: .viewOnce, timestamp: Date(), viewOnceState: .unseen),
                ChatMessage(senderId: "me", content: "Wow gửi ảnh đi xem nào! 👀", type: .text, timestamp: Date()),
            ]
        ),
        ChatConversation(
            user: AppUser.sampleData[1],
            lastMessage: "Ảnh đã xem",
            lastTime: "18:30",
            unreadCount: 0,
            messages: [
                ChatMessage(senderId: "other", content: "Có muốn đi ăn tối không?", type: .text, timestamp: Date()),
                ChatMessage(senderId: "me", content: "Ok đi! Quán nào?", type: .text, timestamp: Date()),
                ChatMessage(senderId: "other", content: "", type: .viewOnce, timestamp: Date(), viewOnceState: .seen),
            ]
        ),
        ChatConversation(
            user: AppUser.sampleData[2],
            lastMessage: "Cuối tuần party nhé 🎉",
            lastTime: "Hôm qua",
            unreadCount: 1,
            messages: [
                ChatMessage(senderId: "other", content: "Cuối tuần party nhé 🎉", type: .text, timestamp: Date()),
            ]
        ),
    ]
}

// MARK: - Color extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255, opacity: Double(a)/255)
    }
}
