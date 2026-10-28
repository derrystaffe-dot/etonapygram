import Foundation
import UIKit
import Display
import AccountContext
import TelegramCore
import TelegramPresentationData
import UndoUI
import EtonaSettings
import EtonaSettingsUI

/// The id as the Bot API writes it, which is what people usually look for.
func etonaDisplayPeerId(_ peerId: EnginePeer.Id) -> String {
    let id = peerId.id._internalGetInt64Value()
    if peerId.namespace == Namespaces.Peer.CloudChannel {
        return "-100\(id)"
    } else if peerId.namespace == Namespaces.Peer.CloudGroup {
        return "-\(id)"
    } else {
        return "\(id)"
    }
}

/// "Show ID" and "Registration date" rows for a profile.
func etonaPeerInfoItems(peer: EnginePeer, presentationData: PresentationData, interaction: PeerInfoInteraction) -> [PeerInfoScreenItem] {
    let settings = EtonaSettings.shared
    let strings = etonaStrings(presentationData.strings)
    var items: [PeerInfoScreenItem] = []

    let copy: (String) -> Void = { text in
        UIPasteboard.general.string = text
        interaction.getController()?.present(UndoOverlayController(presentationData: presentationData, content: .copy(text: strings.copied), elevatedLayout: false, action: { _ in
            return false
        }), in: .current)
    }

    if settings.showPeerId {
        let idText = etonaDisplayPeerId(peer.id)
        items.append(PeerInfoScreenLabeledValueItem(id: "etona.id", label: strings.peerId, text: idText, textColor: .primary, action: { _, _ in
            copy(idText)
        }, longTapAction: { _ in
            copy(idText)
        }, requestLayout: { animated in
            interaction.requestLayout(animated)
        }))
    }

    if settings.showRegistrationDate, case let .user(user) = peer, user.botInfo == nil, let date = EtonaRegistrationDate.approximateDate(userId: user.id.id._internalGetInt64Value()) {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: presentationData.strings.baseLanguageCode)
        formatter.setLocalizedDateFormatFromTemplate("LLLLyyyy")
        let dateText = "~ " + formatter.string(from: date)
        items.append(PeerInfoScreenLabeledValueItem(id: "etona.registration", label: strings.registrationDate, text: dateText, textColor: .primary, action: nil, requestLayout: { animated in
            interaction.requestLayout(animated)
        }))
    }

    return items
}

/// Spoiler entities for the account's own phone number while the phone spoiler is on.
func etonaPhoneSpoilerEntities(text: String, isOwnNumber: Bool) -> [MessageTextEntity] {
    guard isOwnNumber, EtonaSettings.shared.phoneSpoiler else {
        return []
    }
    return [MessageTextEntity(range: 0 ..< (text as NSString).length, type: .Spoiler)]
}

/// The account's own phone number with every digit but the last two masked, for places that
/// cannot show a spoiler (the settings header).
func etonaMaskedPhoneNumber(_ formatted: String) -> String {
    guard EtonaSettings.shared.phoneSpoiler else {
        return formatted
    }
    let digitCount = formatted.filter(\.isNumber).count
    var seenDigits = 0
    var result = ""
    for character in formatted {
        if character.isNumber {
            seenDigits += 1
            result.append(seenDigits > digitCount - 2 ? character : "•")
        } else {
            result.append(character)
        }
    }
    return result
}
