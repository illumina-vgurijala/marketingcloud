/***************************************************************************************************************************************
* @Author:  Gladis
* @Date:   17-June-2021 
* @Description: Update WorkOrder/Opportunity using platform event
* Modification Log:
* 90% code coverage test class : TestWorkOrders
* 75% code coverage test class : TestWorkOrders
* ------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* ------------------------------------------------------------------------------------
* Gladis                   17-June-2021        Initial Version
* Biswajeet Sahoo          2022-08-23          [CMSI-201] Instrumentation of class
******************************************************************************************************************************************************************/
public with sharing class UpdateOpportunityAbandoned implements ilib_AdminOperationLogicInterface{
    private static final String LOG_TITLE = 'UpdateOpportunityAbandoned';
    /**
     *  @author       : Gladis
     *  @description  : Update Opportunity using platform event
     *  @return       : void
     */
    public static void doBusinessLogic(List<Id> lstOpportunityIds){
        ilib_LogEvent.setTitle(LOG_TITLE, ilib_LogEvent.SALES); //CMSI-201
        ilib_LogEvent.push(LOG_TITLE+'.doBusinessLogic()');     //CMSI-201
        list<opportunity> lstOpportunities = new list<opportunity>();
        Map<Id, String> workOrderReasonMap = new Map<Id, String>();
        Set<Id> setOppIds = new Set<Id>(lstOpportunityIds);
        ilib_LogEvent.info('setOppIds--'+setOppIds);  //CMSI-201
        try{

            //DCP-38816
            List<SVMXC__Service_Order__c> lstWorkOrder  = new WorkOrdersSelector().selectWorkOrdersFromOpportunities(setOppIds);           
                for(SVMXC__Service_Order__c wo:lstWorkOrder){
                        workOrderReasonMap.put(wo.opportunity__c,wo.Abandoned_Reason__c);
                }
            for(id idOpp:lstOpportunityIds){
                    Opportunity objOpp = new Opportunity();
                    objOpp.id = idOpp;
                    objOpp.StageName = 'Closed Abandoned'; 
                    objOpp.Probability = 0;
                    objOpp.Amount = 0;
                    objOpp.CloseDate = system.TODAY();
                    objOpp.Abandon_Reason__c = 'Other'; 
                    if(workOrderReasonMap.containsKey(idOpp)){
                        objOpp.Abandoned_Reason_Details__c = workOrderReasonMap.get(idOpp);
                    }
                    lstOpportunities.add(objOpp);
                }
                update lstOpportunities;
                ilib_LogEvent.info('lstOpportunities--'+UtilsCollection.getSetOfIds(lstOpportunities));  //CMSI-201
        }
        catch(Exception e){
            ApexExceptions.emit(LOG_TITLE,lstOpportunityIds.get(0), e, ilib_LogEvent.SALES);  //CMSI-201 added workstream
        }
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
    }
}