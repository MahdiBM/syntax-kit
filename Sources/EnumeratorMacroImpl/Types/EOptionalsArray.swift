import Mustache

struct EOptionalsArray<Element> {
    fileprivate let underlying: [EOptional<Element>]

    init(underlying: [Element?]) {
        self.underlying = underlying.map(EOptional.init)
    }

    init(underlying: [EOptional<Element>]) {
        self.underlying = underlying
    }

    @available(*, unavailable, message: "Unwrap the optionals-array first")
    init(underlying: EOptionalsArray<Element>) {
        fatalError()
    }
}

extension EOptionalsArray: Sequence, MustacheSequence {
    func makeIterator() -> Array<EOptional<Element>>.Iterator {
        self.underlying.makeIterator()
    }
}

extension EOptionalsArray: CustomStringConvertible {
    var description: String {
        self.underlying.description
    }
}

extension EOptionalsArray: WithNormalizedTypeName {
    static var normalizedTypeName: String {
        "[Optional<\(bestEffortTypeName(Element.self))>]"
    }
}

extension EOptionalsArray: CustomReflectable {
    var customMirror: Mirror {
        Mirror(reflecting: self.underlying)
    }
}

extension EOptionalsArray: EMustacheTransformable {
    func transform(_ name: String) -> Any? {
        switch name {
        case "first":
            return self.underlying.first
        case "last":
            return self.underlying.last
        case "reversed":
            return EOptionalsArray(underlying: self.reversed().map { $0 })
        case "count":
            return self.underlying.count
        case "empty":
            return self.underlying.isEmpty
        case "joined":
            let joined = self.underlying
                .enumerated()
                .map { $1.map { String(describing: $0) } ?? "param\($0 + 1)" }
                .joined(separator: ", ")
            let string = EString(joined)
            return string
        case "keyValues":
            let split: [EKeyValue] = self.underlying
                .compactMap { $0.toOptional().map { String(describing: $0) } }
                .compactMap { string -> EKeyValue? in
                    let split = string.split(
                        separator: ":",
                        maxSplits: 1
                    ).map {
                        $0.trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                    guard split.count == 2 else {
                        return nil
                    }
                    return EKeyValue(
                        key: EString(split[0]),
                        value: EString(split[1])
                    )
                }
            return EArray<EKeyValue>(underlying: split)
        default:
            if let keyValues = self as? EOptionalsArray<EKeyValue> {
                /// Don't throw even if the key doesn't exist.
                return keyValues.underlying.first(named: EString(name))
            }
            if let comparable = self as? EComparableSequence {
                /// The underlying type is in charge of adding a diagnostic, if needed.
                return comparable.comparableTransform(name)
            }
            RenderingContext.current.addOrReplaceDiagnostic(
                .invalidTransform(
                    transform: name,
                    normalizedTypeName: Self.normalizedTypeName
                )
            )
            return nil
        }
    }
}

extension EOptionalsArray: EComparableSequence where Element: Comparable {
    func comparableTransform(_ name: String) -> Any? {
        switch name {
        case "sorted":
            return EOptionalsArray(underlying: self.underlying.sorted())
        default:
            RenderingContext.current.addOrReplaceDiagnostic(
                .invalidTransform(
                    transform: name,
                    normalizedTypeName: Self.normalizedTypeName
                )
            )
            return nil
        }
    }
}
