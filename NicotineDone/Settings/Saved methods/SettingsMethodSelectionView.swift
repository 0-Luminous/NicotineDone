import SwiftUI

struct SettingsMethodSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    let backgroundStyle: DashboardBackgroundStyle
    let profiles: [NicotineProfile]
    let selectedMethod: NicotineMethod
    let onSelect: (NicotineProfile) -> Void
    let onAdd: () -> Void
    let onEdit: (NicotineProfile) -> Void
    let onDelete: (NicotineProfile) -> Void

    private var primaryTextColor: Color {
        backgroundStyle.primaryTextColor(for: colorScheme)
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Saved methods")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(primaryTextColor)
                        .padding(.top, 8)

                    if profiles.isEmpty {
                        emptyState
                    } else {
                        VStack(spacing: 14) {
                            ForEach(profiles, id: \.method) { profile in
                                Button {
                                    handleSelection(profile)
                                } label: {
                                    SavedMethodCard(profile: profile,
                                                    isActive: profile.method == selectedMethod,
                                                    backgroundStyle: backgroundStyle)
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    Button {
                                        handleEdit(profile)
                                    } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }

                                    Button(role: .destructive) {
                                        handleDelete(profile)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 32)
            }
            .background(backgroundStyle.backgroundGradient(for: colorScheme).ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 12) {
                    Button(action: handleAdd) {
                        Label("Add method", systemImage: "plus")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PrimaryGradientButtonStyle())
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
                .padding(.top, 8)
                // .background(.ultraThinMaterial)
            }
        }
    }

    private var emptyState: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("No saved methods yet.")
                    .font(.headline)
                    .foregroundStyle(primaryTextColor)
                Text("Add a method to reuse its saved details later.")
                    .font(.subheadline)
                    .foregroundStyle(primaryTextColor.opacity(0.8))
            }
        }
    }

    private func handleSelection(_ profile: NicotineProfile) {
        onSelect(profile)
        dismiss()
    }

    private func handleAdd() {
        dismiss()
        DispatchQueue.main.async {
            onAdd()
        }
    }

    private func handleEdit(_ profile: NicotineProfile) {
        dismiss()
        DispatchQueue.main.async {
            onEdit(profile)
        }
    }

    private func handleDelete(_ profile: NicotineProfile) {
        onDelete(profile)
    }
}

private struct SavedMethodCard: View {
    let profile: NicotineProfile
    let isActive: Bool
    let backgroundStyle: DashboardBackgroundStyle
    @Environment(\.colorScheme) private var colorScheme

    private var primaryTextColor: Color {
        backgroundStyle.primaryTextColor(for: colorScheme)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 14) {
                Image(profile.method.iconAssetName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(LocalizedStringKey(profile.method.localizationKey))
                            .font(.headline)
                            .foregroundStyle(primaryTextColor)

                        if isActive {
                            TagView(text: "Active", color: primaryTextColor)
                        }
                    }

                    Text(LocalizedStringKey(profile.method.descriptionKey))
                        .font(.subheadline)
                        .foregroundStyle(primaryTextColor.opacity(0.85))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            let details = summary(for: profile)
            if !details.isEmpty {
                Divider()
                    .overlay(primaryTextColor.opacity(0.3))

                VStack(alignment: .leading, spacing: 6) {
                    ForEach(details, id: \.self) { line in
                        Text(line)
                            .font(.footnote)
                            .foregroundStyle(primaryTextColor.opacity(0.85))
                    }
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.clear, in: .rect(cornerRadius: 24))
        .shadow(color: .black.opacity(0.35), radius: 18, x: 0, y: 10)
    }

    private func summary(for profile: NicotineProfile) -> [String] {
        switch profile.method {
        case .cigarettes:
            guard let config = profile.cigarettes else { return [] }
            let price = CurrencyFormatterFactory.string(from: config.packPrice, currencyCode: config.currency.code)
            return [
                "\(config.cigarettesPerDay) per day",
                "\(config.cigarettesPerPack) per pack • \(price)"
            ]
        case .disposableVape:
            guard let config = profile.disposableVape else { return [] }
            let price = CurrencyFormatterFactory.string(from: config.devicePrice, currencyCode: config.currency.code)
            return [
                "\(config.puffsPerDevice) puffs per device",
                price
            ]
        case .refillableVape:
            guard let config = profile.refillableVape else { return [] }
            var lines: [String] = []
            let bottlePrice = CurrencyFormatterFactory.string(from: config.liquidPrice, currencyCode: config.currency.code)
            lines.append("\(config.liquidBottleMl) ml • \(config.nicotineMgPerMl) mg")
            lines.append("\(config.estimatedPuffsPerMl) puffs/ml")
            let coil = config.coilPrice.map { CurrencyFormatterFactory.string(from: $0, currencyCode: config.currency.code) }
            if let coil {
                lines.append("\(bottlePrice) bottle • \(coil) coil")
            } else {
                lines.append("\(bottlePrice) bottle")
            }
            return lines
        case .heatedTobacco:
            guard let config = profile.heatedTobacco else { return [] }
            let price = CurrencyFormatterFactory.string(from: config.packPrice, currencyCode: config.currency.code)
            return [
                "\(config.dailySticks) per day",
                "\(config.sticksPerPack) per pack • \(price)"
            ]
        case .snusOrPouches:
            guard let config = profile.snus else { return [] }
            let price = CurrencyFormatterFactory.string(from: config.canPrice, currencyCode: config.currency.code)
            return [
                "\(config.dailyPouches) per day",
                "\(config.pouchesPerCan) per can • \(price)"
            ]
        }
    }
}

private struct TagView: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text.uppercased())
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }
}
