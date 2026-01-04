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

    private let options: [OptionCard] = [
        .init(
            title: "Appenzell (Switzerland)",
            subtitle: "Deep work mode",
            accent: .blue,
            configuration: .appenzell
        ),
        .init(
            title: "Dolomites (Italy)",
            subtitle: "Try something new",
            accent: .purple,
            configuration: .dolomites
        ),
        .init(
            title: "Himalayas (Nepal/India/Tibet)",
            subtitle: "Set goals & milestones",
            accent: .indigo,
            configuration: .himalaya
        ),
        .init(
            title: "Scottish Highlands (Scotland)",
            subtitle: "Review your progress",
            accent: .teal,
            configuration: .scottishHighlands
        ),
        .init(
            title: "Tassili n’Ajjer (Algeria)",
            subtitle: "Make something cool",
            accent: .orange,
            configuration: .tassiliNAjjer
        ),
        .init(
            title: "Torres del Paine (Patagonia)",
            subtitle: "Take a mindful break",
            accent: .pink,
            configuration: .torresDelPaine
        ),
        .init(
            title: "Yosemite Valley (USA)",
            subtitle: "Work with others",
            accent: .red,
            configuration: .yosemite
        ),
        .init(
            title: "Zhangjiajie National Forest Park (China)",
            subtitle: "Level up a skill",
            accent: .green,
            configuration: .zhangjiajie
        ),

    ]

    // Adaptive grid: changes column count based on available width
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
                header

                ScrollView {
                    LazyVGrid(columns: gridItems, spacing: 16) {
                        ForEach(options) { option in
                            SelectableCard(
                                option: option,
                                isSelected: selectedOption?.id == option.id
                            ) {
                                withAnimation(
                                    .spring(
                                        response: 0.25,
                                        dampingFraction: 0.85
                                    )
                                ) {
                                    selectedOption = option
                                }
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

                footer
            }
            .padding(.vertical, 20)
            .background(background)
            .navigationTitle("Choose an Option")
            #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
            #endif
        }
    }

    // MARK: - Pieces

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Pick your next step")
                .font(.system(.largeTitle, design: .rounded).weight(.bold))

            Text("Select one of the options below, then press Start.")
                .font(.system(.body, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
    }

    private var footer: some View {
        HStack(spacing: 12) {
            if let selected = options.first(where: {
                $0.id == selectedOption?.id
            }) {
                SelectedPill(title: selected.title, color: selected.accent)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            } else {
                Text("No option selected")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            NavigationLink(
                destination: {
                    AnimationView(configuration: selectedOption?.configuration ?? .appenzell)
                },
                label: {
                    Label("Start", systemImage: "play.fill")
                        .font(.system(.headline, design: .rounded))
                        .padding(.horizontal, 18)
                        .padding(.vertical, 12)

                }
            )
            .buttonStyle(.borderedProminent)
            .disabled(selectedOption == nil)

            /*  Button {
                  guard let selected = options.first(where: { $0.id == selectedID }) else { return }
                  // Replace with your navigation/action
                  print("Start tapped with: \(selected.title)")
              } label: {
                  Label("Start", systemImage: "play.fill")
                      .font(.system(.headline, design: .rounded))
                      .padding(.horizontal, 18)
                      .padding(.vertical, 12)
              }
              .buttonStyle(.borderedProminent)
              .disabled(selectedID == nil)*/
        }
        .padding(.horizontal, 20)
    }

    private var background: some View {
        AnimationView(configuration: selectedOption?.configuration ?? .appenzell)
            .blur(radius: 10)
            .ignoresSafeArea()

        /* // Fancy but still clean. Works on both iOS & macOS.
         ZStack {
             LinearGradient(
                 colors: [
                     Color.primary.opacity(0.06),
                     Color.primary.opacity(0.02),
                     Color.clear
                 ],
                 startPoint: .topLeading,
                 endPoint: .bottomTrailing
             )
        
             // A couple of soft "blobs"
             Circle()
                 .fill(Color.purple.opacity(0.12))
                 .frame(width: 260, height: 260)
                 .blur(radius: 30)
                 .offset(x: -140, y: -200)
        
             Circle()
                 .fill(Color.blue.opacity(0.10))
                 .frame(width: 300, height: 300)
                 .blur(radius: 35)
                 .offset(x: 160, y: 260)
         }
         .ignoresSafeArea()*/
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
                // Placeholder "image" as a color tile
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                option.accent.opacity(0.95),
                                option.accent.opacity(0.55),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 110)
                    .overlay(
                        HStack {
                            Image(systemName: "sparkles")
                                .font(
                                    .system(
                                        size: 22,
                                        weight: .semibold,
                                        design: .rounded
                                    )
                                )
                                .foregroundStyle(.white.opacity(0.95))
                                .padding(12)

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
                    ? option.accent.opacity(0.9) : Color.primary.opacity(0.08),
                lineWidth: isSelected ? 2.5 : 1
            )
    }
}

// MARK: - Selected Pill

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

// MARK: - Previews (iOS + macOS)

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
