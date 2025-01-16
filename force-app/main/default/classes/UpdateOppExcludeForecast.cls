/***************************************************************************************************************************************
    * NAME   : UpdateOppExcludeForecast
    * DESCRIPTION  : Logic for updating Opportunity Exclude From forecast to true
    *                    
    * @AUTHOR : Akshay Mohan
    * @DATE   : 08-June-2021  
    * 90% code coverage Test classes : TestApttusCheckPriceController, 
                                       TestOpportunityQuoteAutomatio, TestZDSTWorkOrderDataReceiver 
    * 75% code coverage Test classes : TestApttusCheckPriceController, 
                                       TestOpportunityQuoteAutomatio, TestZDSTWorkOrderDataReceiver
    * MODIFICATION LOG: 
    * -----------------------------------------------------------------------------------------------------------------------------------------------------------
    * DEVELOPER                DATE                DESCRIPTION 
    * ------------------------------------------------------------------------------------------------------------------------------------------------------------
    * Akshay Mohan             08-June-2021        DCP-46835: Initial Version. 
    * Biswajeet Sahoo          2022-08-23          [CMSI-201] Instrumentation of the class 
******************************************************************************************************************************************************************/
public with sharing class UpdateOppExcludeForecast implements ilib_AdminOperationLogicInterface{
    private static final String LOG_TITLE = 'UpdateOppExcludeForecast';

    /**
     *  @author       : Akshay Mohan
     *  @description  : Update Opp Exclude From Forecast to true
     *  @return       : void
     */
    public static void doBusinessLogic(List<Id> lstOppIds){
        ilib_LogEvent.setTitle(LOG_TITLE, ilib_LogEvent.SALES);  
        ilib_LogEvent.push(LOG_TITLE + '.doBusinessLogic()');
        List<Opportunity> lstOpps = new List<Opportunity>();
        try{
            for(Opportunity objOpp : new OpportunitySelector().selectOpportunities(new Set<Id>(lstOppIds))){
                if(!objOpp.Exclude_from_Forecast__c){
                    lstOpps.add(new Opportunity(Id=objOpp.id, Exclude_from_Forecast__c=true));
                }
            }
            ilib_LogEvent.info('lstOpps: '+lstOpps);            //CMSI-201
            if(!lstOpps.isEmpty())
            {
                update lstOpps;
                ilib_LogEvent.info('Update success');         //CMSI-201
            }
        }catch(Exception e){
            ApexExceptions.emit(LOG_TITLE,lstOppIds.get(0), e, ilib_LogEvent.SALES);  //CMSI-201 added workstream
            ilib_LogEvent.pop();  //CMSI-201
            ilib_LogEvent.emit(); //CMSI-201
        }
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
    }
}