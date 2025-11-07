import SwiftUI

enum DrawingTool: String, CaseIterable, Identifiable {
    case neo = "neo"
    case tegaki = "tegaki"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .neo: return "draw.tool_neo".localized
        case .tegaki: return "draw.tool_tegaki".localized
        }
    }
}

struct CanvasDimensions: Identifiable {
    let id = UUID()
    let width: Int
    let height: Int
    let tool: DrawingTool
}

struct CanvasDimensionPicker: View {
    let onDimensionsSelected: (Int, Int, DrawingTool) -> Void
    let onCancel: () -> Void

    @State private var selectedWidth: Int = 300
    @State private var selectedHeight: Int = 300
    @State private var selectedTool: DrawingTool = .neo

    private let availableWidths = [300, 350, 400, 450, 500, 550, 600, 650, 700, 750, 800, 850, 900, 950, 1000]
    private let availableHeights = [300, 350, 400, 450, 500, 550, 600, 650, 700, 750, 800]

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("draw.drawing_tool".localized)) {
                    Picker("Tool", selection: $selectedTool) {
                        ForEach(DrawingTool.allCases) { tool in
                            Text(tool.displayName).tag(tool)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section(header: Text("Canvas Size")) {
                    Picker("draw.width".localized, selection: $selectedWidth) {
                        ForEach(availableWidths, id: \.self) { width in
                            Text("\(width)").tag(width)
                        }
                    }

                    Picker("draw.height".localized, selection: $selectedHeight) {
                        ForEach(availableHeights, id: \.self) { height in
                            Text("\(height)").tag(height)
                        }
                    }

                    HStack {
                        Text("draw.preview".localized)
                        Spacer()
                        Text("\(selectedWidth) × \(selectedHeight)")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("draw.canvas_size".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel".localized) {
                        onCancel()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("draw.start_drawing".localized) {
                        onDimensionsSelected(selectedWidth, selectedHeight, selectedTool)
                    }
                }
            }
        }
    }
}

#Preview {
    CanvasDimensionPicker(
        onDimensionsSelected: { width, height, tool in
            print("Selected: \(width)x\(height), tool: \(tool.displayName)")
        },
        onCancel: {
            print("Cancelled")
        }
    )
}
