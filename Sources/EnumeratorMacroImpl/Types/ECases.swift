import Mustache
import SwiftSyntax

struct ECases {
    fileprivate let underlying: EArray<ECase>

    init(underlying: [ECase]) {
        self.underlying = .init(underlying: underlying)
    }

    init(elements: [EnumCaseElementSyntax]) throws {
        self.underlying = .init(
            underlying: try elements.enumerated().map { idx, element in
                try ECase(index: idx, from: element)
            }
        )
    }
}

extension ECases: CustomStringConvertible {
    var description: String {
        self.underlying.description
    }
}

extension ECases: WithNormalizedTypeName {
    static var normalizedTypeName: String {
        "[Case]"
    }
}

extension ECases: Sequence, MustacheSequence {
    func makeIterator() -> Array<ECase>.Iterator {
        self.underlying.makeIterator()
    }
}

extension ECases: CustomReflectable {
    var customMirror: Mirror {
        Mirror(reflecting: self.underlying)
    }
}

extension ECases: EMustacheTransformable {
    func transform(_ name: String) -> Any? {
        /// The underlying type is in charge of adding a diagnostic, if needed.
        return self.underlying.transform(name)
    }
}
