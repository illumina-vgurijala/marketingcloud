/**
 *    @author KD
 *    @date   8-Dec-2020
 *    @description  batch class for knowledgeSync
 *    Modification Log:
 *    ---------------------------------------------------------------------------------------------------------------------
 *             Developer                      Date                Description
 *             Sarath Pullanikkatt            17-Apr-2021         Article Upsert Logic Changed to Use Document Number
			   Shruti Karn                    14-Jun-21           Added null check for Document Number
 *    ---------------------------------------------------------------------------------------------------------------------
 *
 */
public with sharing class BatchKnowledgeArticleICESync extends ilib_RestReceiver implements Database.Batchable<KnowledgeSyncWrapper.LibraryContentDetails>,Database.Stateful,Database.AllowsCallouts{
    List<KnowledgeSyncWrapper.LibraryContentDetails> lstLibraryContentDetailsWrapper;
    public Map<String,String> mapICEToDCPMapping = new Map<String,String>();
    public Map<String,String> mapDCPRecordTypeMapping = new Map<String,String>();
    public Set<String> setFinalRunReport = new Set<String>();
    public static String strProfileName = 'Knowledge Management';
    public static final String CODEPARAMETERNAME = 'Knowledge_Article_Sync_Email_Notify';
    public static final String CODEPARAMETERKAREGION = 'Knowledge_Applicable_Region_Global'; 
    public String strAccessToken;
    Code_Parameter__mdt objCodeParamKARegion;
    /**
    * @author KD
    * @date   26-Nov-2020
    * @description  Constructor
    */
    public BatchKnowledgeArticleICESync(List<KnowledgeSyncWrapper.LibraryContentDetails> lstLibraryContentDetailsWrapper,String strAccessToken) {
        this.lstLibraryContentDetailsWrapper = lstLibraryContentDetailsWrapper;
        this.strAccessToken = strAccessToken;
    }
    /**
    * @author KD
    * @date   26-Nov-2020
    * @description  Constructor
    */
    public BatchKnowledgeArticleICESync(){}
    /**
    * @author KD
    * @date   26-Nov-2020
    * @description  start method for Batch job
    */
    public Iterable<KnowledgeSyncWrapper.LibraryContentDetails> start(Database.batchableContext objBatchableContext){
        List<Knowledge_Sync_Mapping__mdt> lstMapping = new KnowledgeSyncMappingSelector().selectKnowledgeSyncMapping();
        for(Knowledge_Sync_Mapping__mdt objMapping : lstMapping){
            if(objMapping.Type__c == 'Picklist'){
                mapDCPRecordTypeMapping.put(objMapping.MasterLabel,objMapping.Value__c);
            }
            else
                mapICEToDCPMapping.put(objMapping.MasterLabel,objMapping.Value__c);
        }
        
        //TASK0570079
        objCodeParamKARegion = new CodeParametersSelector().selectCodeParameterByDeveloperName(new Set<String>{CODEPARAMETERKAREGION})[0];
        //End of TASK0570079

        Iterable<KnowledgeSyncWrapper.LibraryContentDetails> lstIterable = (Iterable<KnowledgeSyncWrapper.LibraryContentDetails>) new KnowledgeSyncIterator(lstLibraryContentDetailsWrapper);
        return lstIterable;
    }
    /**
    * @author KD
    * @date   26-Nov-2020
    * @description  execute method for Batch job
    */
    public void execute(Database.BatchableContext objBatchableContext, List<KnowledgeSyncWrapper.LibraryContentDetails> lstScope){
        try{
            for(KnowledgeSyncWrapper.LibraryContentDetails objLibContent:lstScope){
                String strAction = '';
                String strKAId = '';
                Boolean boolHasOnlineArticle = false;
                System.debug('Batch run-->'+objLibContent);
                System.debug('Access Token-->'+strAccessToken);
                System.debug('Profile-->'+objLibContent.strContentProfileName+'-');
                // Batch Size is 1 so query inside loop
				//Blank check added for INC0323291 by Shruti
				List<Knowledge__kav> lstKA = new List<Knowledge__kav>();
				if(String.isNotBlank(objLibContent.strDocumentNumber))
					lstKA = new KnowledgeArticlesSelector().selectArticleByDocumentNumber(objLibContent.strDocumentNumber, 'Online');
                if(!lstKA.isEmpty())
                    boolHasOnlineArticle = true;
                //Existig article logic
                if(boolHasOnlineArticle){
                    strKAId = lstKA[0].KnowledgeArticleId;
                    System.debug('Inside Edit article creation');
                    if(objLibContent.boolIsDeleted){
                        strAction = 'Archived';
                        KbManagement.PublishingService.archiveOnlineArticle(lstKA[0].KnowledgeArticleId,null);
                    }
                    else if(objLibContent.strContentProfileName.contains(strProfileName) && objLibContent.boolIsPublished){
                        strAction = 'Re-Published';
                        strKAId = BatchKnowledgeArticleICESyncHelper.upsertArticle(strAccessToken,objLibContent,mapICEToDCPMapping,mapDCPRecordTypeMapping,lstKA[0].KnowledgeArticleId,objCodeParamKARegion);
                    }
                    else
                        strAction = 'No Action';
                }
                // Non-Existing Article
                else{
                    if(objLibContent.boolIsPublished && !objLibContent.boolIsDeleted && objLibContent.strContentProfileName.contains(strProfileName)){
                        System.debug('Inside New article creation');
                        strAction = 'Created';
                        strKAId = BatchKnowledgeArticleICESyncHelper.upsertArticle(strAccessToken,objLibContent,mapICEToDCPMapping,mapDCPRecordTypeMapping,'',objCodeParamKARegion);
                    }
                    else if(!objLibContent.strContentProfileName.contains(strProfileName) || objLibContent.boolIsDeleted){
                        strAction = 'No Action';
                        strKAId = 'N/A';
                    }
                }
                if(String.isNotBlank(strKAId))
                    setFinalRunReport.add(objLibContent.strLibraryContentId+' : '+strAction+' : Success </br>');
                else
                    setFinalRunReport.add(objLibContent.strLibraryContentId+' : '+strAction+' : Failure </br>');
            }
        }catch(Exception e){
            setFinalRunReport.add(lstScope[0].strLibraryContentId+' : '+e.getMessage()+' : Failure </br>');
            System.debug('Exception-->'+e.getMessage());
            System.debug(LoggingLevel.ERROR, 'Error at line        : ' + e.getLineNumber());
            System.debug(LoggingLevel.ERROR,'The following exception has occurred:++++getMessage+++ ' + e.getMessage());
            System.debug(LoggingLevel.ERROR,'Exception type caught : ' + e.getTypeName());
            System.debug(LoggingLevel.ERROR,'Cause                 : ' + e.getCause());
            System.debug(LoggingLevel.ERROR,'Stack trace           : ' + e.getStackTraceString());
            ApexExceptions.emit('ScheduledBatchKnowledgeSyncWithICE',e);
        }
    }
    /**
    * @author KD
    * @date   26-Nov-2020
    * @description  Finish method for Batch job
    */
    public void finish(Database.BatchableContext objBatchableContext){
        CodeParametersSelector codeParameterSlctr = new CodeParametersSelector();
            List<Code_Parameter__mdt> objCodeParam = codeParameterSlctr.selectCodeParameterByDeveloperName(new Set<String>{CODEPARAMETERNAME});
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            List<String> strEmailId = new List<String>();
            if(!Test.isRunningTest()){
                    strEmailId.addAll(objCodeParam[0].Value__c.split(';'));
            }
            else
                strEmailId.add('4a72b2e1.illumina.com@amer.teams.ms');
            email.setToAddresses(strEmailId);
            String subject = 'ICE Daily Knowledge Article Sync';
            email.setSubject(subject);
            String strBody = 'Status of daily article sync </br>Library Content Id : Action : Status  </br>';
            for(String str : setFinalRunReport)
                strBody = strBody + str;
            email.setHtmlBody(strBody);
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
    }
}