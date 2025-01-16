var app = SVMX.getCurrentApplication();
var page;
QUnit.module("ExternalRequestValidator", {
    setup: function() {
        //initialize code
    },
    teardown: function() {
        //cleanup code
        if(app){
        	app.updateDependentRecords.restore();
        	app.errorFromMFL.restore();	
        }
        
        if(page)
        	page.onSaveComplete.restore();
    }
});

test("External Response Validator", function(){
	var client = SVMX.getClient();
	var noErrorCovered = false;
	var errorCovered = false;

	sinon.stub(app, "updateDependentRecords", function(){
		noErrorCovered = true;
	});
	
	sinon.stub(app, "errorFromMFL", function(){
		errorCovered = true;
	});

	var data = {
		action : "SYNC",
		operation : "INSERT_LOCAL_RECORDS",
		type : "RESPONSE",
		data : {
			insertRecordsMap : {}
		}
	};
	app.externalMessage(data);
	equal(noErrorCovered, true, "MFL returened without any error");

	data.data.error = "Error from MFL";
	app.externalMessage(data);

	equal(errorCovered, true, "MFL returned with Error");
});

test("After Save Record Create Dependent Entry", function(){
	app = null;
	page = SVMX.create("com.servicemax.client.installigence.record.PageLayout", {objectName : 'SVMXC__Installed_Product__c', root: {}});
	var dependentEntryCreated = false;
	//debugger;
	sinon.stub(page, "onSaveComplete", function(){
		dependentEntryCreated = true;	
	});

	page.onSaveComplete({});
	equal(dependentEntryCreated, true, "Save Completed with the Dependent Entry Table.");
});