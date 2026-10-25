import Foundation
import IOKit.ps

public protocol PowerMonitorDelegate: AnyObject, Sendable {
    func powerSourceDidChange(isOnBattery: Bool)
}

public final class PowerMonitorService: @unchecked Sendable {
    public static let shared = PowerMonitorService()
    public weak var delegate: PowerMonitorDelegate?
    
    private var runLoopSource: CFRunLoopSource?
    
    public init() {
        setupPowerMonitoring()
    }
    
    deinit {
        if let runLoopSource = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .defaultMode)
        }
    }
    
    public var isOnBattery: Bool {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef] else {
            return false
        }
        
        for source in sources {
            guard let description = IOPSGetPowerSourceDescription(snapshot, source)?.takeUnretainedValue() as? [String: Any],
                  let state = description[kIOPSPowerSourceStateKey as String] as? String else {
                continue
            }
            if state == (kIOPSBatteryPowerValue as String) {
                return true
            }
        }
        return false
    }
    
    private func setupPowerMonitoring() {
        let context = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        let loopSource = IOPSNotificationCreateRunLoopSource({ context in
            guard let context = context else { return }
            let monitor = Unmanaged<PowerMonitorService>.fromOpaque(context).takeUnretainedValue()
            let onBattery = monitor.isOnBattery
            monitor.delegate?.powerSourceDidChange(isOnBattery: onBattery)
        }, context).takeRetainedValue()
        
        self.runLoopSource = loopSource
        CFRunLoopAddSource(CFRunLoopGetMain(), loopSource, .defaultMode)
    }
}
