({
    onRender: function (component, event, helper){ 
        console.log('dispatching custom event');
        document.dispatchEvent(new CustomEvent("OneTrustButtonEnable"));
    }
})
