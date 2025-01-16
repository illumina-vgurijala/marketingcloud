({
    getAllPromotions : function(component, helper) {
        //Calling base super component's helper method to call Aura Method
        helper.callServer(component, "c.getPromotions", 
        function(response)
        {
        	if(response)
            {
                component.set("v.promotions", response);
                //Calling showSuccessToast method of Base Super component
                helper.showSuccessToast
                (
                	"Promotions are loaded",
                    "dismissible",
                    "200"
                );
             }
            else{
                helper.showErrorToast("There are no promotions currently available.");
            }
        });
    },
})