import SwiftUI

struct ContentView: View {
    @StateObject private var vm = ActionClassifierViewModel()
    @State private var showingSummary = false

    var body: some View {
        ZStack {
            // camera + pose preview
            if let image = vm.previewImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .edgesIgnoringSafeArea(.all)
            } else {
                Color.black.edgesIgnoringSafeArea(.all)
            }

            VStack {
                Spacer()

                // prediction labels
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(vm.actionLabel)
                            .font(.headline)
                        Text(vm.confidenceLabel)
                            .font(.subheadline)
                    }
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(10)

                    Spacer()
                }
                .padding(.horizontal)

                // controls
                HStack {
                    Button("Flip") {
                        vm.toggleCamera()
                    }
                    .padding()
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(10)

                    Spacer()

                    Button("Summary") {
                        vm.stop()
                        showingSummary = true
                    }
                    .padding()
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(10)
                }
                .padding([.horizontal, .bottom])
            }
        }
        .onAppear { vm.start() }
        .sheet(isPresented: $showingSummary, onDismiss: {
            vm.start()
        }) {
            SummaryView(actionFrameCounts: vm.actionFrameCounts)
        }
    }
}
