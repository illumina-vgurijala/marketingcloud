({
    handleClick:function(component,event,helper){
        
        component.set('v.columns', [
            { label: 'Title', fieldName: 'Title', type: 'text' },
            { label: 'FileType', fieldName: 'FileType', type: 'text' },
            {
                type: "button", 
                typeAttributes: {
                    iconName: 'action:preview',
                    label: 'Preview',
                    name: 'Preview',
                    title: 'Preview',
                    disabled: false,
                    value: 'Preview',
                    variant: 'brand'
                }
			}, 
            {
                type: "button", 
                typeAttributes: {
                    iconName: 'action:delete' ,
                    label: 'Delete',
                    name: 'Delete',
                    title: 'Delete',
                    disabled: false,
                    value: 'Delete',
                    variant: 'destructive'
                }
			} 
            
        ]);
        component.set("v.TableHeader",false);
        helper.server(component,helper);
        
        
    },
    handleUploadFinished: function (component, event,helper) {
        
        let objectname="Master_Data_Request__c";
        let view="view";
       	
        let pageReference;
        let params = {
            strMDRId : component.get("v.recordId")
           
        	};
              
        
        helper.callServer(component,"c.handlerFileUploadFinish",function(response){
          helper.showSuccessToast("Master Data Request Created","pester",100);
          pageReference = {
            	type: 'standard__recordPage',
                attributes: {
                    recordId: component.get("v.recordId"),
                    objectApiName:objectname,
                    actionName:view
                },
            
        }; 
        component.set("v.pageReference", pageReference);
        let navService = component.find("navService");
        event.preventDefault();
        navService.navigate(pageReference);
        },params);
        
    },
    
    handleRowAction:function(component,event,helper){
       let action = event.getParam('action');
        let row = event.getParam('row');
		
        switch (action.name) {
            case 'Preview':
                
                $A.get('e.lightning:openFiles').fire({
                    recordIds: [row.ContentDocumentId]
                });
                component.set("v.UploadFiles",true);
                break;
            case 'Delete':
                let docId=row.ContentDocumentId;
                let linkedid=component.get("v.recordId");
                let action = component.get("c.updateContentDocument");
                let params = { docId : docId,
                              linkedid : linkedid 	};
                helper.callServer(component,"c.updateContentDocument",function(response){
                    let res=response;
                    if(res.length === 0 ){
                            component.set("v.TableHeader",true);
                            component.set("v.lstContentDoc",res);
                        	component.set("v.UploadFiles",true);
                          
                     }
                    for(let i=0;i<res.length;i++){
                            res[i].Title=res[i].ContentDocument.Title;
                            res[i].FileType=res[i].ContentDocument.FileType;
                            component.set("v.lstContentDoc",res);
                     }
                },params);
				component.set("v.UploadFiles",true);                
                break;
        }
    }
    
    
})