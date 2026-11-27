import XCTest
import AppKit

private final class MockSquirrelConfig: SquirrelConfigReading {
  var bools: [String: Bool] = [:]
  var ints: [String: Int] = [:]
  var doubles: [String: CGFloat] = [:]
  var strings: [String: String] = [:]
  var colors: [String: String] = [:]

  func getBool(_ option: String) -> Bool? { bools[option] }
  func getInt(_ option: String) -> Int? { ints[option] }
  func getDouble(_ option: String) -> CGFloat? { doubles[option] }
  func getString(_ option: String) -> String? { strings[option] }
  func getColor(_ option: String, inSpace colorSpace: SquirrelTheme.RimeColorSpace) -> NSColor? {
    guard let raw = colors[option] else { return nil }
    return SquirrelColorParser.color(from: raw, inSpace: colorSpace)
  }
}

final class SquirrelConfigAndThemeTests: XCTestCase {
  func testColorParserSupportsAccentAndHexFormats() {
    XCTAssertEqual(SquirrelColorParser.color(from: "accent", inSpace: .sRGB), NSColor.controlAccentColor)
    XCTAssertEqual(SquirrelColorParser.color(from: "  CONTROL_ACCENT \n", inSpace: .sRGB), NSColor.controlAccentColor)

    let rgb = SquirrelColorParser.color(from: "0xFF8800", inSpace: .sRGB)?.usingColorSpace(.sRGB)
    XCTAssertNotNil(rgb)
    XCTAssertEqual(rgb?.redComponent ?? -1, 0.0, accuracy: 0.01)
    XCTAssertEqual(rgb?.greenComponent ?? -1, 0x88 / 255.0, accuracy: 0.01)
    XCTAssertEqual(rgb?.blueComponent ?? -1, 1.0, accuracy: 0.01)
    XCTAssertEqual(rgb?.alphaComponent ?? -1, 1.0, accuracy: 0.01)

    let argbP3 = SquirrelColorParser.color(from: "0x80112233", inSpace: .displayP3)?.usingColorSpace(.displayP3)
    XCTAssertNotNil(argbP3)
    XCTAssertEqual(argbP3?.alphaComponent ?? -1, 0x80 / 255.0, accuracy: 0.01)
    XCTAssertEqual(argbP3?.redComponent ?? -1, 0x33 / 255.0, accuracy: 0.01)

    XCTAssertNil(SquirrelColorParser.color(from: "not_a_color", inSpace: .sRGB))
  }

  func testThemeLoadAppliesGridOverridesAndClamping() {
    let mock = MockSquirrelConfig()
    mock.strings["style/color_scheme"] = "custom"
    mock.bools["style/expandable_grid"] = true
    mock.ints["style/grid_visible_rows"] = 0 // should clamp to >= 1
    mock.ints["style/grid_max_columns"] = -3 // should clamp to >= 0
    mock.strings["preset_color_schemes/custom/grid_row_style"] = "border"
    mock.strings["preset_color_schemes/custom/grid_background_style"] = "solid"
    mock.ints["preset_color_schemes/custom/grid_visible_rows"] = 7
    mock.doubles["preset_color_schemes/custom/corner_radius"] = 8
    mock.colors["preset_color_schemes/custom/hilited_candidate_back_color"] = "accent"

    let theme = SquirrelTheme()
    theme.load(config: mock, dark: false)

    XCTAssertFalse(theme.native)
    XCTAssertTrue(theme.expandableGrid)
    XCTAssertEqual(theme.gridVisibleRows, 7)
    XCTAssertEqual(theme.gridMaxColumns, 0)
    XCTAssertEqual(theme.gridRowStyle, .border)
    XCTAssertEqual(theme.resolvedGridBackgroundStyle, .solid)
    XCTAssertEqual(theme.resolvedGridCornerRadius, 8)

    // Dynamic blended label color resolves cleanly under both Aqua and DarkAqua without crashing.
    let labelColor = theme.labelHighlightedAttrs[.foregroundColor] as? NSColor
    XCTAssertNotNil(labelColor)
    NSAppearance(named: .aqua)?.performAsCurrentDrawingAppearance {
      XCTAssertNotNil(labelColor?.usingColorSpace(.sRGB))
    }
    NSAppearance(named: .darkAqua)?.performAsCurrentDrawingAppearance {
      XCTAssertNotNil(labelColor?.usingColorSpace(.sRGB))
    }
  }
}
