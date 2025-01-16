/**
 *    @author Todd Newman
 *    @date   28-November-2018
 *    @description    Customer Readiness Forms domain class
 *    @Test Class for above 90% coverage.
      -TestTAPS_CustomerReadinessForm
*     @Test Class for atleast 75% coverage.
      -TestTAPS_CustomerReadinessForm
 *    Modification Log:
 *   ---------------------------------------------------------------------------------------------------------------------------
 *    Developer                   Date                  Description
 *    Todd                   28-November-2018         Initial Version
 *    Adyasha                29-March-2021            DCP-52276: CodeScan Fixes 
 *    Nesar Mohan            01-April-2022            CodeScan Fixes
 *    Nishan Shetty          24-August-2022           DCP-44091 - Indirect Instantiation of Orchestrator Class for Performance Improvement.
 *   ---------------------------------------------------------------------------------------------------------------------------
**/

public with sharing class CustomerReadinessForms extends ilib_SObjectDomain {

    public static Boolean hasRunTaps = false;

    /*
    *  @Author: Todd Newman
    *  @Description: Parameterized constructor to pass the parameter value to parent constructor
    *  @Param: List<Customer_Readiness_Form__c>
    */

    public CustomerReadinessForms(List<Customer_Readiness_Form__c> sObjectList)
    {
        super(sObjectList);
    }

    /*
    *  @Author: Todd Newman
    *  @Description: Boilerplate which is required for base class instantiation logic
    */

    public class Constructor implements ilib_SObjectDomain.IConstructable
    {
        /*
        *  @Author: Todd Newman
        *  @Description: contruct method to create a CustomerReadinessForms object
        *  @Param: List<SObject>
        *  @Return: ilib_SObjectDomain
        */

        public ilib_SObjectDomain construct(List<SObject> sObjectList)
        {
            return new CustomerReadinessForms(sObjectList);
        }
    }

    /*
     * @author Todd
     * @date   28-November-2018
     * @description  Before insert trigger method
     * @param none
     * @return void
     */

    public override void onAfterInsert()
    {
        TAPS_OrchestratorInterface tapsOrchestrator = (TAPS_OrchestratorInterface)Type.forName('TAPS_Orchestrator').newInstance();//DCP-44091
        tapsOrchestrator.recalculateRecordChanges(UtilsCollection.getSetOfIds(records, 'Id'), getSObjectType());//DCP-44091
        CustomerReadinessFormsService.shareWithFieldUsers((List<Customer_Readiness_Form__c>)records, null);
    }

    /*
     * @author Todd
     * @date   28-November-2018
     * @description  After Update trigger method
     * @param Map<Id, sObject> map of Id to old sObject record
     * @return void
     */

    public override void onAfterUpdate(Map<Id, sObject> existingRecords)
    {
        if (!hasRunTaps && !isInsertOperationForObject(getSObjectType()))
        {
            List<String> fieldsThatTriggerRecalculation = new List<String> { 'OwnerId', 'Opportunity_Name__c' };
            TAPS_OrchestratorInterface tapsOrchestratorInst = (TAPS_OrchestratorInterface)Type.forName('TAPS_Orchestrator').newInstance();//DCP-44091
            Set<Id> idsThatNeedRecalculation = tapsOrchestratorInst.updateRequiresRecalculation(records, existingRecords, fieldsThatTriggerRecalculation);//DCP-44091
            if (!idsThatNeedRecalculation.isEmpty()) {
                tapsOrchestratorInst.recalculateRecordChanges(idsThatNeedRecalculation, getSObjectType());//DCP-44091
                hasRunTaps = true;
            }
        }

        if (!isInsertOperationForObject(getSObjectType())) {
            CustomerReadinessFormsService.shareWithFieldUsers((List<Customer_Readiness_Form__c>)records, (Map<Id, Customer_Readiness_Form__c>)existingRecords);
        }
    }
    /**
    *  @author Nitin
    *  @description  CMSI-223,method will return the workstream
    *  @return string
    **/
    public override string getWorkstream(){
        return ilib_LogEvent.SERVICE;
    }

}