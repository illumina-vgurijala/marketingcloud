/***************************************************************************************************************************************
 * NAME   : WorkOrderQueueableNonSharing
 * DESCRIPTION  :Queueable class on  workorder object in non sharing context
 * Test Class for 75% coverage : 	TestWorkOrders
 * Test Class for 90% coverage : 	TestWorkOrders      
 *    
 * @AUTHOR : KD
 * @DATE   : 2-July-2021 
 *
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 * KD                   2-July-2021          Initial Version
 * Anshaj               21-Sep-2022          Cmsi-364 Instrumentation of class according to framework guidelines
****************************************************************************************************************************************/
public without sharing class WorkOrderQueueableNonSharing implements Queueable{
    private static final String LOG_TITLE = 'WorkOrderQueueableNonSharing';
    String strMethodtoExecute;
    Set<Id> setRecordId = new Set<Id>();
    
    /*constructor for calling linkFieldActionItemsFromCase method*/
    public WorkOrderQueueableNonSharing(String strMethodtoExecute,Set<Id> setRecordId) {    
        this.strMethodtoExecute = strMethodtoExecute;
        this.setRecordId=setRecordId;
    }
    /* Execute method*/
    public void execute(QueueableContext qc){
        ilib_LogEvent.setTitle(LOG_TITLE, ilib_LogEvent.SERVICE);
        ilib_LogEvent.push(LOG_TITLE+'execute()');
        try{
            //DCP-38816
            if(String.isNotBlank(strMethodtoExecute) && strMethodtoExecute== 'updateOpportunityAbandoned' && setRecordId!=null && !setRecordId.isEmpty()){
                    ilib_LogEvent.info(LOG_TITLE+'updateOpportunityAbandoned()');
                    List<SVMXC__Service_Order__c> lstWO  = [Select Id, Name, SVMX_PS_Subject__c, Abandoned_Reason__c, Opportunity__c, Opportunity__r.Owner.Email, SVMXC__Component__r.Name,Estimated_Quote_Amount__c,CurrencyIsoCode,Opportunity__r.name,Opportunity__r.AccountId,Opportunity__r.Account.Name From SVMXC__Service_Order__c Where Opportunity__c IN :setRecordId];
                    Map<Id,List<SVMXC__Service_Order__c>> mapOpportuntinyToLstWO = utilsCollection.getMapOfIdToSObjects(lstWO,'Opportunity__c');
                    OpportunitiesService.updateOpportunityAbandoned(mapOpportuntinyToLstWO);
            }
            
        }
        catch(Exception e){
			ilib_LogEvent.error('Exception occured in:WorkOrderQueueableNonSharing' +e);
			ilib_LogEvent.pop();
            ilib_LogEvent.emit();
			ApexExceptions.emit(LOG_TITLE,(new List<Id>(setRecordId))[0],e, ilib_LogEvent.SERVICE);
			}
            ilib_LogEvent.pop();
            ilib_LogEvent.emit();
    }
}