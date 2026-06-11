import SwiftUI

struct KeyboardView: View {
    @ObservedObject var viewModel: GameViewModel
    let isIPad: Bool
    
    let rows = [
        ["Ä", "W", "E", "R", "T", "Y", "U", "I", "O", "P", "Ö"],
        ["A", "S", "D", "F", "G", "H", "J", "K", "L", "Ň", "Ş"],
        ["Z", "Ü", "Ç", "Ý", "B", "N", "M", "C", "V", "Ž", "-"]
    ]
    
    var keyHeight: CGFloat { isIPad ? 56 : 44 }
    var keyFontSize: CGFloat { isIPad ? 20 : 16 }
    var keySpacing: CGFloat { isIPad ? 8 : 6 }
    
    var body: some View {
        VStack(spacing: keySpacing) {
            ForEach(0..<rows.count, id: \.self) { rowIndex in
                HStack(spacing: keySpacing) {
                    let row = rows[rowIndex]
                    let padding = (11 - row.count) / 2
                    
                    ForEach(0..<padding, id: \.self) { _ in
                        Color.clear.frame(width: 0, height: 0)
                    }
                    
                    ForEach(row, id: \.self) { letter in
                        KeyButton(
                            letter: letter,
                            isGuessed: viewModel.isLetterGuessed(Character(letter)),
                            isCorrect: viewModel.isLetterCorrect(Character(letter)),
                            isDisabled: viewModel.gameOver,
                            keyHeight: keyHeight,
                            keyFontSize: keyFontSize
                        ) {
                            viewModel.guessLetter(Character(letter))
                        }
                    }
                    
                    ForEach(0..<(11 - row.count - padding), id: \.self) { _ in
                        Color.clear.frame(width: 0, height: 0)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
    }
}

struct KeyButton: View {
    let letter: String
    let isGuessed: Bool
    let isCorrect: Bool
    let isDisabled: Bool
    let keyHeight: CGFloat
    let keyFontSize: CGFloat
    let action: () -> Void
    
    var backgroundColor: Color {
        if !isGuessed { return Color.white }
        return isCorrect
            ? Color(red: 0.91, green: 0.97, blue: 0.93)
            : Color(red: 0.99, green: 0.92, blue: 0.92)
    }
    
    var borderColor: Color {
        if !isGuessed { return Color(red: 0.89, green: 0.89, blue: 0.89) }
        return isCorrect
            ? Color(red: 0.60, green: 0.85, blue: 0.67)
            : Color(red: 0.90, green: 0.63, blue: 0.63)
    }
    
    var displayText: String {
        if letter == "'" { return "'" }
        return letter
    }
    
    var body: some View {
        Button(action: {
            if !isDisabled && !isGuessed {
                action()
            }
        }) {
            Text(displayText)
                .font(.system(size: keyFontSize, weight: .regular))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .frame(height: keyHeight)
                .background(backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(borderColor, lineWidth: 1)
                )
                .cornerRadius(14)
        }
        .disabled(isDisabled || isGuessed)
    }
}
