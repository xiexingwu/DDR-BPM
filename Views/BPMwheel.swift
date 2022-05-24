//
//  BPMwheel.swift
//  DDR BPM
//
//  Created by Michael Xie on 3/5/2022.
//

import SwiftUI
import Combine



struct BPMwheel: View {
    var bpmRange : String = "200"
    var dominantBPM : Int? = nil
    
    @EnvironmentObject var viewModel : ViewModel

    @State private var speedMod: Double = 1
    static private let speedMods = [0.25, 0.5, 0.75, 1, 1.25, 1.5, 1.75, 2, 2.25, 2.5, 2.75, 3, 3.25, 3.5, 3.75, 4, 4.5, 5, 5.5, 6, 6.5, 7, 7.5, 8]

    private func fmtSpeedMod(speedMod : Double) -> String {
        let rem = speedMod.truncatingRemainder(dividingBy: 0.5)
        if (rem > 0.01) {
            return String(format: "%.2f", speedMod)
        }else{
            return String(format: "%.1f", speedMod)
        }
    }
    
    
    private func fmtSpeed(speed: Double) -> String{
        String(format: "%.0f", speed)
    }
    
    var wheelHeight : CGFloat = 80

    private var bpms : [Int] {
        getMinMaxBPM(bpmRange)
    }
    
    private var wheelMid : (String, Int) {
        if isVariableBPMRange(bpmRange){
            let dom = dominantBPM ?? bpms[0]
            if dom != bpms[0] && dom != bpms[1]{
                return ("Mostly", dom)
            } else {
                return ("Min", bpms[0])
            }
        } else {
            return ("BPM", bpms[0])
        }
    }
    private var wheelRight : (String, Int?) {
        if isVariableBPMRange(bpmRange){
            return ("Max", bpms[1])
        } else {
            return ("", nil)
        }
    }

    func closestSpeedMod (_ target: Int) -> Double {
        let speeds = BPMwheel.speedMods.map { Int($0 * Double(wheelMid.1)) }
        let closest = speeds.enumerated().min( by: {abs($0.1 - target) < abs($1.1 - target)} )!
        return BPMwheel.speedMods[closest.offset]
    }
    
    var body: some View {
  
        VStack{
            
                BPMrow(left: "Mod",
                       mid: wheelMid.0,
                       right: wheelRight.0)
                .frame(maxHeight:30)
                .clipped()
                
                Picker("Speed mod", selection: $speedMod){
                    ForEach(BPMwheel.speedMods, id:\.self){ speedMod in
                        BPMrow(left: fmtSpeedMod(speedMod:speedMod),
                               mid: fmtSpeed(speed:speedMod*Double(wheelMid.1)),
                               right: wheelRight.1 == nil ? "" : fmtSpeed(speed:speedMod*Double(wheelRight.1!)))
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxHeight: wheelHeight)
                .clipped()

        }
        .onAppear { speedMod = closestSpeedMod(viewModel.userReadSpeed) }
    }
}

struct BPMSheet: View{
    @State private var bpmRange: String = ""
    @FocusState private var bpmInputFocused : Bool
    
    private func cleanInput(_ bpmRange : String) -> String{
        if bpmRange.count == 0 {
            return "200"
        }
        let filtered = bpmRange.filter { "0123456789.".contains($0) }
            .components(separatedBy: ".")
            .joined(separator: "~")
            .trimmingCharacters(in: CharacterSet(charactersIn: "~"))
        return filtered.isEmpty ? "200" : filtered
    }

    var body: some View{
        VStack(alignment:.center){
            Text("BPM Wheel")
                .font(.title2)
            
            Text("min.max for variable BPM")
                .font(.subheadline)
            
            Spacer()
            
            TextField("BPM: 200", text:$bpmRange)
                .focused($bpmInputFocused)
                .font(.title)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 250)
                .onTapGesture {
                    bpmRange = ""
                }
                .onSubmit {
                    bpmInputFocused = false
                }
            
            Spacer()
            
            BPMwheel(bpmRange: cleanInput(bpmRange), wheelHeight: 200)
            
            Spacer()
        }
        .onTapGesture {
            bpmInputFocused = false
//            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to:nil, from:nil, for:nil)
        }
//        .onAppear { DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//            bpmInputFocused = true }
//        }
    }
}

struct BPMrow: View{
    var left: String
    var mid: String
    var right: String
    
    var body: some View{
        HStack{
            Text(left)
                .padding()
                .frame(maxWidth: .infinity)

            Text(mid)
                .padding()
                .frame(maxWidth: .infinity)
            
            if !right.isEmpty {
                Text(right)
                    .padding()
                    .frame(maxWidth: .infinity)
            }

        }
    }
}

struct BPMwheel_Previews: PreviewProvider {
    static let favorites = Favorites()
    static let viewModel = ViewModel()
    static let modelData = ModelData()

    static var previews: some View {
        Group{
            BPMwheel(bpmRange:"200")
            BPMwheel(bpmRange:"100~400")
            BPMwheel(bpmRange:"100~800", dominantBPM: 400)
            BPMSheet()
        }
        .environmentObject(modelData)
        .environmentObject(viewModel)
        .environmentObject(favorites)
        .previewLayout(.fixed(width: 300, height: 300))
    }
}

