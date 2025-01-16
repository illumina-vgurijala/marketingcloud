/**
* @author Shivani Jain
* @date 8th Nov 2022
*
* @description DCP-54018 Queueable Class for Work Order trigger to Partner Flag for VAD Accounts
*/ 
public class PartnerFlagVDQueueable_WOHelper implements Queueable {

    List<SVMXC__Service_Order__c> lstWorkOrders = new List<SVMXC__Service_Order__c>();

    /*******************************************************************************************************
    * @description Constructor
    * @param lstWorkOrders List<SVMXC__Service_Order__c>
    * @return
    */
    public PartnerFlagVDQueueable_WOHelper(List<SVMXC__Service_Order__c> lstWorkOrders) {
        this.lstWorkOrders = lstWorkOrders;
    }

    /*******************************************************************************************************
    * @description Execute method
    * @param QueueableContext qc
    * @return
    */
    public void execute(QueueableContext qc) { 
        try {
            updatePartnerWOFlagForVADAccount(lstWorkOrders);
        } catch(Exception ex) {
            ApexExceptions.emit('PartnerFlagVDQueueable_WOHelper.'+ 'updatePartnerWOFlagForVADAccount', ex);
            throw ex;
        }
       
    }

    /*
    * @author Nishan Shetty [CMCP-23]
    * @date   27-Aug-2021
    * @description: The method is used to set Partner Work Order Flag for Value Added Distributor assigned Territory Account.
    *               This method is called from Work Order Queueable class because Work Order Account is Set in Before Context
    *               in some cases and not in others .It has account already set.
    * @Param lstCampaignMember: list of Work Order.
    * @return:None
    */
    public static void updatePartnerWOFlagForVADAccount(List<SVMXC__Service_Order__c> lstWorkOrders) {
        ilib_LogEvent.push(WorkOrders.LOG_TITLE + '.updatePartnerWOFlagForVADAccount()');  
        Map<Id,String> mapAccountIdToTerritoryType =new Map<Id,String>();
        Set<Id> setAccountIds=new Set<Id>();
        List<SVMXC__Service_Order__c> lstWorkOrderToUpdate=new List<SVMXC__Service_Order__c>();
  
        for(SVMXC__Service_Order__c objWO:lstWorkOrders) {
            setAccountIds.add(objWO.SVMXC__Company__c);
        }
        
        ilib_LogEvent.message('setAccountIds:'+setAccountIds);

        if(!setAccountIds.isEmpty()) {
            mapAccountIdToTerritoryType=TerritoryTypesService.getAccountToTerritoryTypeMap(setAccountIds);
        }
        ilib_LogEvent.message('CPAccountToTerritoryMap:'+mapAccountIdToTerritoryType);
        
        
  
        for(SVMXC__Service_Order__c objWorkOrder:lstWorkOrders) {
            if(mapAccountIdToTerritoryType.containsKey(objWorkOrder.SVMXC__Company__c) 
            && mapAccountIdToTerritoryType.get(objWorkOrder.SVMXC__Company__c)==TerritoryTypesService.TYPE_TERRITORY_VAD_CP
            && !objWorkOrder.Partner_Work_Order__c) {
              //Creating new instance to update the record.  
              SVMXC__Service_Order__c objNewWorkOrder=new SVMXC__Service_Order__c();
              objNewWorkOrder.Partner_Work_Order__c=true;
              objNewWorkOrder.Id=objWorkOrder.Id;
              lstWorkOrderToUpdate.add(objNewWorkOrder);
            }
            ilib_LogEvent.message('PartnerWOFlagInQueueable:'+objWorkOrder.Partner_Work_Order__c);
        }
  
        ilib_LogEvent.message('lstWorkOrderToUpdate:'+lstWorkOrderToUpdate);
        
        if(!lstWorkOrderToUpdate.isEmpty()) {
            update lstWorkOrderToUpdate;
        }
        ilib_LogEvent.pop();
    }  
}
