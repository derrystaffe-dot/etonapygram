import Foundation
import Postbox
import EtonaSettings

/// Local-only state that etonapygram keeps on a message: whether it was deleted on the server
/// and the texts it had before each edit. Never sent anywhere.
public final class EtonaMessageAttribute: MessageAttribute, Equatable {
    public struct EditEntry: Equatable {
        public let text: String
        /// When this text was replaced by the next one.
        public let date: Int32

        public init(text: String, date: Int32) {
            self.text = text
            self.date = date
        }
    }

    /// Server deletion time, or `nil` while the message still exists.
    public let deletedDate: Int32?
    /// Previous texts, oldest first.
    public let editHistory: [EditEntry]

    public init(deletedDate: Int32?, editHistory: [EditEntry]) {
        self.deletedDate = deletedDate
        self.editHistory = editHistory
    }

    public init(decoder: PostboxDecoder) {
        self.deletedDate = decoder.decodeOptionalInt32ForKey("dd")
        let texts = decoder.decodeStringArrayForKey("ht")
        let dates = decoder.decodeInt32ArrayForKey("hd")
        var editHistory: [EditEntry] = []
        for i in 0 ..< min(texts.count, dates.count) {
            editHistory.append(EditEntry(text: texts[i], date: dates[i]))
        }
        self.editHistory = editHistory
    }

    public func encode(_ encoder: PostboxEncoder) {
        if let deletedDate = self.deletedDate {
            encoder.encodeInt32(deletedDate, forKey: "dd")
        } else {
            encoder.encodeNil(forKey: "dd")
        }
        encoder.encodeStringArray(self.editHistory.map(\.text), forKey: "ht")
        encoder.encodeInt32Array(self.editHistory.map(\.date), forKey: "hd")
    }

    public static func ==(lhs: EtonaMessageAttribute, rhs: EtonaMessageAttribute) -> Bool {
        return lhs.deletedDate == rhs.deletedDate && lhs.editHistory == rhs.editHistory
    }

    func withDeletedDate(_ deletedDate: Int32?) -> EtonaMessageAttribute {
        return EtonaMessageAttribute(deletedDate: deletedDate, editHistory: self.editHistory)
    }

    func withAddedEdit(_ entry: EditEntry) -> EtonaMessageAttribute {
        return EtonaMessageAttribute(deletedDate: self.deletedDate, editHistory: self.editHistory + [entry])
    }
}

public extension Message {
    var etonaAttribute: EtonaMessageAttribute? {
        for attribute in self.attributes {
            if let attribute = attribute as? EtonaMessageAttribute {
                return attribute
            }
        }
        return nil
    }

    /// Deleted on the server but kept on this device by "save deleted messages".
    var etonaIsDeleted: Bool {
        return self.etonaAttribute?.deletedDate != nil
    }

    var etonaEditHistory: [EtonaMessageAttribute.EditEntry] {
        return self.etonaAttribute?.editHistory ?? []
    }
}

public extension EngineMessage {
    var etonaIsDeleted: Bool {
        return self._asMessage().etonaIsDeleted
    }

    var etonaEditHistory: [EtonaMessageAttribute.EditEntry] {
        return self._asMessage().etonaEditHistory
    }
}

func etonaAttributes(_ attributes: [MessageAttribute], updating update: (EtonaMessageAttribute) -> EtonaMessageAttribute) -> [MessageAttribute] {
    var attributes = attributes
    let current: EtonaMessageAttribute
    if let index = attributes.firstIndex(where: { $0 is EtonaMessageAttribute }) {
        current = attributes[index] as! EtonaMessageAttribute
        attributes.remove(at: index)
    } else {
        current = EtonaMessageAttribute(deletedDate: nil, editHistory: [])
    }
    attributes.append(update(current))
    return attributes
}

/// Carries etonapygram's attribute over when the server sends a fresh copy of a message.
func etonaCarryOverAttribute(previous: Message, updated attributes: [MessageAttribute]) -> [MessageAttribute] {
    guard let previousAttribute = previous.etonaAttribute, !attributes.contains(where: { $0 is EtonaMessageAttribute }) else {
        return attributes
    }
    return attributes + [previousAttribute]
}

/// Handles a server deletion when "save deleted messages" is on: the message stays and is marked
/// deleted instead. Returns the ids that should still be deleted for real.
func etonaKeepDeletedMessages(transaction: Transaction, ids: [MessageId]) -> [MessageId] {
    guard EtonaSettings.shared.saveDeletedMessages else {
        return ids
    }
    let timestamp = Int32(Date().timeIntervalSince1970)
    var remaining: [MessageId] = []
    for id in ids {
        guard id.namespace == Namespaces.Message.Cloud, let message = transaction.getMessage(id), etonaShouldKeepDeleted(message) else {
            remaining.append(id)
            continue
        }
        if message.etonaIsDeleted {
            continue
        }
        transaction.updateMessage(id, update: { current in
            let storeForwardInfo = current.forwardInfo.flatMap(StoreMessageForwardInfo.init)
            let attributes = etonaAttributes(current.attributes, updating: { $0.withDeletedDate(timestamp) })
            return .update(StoreMessage(id: current.id, customStableId: nil, globallyUniqueId: current.globallyUniqueId, groupingKey: current.groupingKey, threadId: current.threadId, timestamp: current.timestamp, flags: StoreMessageFlags(current.flags), tags: current.tags, globalTags: current.globalTags, localTags: current.localTags, forwardInfo: storeForwardInfo, authorId: current.author?.id, text: current.text, attributes: attributes, media: current.media))
        })
    }
    return remaining
}

private func etonaShouldKeepDeleted(_ message: Message) -> Bool {
    // Service messages (joins, pins, …) are not worth keeping.
    for media in message.media {
        if media is TelegramMediaAction {
            return false
        }
    }
    return true
}

/// Records the text a message had before an edit.
func etonaRecordEdit(previous: Message, updated: StoreMessage) -> StoreMessage {
    guard EtonaSettings.shared.saveEditHistory, previous.text != updated.text, !previous.text.isEmpty else {
        return updated
    }
    var editDate = Int32(Date().timeIntervalSince1970)
    for attribute in updated.attributes {
        if let attribute = attribute as? EditedMessageAttribute {
            editDate = attribute.date
        }
    }
    let attributes = etonaAttributes(updated.attributes, updating: { $0.withAddedEdit(EtonaMessageAttribute.EditEntry(text: previous.text, date: editDate)) })
    return updated.withUpdatedAttributes(attributes)
}
