#!/bin/bash

# Script pro spuštění kompletních SunCalc testů
# Použití: ./run_polar_tests.sh

set -e

echo "🧪 Running SunCalc Comprehensive Edge Case Tests"
echo "================================================"
echo ""
echo "Test files:"
echo "  • SunCalcPolarTests.swift - Basic polar day/night"
echo "  • SunCalcEdgeCasesTests.swift - All twilight types & edge cases"
echo ""

# Spusť všechny testy a filtruj výstup
echo "Running tests..."
swift test 2>&1 | tee test_output.log | grep -E "(🌞|🌙|🌅|🌍|✅|❌|🌃|🌊|✨|💙|☀️|🔄|⏰|Test Suite|Executed|failures)" || true

echo ""
echo "================================================"
echo "📊 Test Summary"
echo "================================================"

# Počítej výsledky
TOTAL_TESTS=$(grep -c "Test Case.*started" test_output.log || echo "0")
PASSED_TESTS=$(grep -c "Test Case.*passed" test_output.log || echo "0")
FAILED_TESTS=$(grep -c "Test Case.*failed" test_output.log || echo "0")

echo "Total tests run: $TOTAL_TESTS"
echo "Passed: $PASSED_TESTS"
echo "Failed: $FAILED_TESTS"

echo ""
echo "================================================"
echo "📖 Documentation"
echo "================================================"
echo "• POLAR_BUG_DOCUMENTATION.md - Basic polar day/night bugs"
echo "• COMPREHENSIVE_BUGS_REPORT.md - Full bug report (all event types)"
echo ""
echo "🔍 Key Findings:"
echo "  ❌ Sunrise/Sunset in polar regions (should be nil)"
echo "  ❌ All twilight types (civil, nautical, astronomical)"
echo "  ❌ Golden hours in extreme conditions"
echo "  ❌ Blue hours when twilight missing"
echo "  ✅ Solar noon/nadir always work"
echo "  ✅ Event ordering correct when events exist"
echo "  ✅ Equator behavior perfect"
echo ""
echo "🌍 Affected regions: Norway, Sweden, Finland, Iceland,"
echo "   Alaska, Northern Canada, Greenland, Antarctica"
echo ""

# Cleanup
rm -f test_output.log

echo "Done! 🎉"
