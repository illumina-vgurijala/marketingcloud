/**
 *    @author Adyasha
 *    @date   04-Jan-2021
 *    @description Scheduled batch class for archiving the knowledge articles in SFDC which are deleted in ICE.
 *    Modification Log:
 *    ---------------------------------------------------------------------------------------------------------------------
 *             Developer                      Date                Description
   ---------------------------------------------------------------------------------------------------------------------
 *
 */
global class ScheduledBatchKnowledgeArchiveICERecords extends ilib_ScheduleAndBatch implements Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts{
    public static final String ERROR = 'ERROR';
    public static final String SOURCE_ICE = 'ICE';
    public static final String PUBLISH_STATUS_ONLINE = 'Online';
    public Set<String> setLibraryContentBatch;
    public Set<String> setArchivedKnowledgeArticles = new Set<String>();
    public static final String CODEPARAMETERNAME = 'Knowledge_Articles_Archived_Recipients';
    /**
    * @author Adyasha
    * @date   04-Jan-2021
    * @description  execute method for scheduled job
    */
    global Override void execute(SchedulableContext sc)
    {
        Database.executeBatch(new ScheduledBatchKnowledgeArchiveICERecords(),200);
    }
    /**
    * @author Adyasha
    * @date   04-Jan-2021
    * @description  start method for Batch job
    */
    global Override Database.QueryLocator start(Database.BatchableContext bc)
    {
        String strAccessToken = KnowledgeArticleICESyncConnector.getAccessToken('ICE Monthly Batch Integration Authorization',false);
        String soql = '';
        System.debug(strAccessToken);
        Set<String> contentLibraryID = new Set<String>();
        if(strAccessToken != ERROR){
            System.debug('In IF'+strAccessToken);
            List<KnowledgeSyncWrapper.ContentDetails> lstLibraryContent = KnowledgeArticleICESyncConnector.fetchContentDetails(strAccessToken);
            if(!lstLibraryContent.isEmpty()){
                system.debug('----list>'+lstLibraryContent);
                for(KnowledgeSyncWrapper.ContentDetails contentDetail : lstLibraryContent){
                    contentLibraryID.add(contentDetail.libraryContentId);  
                }
                system.debug('---@ADcontentlibraryset->'+contentLibraryID);
            }          
        }
        soql = 'SELECT Id,KnowledgeArticleId, Title'
            + ' FROM Knowledge__kav'
            + ' WHERE Knowledge_Source__c = :SOURCE_ICE AND External_Content_ID__c NOT IN :contentLibraryID AND PublishStatus = :PUBLISH_STATUS_ONLINE';
        return Database.getQueryLocator(soql);
    }
    /**
    * @author Adyasha
    * @date   04-Jan-2021
    * @description  execute method for Batch job
    */
    global Override void execute(Database.BatchableContext bc,  List<SObject> scope){
        if(scope.isEmpty()) return;
        try{
            for(Knowledge__kav objKnowledge : (List<Knowledge__kav>)scope){
                system.debug('---@AD->'+objKnowledge.KnowledgeArticleId);
                KbManagement.PublishingService.archiveOnlineArticle(objKnowledge.KnowledgeArticleId,null);
                setArchivedKnowledgeArticles.add(objKnowledge.KnowledgeArticleId +' '+objKnowledge.Title);
            }
        }catch(Exception e){
            System.debug('Exception-->'+e.getMessage());
            ApexExceptions.emit('ScheduledBatchKnowledgeArchiveICERecords',e);
        }
    }
    /**
    * @author Adyasha
    * @date   04-Jan-2021
    * @description  Finish method for Batch job
    */
    global Override void finish(Database.BatchableContext bc){
        if(!setArchivedKnowledgeArticles.isEmpty()){
            CodeParametersSelector codeParameterSlctr = new CodeParametersSelector();
            List<Code_Parameter__mdt> objCodeParam = codeParameterSlctr.selectCodeParameterByDeveloperName(new Set<String>{CODEPARAMETERNAME});
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            List<String> strEmailId = new List<String>();
            if(!Test.isRunningTest()){
                strEmailId.addAll(objCodeParam[0].Value__c.split(';'));
            }
            else{
            strEmailId.add('sfdc_service_account@illumina.com');
            }
            email.setToAddresses(strEmailId);
            String subject = 'IMPORTANT: Knowledge Articles Archived';
            email.setSubject(subject);
            String strBody = 'Following Knowledge Articles have been archived: </br>';
            for(String str : setArchivedKnowledgeArticles)
                strBody = strBody + str+'</br>';
            email.setHtmlBody(strBody);
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
        }
    }
}