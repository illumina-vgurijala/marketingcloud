/***************************************************************************************************************************************
    * NAME   : UpdateQuoteAmountOnWO
    * DESCRIPTION  : Logic for updating work order when quote amount is changed
    *                    
    * @AUTHOR : Akshay Mohan
    * @DATE   : 04-May-2021  
    *
    * @Test Class for 75% Coverage : TestUpdateQuoteAmountOnWO
    * @Test Class for 90% Coverage : TestUpdateQuoteAmountOnWO
    * 
    * MODIFICATION LOG: 
    * -----------------------------------------------------------------------------------------------------------------------------------------------------------
    * DEVELOPER                DATE                DESCRIPTION 
    * ------------------------------------------------------------------------------------------------------------------------------------------------------------
    * Akshay Mohan             04-May-2021          Initial Version. 
    * Adyasha Satapathy        20-May-2021          DCP-47185: Defect Fix
    * Anshaj Sinha             16-Sep-2022          CMSI-204 Instrumented class with latest changes in Logging Framework
******************************************************************************************************************************************************************/
public with sharing class UpdateQuoteAmountOnWO implements ilib_AdminOperationLogicInterface{
    private static final String LOG_TITLE = 'UpdateQuoteAmountOnWO';
    /**
     *  @author       : Akshay Mohan
     *  @description  : Update quote amount on work order using platform event
     *  @return       : void
     */
    public static void doBusinessLogic(List<Id> lstQuoteIds){
        ilib_LogEvent.setTitle(LOG_TITLE, ilib_LogEvent.SALES);  
        ilib_LogEvent.push(LOG_TITLE + '.doBusinessLogic()');
        List<SVMXC__Service_Order__c> lstWO = new List<SVMXC__Service_Order__c>();
        try{
            for(Apttus_Proposal__Proposal__c objProp : new ApttusProposalsSelector().selectById(new Set<Id>(lstQuoteIds))){
                lstWO.add(new SVMXC__Service_Order__c(Id=objProp.Work_Order__c, Quote_Amount__c=objProp.Total_Net__c));
            }
            ilib_LogEvent.info('lstWO: '+lstWO);
            if(!lstWO.isEmpty())
            {
                update lstWO;
                ilib_LogEvent.info('Updated Work Order Record');
                CreateEventToViewDocsInMobile.createEventToViewWODocument(new Map<Id,SVMXC__Service_Order__c>(lstWO).keySet()); //DCP-47185
            }
        }catch(Exception e){
            ilib_LogEvent.pop();
            ilib_LogEvent.emit();
            ApexExceptions.emit(LOG_TITLE,lstQuoteIds.get(0), e, ilib_LogEvent.SALES);
        }
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
    }
}