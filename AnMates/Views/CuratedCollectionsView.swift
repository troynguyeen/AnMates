import SwiftUI

struct CuratedCollectionsView: View {
    @Environment(\.dismiss) private var dismiss
    private let collections = CuratedCollection.samples
    @State private var selected: CuratedCollection?

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0f0f1a").ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 14) {
                        // Featured big card
                        if let first = collections.first {
                            FeaturedCard(collection: first) { selected = first }
                        }

                        // Grid of others
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                            ForEach(collections.dropFirst()) { c in
                                Button {
                                    selected = c
                                } label: {
                                    CollectionCard(collection: c)
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Bộ sưu tập")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Đóng") { dismiss() }.foregroundColor(.white)
                }
            }
            .sheet(item: $selected) { c in
                CollectionDetailView(collection: c)
            }
        }
    }
}

struct FeaturedCard: View {
    let collection: CuratedCollection
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: 20)
                    .fill(LinearGradient(colors: collection.gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(height: 180)
                    .overlay(
                        Text(collection.emoji)
                            .font(.system(size: 100))
                            .opacity(0.3)
                            .offset(x: 80, y: -20)
                    )
                VStack(alignment: .leading, spacing: 4) {
                    Text("✨ Editor's Pick")
                        .font(.caption2.bold())
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .foregroundColor(.white)
                    Text(collection.title).font(.title3.bold()).foregroundColor(.white)
                    Text(collection.subtitle).font(.caption).foregroundColor(.white.opacity(0.85))
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.circle.fill")
                        Text("\(collection.placeCount) địa điểm")
                    }
                    .font(.caption.bold())
                    .foregroundColor(.white)
                    .padding(.top, 4)
                }
                .padding(16)
            }
        }
    }
}

struct CollectionCard: View {
    let collection: CuratedCollection

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 16)
                .fill(LinearGradient(colors: collection.gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(height: 160)
                .overlay(
                    Text(collection.emoji)
                        .font(.system(size: 70))
                        .opacity(0.4)
                        .offset(x: 30, y: -15)
                )
            VStack(alignment: .leading, spacing: 2) {
                Text(collection.title).font(.subheadline.bold()).foregroundColor(.white).lineLimit(2)
                Text("\(collection.placeCount) địa điểm")
                    .font(.caption2.bold())
                    .foregroundColor(.white.opacity(0.85))
            }
            .padding(12)
        }
    }
}

// Detail
struct CollectionDetailView: View {
    let collection: CuratedCollection
    @Environment(\.dismiss) private var dismiss
    private let places = Place.sampleData

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0f0f1a").ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 12) {
                        // Header card
                        RoundedRectangle(cornerRadius: 20)
                            .fill(LinearGradient(colors: collection.gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(height: 140)
                            .overlay(alignment: .leading) {
                                HStack {
                                    Text(collection.emoji).font(.system(size: 60))
                                    VStack(alignment: .leading) {
                                        Text(collection.title).font(.title3.bold()).foregroundColor(.white)
                                        Text(collection.subtitle).font(.caption).foregroundColor(.white.opacity(0.85))
                                    }
                                }
                                .padding()
                            }

                        // Places
                        ForEach(places) { place in
                            NavigationLink {
                                PlaceDetailView(place: place)
                            } label: {
                                HStack(spacing: 12) {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(LinearGradient(colors: place.gradient,
                                                             startPoint: .topLeading, endPoint: .bottomTrailing))
                                        .frame(width: 64, height: 64)
                                        .overlay(Text(place.emoji).font(.title2))
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(place.name).font(.subheadline.bold()).foregroundColor(.white)
                                        HStack(spacing: 6) {
                                            Image(systemName: "star.fill").foregroundColor(.yellow)
                                            Text(String(format: "%.1f", place.rating))
                                            Text("·")
                                            Text(place.priceRange)
                                            Text("·")
                                            Text(place.distance)
                                        }
                                        .font(.caption).foregroundColor(.gray)
                                        Text(place.address).font(.caption2).foregroundColor(.gray).lineLimit(1)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right").foregroundColor(.gray)
                                }
                                .padding(12)
                                .background(Color(hex: "1a1a2e"))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle(collection.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Đóng") { dismiss() }.foregroundColor(.white)
                }
            }
        }
    }
}
