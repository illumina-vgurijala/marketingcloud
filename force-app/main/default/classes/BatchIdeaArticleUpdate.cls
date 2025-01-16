/**
*    @author: Deep Diwakar
*    @date:   Oct-10-2024
*    @description: Batch class to create IdeaArticle__c object records when cases are added to Knowledge articles after idea-knowledge linking
*    @Test Class: TestBatchIdeaArticleUpdate
*    Modification Log:
*    --------------------------------------------------------------------------------------------------
*          Developer           Date                 Description
*         Deep Diwakar       Oct-10-2024       CMCM-8512: Batch class to create IdeaArticle__c object records after idea-knowledge linking
*    --------------------------------------------------------------------------------------------------
*/

public with sharing class BatchIdeaArticleUpdate extends ilib_ScheduleAndBatch  implements Schedulable {
    private static final String LOG_TITLE = 'BatchIdeaArticleUpdate';
    private static final Integer MAX_INSERT_SIZE = 10000;

    /**
     * @author: Deep Diwakar
     * @date: Oct-10-2024
     * @description: Start method for batch class to collect records
     * @param: bc - batch context
     * @return: Database.QueryLocator to return lead records
     */
    public override Database.QueryLocator start(Database.BatchableContext bc) {
        ilib_LogEvent.setTitle(LOG_TITLE, ilib_LogEvent.MARKETING);
        ilib_LogEvent.push(LOG_TITLE + '.start()');

        String strSOQL = 'SELECT Id, CaseId, KnowledgeArticleId, CreatedDate FROM CaseArticle WHERE CreatedDate = TODAY';
        strSOQL=String.escapeSingleQuotes(strSOQL);

        ilib_LogEvent.info('strSOQL: ' + strSOQL);

        ilib_LogEvent.pop();
        ilib_LogEvent.emit();

        return Database.getQueryLocator(strSOQL);
    }


    /*Execute method for Schedulable Context*/
    public override void execute(SchedulableContext sc) {
        Database.executebatch(new BatchIdeaArticleUpdate());
    }
    
    /**
     * @author: Deep Diwakar
     * @date: Oct-10-2024
     * @description: Execute method to run logic for AOW field
     * @param: bc - batch conext
     * @param: scope - lead records for this batch
     * @return: void
     */
    public override void execute (Database.BatchableContext bc, List<SObject> scope) {
        ilib_LogEvent.setTitle(LOG_TITLE, ilib_LogEvent.MARKETING);
        ilib_LogEvent.push(LOG_TITLE + '.execute()');

        List<CaseArticle> lstCaseArticle = (List<CaseArticle>) scope;
        ilib_LogEvent.info('lstCaseArticle size: ' + lstCaseArticle.size());

        // get all knowledge article ids
        Set<Id> setKaIds = new Set<Id>();
        setKaIds = UtilsCollection.getSetOfIds(lstCaseArticle, 'KnowledgeArticleId');
        ilib_LogEvent.info('setKaIds: ' + setKaIds);

        // get all online knowledge article version ids
        List<Knowledge__kav> lstKavList  = [SELECT Id, KnowledgeArticleId FROM Knowledge__kav Where KnowledgeArticleId IN : setKaIds AND PublishStatus = 'Online' LIMIT 2000];
        Set<Id> setKavIds = new Set<Id>();
        setKavIds = UtilsCollection.getSetOfIds(lstKavList, 'Id');
        ilib_LogEvent.info('setKavIds: ' + setKavIds);

        Map<String, List<Knowledge__kav>> mapKaIdIdKav = new Map<String, List<Knowledge__kav>>();
        mapKaIdIdKav = UtilsCollection.getMapOfStringToSObjects(lstKavList, 'KnowledgeArticleId');
        ilib_LogEvent.info('mapKaIdIdKav: ' + mapKaIdIdKav);

        // get all idea articles that have those knowledge article versions
        List<IdeaArticle__c> lstIdeaArticles = new IdeaArticlesSelector().selectIdeaArticlesByKavId(setKavIds);
        Map<String, List<IdeaArticle__c>> mapKavIdIdeaArticles = new Map<String, List<IdeaArticle__c>>();
        mapKavIdIdeaArticles = UtilsCollection.getMapOfStringToSObjects(lstIdeaArticles, 'Knowledge__c');
        ilib_LogEvent.info('mapKavIdIdeaArticles: ' + mapKavIdIdeaArticles);



        // add new records for these idea articles with these new cases
        List<IdeaArticle__c> lstNewIdeaArticles = new List<IdeaArticle__c>();

        for (CaseArticle ca : lstCaseArticle) {
            if (!mapKaIdIdKav.containsKey(ca.KnowledgeArticleId)) {
                ilib_LogEvent.message('article id not found in article version map');
                continue;
            }

            Id kavId = mapKaIdIdKav.get(ca.KnowledgeArticleId).get(0).Id;
            ilib_LogEvent.message('kavId:' + kavId);

            if (!mapKavIdIdeaArticles.containsKey(kavId)) {
                ilib_LogEvent.message('article version id not found in idea article map');
                continue;
            }

            List<IdeaArticle__c> lstCurrIdeaArticles = new List<IdeaArticle__c>();
            lstCurrIdeaArticles = mapKavIdIdeaArticles.get(kavId);
            ilib_LogEvent.message('lstCurrIdeaArticles:' + lstCurrIdeaArticles);

            // this idea list is for making sure we don't add same same record multiple times
            List<Id> lstIdeaId = new List<Id>(); 

            for (IdeaArticle__c extIaRecord : lstCurrIdeaArticles) {
                if (lstIdeaId.contains(extIaRecord.Idea_Innohub__c)) {
                    continue;
                }

                lstIdeaId.add(extIaRecord.Idea_Innohub__c);
                IdeaArticle__c iaRecord = new IdeaArticle__c();
                iaRecord.Knowledge__c = kavId;
                iaRecord.Case__c = ca.CaseId; // this is new here
                iaRecord.Idea_Innohub__c = extIaRecord.Idea_Innohub__c;
                ilib_LogEvent.message('adding idea article object to list:');
                lstNewIdeaArticles.add(iaRecord);

            }

        }

        ilib_LogEvent.info('lstNewIdeaArticles: ' + lstNewIdeaArticles);

        if (lstNewIdeaArticles.isEmpty()) {
            ilib_LogEvent.info('nothing to insert, returning');
            ilib_LogEvent.pop();
            ilib_LogEvent.emit();
            return;

        }

        // calling BatchDMLService in case of more than 10000 records for insert to avoid hitting governor limit
        if (lstNewIdeaArticles.size() > MAX_INSERT_SIZE) {
            ilib_LogEvent.info('calling Batch DML service to handle more that 10000 records');
            BatchDMLService batchDMLService = new BatchDMLService(lstNewIdeaArticles, BatchDMLService.dmlOperation.DML_INSERT, 2000);
            batchDMLService.runBatchDML();
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
            List<Database.SaveResult> results = Database.insert(lstNewIdeaArticles, false);
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
     * @date: Oct-10-2024
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