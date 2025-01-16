({
    uploadHelper: function(component, event){
        component.set("v.boolShowLoadingSpinner", true);
        //var fileInput = component.find("fileId").getElement();
        let fileInput = component.find("fileId").get("v.files");
       	let file = fileInput[0];
        let FileType=file.type;
		console.log('File type--',FileType);        
       	let self = this;
        let reader = new FileReader();       
        //console.log('action is--'+action);
        reader.onload = $A.getCallback(function()  {
        console.log('Result',JSON.stringify(reader.result));
        let str=encodeURIComponent(reader.result);
        //component.set("v.Str",str);
        let action = component.get("c.processFileContents");
        action.setParams({
            strfilecontents: encodeURIComponent(reader.result)          
        });
        action.setCallback(this, function(response) {
            let state = response.getState();
            console.log('State is-',state);
            if (state === "SUCCESS"){
                component.set("v.boolShowLoadingSpinner", false);
                //component.set("v.Str",response.getReturnValue());
                component.set("v.ProcessFileDataMap",response.getReturnValue());
            }
        });
        $A.enqueueAction(action);
		});
         reader.readAsText(file);
		//$A.enqueueAction(action);
        //console.log("Component is--"+component.get("v.Str"));
        let etcompEventFileSelected = component.getEvent("etFileSelected");
        etcompEventFileSelected.setParams({"FileSelected" : "True" }); 
		etcompEventFileSelected.fire();
    }
})