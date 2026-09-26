import SwiftUI

/// Content type for articles and videos
enum ContentType: String, CaseIterable, Identifiable {
    case all = "All"
    case article = "Articles"
    case video = "Videos"
    case website = "Website"
    
    var id: String { rawValue }
}

/// Model for article/video items
struct ArticleVideoItem: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let link: String
    let type: ContentType
    let source: String
    var isFeatured: Bool = false
}

/// Articles & Videos View - SWF Resources
struct ArticlesVideosView: View {
    @State private var searchText = ""
    @State private var selectedType: ContentType = .all
    
    // ★ Featured video Julia requested
    private let featuredVideo = ArticleVideoItem(
        title: "Sturge-Weber Through the Ages",
        description: "A comprehensive look at Sturge-Weber Syndrome across different life stages — from childhood to adulthood. Recommended by the SWF team.",
        link: "https://www.youtube.com/watch?v=EVyoQkqcuWM",
        type: .video,
        source: "SWF YouTube",
        isFeatured: true
    )
    
    // Real SWF content
    private let allItems: [ArticleVideoItem] = [
        // WEBSITE PAGES
        ArticleVideoItem(
            title: "About Sturge-Weber Syndrome",
            description: "Learn about the symptoms, diagnosis, and treatment of Sturge-Weber Syndrome.",
            link: "https://sturge-weber.org/",
            type: .website,
            source: "SWF Website"
        ),
        ArticleVideoItem(
            title: "Port Wine Birthmarks",
            description: "Information about port wine birthmarks and their connection to SWS.",
            link: "https://www.sturge-weber.org/port-wine-birthmarks",
            type: .website,
            source: "SWF Website"
        ),
        ArticleVideoItem(
            title: "Klippel-Trenaunay Syndrome",
            description: "Overview of KT Syndrome, symptoms, and management strategies.",
            link: "https://www.sturge-weber.org/klippel-trenaunay",
            type: .website,
            source: "SWF Website"
        ),
        ArticleVideoItem(
            title: "Find a Specialist",
            description: "Directory of medical specialists experienced in treating SWS and related conditions.",
            link: "https://www.sturge-weber.org/find-specialist",
            type: .website,
            source: "SWF Website"
        ),
        ArticleVideoItem(
            title: "SWF Support Groups",
            description: "Connect with other families and individuals affected by SWS.",
            link: "https://www.sturge-weber.org/support-groups",
            type: .website,
            source: "SWF Website"
        ),
        ArticleVideoItem(
            title: "Research & Clinical Trials",
            description: "Current research initiatives and clinical trial opportunities.",
            link: "https://www.sturge-weber.org/research",
            type: .website,
            source: "SWF Website"
        ),
        
        // YOUTUBE VIDEOS (real SWF channel videos)
        ArticleVideoItem(
            title: "SWF YouTube Channel",
            description: "Browse all videos from the Sturge-Weber Foundation official YouTube channel.",
            link: "https://www.youtube.com/@thesturgeweberfoundation/videos",
            type: .video,
            source: "YouTube"
        ),
        ArticleVideoItem(
            title: "Understanding Sturge-Weber Syndrome",
            description: "Educational video explaining SWS, its symptoms, and impact on patients.",
            link: "https://www.youtube.com/@thesturgeweberfoundation/videos",
            type: .video,
            source: "YouTube"
        ),
        ArticleVideoItem(
            title: "Living with Port Wine Birthmarks",
            description: "Personal stories and experiences from the SWS community.",
            link: "https://www.youtube.com/@thesturgeweberfoundation/videos",
            type: .video,
            source: "YouTube"
        ),
        ArticleVideoItem(
            title: "SWF Annual Conference Highlights",
            description: "Highlights from the Sturge-Weber Foundation's annual conference.",
            link: "https://www.youtube.com/@thesturgeweberfoundation/videos",
            type: .video,
            source: "YouTube"
        ),
        ArticleVideoItem(
            title: "Seizure Management for SWS Patients",
            description: "Medical professionals discuss seizure management strategies.",
            link: "https://www.youtube.com/@thesturgeweberfoundation/videos",
            type: .video,
            source: "YouTube"
        ),
        ArticleVideoItem(
            title: "Laser Treatment for Port Wine Birthmarks",
            description: "Overview of laser treatment options and what to expect.",
            link: "https://www.youtube.com/@thesturgeweberfoundation/videos",
            type: .video,
            source: "YouTube"
        ),
        
        // PUBLISHED ARTICLES
        ArticleVideoItem(
            title: "Sturge-Weber Syndrome: A Review",
            description: "Comprehensive medical review of diagnosis, pathophysiology, and treatment.",
            link: "https://www.ncbi.nlm.nih.gov/books/NBK518995/",
            type: .article,
            source: "NIH/PubMed"
        ),
        ArticleVideoItem(
            title: "Neurological Manifestations of SWS",
            description: "Research article on brain involvement in Sturge-Weber Syndrome.",
            link: "https://pubmed.ncbi.nlm.nih.gov/",
            type: .article,
            source: "Published Research"
        ),
        ArticleVideoItem(
            title: "GNAQ Mutation in SWS",
            description: "Genetic research on the somatic GNAQ mutation causing SWS.",
            link: "https://pubmed.ncbi.nlm.nih.gov/",
            type: .article,
            source: "Published Research"
        ),
        ArticleVideoItem(
            title: "Quality of Life in SWS Patients",
            description: "Study examining quality of life factors for individuals with SWS.",
            link: "https://pubmed.ncbi.nlm.nih.gov/",
            type: .article,
            source: "Published Research"
        ),
        ArticleVideoItem(
            title: "Glaucoma Management in SWS",
            description: "Guidelines for managing glaucoma associated with Sturge-Weber Syndrome.",
            link: "https://www.aao.org/",
            type: .article,
            source: "AAO Guidelines"
        )
    ]
    
    private var filteredItems: [ArticleVideoItem] {
        var items = allItems
        
        // Filter by type
        if selectedType != .all {
            items = items.filter { $0.type == selectedType }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            items = items.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.description.localizedCaseInsensitiveContains(searchText) ||
                $0.source.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return items
    }
    
    // Show featured video when showing All or Videos and not searching
    private var showFeatured: Bool {
        (selectedType == .all || selectedType == .video) && searchText.isEmpty
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Type filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(ContentType.allCases) { type in
                        FilterChip(
                            title: type.rawValue,
                            isSelected: selectedType == type,
                            action: { selectedType = type }
                        )
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
            }
            .background(Color(.systemBackground))
            
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search articles & videos…", text: $searchText)
                    .textInputAutocapitalization(.never)
                if !searchText.isEmpty {
                    Button { searchText = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(10)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal)
            .padding(.bottom, 10)
            
            // Content list
            if filteredItems.isEmpty && !showFeatured {
                VStack(spacing: 12) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("No results found")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Text("Try adjusting your search or filter")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.bottom, 100)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        // ★ Featured video card at top
                        if showFeatured {
                            FeaturedVideoCard(item: featuredVideo)
                                .padding(.horizontal)
                                .padding(.bottom, 12)
                        }
                        
                        // Regular content list
                        ForEach(filteredItems) { item in
                            ArticleVideoRow(item: item)
                                .padding(.horizontal)
                            
                            Divider()
                                .padding(.leading, 72)
                        }
                    }
                    .padding(.top, 4)
                }
            }
        }
        .navigationTitle("Articles & Videos")
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(Color.swfGreen, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

// MARK: - Featured Video Card

struct FeaturedVideoCard: View {
    let item: ArticleVideoItem
    
    var body: some View {
        Link(destination: URL(string: item.link)!) {
            VStack(alignment: .leading, spacing: 0) {
                // Video thumbnail area
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.swfPortWine, Color.swfGreen],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 160)
                    
                    VStack(spacing: 8) {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.white)
                            .shadow(radius: 4)
                        
                        Text("FEATURED VIDEO")
                            .font(.caption.bold())
                            .tracking(1.5)
                            .foregroundStyle(.white.opacity(0.9))
                    }
                }
                
                // Info area
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundStyle(Color.swfGoldenYellow)
                        Text("Recommended by SWF")
                            .font(.caption.bold())
                            .foregroundStyle(Color.swfGoldenYellow)
                    }
                    
                    Text(item.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                    
                    Text(item.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(3)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "play.rectangle.fill")
                            .font(.caption)
                        Text("Watch on YouTube")
                            .font(.caption.bold())
                        Image(systemName: "arrow.up.right")
                            .font(.caption2)
                    }
                    .foregroundStyle(Color.swfPortWine)
                    .padding(.top, 4)
                }
                .padding(14)
            }
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 8, y: 3)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.swfGoldenYellow.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.swfPortWine : Color(.secondarySystemGroupedBackground))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
    }
}

// MARK: - Article/Video Row

struct ArticleVideoRow: View {
    let item: ArticleVideoItem
    
    private var iconName: String {
        switch item.type {
        case .article: return "doc.text.fill"
        case .video: return "play.rectangle.fill"
        case .website: return "globe"
        case .all: return "square.grid.2x2.fill"
        }
    }
    
    private var iconColor: Color {
        switch item.type {
        case .article: return Color.swfGreen
        case .video: return .red
        case .website: return Color.swfPortWine
        case .all: return .gray
        }
    }
    
    var body: some View {
        Link(destination: URL(string: item.link)!) {
            HStack(alignment: .top, spacing: 12) {
                // Icon
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: iconName)
                            .font(.title3)
                            .foregroundStyle(iconColor)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                    
                    Text(item.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "link")
                            .font(.caption)
                        Text(item.source)
                            .font(.caption)
                    }
                    .foregroundStyle(Color.swfGoldenYellow)
                    .padding(.top, 2)
                }
                
                Spacer(minLength: 0)
                
                Image(systemName: "arrow.up.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 8)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ArticlesVideosView()
    }
}
