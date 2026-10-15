require "test_helper"

class DocumentAnalyzerTest < ActiveSupport::TestCase
  test "turns pasted lab text into measurements with reference ranges" do
    user = users(:one)
    doc = user.documents.create!(title: "Blodprover", extracted_text: "LDL 3,9 mmol/L (<3,0)\nHb 142 g/L (134–170)")
    FakeAi.respond_with(
      date: "2026-09-01", summary: "LDL är något förhöjt.",
      values: [
        { name: "LDL-kolesterol", value: "3,9", unit: "mmol/L", reference_low: nil, reference_high: "3,0" },
        { name: "Hb", value: 142, unit: "g/L", reference_low: 134, reference_high: 170 },
        { name: "Kommentar", value: "se nedan" }
      ]
    )

    DocumentAnalyzer.new(doc).call

    doc.reload
    assert_equal "done", doc.status
    assert_equal Date.new(2026, 9, 1), doc.taken_on
    ldl = doc.measurements.find_by(metric_key: "lab_ldl_kolesterol")
    assert_equal 3.9, ldl.value.to_f
    assert ldl.out_of_range?
    refute doc.measurements.find_by(label: "Hb").out_of_range?
    assert_equal 2, doc.measurements.count
  end

  test "marks the document as failed when the model returns garbage" do
    doc = users(:one).documents.create!(title: "X", extracted_text: "Hb 140")
    FakeAi.respond_with("inte json alls")

    assert_raises(Ai::Error) { DocumentAnalyzer.new(doc).call }
    assert_equal "failed", doc.reload.status
  end
end
