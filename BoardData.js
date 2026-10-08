/**
 * 縦置きディスプレイ（1080×1920）向けの予定表 Web アプリ。
 * 表示するのは 日付・ユーザー名・車番・修理内容・備考。
 * 入庫・担当者・完成日は出さない。
 */

var BOARD_SPREADSHEET_ID = '1676Bc3HI8fe_LXaE8-VeoM_sbrXEKLwRiR0Ba53fVb0';
var BOARD_SHEET_NAME = '予定表';
var BOARD_COLUMNS = ['日付', 'ユーザー名', '車番', '修理内容', '備考'];
var BOARD_TIMEZONE = 'Asia/Tokyo';
var BOARD_WEEKDAYS = '日月火水木金土';

function doGet() {
  return HtmlService.createHtmlOutputFromFile('Board')
    .setTitle('一般修理管理表')
    .addMetaTag('viewport', 'width=device-width, initial-scale=1')
    .setXFrameOptionsMode(HtmlService.XFrameOptionsMode.ALLOWALL);
}

function getBoardData() {
  var sheet = SpreadsheetApp.openById(BOARD_SPREADSHEET_ID).getSheetByName(BOARD_SHEET_NAME);
  if (!sheet) {
    throw new Error('シート「' + BOARD_SHEET_NAME + '」が見つかりません');
  }

  var values = sheet.getDataRange().getDisplayValues();
  if (!values.length) {
    return boardPayload_([]);
  }

  var header = values[0].map(function (cell) {
    return String(cell || '').trim();
  });
  var index = {};
  BOARD_COLUMNS.forEach(function (name) {
    index[name] = header.indexOf(name);
  });
  var missing = BOARD_COLUMNS.filter(function (name) {
    return index[name] < 0;
  });
  if (missing.length) {
    throw new Error('列が見つかりません: ' + missing.join('、'));
  }

  var todayKey = Utilities.formatDate(new Date(), BOARD_TIMEZONE, 'yyyy-MM-dd');
  var rows = [];
  for (var r = 1; r < values.length; r++) {
    var line = values[r];
    var fields = {
      dateRaw: String(line[index['日付']] || '').trim(),
      user: String(line[index['ユーザー名']] || '').trim(),
      car: String(line[index['車番']] || '').trim(),
      work: String(line[index['修理内容']] || '').trim(),
      note: String(line[index['備考']] || '').trim()
    };
    if (!fields.dateRaw && !fields.user && !fields.car && !fields.work && !fields.note) {
      continue;
    }

    var date = boardDate_(fields.dateRaw);
    rows.push({
      date: date.label,
      weekday: date.weekday,
      weekdayKind: date.weekdayKind,
      isToday: date.key !== '' && date.key === todayKey,
      user: fields.user,
      car: fields.car,
      work: fields.work,
      note: fields.note
    });
  }

  return boardPayload_(rows);
}

function boardPayload_(rows) {
  var now = new Date();
  return {
    title: '一般修理管理表',
    sheetName: BOARD_SHEET_NAME,
    updated: Utilities.formatDate(now, BOARD_TIMEZONE, 'HH:mm'),
    count: rows.length,
    rows: rows
  };
}

function boardDate_(text) {
  var match = String(text || '').match(/^(\d{4})[\/.\-](\d{1,2})[\/.\-](\d{1,2})/);
  if (!match) {
    return { label: text, weekday: '', weekdayKind: '', key: '' };
  }

  var year = Number(match[1]);
  var month = Number(match[2]);
  var day = Number(match[3]);
  var date = new Date(year, month - 1, day, 12, 0, 0);
  var dayIndex = date.getDay();
  var kind = dayIndex === 0 ? 'sun' : dayIndex === 6 ? 'sat' : '';
  return {
    label: month + '/' + day,
    weekday: BOARD_WEEKDAYS.charAt(dayIndex),
    weekdayKind: kind,
    key: year + '-' + boardPad_(month) + '-' + boardPad_(day)
  };
}

function boardPad_(number) {
  return (number < 10 ? '0' : '') + number;
}
