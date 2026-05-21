import SwiftUI

struct SafetyMenuView: View {
    let targetName: String
    @Environment(\.dismiss) private var dismiss
    @State private var showReport = false
    @State private var showBlockConfirm = false
    @State private var showSOSConfirm = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0f0f1a").ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 12) {

                        // SOS - top priority
                        Button {
                            showSOSConfirm = true
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.title2).foregroundColor(.white)
                                    .padding(12)
                                    .background(.red)
                                    .clipShape(Circle())
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("SOS Khẩn cấp").font(.headline.bold()).foregroundColor(.white)
                                    Text("Gọi 113 + gửi vị trí cho người thân")
                                        .font(.caption).foregroundColor(.white.opacity(0.85))
                                }
                                Spacer()
                            }
                            .padding(14)
                            .background(LinearGradient(colors: [.red, Color(hex: "e17055")],
                                                       startPoint: .leading, endPoint: .trailing))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }

                        // Share location
                        SafetyOption(icon: "location.fill.viewfinder",
                                     iconColor: Color(hex: "00b894"),
                                     title: "Chia sẻ vị trí real-time",
                                     subtitle: "Người thân có thể theo dõi vị trí khi bạn đi gặp") {}

                        // Meeting point
                        SafetyOption(icon: "mappin.and.ellipse",
                                     iconColor: Color(hex: "0984e3"),
                                     title: "Gặp ở nơi công cộng",
                                     subtitle: "Xem gợi ý điểm hẹn an toàn") {}

                        // Verify
                        SafetyOption(icon: "checkmark.seal.fill",
                                     iconColor: Color(hex: "fdcb6e"),
                                     title: "Xác minh người dùng",
                                     subtitle: "Đã verify selfie · Trust Score 85") {}

                        Divider().background(Color(hex: "2a2a4a")).padding(.vertical, 8)

                        // Report
                        Button {
                            showReport = true
                        } label: {
                            SafetyOptionContent(
                                icon: "flag.fill",
                                iconColor: Color(hex: "fdcb6e"),
                                title: "Báo cáo \(targetName)",
                                subtitle: "Quấy rối, spam, profile giả...",
                                showChevron: true)
                        }

                        // Block
                        Button {
                            showBlockConfirm = true
                        } label: {
                            SafetyOptionContent(
                                icon: "hand.raised.fill",
                                iconColor: .red,
                                title: "Chặn \(targetName)",
                                subtitle: "Không nhận được tin nhắn từ người này",
                                showChevron: true)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("An toàn")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Đóng") { dismiss() }.foregroundColor(.white)
                }
            }
            .alert("Gọi SOS?", isPresented: $showSOSConfirm) {
                Button("Huỷ", role: .cancel) {}
                Button("Gọi ngay", role: .destructive) { callEmergency() }
            } message: {
                Text("Sẽ gọi 113 và gửi vị trí hiện tại cho danh sách người thân.")
            }
            .alert("Chặn \(targetName)?", isPresented: $showBlockConfirm) {
                Button("Huỷ", role: .cancel) {}
                Button("Chặn", role: .destructive) { dismiss() }
            } message: {
                Text("Bạn sẽ không thấy hoặc nhận tin nhắn từ người này nữa.")
            }
            .sheet(isPresented: $showReport) {
                ReportSheet(targetName: targetName)
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func callEmergency() {
        if let url = URL(string: "tel://113") {
            UIApplication.shared.open(url)
        }
    }
}

struct SafetyOption: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            SafetyOptionContent(icon: icon, iconColor: iconColor,
                                title: title, subtitle: subtitle, showChevron: true)
        }
    }
}

struct SafetyOptionContent: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let showChevron: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3).foregroundColor(iconColor)
                .frame(width: 40, height: 40)
                .background(iconColor.opacity(0.15))
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.bold()).foregroundColor(.white)
                Text(subtitle).font(.caption).foregroundColor(.gray)
            }
            Spacer()
            if showChevron {
                Image(systemName: "chevron.right").foregroundColor(.gray).font(.caption)
            }
        }
        .padding(14)
        .background(Color(hex: "1a1a2e"))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

struct ReportSheet: View {
    let targetName: String
    @Environment(\.dismiss) private var dismiss
    @State private var selectedReason: String?
    @State private var details: String = ""
    @State private var submitted = false

    private let reasons = [
        "Quấy rối hoặc đe doạ",
        "Spam, quảng cáo",
        "Profile giả mạo, hình ảnh giả",
        "Nội dung không phù hợp",
        "Hành vi lừa đảo",
        "Khác"
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0f0f1a").ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Lý do báo cáo")
                            .font(.headline.bold())
                            .foregroundColor(.white)
                        ForEach(reasons, id: \.self) { r in
                            Button {
                                selectedReason = r
                            } label: {
                                HStack {
                                    Image(systemName: selectedReason == r ? "largecircle.fill.circle" : "circle")
                                        .foregroundColor(selectedReason == r ? Color(hex: "fd79a8") : .gray)
                                    Text(r).font(.subheadline).foregroundColor(.white)
                                    Spacer()
                                }
                                .padding(14)
                                .background(Color(hex: "1a1a2e"))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                        Text("Mô tả thêm (tuỳ chọn)").font(.headline.bold()).foregroundColor(.white).padding(.top, 8)
                        TextField("Mô tả chi tiết để chúng tôi xử lý nhanh hơn",
                                  text: $details, axis: .vertical)
                            .foregroundColor(.white)
                            .padding(12)
                            .lineLimit(3...6)
                            .background(Color(hex: "1a1a2e"))
                            .clipShape(RoundedRectangle(cornerRadius: 14))

                        Button {
                            submitted = true
                        } label: {
                            Text("Gửi báo cáo")
                                .font(.headline.bold())
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity).padding(16)
                                .background(Color(hex: "fd79a8"))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .disabled(selectedReason == nil)
                        .opacity(selectedReason == nil ? 0.5 : 1)
                    }
                    .padding()
                }
            }
            .navigationTitle("Báo cáo \(targetName)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Huỷ") { dismiss() }.foregroundColor(.white)
                }
            }
            .alert("Đã gửi báo cáo ✅", isPresented: $submitted) {
                Button("Đóng") { dismiss() }
            } message: {
                Text("Cảm ơn bạn. Đội ngũ sẽ xử lý trong 24h.")
            }
        }
    }
}
