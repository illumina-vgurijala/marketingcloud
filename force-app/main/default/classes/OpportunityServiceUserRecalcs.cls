    /*
    *  @Author: Todd Newman
    *  @Date: 
    *  @Description: Class for Opportunity Service User Recalculation
    *  Test Class for 75% Coverage : TestApttusApprovals,,TestApttusAssetLineItems,TestApttusCartErrorPageController,TestApttusCheckCatalystDiscount,TestApttusGetPromotionsController,
    *                                TestApttusMobileCreateQuote,TestApttusOrderLineItems,TestApttusPreviewQuotationsAndApprovals,TestApttusTerminateAssetRenewals,TestApttusValidationCallback,TestOpportunities
    *  Test Class for 90% Coverage : TestApttusApprovals,,TestApttusAssetLineItems,TestApttusCartErrorPageController,TestApttusCheckCatalystDiscount,TestApttusGetPromotionsController,
    *                                TestApttusMobileCreateQuote,TestApttusOrderLineItems,TestApttusPreviewQuotationsAndApprovals,TestApttusTerminateAssetRenewals,TestApttusValidationCallback,TestOpportunities
    *  Modification Log:
    *  ---------------------------------------------------------------------------------------------------------------------------
    *       Developer                      Date                Description         
    *       Todd Newman                                      Initial Version
    *       Nesar Mohan                 2022-03-30           CodeScan Fix 
    *       Nishan Shetty               03-Jun-2022          Implementing Batch Manager Framework DCP-50962
    *       Anshaj Sinha                30-Aug-2022          CMSI-202 Instrumented class
    *       Saddam                      08-Dec-2022         Codescan Fix , Varaible naming convention. 
    *    ---------------------------------------------------------------------------------------------------------------------------
    **/
public with sharing class OpportunityServiceUserRecalcs extends ilib_SObjectDomain {

    public static final String LOG_TITLE = 'OpportunityServiceUserRecalcs';
    public static final Integer DEFAULT_BATCH_SIZE = 25;

    /*
    *  @Author      : Todd Newman
    *  @Description : Constructor to pass the object list to parent class
    *  @Param       : List<Opportunity_Service_User_Recalc__e>
    */
    public OpportunityServiceUserRecalcs (List<Opportunity_Service_User_Recalc__e> sObjectList) {
        super(sObjectList);
    }

    /*
    *  @Author      : Todd Newman
    *  @Description : Boilerplate which is required for base class instantiation logic
    */

    public class Constructor implements ilib_SObjectDomain.IConstructable {
        /*
        *  @Author      : Todd Newman
        *  @Description : Constructor to pass the object list to parent class
        *  @Param       : List<Opportunity_Service_User_Recalc__e>
        */
        public ilib_SObjectDomain construct(List<SObject> sObjectList) {
            return new OpportunityServiceUserRecalcs (sObjectList);
        }
    }

    /*
    *  @Author      : Todd Newman
    *  @Description : Method to publish EventBus to put this in a central place so we can log/comment/enhance it
    *  @Param       : Set<Id>
    *  @Return      : void
    */
    public static void publish(Set<Id> setAccountIds) {
        EventBus.publish(new Opportunity_Service_User_Recalc__e(JSON_Account_Ids__c = JSON.serialize(setAccountIds)));
    }

    /*
    *  @Author      : Todd Newman
    *  @Description : Method to fetch configuration values for FS_User_Sharing_Settings
    *  @Param       : None
    *  @Return      : Map<String, String>
    */
    private static Map<String, String> getConfigValues()
    {
        ilib_LogEvent.push(LOG_TITLE + '.getConfigValues()');
        ilib_LogEvent.pop();
        return UtilsSettings.getCustomMetadataMap('FS_User_Sharing_Settings');
    }


    /*
    *  @Author      : Todd Newman
    *  @Description : Method to fetch the batchSize
    *  @Param       : None
    *  @Return      : Integer
    */
    public static Integer getBatchSize()
    {
        ilib_LogEvent.push(LOG_TITLE + '.getBatchSize()');
        ilib_LogEvent.pop();
        return UtilsSettings.parseIntegerFromSettingsMap(getConfigValues(), 'batchSize', DEFAULT_BATCH_SIZE);
    }

    /**
    *  @author Anshaj
    *  @description  CMSI-202,method will return the workstream
    *  @return string
    **/
    public override string getWorkstream(){
        return ilib_LogEvent.SALES;
    }

    /*
    *  @Author      : Todd Newman
    *  @Description : Method to execute After Insert trigger logic
    *  @Param       : None
    *  @Return      : void
    */
    public override void onAfterInsert() {
        ilib_LogEvent.setTitle('Trigger-Insert-OpportunityServiceUserRecalcs', ilib_LogEvent.SALES);
        ilib_LogEvent.push(LOG_TITLE + '.onAfterInsert()');
        ilib_LogEvent.info('event count ' + records.size());

        Set<Id> allAccountIds = new Set<Id>();

        // collect all account IDs
        for (Opportunity_Service_User_Recalc__e recalcRequest : (List<Opportunity_Service_User_Recalc__e>)records) {
            Set<Id> accountIds = safeDeserialize(recalcRequest.JSON_Account_Ids__c);
            ilib_LogEvent.message('accountIds ' + accountIds);
            if (accountIds.isEmpty()) continue;

            allAccountIds.addAll(accountIds);
        }
        if (allAccountIds.isEmpty()) {
            ilib_LogEvent.pop();
            return; }

        List<Opportunity> openOpportunities = new OpportunitySelector().selectRelatedOpenOpportunities(allAccountIds);
        List<Opportunity> closedOpportunities = new OpportunitySelector().selectRelatedClosedOpportunities(allAccountIds);
        ilib_LogEvent.info('openOpportunities size ' + openOpportunities.size());
        ilib_LogEvent.info('closedOpportunities size ' + closedOpportunities.size());
        Integer batchSize = getBatchSize();
        ilib_LogEvent.info('batchSize : '+batchSize);

        if (!openOpportunities.isEmpty()) {
            Set<Id> opptIds = UtilsCollection.getSetOfIds(openOpportunities, 'Id');
            ilib_LogEvent.info('Open Opportunities Ids : '+opptIds);
            OpportunityBatchUpdateFSUsers batchUpdater = new OpportunityBatchUpdateFSUsers(opptIds);
            ilib_BatchManager.executeBatch(batchUpdater,batchSize);
        }

        if (!closedOpportunities.isEmpty()) {
            Set<Id> opptIds = UtilsCollection.getSetOfIds(closedOpportunities, 'Id');
            ilib_LogEvent.info('Closed Opportunities Ids : '+opptIds);
            OpportunityBatchUpdateFSUsers batchUpdater = new OpportunityBatchUpdateFSUsers(opptIds);
            ilib_BatchManager.executeBatch(batchUpdater,batchSize);
            
        }
        ilib_LogEvent.pop();

    }

    /*
    *  @Author      : Todd Newman
    *  @Description : Method to deserialize the passed Ids
    *  @Param       : String
    *  @Return      : Set<Id>
    */
    private Set<Id> safeDeserialize(String rawIds) {
        if (String.isBlank(rawIds)) return new Set<Id>();

        try {
            return (Set<Id>)JSON.deserialize(rawIds, Set<Id>.class);
        } catch(Exception e) {
            return new Set<Id>();
        }
    }

}
