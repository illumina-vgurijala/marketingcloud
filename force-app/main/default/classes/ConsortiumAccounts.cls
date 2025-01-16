/**
*    @author Roopal Verma
*    @date   2018-09-07
*    @description    DCP-9717: Prevent deletion of Consorium Account with Consortium Opportunity
*    @Test Class for above 90% coverage.
*    -TestConsortiumAccounts
*    @Test Class for atleast 75% coverage.
     -TestConsortiumAccounts
*    Modification Log:
*    ------------------------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Jitesh Lakhwani                8-July-2022         Code Scan fixes of Comments
*             Nishan Shetty                  24-Aug-2022           DCP-44091 - Indirect Instantiation of Orchestrator Class for Performance Improvement.
*    --------------------------------------------------------------------------------------------------------------------------------------------------
*                    
*/
public with sharing class ConsortiumAccounts extends ilib_SObjectDomain {
    private static final String LOG_TITLE = 'Consortium Accounts';
    /**
    * @description Parameterized Constructor called
    * @params List<Consortium_Account__c> sObjectList
    * @return void
    **/
    public ConsortiumAccounts(List<Consortium_Account__c> sObjectList)
    {
        super(sObjectList);
    }
    /**
     * Boilerplate which is required for base class instantiation logic
     */
    public class Constructor implements ilib_SObjectDomain.IConstructable
    {
        /**
        * @description  Constructor of base class
        * @params List<SObjects> sObjectList
        * @return sObjectList
        **/
        public ilib_SObjectDomain construct(List<SObject> sObjectList)
        {
            return new ConsortiumAccounts(sObjectList);
        }
    }

    /**
     * @author Roopal Verma
     * @date   2018-09-07
     * @description   DCP-9717: Prevent deletion of Consorium Account with Consortium Opportunity
     * Before delete trigger method
     */
    public override void onBeforeDelete()
    {
        List<Consortium_Account__c> lstConsortiumAcc = (List<Consortium_Account__c>) records;
        checkConsortiumAccOpportunity(lstConsortiumAcc);   
    }

    /**
    * @description Overriding the onAfterInsert base class method
    * @params NA
    * @return void
    **/
    public override void onAfterInsert()
    {   ilib_LogEvent.setTitle(LOG_TITLE,ilib_LogEvent.SALES);
        ilib_LogEvent.push(LOG_TITLE);
        try{
        TAPS_OrchestratorInterface tapsOrchestrator = (TAPS_OrchestratorInterface)Type.forName('TAPS_Orchestrator').newInstance();//DCP-44091
        tapsOrchestrator.recalculateRecordChanges(UtilsCollection.getSetOfIds(records, 'Consortia__c'), Consortium__c.SObjectType);//DCP-44091
        ilib_LogEvent.pop();
        }catch(Exception e){
        		System.debug('Error Message is  '+e.getMessage());
                ApexExceptions.emit(LOG_TITLE,e,ilib_LogEvent.SALES );
    		}
    }

    /**
    * @description This method will check whether an Consortium account is linked to an account OR not, if account is linked it will throw an error.
    * @params List<Consortium_Account__c> lstConsortiumAcc
    * @return void
    **/
    public static void checkConsortiumAccOpportunity(List<Consortium_Account__c> lstConsortiumAcc)
    {
        System.debug('---lstConsortiumAcc--'+lstConsortiumAcc);
        //Set of Consortiums associtated with Consortium Account
        Set<Id> setConsortiumId = new set<id>();
        setConsortiumId = UtilsCollection.getSetOfIds(lstConsortiumAcc,'Consortia__c');

        //List of Opportunities related to Consortiums.
        List<Opportunity> lstOpportunity = new OpportunitySelector().selectConsortiumOpp(setConsortiumId);
        if(lstOpportunity.isEmpty())
            return;

        //Set of Consortiums associated with Consortium Opportunity.
        Set <Id> setOppConsortium = new set<Id>();
        setOppConsortium = UtilsCollection.getSetOfIds(lstOpportunity,'Consortium__c');

        for ( Consortium_Account__c conAcc : lstConsortiumAcc ){
            if ( setOppConsortium.contains(conAcc.Consortia__c) ){
                conAcc.addError(System.label.UI_ErrorMessage_ConsortiumAccountDeleteLinkedToOpp);
            }
        }
    }

}