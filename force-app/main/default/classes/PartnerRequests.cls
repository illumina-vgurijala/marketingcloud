/*
*  @Author:
*  @Date: 
*  @Description:
*  Modification Log:
*  @Test Class for above 90% coverage.
*   TestTAPS_PartnerRequest
*  @Test Class for atleast 75% coverage.
*   TestTAPS_PartnerRequest
*   ------------------------------------------------------------------------------------ 
*    Developer                      Date                    Description
*  Nishan Shetty                 24-Aug-2022            DCP-44091 - Indirect Instantiation of Orchestrator Class for Performance Improvement.
*    ------------------------------------------------------------------------------------                  
*/
public with sharing class PartnerRequests extends ilib_SObjectDomain {

    public static Boolean hasRunTaps = false;
    /*
     * public constructor for ApttusAgreementLineItems
    */
    public PartnerRequests(List< Partner_Request__c > sObjectList)
    {
        super(sObjectList);
    }
    /*
    * Boilerplate which is required for base class instantiation logic
    */
    public class Constructor implements ilib_SObjectDomain.IConstructable
    {   
        /*
         * return a new object ApttusAgreementLineItems
        */
        public ilib_SObjectDomain construct(List<SObject> sObjectList)
        {
            return new PartnerRequests(sObjectList);
        }
    }
    /**
     * Called during after insert event 
    **/
    public override void onAfterInsert()
    {   
        TAPS_OrchestratorInterface tapsOrchestrator = (TAPS_OrchestratorInterface)Type.forName('TAPS_Orchestrator').newInstance();//DCP-44091
        tapsOrchestrator.recalculateRecordChanges(UtilsCollection.getSetOfIds(records, 'Id'), getSObjectType());//DCP-44091
    }
}