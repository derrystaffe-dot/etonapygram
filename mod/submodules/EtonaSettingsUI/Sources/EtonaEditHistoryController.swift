import Foundation
import UIKit
import Display
import SwiftSignalKit
import TelegramCore
import TelegramPresentationData
import TelegramStringFormatting
import TextFormat
import ItemListUI
import PresentationDataUtils
import AccountContext

private final class EtonaEditHistoryArguments {
    let copy: (String) -> Void

    init(copy: @escaping (String) -> Void) {
        self.copy = copy
    }
}

private enum EtonaEditHistoryEntry: ItemListNodeEntry {
    case header(index: Int32, text: String)
    case text(index: Int32, text: String)

    var section: ItemListSectionId {
        switch self {
        case let .header(index, _), let .text(index, _):
            return index
        }
    }

    var stableId: Int32 {
        switch self {
        case let .header(index, _):
            return index * 2
        case let .text(index, _):
            return index * 2 + 1
        }
    }

    static func <(lhs: EtonaEditHistoryEntry, rhs: EtonaEditHistoryEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! EtonaEditHistoryArguments
        switch self {
        case let .header(_, text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: self.section)
        case let .text(_, text):
            return ItemListMultilineTextItem(presentationData: presentationData, text: text, enabledEntityTypes: [], sectionId: self.section, style: .blocks, longTapAction: {
                arguments.copy(text)
            })
        }
    }
}

/// Earlier versions of an edited message, oldest first, followed by the current text.
public func etonaEditHistoryController(context: AccountContext, message: EngineMessage) -> ViewController {
    var presentControllerImpl: ((ViewController) -> Void)?

    let arguments = EtonaEditHistoryArguments(copy: { text in
        UIPasteboard.general.string = text
        let presentationData = context.sharedContext.currentPresentationData.with { $0 }
        presentControllerImpl?(textAlertController(context: context, title: nil, text: presentationData.strings.Conversation_MessageCopied, actions: [TextAlertAction(type: .defaultAction, title: presentationData.strings.Common_OK, action: {})]))
    })

    let signal = context.sharedContext.presentationData
    |> map { presentationData -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let presentationData = presentationData.withUpdated(theme: presentationData.theme.withModalBlocksBackground())
        let strings = etonaStrings(presentationData.strings)

        var entries: [EtonaEditHistoryEntry] = []
        // An entry's date is when that text was replaced, so each text was current from the
        // previous entry's date (or the send date) on.
        var since = message.timestamp
        for (i, edit) in message.etonaEditHistory.enumerated() {
            let date = stringForMediumDate(timestamp: since, strings: presentationData.strings, dateTimeFormat: presentationData.dateTimeFormat)
            entries.append(.header(index: Int32(i), text: date.uppercased()))
            entries.append(.text(index: Int32(i), text: edit.text.isEmpty ? " " : edit.text))
            since = edit.date
        }
        let current = Int32(entries.count / 2)
        let currentDate = stringForMediumDate(timestamp: since, strings: presentationData.strings, dateTimeFormat: presentationData.dateTimeFormat)
        entries.append(.header(index: current, text: "\(strings.editHistoryCurrent) · \(currentDate)".uppercased()))
        entries.append(.text(index: current, text: message.text.isEmpty ? " " : message.text))

        let controllerState = ItemListControllerState(presentationData: ItemListPresentationData(presentationData), title: .text(strings.editHistoryTitle), leftNavigationButton: nil, rightNavigationButton: nil, backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back))
        let listState = ItemListNodeState(presentationData: ItemListPresentationData(presentationData), entries: entries, style: .blocks, animateChanges: false)
        return (controllerState, (listState, arguments))
    }

    let controller = ItemListController(context: context, state: signal)
    presentControllerImpl = { [weak controller] c in
        controller?.present(c, in: .window(.root))
    }
    return controller
}
