/*****************************************************************************************************************
* Class Name: AsyncAfterUpdate_InstalledProductHelper
* Description: Helper class for processing Installed Product on After Update asynchronusly.
* 
* Author: Raviteja Vakkalagadda
* Date: 28-Mar-2022
* 
* Notification Log:
* -------------------------------------------------------------------------------------------------------------
* Developer                  Date                              Description
* -------------------------------------------------------------------------------------------------------------
* Raviteja Vakkalagadda      28-Mar-2022      Helper class for processing Installed Product on After Update asynchronusly.
* Sagar Madkaikar            21-Jul-2022      DCP-54367 : Added method getIPsForLRMPatchUpdate() to check Product Change on IP. Called IBTechnicalAttributeLRMQueueable class to perform LRM patch
* 
******************************************************************************************************************/
public class AsyncAfterUpdate_InstalledProductHelper {
    
    public static Set<Id> setIPIDsForLRMPatch = new Set<Id>();//DCP-54367
    public static final String LRM_PATCH_FEATURE ='LRM_Patch_Feature';//DCP-54367

/*
* @description: Method to send Installed Product to SAP
* @author: Raviteja Vakkalagadda
* @date: 03/28/2022
* @returns: void
*/
    
    public static void sendIPToSAP(Set<Id> setInstalledProductIds,Set<Id> setAssetUpdatedInstalledProductIds, List<SVMXC__Installed_Product__c> lstNewInstalledProduct,Map<Id, SVMXC__Installed_Product__c> mapOldInstalledProduct) {
        
        ilib_Queueablethread  queueableThread=new ilib_Queueablethread('installedProductAfterUpdate');
        
        if(!setInstalledProductIds.isEmpty() && !system.isBatch()) {
            sendInstalledProductToSAP(setInstalledProductIds);
        }
        //DCP-28892
        if (!setInstalledProductIds.isEmpty() && system.isBatch()) {
            queueableThread.logandQueue(new InstalledProductQueueable('batchsendInstalledProductToSAP', null, null, null,setInstalledProductIds ),'InstalledProductQueueable','batchsendInstalledProductToSAP');
        }
        //DCP-43163
        if(!setAssetUpdatedInstalledProductIds.isEmpty()) {
            queueableThread.logandQueue(new InstalledProductQueueable('runBillingRuleEngine', null, null, null,setAssetUpdatedInstalledProductIds ),'InstalledProductQueueable','runBillingRuleEngine'); 
        }

        //START: DCP-54367
        if (Feature.isOn(LRM_PATCH_FEATURE)){
            setIPIDsForLRMPatch = getIPsForLRMPatchUpdate(lstNewInstalledProduct,mapOldInstalledProduct);
            if(!setIPIDsForLRMPatch.isEmpty()){
                queueableThread.logandQueue(new IBTechnicalAttributeLRMQueueable('updateTAInstanceOnIPProductChange',setIPIDsForLRMPatch ),'IBTechnicalAttributeLRMQueueable','updateTAInstanceOnIPProductChange');
            }
        }
        //END : DCP-54367
        if(queueableThread != null && !queueableThread.lstQueueableJobs.isEmpty()) {
            ilib_QueueableManager.enqueueJob(queueableThread,ilib_LogEvent.SERVICE);
        }
    }
    
/*
* @description: Method to make an outbound integration to SAP for sending Installed Product
* @date: 03/28/2022
* @returns: void
* DCP-905
*/
    @future(callout = true)
    public static void sendInstalledProductToSAP(Set<Id> setInstalledProductIds) {
        InstalledProducts.batchsendInstalledProductToSAP(setInstalledProductIds);
    }

    /**
     *  @AUTHOR Sagar Madkaikar
     *  @DESCRIPTION - DCP-54367 : getIPsForLRMPatchUpdate() : This method will filter IP records whose Product is changed 
     *  @DATE - 20-Jul-2022 
     *  @PARAM : List<SVMXC__Installed_Product__c> lstNewInstalledProduct,Map<Id, SVMXC__Installed_Product__c> mapOldInstalledProduct
     *  @RETURN : Set<Id> : Set of Installed Product IDs whose Product is changed.
     **/
    public static Set<Id>  getIPsForLRMPatchUpdate(List<SVMXC__Installed_Product__c> lstNewInstalledProduct,Map<Id, SVMXC__Installed_Product__c> mapOldInstalledProduct){
        Set<Id> setIPWithPRoductChange = new Set<Id>();
        for(SVMXC__Installed_Product__c ipRec : lstNewInstalledProduct)
        {
            if(ipRec.SVMXC__Product__c!=null & ipRec.SVMXC__Product__c!=mapOldInstalledProduct.get(ipRec.Id).SVMXC__Product__c){
                setIPWithPRoductChange.add(ipRec.Id);
            }
        }
        return setIPWithPRoductChange;
    }
}