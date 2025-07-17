// File: VideoCapture.swift
// See LICENSE folder for this sample’s licensing information.
// Abstract:
// Convenience class that configures the video capture session and
// creates a (video) frame publisher.

import UIKit
import Combine
import AVFoundation

/// - Tag: Frame
typealias Frame = CMSampleBuffer
typealias FramePublisher = AnyPublisher<Frame, Never>

protocol VideoCaptureDelegate: AnyObject {
    /// Called when VideoCapture creates a new frame publisher.
    func videoCapture(_ videoCapture: VideoCapture,
                      didCreate framePublisher: FramePublisher)
}

class VideoCapture: NSObject {
    weak var delegate: VideoCaptureDelegate! {
        didSet { createVideoFramePublisher() }
    }

    var isEnabled = true {
        didSet { isEnabled ? enableCaptureSession() : disableCaptureSession() }
    }

    private var cameraPosition = AVCaptureDevice.Position.front {
        didSet { createVideoFramePublisher() }
    }

    private var orientation = AVCaptureVideoOrientation.portrait {
        didSet { createVideoFramePublisher() }
    }

    private let captureSession = AVCaptureSession()
    private var framePublisher: PassthroughSubject<Frame, Never>?
    private let videoCaptureQueue = DispatchQueue(
        label: "Video Capture Queue", qos: .userInitiated
    )

    private var horizontalFlip: Bool { cameraPosition == .front }
    private var videoStabilizationEnabled = false

    func toggleCameraSelection() {
        cameraPosition = (cameraPosition == .back) ? .front : .back
    }

    /// Map physical device orientation directly to videoOrientation
    func updateDeviceOrientation() {
        switch UIDevice.current.orientation {
            case .portrait, .faceUp, .faceDown, .unknown:
                orientation = .portrait
            case .portraitUpsideDown:
                orientation = .portraitUpsideDown
            case .landscapeLeft:
                orientation = .landscapeLeft
            case .landscapeRight:
                orientation = .landscapeRight
            @unknown default:
                orientation = .portrait
        }
    }

    private func enableCaptureSession() {
        if !captureSession.isRunning { captureSession.startRunning() }
    }

    private func disableCaptureSession() {
        if captureSession.isRunning { captureSession.stopRunning() }
    }
}

extension VideoCapture: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput frame: Frame,
                       from connection: AVCaptureConnection) {
        framePublisher?.send(frame)
    }
}

extension VideoCapture {
    private func createVideoFramePublisher() {
        guard let videoDataOutput = configureCaptureSession() else { return }

        let passthrough = PassthroughSubject<Frame, Never>()
        framePublisher = passthrough
        videoDataOutput.setSampleBufferDelegate(self, queue: videoCaptureQueue)
        delegate.videoCapture(self,
                             didCreate: passthrough.eraseToAnyPublisher())
    }

    private func configureCaptureSession() -> AVCaptureVideoDataOutput? {
        disableCaptureSession()
        guard isEnabled else { return nil }
        defer { enableCaptureSession() }

        captureSession.beginConfiguration()
        defer { captureSession.commitConfiguration() }

        // use your model’s frameRate
        let modelFrameRate = PoltekActionClassifierORGINAL.frameRate
        let input = AVCaptureDeviceInput.createCameraInput(
            position: cameraPosition, frameRate: modelFrameRate
        )
        let output = AVCaptureVideoDataOutput.withPixelFormatType(
            kCVPixelFormatType_32BGRA
        )
        guard configureCaptureConnection(input, output) else { return nil }
        return output
    }

    private func configureCaptureConnection(
        _ input: AVCaptureDeviceInput?,
        _ output: AVCaptureVideoDataOutput?
    ) -> Bool {
        guard let input = input, let output = output else { return false }

        captureSession.inputs.forEach { captureSession.removeInput($0) }
        captureSession.outputs.forEach { captureSession.removeOutput($0) }

        guard captureSession.canAddInput(input),
              captureSession.canAddOutput(output) else {
            print("Capture session not compatible")
            return false
        }
        captureSession.addInput(input)
        captureSession.addOutput(output)

        // ⬇️ get the *video* connection directly from the output
        guard let connection = output.connection(with: .video) else {
            print("No video connection found")
            return false
        }

        if connection.isVideoOrientationSupported {
            connection.videoOrientation = orientation
        }
        if connection.isVideoMirroringSupported {
            connection.isVideoMirrored = horizontalFlip
        }
        if connection.isVideoStabilizationSupported {
            connection.preferredVideoStabilizationMode =
                videoStabilizationEnabled ? .standard : .off
        }

        output.alwaysDiscardsLateVideoFrames = true
        return true
    }
}
