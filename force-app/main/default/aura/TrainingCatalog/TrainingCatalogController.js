({
	trainingSelected : function(component, event, helper) {
        let trainingEvent = component.getEvent("trainingSelection");
        let selectedTrainings = component.find("selection").get("v.value").Certification__c;
        let  isSelected= component.find("selection").get("v.checked");
        if(isSelected){
            component.set("v.selectedTrainings",selectedTrainings);
            component.set("v.isSelected",true);
        }else{
            component.set("v.selectedTrainings",selectedTrainings);
            component.set("v.isSelected",false);
        }
        
        trainingEvent.setParams({
            "selectedTrainings" : component.get("v.selectedTrainings"),
            "isSelected" : component.get("v.isSelected")
        });
        trainingEvent.fire();
	}
})