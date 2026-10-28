import Foundation
import UIKit
import Display
import TelegramPresentationData

/// The mod's own strings. Russian when the app language is Russian, English otherwise.
public struct EtonaStrings {
    public let title: String
    public let entryTitle: String

    let ghostHeader: String
    let ghostMode: String
    let hideOnline: String
    let hideTyping: String
    let hideRecordingVideo: String
    let hideUploadingVideo: String
    let hideRecordingVoice: String
    let hideUploadingVoice: String
    let hideUploadingPhoto: String
    let hideUploadingFile: String
    let hideReadReceipts: String
    let hideListened: String
    let anonymousStories: String
    let ghostFooter: String

    let exceptionsHeader: String
    let addException: String
    let exceptionsFooter: String

    let profileHeader: String
    let showPeerId: String
    let phoneSpoiler: String
    let showRegistrationDate: String
    let profileFooter: String

    let chatsHeader: String
    let saveDeletedMessages: String
    let saveEditHistory: String
    let chatsFooter: String

    public let deletedMark: String
    public let editHistoryAction: String
    public let editHistoryTitle: String
    public let editHistoryCurrent: String
    public let registrationDate: String
    public let peerId: String
    public let copied: String

    static let russian = EtonaStrings(
        title: "etonapygram",
        entryTitle: "etonapygram",
        ghostHeader: "РЕЖИМ-ПРИЗРАК",
        ghostMode: "Режим-призрак",
        hideOnline: "Скрывать «в сети»",
        hideTyping: "Скрывать «печатает»",
        hideRecordingVideo: "Скрывать «записывает видео»",
        hideUploadingVideo: "Скрывать «отправляет видео»",
        hideRecordingVoice: "Скрывать «записывает голосовое»",
        hideUploadingVoice: "Скрывать «отправляет голосовое»",
        hideUploadingPhoto: "Скрывать «отправляет фото»",
        hideUploadingFile: "Скрывать «отправляет файл»",
        hideReadReceipts: "Скрывать прочтение",
        hideListened: "Скрывать прослушано/просмотрено",
        anonymousStories: "Анонимный просмотр историй",
        ghostFooter: "Пользуйся Telegram незаметно. Выбери, что именно скрывать. Работает только при включённом режиме-призраке.",
        exceptionsHeader: "ИСКЛЮЧЕНИЯ РЕЖИМА-ПРИЗРАКА",
        addException: "Добавить исключение…",
        exceptionsFooter: "Люди из списка всегда видят твой настоящий статус, даже с включённым режимом-призраком. Смахни влево, чтобы убрать.",
        profileHeader: "ПРОФИЛЬ",
        showPeerId: "Показывать ID",
        phoneSpoiler: "Спойлер на номере телефона",
        showRegistrationDate: "Дата регистрации",
        profileFooter: "«Показывать ID» показывает внутренний ID пользователя, чата или канала в профиле. «Спойлер на номере» прячет номер под спойлер, пока не нажмёшь. «Дата регистрации» показывает примерную дату создания аккаунта.",
        chatsHeader: "СООБЩЕНИЯ",
        saveDeletedMessages: "Сохранять удалённые сообщения",
        saveEditHistory: "Сохранять историю изменений",
        chatsFooter: "Удалённые сообщения остаются в чате с пометкой. Старые версии изменённых сообщений видны в меню сообщения.",
        deletedMark: "удалено",
        editHistoryAction: "История изменений",
        editHistoryTitle: "История изменений",
        editHistoryCurrent: "Сейчас",
        registrationDate: "дата регистрации",
        peerId: "ID",
        copied: "ID скопирован"
    )

    static let english = EtonaStrings(
        title: "etonapygram",
        entryTitle: "etonapygram",
        ghostHeader: "GHOST MODE",
        ghostMode: "Ghost Mode",
        hideOnline: "Hide “online”",
        hideTyping: "Hide “typing”",
        hideRecordingVideo: "Hide “recording video”",
        hideUploadingVideo: "Hide “sending video”",
        hideRecordingVoice: "Hide “recording voice”",
        hideUploadingVoice: "Hide “sending voice”",
        hideUploadingPhoto: "Hide “sending photo”",
        hideUploadingFile: "Hide “sending file”",
        hideReadReceipts: "Hide read receipts",
        hideListened: "Hide listened/watched",
        anonymousStories: "View stories anonymously",
        ghostFooter: "Use Telegram unnoticed. Choose what to hide. Works only while Ghost Mode is on.",
        exceptionsHeader: "GHOST MODE EXCEPTIONS",
        addException: "Add Exception…",
        exceptionsFooter: "People in this list always see your real status, even with Ghost Mode on. Swipe left to remove.",
        profileHeader: "PROFILE",
        showPeerId: "Show ID",
        phoneSpoiler: "Spoiler on Phone Number",
        showRegistrationDate: "Registration Date",
        profileFooter: "“Show ID” shows the internal ID of a user, chat or channel in its profile. “Spoiler on phone number” hides your number until tapped. “Registration date” shows the approximate account creation date.",
        chatsHeader: "MESSAGES",
        saveDeletedMessages: "Keep Deleted Messages",
        saveEditHistory: "Keep Edit History",
        chatsFooter: "Deleted messages stay in the chat with a mark. Earlier versions of edited messages are in the message menu.",
        deletedMark: "deleted",
        editHistoryAction: "Edit History",
        editHistoryTitle: "Edit History",
        editHistoryCurrent: "Now",
        registrationDate: "registration date",
        peerId: "ID",
        copied: "ID copied"
    )
}

public func etonaStrings(_ strings: PresentationStrings) -> EtonaStrings {
    let code = strings.baseLanguageCode.lowercased()
    if code.hasPrefix("ru") || code.hasPrefix("uk") || code.hasPrefix("be") {
        return .russian
    }
    return .english
}

public let etonaSettingsIcon: UIImage? = renderSettingsIcon(name: "Item List/Icons/LastSeen", backgroundColors: [UIColor(rgb: 0x8E59E8), UIColor(rgb: 0xC86DD7)])
