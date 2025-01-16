({
    doInit : function(component, event, helper) {
        $('.carousel').carousel({
            interval: 10000
        })
        
       helper.callLoadCarousel(component, event, helper);
    }, 
})