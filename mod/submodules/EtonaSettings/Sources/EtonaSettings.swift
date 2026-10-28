import Foundation

/// Settings of the etonapygram mod.
///
/// Foundation-only on purpose: TelegramCore (network layer) and TelegramUI both read these
/// values, so the module must not depend on anything above Foundation.
public final class EtonaSettings {
    public static let shared = EtonaSettings()

    public static let didChangeNotification = Notification.Name("EtonaSettingsDidChange")

    public enum Key: String, CaseIterable {
        // Ghost mode
        case ghostMode
        case hideOnline
        case hideTyping
        case hideRecordingVideo
        case hideUploadingVideo
        case hideRecordingVoice
        case hideUploadingVoice
        case hideUploadingPhoto
        case hideUploadingFile
        case hideReadReceipts
        case hideListened
        case anonymousStories

        // Profile
        case showPeerId
        case phoneSpoiler
        case showRegistrationDate

        // Chats
        case saveDeletedMessages
        case saveEditHistory

        var defaultValue: Bool {
            switch self {
            case .ghostMode:
                return false
            case .showPeerId, .phoneSpoiler, .showRegistrationDate:
                return true
            case .saveDeletedMessages, .saveEditHistory:
                return true
            default:
                // Every "hide …" switch is on, so turning on ghost mode alone hides everything.
                return true
            }
        }
    }

    private static let prefix = "etonapygram."
    private static let ghostExceptionsKey = prefix + "ghostExceptions"

    private let defaults: UserDefaults
    private let lock = NSLock()
    private var cachedExceptions: Set<Int64>?

    private init() {
        self.defaults = UserDefaults.standard
    }

    public func bool(_ key: Key) -> Bool {
        let name = EtonaSettings.prefix + key.rawValue
        if self.defaults.object(forKey: name) == nil {
            return key.defaultValue
        }
        return self.defaults.bool(forKey: name)
    }

    public func set(_ key: Key, _ value: Bool) {
        self.defaults.set(value, forKey: EtonaSettings.prefix + key.rawValue)
        self.notifyChanged()
    }

    // MARK: Ghost mode

    public var ghostMode: Bool {
        return self.bool(.ghostMode)
    }

    private func ghost(_ key: Key, peerId: Int64?) -> Bool {
        guard self.ghostMode, self.bool(key) else {
            return false
        }
        if let peerId = peerId, self.isGhostException(peerId: peerId) {
            return false
        }
        return true
    }

    /// The account always reports itself as offline.
    public var hideOnline: Bool {
        return self.ghost(.hideOnline, peerId: nil)
    }

    public func hideReadReceipts(peerId: Int64?) -> Bool {
        return self.ghost(.hideReadReceipts, peerId: peerId)
    }

    public func hideListened(peerId: Int64?) -> Bool {
        return self.ghost(.hideListened, peerId: peerId)
    }

    public func anonymousStories(peerId: Int64?) -> Bool {
        return self.ghost(.anonymousStories, peerId: peerId)
    }

    public enum Activity {
        case typing
        case recordingVideo
        case uploadingVideo
        case recordingVoice
        case uploadingVoice
        case uploadingPhoto
        case uploadingFile
        case other
    }

    public func hideActivity(_ activity: Activity, peerId: Int64?) -> Bool {
        let key: Key
        switch activity {
        case .typing, .other:
            key = .hideTyping
        case .recordingVideo:
            key = .hideRecordingVideo
        case .uploadingVideo:
            key = .hideUploadingVideo
        case .recordingVoice:
            key = .hideRecordingVoice
        case .uploadingVoice:
            key = .hideUploadingVoice
        case .uploadingPhoto:
            key = .hideUploadingPhoto
        case .uploadingFile:
            key = .hideUploadingFile
        }
        return self.ghost(key, peerId: peerId)
    }

    // MARK: Ghost mode exceptions

    /// Peers that always see the real status. Stored as `PeerId.toInt64()`.
    public var ghostExceptions: Set<Int64> {
        self.lock.lock()
        defer { self.lock.unlock() }
        if let cached = self.cachedExceptions {
            return cached
        }
        let stored = (self.defaults.array(forKey: EtonaSettings.ghostExceptionsKey) as? [NSNumber]) ?? []
        let value = Set(stored.map { $0.int64Value })
        self.cachedExceptions = value
        return value
    }

    public func isGhostException(peerId: Int64) -> Bool {
        return self.ghostExceptions.contains(peerId)
    }

    public func setGhostException(peerId: Int64, _ isException: Bool) {
        var value = self.ghostExceptions
        if isException {
            value.insert(peerId)
        } else {
            value.remove(peerId)
        }
        self.lock.lock()
        self.cachedExceptions = value
        self.lock.unlock()
        self.defaults.set(value.map { NSNumber(value: $0) }, forKey: EtonaSettings.ghostExceptionsKey)
        self.notifyChanged()
    }

    // MARK: Profile

    public var showPeerId: Bool {
        return self.bool(.showPeerId)
    }

    public var phoneSpoiler: Bool {
        return self.bool(.phoneSpoiler)
    }

    public var showRegistrationDate: Bool {
        return self.bool(.showRegistrationDate)
    }

    // MARK: Chats

    public var saveDeletedMessages: Bool {
        return self.bool(.saveDeletedMessages)
    }

    public var saveEditHistory: Bool {
        return self.bool(.saveEditHistory)
    }

    private func notifyChanged() {
        let post = {
            NotificationCenter.default.post(name: EtonaSettings.didChangeNotification, object: self)
        }
        if Thread.isMainThread {
            post()
        } else {
            DispatchQueue.main.async(execute: post)
        }
    }
}
