/**
 * onSelectionChange（L1 参照版）
 * ------------------------------------------------------------
 * 目的：
 *   ・選択した行番号を L1 に書き込み、
 *     条件付き書式（=ROW()=$L$1）を発動させて行をハイライト。
 *
 * 特徴：
 *   ・L1 は見出し行なので削除されない → 参照が壊れない
 *   ・L列のゴミは L2 以降だけ消す → L1 は絶対に残す
 *   ・行削除しても #REF! にならない最強構成
 */
function onSelectionChange(e) {

  const sheet = e.source.getActiveSheet();
  const sheetName = sheet.getName();

  // 対象シートのみ動作
  if (sheetName !== "予定表" && sheetName !== "入庫済み") return;

  const row = e.range.getRow();

  // 見出し行は対象外
  if (row < 2) return;

  // ▼ L列のゴミを L2 以降だけクリア（L1 は絶対に消さない）
  const lastRow = sheet.getLastRow();
  if (lastRow >= 2) {
    sheet.getRange(2, 12, lastRow - 1, 1).clearContent(); // L列は12列目
  }

  // ▼ 選択行番号を L1 に書き込む
  sheet.getRange("L1").setValue(row);
}
