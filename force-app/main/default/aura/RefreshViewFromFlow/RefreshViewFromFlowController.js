({
    invoke : function(component, event, helper) {
       let recordId = component.get('v.recordId');
       window.open('/lightning/r/Case/'+recordId+'/view','_self');
    }
})