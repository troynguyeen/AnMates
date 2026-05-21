import SwiftUI

struct DiningGroupView: View {
    let place: Place?
    @Environment(\.dismiss) private var dismiss

    @State private var groupName: String = ""
    @State private var members: [AppUser] = [AppUser.sampleData[0]]   // you
    @State private var selectedMood: Mood = .hungry
    @State private var scheduledTime: Date = Calendar.current.date(byAdding: .hour, value: 3, to: Date()) ?? Date()
    @State private var notes: String = ""
    @State private var showAISuggest = false
    @State private var showCreated = false

    private let maxMembers = 4

    init(place: Place? = nil) {
        self.place = place
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0f0f1a").ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {

                        // Place card (if any)
                        if let place = place {
                            HStack(spacing: 12) {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(LinearGradient(colors: place.gradient,
                                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 56, height: 56)
                                    .overlay(Text(place.emoji).font(.title2))
                                VStack(alignment: .leading) {
                                    Text(place.name).font(.subheadline.bold()).foregroundColor(.white)
                                    Text(place.address).font(.caption).foregroundColor(.gray).lineLimit(1)
                                }
                                Spacer()
                            }
                            .padding(12)
                            .background(Color(hex: "1a1a2e"))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }

                        // Group name
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Tên nhóm").font(.headline.bold()).foregroundColor(.white)
                            TextField("Ví dụ: Tối nay ăn lẩu 🍲", text: $groupName)
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color(hex: "1a1a2e"))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        // Members
                        HStack {
                            Text("Thành viên (\(members.count)/\(maxMembers))")
                                .font(.headline.bold())
                                .foregroundColor(.white)
                            Spacer()
                            if members.count < maxMembers {
                                Text("Còn \(maxMembers - members.count) chỗ")
                                    .font(.caption.bold())
                                    .padding(.horizontal, 10).padding(.vertical, 4)
                                    .background(Color(hex: "00b894").opacity(0.2))
                                    .foregroundColor(Color(hex: "00b894"))
                                    .clipShape(Capsule())
                            } else {
                                Text("Đầy")
                                    .font(.caption.bold())
                                    .padding(.horizontal, 10).padding(.vertical, 4)
                                    .background(Color(hex: "e17055").opacity(0.2))
                                    .foregroundColor(Color(hex: "e17055"))
                                    .clipShape(Capsule())
                            }
                        }

                        // Member slots
                        HStack(spacing: 12) {
                            ForEach(0..<maxMembers, id: \.self) { idx in
                                MemberSlot(user: idx < members.count ? members[idx] : nil,
                                           isYou: idx == 0,
                                           onRemove: idx > 0 && idx < members.count ? {
                                    withAnimation { members.remove(at: idx) }
                                } : nil)
                            }
                        }

                        // Suggest members
                        Text("Mời từ Matches gần đây")
                            .font(.caption.bold())
                            .foregroundColor(.gray)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(AppUser.sampleData.filter { u in
                                    !members.contains(where: { $0.id == u.id })
                                }) { user in
                                    Button {
                                        guard members.count < maxMembers else { return }
                                        withAnimation { members.append(user) }
                                    } label: {
                                        VStack(spacing: 6) {
                                            Circle()
                                                .fill(LinearGradient(colors: user.gradient,
                                                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                                                .frame(width: 54, height: 54)
                                                .overlay(Text(user.emoji).font(.title3))
                                                .overlay(alignment: .topTrailing) {
                                                    Image(systemName: "plus.circle.fill")
                                                        .foregroundColor(Color(hex: "00b894"))
                                                        .background(Circle().fill(.black))
                                                        .offset(x: 4, y: -4)
                                                }
                                            Text(user.name.split(separator: " ").first.map(String.init) ?? user.name)
                                                .font(.caption2)
                                                .foregroundColor(.white)
                                        }
                                    }
                                    .disabled(members.count >= maxMembers)
                                    .opacity(members.count >= maxMembers ? 0.4 : 1)
                                }
                            }
                        }

                        // Mood
                        Text("Mood nhóm").font(.headline.bold()).foregroundColor(.white)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(Mood.allCases, id: \.self) { m in
                                    Button {
                                        selectedMood = m
                                    } label: {
                                        HStack(spacing: 4) {
                                            Text(m.emoji)
                                            Text(m.rawValue).font(.caption.bold())
                                        }
                                        .padding(.horizontal, 12).padding(.vertical, 8)
                                        .background(selectedMood == m ? m.color.opacity(0.3) : Color(hex: "1a1a2e"))
                                        .foregroundColor(selectedMood == m ? m.color : .gray)
                                        .clipShape(Capsule())
                                    }
                                }
                            }
                        }

                        // Time
                        Text("Giờ hẹn").font(.headline.bold()).foregroundColor(.white)
                        DatePicker("", selection: $scheduledTime, in: Date()...,
                                   displayedComponents: [.date, .hourAndMinute])
                            .labelsHidden()
                            .datePickerStyle(.compact)
                            .colorScheme(.dark)
                            .padding(12)
                            .background(Color(hex: "1a1a2e"))
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        // Notes
                        Text("Ghi chú").font(.headline.bold()).foregroundColor(.white)
                        TextField("Ai có dị ứng gì? Có cần đặt bàn trước không?",
                                  text: $notes, axis: .vertical)
                            .foregroundColor(.white)
                            .padding(12)
                            .lineLimit(2...4)
                            .background(Color(hex: "1a1a2e"))
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        // AI suggest button
                        Button {
                            showAISuggest = true
                        } label: {
                            HStack {
                                Image(systemName: "sparkles")
                                Text("Để AI gợi ý món cho nhóm").font(.subheadline.bold())
                                Spacer()
                                Image(systemName: "chevron.right")
                            }
                            .foregroundColor(.white)
                            .padding(14)
                            .background(LinearGradient(colors: [Color(hex: "00b894"), Color(hex: "00cec9")],
                                                       startPoint: .leading, endPoint: .trailing))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }

                        // Notification toggle hint
                        HStack {
                            Image(systemName: "bell.fill").foregroundColor(Color(hex: "fdcb6e"))
                            Text("Mọi người sẽ nhận thông báo khi có người tham gia hoặc rời nhóm.")
                                .font(.caption).foregroundColor(.gray)
                        }
                        .padding(12)
                        .background(Color(hex: "1a1a2e"))
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                        // Create button
                        Button {
                            showCreated = true
                        } label: {
                            HStack {
                                Image(systemName: "person.3.fill")
                                Text("Tạo nhóm & Thông báo")
                            }
                            .font(.headline.bold())
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(16)
                            .background(LinearGradient(colors: [Color(hex: "6C5CE7"), Color(hex: "a29bfe")],
                                                       startPoint: .leading, endPoint: .trailing))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .disabled(groupName.isEmpty || members.count < 2)
                        .opacity((groupName.isEmpty || members.count < 2) ? 0.5 : 1)
                    }
                    .padding()
                }
            }
            .navigationTitle("Tạo Nhóm Đi Ăn")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Huỷ") { dismiss() }.foregroundColor(.white)
                }
            }
            .sheet(isPresented: $showAISuggest) {
                AIFoodSuggestionView(place: place, groupSize: members.count, mood: selectedMood)
            }
            .alert("Đã tạo nhóm! 🎉", isPresented: $showCreated) {
                Button("OK") { dismiss() }
            } message: {
                Text("\(members.count) thành viên sẽ nhận thông báo. Hẹn nhau lúc \(formatTime(scheduledTime)) nhé!")
            }
        }
    }

    private func formatTime(_ d: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "HH:mm dd/MM"; return f.string(from: d)
    }
}

struct MemberSlot: View {
    let user: AppUser?
    let isYou: Bool
    let onRemove: (() -> Void)?

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 4) {
                if let user = user {
                    Circle()
                        .fill(LinearGradient(colors: user.gradient,
                                             startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 54, height: 54)
                        .overlay(Text(user.emoji).font(.title3))
                    Text(isYou ? "Bạn" : (user.name.split(separator: " ").first.map(String.init) ?? user.name))
                        .font(.caption2).foregroundColor(.white).lineLimit(1)
                } else {
                    Circle()
                        .stroke(Color(hex: "2a2a4a"), style: StrokeStyle(lineWidth: 2, dash: [4]))
                        .frame(width: 54, height: 54)
                        .overlay(Image(systemName: "plus").foregroundColor(.gray))
                    Text("Trống").font(.caption2).foregroundColor(.gray)
                }
            }
            .frame(maxWidth: .infinity)
            if let onRemove = onRemove {
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                        .background(Circle().fill(.black))
                }
                .offset(x: -4, y: -4)
            }
        }
    }
}
