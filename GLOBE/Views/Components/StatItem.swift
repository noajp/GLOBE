//======================================================================
// MARK: - StatItem.swift
// Purpose: Small stat pill view for count + label in profile
// Path: GLOBE/Views/Components/StatItem.swift
//======================================================================

import SwiftUI

struct StatItem: View {
    let value: Int
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(MinimalDesign.Colors.primary)
            Text(label)
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(MinimalDesign.Colors.secondary)
        }
        .frame(minWidth: 60)
    }
}

