({
    checkRecordRetrieved : function(component,helper) {//use helper since this cannot be used during callback
        let strError = component.get("v.strRecordError");
        if( !$A.util.isEmpty(strError) ){
            helper.showErrorToast('An unexpected error has occured please contact your system administrator: '+strError);
            return;//don't proceed since some error has occurred
        }
        let objProduct = component.get("v.objTargetProduct");//this is the Product record retrieved
        helper.consoleLog('Product retrieved',false,objProduct);
        
        //put all the Validations here
        helper.consoleLog('Submitting Product');  //using helper as using 'this' in callback below gives error
        console.log('objProduct==> ' +objProduct);
        console.log('config type==> ' +objProduct.Apttus_Config2__ConfigurationType__c);
        console.log('bundle channel==> ' +objProduct.Bundle_Channel__c);
        console.log('product status==> ' +objProduct.Product_Send_To_AEM_Status__c);
        
        let isValidProductRecord = false; 
        let bundleChannelValues = objProduct.Bundle_Channel__c;
        let productConfigType = objProduct.Apttus_Config2__ConfigurationType__c;
        let productAEMStatus = objProduct.Product_Send_To_AEM_Status__c;
        
        //check here for all the validations logic, if all validation successful then call ==> helper.submitToAEM(component,helper);
        if(!$A.util.isEmpty(bundleChannelValues) && productConfigType === 'Bundle' && bundleChannelValues.includes('online') )
            isValidProductRecord = true;
            
        if(isValidProductRecord){
            //if the product has not been sent already Or the previous attempts failed. Then allow callout again
            if(productAEMStatus === 'Failed' || productAEMStatus == null){
                helper.consoleLog('Validate successful. Do outbound call');
        		helper.submitToAEM(component,helper); 
            }else if( productAEMStatus === 'Publishing' ){
                helper.showErrorToast('Previous request is already In-process, Please try again in some time');
                return;
            }else if( productAEMStatus === 'Sent' ){
                helper.showErrorToast('Product has already been sent to AEM');
                return;
            }else{
                helper.showErrorToast('An unexpected error has occured please contact your system administrator');
                return;
            }
       		
       }else
       {
           //throw exception
           if( !(!$A.util.isEmpty(bundleChannelValues) && bundleChannelValues.includes('online')) && productConfigType != 'Bundle'){
               helper.showErrorToast('Bundle Channel should have Online Channel and Configuration Type should be Bundle');
           }else if( !(!$A.util.isEmpty(bundleChannelValues) && bundleChannelValues.includes('online')) ){
               helper.showErrorToast('Bundle Channel should have Online Channel');
           }else{
               helper.showErrorToast('Configuration Type should be Bundle');        
           }
           return;//don't proceed since some error has occurred
       }
    },
    submitToAEM : function(component,helper) {
        let strProductId = component.get('v.recordId');
        helper.callServer(component,"c.submitOutboundRequest",function(response){
            helper.consoleLog('Outbound call successful.');
            helper.redirectToPageURL('/'+strProductId);
        },{
            "strProductId" : strProductId
        });
    }
    
})