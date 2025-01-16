({
	doInit : function(component, event, helper) {
		//Calling loadData of helper to fetch records.
		helper.loadData(component);
	},
    
    createRelatedCode : function(component, event, helper){
        //Calling Create Record function of helper to initiate the RecordCreate event
        let selectedMenuItem = event.getParam("value");
        if(selectedMenuItem == "New"){
            helper.createRecordcall(component,event);
        }
    },
    
    openRecordDetail : function(component, event, helper) {
		//Calling openRecordDetail of helper to open OOTB record detail page.
		helper.openRecordDetail(component,event);
	},
    
    editRecordDetail : function(component, event, helper){
        helper.editRecordDetail(component, event);
    }
})