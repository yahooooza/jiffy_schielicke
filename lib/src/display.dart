import 'package:intl/intl.dart';

import 'getter.dart';
import 'enums/unit.dart';
import 'locale/locale.dart';
import 'manipulator.dart';
import 'query.dart';
import 'utils/jiffy_exception.dart';
import 'jiffy.dart';

class Display {
  final Getter _getter;
  final Manipulator _manipulator;
  final Query _query;

  Display(this._getter, this._manipulator, this._query);

  String formatToISO8601(DateTime dateTime) => dateTime.toIso8601String();

  String format(DateTime dateTime, String pattern, Locale locale) {
    if (pattern.trim().isEmpty) {
      throw JiffyException('The provided pattern for datetime `$dateTime` '
          'cannot be blank');
    }
    final escapedPattern = _replaceEscapePattern(pattern);
    final localeOrdinal = _getLocaleOrdinal(locale, _getter.date(dateTime));
    final newPattern =
        _replaceLocaleOrdinalDatePattern(escapedPattern, localeOrdinal);
    return DateFormat(newPattern).format(dateTime);
  }

  String fromAsRelativeDateTime(DateTime firstDateTime, DateTime secondDateTime,
      Locale locale, bool withPrefixAndSuffix) {
    final isFirstDateTimeSameOrAfterSecondDateTime = _query.isSameOrAfter(
        firstDateTime, secondDateTime, Unit.microsecond, locale.startOfWeek());

    final relativeDateTime = locale.relativeDateTime();
    String prefix, suffix;

    if (isFirstDateTimeSameOrAfterSecondDateTime) {
      prefix = relativeDateTime.prefixFromNow();
      suffix = relativeDateTime.suffixFromNow();
    } else {
      prefix = relativeDateTime.prefixAgo();
      suffix = relativeDateTime.suffixAgo();
    }

    final seconds =
        diff(firstDateTime, secondDateTime, Unit.second, false).abs();
    final minutes =
        diff(firstDateTime, secondDateTime, Unit.minute, false).abs();
    final hours = diff(firstDateTime, secondDateTime, Unit.hour, false).abs();
    final days = diff(firstDateTime, secondDateTime, Unit.day, false).abs();
    final months = diff(firstDateTime, secondDateTime, Unit.month, false).abs();
    final years = diff(firstDateTime, secondDateTime, Unit.year, false).abs();

    String result;

    if (seconds < 45) {
      result = relativeDateTime.lessThanOneMinute(seconds.round());
    } else if (seconds < 90) {
      result = relativeDateTime.aboutAMinute(minutes.round());
    } else if (minutes < 45) {
      result = relativeDateTime.minutes(minutes.round());
    } else if (minutes < 90) {
      result = relativeDateTime.aboutAnHour(minutes.round());
    } else if (hours < 24) {
      result = relativeDateTime.hours(hours.round());
    } else if (hours < 48) {
      result = relativeDateTime.aDay(hours.round());
    } else if (days < 30) {
      result = relativeDateTime.days(days.round());
    } else if (days < 60) {
      result = relativeDateTime.aboutAMonth(days.round());
    } else if (days < 365) {
      result = relativeDateTime.months(months.round());
    } else if (years < 2) {
      result = relativeDateTime.aboutAYear(months.round());
    } else {
      result = relativeDateTime.years(years.round());
    }

    if (withPrefixAndSuffix) {
      return [prefix, result, suffix]
          .where((str) => str.isNotEmpty)
          .join(relativeDateTime.wordSeparator());
    }

    return result;
  }

  String toAsRelativeDateTime(DateTime firstDateTime, DateTime secondDateTime,
      Locale locale, bool withPrefixAndSuffix) {
    return fromAsRelativeDateTime(
        secondDateTime, firstDateTime, locale, withPrefixAndSuffix);
  }

  num diff(DateTime firstDateTime, DateTime secondDateTime, Unit unit,
      bool asFloat) {
    final firstDateTimeMicrosecondsSinceEpoch =
        _getter.microsecondsSinceEpoch(firstDateTime);
    final secondDateTimeMicrosecondsSinceEpoch =
        _getter.microsecondsSinceEpoch(secondDateTime);
    final diffMicrosecondsSinceEpoch = firstDateTimeMicrosecondsSinceEpoch -
        secondDateTimeMicrosecondsSinceEpoch;

    num diff;

    switch (unit) {
      case Unit.microsecond:
        diff = diffMicrosecondsSinceEpoch;
        break;
      case Unit.millisecond:
        diff = diffMicrosecondsSinceEpoch / Duration.microsecondsPerMillisecond;
        break;
      case Unit.second:
        diff = diffMicrosecondsSinceEpoch / Duration.microsecondsPerSecond;
        break;
      case Unit.minute:
        diff = diffMicrosecondsSinceEpoch / Duration.microsecondsPerMinute;
        break;
      case Unit.hour:
        diff = diffMicrosecondsSinceEpoch / Duration.microsecondsPerHour;
        break;
      case Unit.day:
        diff = diffMicrosecondsSinceEpoch / Duration.microsecondsPerDay;
        break;
      case Unit.week:
        diff = (diffMicrosecondsSinceEpoch / Duration.microsecondsPerDay) / 7;
        break;
      case Unit.kwWeek:
        Jiffy first = Jiffy.parseFromDateTime(firstDateTime);
        Jiffy second = Jiffy.parseFromDateTime(secondDateTime);
        if (firstDateTime.year == secondDateTime.year) {
          return (first.calendarWeek - second.calendarWeek).abs();
        } else {
          if (first.isAfter(second)) {
            Jiffy temp = first;
            first = second;
            second = temp;
          }
          int remainingFirstYear =
              (first.endOf(Unit.year).calendarWeek - first.calendarWeek).abs() -
                  1;
          int betweenYears = 0;
          for (int year = first.year + 1; year < second.year; year++) {
            betweenYears += Jiffy.parseFromDateTime(DateTime(year))
                .endOf(Unit.year)
                .calendarWeek;
          }
          int leadingLastYear =
              (second.calendarWeek - second.startOf(Unit.year).calendarWeek)
                      .abs() -
                  1;
          return remainingFirstYear + betweenYears + leadingLastYear;
        }
      case Unit.month:
        diff = (firstDateTime.difference(secondDateTime).inDays / 30);
        break;
      case Unit.year:
        diff = firstDateTime.difference(secondDateTime).inDays / 30 / 12;
        break;
    }

    return asFloat ? _asFloor(diff) : diff;
  }

  String _getLocaleOrdinal(Locale locale, int date) {
    final ordinals = locale.ordinals();
    var suffix = ordinals.last;
    final digit = date % 10;
    if ((digit > 0 && digit < 4) && (date < 11 || date > 13)) {
      suffix = ordinals[digit - 1];
    }
    return suffix;
  }

  String _replaceEscapePattern(String input) {
    return input
        .replaceAll('\'', '\'\'')
        .replaceAll('[', '\'')
        .replaceAll(']', '\'');
  }

  String _replaceLocaleOrdinalDatePattern(String input, String localeOrdinal) {
    var matches = _matchesOrdinalDatePattern(input);
    var pattern = input;

    while (matches.isNotEmpty) {
      final match = matches.first;
      pattern = pattern.replaceRange(match.start, match.end,
          'd${localeOrdinal.isNotEmpty ? "'$localeOrdinal'" : ''}');
      matches = _matchesOrdinalDatePattern(pattern);
    }
    return pattern;
  }

  List<Match> _matchesOrdinalDatePattern(String input) {
    return RegExp(''''[^']*'|(do)''')
        .allMatches(input)
        .where((match) => match.group(1) == 'do')
        .toList();
  }
  /* from original , not needed anymore
  ToDo proof to delete
  num _monthDiff(DateTime firstDateTime, DateTime secondDateTime) {
    if (_getter.date(firstDateTime) < _getter.date(secondDateTime)) {
      return -(_monthDiff(secondDateTime, firstDateTime));
    }

    final monthDiff =
        ((_getter.year(secondDateTime) - _getter.year(firstDateTime)) * 12) +
            (_getter.month(secondDateTime) - _getter.month(firstDateTime));

    final thirdDateTime = _addMonths(firstDateTime, monthDiff);
    final thirdDateTimeMicrosecondsSinceEpoch =
        _getMicrosecondsSinceEpoch(thirdDateTime);

    final diffMicrosecondsSinceEpoch =
        _getMicrosecondsSinceEpoch(secondDateTime) -
            thirdDateTimeMicrosecondsSinceEpoch;

    double offset;

    if (diffMicrosecondsSinceEpoch < 0) {
      final fifthDateTime = _addMonths(firstDateTime, monthDiff - 1);
      offset = diffMicrosecondsSinceEpoch /
          (thirdDateTimeMicrosecondsSinceEpoch -
              _getMicrosecondsSinceEpoch(fifthDateTime));
    } else {
      final fifthDateTime = _addMonths(firstDateTime, monthDiff + 1);
      offset = diffMicrosecondsSinceEpoch /
          (_getMicrosecondsSinceEpoch(fifthDateTime) -
              thirdDateTimeMicrosecondsSinceEpoch);
    }

    return -(monthDiff + offset);
  }
 */

  /* from original, not needed anymore
  ToDo proof to delete

  DateTime _addMonths(DateTime dateTime, int months) {
    return _manipulator.add(dateTime, 0, 0, 0, 0, 0, 0, 0, months, 0);
  }


  int _getMicrosecondsSinceEpoch(DateTime dateTime) {
    return _getter.microsecondsSinceEpoch(dateTime);
  }

   */

  int _asFloor(num number) => number.round();

  int _numOfWeeks(int year) {
    Jiffy dec28 = Jiffy.parseFromDateTime(DateTime(year, 12, 28));
    int dayOfDec28 = dec28.dayOfYear;
    return ((dayOfDec28 - dec28.dayOfWeek + 10) / 7).floor();
  }

  int calendarWeek(DateTime dateTime) {
    Jiffy date = Jiffy.parseFromDateTime(dateTime);
    int woy = ((date.dayOfYear - date.dayOfWeek + 10) / 7).floor();
    if (woy < 1) {
      woy = _numOfWeeks(date.year - 1);
    } else if (woy > _numOfWeeks(date.year)) {
      woy = 1;
    }
    return woy;
  }
}
