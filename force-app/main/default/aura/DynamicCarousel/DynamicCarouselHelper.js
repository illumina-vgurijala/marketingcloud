// Method for getting slides and carousel
({
	callloadCarousel : function(component) {       
        let doc=component.get("c.loadCarousel");
        doc.setCallback(this,function(response){           
            if(component.isValid() && response.getState() === "SUCCESS"){
                component.set("v.SlidesArr",response.getReturnValue());
            }else{
				console.log('fetchCarousel false');
                this.showErrorToast("Something went wrong!!");
            }
        });
        $A.enqueueAction(doc);
	}
})