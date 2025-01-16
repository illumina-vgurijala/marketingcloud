/**
*    @author: Deep Diwakar
*    @date:   Oct-17-2024
*    @description: Batch class to update IdeaArticle__c object records with latest KAV versions
*    @Test Class: TestBatchIdeaArticleKAVUpdate
*    Modification Log:
*    --------------------------------------------------------------------------------------------------
*          Developer           Date                 Description
*         Deep Diwakar       Oct-17-2024       CMCM-11914: Batch class to update IdeaArticle__c object records with latest KAV versions
*    --------------------------------------------------------------------------------------------------
*/

public with sharing class BatchIdeaArticleKAVUpdate extends ilib_ScheduleAndBatch implements Schedulable {
    private static final String LOG_TITLE = 'BatchIdeaArticleKAVUpdate';

    /**
     * @author: Deep Diwakar
     * @date: Oct-17-2024
     * @description: Start method for batch class to collect records
     * @param: bc - batch context
     * @return: Database.QueryLocator to return lead records
     */
    public override Database.QueryLocator start(Database.BatchableContext bc) {
        ilib_LogEvent.setTitle(LOG_TITLE, ilib_LogEvent.MARKETING);
        ilib_LogEvent.push(LOG_TITLE + '.start()');
        String publishStatus = 'Online';

        String strSOQL = 'SELECT Id, KnowledgeArticleId FROM Knowledge__kav WHERE PublishStatus =: publishStatus and LastPublishedDate = TODAY';
        strSOQL=String.escapeSingleQuotes(strSOQL);

        ilib_LogEvent.info('strSOQL: ' + strSOQL);

        ilib_LogEvent.pop();
        ilib_LogEvent.emit();

        return Database.getQueryLocator(strSOQL);
    }

    /*Execute method for Schedulable Context*/
    public override void execute(SchedulableContext sc) {
        BatchIdeaArticleKAVUpdate b = new BatchIdeaArticleKAVUpdate();
        Database.executebatch(b);
    }
    
    /**
     * @author: Deep Diwakar
     * @date: Oct-17-2024
     * @description: Execute method to run logic for AOW field
     * @param: bc - batch conext
     * @param: scope - lead records for this batch
     * @return: void
     */
    public override void execute (Database.BatchableContext bc, List<SObject> scope) {
        ilib_LogEvent.setTitle(LOG_TITLE, ilib_LogEvent.MARKETING);
        ilib_LogEvent.push(LOG_TITLE + '.execute()');

        List<Knowledge__kav> lstKnowledgeArticleVersion = (List<Knowledge__kav>) scope;

        // create map of KA Id to latest KAV Id
        Map<String, String> mapKaIdToKavId = new Map<String, String>();
        mapKaIdToKavId = UtilsCollection.getMapOfStringToString(lstKnowledgeArticleVersion, 'KnowledgeArticleId', 'Id');
        ilib_LogEvent.info('mapKaIdToKavId: ' + mapKaIdToKavId);

        // get set of KA Ids
        Set<String> setKAIds = mapKaIdToKavId.keySet();

        List<Knowledge__kav> lstKAVRecordsPrevious = new List<Knowledge__kav>();

        // query to get last archived KAV records for given KA Ids
        lstKAVRecordsPrevious = [Select Id, KnowledgeArticleId FROM Knowledge__kav WHERE KnowledgeArticleId IN :setKAIds 
                                    AND PublishStatus = 'Archived' and IsLatestVersion = false AND ArchivedDate = TODAY];

        Map<String, String> mapPrevKavIdToKaId = new Map<String, String>();

        // TODO: Edge Case: If same article published twice in a day then there will be two archived versions 
        // create map to story last archived KAV Id to KA Id
        mapPrevKavIdToKaId = UtilsCollection.getMapOfStringToString(lstKAVRecordsPrevious, 'Id', 'KnowledgeArticleId');

        Set<Id> setPrevKAVIds = UtilsCollection.getSetOfIds(lstKAVRecordsPrevious, 'Id');

        List<IdeaArticle__c> lstExistingIdeaArticles = new List<IdeaArticle__c>();

        // query Idea article object using last archived KAV Ids to find all Idea Article records tied to those
        lstExistingIdeaArticles = new IdeaArticlesSelector().selectIdeaArticlesByKavId(setPrevKAVIds);

        List<IdeaArticle__c> lstIdeaArticlesUpdate = new List<IdeaArticle__c>();

        // loop to update Idea Article records found from above query
        for (IdeaArticle__c ideaArticle : lstExistingIdeaArticles) {

            String currentKAVId = ideaArticle.Knowledge__c;
            // get KA Id first
            String kaId = mapPrevKavIdToKaId.get(currentKAVId);

            // get latest KAV Id
            String latestKavId = mapKaIdToKavId.get(kaId);

            IdeaArticle__c iaUpdate = new IdeaArticle__c(Id = ideaArticle.Id);
            iaUpdate.Knowledge__c = latestKavId;

            // update idea article record
            lstIdeaArticlesUpdate.add(iaUpdate);

        }

        ilib_LogEvent.info('lstIdeaArticlesUpdate: ' + lstIdeaArticlesUpdate);

        if (lstIdeaArticlesUpdate.isEmpty()) {
            ilib_LogEvent.info('nothing to update, returning');
            ilib_LogEvent.pop();
            ilib_LogEvent.emit();
            return;

        }

        // Bypassing trigger run, validation and flows because this is one time mass update of existing records
        if (Schema.sObjectType.cs_Apex_Settings__c.isUpdateable() && Schema.sObjectType.cs_Apex_Settings__c.isCreateable()) {
            cs_Apex_Settings__c objApexSettings=cs_Apex_Settings__c.getInstance();
            
            // adding bypass for running user
            objApexSettings.Bypass_All_Validations__c=true;
            objApexSettings.Bypass_All_Triggers__c=true;
            objApexSettings.Bypass_All_Flows__c=true;
            upsert objApexSettings cs_Apex_Settings__c.Id;
            List<Database.SaveResult> results = Database.update(lstIdeaArticlesUpdate, false);
            // log errors, if any
            ApexExceptions.emitSaveErrors(results, LOG_TITLE);
    
            // revert bypass
            objApexSettings.Bypass_All_Validations__c=false;
            objApexSettings.Bypass_All_Triggers__c=false;
            objApexSettings.Bypass_All_Flows__c=false;
            upsert objApexSettings cs_Apex_Settings__c.Id;
        } else {
            ilib_LogEvent.info('User does not have create and update permission on custom setting - Apex Settings');
        }

        ilib_LogEvent.pop();
        ilib_LogEvent.emit();

    }

    /**
     * @author: Deep Diwakar
     * @date: Oct-17-2024
     * @description: Required final method for batch
     * @param: bc - batch context
     * @return: void
     */
    public override void finish(Database.BatchableContext bc) {
        ilib_LogEvent.setTitle(LOG_TITLE, ilib_LogEvent.MARKETING);
        ilib_LogEvent.push(LOG_TITLE + '.finish()');

        ilib_LogEvent.info('No work for finish method');

        ilib_LogEvent.pop();
        ilib_LogEvent.emit();

    }

}