import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(gitlab_fusionTests.allTests),
    ]
}
#endif
