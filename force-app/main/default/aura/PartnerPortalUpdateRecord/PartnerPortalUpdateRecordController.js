({
    doInit : function(component, event, helper) {
        try{
            helper.doinitHelper(component, event, helper);               
        }
        catch(err){
            console.log('Status error' + err.message);
        }
        
    }
})