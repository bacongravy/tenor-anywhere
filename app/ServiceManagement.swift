import CoreFoundation
import ServiceManagement

func setLoginItem(enabled: Bool) {
    SMLoginItemSetEnabled("net.bacongravy.tenor-anywhere-helper" as CFString, enabled)
}
