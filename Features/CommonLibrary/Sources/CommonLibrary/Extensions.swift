import Foundation

extension CaseIterable where Self: Equatable {
	public var next: Self {
		let all = Self.allCases
		let idx = all.firstIndex(of: self)!
		let next = all.index(after: idx)
		return all[next == all.endIndex ? all.startIndex : next]
	}

	public var isLast: Bool {
		let all = Self.allCases
		let idx = all.firstIndex(of: self)!
		let next = all.index(after: idx)
		return next == all.endIndex
	}
}
