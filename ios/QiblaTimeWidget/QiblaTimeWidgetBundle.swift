import SwiftUI
import WidgetKit

@main
struct QiblaTimeWidgetBundle: WidgetBundle {
    var body: some Widget {
        QiblaTimeWidget()
        QiblaTimeLockScreenWidget()
    }
}
