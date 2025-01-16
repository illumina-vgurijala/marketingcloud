describe('Event', function() {
  var type = 'com.servicemax.client.lib.api.Event';
  var target = this;
  var data =  {
    request : {},
    responder : {}
  };

  var event = SVMX.create('com.servicemax.client.lib.api.Event', type, target, data);

  it('Properties check', function() {
    var type = 'com.servicemax.client.lib.api.Event',
      data =  {
        request : {},
        responder : {}
      },
      error = {
        error:{},
        message:{}
      };

    assert.equal(event.type, type, 'type = com.servicemax.client.lib.api.Event; equal succeeds');
    assert.ok(event.target === target, 'target = this; equal succeeds');
    assert.deepEqual(event.data, data, 'data = {request:{},responder:{}}; equal succeeds');

    //bad
    assert.notEqual(event.type, 'blah', 'type != blah; not equal succeeds');
    assert.ok(event.target !== window, 'target != window; not equal succeeds');
    assert.notDeepEqual(event.data, error, 'data != {error:{}, message:{}}; not equal succeeds');
  });
});
