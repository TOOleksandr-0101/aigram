import SwiftUI

struct ContactsScreen: View {
    let onOpenContact: (ContactProfile) -> Void

    private let contacts = ContactProfile.sampleContacts

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                topBar
                actionRow(title: "Add People Nearby", symbol: "person.crop.circle.badge.plus", tint: TelegramPalette.accentBlue)
                actionRow(title: "Invite Friends", symbol: "square.and.arrow.up", tint: TelegramPalette.accentBlue)

                ForEach(Array(contacts.enumerated()), id: \.element.id) { index, contact in
                    Button {
                        onOpenContact(contact)
                    } label: {
                        contactRow(contact: contact, showSeparator: index < contacts.count - 1)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.bottom, 96)
        }
        .background(TelegramPalette.backgroundPrimary)
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
    }

    private var topBar: some View {
        VStack(spacing: 10) {
            HStack {
                Button("Sort") { }
                    .font(.system(size: 17))
                    .foregroundStyle(.white.opacity(0.92))

                Spacer()

                Text("Contacts")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)

                Spacer()

                Button {
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 24, height: 24)
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.top, 8)
        .padding(.bottom, 12)
        .background(TelegramPalette.backgroundElevated)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(TelegramPalette.separator)
                .frame(height: 0.5)
        }
    }

    private func actionRow(title: String, symbol: String, tint: Color) -> some View {
        HStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(tint)
                .frame(width: 26)

            Text(title)
                .font(.system(size: 17))
                .foregroundStyle(.white)

            Spacer()
        }
        .padding(.horizontal, 16)
        .frame(height: 44)
        .background(TelegramPalette.backgroundPrimary)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(TelegramPalette.separator)
                .frame(height: 0.5)
                .padding(.leading, 16)
        }
    }

    private func contactRow(contact: ContactProfile, showSeparator: Bool) -> some View {
        HStack(spacing: 10) {
            AvatarView(kind: contact.avatar, showsOnlineDot: contact.presence.isOnline)

            VStack(alignment: .leading, spacing: 3) {
                Text("\(contact.firstName) \(contact.lastName)")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.white)

                Text(contact.presence.label)
                    .font(.system(size: 15))
                    .foregroundStyle(contact.presence.isOnline ? TelegramPalette.accentBlue : TelegramPalette.mutedText)
            }

            Spacer()
        }
        .padding(.horizontal, 10)
        .frame(height: 76)
        .background(TelegramPalette.backgroundPrimary)
        .overlay(alignment: .bottom) {
            if showSeparator {
                Rectangle()
                    .fill(TelegramPalette.separator)
                    .frame(height: 0.5)
                    .padding(.leading, 79)
            }
        }
    }
}

struct ContactInfoScreen: View {
    let contact: ContactProfile
    let onEdit: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            lightTopBar(title: "Info", trailingTitle: "Edit", trailingAction: onEdit)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    profileHeader
                    infoGroup
                    actionGroup
                    communicationGroup
                    destructiveButton(title: "Block User")
                }
                .padding(.top, 16)
                .padding(.bottom, 40)
            }
            .background(TelegramPalette.groupedBackground)
        }
        .background(TelegramPalette.groupedBackground.ignoresSafeArea())
        .preferredColorScheme(.light)
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
    }

    private var profileHeader: some View {
        VStack(spacing: 12) {
            AvatarView(kind: contact.avatar, showsOnlineDot: contact.presence.isOnline)
                .frame(width: 82, height: 82)
                .scaleEffect(1.32)

            Text("\(contact.firstName) \(contact.lastName)")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(.black)

            Text(contact.presence.isOnline ? "online" : "last seen recently")
                .font(.system(size: 15))
                .foregroundStyle(contact.presence.isOnline ? TelegramPalette.accentBlue : Color(hex: 0x636366))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    private var infoGroup: some View {
        LightGroupCard {
            InfoValueRow(title: "username", value: contact.username)
            DividerLine()
            InfoValueRow(title: "main", value: contact.mainPhone)
            DividerLine()
            InfoValueRow(title: "home", value: contact.homePhone)
            DividerLine()
            InfoValueRow(title: "bio", value: contact.bio, multiline: true)
        }
    }

    private var actionGroup: some View {
        LightGroupCard {
            PlainTextRow(title: "Share Contact", titleColor: TelegramPalette.accentBlue)
            DividerLine()
            PlainTextRow(title: "Send Message", titleColor: TelegramPalette.accentBlue)
            DividerLine()
            PlainTextRow(title: "Start Secret Chat", titleColor: TelegramPalette.accentBlue)
        }
    }

    private var communicationGroup: some View {
        LightGroupCard {
            ChevronValueRow(title: "Shared Media", value: "Enabled")
            DividerLine()
            ChevronValueRow(title: "Notifications", value: "1")
            DividerLine()
            ChevronValueRow(title: "Groups In Common", value: nil)
        }
    }

    private func destructiveButton(title: String) -> some View {
        Text(title)
            .font(.system(size: 17))
            .foregroundStyle(Color(hex: 0xFE3B30))
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .padding(.horizontal, 12)
    }

    private func lightTopBar(title: String, trailingTitle: String, trailingAction: @escaping () -> Void) -> some View {
        HStack {
            Button {
                dismiss()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Back")
                        .font(.system(size: 17))
                }
                .foregroundStyle(TelegramPalette.accentBlue)
            }

            Spacer()

            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.black)

            Spacer()

            Button(trailingTitle, action: trailingAction)
                .font(.system(size: 17))
                .foregroundStyle(TelegramPalette.accentBlue)
        }
        .padding(.horizontal, 12)
        .frame(height: 44)
        .background(Color(hex: 0xF6F6F6))
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.black.opacity(0.12))
                .frame(height: 0.5)
        }
    }
}

struct EditableContactInfoScreen: View {
    let contact: ContactProfile

    @Environment(\.dismiss) private var dismiss
    @State private var firstName: String
    @State private var lastName: String
    @State private var bio: String

    init(contact: ContactProfile) {
        self.contact = contact
        _firstName = State(initialValue: contact.firstName)
        _lastName = State(initialValue: contact.lastName)
        _bio = State(initialValue: contact.bio)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .font(.system(size: 17))
                .foregroundStyle(TelegramPalette.accentBlue)

                Spacer()

                Text("Info")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.black)

                Spacer()

                Button("Done") {
                    dismiss()
                }
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(TelegramPalette.accentBlue)
            }
            .padding(.horizontal, 16)
            .frame(height: 44)
            .background(Color(hex: 0xF6F6F6))
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(Color.black.opacity(0.12))
                    .frame(height: 0.5)
            }

            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    VStack(spacing: 0) {
                        HStack(spacing: 14) {
                            AvatarView(kind: contact.avatar, showsOnlineDot: false)

                            VStack(spacing: 16) {
                                TextField("John", text: $firstName)
                                    .font(.system(size: 17))
                                DividerLine()
                                TextField("Zack", text: $lastName)
                                    .font(.system(size: 17))
                            }
                        }
                        .padding(.horizontal, 15)
                        .padding(.vertical, 13)
                        .background(Color.white)

                        Text("Enter contact name and update profile details.")
                            .font(.system(size: 14))
                            .foregroundStyle(Color(hex: 0x636366))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                    }

                    LightGroupCard {
                        InfoValueRow(title: "main", value: contact.mainPhone)
                        DividerLine()
                        InfoValueRow(title: "home", value: contact.homePhone)
                        DividerLine()
                        HStack(alignment: .top) {
                            Text("bio")
                                .font(.system(size: 15))
                                .foregroundStyle(Color(hex: 0x636366))
                                .frame(width: 86, alignment: .leading)

                            TextField("Bio", text: $bio, axis: .vertical)
                                .font(.system(size: 17))
                                .foregroundStyle(.black)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }

                    LightGroupCard {
                        ChevronValueRow(title: "Notifications", value: "Enabled")
                    }

                    Text("Delete Contact")
                        .font(.system(size: 17))
                        .foregroundStyle(Color(hex: 0xFE3B30))
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .padding(.horizontal, 12)
                }
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
            .background(TelegramPalette.groupedBackground)
        }
        .background(TelegramPalette.groupedBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
    }
}

private struct LightGroupCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .padding(.horizontal, 12)
    }
}

private struct DividerLine: View {
    var body: some View {
        Rectangle()
            .fill(Color.black.opacity(0.08))
            .frame(height: 0.5)
            .padding(.leading, 16)
    }
}

private struct InfoValueRow: View {
    let title: String
    let value: String
    var multiline = false

    var body: some View {
        HStack(alignment: multiline ? .top : .center) {
            Text(title)
                .font(.system(size: 15))
                .foregroundStyle(Color(hex: 0x636366))
                .frame(width: 86, alignment: .leading)

            Text(value)
                .font(.system(size: 17))
                .foregroundStyle(.black)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: multiline)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

private struct PlainTextRow: View {
    let title: String
    let titleColor: Color

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 17))
                .foregroundStyle(titleColor)
            Spacer()
        }
        .padding(.horizontal, 16)
        .frame(height: 44)
    }
}

private struct ChevronValueRow: View {
    let title: String
    let value: String?

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 17))
                .foregroundStyle(.black)

            Spacer()

            if let value {
                Text(value)
                    .font(.system(size: 17))
                    .foregroundStyle(Color.black.opacity(0.6))
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color(hex: 0xC7C7CC))
        }
        .padding(.horizontal, 16)
        .frame(height: 44)
    }
}

struct ContactsFlow_Previews: PreviewProvider {
    static var previews: some View {
        ContactsScreen { _ in }
    }
}
