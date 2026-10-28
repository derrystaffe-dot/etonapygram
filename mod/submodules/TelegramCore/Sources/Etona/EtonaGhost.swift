import Foundation
import Postbox
import EtonaSettings

/// Whether ghost mode keeps this activity ("typing", "recording video", …) from being sent.
/// Cancelling an activity (`nil`) is never hidden: it reveals nothing.
func etonaShouldHideActivity(_ activity: PeerInputActivity?, peerId: PeerId) -> Bool {
    guard let activity = activity else {
        return false
    }
    let mapped: EtonaSettings.Activity
    switch activity {
    case .typingText, .choosingSticker, .playingGame, .interactingWithEmoji, .seeingEmojiInteraction:
        mapped = .typing
    case .recordingVoice:
        mapped = .recordingVoice
    case .recordingInstantVideo:
        mapped = .recordingVideo
    case .uploadingVideo, .uploadingInstantVideo:
        mapped = .uploadingVideo
    case .uploadingPhoto:
        mapped = .uploadingPhoto
    case .uploadingFile:
        mapped = .uploadingFile
    case .speakingInGroupCall:
        return false
    }
    return EtonaSettings.shared.hideActivity(mapped, peerId: peerId.toInt64())
}

func etonaHideReadReceipts(peerId: PeerId) -> Bool {
    return EtonaSettings.shared.hideReadReceipts(peerId: peerId.toInt64())
}

func etonaHideListened(peerId: PeerId) -> Bool {
    return EtonaSettings.shared.hideListened(peerId: peerId.toInt64())
}

func etonaAnonymousStories(peerId: PeerId) -> Bool {
    return EtonaSettings.shared.anonymousStories(peerId: peerId.toInt64())
}
