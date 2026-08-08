import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = SafeFlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()

#if DEBUG
    if let requestedSize = ProcessInfo.processInfo.environment["TUTUNER_TEST_WINDOW_SIZE"] {
      let dimensions = requestedSize.split(separator: "x").compactMap { Double($0) }
      if dimensions.count == 2 {
        DispatchQueue.main.async {
          self.setContentSize(NSSize(width: dimensions[0], height: dimensions[1]))
          self.center()
        }
      }
    }
#endif
  }
}
