/* @ author       : KD
* @ date         : 23-Nov-2020
* @ Description  : Controller class for Knowledge Association Component
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID      Description
 ---------------------------------------------------------------------------------------------------------------------------------------
*/
public with sharing class KnowledgeAssociationComponentController {
    /**
    *  @author KD
    *  @description search KA based on query string 
    *  @param String SearchKey, String Record Id
    *  @return String
    **/
    @AuraEnabled  
    public static string fetchKnowledgeArticles(String strSearchKey,String strParentKnowledgeId){
        try{
            List<Knowledge_Association__c> lstExistingKnowledgeAssociation = new KnowledgeAssociationSelector().getAssociationByParentId(strParentKnowledgeId);
            List<AssociatedKnowledgeRecords> lstAssociatedKnowledgeRecords = new List<AssociatedKnowledgeRecords>();
            String strSearchKeyUpdated = '%' + strSearchKey + '%';
            List<Knowledge__kav> lstKA = new KnowledgeArticlesSelector().selectArticleByTitleExcludedList(strSearchKeyUpdated,UtilsCollection.getSetOfIds(lstExistingKnowledgeAssociation,'Related_Knowledge__c'));
            for(Knowledge__kav objKA : lstKA){
                lstAssociatedKnowledgeRecords.add(new AssociatedKnowledgeRecords(objKA));
            }
            return JSON.serialize(lstAssociatedKnowledgeRecords);
        }
        catch(Exception e){
            errorHandling(e);
            throw new AuraHandledException(e.getMessage()); 
        }
    }
    /**
    *  @author KD
    *  @description fetch related article
    *  @param  String Record Id
    *  @return String
    **/
    @AuraEnabled
    public static string fetchRelatedKnowledge(String strParentKnowledgeId){
        try{
            Map<String,List<AssociatedKnowledgeRecords>> mapRecordTypeToAssociation = new Map<String,List<AssociatedKnowledgeRecords>>();
            List<Knowledge_Association__c> lstKnowledgeAssociation = new KnowledgeAssociationSelector().getAssociationByParentId(strParentKnowledgeId);
            for(Knowledge_Association__c objKA : lstKnowledgeAssociation){
                if(!mapRecordTypeToAssociation.containsKey(objKA.Related_Knowledge__r.RecordType.Name))
                    mapRecordTypeToAssociation.put(objKA.Related_Knowledge__r.RecordType.Name,new List<AssociatedKnowledgeRecords>());
                mapRecordTypeToAssociation.get(objKA.Related_Knowledge__r.RecordType.Name).add(new AssociatedKnowledgeRecords(objKA));
            }
            return '{"lstKnowledgeAssociationWrap": '+JSON.serialize(mapRecordTypeToAssociation)+','
                        +' "mapLabels": '+JSON.serialize(generateLabelMap())+'}';
        }
        catch(Exception e){
            errorHandling(e);
            throw new AuraHandledException(e.getMessage()); 
        }
    }
    /**
    *  @author KD
    *  @description Generate map of labels
    *  @param 
    **/
    public static Map<String,String> generateLabelMap(){
        Map<String,String> mapLabels = new Map<String,String>();
        mapLabels.put('UI_Label_Search_Knowledge_Article',Label.UI_Label_Search_Knowledge_Article);
        mapLabels.put('UI_Label_Knowledge_Card',Label.UI_Label_Knowledge_Card);
        mapLabels.put('UI_Message_Knowledge_Dissociation',Label.UI_Message_Knowledge_Dissociation);
        mapLabels.put('UI_Message_Knowledge_Dissociation_Success',Label.UI_Message_Knowledge_Dissociation_Success);
        mapLabels.put('UI_Message_Knowledge_Association_Success',Label.UI_Message_Knowledge_Association_Success);
        return mapLabels;
    }
    /**
    *  @author KD
    *  @description Wrapper class for Agreement
    **/
    public class AssociatedKnowledgeRecords{
        public string strRecordId,strRelatedRecordId,strTitle,strSummary,strRecordType,strRecordURL,strSource,strLastModifiedDate;
        AssociatedKnowledgeRecords(Knowledge_Association__c objKA){
            this.strRecordId = objKA.Id;
            this.strTitle = objKA.Related_Knowledge__r.Title;
            this.strRelatedRecordId = '/lightning/r/Knowledge__kav/'+objKA.Related_Knowledge__c+'/view';
            this.strRecordURL = '/'+objKA.Id;
            this.strSource = objKA.Related_Knowledge__r.Knowledge_Source__c;
            this.strLastModifiedDate = String.valueof(objKA.Related_Knowledge__r.LastModifiedDate.date());
        }
        AssociatedKnowledgeRecords(Knowledge__kav objKA){
            this.strRecordURL ='/lightning/r/Knowledge__kav/'+objKA.Id+'/view';
            this.strRecordId = objKA.Id;
            this.strTitle = objKA.Title;
            this.strRecordType = objKA.RecordType.Name;
            this.strSource = objKA.Knowledge_Source__c;
            this.strLastModifiedDate = String.valueof(objKA.LastModifiedDate.date());
        }
    }
    /**
    *  @author KD
    *  @description Error Handling 
    *  @param Exception
    **/
    public static void errorHandling(Exception e){
        System.debug(LoggingLevel.ERROR, 'Error at line        : ' + e.getLineNumber());
        System.debug(LoggingLevel.ERROR,'The following exception has occurred:++++getMessage+++ ' + e.getMessage());
        System.debug(LoggingLevel.ERROR,'Exception type caught : ' + e.getTypeName());
        System.debug(LoggingLevel.ERROR,'Cause                 : ' + e.getCause());
        System.debug(LoggingLevel.ERROR,'Stack trace           : ' + e.getStackTraceString());
    }
}