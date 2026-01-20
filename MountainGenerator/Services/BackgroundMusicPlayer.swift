import AVFoundation
import Foundation

@MainActor
final class BackgroundMusicPlayer {
    private var player: AVAudioPlayer?
    private var currentlyPlayingResourceName: String?

    func play(resourceName: String?, fileExtension: String = "wav") {
        guard let resourceName else {
            stop()
            return
        }

        guard resourceName != currentlyPlayingResourceName else { return }
        stop()

        do {
            try configureAudioSessionIfNeeded()

            guard let url = resolveBundleURL(
                resourceName: resourceName,
                fileExtension: fileExtension
            ) else {
                return
            }

            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1
            player.prepareToPlay()
            player.play()

            self.player = player
            self.currentlyPlayingResourceName = resourceName
        } catch {
            stop()
        }
    }

    func stop() {
        player?.stop()
        player = nil
        currentlyPlayingResourceName = nil
    }

    private func resolveBundleURL(
        resourceName: String,
        fileExtension: String
    ) -> URL? {
        if let url = Bundle.main.url(
            forResource: resourceName,
            withExtension: fileExtension,
            subdirectory: "Music"
        ) {
            return url
        }

        return Bundle.main.url(
            forResource: resourceName,
            withExtension: fileExtension
        )
    }

    private func configureAudioSessionIfNeeded() throws {
        #if os(iOS) || os(tvOS) || os(visionOS)
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        #endif
    }
}
