({
   selectRecord : function(component, event, helper){      
    // get the selected record from list 
    //console.log('Selected is--'+JSON.stringify("v.oRecord")) ;
	let getSelectRecord = component.get("v.objORecord");
    console.log('testing--'+JSON.stringify(getSelectRecord)+'--'+getSelectRecord.Id);
    // call the event   
    let compEvent = component.getEvent("oSelectedRecordEvent");
    // set the Selected sObject Record to the event attribute.  
    compEvent.setParams({"objRecordByEvent" : getSelectRecord });  
    // fire the event  
    compEvent.fire();
    },
})