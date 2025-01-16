
var stateService;
var stateChangeCalled;

QUnit.module("StateManager", {
    setup: function() {
        stateService = SVMX.create('com.servicemax.client.sfmconsole.utils.StateService');
        stateService.triggerStateChange = function(eventName) {
            stateChangeCalled = eventName || 'STATE_CHANGE';
        };
    },
    teardown: function() {
        stateService = null;
        stateChangeCalled = false;
    }
});

test("constructor", function() {
    equal(stateService.getState(), undefined, 'State stack is empty');
    equal(stateService.getIndex(), 0, 'State index is zero');
});

test("pushState", function() {
    var pushedState = stateService.pushState({
        title: "test",
        subtitle: "subtest"
    });
    var currentState = stateService.getState();
    equal(pushedState.title, 'test', 'State property exists');
    equal(currentState.title, pushedState.title, 'Current state title is set');
    equal(stateChangeCalled, 'STATE_CHANGE', 'State change event triggered');
});

test("replaceState", function() {
    var origState = stateService.pushState({
        title: 'test1'
    });
    var newState = stateService.replaceState({
        title: 'test2'
    });
    var currentState = stateService.getState();
    equal(origState.index, newState.index, 'New state has same index as orig');
    equal(currentState.title, 'test2', 'Current state title should be replaced');
    equal(stateChangeCalled, 'STATE_CHANGE', 'State change event triggered');
});

test("modifyState", function() {
    var origState = stateService.pushState({
        title: 'test1'
    });
    var modState = stateService.modifyState({
        title: 'test2'
    });
    var currentState = stateService.getState();
    equal(origState.index, modState.index, 'New state has same index as modified');
    equal(currentState.title, 'test2', 'Current state title should be replaced');
    equal(stateChangeCalled, 'STATE_MODIFIED', 'State change event triggered');
});

test("getState", function() {
    var pushedState = stateService.pushState({
        title: 'test',
        subtitle: 'subtest'
    });
    var currentState = stateService.getState();
    equal(currentState.title, pushedState.title, 'State title is the same as pushed');
    equal(currentState.index, pushedState.index, 'State index is the same as pushed');
});

test("getIndex", function() {
    stateService.pushState({
        title: 'test1'
    });
    stateService.pushState({
        title: 'test2'
    });
    var currentIndex = stateService.getIndex();
    equal(currentIndex, 1, 'Current index is 1 after 2 state pushes');
});

test("back", function() {
    stateService.pushState({
        title: 'test'
    });
    stateService.pushState({
        title: 'test2'
    });
    stateService.back();
    var currentIndex = stateService.getIndex();
    equal(currentIndex, 0, 'State index is 0 after back');
    equal(stateChangeCalled, 'STATE_CHANGE', 'State change event triggered');
});

test("forward", function() {
    stateService.pushState({
        title: 'test'
    });
    stateService.pushState({
        title: 'test2'
    });
    stateService.back();
    stateService.forward();
    var currentIndex = stateService.getIndex();
    equal(currentIndex, 1, 'State index is 1 after back and forward');
    equal(stateChangeCalled, 'STATE_CHANGE', 'State change event triggered');
});

test("go", function() {
    stateService.pushState({
        title: 'test'
    });
    stateService.pushState({
        title: 'test2'
    });
    stateService.go(-1);
    var currentIndex = stateService.getIndex();
    equal(currentIndex, 0, 'State index is 0 after go');
    equal(stateChangeCalled, 'STATE_CHANGE', 'State change event triggered');
});
