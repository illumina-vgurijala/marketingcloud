/**
 * # com.servicemax.client.lib.datetimeutils #
 * Datetime utils core library, relies heavily on Moment.js.
 * Rewrite of the old datetimeutils, restructured and documented.
 *
 * @singleton
 * @author Maxfield Gurela
 * @copyright 2015 ServiceMax, Inc.
 */
(function () {

  var datetimeutil = SVMX.Package('com.servicemax.client.lib.datetimeutils');

    /**
     * @class           com.servicemax.client.lib.datetimeutils.DatetimeUtil
     * @extends         com.servicemax.client.lib.api.Object
     * @description
     * All datetime functionality should go through this class at some point, to keep all
     * date and time manipulations consistent. This class mostly relies on Moment.js
     */
  datetimeutil.Class('DatetimeUtil', com.servicemax.client.lib.api.Object, {
    __constructor: function () {}
  }, {
    __locale: moment.locale('en-US'), // Can be changed based on locale later
    _timeZone: moment().utcOffset(),
    _timeZoneStr: '',

        /**
         * Swap the keys and values in a simple string:string object
         *
         * @param  {Object}   obj   Simple string:string object
         *
         * @return Object with swapped keys and values
         */
    _swap: function (obj) {
      var ret = {};
      for(var key in obj){
        ret[obj[key]] = key;
      }
      return ret;
    },

        /**
         * Set the DatetimeUtil default timezone
         *
         * @param (String) timezone   Timezone string in IANA (Olson) format (ex America/Los_Angeles)
         */
    setTimezone: function(timezone) {
      if (!timezone) return console.warn('Something tried to set TZ to empty string!');
      moment.tz.setDefault(timezone);
      datetimeutil.DatetimeUtil._timeZoneStr = timezone;
    },

        /**
         * Set the DatetimeUtil default timezone offset.
         *
         * @param (String)  timezoneOffset  The value of the timezone offset, ex: +07:00
         */
    setTimezoneOffset: function (timezoneOffset) {
      datetimeutil.DatetimeUtil._timeZone = datetimeutil.DatetimeUtil.parseOffsetString(timezoneOffset);
    },

        /**
         * Set the DatetimeUtil default date format. Builds a settings object from the current
         * Momentjs locale to overwrite the date format set there.
         *
         * @param (String)  format  The date format to use, ex: MM/DD/YYYY
         */
    setDateFormat: function (format) {
      var fmt = moment.localeData(moment.locale())._longDateFormat;
      var locale = $.extend({}, fmt, { L:format, l:format, lll: 'll LT', LLL: 'LL LT' });
      datetimeutil.DatetimeUtil.setLocale({longDateFormat : locale});
    },

        /**
         * Set the DatetimeUtil default time format. Builds a settings object from the current
         * Momentjs locale to overwrite the date format set there.
         *
         * @param (String)  format  The date format to use, ex: HH:mm a
         */
    setTimeFormat: function (format) {
      var fmt = moment.localeData(moment.locale())._longDateFormat;
      var locale = $.extend({}, fmt, { LT:format, lt:format, lll: 'll LT', LLL: 'LL LT' });
      datetimeutil.DatetimeUtil.setLocale({longDateFormat : locale});
    },

        /**
         * Set the DatetimeUtil default date format. Builds a settings object from the current
         * Momentjs locale to overwrite the date format set there.
         *
         * @param (String)  format  The date format to use, ex: dddd, MMMM Do YYYY
         */
    setLongDateFormat: function (format) {
      var fmt = moment.localeData(moment.locale())._longDateFormat;
      var locale = $.extend({}, fmt, { LL:format, ll:format, lll: 'll LT', LLL: 'LL LT' });
      datetimeutil.DatetimeUtil.setLocale({longDateFormat : locale});
    },

        /**
         * Get the timezone offset
         *
         * @param (String/Date) [date=now]  Datetime to get the offset from, optional
         *
         * @return {String}  The value of the timezone offset, ex: -07:00
         */
    getTimezoneOffset: function (date) {
      if (datetimeutil.DatetimeUtil._timeZoneStr) {
        return moment(date).format('Z');
      }
      return moment(date).utcOffset(datetimeutil.DatetimeUtil._timeZone).format('Z');
    },

        /**
         * Get the timezone earlier set
         *
         * @return {String}   Timezone IANA/Olson timezone string.
         */
    getTimezone: function() {
      return datetimeutil.DatetimeUtil._timeZoneStr;
    },

        /**
         * Get the DatetimeUtil date format. Builds a settings object from the current
         * Momentjs locale to overwrite the date format set there.
         *
         * @return {String}   DatetimeUtil default date format
         */
    getDefaultDateFormat: function () {
      return moment.localeData(moment.locale())._longDateFormat.l || moment.localeData(moment.locale())._longDateFormat.ll || 'MM-DD-YYYY';
    },

        /**
         * Get the DatetimeUtil time format.
         *
         * @return {String}   DatetimeUtil default date format
         */
    getDefaultTimeFormat: function () {
      return moment.localeData(moment.locale())._longDateFormat.LT || 'HH:mm:ss';
    },

    getDefaultDatetimeFormat: function () {
      return datetimeutil.DatetimeUtil.getDefaultDateFormat() + ' ' + datetimeutil.DatetimeUtil.getDefaultTimeFormat();
    },

        /**
         * Set the current locale for date/time translations. This can also be used to set arbitrary moment settings
         * including formats and translations
         *
         * @param   (String)   locale    The locale for datetime utils to use.
         * @param   (Object)   settings  The settings to pass to Momentjs
         */
    setLocale: function (locale, settings) {
      if (typeof locale !== 'string') {
        settings = locale;
        if (settings.value) {
          var splitValues = settings.value.split(/[\-_]/);
          locale = splitValues[0];
        } else {
          locale = datetimeutil.DatetimeUtil.__locale;
        }
      }
      if (settings !== undefined && settings !== null) settings.invalidDate = '';
      datetimeutil.DatetimeUtil.__locale = moment.locale(locale, settings);
    },

        /**
         * @return  {String}    Locale in the form en, en_gb, etc..
         */
    getLocale: function() {
      return datetimeutil.DatetimeUtil.__locale;
    },

        /**
         * This is really the worst way to set am/pm text, but we have to in order to match what a VF page might output.
         * Ideally, we would use Moment's built in localization functionality and have full support for even non-12 hour based formats.
         *
         * @param   (String)   amText   The text to use for "AM"
         * @param   (String)   pmText   The text to use for "PM"
         */
    setAmPmText: function(amText, pmText) {
      var meridiemParse = new RegExp(amText+'|'+pmText,'i');
      var isPM = function (input) { return input === pmText; };
      var meridiem = function (hour, minute, isLowercase) { if (hour > 11) return pmText; else return amText; };
      datetimeutil.DatetimeUtil.setLocale({ meridiemParse: meridiemParse, isPM: isPM, meridiem: meridiem });
    },

        /**
         * Get the format to display on screen, using given displayFormat
         *
         * @param   (String)    displayFormat   The type of display to format for (dateTime,dateOnly)
         *
         * @return  {String}    Formatting string for datetimes
         */
    getDisplayDatetimeFormat: function (displayFormat) {
      var response = datetimeutil.DatetimeUtil.getDefaultDatetimeFormat();
      if (displayFormat.toLowerCase() === 'dateonly' || displayFormat.toLowerCase() === 'date') {
        response = datetimeutil.DatetimeUtil.getDefaultDateFormat();
      }
      return response;
    },

        /**
         * Takes in a string SaleForce GMT time format 24hr, changes the timezone with
         * the given offset, and returns the formatted date string
         *
         * @param   (String)    date                  Datetime string
         * @param   (String)    timezoneOffset        Standard tz offset string, ex: "+07:00"
         * @param   (Boolean)   convertToServerTime   Reverses the function of this method, converting from user time to server time.
         *
         * @return  {String}    Converted date string
         */
    convertToTimezone: function (date, timezoneOffset, convertToServerTime){
      if (datetimeutil.DatetimeUtil._timeZoneStr !== '') {
        if (convertToServerTime) {
          return datetimeutil.DatetimeUtil.getFormattedDatetime(moment(date).utc(), datetimeutil.DatetimeUtil.getSaveFormat('datetime'));
        } else {
          return datetimeutil.DatetimeUtil.getFormattedDatetime(moment.utc(date).local(), datetimeutil.DatetimeUtil.getSaveFormat('datetime'));
        }
      }else {
        var currentOffset  = datetimeutil.DatetimeUtil._timeZone;

        if (timezoneOffset !== undefined && timezoneOffset !== null) {
                    // If the timezoneOffset is already an integer, lets leave it alone.
          if (typeof timezoneOffset !== 'number') {
            timezoneOffset = datetimeutil.DatetimeUtil.parseOffsetString(timezoneOffset);
          }
        } else {
          timezoneOffset = currentOffset;
        }

                // var sourceOffset = moment(date).utcOffset();
                // if (sourceOffset !== currentOffset) {
                //     timezoneOffset -= (currentOffset - sourceOffset);
                // }

                // Invert the timezoneOffset unless we are converting to server time.
        if (convertToServerTime) {
          timezoneOffset *= -1;
        }

        return datetimeutil.DatetimeUtil.getFormattedDatetime(moment.utc(date).utcOffset(timezoneOffset), datetimeutil.DatetimeUtil.getSaveFormat('datetime'));
      }
    },

        /**
         * Regex to match offset chunks +00 00 -00
         */
    chunkOffset: /([+-]|\d\d)/gi,

        /**
         * Regex to match offsets +00:00 -00:00 +0000 -0000 or Z
         */
    matchOffset: /Z|[+-]?\d\d:?\d\d/gi,

        /**
         * Parse a string timezone offset to an integer. Should work in every possible case, but hasn't been tested thoroughly.
         * Previously called "convertTimezoneStringToNumber" but refactored for clarity
         *
         * @param   (String)  offset   The string representation of the offset, formatted either '+10:00' or '-1530'
         *
         * @return  {String}  The numeric representation of the passed offset
         */
    parseOffsetString: function (offset) {
      if (offset.indexOf('-') === -1 && offset.indexOf('+') === -1) offset = '+'+offset;

      var matches = ((offset || '').match(datetimeutil.DatetimeUtil.matchOffset) || []);
      var chunk   = matches[matches.length - 1] || [];
      var parts   = (chunk + '').match(datetimeutil.DatetimeUtil.chunkOffset) || ['-', 0, 0];
      var minutes = +(parts[1] * 60) + datetimeutil.DatetimeUtil.__toInt(parts[2]);

      return parts[0] === '+' ? minutes : -minutes;
    },

        /**
         * Helper function for parsing timezone offsets
         *
         * @param   (Mixed)   input   The object to coerce to an integer
         *
         * @return  {Integer} The integer that represents the input value
         */
    __toInt: function (input) {
      var coercedNumber = +input,
        value = 0;

      if (coercedNumber !== 0 && isFinite(coercedNumber)) {
        if (coercedNumber >= 0) {
          value = Math.floor(coercedNumber);
        } else {
          value = Math.ceil(coercedNumber);
        }
      }

      return value;
    },

        /**
         * Used to build the datetime value based on macros, retuns a date/time string formatted with the default formatting.
         * Result will be in UTC (server) time! If you want local time, you must convert yourself.
         *
         * @param   (String)   macro                Yesterday, Now, Today, or Tomorrow
         * @param   (String)   [dateFormat]         Standard date format string, ex: YYYY-MM-DD
         * @param   (String)   [timeFormat]         Standard time format string, ex: hh:mm:ss
         * @param   (String)   [displayMode]        datetime or date, depending on which we want
         * @param   (String)   [dtValue]            A current datetime value, used for when displayMode is undefined or null
         * @param   (bool)     true/false           If you want macros to respect local time.
         *
         * @return  {String}   Formatted date/time string
         */
    macroDrivenDatetime: function (macro, dateFormat, timeFormat, displayMode, dtValue) {
      var date = moment.utc();
      dateFormat = dateFormat || datetimeutil.DatetimeUtil.getDefaultDateFormat();
      timeFormat = timeFormat || datetimeutil.DatetimeUtil.getDefaultTimeFormat();

      var value;

      if (macro.toLowerCase() !== 'now' && datetimeutil.DatetimeUtil._timeZoneStr === '') {
        date = date.utcOffset(datetimeutil.DatetimeUtil._timeZone);
      }

      switch (macro.toLowerCase()) {
      case 'yesterday':
        date = date.local().subtract(1, 'days').startOf('day');
        break;
      case 'now':
                // No-op, date is already now.
        break;
      case 'today':
        date = date.local().startOf('day');
        break;
      case 'tomorrow':
        date = date.local().add(1, 'days').startOf('day');
        break;
      }

            // Default formatting to date and time.
      value = date.format(dateFormat + ' ' + timeFormat);
            // Some fields might have specific formatting needs, so address them here.
      if (displayMode !== null && displayMode !== undefined) {
        if (displayMode === 'datetime') {
          value = date.format(dateFormat + ' ' + timeFormat);
        } else if (displayMode === 'date') {
          value = date.format(dateFormat);
        } else {
          value = date.format(dateFormat + ' ' + timeFormat);
        }
      } else if (dtValue !== null && dtValue !== undefined) {
        value = date.format(dateFormat);
        if (dtValue.length > 12) {
          value = date.format(dateFormat + ' ' + timeFormat);
        }
      }

      return value;
    },

        /**
         * Easily manipulate dates
         *
         * @param   (String/Date/Object)   datetime   String representing the datetime to modify
         * @param   (String)   timeunit   String representing the unit to modify by
         * @param   (Number)   amount     The amount to modify the previous unit by
         *
         * @return  {String}   Modified datetime string
         */
    manipulateDatetime: function (datetime, timeunit, amount) {
      var dateobj = moment(datetime);
      if (!dateobj.isValid())
        return datetime;
      if (amount < 0) {
        amount *= -1;
        return dateobj.subtract(amount, timeunit).format('YYYY-MM-DD HH:mm:ss');
      }
      return dateobj.add(amount, timeunit).format('YYYY-MM-DD HH:mm:ss');
    },

        /**
         *
         * Get the start of a unit of time
         *
         * Units supported: year, month, quarter, week, isoweek, day, hor, minute, second
         *
         * @param   (String/Date/Object)   datetime   String representing the datetime to modify
         * @param   (String)   unit   String representing the unit to modify by
         *
         * @return  {String}   Modified datetime string
         */
    getStartOf: function(datetime, unit) {
      var dateobj = moment(datetime);
      if (!dateobj.isValid()) {
        return datetime;
      }

      return dateobj.startOf(unit).format('YYYY-MM-DD HH:mm:ss');
    },

        /**
         *
         * Get the end of a unit of time
         *
         * Units supported: year, month, quarter, week, isoweek, day, hor, minute, second
         *
         * @param   (String/Date/Object)   datetime   String representing the datetime to modify
         * @param   (String)   unit   String representing the unit to modify by
         *
         * @return  {String}   Modified datetime string
         */
    getEndOf: function(datetime, unit) {
      var dateobj = moment(datetime);
      if (!dateobj.isValid()) {
        return datetime;
      }

      return dateobj.endOf(unit).format('YYYY-MM-DD HH:mm:ss');
    },

        /**
         * Used to determine if an arbitrary format uses 24 hour time or 12 hour time.
         *
         * Previously called "getTimeFormat" but refactored for clarity
         *
         * @param   (String)   format   Format string to determine whether or not it is 24 hour time
         *
         * @return  {String}   12/24 depending on if the format is 12  or 24 hour time.
         */
    isFormat24HourTime: function (format) {
      if (format.indexOf('h') > -1) {
        return '12';
      } else {
        return '24';
      }
    },

        /**
         * Used to determine if an arbitrary object is a valid date/time representation
         *
         * @param   (Mixed)     date   A representation of a date/time
         *
         * @return  {Boolean}   true if this object is a valid date/time object, else false.
         */
    isValidDate: function (date) {
      return moment(date).isValid();
    },

        /**
         * Get the format which we should save the date in. Eventually will be ISO 8601 compliant.
         * @todo Make this ISO 8601 compliant, and make sure doing so doesn't break anything.
         *
         * @param   (String)   mode   datetime will save including time, anything else will only save date.
         *
         * @return  {String}   Save format
         */
    getSaveFormat: function (mode) {
      var saveFormat = 'YYYY-MM-DD';
      if (mode !== undefined && mode !== null && mode.toLowerCase() === 'datetime') {
        saveFormat = 'YYYY-MM-DD HH:mm:ss';
      }
      return saveFormat;
    },

        /**
         * Format a given datetime to the save format, either with or without the time.
         * DEPRECATED: Please use getFormattedDatetime in combination with getSaveFormat instead.
         *
         * @param   (String/Date)  inDate       Datetime object to format to save format
         * @param   (Boolean)      [dateOnly]   Is this datetime date only or not
         *
         * @return  {String}    Save-formatted datetime
         */
    dateObjFormatter: function (inDate, dateOnly) {
      console.warn('DatetimeUtils.dateObjFormatter is deprecated! Please use getFormattedDatetime in combination with getSaveFormat instead');
      return datetimeutil.DatetimeUtil.getFormattedDatetime(inDate, datetimeutil.DatetimeUtil.getSaveFormat(dateOnly ? 'dateOnly' : 'dateTime'));
    },

        /**
         * Get current datetime, formatted with either the format given, or the default date time format.
         *
         * @param   (String)   [format]   The format that the returned datetime should use.
         *
         * @return  {String}   A formatted datetime
         */
    getCurrentDatetime: function (format) {
      if (datetimeutil.DatetimeUtil._timeZoneStr !== '') {
        return datetimeutil.DatetimeUtil.getFormattedDatetime(moment(), format);
      }
      return datetimeutil.DatetimeUtil.getFormattedDatetime(moment.utc().utcOffset(datetimeutil.DatetimeUtil._timeZone), format);
    },

        /**
         * Get current local datetime, ISO 8601 formatted
         *
         * @return  {String}   Current local datetime, formatted like 2013-02-04T22:44:30.652Z
         */
    getCurrentDatetimeISO: function () {
      return moment().toISOString();
    },

        /**
         * Get current datetime, formatted with either the format given, or the default date time format.
         * @todo Should eventually be in UTC format
         *
         * @param   (String)   [format]   The format that the returned datetime should use.
         *
         * @return  {String}   A formatted datetime
         */
    getCurrentDatetimeGMT: function (format) {
      return datetimeutil.DatetimeUtil.getFormattedDatetime(moment.utc(), format);
    },

        /**
         * Format a datetime with either the format given, or the default date time format.
         *
         * @param   (String/Moment)   datetime   The datetime to use, may be a string or a momentjs object.
         * @param   (String)          [format]   The format that the returned datetime should use.
         *
         * @return  {String}   A formatted datetime
         */
    getFormattedDatetime: function (datetime, format) {
      if (format === null || format === undefined) {
        format = datetimeutil.DatetimeUtil.getDefaultDatetimeFormat();
      }
      return moment(datetime).format(format);
    },

        /**
         * Format a datetime with either the format given, or the default date time format.
         *
         * @param   (String/Moment/Date)   datetime   The datetime to use, may be a string, date or a momentjs object.
         * @param   (String)               [format]   The format that the returned datetime should use.
         *
         * @return  {String}   A formatted datetime
         */
    getFormattedUTCDatetime: function (datetime, format) {
      if (format === null || format === undefined) {
        format = datetimeutil.DatetimeUtil.getDefaultDatetimeFormat();
      }
      return moment.utc(datetime).format(format);
    },

        /**
         * Parse a given date string and return the JS date object.
         * Parsing is done by Moment.js, and should support all possible formats here.
         *
         *
         * Mostly used in sfm engines, there are two datetime formats used in data models:
         * "2013-04-17T23:38:18.000+0000"
         * "2013-04-01 00:00:00"
         * It may also be possible to have just "2013-04-01"
         *
         * Previously called "getDateObjFromDataModel" but refactored for clarity
         *
         * @param   (String/Date/Object)    date      The date string to parse.
         * @param   (String)    [format]  Formatting hint
         *
         * @return  {Date}   JS Date object
         */
    parseDate: function (date, format) {
      return moment(date, format).toDate();
    },

        /**
         * Parse a given date string and return the JS date object.
         * Parsing is done by Moment.js, and should support all possible formats here.
         *
         *
         * @param   (String)    date      The GMT/UTC date string to parse.
         * @param   (String)    [format]  Formatting hint
         *
         * @return  {Date}   JS Date object
         */
        parseGMTDate: function (date, format) {
            try {
                var jsDate = moment.utc(date, format).format("YYYY-MM-DD HH:mm:ss");
                return moment.utc(jsDate).toDate();
            } catch (e) {
                throw new Error("Failed to parse date in GMT format: " + date);
            }
        },

        /**
         * Parse a given date string and return the JS date object, with all time parts set to 0
         * Parsing is done by Moment.js, and should support all possible formats here.
         *
         *
         * @param   (String)    date      The date string to parse.
         * @param   (String)    [format]  Formatting hint
         *
         * @return  {Date}   JS Date object
         */
    parseDateOnly: function (date, format) {
      return moment(date, format).startOf('day').toDate();
    },

        /**
         * Parse a given date string and return the JS date object, with all time parts set to 0
         * Parsing is done by Moment.js, and should support all possible formats here.
         *
         *
         * @param   (String)    date      The GMT/UTC date string to parse.
         * @param   (String)    [format]  Formatting hint
         *
         * @return  {Date}   JS Date object
         */
    parseGMTDateOnly: function (date, format) {
      var jsDate = moment.utc(date, format).startOf('day');
      if (jsDate && !jsDate.isValid()) {
        throw 'Failed to parse date in GMT format: ' + date;
      }
      return jsDate.toDate();
    },

        /**
         * Engineer the value in a format as to be read by Ext.date.parse. Ext
         * throws a fit if the datetime we give it is not 24 hour.
         *
         * Previously called "setDatetimeValue" but refactored for clarity
         *
         * @param   (String)    datetime  Datetime string to convert to Ext parsable string
         * @param   (String)    [format]  Formatting hint
         *
         * @return  {String}    The formatted string for Ext Parsing
         */
    convertDatetimeForExt: function (datetime, format) {
      return moment.utc(datetime, format).format('YYYY-MM-DD HH:mm:ss');
    },


        /**
         * Engineer the value in a format as to be read by Ext.date.parse. 
         
         *
         * @param   (String)    date  Date string to convert to Ext parsable string
         * @param   (String)    [format]  Formatting hint
         *
         * @return  {String}    The formatted string for Ext Parsing
         */
    convertDateForExt: function (date, format) {
      return moment.utc(date, format).format('YYYY-MM-DD');
    },

        /**
         * Generate a humanized relative date string, along the lines of
         * "Last Thursday at 9:45 am" or "Tomorrow at 3:00 pm"
         *
         * @param   (String)    datetime    GMT Datetime
         * @param   (Number)    [timespan]  Number of days to show relative time before dropping to standard date/time (default and max 7)
         *
         * @return  {String}    The humanized relative datetime string
         */
    humanizeRelativeDate: function (datetime, timespan) {
      timespan = (timespan === undefined || timespan === null) ? 7 : timespan;

      if (timespan > 7) {
        throw new Error('DatetimeUtils.humanizeRelativeDate: timespan for humanized dates too long');
      }
      else {
        var daysDiff = moment().startOf('d').diff(moment(datetime), 'days');
        if (daysDiff >= timespan || daysDiff < -timespan) {
          return datetimeutil.DatetimeUtil.getFormattedDatetime(datetime);
        }
      }
      return moment(datetime).calendar();
    },

        /**
         * Get the time duration between two datetimes.
         *
         * @param (String/Date)   d1   First datetime to compare
         * @param (String/Date)   d2   Second datetime to compare
         *
         * @return {Duration}   MomentJS duration
         */
    getDurationBetween: function (d1, d2) {
      var isValid = moment(d1).isValid() && moment(d2).isValid();
      var result = moment.duration(moment(d2).diff(d1));
      result.isValid = function() { return isValid; };
      return result;
    },

        /**
         * Returns whether two dates are the same.
         *
         * @param (String/Date)   d1   First datetime to compare
         * @param (String/Date)   d2   Second datetime to compare
         * @param {String} unit String representing the unit to compare
         *
         * @return {Boolean}   true if two dates are the same up to the specified unit, else false.
         */
    isSame: function (d1, d2, unit) {
      return moment(d1).isSame(moment(d2), unit);
    },

        /**
         * Engineer the value in a format as to be saved to the DB
         *
         * @param   (String)    datetime  Datetime string to convert to save formatted string
         * @param   (String)    [format]  Formatting hint
         *
         * @return  {String}    The formatted string for saving
         */
    convertDatetimeForSave: function (datetime, format) {
      return moment.utc(datetime, format).format(datetimeutil.DatetimeUtil.getSaveFormat('dateTime'));
    },

        /**
         * Get local UTC offset, in +07:00 format
         *
         * @return  {String}    UTC offset string
         */
    getLocalUTCOffsetString: function () {
      return moment().format('Z');
    },

        /**
         * Get local UTC offset, in integer (minutes) format
         *
         * @return  {Integer}   UTC offset integer
         */
    getLocalUTCOffset: function () {
      return moment().utcOffset();
    },

        /**
         * Get current timestamp in the save format.
         *
         * @return  {String}    Timestamped save format
         */
    getTimestampWithSaveFormat: function () {
      return datetimeutil.DatetimeUtil.macroDrivenDatetime('Now', 'YYYY-MM-DD', 'HH:mm:ss');
    },

        /**
         * Get the day name by respecting the device locale
         * @param   (Number)    dayNumber  (0 = Sunday, 1 = Monday... 6 = Saturday )
         * @param   (String)    displayFormat (ddd = 'Sun', 'dddd' = 'Sunday')
         * @return  {String}   Name of the day in the device locale
         */
    getWeekDayNameInUserLocale: function (dayNumber, displayFormat) {
      if ( !displayFormat ) {
        displayFormat = 'ddd';
      }

      return moment().day(dayNumber).format(displayFormat);
    },

        /*
        * Extending moment.add function as Ext.Date.Add has a bug for DST
        * This is a pretty robust function for adding time to an existing date. 
        * To add time, pass the key of what time you want to add, and the amount you want to add.
        * @param (Date) date (valid date object)
        * @param (Number) amount (Positive / Negative as units converted. Ex: To add a day pass '1' and unit as 'days' / 'd' )
        * @param (String) unit (valid values are listed below)
        *    years    y
        *    quarters    Q
        *    months  M
        *    weeks   w
        *    days    d
        *    hours   h
        *    minutes m
        *    seconds s
        *    milliseconds    ms
        * @return  {date}   new JSDate
        */
    addUnitToDateTime : function(date, amount, unit) {
      return moment(date).add(amount, unit).toDate();
    },

    ext_tokens: {
      YY : 'y',
      YYYY: 'Y',
      M : 'n',
      MM : 'm',
      MMM : 'M',
      MMMM : 'F',
      w : 'W',
      D : 'j',
      Do : 'jS',
      DD : 'd',
      DDD : 'z',
      ddd : 'D',
      dddd : 'l',
      d : 'w',
      H : 'G',
      HH : 'H',
      h : 'g',
      hh : 'h',
      mm : 'i',
      ss : 's',
      z : 'e',
      zz : 'e'
    },

        /**
         * Convert format string from JS format to PHP format, for usage in EXTJS components.
         * If no format is given, it will convert the default datetime format.
         *
         * @param   (String)    [format]  The format to convert, if none specified this will use the default datetime format
         *
         * @return  {String}    PHP formatted datetime format string
         */
    convertFormatForExt: function (format) {
      format = format || datetimeutil.DatetimeUtil.getDefaultDatetimeFormat();
      return datetimeutil.DatetimeUtil.convertFormatToFormat(format, datetimeutil.DatetimeUtil.ext_tokens);
    },

        /**
         * Convert format string from PHP format to JS format, for usage in EXTJS components.
         * If no format is given, it will convert the default datetime format.
         *
         * @param   (String)    format  The format to convert
         *
         * @return  {String}    JS formatted datetime format string
         */
    convertFormatFromExt: function (format) {
      var tokens = datetimeutil.DatetimeUtil._swap(datetimeutil.DatetimeUtil.ext_tokens);
      return datetimeutil.DatetimeUtil.convertFormatToFormat(format, tokens);
    },

        /**
         * Token translations for C# -> JS datetime formatting
         */
    tokens: {
      d : 'D',            //The day of the month, from 1 through 31. (eg. 5/1/2014 1:45:30 PM, Output: 1)
      dd : 'DD',          //The day of the month, from 01 through 31. (eg. 5/1/2014 1:45:30 PM, Output: 01)
      ddd : 'ddd',        //The abbreviated name of the day of the week. (eg. 5/15/2014 1:45:30 PM, Output: Mon)
      dddd : 'dddd',      //The full name of the day of the week. (eg. 5/15/2014 1:45:30 PM, Output: Monday)
      f : 'S',            //The tenths of a second in a date and time value. (eg. 5/15/2014 13:45:30.617, Output: 6)
      ff : 'SS',          //The hundredths of a second in a date and time value.  (eg. 5/15/2014 13:45:30.617, Output: 61)
      fff : 'SSS',        //The milliseconds in a date and time value. (eg. 5/15/2014 13:45:30.617, Output: 617)
      h : 'h',            //The hour, using a 12-hour clock from 1 to 12. (eg. 5/15/2014 1:45:30 AM, Output: 1)
      hh : 'hh',          //The hour, using a 12-hour clock from 01 to 12. (eg. 5/15/2014 1:45:30 AM, Output: 01)
      H : 'H',            //The hour, using a 24-hour clock from 0 to 23. (eg. 5/15/2014 1:45:30 AM, Output: 1)
      HH : 'HH',          //The hour, using a 24-hour clock from 00 to 23. (eg. 5/15/2014 1:45:30 AM, Output: 01)
      m : 'm',            //The minute, from 0 through 59. (eg. 5/15/2014 1:09:30 AM, Output: 9
      mm : 'mm',          //The minute, from 00 through 59. (eg. 5/15/2014 1:09:30 AM, Output: 09
      M : 'M',            //The month, from 1 through 12. (eg. 5/15/2014 1:45:30 PM, Output: 6
      MM : 'MM',          //The month, from 01 through 12. (eg. 5/15/2014 1:45:30 PM, Output: 0
      MMM : 'MMM',        //The abbreviated name of the month. (eg. 5/15/2014 1:45:30 PM, Output: Jun
      MMMM : 'MMMM',      //The full name of the month. (eg. 5/15/2014 1:45:30 PM, Output: June)
      s : 's',            //The second, from 0 through 59. (eg. 5/15/2014 1:45:09 PM, Output: 9)
      ss : 'ss',          //The second, from 00 through 59. (eg. 5/15/2014 1:45:09 PM, Output: 09)
      t : 'a',            //The first character of the AM/PM designator. (eg. 5/15/2014 1:45:30 PM, Output: P)
      tt : 'A',           //The AM/PM designator. (eg. 5/15/2014 1:45:30 PM, Output: PM)
      y : 'YY',           //The year, from 0 to 99. (eg. 5/15/2014 1:45:30 PM, Output: 9)
      yy : 'YY',          //The year, from 00 to 99. (eg. 5/15/2014 1:45:30 PM, Output: 09)
      yyy : 'YYYY',       //The year, with a minimum of three digits. (eg. 5/15/2014 1:45:30 PM, Output: 2009)
      yyyy : 'YYYY',      //The year as a four-digit number. (eg. 5/15/2014 1:45:30 PM, Output: 2009)
      z : 'Z',            //Hours offset from UTC, with no leading zeros. (eg. 5/15/2014 1:45:30 PM -07:00, Output: -7)
      zz : 'Z',           //Hours offset from UTC, with a leading zero for a single-digit value. (eg. 5/15/2014 1:45:30 PM -07:00, Output: -07)
      zzz : 'Z',          //Hours and minutes offset from UTC. (eg. 5/15/2014 1:45:30 PM -07:00, Output: -07:00)
      st: 'Do',           //Date ordinal display from day of the date. (eg. 5/15/2014 1:45:30 PM, Output: 15th)
      ee: 'e',            //Day of the week, from 0 through 6, where the starting day depends on locale (eg. 5/15/2014 1:45:30 PM, Output: 0)
      eee: 'ddd',         //The abbreviated name of the day of the week. (eg. 5/15/2014 1:45:30 PM, Output: Mon)
      eeee: 'dddd',       //The full name of the day of the week. (eg. 5/15/2014 1:45:30 PM, Output: Monday)
      EE: 'E',            //Day of the week, from 0 through 6, where Sunday is 0(eg. 5/15/2014 1:45:30 PM, Output: 1)
      EEE: 'ddd',         //The abbreviated name of the day of the week. (eg. 5/15/2014 1:45:30 PM, Output: Mon)
      EEEE: 'dddd'        //The full name of the day of the week. (eg. 5/15/2014 1:45:30 PM, Output: Monday)
    },

        /**
         * Convert an arbitrary datetime format to JS time format
         *
         * @param   (String)    format  The format to convert to JS format
         * @param   [Object]    tokens  If undefined, C# to JS formatting translations will be used.
         *
         * @return  {String}    JS Datetime formatting string
         */
    convertFormatToJSFormat: function (format, tokens) {
      tokens = tokens || datetimeutil.DatetimeUtil.tokens;
      return datetimeutil.DatetimeUtil.convertFormatToFormat(format, tokens);
    },

        /**
         * Convert an ISO Date string into specified date format.
         *
         *@param (String) dateString ISO date string.
         *
         * @param   (String)    format  The format to convert to JS format
         *
         * @return  {String}    formatted date string
         */

    convertISODateStringToSpecifiedFormat : function(dateString,format) {
      var formattedDate = moment(datetimeutil.DatetimeUtil.convertDatetimeForSave(dateString));
      var result = datetimeutil.DatetimeUtil.getFormattedDatetime(formattedDate, format);
      return result;
    },

        /**
         * Convert an arbitrary datetime format to an arbitrary format
         *
         * @param   (String)    format  The format to convert to JS format
         * @param   (Object)    tokens  The list of tokens and their replacements
         *
         * @return  {String}    Transformed string
         */
    convertFormatToFormat: function (format, tokens) {
      var parts = format.split(/\W+/),
        delims = format.split(/\w+/),
        count = 1; // Start at one because we always want to be one ahead of the parts

      format = ''; // Reset the format to empty, we will build it again from the parts and delimiters
      parts.forEach(function(part) {
                // If the part is in the tokens, replace it with the token value
        if (typeof(tokens[part]) === 'string') {
          part = tokens[part];
        }
                // Append the part itself to the output
        format += part;
                // If there's a delimiter, add that after the part
        if (delims[count] !== undefined) format += delims[count];
        count++;
      });
            // Return the transformed format
      return format;
    },

  });
})();
