// Method for getting slides and carousel
({
	callLoadCarousel : function(component, event, helper) {
        helper.callServer(component,"c.loadCarousel",function(response){
            let ErrorMsg;
            if(response.length !== 0){
                console.log(JSON.stringify(response));                   
                component.set("v.varPartnerPortalContentWrapper",response);
                let getData=component.get("v.varPartnerPortalContentWrapper");
                component.set("v.lstSlides",getData.lstCopySlides);
                component.set("v.lstSlides",getData.lstCopySlides);
                console.log(JSON.stringify(getData.lstCopySlides));
                ErrorMsg=component.get("v.varError");
                let SlidesList=component.get("v.lstSlides");
                let cssBackgroundImage;
                if (typeof(SlidesList) != 'undefined') {
                    for (let i = 0; i < SlidesList.length; i++) {
                    cssBackgroundImage="background: url("+SlidesList[i].Image_URL__c+");background-repeat: no-repeat;background-size: cover; background-position: center; linear-gradient(to top left, #cec4c4 -17%, #ffffff 97%);";
                	SlidesList[i].ImageCSS__c = cssBackgroundImage;
                	}
                }
                
                component.set("v.lstSlides",SlidesList);
                let checkData = component.get("v.lstSlides");
                                
            }if(ErrorMsg!=''){
                this.showErrorToast(ErrorMsg);
            }
        });
	},
})