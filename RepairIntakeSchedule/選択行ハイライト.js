function onSelectionChange(e) {

  const sheet = e.source.getActiveSheet();
  const sheetName = sheet.getName();
  const row = e.range.getRow();

  console.log("=== onSelectionChange 発火 ===");
  console.log("シート名:", sheetName);
  console.log("選択行:", row);

  // 対象シートのみ動作
  if (sheetName !== "予定表" && sheetName !== "入庫済み") {
    console.log("対象外シートのため終了");
    return;
  }

  // 見出し行は対象外
  if (row < 2) {
    console.log("見出し行のため終了");
    return;
  }

  const lastRow = sheet.getLastRow();
  console.log("最終行:", lastRow);

  // ▼ L列のゴミを L2 以降だけクリア（L1 は絶対に消さない）
  if (lastRow >= 2) {
    console.log("L2:L のゴミをクリアします");
    sheet.getRange(2, 12, lastRow - 1, 1).clearContent();
  }

  // ▼ 選択行番号を L1 に書き込む
  console.log("L1 に書き込む値:", row);
  sheet.getRange("L1").setValue(row);

  console.log("=== onSelectionChange 完了 ===");
}
