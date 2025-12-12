import Combine

final class CounterViewModel {

    // Output
    @Published private(set) var count: Int = 0

    // Input
    func increment() {
        count += 1
    }
}
