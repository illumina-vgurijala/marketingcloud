({
	fetchTextHelper : function(component, event, helper) {
        let doc=component.get("c.fetchDynamicText"); 
        doc.setCallback(this,function(response){           
            if(component.isValid() && response.getState() === "SUCCESS"){
                component.set("v.strText",response.getReturnValue());
                let test=component.get("v.strText");
                console.log('test===='+test);
                
            }else{
                this.showErrorToast("Dynamic Text cannot be fetched!!");
            }
        });
        $A.enqueueAction(doc);
    }
})