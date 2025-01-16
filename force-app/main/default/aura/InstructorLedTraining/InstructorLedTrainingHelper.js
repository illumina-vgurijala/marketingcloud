({
    launchTrainingCourses : function(component, event, helper) {
        helper.callServer(component,"c.getTrainingList",function(response){
            if(response.length !== 0){
                component.set("v.trainings",response);
            }else{
                helper.showErrorToast("Currently there are no trainings available for registration...");
            }
            
        });
    },
    
    fetchListViewId : function (component, event, helper){
        helper.callServer(component,"c.getListViewId",function(response){
            component.set("v.listViewId",response.getReturnValue());
        },{
            "strObjectType" : $A.get("$Label.c.Partner_Request_Obj"),
            "strListViewName" : $A.get("$Label.c.Instructor_Led_Training_List_View_Name")
        });
    },
    
    resetTrainingList : function(component, event, helper){
        let crsJust = undefined;
        let tmForAtt = undefined;
        component.set("v.courseJustification",crsJust);
        component.set("v.timeFrameForAttendance",tmForAtt);
        let listTraining = [];
        component.set("v.lstTraining", listTraining);
    },
    
    saveTrainingCourses : function(component, event, helper){
        let courseListSelected = component.get("v.lstTraining");
        let timeForAttendance = component.get("v.timeFrameForAttendance");
        let courseJustification =  component.get("v.courseJustification");
        if(courseListSelected.length !== 0){            
            if(timeForAttendance !== undefined && courseJustification !== undefined){
                helper.callServer(component,"c.saveTrainingCourses",function(response){
                    if(response === ''){
                        helper.showToast("Saved","The record was saved successfully.","success","dismissible","200");
                        helper.resetTrainingList(component,event,helper);
                        helper.launchTrainingCourses(component,event,helper);
                        
                        let navEvent = $A.get("e.force:navigateToList");
                        navEvent.setParams({
                            "listViewId": component.get("v.listViewId"),
                            "listViewName": null,
                            "scope": $A.get("$Label.c.Partner_Request_Obj")
                        });
                        navEvent.fire();
                    }else{
                        helper.showErrorToast(response); 
                    }
                },{
                    "strCoursesSelected" : courseListSelected.join('\n'),
                    "strTimeForAttendance" : timeForAttendance,
                    "strCourseJustification" : courseJustification,
                    "strObjApiName" : $A.get("$Label.c.Partner_Request_Obj"),
                    "strRecordTypeName" : "Instructor-Led Training Request"
                });
            }else{
                component.find('courseJust').focus();
                component.find('timeForFrameAttend').focus();
                helper.showErrorToast("Please enter all mandatory fields before proceeding to save...");
            }
            
        }else{
            helper.showErrorToast("Select atleast one course before proceeding to save...");
        }
        
    }
    
})