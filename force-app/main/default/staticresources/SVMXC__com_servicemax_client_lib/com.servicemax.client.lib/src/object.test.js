describe('Object', function() {
  var object = SVMX.create('com.servicemax.client.lib.api.Object');

  it('getClassName()', function() {
    assert.equal(object.getClassName(), 'Object', 'Object = Object; equal succeeds');

    //bad
    assert.notEqual(object.getClassName(), 'Objects', 'Object != Objects; not equal succeeds');
  });

  it('toString()', function() {
    assert.equal(object.toString(), 'Object', 'Object = Object; equal succeeds');

    //bad
    assert.notEqual(object.toString(), 'Objects', 'Object != Objects; not equal succeeds');
  });
});
