import 'enums/start_of_week.dart';
import 'enums/unit.dart';
import 'getter.dart';
import 'manipulator.dart';

class Query {
  final Getter _getter;
  final Manipulator _manipulator;

  Query(this._getter, this._manipulator);

  bool isBefore(DateTime firstDateTime, DateTime secondDateTime, Unit unit,
      StartOfWeek startOfWeek) {
    if (unit == Unit.microsecond) {
      return _getter.microsecondsSinceEpoch(firstDateTime) <
          _getter.microsecondsSinceEpoch(secondDateTime);
    }
    return _manipulator
        .startOf(firstDateTime, unit, startOfWeek)
        .isBefore(_manipulator.startOf(secondDateTime, unit, startOfWeek));
  }

  bool isAfter(DateTime firstDateTime, DateTime secondDateTime, Unit unit,
      StartOfWeek startOfWeek) {
    if (unit == Unit.microsecond) {
      return _getter.microsecondsSinceEpoch(firstDateTime) >
          _getter.microsecondsSinceEpoch(secondDateTime);
    }
    return _manipulator
        .startOf(firstDateTime, unit, startOfWeek)
        .isAfter(_manipulator.startOf(secondDateTime, unit, startOfWeek));
  }

  bool isSame(DateTime firstDateTime, DateTime secondDateTime, Unit unit,
      StartOfWeek startOfWeek) {
    if (unit == Unit.microsecond) {
      return _getter.microsecondsSinceEpoch(firstDateTime) ==
          _getter.microsecondsSinceEpoch(secondDateTime);
    }
    return _manipulator
        .startOf(secondDateTime, unit, startOfWeek)
        .isAtSameMomentAs(
            _manipulator.startOf(firstDateTime, unit, startOfWeek));
  }

  bool isSameOrBefore(DateTime firstDateTime, DateTime secondDateTime,
      Unit unit, StartOfWeek startOfWeek) {
    return isSame(firstDateTime, secondDateTime, unit, startOfWeek) ||
        isBefore(firstDateTime, secondDateTime, unit, startOfWeek);
  }

  bool isSameOrAfter(DateTime firstDateTime, DateTime secondDateTime, Unit unit,
      StartOfWeek startOfWeek) {
    return isSame(firstDateTime, secondDateTime, unit, startOfWeek) ||
        isAfter(firstDateTime, secondDateTime, unit, startOfWeek);
  }

  bool isBetween(DateTime firstDateTime, DateTime secondDateTime,
      DateTime thirdDateTime, Unit unit, StartOfWeek startOfWeek) {
    return isAfter(firstDateTime, secondDateTime, unit, startOfWeek) &&
        isBefore(firstDateTime, thirdDateTime, unit, startOfWeek);
  }

  static bool isUtc(DateTime dateTime) => dateTime.isUtc;

  static bool isLeapYear(int year) {
    return (year % 4 == 0) && ((year % 100 != 0) || (year % 400 == 0));
  }
}
