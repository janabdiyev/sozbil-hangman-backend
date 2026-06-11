import SwiftUI

struct HangmanView: View {
    let wrongGuesses: Int
    
    var body: some View {
        GeometryReader { geometry in
            let w = geometry.size.width
            let h = geometry.size.height
            
            let baseY = h * 0.90
            let poleX = w * 0.28
            let topY = h * 0.12
            let beamX = w * 0.70
            let ropeY = h * 0.22
            
            let headR = w * 0.08
            let headCx = beamX
            let headCy = ropeY + headR
            
            Canvas { context, size in
                var path = Path()
                
                // Base
                path.move(to: CGPoint(x: w * 0.12, y: baseY))
                path.addLine(to: CGPoint(x: w * 0.70, y: baseY))
                
                // Pole
                path.move(to: CGPoint(x: poleX, y: baseY))
                path.addLine(to: CGPoint(x: poleX, y: topY))
                
                // Beam
                path.move(to: CGPoint(x: poleX, y: topY))
                path.addLine(to: CGPoint(x: beamX, y: topY))
                
                // Rope
                path.move(to: CGPoint(x: beamX, y: topY))
                path.addLine(to: CGPoint(x: beamX, y: ropeY))
                
                context.stroke(path, with: .color(.init(red: 0.13, green: 0.13, blue: 0.13)), lineWidth: 10)
                
                // Head
                if wrongGuesses >= 1 {
                    var headPath = Path()
                    headPath.addEllipse(in: CGRect(x: headCx - headR, y: headCy - headR, width: headR * 2, height: headR * 2))
                    context.stroke(headPath, with: .color(.init(red: 0.13, green: 0.13, blue: 0.13)), lineWidth: 10)
                }
                
                // Body
                if wrongGuesses >= 2 {
                    var bodyPath = Path()
                    bodyPath.move(to: CGPoint(x: headCx, y: headCy + headR))
                    bodyPath.addLine(to: CGPoint(x: headCx, y: headCy + headR + h * 0.22))
                    context.stroke(bodyPath, with: .color(.init(red: 0.13, green: 0.13, blue: 0.13)), lineWidth: 7)
                }
                
                // Left arm
                if wrongGuesses >= 3 {
                    var leftArmPath = Path()
                    leftArmPath.move(to: CGPoint(x: headCx, y: headCy + headR + h * 0.06))
                    leftArmPath.addLine(to: CGPoint(x: headCx - w * 0.11, y: headCy + headR + h * 0.15))
                    context.stroke(leftArmPath, with: .color(.init(red: 0.13, green: 0.13, blue: 0.13)), lineWidth: 7)
                }
                
                // Right arm
                if wrongGuesses >= 4 {
                    var rightArmPath = Path()
                    rightArmPath.move(to: CGPoint(x: headCx, y: headCy + headR + h * 0.06))
                    rightArmPath.addLine(to: CGPoint(x: headCx + w * 0.11, y: headCy + headR + h * 0.15))
                    context.stroke(rightArmPath, with: .color(.init(red: 0.13, green: 0.13, blue: 0.13)), lineWidth: 7)
                }
                
                // Left leg
                if wrongGuesses >= 5 {
                    var leftLegPath = Path()
                    leftLegPath.move(to: CGPoint(x: headCx, y: headCy + headR + h * 0.22))
                    leftLegPath.addLine(to: CGPoint(x: headCx - w * 0.10, y: headCy + headR + h * 0.34))
                    context.stroke(leftLegPath, with: .color(.init(red: 0.13, green: 0.13, blue: 0.13)), lineWidth: 7)
                }
                
                // Right leg
                if wrongGuesses >= 6 {
                    var rightLegPath = Path()
                    rightLegPath.move(to: CGPoint(x: headCx, y: headCy + headR + h * 0.22))
                    rightLegPath.addLine(to: CGPoint(x: headCx + w * 0.10, y: headCy + headR + h * 0.34))
                    context.stroke(rightLegPath, with: .color(.init(red: 0.13, green: 0.13, blue: 0.13)), lineWidth: 7)
                }
            }
        }
    }
}
