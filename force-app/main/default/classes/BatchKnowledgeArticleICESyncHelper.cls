/**
 *    @author KD
 *    @date   8-Dec-2020
 *    @description  Helper class for BatchKnowledgeArticleICESync
 *    Modification Log:
 *    ---------------------------------------------------------------------------------------------------------------------
 *             Developer                      Date                Description
 *             Sarath Pullanikkatt            17-Apr-2021         Article Upsert Logic Changed to Use Document Number
 *             Gladis                         22-Sep-2021         CMCP-122 Check for Distribution Articles 
 *    ---------------------------------------------------------------------------------------------------------------------
 *
 */
public with sharing class BatchKnowledgeArticleICESyncHelper {

    private static final String STRING_REGIONAL_DISTRIBUTION = 'Regional Distribution';
    private static final String STRING_CONTENT_ASSET_TYPE = 'Content Asset Type';
    private static final String STRING_ALLOWED_DISTRIBUTION = 'Allowed Distribution';
    
    /**
    * @author KD
    * @date    8-Dec-2020
    * @description   method to create/Edit knowledge article
    */
    public static string upsertArticle(String strAccessToken,KnowledgeSyncWrapper.LibraryContentDetails objLibContent,Map<String,String> mapICEToDCPMapping,Map<String,String> mapDCPRecordTypeMapping,String strOnlineVersionId, Code_Parameter__mdt objCodeParamKARegion){
        return upsertArticles(strAccessToken, objLibContent.strDocumentNumber, objLibContent.strLibraryContentURL,objLibContent.strTeamSiteId,objLibContent.strLibraryContentId,mapICEToDCPMapping,mapDCPRecordTypeMapping,strOnlineVersionId,objCodeParamKARegion);
    }
     /**
    * @author KD
    * @date    8-Dec-2020
    * @description   method to create/Edit knowledge article
    */
    public static string upsertArticles(String strAccessToken, String strDocumentNumber, String strLibraryContentURL,String strTeamSiteId,String strLibraryContentId,Map<String,String> mapICEToDCPMapping,Map<String,String> mapDCPRecordTypeMapping,String strOnlineVersionId, Code_Parameter__mdt objCodeParamKARegion){
        String strDraftKAArticleId = '';
        KnowledgeSyncWrapper.FileContent objFileContent = KnowledgeArticleICESyncConnector.fetchFileContent(strAccessToken,strTeamSiteId,strLibraryContentId);
        System.debug('KnowledgeSyncWrapper.FileContent-->'+objFileContent);
        if(objFileContent != null){
            if(String.isNotBlank(strOnlineVersionId))
                strDraftKAArticleId = createDraftArticle(strOnlineVersionId);
            Knowledge__kav objKA = syncICEContent(objFileContent, strDocumentNumber, strLibraryContentURL,strTeamSiteId,mapICEToDCPMapping,mapDCPRecordTypeMapping,strDraftKAArticleId,objCodeParamKARegion);
            upsert objKA;
            List<Knowledge__kav> lstKAUpserted = new KnowledgeArticlesSelector().selectArticleByDocumentNumber(strDocumentNumber, 'Draft');
            publishArticle(lstKAUpserted[0].KnowledgeArticleId);
            return objKA.id;
        }
        else 
            return '';
    }
    /**
    * @author KD
    * @date    8-Dec-2020
    * @description   method to publishArticle article
    */  
    public static void publishArticle(String strKAId){
        KbManagement.PublishingService.publishArticle(strKAId, true);
    }
    /**
    * @author KD
    * @date    8-Dec-2020
    * @description   populate article value as per ICE content
    */
    public static Knowledge__kav syncICEContent(KnowledgeSyncWrapper.FileContent objFileContent, String strDocumentNumber, String strURL,String strTeamSiteId,Map<String,String> mapICEToDCPMapping,Map<String,String> mapDCPRecordTypeMapping,String strDraftVersionId,Code_Parameter__mdt objCodeParamKARegion){
        Knowledge__kav objKA = new Knowledge__kav();
        if(String.isNotBlank(strDraftVersionId)){
            objKA.id = strDraftVersionId;
        }
        objKA.Primary_Workflow__c = 'External Content';
        objKA.Secondary_Workflow__c = 'External Content';
        objKA.Title = objFileContent.name.replaceAll('_',' ');
        objKA.Summary =  objFileContent.description != null ? objFileContent.description : objFileContent.name;
        objKA.Article_Body__c =  'Knowledge content is in an external system, click on Link to External Content to view the content. New window will be displayed with knowledge content.';
        objKA.External_Content_ID__c = objFileContent.id;
        objKA.Document_Number__c = strDocumentNumber;
        objKA.Link_to_External_Content__c = strURL;
        objKA.Knowledge_Source__c = 'ICE';
        objKA.TeamSite_ID__c = strTeamSiteId;
        objKA.ValidationStatus = 'Not Applicable';
        objKA.UrlName =  objFileContent.name.replaceAll('[^a-zA-Z0-9\\-s]', '');
        objKA.Content_Format__c =objFileContent.format;

        for(KnowledgeSyncWrapper.ContentProperties objContentProperty : objFileContent.properties){
            if(mapICEToDCPMapping.containsKey(objContentProperty.name)){
                system.debug('objContentProperty-->'+objContentProperty.name);
                if(objContentProperty.name == STRING_REGIONAL_DISTRIBUTION) {
                    //TASK0570079
                        objKA.put(mapICEToDCPMapping.get(objContentProperty.name),objContentProperty.values.size() == Integer.valueOf(objCodeParamKARegion.Value__c) ? 'Global' : string.join(objContentProperty.values,';').replace('For ',''));
                    //End of TASK0570079
                }
                else if(objContentProperty.name == STRING_CONTENT_ASSET_TYPE) {
                    Id idRecordTypeId = Schema.SObjectType.Knowledge__kav.getRecordTypeInfosByName().get(mapDCPRecordTypeMapping.get(objContentProperty.values[0])).getRecordTypeId();
                    objKA.put('RecordTypeId',idRecordTypeId);
                    objKA.put(mapICEToDCPMapping.get(objContentProperty.name),string.join(objContentProperty.values,';'));
                }
                //CMCP-122 Starts 
                else if(objContentProperty.name == STRING_ALLOWED_DISTRIBUTION) {
                    string strDistribution = string.join(objContentProperty.values,';');
                    if (strDistribution!=null && (strDistribution.containsIgnoreCase('Public') || strDistribution.containsIgnoreCase('Channel Partner'))){
                        objKA.put('IsVisibleInPrm',true);
                    }
                    objKA.put(mapICEToDCPMapping.get(objContentProperty.name),string.join(objContentProperty.values,';'));
                }
                //CMCP-122 Ends 
                else{
                    objKA.put(mapICEToDCPMapping.get(objContentProperty.name),string.join(objContentProperty.values,';'));
                }
            }
        }
        System.debug('Knowledge to Create -->'+objKA);
        return objKA;
    }
    /**
     * @author KD
     * @date    8-Dec-2020
     * @description   Create Draft article
     */
    public static String createDraftArticle(Id idOnlineArticleVersionId){
        return KbManagement.PublishingService.editOnlineArticle(idOnlineArticleVersionId, false);
    }
}