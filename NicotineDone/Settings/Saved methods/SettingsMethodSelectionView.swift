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
    @State private var selection: Set<NicotineMethod> = []

    private var primaryTextColor: Color {
        backgroundStyle.primaryTextColor(for: colorScheme)
    }

    private var selectionCount: Int {
        selection.count
    }

    private var selectedProfiles: [NicotineProfile] {
        profiles.filter { selection.contains($0.method) }
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
                                    toggleSelection(profile)
                                } label: {
                                    SavedMethodCard(profile: profile,
                                                    isActive: profile.method == selectedMethod,
                                                    isSelected: selection.contains(profile.method),
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
            .onChange(of: profiles) { newProfiles in
                let available = Set(newProfiles.map(\.method))
                selection = selection.intersection(available)
            }
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        if selectionCount == 0 {
                            Button(action: handleAdd) {
                                Label("Add method", systemImage: "plus")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(PrimaryGradientButtonStyle())
                        }

                        if selectionCount == 1 {
                            Button(action: handleConfirmSelection) {
                                Label("Select", systemImage: "checkmark")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(PrimaryGradientButtonStyle())
                            .disabled(selectionCount != 1)
                            .opacity(selectionCount == 1 ? 1 : 0.5)
                        }
                    }

                    if selectionCount > 0 {
                        HStack(spacing: 12) {
                            if selectionCount == 1 {
                                Button(action: handleEditSelection) {
                                    Label("Edit", systemImage: "pencil")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(PrimaryGradientButtonStyle())
                            }

                            Button(role: .destructive, action: handleDeleteSelection) {
                                Label("Delete", systemImage: "trash")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(PrimaryGradientButtonStyle())
                        }
                    }
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

    private func toggleSelection(_ profile: NicotineProfile) {
        if selection.contains(profile.method) {
            selection.remove(profile.method)
        } else {
            selection.insert(profile.method)
        }
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

    private func handleConfirmSelection() {
        guard selectionCount == 1, let profile = selectedProfiles.first else { return }
        onSelect(profile)
        dismiss()
    }

    private func handleEditSelection() {
        guard selectionCount == 1, let profile = selectedProfiles.first else { return }
        handleEdit(profile)
    }

    private func handleDeleteSelection() {
        let profilesToDelete = selectedProfiles
        profilesToDelete.forEach { onDelete($0) }
        selection.subtract(profilesToDelete.map(\.method))
    }

    private func handleDelete(_ profile: NicotineProfile) {
        onDelete(profile)
    }
}

private struct SavedMethodCard: View {
    let profile: NicotineProfile
    let isActive: Bool
    let isSelected: Bool
    let backgroundStyle: DashboardBackgroundStyle
    @Environment(\.colorScheme) private var colorScheme

    private let iconShape = RoundedRectangle(cornerRadius: 20, style: .continuous)
    private let cardShape = RoundedRectangle(cornerRadius: 24, style: .continuous)

    private var primaryTextColor: Color {
        backgroundStyle.primaryTextColor(for: colorScheme)
    }

    private var isLightBackground: Bool {
        switch backgroundStyle {
        case .sunrise, .melloYellow:
            return true
        default:
            return false
        }
    }

    private var iconStrokeColor: Color {
        isLightBackground ? Color.black.opacity(0.05) : Color.white.opacity(0.2)
    }
    
    private var selectedBorderColor: Color {
        primaryTextColor.opacity(isLightBackground ? 0.35 : 0.45)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 14) {
                iconShape
                    .fill(backgroundStyle.circleGradient)
                    .frame(width: 56, height: 56)
                    .overlay(
                        Image(profile.method.iconAssetName)
                            .resizable()
                            .renderingMode(.original)
                            .scaledToFit()
                            .frame(width: 52, height: 52)
                            .clipShape(iconShape)
                    )
                    .overlay(
                        iconShape
                            .stroke(iconStrokeColor, lineWidth: 1)
                    )
                    .overlay(
                        iconShape
                            .stroke(isActive ? selectedBorderColor : .clear, lineWidth: 1)
                    )

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
        .overlay(
            cardShape
                .stroke((isActive || isSelected) ? selectedBorderColor : .clear, lineWidth: 1)
        )
        .overlay(alignment: .topTrailing) {
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(primaryTextColor)
                    .padding(12)
            }
        }
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
        case .hookah:
            guard let config = profile.cigarettes else { return [] }
            let perSessionCost = config.packPrice * config.hookahPacksPerSession
            let price = CurrencyFormatterFactory.string(from: perSessionCost, currencyCode: config.currency.code)
            let packsPerSession = decimalString(config.hookahPacksPerSession)
            return [
                "\(config.cigarettesPerDay) sessions per week",
                "\(packsPerSession) packs per session • \(price)"
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

    private func decimalString(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSDecimalNumber(decimal: value)) ?? "\(value)"
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
