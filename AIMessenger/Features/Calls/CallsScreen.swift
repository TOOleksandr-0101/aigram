import SwiftUI

struct CallsScreen: View {
    private let calls = CallRecord.sampleCalls

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                topBar

                ForEach(Array(calls.enumerated()), id: \.element.id) { index, call in
                    callRow(call: call, showSeparator: index < calls.count - 1)
                }
            }
            .padding(.bottom, 96)
        }
        .background(TelegramPalette.backgroundPrimary)
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
    }

    private var topBar: some View {
        VStack(spacing: 12) {
            HStack {
                Button("Edit") { }
                    .font(.system(size: 17))
                    .foregroundStyle(.white)

                Spacer()

                Text("Calls")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)

                Spacer()

                Button {
                } label: {
                    Image(systemName: "phone.badge.plus")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.white)
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

    private func callRow(call: CallRecord, showSeparator: Bool) -> some View {
        HStack(spacing: 10) {
            AvatarView(kind: call.avatar, showsOnlineDot: false)

            VStack(alignment: .leading, spacing: 3) {
                Text(call.name)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.white)

                Text(call.detail)
                    .font(.system(size: 15))
                    .foregroundStyle(call.direction.color)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 8) {
                Text(call.date)
                    .font(.system(size: 14))
                    .foregroundStyle(TelegramPalette.mutedText)

                Image(systemName: "info.circle")
                    .font(.system(size: 18))
                    .foregroundStyle(TelegramPalette.accentBlue)
            }
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

struct CallsScreen_Previews: PreviewProvider {
    static var previews: some View {
        CallsScreen()
    }
}
