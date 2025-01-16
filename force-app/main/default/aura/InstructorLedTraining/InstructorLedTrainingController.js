({
    doInit : function(component, event, helper) {
        helper.launchTrainingCourses(component,event,helper);
        helper.fetchListViewId(component, event, helper);
    },
    
    resetTrainingCourses : function(component, event, helper) {
        helper.resetTrainingList(component,event,helper);
        helper.launchTrainingCourses(component,event,helper);
    },
    handleSelection : function(component, event, helper){
        let trainings = component.get("v.trainings");
        let currentSelection = event.getParam("selectedTrainings");
        let isSelected = event.getParam("isSelected");
        let selected = [];
        if(component.get("v.lstTraining") !== undefined){
            selected = component.get("v.lstTraining");
        }
        for(let i=0;i<trainings.length;i++){
            if(trainings[i].Certification__c === currentSelection){
                if(isSelected){
                    selected.push(currentSelection);
                }else{
                    selected.splice(i,1);
                }
            }
        }
        component.set("v.lstTraining",selected);
    },
    saveTrainingDetails : function(component, event, helper){
        helper.saveTrainingCourses(component, event, helper);       
    }
})