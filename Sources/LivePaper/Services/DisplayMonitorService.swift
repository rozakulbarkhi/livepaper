import AppKit
import Combine

public protocol DisplayMonitorDelegate: AnyObject, Sendable {
    func displayConfigurationDidChange()
    func systemWillSleep()
    func systemDidWake()
    func screensDidSleep()
    func screensDidWake()
    func screenIsLocked()
    func screenIsUnlocked()
}

public final class DisplayMonitorService: @unchecked Sendable {
    public weak var delegate: DisplayMonitorDelegate?
    private var observers: [NSObjectProtocol] = []
    
    public init() {
        setupObservers()
    }
    
    deinit {
        for observer in observers {
            NotificationCenter.default.removeObserver(observer)
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
            DistributedNotificationCenter.default().removeObserver(observer)
        }
    }
    
    private func setupObservers() {
        // Monitor screen resolution/configuration changes
        let screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.delegate?.displayConfigurationDidChange()
        }
        observers.append(screenObserver)
        
        // System sleep
        let sleepObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.willSleepNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.delegate?.systemWillSleep()
        }
        observers.append(sleepObserver)
        
        // System wake
        let wakeObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.delegate?.systemDidWake()
        }
        observers.append(wakeObserver)
        
        // Screens sleep
        let screensSleepObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.screensDidSleepNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.delegate?.screensDidSleep()
        }
        observers.append(screensSleepObserver)
        
        // Screens wake
        let screensWakeObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.screensDidWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.delegate?.screensDidWake()
        }
        observers.append(screensWakeObserver)
        
        // Screen Lock Notifications
        let lockObserver = DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name("com.apple.screenIsLocked"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.delegate?.screenIsLocked()
        }
        observers.append(lockObserver)
        
        // Screen Unlock Notifications
        let unlockObserver = DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name("com.apple.screenIsUnlocked"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.delegate?.screenIsUnlocked()
        }
        observers.append(unlockObserver)
    }
}
