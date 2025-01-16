({
    doSave: function(component, event, helper) {
        if (component.find("fileId").get("v.files").length > 0) {
            let fileInput = component.find("fileId").get("v.files");
            let file = fileInput[0];
            let FileType=file.type;
            
            // DCP-51320: Allowing csv files from Mac system to be accepted as well for product notification
            console.log('FileType: ' + FileType);
            if (FileType === "application/vnd.ms-excel" || FileType === "text/csv") {
                helper.uploadHelper(component, event);
            }
            else {
                alert('Please Select a Valid File');
            }
            
        } else {
            alert('Please Select a Valid File');
        }
    },
 
    handleFilesChange: function(component, event, helper) {
        let fileName = 'No File Selected..';
        if (event.getSource().get("v.files").length > 0) {
            fileName = event.getSource().get("v.files")[0]['name'];
        }
        component.set("v.strFileName", fileName);
    },
})