//
//  OptionCard.swift
//  MontainGenerator
//
//  Created by Jan Huber on 04.01.2026.
//

import SwiftUI

// MARK: - Model

struct OptionCard: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let subtitle: String
    let accent: Color
    let configuration: MountainsConfiguration
    let image: ImageResource

    static func == (lhs: OptionCard, rhs: OptionCard) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Screen

struct FancyOptionPickerScreen: View {
    @State private var selectedOption: OptionCard? = nil
    @State private var navigateTo: OptionCard? = nil   // 👈 NEW

    private let options: [OptionCard] = [
        .init(
            title: "Appenzell (Switzerland)",
            subtitle: "Deep work mode",
            accent: .blue,
            configuration: .appenzell,
            image: .appenzell
        ),
        .init(
            title: "Dolomites (Italy)",
            subtitle: "Try something new",
            accent: .purple,
            configuration: .dolomites,
            image: .dolomites
        ),
        .init(
            title: "Himalayas (Nepal/India/Tibet)",
            subtitle: "Set goals & milestones",
            accent: .indigo,
            configuration: .himalaya,
            image: .himalayas
        ),
        .init(
            title: "Scottish Highlands (Scotland)",
            subtitle: "Review your progress",
            accent: .teal,
            configuration: .scottishHighlands,
            image: .scottishHighlands
        ),
        .init(
            title: "Tassili n’Ajjer (Algeria)",
            subtitle: "Make something cool",
            accent: .orange,
            configuration: .tassiliNAjjer,
            image: .tassiliNAjjer
        ),
        .init(
            title: "Torres del Paine (Patagonia)",
            subtitle: "Take a mindful break",
            accent: .pink,
            configuration: .torresDelPaine,
            image: .torresDelPaine
        ),
        .init(
            title: "Yosemite Valley (USA)",
            subtitle: "Work with others",
            accent: .red,
            configuration: .yosemite,
            image: .yosemiteValley
        ),
        .init(
            title: "Zhangjiajie National Forest Park (China)",
            subtitle: "Level up a skill",
            accent: .green,
            configuration: .zhangjiajie,
            image: .zhangjiajieNationalForestPark
        ),
    ]

    private var gridItems: [GridItem] {
        [
            GridItem(
                .adaptive(minimum: 220, maximum: 360),
                spacing: 16,
                alignment: .top
            )
        ]
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {

                #if os(macOS)
                header
                #endif

                ScrollView {
                    LazyVGrid(columns: gridItems, spacing: 16) {
                        ForEach(options) { option in
                            SelectableCard(
                                option: option,
                                isSelected: selectedOption?.id == option.id
                            ) {
                                // Selection animation
                                withAnimation(
                                    .spring(
                                        response: 0.25,
                                        dampingFraction: 0.85
                                    )
                                ) {
                                    selectedOption = option
                                }

                                // Immediate navigation
                                navigateTo = option
                            }
                            .accessibilityLabel(
                                "\(option.title). \(option.subtitle)"
                            )
                            .accessibilityAddTraits(
                                selectedOption?.id == option.id
                                    ? .isSelected : []
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                }
            }
            #if os(macOS)
            .padding(.vertical, 20)
            #endif
            .background(background)

#if os(macOS)
            .navigationTitle("Mountain Generator")

            #else
            .navigationTitle("Pick your animation")
            #endif


            .navigationDestination(item: $navigateTo) { option in
                AnimationView(configuration: option.configuration)
                    .ignoresSafeArea()
            }
        }
    }

    // MARK: - Pieces

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Pick your animation")
                .font(.system(.largeTitle, design: .rounded).weight(.bold))

            Text("Tap an option to start immediately.")
                .font(.system(.body, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
    }

    private var background: some View {
        AnimationView(configuration: .background)
            .ignoresSafeArea()
    }
}

// MARK: - Card View

struct SelectableCard: View {
    let option: OptionCard
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {

                Image(option.image)
                    .resizable()
                    .clipShape(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                    )
                    .frame(height: 110)
                    .overlay(
                        HStack {
                            Spacer()

                            if isSelected {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundStyle(.white)
                                    .padding(12)
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                    )

                VStack(alignment: .leading, spacing: 6) {
                    Text(option.title)
                        .font(
                            .system(.headline, design: .rounded).weight(
                                .semibold
                            )
                        )
                        .foregroundStyle(.primary)

                    Text(option.subtitle)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer(minLength: 0)
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 210, alignment: .topLeading)
            .background(cardBackground)
            .overlay(selectionRing)
            .scaleEffect(isSelected ? 1.01 : 1.0)
            .animation(
                .spring(response: 0.25, dampingFraction: 0.85),
                value: isSelected
            )
        }
        .buttonStyle(.plain)
        .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(.ultraThinMaterial)
            .shadow(color: .black.opacity(0.08), radius: 18, x: 0, y: 10)
            .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
    }

    private var selectionRing: some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .strokeBorder(
                isSelected
                    ? option.accent.opacity(0.9)
                    : Color.primary.opacity(0.08),
                lineWidth: isSelected ? 2.5 : 1
            )
    }
}

// MARK: - Selected Pill (unchanged, unused)

struct SelectedPill: View {
    let title: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)

            Text("Selected: \(title)")
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(.thinMaterial)
                .overlay(
                    Capsule().strokeBorder(
                        Color.primary.opacity(0.08),
                        lineWidth: 1
                    )
                )
        )
    }
}

// MARK: - Previews

struct FancyOptionPickerScreen_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NavigationStack {
                FancyOptionPickerScreen()
            }
            .previewDisplayName("Default")

            NavigationStack {
                FancyOptionPickerScreen()
            }
            .previewLayout(.fixed(width: 1000, height: 700))
            .previewDisplayName("Wide (macOS-like)")
        }
    }
}
