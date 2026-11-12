/**
 * setHighlightRule（L1 参照版）
 * ------------------------------------------------------------
 * 目的：
 *   ・「選択した行だけ」を条件付き書式でハイライトするルールを
 *     予定表シートと入庫済みシートの両方に登録する。
 *
 * 重要ポイント：
 *   ・この関数は “一度だけ” 実行すればOK（手動実行推奨）
 *   ・onSelectionChange が L1 に選択行番号を書き込む
 *   ・条件付き書式は L1 の値と ROW() を比較して色付けする
 */
function setHighlightRule() {

  const ss = SpreadsheetApp.getActiveSpreadsheet();

  // ▼ 対象シート名のリスト（予定表・入庫済み）
  const sheetNames = ["予定表", "入庫済み"];

  sheetNames.forEach(name => {

    const sheet = ss.getSheetByName(name);
    if (!sheet) return;

    const targetRange = sheet.getRange("A2:H");

    const rule = SpreadsheetApp.newConditionalFormatRule()
      .whenFormulaSatisfied('=ROW()=$L$1')   // ★ I2 → L1 に変更
      .setBackground("#FDE2E2")
      .setRanges([targetRange])
      .build();

    const rules = sheet.getConditionalFormatRules();
    rules.push(rule);
    sheet.setConditionalFormatRules(rules);
  });
}
