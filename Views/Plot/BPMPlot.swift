//
//  BPMPlot.swift
//  DDR BPM
//
//  Created by Michael Xie on 8/5/2022.
//

import SwiftUI
import CoreGraphics

extension UIScreen{
   static let screenWidth = UIScreen.main.bounds.size.width
//   static let screenHeight = UIScreen.main.bounds.size.height
//   static let screenSize = UIScreen.main.bounds.size
}

func songToBPMPoints(_ song: Song, chartID : Int = 0) -> [CGPoint] {
    let chart = song.chart[chartID]
    var points : [CGPoint] = []
    
    for bpm in chart.bpms {
        points.append(
            CGPoint(
                x: CGFloat(bpm.st),
                y: CGFloat(bpm.val)
            )
        )
        points.append(
            CGPoint(
                x: CGFloat(bpm.ed),
                y: CGFloat(bpm.val)
            )
        )
    }
    
    return points
}

struct BPMPlot: View {
    var song : Song
    var chartID : Int = 0
    var data : [CGPoint] {
        songToBPMPoints(song, chartID: chartID)
    }

    var xdiv : CGFloat = 15
    
    var body: some View {
        LinePlot(data: data,
                 xmin: 0,
                 ymin: 0,
                 xdiv: xdiv,
                 xGrid: true,
                 yGrid: true
        )
        .aspectRatio(contentMode: .fit)
        
        
    }
}

struct Line {
    var points: [CGPoint]
    var path: Path {
        Path{ path in
            path.move(
                to: CGPoint(
                    x: points[0].x,
                    y: points[0].y
                )
            )
            
            points.forEach{ point in
                path.addLine(
                    to: CGPoint(
                        x: point.x,
                        y: point.y
                    )
                )
            }
        }
    }
}

struct LinePlot : View{
    var data : [CGPoint]
    
    var xmin : CGFloat?
    var ymin : CGFloat?
    
    var xmax : CGFloat?
    var ymax : CGFloat?
    
    var xdiv : CGFloat?
    var ydiv : CGFloat?
    
    var xGrid : Bool = false
    var yGrid : Bool = false
    
    var xOffset : CGFloat = 30
    var yOffset : CGFloat = 30
    
    var width : CGFloat?
    var aspectRatio : CGFloat?
    
    private var xgrid : [CGFloat] {
        xGrid ? computeGrid(xMin, xMax, xDiv) : []
    }
    
    private var ygrid : [CGFloat] {
        yGrid ? computeGrid(yMin, yMax, yDiv) : []
    }
    
    private func computeGrid(_ min: CGFloat, _ max: CGFloat, _ div: CGFloat) -> [CGFloat] {
        var gridValues : [CGFloat] = []
        if min >= max {return gridValues}
        
        var grid : CGFloat = min
        repeat {
            gridValues.append(grid)
            grid += div
        } while (grid <= max)
        return gridValues
    }
    
    private var xMin : CGFloat {
        xmin ?? floor(data.map{ $0.x }.min()! / xDiv) * xDiv
    }
    private var xMax : CGFloat {
        xmax ?? ceil(data.map{ $0.x }.max()! / xDiv) * xDiv
    }
    private var yMin : CGFloat {
        ymin ?? floor(data.map{ $0.y }.min()! / yDiv) * yDiv
    }
    private var yMax : CGFloat {
        ymax ?? ceil(data.map{ $0.y }.max()! / yDiv) * yDiv
    }
    
    private var xDiv : CGFloat {
        xdiv ?? {
            let x = data.map{ $0.x }
            let range = (xmax ?? x.max()!) - (xmin ?? x.min()!)
            return computeDiv(range)
        } ()
    }
    
    private var yDiv : CGFloat {
        ydiv ?? {
            let y = data.map{ $0.y }
            let range = (ymax ?? y.max()!) - (ymin ?? y.min()!)
            return computeDiv(range)
        } ()
    }
    
    private func computeDiv(_ range: CGFloat) -> CGFloat {
        // are we working in the tens/hundrs/thousands?
        let power = floor(log10(range))
        var div = pow(10, power-1)
        if range / div > 10{
            div *= 2.5
        }
        if range / div > 10{
            div *= 2
        }
        if range / div > 10{
            div *= 2
        }
        return div
    }
    
    private func dataToPix(_ val: CGFloat,
                           min: CGFloat = 0,
                           max: CGFloat = 0,
                           width: CGFloat
    ) -> CGFloat {
        val / (max - min) * width
    }
    
    private func dataPointToCanvasPoint(_ point: CGPoint,
                                        width: CGFloat = 0,
                                        height: CGFloat = 0
    ) -> CGPoint {
        CGPoint(
            x: dataToPix(point.x,
                         min: xMin,
                         max: xMax,
                         width: width),
            y: dataToPix(yMax - point.y,
                         min: yMin,
                         max: yMax,
                         width: height)
        )
    }
    
    var body: some View {
        GeometryReader{ geo in
            let geoWidth = (width ?? geo.size.width) - xOffset
            let geoHeight = geo.size.width / (aspectRatio ?? 16/9)
            
            let convertPoint : (CGPoint) -> CGPoint = {
                dataPointToCanvasPoint($0,
                                       width: geoWidth,
                                       height: geoHeight
                )
            }
            
            let axesLine = Line(points: [
                CGPoint(x:xMin, y:yMin),
                CGPoint(x:xMax, y:yMin),
                CGPoint(x:xMax, y:yMax),
                CGPoint(x:xMin, y:yMax),
                CGPoint(x:xMin, y:yMin),
            ].map(convertPoint))
            
            let yGridLines = ygrid.map{Line(points: [
                CGPoint(x:xMin, y:$0),
                CGPoint(x:xMax, y:$0)
            ].map(convertPoint))}
            
            let xGridLines = xgrid.map{Line(points: [
                CGPoint(x:$0, y:yMin),
                CGPoint(x:$0, y:yMax)
            ].map(convertPoint))}
            
            /* Plot */
            ZStack(alignment: .topLeading){

                /* xlabels */
                ForEach(0 ... xGridLines.count - 1, id:\.self){ i in
                    Text(String(format:"%g", xgrid[i]))
                        .hidden()
                        .multilineTextAlignment(.trailing)
                        .overlay(GeometryReader {labelGeo in
                            Text(String(format:"%g", xgrid[i]))
                                .transformEffect(.init(
                                    translationX: -labelGeo.size.width/2,
                                    y: -labelGeo.size.height))
                        })
                        .offset(
                            x: xGridLines[i].points[1].x,
                            y: geoHeight
                        )
                }
                .offset(x: xOffset, y: yOffset)

                /* ylabels */
                ForEach(0 ... yGridLines.count - 1, id:\.self){ i in
                    Text(String(format:"%g", ygrid[i]))
                        .hidden()
                        .multilineTextAlignment(.trailing)
                        .overlay(GeometryReader {labelGeo in
                            Text(String(format:"%g", ygrid[i]))
                                .transformEffect(.init(
                                    translationX: -labelGeo.size.width/2,
                                    y: -labelGeo.size.height/2))
                        })
                        .offset(
                            x: 0,
                            y: yGridLines[i].points[1].y
                        )
                }
//                .offset(y: -yOffset)

                Group{
                    /* Grid lines */
                    ForEach(0 ... xGridLines.count-1, id:\.self){i in
                        xGridLines[i].path
                            .stroke(.gray, lineWidth: 0.5)
                    }
                    ForEach(0 ... yGridLines.count-1, id:\.self){i in
                        yGridLines[i].path
                            .stroke(.gray, lineWidth: 0.5)
                    }
                    
                    /* Axes + Box */
                    axesLine.path
                        .stroke(.black)
                    
                    /* Data */
                    Group{
                        let line = Line(points: data.map(convertPoint))
                        line.path
                            .stroke(.blue)
                    }
                }
                .offset(
                    x: xOffset,
                    y: 0 //-yOffset
                )
            }
        }
        .padding(20)
        .frame(
            width: width ?? UIScreen.screenWidth,
            height: {
                let def : CGFloat = (width ?? UIScreen.screenWidth) / (aspectRatio ?? 16/9)
                return def + yOffset
            }()
        )
    }
}

struct BPMPlot_Previews: PreviewProvider {
    static let favorites = Favorites()
    static let viewModel = ViewModel()
    static let modelData = ModelData()
    
    static var previews: some View {
        VStack{
            Text("Text before")
            BPMPlot(song: modelData.songs[16], chartID: 3)
                .environmentObject(modelData)
                .environmentObject(viewModel)
                .environmentObject(favorites)
            
            Text("Text after")
        }
    }
}
