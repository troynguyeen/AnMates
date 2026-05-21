import SwiftUI

struct DateSchedulingView: View {
    let place: Place
    @Environment(\.dismiss) private var dismiss

    @State private var selectedDate: Date = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
    @State private var selectedPartner: AppUser? = AppUser.sampleData.first
    @State private var note: String = ""
    @State private var reminderIndex: Int = 1
    @State private var showSuccess = false

    private let reminderOptions = [15, 60, 120, 1440] // minutes
    private let reminderLabels = ["15 phút trước", "1 giờ trước", "2 giờ trước", "1 ngày trước"]

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0f0f1a").ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {

                        // Place card
                        HStack(spacing: 12) {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(LinearGradient(colors: place.gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 60, height: 60)
                                .overlay(Text(place.emoji).font(.title2))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(place.name).font(.subheadline.bold()).foregroundColor(.white)
                                Text(place.address).font(.caption).foregroundColor(.gray).lineLimit(2)
                            }
                            Spacer()
                        }
                        .padding(14)
                        .background(Color(hex: "1a1a2e"))
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                        // Partner
                        Text("Đi cùng ai?")
                            .font(.headline.bold())
                            .foregroundColor(.white)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(AppUser.sampleData) { user in
                                    Button {
                                        selectedPartner = user
                                    } label: {
                                        VStack(spacing: 6) {
                                            Circle()
                                                .fill(LinearGradient(colors: user.gradient,
                                                                     startPoint: .topLeading,
                                                                     endPoint: .bottomTrailing))
                                                .frame(width: 58, height: 58)
                                                .overlay(Text(user.emoji).font(.title3))
                                                .overlay(
                                                    Circle().stroke(
                                                        selectedPartner?.id == user.id ? Color(hex: "fd79a8") : Color.clear,
                                                        lineWidth: 3
                                                    )
                                                )
                                            Text(user.name.split(separator: " ").first.map(String.init) ?? user.name)
                                                .font(.caption2)
                                                .foregroundColor(.white)
                                        }
                                    }
                                }
                            }
                        }

                        // Date & time picker
                        Text("Khi nào?")
                            .font(.headline.bold())
                            .foregroundColor(.white)
                        DatePicker("", selection: $selectedDate, in: Date()...,
                                   displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(.graphical)
                            .colorScheme(.dark)
                            .accentColor(Color(hex: "6C5CE7"))
                            .padding(12)
                            .background(Color(hex: "1a1a2e"))
                            .clipShape(RoundedRectangle(cornerRadius: 16))

                        // Reminder
                        Text("Nhắc nhở trước")
                            .font(.headline.bold())
                            .foregroundColor(.white)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(0..<reminderOptions.count, id: \.self) { i in
                                    Button {
                                        reminderIndex = i
                                    } label: {
                                        Text(reminderLabels[i])
                                            .font(.caption.bold())
                                            .padding(.horizontal, 14).padding(.vertical, 10)
                                            .background(reminderIndex == i ?
                                                        Color(hex: "6C5CE7") : Color(hex: "1a1a2e"))
                                            .foregroundColor(.white)
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                        }

                        // Note
                        Text("Ghi chú (tuỳ chọn)")
                            .font(.headline.bold())
                            .foregroundColor(.white)
                        TextField("Ví dụ: Đi xem phim trước rồi ăn tối", text: $note, axis: .vertical)
                            .foregroundColor(.white)
                            .padding(12)
                            .lineLimit(3...5)
                            .background(Color(hex: "1a1a2e"))
                            .clipShape(RoundedRectangle(cornerRadius: 14))

                        // Submit
                        Button {
                            scheduleDate()
                        } label: {
                            HStack {
                                Image(systemName: "calendar.badge.checkmark")
                                Text("Xác nhận đặt lịch")
                            }
                            .font(.headline.bold())
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(16)
                            .background(LinearGradient(colors: [Color(hex: "6C5CE7"), Color(hex: "fd79a8")],
                                                       startPoint: .leading, endPoint: .trailing))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .padding(.top, 8)
                    }
                    .padding()
                }
            }
            .navigationTitle("Đặt lịch hẹn")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Huỷ") { dismiss() }.foregroundColor(.white)
                }
            }
            .alert("Đã đặt lịch! 🎉", isPresented: $showSuccess) {
                Button("OK") { dismiss() }
            } message: {
                Text("Sẽ nhắc bạn \(reminderLabels[reminderIndex]) buổi hẹn.")
            }
        }
    }

    private func scheduleDate() {
        // In real app: persist + register UNNotification
        // Mock: trigger success alert
        showSuccess = true
    }
}
