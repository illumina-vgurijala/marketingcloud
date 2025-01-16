({
    acceptppmValue : function(component,event) {
        let lstWrapGlobalLang = [];
        let args=event.getParam("arguments");
        let sPpmVal=args.strPpmVal;
        let sProposalId=args.strProposalId;
        let helper=this;
        helper.callServer(component,"c.populateGlobalLanguageOnChange",function(response){
            let lstGlobalLang = JSON.parse(response);
            component.set("v.lstStrTemp",JSON.parse(response));
            lstGlobalLang.forEach(function(iValue, iIndex){
                if(iValue.sType == 'static'){
                    iValue.sValue=iValue.sValue.replace(/\n|\r\n|\r/g, '<br/>') ;
                }
                lstWrapGlobalLang.push(iValue);
            });
            component.set("v.strGlobalLang",lstWrapGlobalLang);
            
        },{
            "strPpmValue": sPpmVal,
            "strProposalId": sProposalId
        });
    },
    
    validate : function(component,sProposalId,sPpmVal){
        let helper=this;
        let lstStrTemp=component.get("v.lstStrTemp");
        let lstGlobalLang=component.get("v.strGlobalLang");
        let sConcatenatedVal='';
        lstGlobalLang.forEach(function(iValue,iIndex){
            if(iValue.sType=='static') { //codescanfix-A conditionally executed single line should be denoted by indentation
                sConcatenatedVal=sConcatenatedVal.concat(lstStrTemp[iIndex].sValue);
            }
            else{
                sConcatenatedVal=sConcatenatedVal.concat(iValue.sValue);    
            }
         });
        let booFocused = false;
        let strArray = component.find('fieldId');
        let allValid = false;
        if(Array.isArray(strArray)){
                allValid = strArray.reduce(function (validSoFar, inputCmp) {
                if(!booFocused && inputCmp.get('v.validity').valueMissing){
                    booFocused = true;
                    inputCmp.focus();
                }
                	  
                return validSoFar && !inputCmp.get('v.validity').valueMissing;
            }, true);
        }
        if(!Array.isArray(strArray) && !$A.util.isUndefined(component.find('fieldId'))){
            if(!booFocused && strArray.get('v.validity').valueMissing){
                allValid = false;
                booFocused = true;
                strArray.focus();
            }
            else{
                allValid = true; 
            }
        }
        if ((allValid || $A.util.isUndefined(component.find('fieldId'))) && !$A.util.isEmpty(sConcatenatedVal)) {
            return sConcatenatedVal;
        } 
        else{
            return 'error';
        }
    }
})