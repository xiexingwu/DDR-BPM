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
    var wheelHeight : CGFloat = 150

    @EnvironmentObject var viewModel : ViewModel

    @State private var speedMod: Double = 1
    static private let speedMods : [Double] = [0.25, 0.5, 0.75, 1, 1.25, 1.5, 1.75, 2, 2.25, 2.5, 2.75, 3, 3.25, 3.5, 3.75, 4, 4.5, 5, 5.5, 6, 6.5, 7, 7.5, 8]

    private func fmtSpeedMod(_ speedMod : Double) -> String {
        let rem = speedMod.truncatingRemainder(dividingBy: 0.5)
        if (rem > 0.01) {
            return String(format: "%.2f", speedMod)
        }else{
            return String(format: "%.1f", speedMod)
        }
    }
    
    private func fmtSpeed(_ speedMod: Double, _ bpm: Int) -> String{
        let speed = Int(speedMod * Double(bpm))
        return String(speed)
    }
    

    private var BPMNCols : Int {
        if isVariableBPMRange(bpmRange){
            return dominantBPM == nil ? 3 : 4
        } else {
            return 2
        }
    }
    
    private var BPMHeader : [String] {
        switch BPMNCols{
        case 2:
            return ["Mod", "Speed"]
        case 3:
            return ["Mod", "Min", "Max"]
        case 4:
            return ["Mod", "Mostly", "Min", "Max"]
        default:
            return ["Mod", "??"]
        }
    }
    
    private var bpms : [Int] {
        getMinMaxBPM(bpmRange)
    }
    
    private func speedModToBPMCols(_ speedMod: Double) -> [String] {
        let modStr = fmtSpeedMod(speedMod)
        switch BPMNCols{
        case 2:
            return [modStr, fmtSpeed(speedMod, bpms[0])]
        case 3:
            return [modStr, fmtSpeed(speedMod, bpms[0]), fmtSpeed(speedMod, bpms[1])]
        case 4:
            return [modStr, fmtSpeed(speedMod, dominantBPM!), fmtSpeed(speedMod, bpms[0]), fmtSpeed(speedMod, bpms[1])]
        default:
            return [modStr, "??"]
        }
    }

    func closestSpeedMod (_ target: Int) -> Double {
        let speeds : [Int] = BPMwheel.speedMods.map {
            var refBPM : Int = 0
            switch BPMNCols {
            case 2:
                refBPM = bpms[0]
            case 3:
                refBPM = bpms[1]
            case 4:
                refBPM = dominantBPM!
            default:
                refBPM = 0
            }
            return Int($0 * Double(refBPM))
        }
        let closest = speeds.enumerated().min( by: {abs($0.1 - target) < abs($1.1 - target)} )!
        return BPMwheel.speedMods[closest.offset]
    }
    
    var body: some View {
  
        VStack{
            
            BPMRow(cols: BPMHeader)
                .frame(maxHeight:30)
                .clipped()
                
                Picker("Speed mod", selection: $speedMod){
                    ForEach(BPMwheel.speedMods, id:\.self){ speedMod in
                        BPMRow(cols: speedModToBPMCols(speedMod))
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
        NavigationView{
            VStack(alignment:.center){
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
                    .toolbar{
                        ToolbarItem(placement: .keyboard){
                            ToolbarKeyboard(cancelAction: {bpmInputFocused = false} )
                        }
                    }

                Spacer()
                
                BPMwheel(bpmRange: cleanInput(bpmRange), wheelHeight: 200)
                
                Spacer()
            }
            .navigationTitle("BPM Wheel")
            .navigationBarTitleDisplayMode(.inline)
            .hideKeyboardWhenTappedAround()
        }

    }
}



struct BPMRow: View{
    var cols: [String]
    
    var body: some View{
        HStack{
            ForEach(cols, id:\.self){col in
                Text(col)
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
        .previewLayout(.fixed(width: 400, height: 300))
    }
}

