/**
 *    @author KD
 *    @date   8-Dec-2020
 *    @description  Controller class for KnowledgeOnDemandSyncComponent
 *    Modification Log:
 *    ---------------------------------------------------------------------------------------------------------------------
 *             Developer                      Date                Description
   ---------------------------------------------------------------------------------------------------------------------
 *
 */
public with sharing class KnowledgeOnDemandSyncCmpController {
    /**
     * @author KD
     * @date    8-Dec-2020
     * @description   method to sync article
     */
    @AuraEnabled
    public static string onDemandSync(String strKnowledgeId){
        Map<String,String> mapICEToDCPMapping = new Map<String,String>();
        Map<String,String> mapDCPRecordTypeMapping = new Map<String,String>();
        //TASK0570079
        Code_Parameter__mdt objCodeParamKARegion = new CodeParametersSelector().selectCodeParameterByDeveloperName(new Set<String>{BatchKnowledgeArticleICESync.CODEPARAMETERKAREGION})[0];
        //End of TASK0570079
        try {
            Id idKnowledgeId = Id.valueOf(strKnowledgeId);
            Knowledge__kav objKA = new KnowledgeArticlesSelector().selectById(new Set<Id>{idKnowledgeId})[0];
            List<Knowledge_Sync_Mapping__mdt> lstMapping = new KnowledgeSyncMappingSelector().selectKnowledgeSyncMapping();
            for(Knowledge_Sync_Mapping__mdt objMapping : lstMapping){
                if(objMapping.Type__c == 'Picklist'){
                    mapDCPRecordTypeMapping.put(objMapping.MasterLabel,objMapping.Value__c);
                }
                else
                    mapICEToDCPMapping.put(objMapping.MasterLabel,objMapping.Value__c);
            }
            String strAccessToken = KnowledgeArticleICESyncConnector.getAccessToken('On Demand Sync',false);
            System.debug(strAccessToken);
            return BatchKnowledgeArticleICESyncHelper.upsertArticles(strAccessToken, objKA.Document_Number__c, objKA.Link_to_External_Content__c,objKA.TeamSite_ID__c,objKA.External_Content_ID__c,mapICEToDCPMapping,mapDCPRecordTypeMapping,objKA.KnowledgeArticleId,objCodeParamKARegion);
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error at line        : ' + e.getLineNumber());
            System.debug(LoggingLevel.ERROR,'The following exception has occurred:++++getMessage+++ ' + e.getMessage());
            System.debug(LoggingLevel.ERROR,'Exception type caught : ' + e.getTypeName());
            System.debug(LoggingLevel.ERROR,'Cause                 : ' + e.getCause());
            System.debug(LoggingLevel.ERROR,'Stack trace           : ' + e.getStackTraceString());
            ApexExceptions.emit('KnowledgeOnDemandSync',e);
            throw new AuraHandledException(e.getMessage());
        }
    }
}