({
	
    server:function(component,helper){
        let linkedid=component.get("v.recordId");
        let action=component.get("c.updateContentDocument");
        action.setParams({ docId : '',
            linkedid : linkedid });
            let params = {
            docId : '',
            linkedid : linkedid
        	};
        helper.callServer(component,"c.updateContentDocument",function(response){
             console.log(response);
            //response=JSON.parse(response);
            let res=response;
           
                for(let i=0;i<res.length;i++){
                    res[i].Title=res[i].ContentDocument.Title;
                     res[i].FileType=res[i].ContentDocument.FileType;
                }
           	console.log("res--",res);
            component.set("v.TableHeader",false);
            component.set("v.lstContentDoc",res);
            
            
        }
                          
        ,params);
    } 
	
})