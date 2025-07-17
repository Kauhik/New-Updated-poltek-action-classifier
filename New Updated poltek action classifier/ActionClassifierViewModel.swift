import SwiftUI
import Combine
import UIKit

@MainActor
class ActionClassifierViewModel: NSObject, ObservableObject {
    // Published for the SwiftUI view
    @Published var previewImage: UIImage?
    @Published var actionLabel: String = ActionPrediction.startingPrediction.label
    @Published var confidenceLabel: String = "Observing..."
    @Published var actionFrameCounts: [String: Int] = [:]

    private let videoCapture = VideoCapture()
    private var videoProcessingChain = VideoProcessingChain()

    override init() {
        super.init()

        // hook up delegates
        videoCapture.delegate = self
        videoProcessingChain.delegate = self
    }

    /// Start the capture + processing
    func start() {
        videoCapture.updateDeviceOrientation()
        videoCapture.isEnabled = true
    }

    /// Stop capture (e.g. while showing summary)
    func stop() {
        videoCapture.isEnabled = false
    }

    /// Flip between front/back
    func toggleCamera() {
        videoCapture.toggleCameraSelection()
    }

    // Draw poses onto the raw CGImage
    private func drawPoses(_ poses: [Pose]?, onto frame: CGImage) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        let size = CGSize(width: frame.width, height: frame.height)
        let renderer = UIGraphicsImageRenderer(size: size, format: format)

        let uiImage = renderer.image { ctx in
            let cg = ctx.cgContext
            // draw the raw camera
            cg.draw(frame, in: CGRect(origin: .zero, size: size))
            // overlay poses
            let transform = CGAffineTransform(scaleX: size.width, y: size.height)
            poses?.forEach { $0.drawWireframeToContext(cg, applying: transform) }
        }
        return uiImage
    }
}

// MARK: - VideoCaptureDelegate
extension ActionClassifierViewModel: VideoCaptureDelegate {
    func videoCapture(_ videoCapture: VideoCapture,
                      didCreate framePublisher: FramePublisher) {
        // reset labels
        actionLabel = ActionPrediction.startingPrediction.label
        confidenceLabel = "Observing..."
        // feed into processing chain
        videoProcessingChain.upstreamFramePublisher = framePublisher
    }
}

// MARK: - VideoProcessingChainDelegate
extension ActionClassifierViewModel: VideoProcessingChainDelegate {
    func videoProcessingChain(_ chain: VideoProcessingChain,
                              didDetect poses: [Pose]?,
                              in frame: CGImage) {
        let img = drawPoses(poses, onto: frame)
        previewImage = img
    }

    func videoProcessingChain(_ chain: VideoProcessingChain,
                              didPredict actionPrediction: ActionPrediction,
                              for frames: Int) {
        // accumulate for summary
        if actionPrediction.isModelLabel {
            let total = (actionFrameCounts[actionPrediction.label] ?? 0) + frames
            actionFrameCounts[actionPrediction.label] = total
        }
        // update labels
        actionLabel = actionPrediction.label
        confidenceLabel = actionPrediction.confidenceString ?? "Observing..."
    }
}
