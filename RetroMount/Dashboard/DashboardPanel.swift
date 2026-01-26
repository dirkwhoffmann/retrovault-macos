// -----------------------------------------------------------------------------
// This file is part of RetroMount
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

import SwiftUI
import Charts

//
// SwiftUI Views
//

@MainActor
struct TimeSeriesView: View {

    @ObservedObject var model: DashboardDataProvider
    var panel: DashboardPanel!

    var body: some View {

        VStack(alignment: .leading) {

            VStack(alignment: .leading) {
                Text(panel.heading)
                    .font(.system(size: 14))
                    .fontWeight(.bold)
                    .foregroundColor(panel.headingColor)
                    .padding(.bottom, 1)
                Text(panel.subHeading)
                    .font(.system(size: 9))
                    .fontWeight(.regular)
                    .foregroundColor(panel.subheadingColor)
            }

            Chart {

                ForEach(model.data.filter { $0.series != 3 }, id: \.id) { dataPoint in
                    AreaMark(
                        x: .value("Time", dataPoint.timestamp),
                        y: .value("Value", dataPoint.value),
                        series: .value("Series", dataPoint.series)
                    )
                    .foregroundStyle(by: .value("Series", dataPoint.series))
                }

                ForEach(model.data.filter { $0.series == 3 }, id: \.id) { dataPoint in
                    LineMark(
                        x: .value("Time", dataPoint.timestamp),
                        y: .value("Value", dataPoint.value),
                        series: .value("Series", dataPoint.series)
                    )

                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(panel.lineColor)
                    .lineStyle(StrokeStyle(lineWidth: 1.5))
                    /*
                    .symbol {
                        if #available(macOS 15.0, *) {
                            Circle()
                                .fill(panel.graph1Color.mix(with: .white, by: 0.5))
                                .frame(width: 4)
                        } else {
                            Circle()
                                .fill(panel.graph1Color)
                                .frame(width: 2)
                        }
                    }
                    */
                }
            }
            .chartXScale(domain: Date() - DashboardDataProvider.maxTimeSpan...Date())
            .chartXAxis(.hidden)
            .chartYScale(domain: model.range)
            .chartYAxis {
                AxisMarks(values: model.gridLines) {
                    AxisGridLine()
                        .foregroundStyle(panel.gridLineColor)
                }
            }
            .chartLegend(.hidden)
            .chartForegroundStyleScale(panel.gradients)
        }
        .padding(panel.padding)
        .background(panel.background)
        .cornerRadius(10)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct GaugeView: View {

    @ObservedObject var model: DashboardDataProvider
    var panel: DashboardPanel

    var body: some View {

        VStack(alignment: .leading) {

            VStack(alignment: .leading) {
                Text(panel.heading)
                    .font(.system(size: 14))
                    .fontWeight(.bold)
                    .foregroundColor(panel.headingColor)
                    .padding(.bottom, 1)
                Text(panel.subHeading)
                    .font(.system(size: 9))
                    .fontWeight(.regular)
                    .foregroundColor(panel.subheadingColor)
            }

            if #available(macOS 14.0, *) {

                GeometryReader { geometry in

                    Gauge(value: model.latest(), in: model.range) {
                        Text(model.unit)
                    } currentValueLabel: {
                        Text(panel.latest())
                    }
                    .gaugeStyle(.accessoryCircular)
                    .tint(panel.gaugeGradient)
                    .scaleEffect(min(geometry.size.width, geometry.size.height) / 65)
                    .padding(EdgeInsets(top: 3.0, leading: 0.0, bottom: 0.0, trailing: 0.0))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    // .background(.green)
                }
            } else { }
        }
        .padding(panel.padding)
        .background(panel.background)
        .cornerRadius(10)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

//
// Wrapper NSView
//

class DashboardPanel: NSView {

    var model = DashboardDataProvider()

    // Title and sub title
    var heading = ""
    var subHeading = ""

    // Colors and gradients
    var graph1Color = Color(NSColor.init(r: 0x33, g: 0x99, b: 0xFF))
    var graph2Color = Color(NSColor.init(r: 0xFF, g: 0x33, b: 0x99))
    var lineColor = Color(NSColor.labelColor).opacity(0.5)
    var headingColor = Color(NSColor.secondaryLabelColor)
    var subheadingColor = Color(NSColor.secondaryLabelColor)

    var themeColor: NSColor = .white {
        didSet {
            // lineColor = Color(themeColor).opacity(0.6)
            graph1Color = Color(themeColor)
            graph2Color = Color(themeColor)
            // headingColor = Color(themeColor)
        }
    }

    func configure(title: String,
                   subtitle: String,
                   range: ClosedRange<Double> = 0...1,
                   unit: String = "",
                   logScale: Bool = false) {

        heading = title
        subHeading = subtitle
        model.unit = unit
        model.logScale = logScale
        model.range = range
    }

    var background: Gradient {
        if #available(macOS 14.0, *) {
            return Gradient(colors: [Color(NSColor.controlBackgroundColor),
                                     Color(window!.backgroundColor)])
        } else {
            return Gradient(colors: [Color.clear, Color.clear])
        }
    }

    var gradients: KeyValuePairs<Int, Gradient> {
        return [ 1: Gradient(colors: [graph1Color.opacity(0.75), graph1Color.opacity(0.25)]),
                 2: Gradient(colors: [graph2Color.opacity(0.75), graph2Color.opacity(0.25)])]
    }
    /*
     var gaugeGradient: Gradient {
     return Gradient(colors: [.green, .yellow, .orange, .red])
     }
     */
    var gaugeGradient: Gradient = Gradient(colors: [.green, .yellow, .orange, .red])

    var gridLineColor: Color {
        return Color(NSColor.labelColor).opacity(0.2)
    }
    /*
     var padding: EdgeInsets {
     return EdgeInsets(top: 8.0, leading: 8.0, bottom: 0.0, trailing: 8.0)
     }
     */
    var padding = EdgeInsets(top: 8.0, leading: 8.0, bottom: 0.0, trailing: 8.0)

    var host1: NSHostingView<TimeSeriesView>!
    var host2: NSHostingView<GaugeView>!
    var subview: NSView? { return subviews.isEmpty ? nil : subviews[0] }

    var latest: () -> String = { "" }

    required init?(coder aDecoder: NSCoder) {

        super.init(coder: aDecoder)

        host1 = NSHostingView(rootView: TimeSeriesView(model: model, panel: self))
        host2 = NSHostingView(rootView: GaugeView(model: model, panel: self))
        switchStyle()
    }

    required override init(frame frameRect: NSRect) {

        super.init(frame: frameRect)

        host1 = NSHostingView(rootView: TimeSeriesView(model: model, panel: self))
        host2 = NSHostingView(rootView: GaugeView(model: model, panel: self))
        switchStyle()
    }

    override func mouseDown(with event: NSEvent) {

        switchStyle()
    }

    func switchStyle() {

        if subview == host1 {

            if #available(macOS 14.0, *) { } else {
                // Prevent switching to the (not existing) gauge element
                return
            }
        }

        if subview == host1 {
            subview!.removeFromSuperview()
            addSubview(host2)
        } else if subview == host2 {
            subview!.removeFromSuperview()
            addSubview(host1)
        } else {
            addSubview(host1)
        }

        if let subview = subview {
            subview.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                subview.leadingAnchor.constraint(equalTo: self.leadingAnchor),
                subview.trailingAnchor.constraint(equalTo: self.trailingAnchor),
                subview.topAnchor.constraint(equalTo: self.topAnchor),
                subview.bottomAnchor.constraint(equalTo: self.bottomAnchor)
            ])
        }
    }
}

//
// Custom panels
//

@MainActor
class ReadPanel: DashboardPanel {

    required init?(coder aDecoder: NSCoder) {

        super.init(coder: aDecoder)
        setup()
    }

    required init(frame frameRect: NSRect) {

        super.init(frame: frameRect)
        setup()
    }

    func setup() {

        configure(title: "Read",
                  subtitle: "Transferred bytes",
                  range: 0...Double(1.0))

        latest = { String(Int(self.model.latest().rounded())) }
    }
}

@MainActor
class WritePanel: DashboardPanel {

    required init?(coder aDecoder: NSCoder) {

        super.init(coder: aDecoder)
        setup()
    }

    required init(frame frameRect: NSRect) {

        super.init(frame: frameRect)
        setup()
    }

    func setup() {

        configure(title: "Write",
                  subtitle: "Transferred bytes",
                  range: 0...Double(1.0))

        latest = { String(Int(self.model.latest().rounded())) }
    }
}
