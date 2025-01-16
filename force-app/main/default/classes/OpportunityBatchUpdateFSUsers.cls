/**
*    @author Todd Newman
*    @date   2019-11-11
*    @description    INC0234515 - batch opportunity FS user updates to increase scalability
*    Modification Log:
*    ---------------------------------------------------------------------------------------------------------
*             Developer            Date                Description
*             Todd Newman          11 Nov 2019         INC0234515 - Initial dev
*             Akshay Mohan         18-June-2021        DCP-38968 Remove OpportunitiesService.shareOpportunites
*             Nishan Shetty        03-Jun-2022         Implementing Batch Manager Framework DCP-50962
*             Parthasarathy D      10-OCT-2022         Codescan fix - Added Method level comments.
*             Aman Tyagi           12-Dec-2022         CodeScan Fixes
*    ---------------------------------------------------------------------------------------------------------
*                    
*/
global class OpportunityBatchUpdateFSUsers extends ilib_BatchDeferrable {

    public static final String LOG_TITLE = 'Service User Recalculation';
    private Inputs inputs;
    private Set<Id> affectedRecordIds;

    /*
    *  @Author      : Nishan Shetty
    *  @Description : Parameter wrapper for easy serialization
    */
    public class Inputs {
        public Set<Id> setAffectedRecordIds;
        /* Constructor */
        public Inputs(Set<Id> affectedRecordIds) {
            this.setAffectedRecordIds = affectedRecordIds;
        }
    }
    /* Constructor */
    public OpportunityBatchUpdateFSUsers()
    {   super();
        this.affectedRecordIds = new Set<Id>();
    }

    /* Constructor */
    public OpportunityBatchUpdateFSUsers(Set<Id> affectedRecordIds) {  
        super();
        this.inputs = new Inputs(affectedRecordIds);
        this.affectedRecordIds = inputs.setAffectedRecordIds;
    }
    
    /* START METHOD */
    global override Database.QueryLocator start(Database.BatchableContext bC) {
        // get all FS user fields (such as Primary_Field_Service_Engineer__c) for select clause 
        List<String> userLookupFields = AutomateFieldServicePopulation.SERVICE_ROLE_TO_OPPORTUNITY_FIELD.values();
        String fsSelectFields = String.join(userLookupFields, ',');

        String strQuery = 'SELECT Id, RecordTypeId, Ultimate_Consignee__c, Distributor__c, ' +
            fsSelectFields + ' ' +
            'FROM Opportunity ' +
            'WHERE Id IN :affectedRecordIds';
        return Database.getQueryLocator(strQuery);
    }
    
    /* EXECUTE METHOD */
    global override void execute(Database.BatchableContext bc, List<SObject> records) {
        ilib_LogEvent.setBatchTitle(LOG_TITLE, transactionId);
        ilib_LogEvent.rootTitle = LOG_TITLE;
        ilib_LogEvent.push('OpportunityBatchUpdateFSUsers.execute');

        List<Opportunity> updatedRecords = updateOpportunityRecords((List<Opportunity>)records);

        persistChanges(updatedRecords);

        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
    }
    
    /* FINISH METHOD */
    global override void finish(Database.BatchableContext bc) { }

    /*
    *  @author      : 
    *  @description : Method to update the opportunity records.
    *  @param       : List of Opportunity.
    *  @return      : List of Opportunity.
    */
    public List<Opportunity> updateOpportunityRecords(List<Opportunity> lstOpportunities)
    {
        // bucket opportunities by account
        Map<Id, List<Opportunity>> accountIdToOpportunities = mapAccountIdToOpportunities(lstOpportunities);

        // query and map related Account to Field Supports
        Set<Id> accountIds = accountIdToOpportunities.keySet();
        List<Account_to_Field_Support__c> lstAccToFieldSupport = new List<Account_to_Field_Support__c>();
        if(accountIds != null && !accountIds.isEmpty())
        {
            lstAccToFieldSupport = new AccountTechniciansSelector().selectRelatedAccountTechnicians(accountIds);
        }

        ilib_LogEvent.message('lstAccToFieldSupport ' + lstAccToFieldSupport);
        if (lstAccToFieldSupport.isEmpty()) return new List<Opportunity>();
        Map <Id, List<Account_to_Field_Support__c>> accountIdToFieldSupports = UtilsCollection.getMapOfIdToSObjects(lstAccToFieldSupport, 'Account__c');

        // set field service users on opportunity records
        List<Opportunity> updatedRecords = AutomateFieldServicePopulation.setFieldServiceFields(accountIdToOpportunities, accountIdToFieldSupports);
        ilib_LogEvent.message('updatedRecords ' + updatedRecords);

        return updatedRecords;
    }

    // direct oppts get bucketed by UC
    // indirect oppts get bucketed by Distributor
    /*
    *  @author      : 
    *  @description : Method to get the Map of Account IDs to opportunities.
    *  @param       : List of Opportunity.
    *  @return      : Map of Account IDs to opportunities.
    */
    public Map<Id, List<Opportunity>> mapAccountIdToOpportunities(List<Opportunity> lstOpportunities)
    {
        Map<Id, List<Opportunity>> accountIdToOpportunities = new Map<Id, List<Opportunity>>();

        for (Opportunity opp : lstOpportunities)
        {
            String strRecordTypeName = Opportunities.getIdToRecordType().get(opp.RecordTypeId).getDeveloperName();
            if (Opportunities.DIRECT_RECORD_TYPES.contains(strRecordTypeName) && String.isNotBlank(opp.Ultimate_Consignee__c)) // && !setClosedStages.contains(opp.StageName))
            {
                if (!accountIdToOpportunities.containsKey(opp.Ultimate_Consignee__c))
                    accountIdToOpportunities.put(opp.Ultimate_Consignee__c, new List<Opportunity>());
                accountIdToOpportunities.get(opp.Ultimate_Consignee__c).add(opp);
            }

            if (Opportunities.INDIRECT_RECORD_TYPES.contains(strRecordTypeName) && String.isNotBlank(opp.Distributor__c)) // && !setClosedStages.contains(opp.StageName)){
            {
                if (!accountIdToOpportunities.containsKey(opp.Distributor__c))
                    accountIdToOpportunities.put(opp.Distributor__c, new List<Opportunity>());
                accountIdToOpportunities.get(opp.Distributor__c).add(opp);
            }
        }

        return accountIdToOpportunities;
    }

    private void persistChanges(List<Opportunity> updatedRecords)
    {
        List<Database.SaveResult> results = Database.update(updatedRecords, false);
        for (Database.SaveResult res : results)
        {
            if (res.isSuccess()) continue;

            ilib_LogEvent.message('error on record ' + res.getId() + ': ' + res.getErrors());
            ApexExceptions.emit(LOG_TITLE, JSON.serialize(res.getErrors()),ilib_LogEvent.SALES );
        }

        Set<Id> recordIds = UtilsCollection.getSetOfIds(updatedRecords, 'Id');
        // deferring logic removed as part of TASK0548217/DCP-43261
        
        List<Customer_Readiness_Form__c> crfs = [SELECT Id, Opportunity_Name__c FROM Customer_Readiness_Form__c WHERE Opportunity_Name__c IN :recordIds];
        if(!crfs.isEmpty())
            CustomerReadinessFormsService.shareWithFieldUsers(crfs, null);
    }


    // ************************************************************************************************
    // Deferrable implementation
    // ************************************************************************************************
    
    /*
    *  @Author      : Nishan Shetty
    *  @Description : Method to simple input serialization
    *  @Param       : None
    *  @Return      : String
    */
    public override String serializeInputs()
    {
        return JSON.serialize(inputs);
    }

    /*
    *  @Author      : Nishan Shetty
    *  @Description : Method to simple input deserialization
    *  @Param       : String
    *  @Return      : void
    */
    public override void restoreInputs(String serializedInputs)
    {
        this.inputs = (OpportunityBatchUpdateFSUsers.Inputs)JSON.deserialize(serializedInputs, OpportunityBatchUpdateFSUsers.Inputs.class);
    }

}