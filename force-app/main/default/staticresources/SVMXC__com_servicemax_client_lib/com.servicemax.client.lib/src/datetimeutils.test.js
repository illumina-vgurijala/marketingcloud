describe('DatetimeUtils', function() {
  var Utils = com.servicemax.client.lib.datetimeutils.DatetimeUtil;

  // Removed flakey tests
  // TODO: Add better tests

  describe('#manipulateDatetime', function() {
    it('should be able to manipulate year', function() {
      var goodDate = '2014-03-14 01:01:01';
      var badDate = 'NaN-NaN-NaN 00:00:00';
      var reallYadDate = 'NaN-Foo 00:00';
      var badString = 'Hello World';

      //Good tests
      var newDate = Utils.manipulateDatetime(goodDate, 'years', 2);
      assert.equal(newDate, '2016-03-14 01:01:01', 'Year should be 2016');
      newDate = Utils.manipulateDatetime(goodDate, 'years', -2);
      assert.equal(newDate, '2012-03-14 01:01:01', 'Year should be 2012');
      newDate = Utils.manipulateDatetime(badDate, 'years', 2);
      assert.equal(newDate, badDate, 'Year should original');
      newDate = Utils.manipulateDatetime(reallYadDate, 'years', 2);
      assert.equal(newDate, reallYadDate, 'Year should original');
      newDate = Utils.manipulateDatetime(badString, 'years', 2);
      assert.equal(newDate, badString, 'Year should original');
    });

    it('should be able to manipulate month', function() {
      var goodDate = '2014-03-14 01:01:01';
      var badDate = 'NaN-NaN-NaN 00:00:00';
      var reallYadDate = 'NaN-Foo 00:00';
      var badString = 'Hello World';

      //Good tests
      var newDate = Utils.manipulateDatetime(goodDate, 'months', 2);
      assert.equal(newDate, '2014-05-14 01:01:01', 'Month should be 5');
      newDate = Utils.manipulateDatetime(goodDate, 'months', -2);
      assert.equal(newDate, '2014-01-14 01:01:01', 'Month should be 2');
      newDate = Utils.manipulateDatetime(goodDate, 'months', 13);
      assert.equal(newDate, '2015-04-14 01:01:01', 'Month should be 4 and Year should be 2015');
      newDate = Utils.manipulateDatetime(badDate, 'months', 2);
      assert.equal(newDate, badDate, 'Month should original');
      newDate = Utils.manipulateDatetime(reallYadDate, 'months', 2);
      assert.equal(newDate, reallYadDate, 'Month should original');
      newDate = Utils.manipulateDatetime(badString, 'months', 2);
      assert.equal(newDate, badString, 'Month should original');
    });

    it('should be able to manipulate day', function() {
      var goodDate = '2014-03-14 01:01:01';
      var badDate = 'NaN-NaN-NaN 00:00:00';
      var reallYadDate = 'NaN-Foo 00:00';
      var badString = 'Hello World';

      //Good tests
      var newDate = Utils.manipulateDatetime(goodDate, 'days', 2);
      assert.equal(newDate, '2014-03-16 01:01:01', 'Day should be 16');
      newDate = Utils.manipulateDatetime(goodDate, 'days', -2);
      assert.equal(newDate, '2014-03-12 01:01:01', 'Day should be 12');
      newDate = Utils.manipulateDatetime(goodDate, 'days', 366);
      assert.equal(newDate, '2015-03-15 01:01:01', 'Day should be 15 and Year should be 2015');
      newDate = Utils.manipulateDatetime(badDate, 'days', 2);
      assert.equal(newDate, badDate, 'Day should original');
      newDate = Utils.manipulateDatetime(reallYadDate, 'days', 2);
      assert.equal(newDate, reallYadDate, 'Day should original');
      newDate = Utils.manipulateDatetime(badString, 'days', 2);
      assert.equal(newDate, badString, 'Day should original');
    });

    it('should be able to manipulate hour', function() {
      var goodDate = '2014-03-14 01:01:01';
      var badDate = 'NaN-NaN-NaN 00:00:00';
      var reallYadDate = 'NaN-Foo 00:00';
      var badString = 'Hello World';

      //Good tests
      var newDate = Utils.manipulateDatetime(goodDate, 'hours', 2);
      assert.equal(newDate, '2014-03-14 03:01:01', 'Hour should be 3');
      newDate = Utils.manipulateDatetime(goodDate, 'hours', -2);
      assert.equal(newDate, '2014-03-13 23:01:01', 'Hour should be 23 and Day 13');
      newDate = Utils.manipulateDatetime(badDate, 'hours', 2);
      assert.equal(newDate, badDate, 'Hour should original');
      newDate = Utils.manipulateDatetime(reallYadDate, 'hours', 2);
      assert.equal(newDate, reallYadDate, 'Hour should original');
      newDate = Utils.manipulateDatetime(badString, 'hours', 2);
      assert.equal(newDate, badString, 'Hour should original');
    });

    it('should be able to manipulate minute', function() {
      var goodDate = '2014-03-14 01:01:01';
      var badDate = 'NaN-NaN-NaN 00:00:00';
      var reallYadDate = 'NaN-Foo 00:00';
      var badString = 'Hello World';

      //Good tests
      var newDate = Utils.manipulateDatetime(goodDate, 'minutes', 2);
      assert.equal(newDate, '2014-03-14 01:03:01', 'Minute should be 3');
      newDate = Utils.manipulateDatetime(goodDate, 'minutes', -2);
      assert.equal(newDate, '2014-03-14 00:59:01', 'Minute should be 59, Hours 23, and Day 13');
      newDate = Utils.manipulateDatetime(badDate, 'minutes', 2);
      assert.equal(newDate, badDate, 'Minute should original');
      newDate = Utils.manipulateDatetime(reallYadDate, 'minutes', 2);
      assert.equal(newDate, reallYadDate, 'Minute should original');
      newDate = Utils.manipulateDatetime(badString, 'minutes', 2);
      assert.equal(newDate, badString, 'Minute should original');
    });

    it('should be able to manipulate seconds', function() {
      var goodDate = '2014-03-14 01:01:01';
      var badDate = 'NaN-NaN-NaN 00:00:00';
      var reallYadDate = 'NaN-Foo 00:00';
      var badString = 'Hello World';

      //Good tests
      var newDate = Utils.manipulateDatetime(goodDate, 'seconds', 2);
      assert.equal(newDate, '2014-03-14 01:01:03', 'Second should be 3');
      newDate = Utils.manipulateDatetime(goodDate, 'seconds', -2);
      assert.equal(newDate, '2014-03-14 01:00:59', 'Second should be 59, Minutes 00');
      newDate = Utils.manipulateDatetime(badDate, 'seconds', 2);
      assert.equal(newDate, badDate, 'Second should original');
      newDate = Utils.manipulateDatetime(reallYadDate, 'seconds', 2);
      assert.equal(newDate, reallYadDate, 'Second should original');
      newDate = Utils.manipulateDatetime(badString, 'seconds', 2);
      assert.equal(newDate, badString, 'Second should original');
    });

    it('should do nothing for invalid manipulations', function() {
      var goodDate = '2014-03-14 01:01:01';

      //Good tests
      newDate = Utils.manipulateDatetime(goodDate, 'xxxx', 2);
      assert.equal(newDate, goodDate, 'Result should be ' + goodDate);
    });
  });

  describe('#getDurationBetween', function() {
    it('should be invalid when provided invalid inputs', function() {
      var results = Utils.getDurationBetween('NaN-NaN', '2014-03-14 01:01:01');
      assert.equal(results.isValid(), false, 'Result should not be valid');
      results = Utils.getDurationBetween('2014-03-14 01:01:01', 'NaN');
      assert.equal(results.isValid(), false, 'Result should not be valid');
      results = Utils.getDurationBetween(null, 'NaN');
      assert.equal(results.isValid(), false, 'Result should not be valid');
    });

    it('should work for durations within the same day', function() {
      var start = '2014-03-14 13:01:01';
      var end = '2014-03-14 15:30:01';
      var results = Utils.getDurationBetween(start, end);

      assert.equal(results.get('years'), 0, 'Resulting year duration should be 0');
      assert.equal(results.get('months'), 0, 'Resulting month duration should be 0');
      assert.equal(results.get('days'), 0, 'Resulting day duration should be 0');
      assert.equal(results.get('hours'), 2, 'Resulting hour duration should be 2');
      assert.equal(results.get('minutes'), 29, 'Resulting minute duration should be 29');
      assert.equal(results.get('seconds'), 0, 'Resulting minute duration should be 0');
      assert.equal(results.get('milliseconds'), 0, 'Resulting millisecond duration should be 0');

      assert.equal(results.as('minutes'), 149, 'Resulting total minute duration should be 149');
      assert.equal(results.toString(), 'PT2H29M', 'Resulting ISO duration should be PT2H29M');
    });

    it('should work for durations within a couple days', function() {
      var start = '2014-03-14 13:01:01';
      var end = '2014-03-15 15:30:01';
      var results = Utils.getDurationBetween(start, end);

      assert.equal(results.get('years'), 0, 'Resulting year duration should be 0');
      assert.equal(results.get('months'), 0, 'Resulting month duration should be 0');
      assert.equal(results.get('days'), 1, 'Resulting day duration should be 1');
      assert.equal(results.get('hours'), 2, 'Resulting hour duration should be 2');
      assert.equal(results.get('minutes'), 29, 'Resulting minute duration should be 29');
      assert.equal(results.get('seconds'), 0, 'Resulting minute duration should be 0');
      assert.equal(results.get('milliseconds'), 0, 'Resulting millisecond duration should be 0');

      assert.equal(results.as('minutes'), 1589, 'Resulting total minute duration should be 1589');
      assert.equal(results.toString(), 'P1DT2H29M', 'Resulting ISO duration should be P1DT2H29M');
    });

    it('should work for durations within a week', function() {
      var start = '2014-03-14 13:01:01';
      var end = '2014-03-20 15:30:01';
      var results = Utils.getDurationBetween(start, end);

      assert.equal(results.get('years'), 0, 'Resulting year duration should be 0');
      assert.equal(results.get('months'), 0, 'Resulting month duration should be 0');
      assert.equal(results.get('days'), 6, 'Resulting day duration should be 6');
      assert.equal(results.get('hours'), 2, 'Resulting hour duration should be 2');
      assert.equal(results.get('minutes'), 29, 'Resulting minute duration should be 29');
      assert.equal(results.get('seconds'), 0, 'Resulting minute duration should be 0');
      assert.equal(results.get('milliseconds'), 0, 'Resulting millisecond duration should be 0');

      assert.equal(results.as('minutes'), 8789, 'Resulting total minute duration should be 8789');
      assert.equal(results.toString(), 'P6DT2H29M', 'Resulting ISO duration should be P6DT2H29M');
    });

    it('should work for durations around a month', function() {
      var start = '2014-03-14 13:01:01';
      var end = '2014-04-13 15:30:01';
      var results = Utils.getDurationBetween(start, end);

      // Month durations are under the assumption that the average month has 30 days.
      assert.equal(results.get('years'), 0, 'Resulting year duration should be 0');
      assert.equal(results.get('months'), 1, 'Resulting month duration should be 1');
      assert.equal(results.get('days'), 0, 'Resulting day duration should be 0');
      assert.equal(results.get('hours'), 2, 'Resulting hour duration should be 2');
      assert.equal(results.get('minutes'), 29, 'Resulting minute duration should be 29');
      assert.equal(results.get('seconds'), 0, 'Resulting minute duration should be 0');
      assert.equal(results.get('milliseconds'), 0, 'Resulting millisecond duration should be 0');

      assert.equal(results.as('minutes'), 43349, 'Resulting total minute duration should be 43349');
      assert.equal(results.toString(), 'P1MT2H29M', 'Resulting ISO duration should be P1MT2H29M');
    });

    it('should work for durations over a month', function() {
      var start = '2014-03-14 13:01:01';
      var end = '2014-04-24 15:30:01';
      var results = Utils.getDurationBetween(start, end);

      // Month durations are under the assumption that the average month has 30 days.
      assert.equal(results.get('years'), 0, 'Resulting year duration should be 0');
      assert.equal(results.get('months'), 1, 'Resulting month duration should be 1');
      assert.equal(results.get('days'), 11, 'Resulting day duration should be 11');
      assert.equal(results.get('hours'), 2, 'Resulting hour duration should be 2');
      assert.equal(results.get('minutes'), 29, 'Resulting minute duration should be 29');
      assert.equal(results.get('seconds'), 0, 'Resulting minute duration should be 0');
      assert.equal(results.get('milliseconds'), 0, 'Resulting millisecond duration should be 0');

      assert.equal(results.as('minutes'), 59189, 'Resulting total minute duration should be 59189');
      assert.equal(results.toString(), 'P1M11DT2H29M', 'Resulting ISO duration should be P1M11DT2H29M');
    });

    it('should work for durations spanning multiple months', function() {
      var start = '2014-03-14 13:01:01';
      var end = '2014-05-13 15:30:01';
      var results = Utils.getDurationBetween(start, end);

      // Month durations are under the assumption that the average month has 30 days.
      assert.equal(results.get('years'), 0, 'Resulting year duration should be 0');
      assert.equal(results.get('months'), 2, 'Resulting month duration should be 2');
      assert.equal(results.get('days'), 0, 'Resulting day duration should be 0');
      assert.equal(results.get('hours'), 2, 'Resulting hour duration should be 2');
      assert.equal(results.get('minutes'), 29, 'Resulting minute duration should be 29');
      assert.equal(results.get('seconds'), 0, 'Resulting minute duration should be 0');
      assert.equal(results.get('milliseconds'), 0, 'Resulting millisecond duration should be 0');

      assert.equal(results.as('minutes'), 86549, 'Resulting total minute duration should be 86549');
      assert.equal(results.toString(), 'P2MT2H29M', 'Resulting ISO duration should be P2MT2H29M');
    });

    it('should work for durations spanning multiple months and days', function() {
      var start = '2014-03-14 13:01:01';
      var end = '2014-05-24 15:30:01';
      var results = Utils.getDurationBetween(start, end);

      // Month durations are under the assumption that the average month has 30 days.
      assert.equal(results.get('years'), 0, 'Resulting year duration should be 0');
      assert.equal(results.get('months'), 2, 'Resulting month duration should be 2');
      assert.equal(results.get('days'), 11, 'Resulting day duration should be 11');
      assert.equal(results.get('hours'), 2, 'Resulting hour duration should be 2');
      assert.equal(results.get('minutes'), 29, 'Resulting minute duration should be 29');
      assert.equal(results.get('seconds'), 0, 'Resulting minute duration should be 0');
      assert.equal(results.get('milliseconds'), 0, 'Resulting millisecond duration should be 0');

      assert.equal(results.as('minutes'), 102389, 'Resulting total minute duration should be 102389');
      assert.equal(results.toString(), 'P2M11DT2H29M', 'Resulting ISO duration should be P2M11DT2H29M');
    });
  });
});
