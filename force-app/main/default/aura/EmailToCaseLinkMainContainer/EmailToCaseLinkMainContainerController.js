({
    doInit: function(component, event, helper) {
    //check if the relatedToId is Case and not any other object.
    helper.fetchRelatedToObjectName(component);    
    },
     searchClicked: function(component, event, helper) {
        
        //map to hold caseIdToEmailMessageId
        let mapToSend = {}

        //find autocomplete component using aura id
        const autoCompleteComponent = component.find("case-record");
        let searchBoxValue = autoCompleteComponent.get("v.selectedOption");
        console.log('searchBoxValue  ' +searchBoxValue);
        
        if (autoCompleteComponent) {
            
            //get selected option from auto complete component's selectedOption attribute
            const selectedOption = autoCompleteComponent.get("v.selectedOption");
            //set selected value in component attribute
            component.set("v.selectedValue", selectedOption);

        }
		
        if(!$A.util.isEmpty(searchBoxValue)){
        
        //populate the javaScript Map
        mapToSend[component.get("v.selectedValue")] = component.get("v.recordId");
        //populate the Map attribute
        component.set("v.caseIdToEmailMessageId", mapToSend);
		console.log('mapToSend == ' + JSON.stringify(mapToSend));
        
        //helper method : to move the email message to selected case.
        helper.moveToExisitingCase(component);    
            
        } else {
        helper.showNotification(component, 'warning', 'Invalid Case', 'Invalid Case selected. Kindly select a Case from the dropdown and Submit again.');   
       }
        

    }
})