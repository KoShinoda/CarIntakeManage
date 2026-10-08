/**
 * onEdit 統合版（A列＝チェック、B列＝日付、C列＝名前、E列＝セレクトボックス）
 * ------------------------------------------------------------------
 * ① 予定表の A列チェック → 入庫済みへ移動（削除前に1行追加）
 * ② 入庫済みの A列チェック → 予定表へ戻す（通常追加）
 * ③ 予定表の E列編集 → ソート後にカーソルを E列へ戻す（PCのみ）
 *
 * ★ B列編集時の「ソート後カーソル復帰処理」は削除済み（要望対応）
 * ★ ソート後は行が動くため、カーソル復帰処理は
 *   ソート前の行データを保持して位置特定する必要がある。
 */
function onEdit(e) {

  // ▼ 編集されたシート・セル情報を取得
  const sheet = e.source.getActiveSheet();
  const sheetName = sheet.getName();

  // ▼ シート名（固定）
  const yoteiSheetName = "予定表";     // メインシート
  const doneSheetName = "入庫済み";    // 完了シート

  // ▼ 編集された行・列
  const row = e.range.getRow();
  const col = e.range.getColumn();

  // ▼ シートの最終列（列数）
  const lastCol = sheet.getLastColumn();


  // ============================================================
  // ① 予定表の A列チェック → 入庫済みへ移動（確認ダイアログなし）
  // ============================================================
  if (sheetName === yoteiSheetName && col === 1 && row >= 2) {

    const checked = e.range.getValue() === true;
    if (!checked) return; // チェックが外れた場合は何もしない

    const doneSheet = e.source.getSheetByName(doneSheetName);

    // ▼ 行データ取得（移動元の行）
    const rowData = sheet.getRange(row, 1, 1, lastCol).getValues()[0];

    // ▼ A列チェックを false に戻す（移動先でチェック済みにならないように）
    rowData[0] = false;

    // ▼ 入庫済みの最終行へ追加
    const doneLastRow = doneSheet.getLastRow();
    doneSheet.getRange(doneLastRow + 1, 1, 1, lastCol).setValues([rowData]);

    // ▼ 削除前に1行追加（行ずれ防止）
    sheet.insertRowAfter(row);

    // ▼ 元の行を削除
    sheet.deleteRow(row);

    // ▼ 両シートをソート
    autoSortSheet(sheet);
    autoSortSheet(doneSheet);
  }


  // ============================================================
  // ② 入庫済みの A列チェック → 予定表へ戻す（確認ダイアログなし）
  // ============================================================
  if (sheetName === doneSheetName && col === 1 && row >= 2) {

    const checked = e.range.getValue() === true;
    if (!checked) return;

    const yoteiSheet = e.source.getSheetByName(yoteiSheetName);

    // ▼ 行データ取得
    const rowData = sheet.getRange(row, 1, 1, lastCol).getValues()[0];

    // ▼ A列チェックを false に戻す
    rowData[0] = false;

    // ▼ 予定表の最終行へ追加
    const yoteiLastRow = yoteiSheet.getLastRow();
    yoteiSheet.getRange(yoteiLastRow + 1, 1, 1, lastCol).setValues([rowData]);

    // ▼ 入庫済み側の行を削除
    sheet.deleteRow(row);

    // ▼ 両シートをソート
    autoSortSheet(sheet);
    autoSortSheet(yoteiSheet);
  }


  // ============================================================
  // ③ 予定表の F列編集 → ソート後にカーソル復帰（PCのみ）
  // ============================================================
  if (sheetName === yoteiSheetName && col === 6 && row >= 2) {

    const startRowIndex = 2;       // データ開始行
    const sortColumnIndex = 2;     // ソート基準（B列）
    const lastRow = sheet.getLastRow();

    // ▼ ソート前の行データを保持（移動後の位置特定用）
    const originalRowValues = sheet.getRange(row, 1, 1, lastCol).getValues()[0];

    // ▼ ソート実行（B列昇順）
    const sortRange = sheet.getRange(startRowIndex, 1, lastRow - startRowIndex + 1, lastCol);
    sortRange.sort({ column: sortColumnIndex, ascending: true });

    // ▼ ソート後の全データを取得
    const afterData = sheet.getRange(startRowIndex, 1, lastRow - startRowIndex + 1, lastCol).getValues();

    // ▼ 移動後の行番号を検索
    let newRow = null;
    for (let i = 0; i < afterData.length; i++) {
      if (JSON.stringify(afterData[i]) === JSON.stringify(originalRowValues)) {
        newRow = startRowIndex + i;
        break;
      }
    }

    // ▼ PCのみカーソル移動（スマホは setActiveRange が無効）
    if (newRow) {
      sheet.setActiveRange(sheet.getRange(newRow, 6)); // ★F列へカーソル復帰
    }
  }

}


/**
 * 任意シートを B列で昇順ソートする（汎用関数）
 * ------------------------------------------------------------------
 * A列チェック時の移動処理で使用。
 * B列（2列目）を基準に昇順ソートする。
 */
function autoSortSheet(sheet) {

  const startRow = 2;
  const lastRow = sheet.getLastRow();
  const lastCol = sheet.getLastColumn();

  if (lastRow <= startRow) return;

  const sortRange = sheet.getRange(startRow, 1, lastRow - startRow + 1, lastCol);

  sortRange.sort({ column: 2, ascending: true }); // B列でソート
}
