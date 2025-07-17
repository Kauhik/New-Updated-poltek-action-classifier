// File: ContentView.swift
// Drop‑in replacement so the preview image rotates right‑side up.

import SwiftUI

struct ContentView: View {
    @StateObject private var vm = ActionClassifierViewModel()
    @State private var showingSummary = false

    var body: some View {
        ZStack {
            if let uiImage = vm.previewImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    // rotate 180° so that upside‑down frames appear upright
                    .rotationEffect(.degrees(180))
                    .edgesIgnoringSafeArea(.all)
            } else {
                Color.black.edgesIgnoringSafeArea(.all)
            }

            VStack {
                Spacer()

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(vm.actionLabel).font(.headline)
                        Text(vm.confidenceLabel).font(.subheadline)
                    }
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(10)

                    Spacer()
                }
                .padding(.horizontal)

                HStack {
                    Button("Flip") { vm.toggleCamera() }
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
        .sheet(isPresented: $showingSummary, onDismiss: { vm.start() }) {
            SummaryView(actionFrameCounts: vm.actionFrameCounts)
        }
    }
}
