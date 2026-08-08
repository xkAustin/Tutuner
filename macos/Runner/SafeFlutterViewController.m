#import "SafeFlutterViewController.h"

// Flutter 3.44's macOS 27 accessibility bridge can dereference a removed node
// while a window resize reparents the semantics tree. The selector is internal
// to FlutterMacOS, so declare it locally before forwarding on unaffected OSes.
@interface FlutterViewController (TutunerSemanticsInternal)
- (void)updateSemantics:(const void*)update;
@end

@implementation SafeFlutterViewController

- (void)updateSemantics:(const void*)update {
  if (NSProcessInfo.processInfo.operatingSystemVersion.majorVersion >= 27) {
    return;
  }
  [super updateSemantics:update];
}

@end
