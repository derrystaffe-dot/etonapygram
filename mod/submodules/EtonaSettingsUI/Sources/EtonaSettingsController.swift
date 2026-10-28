import Foundation
import UIKit
import Display
import SwiftSignalKit
import TelegramCore
import TelegramPresentationData
import ItemListUI
import ItemListPeerItem
import ItemListPeerActionItem
import PresentationDataUtils
import AccountContext
import EtonaSettings

private final class EtonaSettingsControllerArguments {
    let context: AccountContext
    let toggle: (EtonaSettings.Key, Bool) -> Void
    let addException: () -> Void
    let removeException: (EnginePeer.Id) -> Void
    let readAll: () -> Void
    let setPeerIdWithRevealedOptions: (EnginePeer.Id?, EnginePeer.Id?) -> Void

    init(
        context: AccountContext,
        toggle: @escaping (EtonaSettings.Key, Bool) -> Void,
        addException: @escaping () -> Void,
        removeException: @escaping (EnginePeer.Id) -> Void,
        readAll: @escaping () -> Void,
        setPeerIdWithRevealedOptions: @escaping (EnginePeer.Id?, EnginePeer.Id?) -> Void
    ) {
        self.context = context
        self.toggle = toggle
        self.addException = addException
        self.removeException = removeException
        self.readAll = readAll
        self.setPeerIdWithRevealedOptions = setPeerIdWithRevealedOptions
    }
}

private enum EtonaSettingsSection: Int32 {
    case ghost
    case exceptions
    case profile
    case chats
}

private enum EtonaSettingsEntry: ItemListNodeEntry {
    case ghostHeader(String)
    case toggle(index: Int32, section: EtonaSettingsSection, key: EtonaSettings.Key, title: String, value: Bool, enabled: Bool)
    case ghostFooter(String)

    case exceptionsHeader(String)
    case addException(String)
    case exception(index: Int32, peer: EnginePeer, revealed: Bool)
    case exceptionsFooter(String)

    case profileHeader(String)
    case profileFooter(String)

    case chatsHeader(String)
    case chatsFooter(String)
    case readAll(String)

    var section: ItemListSectionId {
        switch self {
        case .ghostHeader, .ghostFooter:
            return EtonaSettingsSection.ghost.rawValue
        case let .toggle(_, section, _, _, _, _):
            return section.rawValue
        case .exceptionsHeader, .addException, .exception, .exceptionsFooter:
            return EtonaSettingsSection.exceptions.rawValue
        case .profileHeader, .profileFooter:
            return EtonaSettingsSection.profile.rawValue
        case .chatsHeader, .chatsFooter, .readAll:
            return EtonaSettingsSection.chats.rawValue
        }
    }

    var stableId: Int32 {
        switch self {
        case .ghostHeader:
            return 0
        case let .toggle(index, section, _, _, _, _):
            return (section.rawValue + 1) * 1000 + index
        case .ghostFooter:
            return 1999
        case .exceptionsHeader:
            return 2000
        case .addException:
            return 2001
        case let .exception(index, _, _):
            return 2100 + index
        case .exceptionsFooter:
            return 2999
        case .profileHeader:
            return 3000
        case .profileFooter:
            return 3999
        case .chatsHeader:
            return 4000
        case .chatsFooter:
            return 4998
        case .readAll:
            return 4999
        }
    }

    static func ==(lhs: EtonaSettingsEntry, rhs: EtonaSettingsEntry) -> Bool {
        switch lhs {
        case let .ghostHeader(text):
            if case .ghostHeader(text) = rhs { return true } else { return false }
        case let .toggle(index, section, key, title, value, enabled):
            if case .toggle(index, section, key, title, value, enabled) = rhs { return true } else { return false }
        case let .ghostFooter(text):
            if case .ghostFooter(text) = rhs { return true } else { return false }
        case let .exceptionsHeader(text):
            if case .exceptionsHeader(text) = rhs { return true } else { return false }
        case let .addException(text):
            if case .addException(text) = rhs { return true } else { return false }
        case let .exception(index, peer, revealed):
            if case .exception(index, peer, revealed) = rhs { return true } else { return false }
        case let .exceptionsFooter(text):
            if case .exceptionsFooter(text) = rhs { return true } else { return false }
        case let .profileHeader(text):
            if case .profileHeader(text) = rhs { return true } else { return false }
        case let .profileFooter(text):
            if case .profileFooter(text) = rhs { return true } else { return false }
        case let .chatsHeader(text):
            if case .chatsHeader(text) = rhs { return true } else { return false }
        case let .chatsFooter(text):
            if case .chatsFooter(text) = rhs { return true } else { return false }
        case let .readAll(text):
            if case .readAll(text) = rhs { return true } else { return false }
        }
    }

    static func <(lhs: EtonaSettingsEntry, rhs: EtonaSettingsEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! EtonaSettingsControllerArguments
        switch self {
        case let .ghostHeader(text), let .exceptionsHeader(text), let .profileHeader(text), let .chatsHeader(text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: self.section)
        case let .ghostFooter(text), let .exceptionsFooter(text), let .profileFooter(text), let .chatsFooter(text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: self.section)
        case let .toggle(_, _, key, title, value, enabled):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: title, value: value, enabled: enabled, maximumNumberOfLines: 2, sectionId: self.section, style: .blocks, updated: { value in
                arguments.toggle(key, value)
            })
        case let .readAll(text):
            return ItemListActionItem(presentationData: presentationData, systemStyle: .glass, title: text, kind: .generic, alignment: .natural, sectionId: self.section, style: .blocks, action: {
                arguments.readAll()
            })
        case let .addException(text):
            return ItemListPeerActionItem(presentationData: presentationData, systemStyle: .glass, icon: PresentationResourcesItemList.addPersonIcon(presentationData.theme), title: text, sectionId: self.section, height: .generic, editing: false, action: {
                arguments.addException()
            })
        case let .exception(_, peer, revealed):
            let strings = presentationData.strings
            let revealOptions = ItemListPeerItemRevealOptions(options: [ItemListPeerItemRevealOption(type: .destructive, title: strings.Common_Delete, action: {
                arguments.removeException(peer.id)
            })])
            return ItemListPeerItem(presentationData: presentationData, systemStyle: .glass, dateTimeFormat: PresentationDateTimeFormat(), nameDisplayOrder: .firstLast, context: arguments.context, peer: peer, presence: nil, text: .none, label: .none, editing: ItemListPeerItemEditing(editable: true, editing: false, revealed: revealed), revealOptions: revealOptions, switchValue: nil, enabled: true, selectable: false, sectionId: self.section, action: nil, setPeerIdWithRevealedOptions: { previousId, id in
                arguments.setPeerIdWithRevealedOptions(previousId, id)
            }, removePeer: { peerId in
                arguments.removeException(peerId)
            })
        }
    }
}

private struct EtonaSettingsState: Equatable {
    var version: Int = 0
    var peerIdWithRevealedOptions: EnginePeer.Id?
}

private func etonaSettingsEntries(strings s: EtonaStrings, state: EtonaSettingsState, exceptionPeers: [EnginePeer]) -> [EtonaSettingsEntry] {
    let settings = EtonaSettings.shared
    let ghostMode = settings.ghostMode
    var entries: [EtonaSettingsEntry] = []

    entries.append(.ghostHeader(s.ghostHeader))
    entries.append(.toggle(index: 0, section: .ghost, key: .ghostMode, title: s.ghostMode, value: ghostMode, enabled: true))
    let ghostKeys: [(EtonaSettings.Key, String)] = [
        (.hideOnline, s.hideOnline),
        (.hideTyping, s.hideTyping),
        (.hideRecordingVideo, s.hideRecordingVideo),
        (.hideUploadingVideo, s.hideUploadingVideo),
        (.hideRecordingVoice, s.hideRecordingVoice),
        (.hideUploadingVoice, s.hideUploadingVoice),
        (.hideUploadingPhoto, s.hideUploadingPhoto),
        (.hideUploadingFile, s.hideUploadingFile),
        (.hideReadReceipts, s.hideReadReceipts),
        (.hideListened, s.hideListened),
        (.anonymousStories, s.anonymousStories),
    ]
    for (i, item) in ghostKeys.enumerated() {
        entries.append(.toggle(index: Int32(i + 1), section: .ghost, key: item.0, title: item.1, value: settings.bool(item.0), enabled: ghostMode))
    }
    entries.append(.ghostFooter(s.ghostFooter))

    entries.append(.exceptionsHeader(s.exceptionsHeader))
    entries.append(.addException(s.addException))
    for (i, peer) in exceptionPeers.enumerated() {
        entries.append(.exception(index: Int32(i), peer: peer, revealed: state.peerIdWithRevealedOptions == peer.id))
    }
    entries.append(.exceptionsFooter(s.exceptionsFooter))

    entries.append(.profileHeader(s.profileHeader))
    entries.append(.toggle(index: 0, section: .profile, key: .showPeerId, title: s.showPeerId, value: settings.showPeerId, enabled: true))
    entries.append(.toggle(index: 1, section: .profile, key: .phoneSpoiler, title: s.phoneSpoiler, value: settings.phoneSpoiler, enabled: true))
    entries.append(.toggle(index: 2, section: .profile, key: .showRegistrationDate, title: s.showRegistrationDate, value: settings.showRegistrationDate, enabled: true))
    entries.append(.profileFooter(s.profileFooter))

    entries.append(.chatsHeader(s.chatsHeader))
    entries.append(.toggle(index: 0, section: .chats, key: .saveDeletedMessages, title: s.saveDeletedMessages, value: settings.saveDeletedMessages, enabled: true))
    entries.append(.toggle(index: 1, section: .chats, key: .saveEditHistory, title: s.saveEditHistory, value: settings.saveEditHistory, enabled: true))
    entries.append(.chatsFooter(s.chatsFooter))
    entries.append(.readAll(s.readAll))

    return entries
}

public func etonaSettingsController(context: AccountContext) -> ViewController {
    let statePromise = ValuePromise(EtonaSettingsState(), ignoreRepeated: true)
    let stateValue = Atomic(value: EtonaSettingsState())
    let updateState: ((inout EtonaSettingsState) -> Void) -> Void = { f in
        statePromise.set(stateValue.modify { state in
            var state = state
            f(&state)
            return state
        })
    }
    let bumpVersion = {
        updateState { $0.version += 1 }
    }

    var pushControllerImpl: ((ViewController) -> Void)?
    var presentControllerImpl: ((ViewController) -> Void)?

    let arguments = EtonaSettingsControllerArguments(
        context: context,
        toggle: { key, value in
            EtonaSettings.shared.set(key, value)
            bumpVersion()
        },
        addException: {
            let controller = context.sharedContext.makePeerSelectionController(PeerSelectionControllerParams(context: context, filter: [.excludeSecretChats, .excludeChannels], hasContactSelector: true, hasGlobalSearch: true, title: etonaStrings(context.sharedContext.currentPresentationData.with { $0 }.strings).addException))
            controller.peerSelected = { [weak controller] peer, _ in
                EtonaSettings.shared.setGhostException(peerId: peer.id.toInt64(), true)
                bumpVersion()
                controller?.dismiss()
            }
            pushControllerImpl?(controller)
        },
        removeException: { peerId in
            EtonaSettings.shared.setGhostException(peerId: peerId.toInt64(), false)
            updateState { state in
                state.version += 1
                state.peerIdWithRevealedOptions = nil
            }
        },
        readAll: {
            let presentationData = context.sharedContext.currentPresentationData.with { $0 }
            let strings = etonaStrings(presentationData.strings)
            presentControllerImpl?(textAlertController(context: context, title: nil, text: strings.readAllConfirmation, actions: [
                TextAlertAction(type: .genericAction, title: presentationData.strings.Common_Cancel, action: {}),
                TextAlertAction(type: .defaultAction, title: strings.readAllConfirm, action: {
                    let _ = context.engine.messages.markAllChatsAsReadInteractively(items: [(groupId: .root, filterPredicate: nil), (groupId: .archive, filterPredicate: nil)]).startStandalone()
                })
            ]))
        },
        setPeerIdWithRevealedOptions: { previousId, id in
            updateState { state in
                if (previousId == nil && state.peerIdWithRevealedOptions == nil) || previousId == state.peerIdWithRevealedOptions {
                    state.peerIdWithRevealedOptions = id
                }
            }
        }
    )

    let exceptionPeers = statePromise.get()
    |> map { state -> Set<Int64> in
        let _ = state.version
        return EtonaSettings.shared.ghostExceptions
    }
    |> distinctUntilChanged
    |> mapToSignal { ids -> Signal<[EnginePeer], NoError> in
        let peerIds = ids.sorted().map { EnginePeer.Id($0) }
        return context.engine.data.subscribe(EngineDataList(peerIds.map(TelegramEngine.EngineData.Item.Peer.Peer.init(id:))))
        |> map { peers -> [EnginePeer] in
            return peers.compactMap { $0 }
        }
    }

    let signal = combineLatest(queue: .mainQueue(),
        context.sharedContext.presentationData,
        statePromise.get(),
        exceptionPeers
    )
    |> map { presentationData, state, exceptionPeers -> (ItemListControllerState, (ItemListNodeState, Any)) in
        var presentationData = presentationData
        presentationData = presentationData.withUpdated(theme: presentationData.theme.withModalBlocksBackground())
        let strings = etonaStrings(presentationData.strings)

        let controllerState = ItemListControllerState(presentationData: ItemListPresentationData(presentationData), title: .text(strings.title), leftNavigationButton: nil, rightNavigationButton: nil, backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back))
        let listState = ItemListNodeState(presentationData: ItemListPresentationData(presentationData), entries: etonaSettingsEntries(strings: strings, state: state, exceptionPeers: exceptionPeers), style: .blocks, animateChanges: true)
        return (controllerState, (listState, arguments))
    }

    let controller = ItemListController(context: context, state: signal)
    pushControllerImpl = { [weak controller] c in
        controller?.push(c)
    }
    presentControllerImpl = { [weak controller] c in
        controller?.present(c, in: .window(.root))
    }
    return controller
}
