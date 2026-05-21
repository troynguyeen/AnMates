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
    // Detailed info
    var phone: String = "+84 28 3822 1234"
    var openingHours: String = "09:00 - 23:00"
    var reviewCount: Int = 128
    var detailDescription: String = "Một địa điểm tuyệt vời với không gian ấm cúng, phù hợp cho cả hẹn hò lẫn đi cùng bạn bè."
    var reviews: [PlaceReview] = PlaceReview.sampleReviews
}

// MARK: - Review Model
struct PlaceReview: Identifiable {
    let id = UUID()
    let authorName: String
    let authorEmoji: String
    let rating: Int
    let content: String
    let timeAgo: String
    let vibeTags: [String]

    static let sampleReviews: [PlaceReview] = [
        PlaceReview(authorName: "Linh N.", authorEmoji: "👩‍🎨", rating: 5,
                    content: "View đẹp, đồ uống ngon, không gian instagram-able cực! Sẽ quay lại 💕",
                    timeAgo: "2 ngày trước", vibeTags: ["Romantic 💕", "Instagrammable 📸"]),
        PlaceReview(authorName: "Minh T.", authorEmoji: "👨‍💻", rating: 4,
                    content: "Đồ ăn ok, giá hợp lý. Buổi tối hơi đông, nên đặt trước.",
                    timeAgo: "5 ngày trước", vibeTags: ["Foodie 🍜", "Lively 🎉"]),
        PlaceReview(authorName: "Hà P.", authorEmoji: "👩‍💼", rating: 5,
                    content: "Phục vụ nhiệt tình, nhạc hay, không gian chill 🌃",
                    timeAgo: "1 tuần trước", vibeTags: ["Chill ☕", "Music 🎵"]),
    ]
}

// MARK: - Scheduled Date (Đặt lịch hẹn)
struct ScheduledDate: Identifiable {
    let id = UUID()
    let place: Place
    let partner: AppUser
    var date: Date
    var note: String
    var reminderMinutesBefore: Int = 60
}

// MARK: - Dining Group (Tạo Nhóm Đi Ăn)
struct DiningGroup: Identifiable {
    let id = UUID()
    var name: String
    var place: Place?
    var members: [AppUser]
    var maxMembers: Int = 4
    var scheduledTime: Date
    var mood: Mood
    var notes: String = ""
    var isJoined: Bool = false

    var isFull: Bool { members.count >= maxMembers }
    var slotsLeft: Int { maxMembers - members.count }
}

// MARK: - AI Food Suggestion
struct FoodSuggestion: Identifiable {
    let id = UUID()
    let name: String
    let emoji: String
    let priceLevel: String   // "Thấp", "Trung bình"
    let estimatedPrice: String
    let matchScore: Int      // 0-100
    let reason: String
    let suitableFor: Int     // số người phù hợp

    static func suggestions(forGroupSize size: Int, mood: Mood) -> [FoodSuggestion] {
        let all: [FoodSuggestion] = [
            FoodSuggestion(name: "Lẩu Thái chua cay", emoji: "🍲", priceLevel: "Trung bình",
                           estimatedPrice: "200-300k/người", matchScore: 95,
                           reason: "Hoàn hảo cho nhóm \(size) người, hợp mood ấm áp", suitableFor: 4),
            FoodSuggestion(name: "Bún Bò Huế", emoji: "🍜", priceLevel: "Thấp",
                           estimatedPrice: "60-90k/người", matchScore: 88,
                           reason: "Đậm đà, hợp khẩu vị Việt, giá rẻ", suitableFor: 2),
            FoodSuggestion(name: "BBQ Hàn Quốc", emoji: "🥩", priceLevel: "Trung bình",
                           estimatedPrice: "250-400k/người", matchScore: 92,
                           reason: "Phù hợp nhóm, không khí vui vẻ", suitableFor: 4),
            FoodSuggestion(name: "Sushi Combo", emoji: "🍣", priceLevel: "Trung bình",
                           estimatedPrice: "180-280k/người", matchScore: 85,
                           reason: "Sang trọng vừa phải, hợp date 2 người", suitableFor: 2),
            FoodSuggestion(name: "Pizza & Pasta", emoji: "🍕", priceLevel: "Thấp",
                           estimatedPrice: "120-180k/người", matchScore: 80,
                           reason: "Dễ chia sẻ, hợp nhóm bạn", suitableFor: 4),
            FoodSuggestion(name: "Phở", emoji: "🍜", priceLevel: "Thấp",
                           estimatedPrice: "50-80k/người", matchScore: 78,
                           reason: "Đơn giản, ngon, giá rẻ", suitableFor: 2),
        ]
        return all.filter { $0.suitableFor == size || size == 4 }
                  .sorted { $0.matchScore > $1.matchScore }
    }
}

// MARK: - Curated Collection
struct CuratedCollection: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let emoji: String
    let gradient: [Color]
    let placeCount: Int

    static let samples: [CuratedCollection] = [
        CuratedCollection(title: "Date Night dưới 500k", subtitle: "Lãng mạn không tốn nhiều ❤️", emoji: "💕",
                          gradient: [Color(hex: "fd79a8"), Color(hex: "6C5CE7")], placeCount: 12),
        CuratedCollection(title: "Rooftop Bars Sài Gòn", subtitle: "View cực đỉnh về đêm 🌃", emoji: "🌃",
                          gradient: [Color(hex: "2d3436"), Color(hex: "6C5CE7")], placeCount: 8),
        CuratedCollection(title: "Hidden Gems Quận 1", subtitle: "Ít người biết, chất lượng 💎", emoji: "💎",
                          gradient: [Color(hex: "00cec9"), Color(hex: "0984e3")], placeCount: 15),
        CuratedCollection(title: "Cafe làm việc cả ngày", subtitle: "Wifi tốt, ổ cắm nhiều ☕", emoji: "☕",
                          gradient: [Color(hex: "00b894"), Color(hex: "55efc4")], placeCount: 20),
        CuratedCollection(title: "Trời mưa thì đi đâu?", subtitle: "Indoor, ấm cúng 🌧️", emoji: "🌧️",
                          gradient: [Color(hex: "636e72"), Color(hex: "74b9ff")], placeCount: 10),
    ]
}

// MARK: - Smart Filter
struct PlaceFilter {
    var distance: Double = 5.0          // km
    var maxPrice: Double = 500          // nghìn VND
    var minRating: Double = 4.0
    var openNow: Bool = false
    var suitableFor: String = "Mọi người"

    static let suitableOptions = ["Mọi người", "1 người", "Nhóm bạn", "Date 💕", "Gia đình"]
}

// MARK: - Theme Manager (Adaptive Theme)
enum ThemeMode: String, CaseIterable {
    case sunriseAmber, oceanBlue, sunsetOrange, midnight, purplePink, emeraldGreen

    var displayName: String {
        switch self {
        case .sunriseAmber: return "Sunrise Amber"
        case .oceanBlue:    return "Ocean Blue"
        case .sunsetOrange: return "Sunset Orange"
        case .midnight:     return "Midnight"
        case .purplePink:   return "Purple Pink"
        case .emeraldGreen: return "Emerald Green"
        }
    }

    var emoji: String {
        switch self {
        case .sunriseAmber: return "🌅"
        case .oceanBlue:    return "☀️"
        case .sunsetOrange: return "🌆"
        case .midnight:     return "🌙"
        case .purplePink:   return "🌃"
        case .emeraldGreen: return "🌿"
        }
    }

    var accent: Color {
        switch self {
        case .sunriseAmber: return Color(hex: "fdcb6e")
        case .oceanBlue:    return Color(hex: "0984e3")
        case .sunsetOrange: return Color(hex: "e17055")
        case .midnight:     return Color(hex: "6C5CE7")
        case .purplePink:   return Color(hex: "fd79a8")
        case .emeraldGreen: return Color(hex: "00b894")
        }
    }

    static func forCurrentHour(_ hour: Int = Calendar.current.component(.hour, from: Date())) -> ThemeMode {
        switch hour {
        case 6..<11:  return .sunriseAmber
        case 11..<17: return .oceanBlue
        case 17..<20: return .sunsetOrange
        case 20..<24: return .purplePink
        default:      return .midnight
        }
    }
}

final class ThemeManager: ObservableObject {
    @Published var mode: ThemeMode = ThemeMode.forCurrentHour()
    @Published var isLocked: Bool = false

    func refreshIfNeeded() {
        guard !isLocked else { return }
        mode = ThemeMode.forCurrentHour()
    }

    func override(_ newMode: ThemeMode, lock: Bool = true) {
        mode = newMode
        isLocked = lock
    }
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
