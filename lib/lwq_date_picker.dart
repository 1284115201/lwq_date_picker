library lwq_date_picker;

import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

/// Default value of minimum datetime.
const String datePickerMinDatetime = "1900-01-01 00:00:00";

/// Default value of maximum datetime.
const String datePickerMaxDatetime = "2100-12-31 23:59:59";

/// Default value of date format
const String datetimePickerDateFormat = 'yyyy-MM-dd';

/// Default value of time format
const String datetimePickerTimeFormat = 'HH:mm:ss';

/// Default value of datetime format
const String datetimePickerDatetimeFormat = 'yyyyMMdd HH:mm:ss';

/// Default value of date format
const String datetimeRangePickerDateFormat = 'MM-dd';

/// Default value of time format
const String datetimeRangePickerTimeFormat = 'HH:mm';

/// Default value of datetime format
const String datetimeRangePickerDatetimeFormat = 'MMdd HH:mm';

const String dateFormatSeparator = r'[|,-\._: ]+';

/// Default value of DatePicker's background color.
const pickerBackgroundColor = Colors.white;

/// Default value of whether show title widget or not.
const pickerShowTitleDefault = true;

/// Default value of DatePicker's height.
const double pickerContentHeight = 240.0;

/// Default value of DatePicker's title height.
const double pickerTitleHeight = 48.0;

/// Default value of DatePicker's column height.
const double pickerItemHeight = 48.0;

const Color dividerColor = Color(0xFFD5D5D5);
const Color kHighlighterBorder = Color(0xFFF0F0F0);
const Color kDefaultBackground = Color(0xFFFFFFFF);

// Eyeballed values comparing with a native picker to produce the right
// curvatures and densities.
const double kDefaultDiameterRatio = 3;
const double kDefaultPerspective = 0.001;
const double kSqueeze = 1;

/// Opacity fraction value that hides the wheel above and below the 'magnifier'
/// lens with the same color as the background.
const double kForegroundScreenOpacityFraction = 0.4;

/// Solar months of 31 days.
const List<int> solarMonthsOf31Days = <int>[1, 3, 5, 7, 8, 10, 12];

const textStyle = TextStyle(
  color: Color(0xFF222222),
  fontSize: 18.0,
);

typedef DateVoidCallback = Function();

typedef DateValueCallback = Function(
    DateTime dateTime, List<int> selectedIndex);

enum LwqDateTimePickerMode {
  date,

  time,

  datetime,
}

enum LwqDateTimeRangePickerMode {
  /// 日期模式，仅展示到 月、日
  date,

  /// 时间模式，仅展示到 时、分、秒
  time,
}

enum ColumnType { year, month, day, hour, minute, second }

class LwqDatePicker {
  static void showDatePicker(
    BuildContext context, {
    bool rootNavigator = false,
    bool? canBarrierDismissible,
    DateTime? minDateTime,
    DateTime? maxDateTime,
    DateTime? initialDateTime,
    String? dateFormat,
    int minuteDivider = 1,
    LwqDateTimePickerMode pickerMode = LwqDateTimePickerMode.date,
    DateVoidCallback? onCancel,
    DateVoidCallback? onClose,
    DateValueCallback? onChange,
    DateValueCallback? onConfirm,
  }) {
    minDateTime ??= DateTime.parse(datePickerMinDatetime);
    maxDateTime ??= DateTime.parse(datePickerMaxDatetime);

    initialDateTime ??= DateTime.now();

    dateFormat = DateTimeFormatter.generateDateFormat(dateFormat, pickerMode);

    Navigator.of(context, rootNavigator: rootNavigator)
        .push(
          _DatePickerRoute(
            canBarrierDismissible: canBarrierDismissible,
            minDateTime: minDateTime,
            maxDateTime: maxDateTime,
            initialDateTime: initialDateTime,
            dateFormat: dateFormat,
            minuteDivider: minuteDivider,
            pickerMode: pickerMode,
            onCancel: onCancel,
            onChange: onChange,
            onConfirm: onConfirm,
            theme: Theme.of(context),
            barrierLabel:
                MaterialLocalizations.of(context).modalBarrierDismissLabel,
          ),
        )
        .whenComplete(onClose ?? () {});
  }
}

class _DatePickerRoute<T> extends PopupRoute<T> {
  _DatePickerRoute({
    this.minDateTime,
    this.maxDateTime,
    this.initialDateTime,
    this.minuteDivider,
    this.dateFormat,
    this.pickerMode = LwqDateTimePickerMode.date,
    this.onCancel,
    this.onChange,
    this.onConfirm,
    this.theme,
    this.barrierLabel,
    this.canBarrierDismissible,
    super.settings,
  });

  final DateTime? minDateTime, maxDateTime, initialDateTime;
  final String? dateFormat;
  final LwqDateTimePickerMode pickerMode;
  final VoidCallback? onCancel;
  final DateValueCallback? onChange;
  final DateValueCallback? onConfirm;
  bool? canBarrierDismissible;
  final int? minuteDivider;
  final ThemeData? theme;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 200);

  @override
  bool get barrierDismissible => canBarrierDismissible ?? true;

  @override
  final String? barrierLabel;

  @override
  Color get barrierColor => Colors.black54;

  AnimationController? _animationController;

  @override
  AnimationController createAnimationController() {
    assert(_animationController == null);
    _animationController =
        BottomSheet.createAnimationController(navigator!.overlay!);
    return _animationController!;
  }

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    double pickerHeight = pickerTitleHeight + pickerContentHeight;

    Widget bottomSheet = MediaQuery.removePadding(
      context: context,
      removeTop: true,
      child: _DatePickerComponent(route: this, pickerHeight: pickerHeight),
    );

    if (theme != null) {
      bottomSheet = Theme(data: theme!, child: bottomSheet);
    }
    return bottomSheet;
  }
}

// ignore: must_be_immutable
class _DatePickerComponent extends StatelessWidget {
  final _DatePickerRoute route;
  final double _pickerHeight;

  const _DatePickerComponent({required this.route, required pickerHeight})
      : _pickerHeight = pickerHeight;

  @override
  Widget build(BuildContext context) {
    Widget? pickerWidget;
    switch (route.pickerMode) {
      case LwqDateTimePickerMode.date:
        pickerWidget = LwqDateWidget(
          minDateTime: route.minDateTime,
          maxDateTime: route.maxDateTime,
          initialDateTime: route.initialDateTime,
          dateFormat: route.dateFormat,
          onCancel: route.onCancel,
          onChange: route.onChange,
          onConfirm: route.onConfirm,
        );
        break;
      case LwqDateTimePickerMode.time:
        pickerWidget = LwqTimeWidget(
          minDateTime: route.minDateTime,
          maxDateTime: route.maxDateTime,
          initDateTime: route.initialDateTime,
          dateFormat: route.dateFormat,
          minuteDivider: route.minuteDivider,
          onCancel: route.onCancel,
          onChange: route.onChange,
          onConfirm: route.onConfirm,
        );
        break;
      case LwqDateTimePickerMode.datetime:
        pickerWidget = LwqDateTimeWidget(
          minDateTime: route.minDateTime,
          maxDateTime: route.maxDateTime,
          initDateTime: route.initialDateTime,
          dateFormat: route.dateFormat,
          minuteDivider: route.minuteDivider,
          onCancel: route.onCancel,
          onChange: route.onChange,
          onConfirm: route.onConfirm,
        );
        break;
    }
    return GestureDetector(
      child: AnimatedBuilder(
        animation: route.animation!,
        builder: (BuildContext context, Widget? child) {
          return ClipRect(
            child: CustomSingleChildLayout(
              delegate:
                  _BottomPickerLayout(route.animation!.value, _pickerHeight),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8.0),
                  topRight: Radius.circular(8.0),
                ),
                child: pickerWidget,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BottomPickerLayout extends SingleChildLayoutDelegate {
  _BottomPickerLayout(this.progress, this.contentHeight);

  final double progress;
  final double contentHeight;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return BoxConstraints(
      minWidth: constraints.maxWidth,
      maxWidth: constraints.maxWidth,
      minHeight: 0.0,
      maxHeight: contentHeight,
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    double height = size.height - childSize.height * progress;
    return Offset(0.0, height);
  }

  @override
  bool shouldRelayout(_BottomPickerLayout oldDelegate) {
    return progress != oldDelegate.progress;
  }
}

class DateTimeFormatter {
  // static DateTime? convertStringToDate(String? format, String? date) {
  //   if (LwqTools.isEmpty(format) || LwqTools.isEmpty(date)) return null;
  //
  //   return DateFormat(format).parse(date!);
  // }

  static DateTime? convertIntValueToDateTime(String? value) {
    if (value == null) {
      return null;
    } else {
      return int.tryParse(value) != null
          ? DateTime.fromMillisecondsSinceEpoch(int.tryParse(value)!)
          : null;
    }
  }

  /// Get default value of date format.
  static String generateDateFormat(
      String? dateFormat, LwqDateTimePickerMode pickerMode) {
    if (dateFormat != null && dateFormat.isNotEmpty) {
      return dateFormat;
    }
    switch (pickerMode) {
      case LwqDateTimePickerMode.date:
        return datetimePickerDateFormat;
      case LwqDateTimePickerMode.time:
        return datetimePickerTimeFormat;
      case LwqDateTimePickerMode.datetime:
        return datetimePickerDatetimeFormat;
    }
  }

  static String generateDateRangePickerFormat(
      String? dateFormat, LwqDateTimeRangePickerMode pickerMode) {
    if (dateFormat != null && dateFormat.isNotEmpty) {
      return dateFormat;
    }
    switch (pickerMode) {
      case LwqDateTimeRangePickerMode.date:
        return datetimeRangePickerDateFormat;
      case LwqDateTimeRangePickerMode.time:
        return datetimeRangePickerTimeFormat;
    }
  }

  /// Check if the date format is for day(contain y、M、d、E) or not.
  static bool isDayFormat(String format) {
    return format.contains(RegExp(r'[yMdE]'));
  }

  /// Check if the date format is for time(contain H、m、s) or not.
  static bool isTimeFormat(String format) {
    return format.contains(RegExp(r'[Hms]'));
  }

  /// Split date format to array.
  static List<String> splitDateFormat(String? dateFormat,
      {LwqDateTimePickerMode? mode}) {
    if (dateFormat == null || dateFormat.isEmpty) {
      return [];
    }
    List<String> result = dateFormat.split(RegExp(dateFormatSeparator));
    if (mode == LwqDateTimePickerMode.datetime) {
      // datetime mode need join day format
      List<String> temp = [];
      StringBuffer dayFormat = StringBuffer();
      for (int i = 0; i < result.length; i++) {
        String format = result[i];
        if (isDayFormat(format)) {
          // find format pre-separator
          int end = dateFormat.indexOf(format);
          if (end > 0) {
            int start = 0;
            if (i > 0) {
              start = dateFormat.indexOf(result[i - 1]) + result[i - 1].length;
            }
            dayFormat.write(dateFormat.substring(start, end));
          }
          dayFormat.write(format);
        } else if (isTimeFormat(format)) {
          temp.add(format);
        }
      }
      if (dayFormat.length > 0) {
        temp.insert(0, dayFormat.toString());
      } else {
        // add default date format
        temp.insert(0, datetimePickerDateFormat);
      }
      result = temp;
    }
    return result;
  }

  /// Format datetime string
  static String formatDateTime(int value, String format) {
    if (format.isEmpty) {
      return value.toString();
    }

    String result = format;
    // format year text
    if (format.contains('y')) {
      result = _formatYear(value, result);
    }
    // format month text
    if (format.contains('M')) {
      result = _formatMonth(value, result);
    }
    // format day text
    if (format.contains('d')) {
      result = _formatDay(value, result);
    }
    if (format.contains('E')) {
      result = _formatWeek(value, result);
    }
    // format hour text
    if (format.contains('H')) {
      result = _formatHour(value, result);
    }
    // format minute text
    if (format.contains('m')) {
      result = _formatMinute(value, result);
    }
    // format second text
    if (format.contains('s')) {
      result = _formatSecond(value, result);
    }
    if (result == format) {
      return value.toString();
    }
    return result;
  }

  /// Format day display
  static String formatDate(DateTime dateTime, String format) {
    if (format.isEmpty) {
      return dateTime.toString();
    }

    String result = format;
    // format year text
    if (format.contains('y')) {
      result = _formatYear(dateTime.year, result);
    }
    // format month text
    if (format.contains('M')) {
      result = _formatMonth(dateTime.month, result);
    }
    // format day text
    if (format.contains('d')) {
      result = _formatDay(dateTime.day, result);
    }
    if (format.contains('E')) {
      result = _formatWeek(dateTime.weekday, result);
    }
    if (result == format) {
      return dateTime.toString();
    }
    return result;
  }

  /// format year text
  static String _formatYear(int value, String format) {
    if (format.contains('yyyy')) {
      // yyyy: the digit count of year is 4, e.g. 2019
      return format.replaceAll('yyyy', value.toString());
    } else if (format.contains('yy')) {
      // yy: the digit count of year is 2, e.g. 19
      return format.replaceAll('yy',
          value.toString().substring(max(0, value.toString().length - 2)));
    }
    return value.toString();
  }

  /// format month text
  static String _formatMonth(int value, String format) {
    List<String> months = LwqIntl.currentResource.months;
    if (format.contains('MMMM')) {
      // MMMM: the full name of month, e.g. January
      return format.replaceAll('MMMM', months[value - 1]);
    } else if (format.contains('MMM')) {
      // MMM: the short name of month, e.g. Jan
      String month = months[value - 1];
      return format.replaceAll('MMM', month.substring(0, min(3, month.length)));
    }
    return _formatNumber(value, format, 'M');
  }

  /// format day text
  static String _formatDay(int value, String format) {
    return _formatNumber(value, format, 'd');
  }

  /// format week text
  static String _formatWeek(int value, String format) {
    if (format.contains('EEEE')) {
      // EEEE: the full name of week, e.g. Monday
      List<String> weeks = LwqIntl.currentResource.weekFullName;
      return format.replaceAll('EEEE', weeks[value - 1]);
    }
    // EEE: the short name of week, e.g. Mon
    List<String> weeks = LwqIntl.currentResource.weekShortName;
    return format.replaceAll(RegExp(r'E+'), weeks[value - 1]);
  }

  /// format hour text
  static String _formatHour(int value, String format) {
    return _formatNumber(value, format, 'H');
  }

  /// format minute text
  static String _formatMinute(int value, String format) {
    return _formatNumber(value, format, 'm');
  }

  /// format second text
  static String _formatSecond(int value, String format) {
    return _formatNumber(value, format, 's');
  }

  /// format number, if the digit count is 2, will pad zero on the left
  static String _formatNumber(int value, String format, String unit) {
    if (format.contains('$unit$unit')) {
      return format.replaceAll('$unit$unit', value.toString().padLeft(2, '0'));
    } else if (format.contains(unit)) {
      return format.replaceAll(unit, value.toString());
    }
    return value.toString();
  }
}

class LwqDateWidget extends StatefulWidget {
  LwqDateWidget({
    super.key,
    this.minDateTime,
    this.maxDateTime,
    this.initialDateTime,
    this.dateFormat = datetimePickerDateFormat,
    this.onCancel,
    this.onChange,
    this.onConfirm,
    this.canPop = true,
  }) {
    DateTime minTime = minDateTime ?? DateTime.parse(datePickerMinDatetime);
    DateTime maxTime = maxDateTime ?? DateTime.parse(datePickerMaxDatetime);
    assert(minTime.compareTo(maxTime) < 0);
  }

  final DateTime? minDateTime, maxDateTime, initialDateTime;
  final String? dateFormat;

  final DateVoidCallback? onCancel;
  final DateValueCallback? onChange, onConfirm;
  final bool canPop;

  @override
  State<StatefulWidget> createState() => _LwqDateWidgetState();
}

class _LwqDateWidgetState extends State<LwqDateWidget> {
  late DateTime _minDateTime, _maxDateTime;
  late int _currYear, _currMonth, _currDay;
  late List<int> _yearRange, _monthRange, _dayRange;
  late FixedExtentScrollController? _yearScrollCtrl,
      _monthScrollCtrl,
      _dayScrollCtrl;

  late Map<String, FixedExtentScrollController?> _scrollCtrlMap;
  late Map<String, List<int>?> _valueRangeMap;

  bool _isChangeDateRange = false;

  _LwqDateWidgetState();

  @override
  void initState() {
    // handle current selected year、month、day
    DateTime initDateTime = widget.initialDateTime ?? DateTime.now();
    _currYear = initDateTime.year;
    _currMonth = initDateTime.month;
    _currDay = initDateTime.day;

    // handle DateTime range
    _minDateTime = widget.minDateTime ?? DateTime.parse(datePickerMinDatetime);
    _maxDateTime = widget.maxDateTime ?? DateTime.parse(datePickerMaxDatetime);

    // limit the range of year
    _yearRange = _calcYearRange();
    _currYear = min(max(_minDateTime.year, _currYear), _maxDateTime.year);

    // limit the range of month
    _monthRange = _calcMonthRange();
    _currMonth = min(max(_monthRange.first, _currMonth), _monthRange.last);

    // limit the range of day
    _dayRange = _calcDayRange();
    _currDay = min(max(_dayRange.first, _currDay), _dayRange.last);

    // create scroll controller
    _yearScrollCtrl =
        FixedExtentScrollController(initialItem: _currYear - _yearRange.first);
    _monthScrollCtrl = FixedExtentScrollController(
        initialItem: _currMonth - _monthRange.first);
    _dayScrollCtrl =
        FixedExtentScrollController(initialItem: _currDay - _dayRange.first);

    _scrollCtrlMap = {
      'y': _yearScrollCtrl,
      'M': _monthScrollCtrl,
      'd': _dayScrollCtrl
    };
    _valueRangeMap = {'y': _yearRange, 'M': _monthRange, 'd': _dayRange};
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Material(
          color: Colors.transparent, child: _renderPickerView(context)),
    );
  }

  /// render date picker widgets
  Widget _renderPickerView(BuildContext context) {
    Widget titleWidget = LwqPickerTitle(
      onCancel: () => _onPressedCancel(),
      onConfirm: () => _onPressedConfirm(),
    );
    Widget datePickerWidget = _renderDatePickerWidget();
    return Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[titleWidget, datePickerWidget]);
  }

  /// pressed cancel widget
  void _onPressedCancel() {
    if (widget.onCancel != null) {
      widget.onCancel!();
    }
    if (widget.canPop) Navigator.pop(context);
  }

  /// pressed confirm widget
  void _onPressedConfirm() {
    if (widget.onConfirm != null) {
      DateTime dateTime = DateTime(_currYear, _currMonth, _currDay);
      widget.onConfirm!(dateTime, _calcSelectIndexList());
    }
    if (widget.canPop) Navigator.pop(context);
  }

  /// notify selected date changed
  void _onSelectedChange() {
    if (widget.onChange != null) {
      DateTime dateTime = DateTime(_currYear, _currMonth, _currDay);
      widget.onChange!(dateTime, _calcSelectIndexList());
    }
  }

  /// find scroll controller by specified format
  FixedExtentScrollController? _findScrollCtrl(String format) {
    FixedExtentScrollController? scrollCtrl;
    _scrollCtrlMap.forEach((key, value) {
      if (format.contains(key)) {
        scrollCtrl = value;
      }
    });
    return scrollCtrl;
  }

  /// find item value range by specified format
  List<int>? _findPickerItemRange(String format) {
    List<int>? valueRange;
    _valueRangeMap.forEach((key, value) {
      if (format.contains(key)) {
        valueRange = value;
      }
    });
    return valueRange;
  }

  /// render the picker widget of year、month and day
  Widget _renderDatePickerWidget() {
    List<Widget> pickers = [];
    List<String> formatArr =
        DateTimeFormatter.splitDateFormat(widget.dateFormat);
    for (var format in formatArr) {
      List<int> valueRange = _findPickerItemRange(format)!;

      Widget pickerColumn = _renderDatePickerColumnComponent(
        scrollCtrl: _findScrollCtrl(format),
        valueRange: valueRange,
        format: format,
        valueChanged: (value) {
          if (format.contains('y')) {
            _changeYearSelection(value);
          } else if (format.contains('M')) {
            _changeMonthSelection(value);
          } else if (format.contains('d')) {
            _changeDaySelection(value);
          }
        },
      );
      pickers.add(pickerColumn);
    }
    return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, children: pickers);
  }

  Widget _renderDatePickerColumnComponent({
    required FixedExtentScrollController? scrollCtrl,
    required List<int> valueRange,
    required String format,
    required ValueChanged<int> valueChanged,
  }) {
    return Expanded(
      flex: 1,
      child: Container(
        height: pickerContentHeight,
        decoration: const BoxDecoration(color: Colors.white),
        child: LwqPicker.builder(
          backgroundColor: Colors.white,
          lineColor: dividerColor,
          scrollController: scrollCtrl,
          itemExtent: pickerItemHeight,
          onSelectedItemChanged: valueChanged,
          childCount: valueRange.last - valueRange.first + 1,
          itemBuilder: (context, index) => _renderDatePickerItemComponent(
              format.contains("y")
                  ? ColumnType.year
                  : (format.contains("M") ? ColumnType.month : ColumnType.day),
              index,
              valueRange.first + index,
              format),
        ),
      ),
    );
  }

  Widget _renderDatePickerItemComponent(
      ColumnType columnType, int index, int value, String format) {
    if ((ColumnType.year == columnType && index == _calcSelectIndexList()[0]) ||
        (ColumnType.month == columnType &&
            index == _calcSelectIndexList()[1]) ||
        (ColumnType.day == columnType && index == _calcSelectIndexList()[2])) {}
    return Container(
      height: pickerItemHeight,
      alignment: Alignment.center,
      child: Text(DateTimeFormatter.formatDateTime(value, format),
          style: textStyle),
    );
  }

  /// change the selection of year picker
  void _changeYearSelection(int index) {
    int year = _yearRange.first + index;
    if (_currYear != year) {
      _currYear = year;
      _changeDateRange();
      _onSelectedChange();
    }
  }

  /// change the selection of month picker
  void _changeMonthSelection(int index) {
    int month = _monthRange.first + index;
    if (_currMonth != month) {
      _currMonth = month;
      _changeDateRange();
      _onSelectedChange();
    }
  }

  /// change the selection of day picker
  void _changeDaySelection(int index) {
    int dayOfMonth = _dayRange.first + index;
    if (_currDay != dayOfMonth) {
      _currDay = dayOfMonth;
      _changeDateRange();
      _onSelectedChange();
    }
  }

  /// change range of month and day
  void _changeDateRange() {
    if (_isChangeDateRange) {
      return;
    }
    _isChangeDateRange = true;

    List<int> monthRange = _calcMonthRange();
    bool monthRangeChanged = _monthRange.first != monthRange.first ||
        _monthRange.last != monthRange.last;
    if (monthRangeChanged) {
      // selected year changed
      _currMonth = max(min(_currMonth, monthRange.last), monthRange.first);
    }

    List<int> dayRange = _calcDayRange();
    bool dayRangeChanged =
        _dayRange.first != dayRange.first || _dayRange.last != dayRange.last;
    if (dayRangeChanged) {
      // day range changed, need limit the value of selected day
      _currDay = max(min(_currDay, dayRange.last), dayRange.first);
    }

    setState(() {
      _monthRange = monthRange;
      _dayRange = dayRange;

      _valueRangeMap['M'] = monthRange;
      _valueRangeMap['d'] = dayRange;
    });

    if (monthRangeChanged) {
      // CupertinoPicker refresh data not working (https://github.com/flutter/flutter/issues/22999)
      int currMonth = _currMonth;
      _monthScrollCtrl!.jumpToItem(monthRange.last - monthRange.first);
      if (currMonth < monthRange.last) {
        _monthScrollCtrl!.jumpToItem(currMonth - monthRange.first);
      }
    }

    if (dayRangeChanged) {
      // CupertinoPicker refresh data not working (https://github.com/flutter/flutter/issues/22999)
      int currDay = _currDay;
      _dayScrollCtrl!.jumpToItem(dayRange.last - dayRange.first);
      if (currDay < dayRange.last) {
        _dayScrollCtrl!.jumpToItem(currDay - dayRange.first);
      }
    }

    _isChangeDateRange = false;
  }

  /// calculate the count of day in current month
  int _calcDayCountOfMonth() {
    if (_currMonth == 2) {
      return isLeapYear(_currYear) ? 29 : 28;
    } else if (solarMonthsOf31Days.contains(_currMonth)) {
      return 31;
    }
    return 30;
  }

  /// whether or not is leap year
  bool isLeapYear(int year) {
    return (year % 4 == 0 && year % 100 != 0) || year % 400 == 0;
  }

  /// calculate selected index list
  List<int> _calcSelectIndexList() {
    int yearIndex = _currYear - _minDateTime.year;
    int monthIndex = _currMonth - _monthRange.first;
    int dayIndex = _currDay - _dayRange.first;
    return [yearIndex, monthIndex, dayIndex];
  }

  /// calculate the range of year
  List<int> _calcYearRange() {
    return [_minDateTime.year, _maxDateTime.year];
  }

  /// calculate the range of month
  List<int> _calcMonthRange() {
    int minMonth = 1, maxMonth = 12;
    int minYear = _minDateTime.year;
    int maxYear = _maxDateTime.year;
    if (minYear == _currYear) {
      // selected minimum year, limit month range
      minMonth = _minDateTime.month;
    }
    if (maxYear == _currYear) {
      // selected maximum year, limit month range
      maxMonth = _maxDateTime.month;
    }
    return [minMonth, maxMonth];
  }

  /// calculate the range of day
  List<int> _calcDayRange({currMonth}) {
    int minDay = 1, maxDay = _calcDayCountOfMonth();
    int minYear = _minDateTime.year;
    int maxYear = _maxDateTime.year;
    int minMonth = _minDateTime.month;
    int maxMonth = _maxDateTime.month;
    currMonth ??= _currMonth;
    if (minYear == _currYear && minMonth == currMonth) {
      // selected minimum year and month, limit day range
      minDay = _minDateTime.day;
    }
    if (maxYear == _currYear && maxMonth == currMonth) {
      // selected maximum year and month, limit day range
      maxDay = _maxDateTime.day;
    }
    return [minDay, maxDay];
  }
}

class LwqTimeWidget extends StatefulWidget {
  LwqTimeWidget({
    super.key,
    this.minDateTime,
    this.maxDateTime,
    this.initDateTime,
    this.dateFormat = datetimePickerTimeFormat,
    this.minuteDivider = 1,
    this.onCancel,
    this.onChange,
    this.onConfirm,
  }) {
    DateTime minTime = minDateTime ?? DateTime.parse(datePickerMinDatetime);
    DateTime maxTime = maxDateTime ?? DateTime.parse(datePickerMaxDatetime);
    assert(minTime.compareTo(maxTime) < 0);
  }

  final DateTime? minDateTime, maxDateTime, initDateTime;
  final String? dateFormat;
  final DateVoidCallback? onCancel;
  final DateValueCallback? onChange, onConfirm;
  final int? minuteDivider;

  @override
  State<StatefulWidget> createState() => _LwqTimeWidgetState();
}

class _LwqTimeWidgetState extends State<LwqTimeWidget> {
  static const int _defaultMinuteDivider = 1;

  late DateTime _minTime, _maxTime;
  late int _currHour, _currMinute, _currSecond;
  late int _minuteDivider;
  late List<int> _hourRange, _minuteRange, _secondRange;
  late FixedExtentScrollController _hourScrollCtrl,
      _minuteScrollCtrl,
      _secondScrollCtrl;

  late Map<String, FixedExtentScrollController?> _scrollCtrlMap;
  late Map<String, List<int>> _valueRangeMap;

  bool _isChangeTimeRange = false;

  _LwqTimeWidgetState();

  @override
  void initState() {
    _minTime = widget.minDateTime ?? DateTime.parse(datePickerMinDatetime);
    _maxTime = widget.maxDateTime ?? DateTime.parse(datePickerMaxDatetime);
    DateTime initDateTime = widget.initDateTime ?? DateTime.now();
    _currHour = initDateTime.hour;
    _currMinute = initDateTime.minute;
    _currSecond = initDateTime.second;
    _minuteDivider = widget.minuteDivider ?? _defaultMinuteDivider;

    // limit the range of hour
    _hourRange = _calcHourRange();
    _currHour = min(max(_hourRange.first, _currHour), _hourRange.last);

    // limit the range of minute
    _minuteRange = _calcMinuteRange();
    _currMinute = min(max(_minuteRange.first, _currMinute), _minuteRange.last);
    _currMinute -= _currMinute % _minuteDivider;
    // limit the range of second
    _secondRange = _calcSecondRange();
    _currSecond = min(max(_secondRange.first, _currSecond), _secondRange.last);

    // create scroll controller
    _hourScrollCtrl =
        FixedExtentScrollController(initialItem: _currHour - _hourRange.first);
    _minuteScrollCtrl = FixedExtentScrollController(
        initialItem: (_currMinute - _minuteRange.first) ~/ _minuteDivider);
    _secondScrollCtrl = FixedExtentScrollController(
        initialItem: _currSecond - _secondRange.first);

    _scrollCtrlMap = {
      'H': _hourScrollCtrl,
      'm': _minuteScrollCtrl,
      's': _secondScrollCtrl
    };
    _valueRangeMap = {'H': _hourRange, 'm': _minuteRange, 's': _secondRange};
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Material(
          color: Colors.transparent, child: _renderPickerView(context)),
    );
  }

  /// render time picker widgets
  Widget _renderPickerView(BuildContext context) {
    Widget titleWidget = LwqPickerTitle(
      onCancel: () => _onPressedCancel(),
      onConfirm: () => _onPressedConfirm(),
    );
    Widget pickerWidget = _renderDatePickerWidget();
    return Column(children: <Widget>[titleWidget, pickerWidget]);
  }

  /// pressed cancel widget
  void _onPressedCancel() {
    if (widget.onCancel != null) {
      widget.onCancel!();
    }
    Navigator.pop(context);
  }

  /// pressed confirm widget
  void _onPressedConfirm() {
    if (widget.onConfirm != null) {
      DateTime now = DateTime.now();
      DateTime dateTime = DateTime(
          now.year, now.month, now.day, _currHour, _currMinute, _currSecond);
      widget.onConfirm!(dateTime, _calcSelectIndexList());
    }
    Navigator.pop(context);
  }

  /// notify selected time changed
  void _onSelectedChange() {
    if (widget.onChange != null) {
      DateTime now = DateTime.now();
      DateTime dateTime = DateTime(
          now.year, now.month, now.day, _currHour, _currMinute, _currSecond);
      widget.onChange!(dateTime, _calcSelectIndexList());
    }
  }

  /// find scroll controller by specified format
  FixedExtentScrollController? _findScrollCtrl(String format) {
    FixedExtentScrollController? scrollCtrl;
    _scrollCtrlMap.forEach((key, value) {
      if (format.contains(key)) {
        scrollCtrl = value;
      }
    });
    return scrollCtrl;
  }

  /// find item value range by specified format
  List<int>? _findPickerItemRange(String format) {
    List<int>? valueRange;
    _valueRangeMap.forEach((key, value) {
      if (format.contains(key)) {
        valueRange = value;
      }
    });
    return valueRange;
  }

  /// render the picker widget of year、month and day
  Widget _renderDatePickerWidget() {
    List<Widget> pickers = [];
    List<String> formatArr =
        DateTimeFormatter.splitDateFormat(widget.dateFormat);
    for (var format in formatArr) {
      List<int>? valueRange = _findPickerItemRange(format);

      Widget pickerColumn = _renderDatePickerColumnComponent(
        scrollCtrl: _findScrollCtrl(format),
        valueRange: valueRange,
        format: format,
        valueChanged: (value) {
          if (format.contains('H')) {
            _changeHourSelection(value);
          } else if (format.contains('m')) {
            _changeMinuteSelection(value);
          } else if (format.contains('s')) {
            _changeSecondSelection(value);
          }
        },
      );
      pickers.add(pickerColumn);
    }
    return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, children: pickers);
  }

  Widget _renderDatePickerColumnComponent({
    required FixedExtentScrollController? scrollCtrl,
    required List<int>? valueRange,
    required String format,
    required ValueChanged<int> valueChanged,
  }) {
    return Expanded(
      flex: 1,
      child: Container(
        height: pickerContentHeight,
        decoration: const BoxDecoration(color: Colors.white),
        child: LwqPicker.builder(
          backgroundColor: Colors.white,
          lineColor: dividerColor,
          scrollController: scrollCtrl,
          itemExtent: pickerItemHeight,
          onSelectedItemChanged: valueChanged,
          childCount: format.contains('m')
              ? _calculateMinuteChildCount(valueRange, _minuteDivider)
              : valueRange!.last - valueRange.first + 1,
          itemBuilder: (context, index) {
            int value = valueRange!.first + index;

            if (format.contains('m')) {
              value = _minuteDivider * index;
            }

            return _renderDatePickerItemComponent(
                getColumnType(format), index, value, format);
          },
        ),
      ),
    );
  }

  // ignore: missing_return
  ColumnType? getColumnType(String format) {
    if (format.contains('H')) {
      return ColumnType.hour;
    } else if (format.contains('m')) {
      return ColumnType.minute;
    } else if (format.contains('s')) {
      return ColumnType.second;
    }
    return null;
  }

  _calculateMinuteChildCount(List<int>? valueRange, int? divider) {
    if (divider == 0) {
      debugPrint("Cant devide by 0");
      return (valueRange!.last - valueRange.first + 1);
    }

    return (valueRange!.last - valueRange.first + 1) ~/ divider!;
  }

  Widget _renderDatePickerItemComponent(
      ColumnType? columnType, int index, int value, String format) {
    if ((ColumnType.hour == columnType && index == _calcSelectIndexList()[0]) ||
        (ColumnType.minute == columnType &&
            index == _calcSelectIndexList()[1]) ||
        (ColumnType.second == columnType &&
            index == _calcSelectIndexList()[2])) {}
    return Container(
      height: pickerItemHeight,
      alignment: Alignment.center,
      child: Text(DateTimeFormatter.formatDateTime(value, format),
          style: textStyle),
    );
  }

  /// change the selection of hour picker
  void _changeHourSelection(int index) {
    int value = _hourRange.first + index;
    if (_currHour != value) {
      _currHour = value;
      _changeTimeRange();
      _onSelectedChange();
    }
  }

  /// change the selection of month picker
  void _changeMinuteSelection(int index) {
    int value = index * _minuteDivider;
    if (_currMinute != value) {
      _currMinute = value;
      _changeTimeRange();
      _onSelectedChange();
    }
  }

  /// change the selection of second picker
  void _changeSecondSelection(int index) {
    int value = _secondRange.first + index;
    if (_currSecond != value) {
      _currSecond = value;
      _changeTimeRange();
      _onSelectedChange();
    }
  }

  /// change range of minute and second
  void _changeTimeRange() {
    if (_isChangeTimeRange) {
      return;
    }
    _isChangeTimeRange = true;

    List<int> minuteRange = _calcMinuteRange();
    bool minuteRangeChanged = _minuteRange.first != minuteRange.first ||
        _minuteRange.last != minuteRange.last;
    if (minuteRangeChanged) {
      // selected hour changed
      _currMinute = max(min(_currMinute, minuteRange.last), minuteRange.first);
      _currMinute -= _currMinute % _minuteDivider;
    }

    List<int> secondRange = _calcSecondRange();
    bool secondRangeChanged = _secondRange.first != secondRange.first ||
        _secondRange.last != secondRange.last;
    if (secondRangeChanged) {
      // second range changed, need limit the value of selected second
      _currSecond = max(min(_currSecond, secondRange.last), secondRange.first);
    }

    setState(() {
      _minuteRange = minuteRange;
      _secondRange = secondRange;

      _valueRangeMap['m'] = minuteRange;
      _valueRangeMap['s'] = secondRange;
    });

    if (minuteRangeChanged) {
      // CupertinoPicker refresh data not working (https://github.com/flutter/flutter/issues/22999)
      int currMinute = _currMinute;
      _minuteScrollCtrl
          .jumpToItem((minuteRange.last - minuteRange.first) ~/ _minuteDivider);
      if (currMinute < minuteRange.last) {
        _minuteScrollCtrl.jumpToItem(currMinute - minuteRange.first);
      }
    }

    if (secondRangeChanged) {
      // CupertinoPicker refresh data not working (https://github.com/flutter/flutter/issues/22999)
      int currSecond = _currSecond;
      _secondScrollCtrl.jumpToItem(secondRange.last - secondRange.first);
      if (currSecond < secondRange.last) {
        _secondScrollCtrl.jumpToItem(currSecond - secondRange.first);
      }
    }

    _isChangeTimeRange = false;
  }

  /// calculate selected index list
  List<int> _calcSelectIndexList() {
    int hourIndex = _currHour - _hourRange.first;
    int minuteIndex = (_currMinute - _minuteRange.first) ~/ _minuteDivider;
    int secondIndex = _currSecond - _secondRange.first;
    return [hourIndex, minuteIndex, secondIndex];
  }

  /// calculate the range of hour
  List<int> _calcHourRange() {
    return [_minTime.hour, _maxTime.hour];
  }

  /// calculate the range of minute
  List<int> _calcMinuteRange({currHour}) {
    int minMinute = 0, maxMinute = 59;
    int minHour = _minTime.hour;
    int maxHour = _maxTime.hour;
    currHour ??= _currHour;

    if (minHour == currHour) {
      // selected minimum hour, limit minute range
      minMinute = _minTime.minute;
    }
    if (maxHour == currHour) {
      // selected maximum hour, limit minute range
      maxMinute = _maxTime.minute;
    }
    return [minMinute, maxMinute];
  }

  /// calculate the range of second
  List<int> _calcSecondRange({currHour, currMinute}) {
    int minSecond = 0, maxSecond = 59;
    int minHour = _minTime.hour;
    int maxHour = _maxTime.hour;
    int minMinute = _minTime.minute;
    int maxMinute = _maxTime.minute;

    currHour ??= _currHour;
    currMinute ??= _currMinute;

    if (minHour == currHour && minMinute == currMinute) {
      // selected minimum hour and minute, limit second range
      minSecond = _minTime.second;
    }
    if (maxHour == currHour && maxMinute == currMinute) {
      // selected maximum hour and minute, limit second range
      maxSecond = _maxTime.second;
    }
    return [minSecond, maxSecond];
  }
}

class LwqDateTimeWidget extends StatefulWidget {
  LwqDateTimeWidget({
    super.key,
    this.minDateTime,
    this.maxDateTime,
    this.initDateTime,
    this.dateFormat = datetimePickerTimeFormat,
    this.onCancel,
    this.onChange,
    this.onConfirm,
    this.minuteDivider,
  }) {
    DateTime minTime = minDateTime ?? DateTime.parse(datePickerMinDatetime);
    DateTime maxTime = maxDateTime ?? DateTime.parse(datePickerMaxDatetime);
    assert(minTime.compareTo(maxTime) < 0);
  }

  final DateTime? minDateTime, maxDateTime, initDateTime;
  final int? minuteDivider;
  final String? dateFormat;

  final DateVoidCallback? onCancel;
  final DateValueCallback? onChange, onConfirm;

  @override
  State<StatefulWidget> createState() => _LwqDateTimeWidgetState();
}

class _LwqDateTimeWidgetState extends State<LwqDateTimeWidget> {
  final int _defaultMinuteDivider = 1;

  late DateTime _minTime, _maxTime;
  late int _currYear, _currMonth, _currDay, _currHour, _currMinute, _currSecond;
  late List<int> _yearRange,
      _monthRange,
      _dayRange,
      _hourRange,
      _minuteRange,
      _secondRange;
  late FixedExtentScrollController _yearScrollCtrl,
      _monthScrollCtrl,
      _dayScrollCtrl,
      _hourScrollCtrl,
      _minuteScrollCtrl,
      _secondScrollCtrl;

  late Map<String, FixedExtentScrollController?> _scrollCtrlMap;
  late Map<String, List<int>?> _valueRangeMap;

  bool _isChangeTimeRange = false;

  int? _minuteDivider;

  _LwqDateTimeWidgetState();

  @override
  void initState() {
    _minTime = widget.minDateTime ?? DateTime.parse(datePickerMinDatetime);
    _maxTime = widget.maxDateTime ?? DateTime.parse(datePickerMaxDatetime);
    DateTime initDateTime = widget.initDateTime ?? DateTime.now();
    _currYear = initDateTime.year;
    _currMonth = initDateTime.month;
    _currDay = initDateTime.day;
    _currHour = initDateTime.hour;
    _currMinute = initDateTime.minute;
    _currSecond = initDateTime.second;
    _minuteDivider = widget.minuteDivider ?? _defaultMinuteDivider;

    // limit the range of year
    _yearRange = _calcYearRange();
    _currYear = min(max(_minTime.year, _currYear), _maxTime.year);
    // limit the range of month
    _monthRange = _calcMonthRange();
    _currMonth = min(max(_monthRange.first, _currMonth), _monthRange.last);
    // limit the range of date
    _dayRange = _calcDayRange();
//    int currDate = initTime.difference(_baselineDate).inDays;
    _currDay = min(max(_dayRange.first, _currDay), _dayRange.last);
    // limit the range of hour
    _hourRange = _calcHourRange();
    _currHour = min(max(_hourRange.first, _currHour), _hourRange.last);
    // limit the range of minute
    _minuteRange = _calcMinuteRange();
    _currMinute = min(max(_minuteRange.first, _currMinute), _minuteRange.last);
    _currMinute -= _currMinute % _minuteDivider!;

    // limit the range of second
    _secondRange = _calcSecondRange();
    _currSecond = min(max(_secondRange.first, _currSecond), _secondRange.last);

    // create scroll controller
    _yearScrollCtrl =
        FixedExtentScrollController(initialItem: _currYear - _yearRange.first);
    _monthScrollCtrl = FixedExtentScrollController(
        initialItem: _currMonth - _monthRange.first);
    _dayScrollCtrl =
        FixedExtentScrollController(initialItem: _currDay - _dayRange.first);
    _hourScrollCtrl =
        FixedExtentScrollController(initialItem: _currHour - _hourRange.first);
    _minuteScrollCtrl = FixedExtentScrollController(
        initialItem: (_currMinute - _minuteRange.first) ~/ _minuteDivider!);
    _secondScrollCtrl = FixedExtentScrollController(
        initialItem: _currSecond - _secondRange.first);

    _scrollCtrlMap = {
      'y': _yearScrollCtrl,
      'M': _monthScrollCtrl,
      'd': _dayScrollCtrl,
      'H': _hourScrollCtrl,
      'm': _minuteScrollCtrl,
      's': _secondScrollCtrl
    };
    _valueRangeMap = {
      'y': _yearRange,
      'M': _monthRange,
      'd': _dayRange,
      'H': _hourRange,
      'm': _minuteRange,
      's': _secondRange
    };
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Material(
          color: Colors.transparent, child: _renderPickerView(context)),
    );
  }

  /// render time picker widgets
  Widget _renderPickerView(BuildContext context) {
    Widget titleWidget = LwqPickerTitle(
      onCancel: () => _onPressedCancel(),
      onConfirm: () => _onPressedConfirm(),
    );
    Widget pickerWidget = _renderDatePickerWidget();
    return Column(children: <Widget>[titleWidget, pickerWidget]);
  }

  /// pressed cancel widget
  void _onPressedCancel() {
    if (widget.onCancel != null) {
      widget.onCancel!();
    }
    Navigator.pop(context);
  }

  /// pressed confirm widget
  void _onPressedConfirm() {
    if (widget.onConfirm != null) {
      List<String> formatArr =
          DateTimeFormatter.splitDateFormat(widget.dateFormat);

      /// 如果传入的时间格式不包含 月、天、小时、分钟、秒。则相对应的时间置为 1,1,0,0,0；
      DateTime dateTime = DateTime(
        _currYear,
        (formatArr.where((format) => format.contains('M')).toList()).isNotEmpty
            ? _currMonth
            : 1,
        (formatArr.where((format) => format.contains('d')).toList()).isNotEmpty
            ? _currDay
            : 1,
        (formatArr.where((format) => format.contains('H')).toList()).isNotEmpty
            ? _currHour
            : 0,
        (formatArr.where((format) => format.contains('m')).toList()).isNotEmpty
            ? _currMinute
            : 0,
        (formatArr.where((format) => format.contains('s')).toList()).isNotEmpty
            ? _currSecond
            : 0,
      );
      widget.onConfirm!(dateTime, _calcSelectIndexList());
    }
    Navigator.pop(context);
  }

  /// notify selected datetime changed
  void _onSelectedChange() {
    if (widget.onChange != null) {
      DateTime dateTime = DateTime(
          _currYear, _currMonth, _currDay, _currHour, _currMinute, _currSecond);
      widget.onChange!(dateTime, _calcSelectIndexList());
    }
  }

  /// find scroll controller by specified format
  FixedExtentScrollController? _findScrollCtrl(String format) {
    FixedExtentScrollController? scrollCtrl;
    _scrollCtrlMap.forEach((key, value) {
      if (format.contains(key)) {
        scrollCtrl = value;
      }
    });
    return scrollCtrl;
  }

  /// find item value range by specified format
  List<int>? _findPickerItemRange(String format) {
    List<int>? valueRange;
    _valueRangeMap.forEach((key, value) {
      if (format.contains(key)) {
        valueRange = value;
      }
    });
    return valueRange;
  }

  /// render the picker widget of year、month and day
  Widget _renderDatePickerWidget() {
    List<Widget> pickers = [];
    List<String> formatArr =
        DateTimeFormatter.splitDateFormat(widget.dateFormat);

    // render time picker column
    for (var format in formatArr) {
      List<int>? valueRange = _findPickerItemRange(format);

      Widget pickerColumn = _renderDatePickerColumnComponent(
        scrollCtrl: _findScrollCtrl(format),
        valueRange: valueRange,
        format: format,
        flex: 1,
        valueChanged: (value) {
          if (format.contains('y')) {
            _changeYearSelection(value);
          } else if (format.contains('M')) {
            _changeMonthSelection(value);
          } else if (format.contains('d')) {
            _changeDaySelection(value);
          } else if (format.contains('H')) {
            _changeHourSelection(value);
          } else if (format.contains('m')) {
            _changeMinuteSelection(value);
          } else if (format.contains('s')) {
            _changeSecondSelection(value);
          }
        },
      );
      pickers.add(pickerColumn);
    }
    return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, children: pickers);
  }

  Widget _renderDatePickerColumnComponent(
      {required FixedExtentScrollController? scrollCtrl,
      required List<int>? valueRange,
      required String format,
      required ValueChanged<int> valueChanged,
      required int flex,
      IndexedWidgetBuilder? itemBuilder}) {
    Widget columnWidget = Container(
      width: double.infinity,
      height: pickerContentHeight,
      decoration: const BoxDecoration(color: Colors.white),
      child: LwqPicker.builder(
        backgroundColor: Colors.white,
        lineColor: dividerColor,
        scrollController: scrollCtrl,
        itemExtent: pickerItemHeight,
        onSelectedItemChanged: valueChanged,
        childCount: format.contains('m')
            ? _calculateMinuteChildCount(valueRange, _minuteDivider)
            : valueRange!.last - valueRange.first + 1,
        itemBuilder: itemBuilder ??
            (context, index) {
              int value = valueRange!.first + index;

              if (format.contains('m')) {
                value = valueRange.first + _minuteDivider! * index;
              }
              return _renderDatePickerItemComponent(
                  getColumnType(format), index, value, format);
            },
      ),
    );
    return Expanded(
      flex: flex,
      child: columnWidget,
    );
  }

  _calculateMinuteChildCount(List<int>? valueRange, int? divider) {
    if (divider == 0 || divider == 1) {
      debugPrint("Cant devide by 0");
      return (valueRange!.last - valueRange.first + 1);
    }

    return ((valueRange!.last - valueRange.first) ~/ divider!) + 1;
  }

  // ignore: missing_return
  ColumnType? getColumnType(String format) {
    if (format.contains('y')) {
      return ColumnType.year;
    } else if (format.contains('M')) {
      return ColumnType.month;
    } else if (format.contains('d')) {
      return ColumnType.day;
    } else if (format.contains('H')) {
      return ColumnType.hour;
    } else if (format.contains('m')) {
      return ColumnType.minute;
    } else if (format.contains('s')) {
      return ColumnType.second;
    }
    return null;
  }

  /// change the selection of year picker
  void _changeYearSelection(int index) {
    int year = _yearRange.first + index;
    if (_currYear != year) {
      _currYear = year;
      _changeDateRange();
      _onSelectedChange();
      _changeTimeRange();
    }
  }

  /// change the selection of month picker
  void _changeMonthSelection(int index) {
    int month = _monthRange.first + index;
    if (_currMonth != month) {
      _currMonth = month;
      _changeDateRange();
      _onSelectedChange();
      _changeTimeRange();
    }
  }

  /// change the selection of day picker
  void _changeDaySelection(int index) {
    int dayOfMonth = _dayRange.first + index;
    if (_currDay != dayOfMonth) {
      _currDay = dayOfMonth;
      _changeDateRange();
      _onSelectedChange();
      _changeTimeRange();
    }
  }

  /// change range of month and day
  void _changeDateRange() {
    if (_isChangeTimeRange) {
      return;
    }
    _isChangeTimeRange = true;

    List<int> monthRange = _calcMonthRange();
    bool monthRangeChanged = _monthRange.first != monthRange.first ||
        _monthRange.last != monthRange.last;
    if (monthRangeChanged) {
      // selected year changed
      _currMonth = max(min(_currMonth, monthRange.last), monthRange.first);
    }

    List<int> dayRange = _calcDayRange();
    bool dayRangeChanged =
        _dayRange.first != dayRange.first || _dayRange.last != dayRange.last;
    if (dayRangeChanged) {
      // day range changed, need limit the value of selected day
      _currDay = max(min(_currDay, dayRange.last), dayRange.first);
    }

    setState(() {
      _monthRange = monthRange;
      _dayRange = dayRange;

      _valueRangeMap['M'] = monthRange;
      _valueRangeMap['d'] = dayRange;
    });

    if (monthRangeChanged) {
      // CupertinoPicker refresh data not working (https://github.com/flutter/flutter/issues/22999)
      _monthScrollCtrl.jumpToItem(monthRange.last - monthRange.first);
      if (_currMonth < monthRange.last) {
        _monthScrollCtrl.jumpToItem(_currMonth - monthRange.first);
      }
    }

    if (dayRangeChanged) {
      // CupertinoPicker refresh data not working (https://github.com/flutter/flutter/issues/22999)
      _dayScrollCtrl.jumpToItem(dayRange.last - dayRange.first);
      if (_currDay < dayRange.last) {
        _dayScrollCtrl.jumpToItem(_currDay - dayRange.first);
      }
    }

    _isChangeTimeRange = false;
  }

  /// render hour、minute、second picker item
  Widget _renderDatePickerItemComponent(
      ColumnType? columnType, int index, int value, String format) {
    if ((ColumnType.year == columnType && index == _calcSelectIndexList()[0]) ||
        (ColumnType.month == columnType &&
            index == _calcSelectIndexList()[1]) ||
        (ColumnType.day == columnType && index == _calcSelectIndexList()[2]) ||
        (ColumnType.hour == columnType && index == _calcSelectIndexList()[3]) ||
        (ColumnType.minute == columnType &&
            index == _calcSelectIndexList()[4]) ||
        (ColumnType.second == columnType &&
            index == _calcSelectIndexList()[5])) {}

    return Container(
      height: pickerItemHeight,
      alignment: Alignment.center,
      child: Text(DateTimeFormatter.formatDateTime(value, format),
          style: textStyle),
    );
  }

//  /// change the selection of day picker
//  void _changeDaySelection(int days) {
//    int value = _dayRange.first + days;
//    if (_currDay != value) {
//      _currDay = value;
//      _changeTimeRange();
//      _onSelectedChange();
//    }
//  }

  /// change the selection of hour picker
  void _changeHourSelection(int index) {
    int value = _hourRange.first + index;
    if (_currHour != value) {
      _currHour = value;
      _changeTimeRange();
      _onSelectedChange();
    }
  }

  /// change the selection of month picker
  void _changeMinuteSelection(int index) {
    int value = _minuteRange.first + index * _minuteDivider!;
    _currMinute = value;
    _changeTimeRange();
    _onSelectedChange();
  }

  /// change the selection of second picker
  void _changeSecondSelection(int index) {
    int value = _secondRange.first + index;
    _currSecond = value;
    _changeTimeRange();
    _onSelectedChange();
  }

  /// change range of minute and second
  void _changeTimeRange() {
    if (_isChangeTimeRange) {
      return;
    }
    _isChangeTimeRange = true;

    List<int> hourRange = _calcHourRange();
    bool hourRangeChanged = _hourRange.first != hourRange.first ||
        _hourRange.last != hourRange.last;
    if (hourRangeChanged) {
      // selected day changed
      _currHour = max(min(_currHour, hourRange.last), hourRange.first);
    }

    List<int> minuteRange = _calcMinuteRange();
    bool minuteRangeChanged = _minuteRange.first != minuteRange.first ||
        _minuteRange.last != minuteRange.last;
    if (minuteRangeChanged) {
      // selected hour changed
      _currMinute = max(min(_currMinute, minuteRange.last), minuteRange.first);
    }

    List<int> secondRange = _calcSecondRange();
    bool secondRangeChanged = _secondRange.first != secondRange.first ||
        _secondRange.last != secondRange.last;
    if (secondRangeChanged) {
      // second range changed, need limit the value of selected second
      _currSecond = max(min(_currSecond, secondRange.last), secondRange.first);
    }

    setState(() {
      _hourRange = hourRange;
      _minuteRange = minuteRange;
      _secondRange = secondRange;

      _valueRangeMap['H'] = hourRange;
      _valueRangeMap['m'] = minuteRange;
      _valueRangeMap['s'] = secondRange;
    });

    if (hourRangeChanged) {
      // CupertinoPicker refresh data not working (https://github.com/flutter/flutter/issues/22999)
      _hourScrollCtrl.jumpToItem(hourRange.last - hourRange.first);
      if (_currHour < hourRange.last) {
        _hourScrollCtrl.jumpToItem(_currHour - hourRange.first);
      }
    }

    if (minuteRangeChanged) {
      // CupertinoPicker refresh data not working (https://github.com/flutter/flutter/issues/22999)
      _minuteScrollCtrl.jumpToItem(
          (minuteRange.last - minuteRange.first) ~/ _minuteDivider!);
      if (_currMinute < minuteRange.last) {
        _minuteScrollCtrl
            .jumpToItem((_currMinute - minuteRange.first) ~/ _minuteDivider!);
      }
    }

    if (secondRangeChanged) {
      // CupertinoPicker refresh data not working (https://github.com/flutter/flutter/issues/22999)
      _secondScrollCtrl.jumpToItem(secondRange.last - secondRange.first);
      if (_currSecond < secondRange.last) {
        _secondScrollCtrl.jumpToItem(_currSecond - secondRange.first);
      }
    }

    _isChangeTimeRange = false;
  }

  /// calculate selected index list
  List<int> _calcSelectIndexList() {
    int yearIndex = _currYear - _yearRange.first;
    int monthIndex = _currMonth - _monthRange.first;
    int dayIndex = _currDay - _dayRange.first;
    int hourIndex = _currHour - _hourRange.first;
    int minuteIndex = (_currMinute - _minuteRange.first) ~/ _minuteDivider!;
    int secondIndex = _currSecond - _secondRange.first;
    return [
      yearIndex,
      monthIndex,
      dayIndex,
      hourIndex,
      minuteIndex,
      secondIndex
    ];
  }

  /// calculate the range of year
  List<int> _calcYearRange() {
    return [_minTime.year, _maxTime.year];
  }

  /// calculate the range of month
  List<int> _calcMonthRange() {
    int minMonth = 1, maxMonth = 12;
    int minYear = _minTime.year;
    int maxYear = _maxTime.year;
    if (minYear == _currYear) {
      // selected minimum year, limit month range
      minMonth = _minTime.month;
    }
    if (maxYear == _currYear) {
      // selected maximum year, limit month range
      maxMonth = _maxTime.month;
    }
    return [minMonth, maxMonth];
  }

  /// whether or not is leap year
  bool isLeapYear(int year) {
    return (year % 4 == 0 && year % 100 != 0) || year % 400 == 0;
  }

  /// calculate the count of day in current month
  int _calcDayCountOfMonth() {
    if (_currMonth == 2) {
      return isLeapYear(_currYear) ? 29 : 28;
    } else if (solarMonthsOf31Days.contains(_currMonth)) {
      return 31;
    }
    return 30;
  }

  /// calculate the range of day
  List<int> _calcDayRange({currMonth}) {
    int minDay = 1, maxDay = _calcDayCountOfMonth();
    int minYear = _minTime.year;
    int maxYear = _maxTime.year;
    int minMonth = _minTime.month;
    int maxMonth = _maxTime.month;
    currMonth ??= _currMonth;
    if (minYear == _currYear && minMonth == currMonth) {
      // selected minimum year and month, limit day range
      minDay = _minTime.day;
    }
    if (maxYear == _currYear && maxMonth == currMonth) {
      // selected maximum year and month, limit day range
      maxDay = _maxTime.day;
    }
    return [minDay, maxDay];
  }

  /// calculate the range of hour
  List<int> _calcHourRange() {
    int minHour = 0, maxHour = 23;
    if (_currYear == _minTime.year &&
        _currMonth == _minTime.month &&
        _currDay == _minTime.day) {
      minHour = _minTime.hour;
    }

    int modValue = _minTime.minute % _minuteDivider!;
    int minMinute = modValue == 0
        ? _minTime.minute
        : (_minTime.minute - modValue + _minuteDivider!);
    if (minMinute == 60) {
      minHour = minHour + 1 > _maxTime.hour ? _maxTime.hour : minHour + 1;
    }

    if (_currYear == _maxTime.year &&
        _currMonth == _maxTime.month &&
        _currDay == _maxTime.day) {
      maxHour = _maxTime.hour;
    }
    return [minHour, maxHour];
  }

  /// calculate the range of minute
  List<int> _calcMinuteRange({currHour}) {
    int minMinute = 0, maxMinute = 59;
    currHour ??= _currHour;

    if (_currYear == _minTime.year &&
        _currMonth == _minTime.month &&
        _currDay == _minTime.day &&
        _currHour == _minTime.hour) {
      // selected minimum day、hour, limit minute range
      int modValue = _minTime.minute % _minuteDivider!;
      minMinute = modValue == 0
          ? _minTime.minute
          : (_minTime.minute - modValue + _minuteDivider!);
      if (minMinute == 60) {
        minMinute = 0;
        currHour = currHour + 1 > _maxTime.hour ? _maxTime.hour : currHour + 1;
      }
    }
    if (_currYear == _maxTime.year &&
        _currMonth == _maxTime.month &&
        _currDay == _maxTime.day &&
        _currHour == _maxTime.hour) {
      // selected maximum day、hour, limit minute range
      maxMinute = _maxTime.minute - _maxTime.minute % _minuteDivider!;
    }
    return [minMinute, maxMinute];
  }

  /// calculate the range of second
  List<int> _calcSecondRange() {
    int minSecond = 0, maxSecond = 59;
    return [minSecond, maxSecond];
  }
}

class LwqTools {
  const LwqTools._();

  /// 从16进制数字字符串，生成Color，例如EDF0F3
  static Color colorFromHexString(String? s) {
    if (s == null || s.length != 6 || int.tryParse(s, radix: 16) == null) {
      return Colors.black;
    }
    return Color(int.parse(s, radix: 16) + 0xFF000000);
  }

  /// 根据 TextStyle 计算 text 宽度。
  static Size textSize(String text, TextStyle style) {
    if (isEmpty(text)) return const Size(0, 0);
    final TextPainter textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout(minWidth: 0, maxWidth: double.infinity);
    return textPainter.size;
  }

  /// 判空
  static bool isEmpty(Object? obj) {
    if (obj is String) {
      return obj.isEmpty;
    }
    if (obj is Iterable) {
      return obj.isEmpty;
    }
    if (obj is Map) {
      return obj.isEmpty;
    }
    return obj == null;
  }
}

class LwqIntl {
  /// 内置支持的语言和资源
  final Map<String, LwqBaseResource> _defaultResourceMap = {
    'en': LwqResourceEn(),
    'zh': LwqResourceZh()
  };

  /// 缓存当前语言对应的资源，用于无 context 的情况
  static LwqIntl? _current;
  static LwqBaseResource get currentResource {
    assert(
        _current != null,
        'No instance of LwqIntl was loaded. \n'
        'Try to initialize the LwqLocalizationDelegate before accessing LwqIntl.currentResource.');

    /// 若应用未做本地化，则默认使用 zh-CN 资源
    _current ??= LwqIntl(LwqResourceZh.locale);
    return _current!.localizedResource;
  }

  final Locale locale;

  LwqIntl(this.locale);

  /// 获取当前语言下对应的资源，若为 null 则返回 [LwqResourceZh]
  LwqBaseResource get localizedResource {
    // 支持动态资源文件
    LwqBaseResource? resource =
        _LwqIntlHelper.findIntlResourceOfType<LwqBaseResource>(locale);
    if (resource != null) return resource;
    // 常规的多语言资源加载
    return _defaultResourceMap[locale.languageCode] ??
        _defaultResourceMap['zh']!;
  }

  /// 获取[LwqIntl]实例
  static LwqIntl of(BuildContext context) {
    return Localizations.of(context, LwqIntl) ?? LwqIntl(LwqResourceZh.locale);
  }

  /// 获取当前语言下资源
  static LwqBaseResource i10n(BuildContext context) {
    return LwqIntl.of(context).localizedResource;
  }

  /// 应用加载本地化资源
  static Future<LwqIntl> _load(Locale locale) {
    _current = LwqIntl(locale);
    return SynchronousFuture<LwqIntl>(_current!);
  }

  /// 支持非内置的本地化能力
  static void add(Locale locale, LwqBaseResource resource) {
    _LwqIntlHelper.add(locale, resource);
  }

  /// 支持非内置的本地化能力
  static void addAll(Locale locale, List<LwqBaseResource> resources) {
    _LwqIntlHelper.addAll(locale, resources);
  }
}

///
/// 组件多语言适配代理
///
class LwqLocalizationDelegate extends LocalizationsDelegate<LwqIntl> {
  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<LwqIntl> load(Locale locale) {
    debugPrint(
        '$runtimeType load: locale = $locale, ${locale.countryCode}, ${locale.languageCode}');
    return LwqIntl._load(locale);
  }

  @override
  bool shouldReload(LocalizationsDelegate<LwqIntl> old) => false;

  /// 需在app入口注册
  static LwqLocalizationDelegate delegate = LwqLocalizationDelegate();
}

abstract class LwqBaseResource {
  String get ok;

  String get cancel;

  String get confirm;

  String get loading;

  String get pleaseEnter;

  String get enterRangeError;

  String get pleaseChoose;

  String get selectRangeError;

  String get reset;

  String get confirmClearSelectedList;

  String get selectedList;

  String get clear;

  String get shareTo;

  List<String> get appriseLevel;

  String get dateFormatYYYYMM;

  String get dateFormatYYYYMMDD;

  String get dateFormatYYYYMMMMDD;

  String get expand;

  String get collapse;

  String get more;

  String get allPics;

  String get submit;

  String get noTagDataTip;

  List<String> get months;

  List<String> get weekFullName;

  List<String> get weekShortName;

  List<String> get weekMinName;

  String get skip;

  String get known;

  String get next;

  String get inputSearchTip;

  String get done;

  String get noDataTip;

  String get selectAll;

  String get selected;

  String get shareWayTip;

  String get max;

  String get min;

  String get selectCountLimitTip;

  String get to;

  String get recommandCity;

  String get selectCity;

  String get filterConditionCountLimited;

  String get minValue;

  String get maxValue;

  String selectTitle(String selected);

  String get customRange;

  String get startDate;

  String get endDate;

  String get selectStartDate;

  String get selectEndDate;

  List<String> get shareChannels;

  String get fetchErrorAndRetry;

  String get netErrorAndRetryLater;

  String get noSearchData;

  String get clickPageAndRetry;
}

///
/// 中文资源
///
class LwqResourceZh extends LwqBaseResource {
  static Locale locale = const Locale('zh', 'CN');

  @override
  String get ok => '确定';

  @override
  String get cancel => '取消';

  @override
  String get confirm => '确认';

  @override
  String get loading => '加载中...';

  @override
  String get pleaseEnter => '请输入';

  @override
  String get enterRangeError => '您输入的区间有误';

//// TODO
  @override
  String get pleaseChoose => '请选择';

  @override
  String get selectRangeError => '您选择的区间有误';

  @override
  String get reset => '重置';

  @override
  String get confirmClearSelectedList => '确定要清空已选列表吗?';

  @override
  String get selectedList => '已选列表';

  @override
  String get clear => '清空';

  @override
  String get shareTo => '分享至';

  @override
  List<String> get appriseLevel => [
        '不好',
        '还行',
        '满意',
        '很棒',
        '超惊喜',
      ];

  @override
  String get dateFormatYYYYMM => 'yyyy年MM月';

  @override
  String get dateFormatYYYYMMDD => 'yyyy年MM月dd日';

  @override
  String get dateFormatYYYYMMMMDD => 'yyyy年,MMMM月,dd日';

  @override
  String get expand => '展开';

  @override
  String get collapse => '收起';

  @override
  String get more => '更多';

  @override
  String get allPics => '全部图片';

  @override
  String get submit => '提交';

  @override
  String get noTagDataTip => '暂未配置可选标签数据';

  @override
  List<String> get months => [
        '01',
        '02',
        '03',
        '04',
        '05',
        '06',
        '07',
        '08',
        '09',
        '10',
        '11',
        '12',
      ];

  @override
  List<String> get weekFullName => [
        '星期一',
        '星期二',
        '星期三',
        '星期四',
        '星期五',
        '星期六',
        '星期日',
      ];

  @override
  List<String> get weekShortName => [
        '周一',
        '周二',
        '周三',
        '周四',
        '周五',
        '周六',
        '周日',
      ];

  @override
  List<String> get weekMinName => [
        '日',
        '一',
        '二',
        '三',
        '四',
        '五',
        '六',
      ];

  @override
  String get skip => '跳过';

  @override
  String get known => '我知道了';

  @override
  String get next => '下一步';

  @override
  String get inputSearchTip => '请输入搜索内容';

  @override
  String get done => '完成';

  @override
  String get noDataTip => '暂无数据';

  @override
  String get selectAll => '全选';

  @override
  String get selected => '已选';

  @override
  String get shareWayTip => '你可以通过以下方式分享给客户';

  @override
  String get max => '最小';

  @override
  String get min => '最大';

  @override
  String get selectCountLimitTip => '您选择的数量已达上限';

  @override
  String get to => '至';

  @override
  String get recommandCity => '这里是推荐城市';

  @override
  String get selectCity => '城市选择';

  @override
  String get filterConditionCountLimited => '您选择的筛选条件数量已达上限';

  @override
  String get minValue => '最小值';

  @override
  String get maxValue => '最大值';

  @override
  String selectTitle(String selected) => '选择$selected';

  @override
  String get customRange => '自定义区间';

  @override
  String get startDate => '开始日期';

  @override
  String get endDate => '结束日期';

  @override
  String get selectStartDate => '请选择开始时间';

  @override
  String get selectEndDate => '请选择结束时间';

  @override
  List<String> get shareChannels => [
        '微信',
        '朋友圈',
        'QQ',
        'QQ空间',
        '微博',
        '链接',
        '短信',
        '剪贴板',
        '浏览器',
        '相册',
      ];

  @override
  String get fetchErrorAndRetry => '获取数据失败，请重试';

  @override
  String get netErrorAndRetryLater => '网络连接失败，检查后重试';

  @override
  String get noSearchData => '暂无搜索结果';

  @override
  String get clickPageAndRetry => '请点击页面重试';
}

///
/// en resources
///
class LwqResourceEn extends LwqBaseResource {
  static Locale locale = const Locale('en', 'US');

  @override
  String get ok => 'Ok';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get loading => 'Loading ...';

  @override
  String get pleaseEnter => 'Please Enter';

  @override
  String get enterRangeError => 'The range you entered is incorrect';

  @override
  String get pleaseChoose => 'Please choose';

  @override
  String get selectRangeError => 'You have selected the wrong range';

  @override
  String get reset => 'Reset';

  @override
  String get confirmClearSelectedList =>
      'Are you sure you want to clear the selected list?';

  @override
  String get selectedList => 'Selected list';

  @override
  String get clear => 'Clear';

  @override
  String get shareTo => 'Share to';

  @override
  List<String> get appriseLevel => [
        'not good',
        'good',
        'satisfy',
        'great',
        'surprise',
      ];

  @override
  String get dateFormatYYYYMM => 'MM/yyyy';

  @override
  String get dateFormatYYYYMMDD => 'dd/MM/yyyy';

  @override
  String get dateFormatYYYYMMMMDD => 'dd/MMMM/yyyy';

  @override
  String get expand => 'Expand';

  @override
  String get collapse => 'Collapse';

  @override
  String get more => 'More';

  @override
  String get allPics => 'All pictures';

  @override
  String get submit => 'Submit';

  @override
  String get noTagDataTip => 'Tag data not configured yet';

  @override
  List<String> get months => [
        '01',
        '02',
        '03',
        '04',
        '05',
        '06',
        '07',
        '08',
        '09',
        '10',
        '11',
        '12',
      ];

  @override
  List<String> get weekFullName => [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ];

  @override
  List<String> get weekShortName => [
        'Mon',
        'Tue',
        'Wed',
        'Thu',
        'Fri',
        'Sat',
        'Sun',
      ];

  @override
  List<String> get weekMinName => [
        'U',
        'M',
        'T',
        'W',
        'R',
        'F',
        'S',
      ];

  @override
  String get skip => 'Skip';

  @override
  String get known => 'I see';

  @override
  String get next => 'Next';

  @override
  String get inputSearchTip => 'Please enter search content';

  @override
  String get done => 'Done';

  @override
  String get noDataTip => 'No data';

  @override
  String get selectAll => 'Select all';

  @override
  String get selected => 'Selected';

  @override
  String get shareWayTip =>
      'You can share with customers in the following ways';

  @override
  String get max => 'Min';

  @override
  String get min => 'Max';

  @override
  String get selectCountLimitTip =>
      'You have already selected the maximum number';

  @override
  String get to => 'to';

  @override
  String get recommandCity => 'Here are the recommended cities';

  @override
  String get selectCity => 'Select city';

  @override
  String get filterConditionCountLimited =>
      'You have selected the maximum number of filters';

  @override
  String get minValue => 'Min';

  @override
  String get maxValue => 'Max';

  @override
  String selectTitle(String selected) => 'Select $selected';

  @override
  String get customRange => 'Custom range';

  @override
  String get startDate => 'Start date';

  @override
  String get endDate => 'End date';

  @override
  String get selectStartDate => 'Please select a start time';

  @override
  String get selectEndDate => 'Please select a end time';

  @override
  List<String> get shareChannels => [
        'Wechat',
        'Friends',
        'QQ',
        'QQ Zone',
        'Weibo',
        'Link',
        'Message',
        'Clipboard',
        'Browser',
        'Photo Album',
      ];

  @override
  String get fetchErrorAndRetry => 'Fetch data fail, please try again';

  @override
  String get netErrorAndRetryLater =>
      'Network connection failed, check and try again';

  @override
  String get noSearchData => 'No search results';

  @override
  String get clickPageAndRetry => 'Please click the page to try again';
}

///
/// 支持外部动态添加其他语言支的本地化
///
final Map<Locale, Map<Type, dynamic>> _additionalIntls = {};

class _LwqIntlHelper {
  ///
  /// 根据 locale 查找 value 类型为[T]的资源
  ///
  static T? findIntlResourceOfType<T>(Locale locale) {
    Map<Type, dynamic>? res = _additionalIntls[locale];
    if (res != null && res.isNotEmpty) {
      for (var entry in res.entries) {
        if (entry.value is T) {
          return entry.value;
        }
      }
    }
    return null;
  }

  ///
  /// 设置自定义 locale 的资源
  ///
  static void addAll(Locale locale, List<LwqBaseResource> resources) {
    var res = _additionalIntls[locale];
    if (res == null) {
      res = {};
      _additionalIntls[locale] = res;
    }
    for (LwqBaseResource resource in resources) {
      res[resource.runtimeType] = resource;
    }
  }

  ///
  /// 设置自定义 locale 的资源
  ///
  static void add(Locale locale, LwqBaseResource resource) {
    var res = _additionalIntls[locale];
    if (res == null) {
      res = {};
      _additionalIntls[locale] = res;
    }
    res[resource.runtimeType] = resource;
  }
}

class LwqPicker extends StatefulWidget {
  /// Creates a picker from a concrete list of children.
  ///
  /// The [diameterRatio] and [itemExtent] arguments must not be null. The
  /// [itemExtent] must be greater than zero.
  ///
  /// The [backgroundColor] defaults to light gray. It can be set to null to
  /// disable the background painting entirely; this is mildly more efficient
  /// than using [Colors.transparent]. Also, if it has transparency, no gradient
  /// effect will be rendered.
  ///
  /// The [scrollController] argument can be used to specify a custom
  /// [FixedExtentScrollController] for programmatically reading or changing
  /// the current picker index or for selecting an initial index value.
  ///
  /// The [looping] argument decides whether the child list loops and can be
  /// scrolled infinitely.  If set to true, scrolling past the end of the list
  /// will loop the list back to the beginning.  If set to false, the list will
  /// stop scrolling when you reach the end or the beginning.
  LwqPicker({
    super.key,
    this.diameterRatio = kDefaultDiameterRatio,
    this.backgroundColor = kDefaultBackground,
    this.lineColor = kHighlighterBorder,
    this.offAxisFraction = 0.0,
    this.useMagnifier = false,
    this.magnification = 1.0,
    this.scrollController,
    this.squeeze = kSqueeze,
    required this.itemExtent,
    required this.onSelectedItemChanged,
    required List<Widget> children,
    bool looping = false,
  })  : assert(diameterRatio > 0.0,
            RenderListWheelViewport.diameterRatioZeroMessage),
        assert(magnification > 0),
        assert(itemExtent > 0),
        assert(squeeze > 0),
        childDelegate = looping
            ? ListWheelChildLoopingListDelegate(children: children)
            : ListWheelChildListDelegate(children: children);

  /// Creates a picker from an [IndexedWidgetBuilder] callback where the builder
  /// is dynamically invoked during layout.
  ///
  /// A child is lazily created when it starts becoming visible in the viewport.
  /// All of the children provided by the builder are cached and reused, so
  /// normally the builder is only called once for each index (except when
  /// rebuilding - the cache is cleared).
  ///
  /// The [itemBuilder] argument must not be null. The [childCount] argument
  /// reflects the number of children that will be provided by the [itemBuilder].
  /// {@macro flutter.widgets.wheelList.childCount}
  ///
  /// The [itemExtent] argument must be non-null and positive.
  ///
  /// The [backgroundColor] defaults to light gray. It can be set to null to
  /// disable the background painting entirely; this is mildly more efficient
  /// than using [Colors.transparent].
  LwqPicker.builder({
    super.key,
    this.diameterRatio = kDefaultDiameterRatio,
    this.backgroundColor = kDefaultBackground,
    this.lineColor = kHighlighterBorder,
    this.offAxisFraction = 0.0,
    this.useMagnifier = false,
    this.magnification = 1.0,
    this.scrollController,
    this.squeeze = kSqueeze,
    required this.itemExtent,
    required this.onSelectedItemChanged,
    required IndexedWidgetBuilder itemBuilder,
    int? childCount,
  })  : assert(diameterRatio > 0.0,
            RenderListWheelViewport.diameterRatioZeroMessage),
        assert(magnification > 0),
        assert(itemExtent > 0),
        assert(squeeze > 0),
        childDelegate = ListWheelChildBuilderDelegate(
            builder: itemBuilder, childCount: childCount);

  /// Relative ratio between this picker's height and the simulated cylinder's diameter.
  ///
  /// Smaller values creates more pronounced curvatures in the scrollable wheel.
  ///
  /// For more details, see [ListWheelScrollView.diameterRatio].
  ///
  /// Must not be null and defaults to `1.1` to visually mimic iOS.
  final double diameterRatio;

  /// Background color behind the children.
  ///
  /// Defaults to a gray color in the iOS color palette.
  ///
  /// This can be set to null to disable the background painting entirely; this
  /// is mildly more efficient than using [Colors.transparent].
  ///
  /// Any alpha value less 255 (fully opaque) will cause the removal of the
  /// wheel list edge fade gradient from rendering of the widget.
  final Color backgroundColor;

  ///分割线颜色
  final Color? lineColor;

  /// {@macro flutter.rendering.wheelList.offAxisFraction}
  final double offAxisFraction;

  /// {@macro flutter.rendering.wheelList.useMagnifier}
  final bool useMagnifier;

  /// {@macro flutter.rendering.wheelList.magnification}
  final double magnification;

  /// A [FixedExtentScrollController] to read and control the current item.
  ///
  /// If null, an implicit one will be created internally.
  final FixedExtentScrollController? scrollController;

  /// The uniform height of all children.
  ///
  /// All children will be given the [BoxConstraints] to match this exact
  /// height. Must not be null and must be positive.
  final double itemExtent;

  /// {@macro flutter.rendering.wheelList.squeeze}
  ///
  /// Defaults to `1.45` fo visually mimic iOS.
  final double squeeze;

  /// An option callback when the currently centered item changes.
  ///
  /// Value changes when the item closest to the center changes.
  ///
  /// This can be called during scrolls and during ballistic flings. To get the
  /// value only when the scrolling settles, use a [NotificationListener],
  /// listen for [ScrollEndNotification] and read its [FixedExtentMetrics].
  final ValueChanged<int> onSelectedItemChanged;

  /// A delegate that lazily instantiates children.
  final ListWheelChildDelegate childDelegate;

  @override
  State<StatefulWidget> createState() => _CupertinoPickerState();
}

class _CupertinoPickerState extends State<LwqPicker> {
  int? _lastHapticIndex;
  FixedExtentScrollController? _controller;

  @override
  void initState() {
    super.initState();
    if (widget.scrollController == null) {
      _controller = FixedExtentScrollController();
    }
  }

  @override
  void didUpdateWidget(LwqPicker oldWidget) {
    if (widget.scrollController != null && oldWidget.scrollController == null) {
      _controller = null;
    } else if (widget.scrollController == null &&
        oldWidget.scrollController != null) {
      assert(_controller == null);
      _controller = FixedExtentScrollController();
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _handleSelectedItemChanged(int index) {
    // Only the haptic engine hardware on iOS devices would produce the
    // intended effects.
    if (defaultTargetPlatform == TargetPlatform.iOS &&
        index != _lastHapticIndex) {
      _lastHapticIndex = index;
      HapticFeedback.selectionClick();
    }
    widget.onSelectedItemChanged(index);
  }

  /// Makes the fade to [CupertinoPicker.backgroundColor] edge gradients.
  Widget _buildGradientScreen() {
    // Because BlendMode.dstOut doesn't work correctly with BoxDecoration we
    // have to just do a color blend. And a due to the way we are layering
    // the magnifier and the gradient on the background, using a transparent
    // background color makes the picker look odd.
    if (widget.backgroundColor.alpha < 255) return Container();

    final Color widgetBackgroundColor = widget.backgroundColor;
    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: <Color>[
                widgetBackgroundColor,
                widgetBackgroundColor.withAlpha(0xFF),
                widgetBackgroundColor.withAlpha(0xCC),
                widgetBackgroundColor.withAlpha(0),
                widgetBackgroundColor.withAlpha(0),
                widgetBackgroundColor.withAlpha(0xCC),
                widgetBackgroundColor.withAlpha(0xFF),
                widgetBackgroundColor,
              ],
              stops: const <double>[
                0.0,
                0.05,
                0.09,
                0.22,
                0.78,
                0.91,
                0.95,
                1.0,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
    );
  }

  /// Makes the magnifier lens look so that the colors are normal through
  /// the lens and partially grayed out around it.
  Widget _buildMagnifierScreen() {
    final Color foreground = widget.backgroundColor.withAlpha(
        (widget.backgroundColor.alpha * kForegroundScreenOpacityFraction)
            .toInt());

    return IgnorePointer(
      child: Column(
        children: <Widget>[
          Expanded(
            child: Container(
              color: foreground,
            ),
          ),
          Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide.none,
                right: BorderSide.none,
                top: BorderSide(
                    width: 0.5, color: widget.lineColor ?? kHighlighterBorder),
                bottom: BorderSide(
                    width: 0.5, color: widget.lineColor ?? kHighlighterBorder),
              ),
            ),
            constraints: BoxConstraints.expand(
              height: widget.itemExtent * widget.magnification,
            ),
          ),
          Expanded(
            child: Container(
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnderMagnifierScreen() {
    final Color foreground = widget.backgroundColor.withAlpha(
        (widget.backgroundColor.alpha * kForegroundScreenOpacityFraction)
            .toInt());

    return Column(
      children: <Widget>[
        Expanded(child: Container()),
        Container(
          color: foreground,
          constraints: BoxConstraints.expand(
            height: widget.itemExtent * widget.magnification,
          ),
        ),
        Expanded(child: Container()),
      ],
    );
  }

  Widget _addBackgroundToChild(Widget child) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: widget.backgroundColor,
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget result = DefaultTextStyle(
      style: textStyle,
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: _CupertinoPickerSemantics(
              scrollController: widget.scrollController ?? _controller!,
              child: ListWheelScrollView.useDelegate(
                controller: widget.scrollController ?? _controller,
                physics: const FixedExtentScrollPhysics(),
                diameterRatio: widget.diameterRatio,
                perspective: kDefaultPerspective,
                offAxisFraction: widget.offAxisFraction,
                useMagnifier: widget.useMagnifier,
                magnification: widget.magnification,
                itemExtent: widget.itemExtent,
                squeeze: widget.squeeze,
                onSelectedItemChanged: _handleSelectedItemChanged,
                childDelegate: widget.childDelegate,
              ),
            ),
          ),
          _buildGradientScreen(),
          _buildMagnifierScreen(),
        ],
      ),
    );
    // Adds the appropriate opacity under the magnifier if the background
    // color is transparent.
    if (widget.backgroundColor.alpha < 255) {
      result = Stack(
        children: <Widget>[
          _buildUnderMagnifierScreen(),
          _addBackgroundToChild(result),
        ],
      );
    } else {
      result = _addBackgroundToChild(result);
    }
    return result;
  }
}

// Turns the scroll semantics of the ListView into a single adjustable semantics
// node. This is done by removing all of the child semantics of the scroll
// wheel and using the scroll indexes to look up the current, previous, and
// next semantic label. This label is then turned into the value of a new
// adjustable semantic node, with adjustment callbacks wired to move the
// scroll controller.
class _CupertinoPickerSemantics extends SingleChildRenderObjectWidget {
  const _CupertinoPickerSemantics({
    super.child,
    required this.scrollController,
  });

  final FixedExtentScrollController scrollController;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderCupertinoPickerSemantics(
          scrollController, Directionality.of(context));

  @override
  void updateRenderObject(BuildContext context,
      covariant _RenderCupertinoPickerSemantics renderObject) {
    renderObject
      ..textDirection = Directionality.of(context)
      ..controller = scrollController;
  }
}

class _RenderCupertinoPickerSemantics extends RenderProxyBox {
  _RenderCupertinoPickerSemantics(
      FixedExtentScrollController controller, this._textDirection) {
    this.controller = controller;
  }

  FixedExtentScrollController? get controller => _controller;
  FixedExtentScrollController? _controller;

  set controller(FixedExtentScrollController? value) {
    if (value == _controller) return;
    if (_controller != null) {
      _controller!.removeListener(_handleScrollUpdate);
    } else {
      _currentIndex = value!.initialItem;
    }
    value?.addListener(_handleScrollUpdate);
    _controller = value;
  }

  TextDirection get textDirection => _textDirection;
  TextDirection _textDirection;

  set textDirection(TextDirection value) {
    if (textDirection == value) return;
    _textDirection = value;
    markNeedsSemanticsUpdate();
  }

  int _currentIndex = 0;

  void _handleIncrease() {
    controller!.jumpToItem(_currentIndex + 1);
  }

  void _handleDecrease() {
    if (_currentIndex == 0) return;
    controller!.jumpToItem(_currentIndex - 1);
  }

  void _handleScrollUpdate() {
    if (controller!.selectedItem == _currentIndex) return;
    _currentIndex = controller!.selectedItem;
    markNeedsSemanticsUpdate();
  }

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    config.isSemanticBoundary = true;
    config.textDirection = textDirection;
  }

  @override
  void assembleSemanticsNode(SemanticsNode node, SemanticsConfiguration config,
      Iterable<SemanticsNode> children) {
    if (children.isEmpty) {
      return super.assembleSemanticsNode(node, config, children);
    }
    final SemanticsNode scrollable = children.first;
    final Map<int?, SemanticsNode> indexedChildren = <int?, SemanticsNode>{};
    scrollable.visitChildren((SemanticsNode child) {
      assert(child.indexInParent != null);
      indexedChildren[child.indexInParent] = child;
      return true;
    });
    if (indexedChildren[_currentIndex] == null) {
      return node.updateWith(config: config);
    }
    config.value = indexedChildren[_currentIndex]!.label;
    final SemanticsNode? previousChild = indexedChildren[_currentIndex - 1];
    final SemanticsNode? nextChild = indexedChildren[_currentIndex + 1];
    if (nextChild != null) {
      config.increasedValue = nextChild.label;
      config.onIncrease = _handleIncrease;
    }
    if (previousChild != null) {
      config.decreasedValue = previousChild.label;
      config.onDecrease = _handleDecrease;
    }
    node.updateWith(config: config);
  }
}

class LwqPickerTitle extends StatelessWidget {
  final DateVoidCallback onCancel, onConfirm;

  const LwqPickerTitle({
    super.key,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: pickerTitleHeight,
      decoration: const ShapeDecoration(
        color: kDefaultBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(8),
            topRight: Radius.circular(8),
          ),
        ),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            height: pickerTitleHeight - 0.5,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    height: pickerTitleHeight,
                    alignment: Alignment.center,
                    child: _renderCancelWidget(context),
                  ),
                  onTap: () {
                    onCancel();
                  },
                ),
                Text(
                  LwqIntl.of(context).localizedResource.pleaseChoose,
                ),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    height: pickerTitleHeight,
                    alignment: Alignment.center,
                    child: _renderConfirmWidget(context),
                  ),
                  onTap: () {
                    onConfirm();
                  },
                ),
              ],
            ),
          ),
          const Divider(
            color: dividerColor,
            indent: 0.0,
            height: 0.5,
          ),
        ],
      ),
    );
  }

  /// render cancel button widget
  Widget _renderCancelWidget(BuildContext context) {
    return Text(
      LwqIntl.of(context).localizedResource.cancel,
      textAlign: TextAlign.left,
    );
  }

  /// render confirm button widget
  Widget _renderConfirmWidget(BuildContext context) {
    return Text(
      LwqIntl.of(context).localizedResource.done,
      textAlign: TextAlign.right,
    );
  }
}
