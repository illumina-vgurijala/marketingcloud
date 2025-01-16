({handleRecordUpdated: function(component, event, helper) {
        let eventParams = event.getParams();
        if(eventParams.changeType === "LOADED") {
           // record is loaded (render other component which needs record data value)
            console.log("Record is loaded successfully.");
            let instrumentId = component.get("v.simpleRecord.SVMXC__Serial_Lot_Number__c");  
            console.log(instrumentId);
            console.log($A.get('$Label.c.Proactive_Base_URL'));
            //set the iframe src.
            //component.set("v.iframesrc", 'https://compass.cloud-test.illumina.com/Thingworx/Runtime/index.html#mashup=Proactive.DCPInstrumentFrame.MU&amp;instrumentId='+instrumentId);
            //component.set("v.iframesrc", 'https://compass.cloud-test.illumina.com/Thingworx/Runtime/index.html#mashup=Proactive.DCPInstrumentFrame.MU&instrumentId='+instrumentId);
			component.set("v.iframesrc", $A.get('$Label.c.Proactive_Base_URL')+ 'instrument/'+instrumentId+'?view=DCP');
		} else if(eventParams.changeType === "CHANGED") {
            // record is changed
        } else if(eventParams.changeType === "REMOVED") {
            // record is deleted
        } else if(eventParams.changeType === "ERROR") {
            // there’s an error while loading, saving, or deleting the record
        }
    }
})