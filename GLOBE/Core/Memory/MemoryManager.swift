//======================================================================
// MARK: - MemoryManager.swift
// Purpose: Memory leak prevention and management utilities
// Path: GLOBE/Core/Memory/MemoryManager.swift
//======================================================================

import Foundation
import Combine

// MARK: - Memory Management Utilities

class MemoryManager {
    static let shared = MemoryManager()

    private var cancellableTracker: Set<AnyCancellable> = []
    private var timerTracker: [Timer] = []

    private init() {}

    // MARK: - Cancellable Management
    func track(_ cancellable: AnyCancellable) {
        cancellable.store(in: &cancellableTracker)
    }

    func track(_ cancellables: Set<AnyCancellable>) {
        cancellables.forEach { track($0) }
    }

    func cancelAll() {
        cancellableTracker.forEach { $0.cancel() }
        cancellableTracker.removeAll()
    }

    // MARK: - Timer Management
    func track(_ timer: Timer) {
        timerTracker.append(timer)
    }

    func invalidateAllTimers() {
        timerTracker.forEach { $0.invalidate() }
        timerTracker.removeAll()
    }

    // MARK: - Memory Cleanup
    func performCleanup() {
        cancelAll()
        invalidateAllTimers()
    }
}

// MARK: - Weak Reference Wrapper

@propertyWrapper
struct WeakRef<T: AnyObject> {
    private weak var _value: T?

    var wrappedValue: T? {
        get { _value }
        set { _value = newValue }
    }

    init(_ value: T? = nil) {
        _value = value
    }
}

// MARK: - Safe Combine Extensions

extension Publisher {
    func safeSink(
        receiveCompletion: @escaping (Subscribers.Completion<Failure>) -> Void = { _ in },
        receiveValue: @escaping (Output) -> Void
    ) -> AnyCancellable {
        let cancellable = sink(receiveCompletion: receiveCompletion, receiveValue: receiveValue)
        MemoryManager.shared.track(cancellable)
        return cancellable
    }

    func weakSink<T: AnyObject>(
        on object: T,
        receiveValue: @escaping (T, Output) -> Void
    ) -> AnyCancellable {
        return sink(receiveCompletion: { _ in }, receiveValue: { [weak object] value in
            guard let object = object else { return }
            receiveValue(object, value)
        })
    }
}

// MARK: - Memory-Safe Timer

extension Timer {
    static func safeScheduledTimer(
        withTimeInterval interval: TimeInterval,
        repeats: Bool,
        block: @escaping (Timer) -> Void
    ) -> Timer {
        let timer = scheduledTimer(withTimeInterval: interval, repeats: repeats, block: block)
        MemoryManager.shared.track(timer)
        return timer
    }
}

// MARK: - ViewModel Base Class with Memory Management

@MainActor
class BaseViewModel: ObservableObject {
    private var cancellables = Set<AnyCancellable>()

    deinit {
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
    }

    // MARK: - Safe Combine Methods
    func store(_ cancellable: AnyCancellable) {
        cancellable.store(in: &cancellables)
    }

    // Convenience: store using instance reference (for chaining in sinks)
    func store(with _: BaseViewModel, _ cancellable: AnyCancellable) {
        cancellable.store(in: &cancellables)
    }

    func cancelAllSubscriptions() {
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
    }
}

// MARK: - Convenience storing for Combine
extension AnyCancellable {
    func store(with viewModel: BaseViewModel) {
        viewModel.store(self)
    }
}
