import SwiftUI

struct OrientationPicker: View {
    let onOrientationSelected: (Int, Int) -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("Select canvas orientation")
                    .font(.headline)
                    .padding(.top, 24)

                VStack(spacing: 16) {
                    // Landscape button
                    Button(action: {
                        onOrientationSelected(640, 480)
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: "rectangle")
                                .font(.system(size: 48))
                                .frame(width: 80, height: 60)
                            Text("Landscape")
                                .font(.subheadline)
                            Text("640 × 480")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .cornerRadius(12)
                    }

                    // Portrait button
                    Button(action: {
                        onOrientationSelected(480, 640)
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: "rectangle.portrait")
                                .font(.system(size: 48))
                                .frame(width: 60, height: 80)
                            Text("Portrait")
                                .font(.subheadline)
                            Text("480 × 640")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal)

                Spacer()
            }
            .navigationTitle("Canvas Orientation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("common.cancel".localized) {
                        onCancel()
                    }
                }
            }
        }
    }
}

#Preview {
    OrientationPicker(
        onOrientationSelected: { width, height in
            print("Selected: \(width)×\(height)")
        },
        onCancel: {
            print("Cancelled")
        }
    )
}
