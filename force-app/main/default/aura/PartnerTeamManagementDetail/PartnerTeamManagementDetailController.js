({  
    redirectToDetailPage : function(component, event, helper){
        let selectedItem = event.currentTarget;
        let selectedContactId = selectedItem.dataset.record;
        
        let urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "url": '/contact/'+selectedContactId,
            "isredirect" :false
        });
        urlEvent.fire();
    }
})