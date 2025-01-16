/***************************************************************************************************************************************
* @NAME   : QualtricsSurveyResponseShareService
* @DESCRIPTION  : Class for Sharing QSR records Based on proxy User Update.               
* @AUTHOR : Vignesh
* @DATE   : 18-Jun-2020  
* 
* MODIFICATION LOG: 
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------
* Vignesh               18-Jun-2020         Initial Version. 
****************************************************************************************************************************************/

public without sharing class QualtricsSurveyResponseShareService{
    
    /**
    *  @author Vignesh
    *  @description - Method to Update Share record for QSR Record based on Proxy Owner. 
    *               
    **/
    public static void updateQSRShareBasedOnProxy(list<Qualtrics_Survey_Response__c> lstQSR, Map<Id,Qualtrics_Survey_Response__c> oldMap){
        set<Id> setQSRIds = new set<Id>();
        list<Id> lstUserIds = new list<Id>();
        Map<Id,Id> mapQSRIDProxyUserIdToRemoveAccess = new Map<Id,Id>();
        Map<Id,Qualtrics_Survey_Response__Share> mapQSRIDProxyUserIdToProvideAccess = new Map<Id,Qualtrics_Survey_Response__Share>();
        
        for(Qualtrics_Survey_Response__c qsrObj : lstQSR){
            Qualtrics_Survey_Response__c oldqsrObj = oldMap != Null ? oldMap.get(qsrObj.Id) : Null;
            
            if(String.isNotBlank(qsrObj.Proxy_Owner__c) && (oldqsrObj == Null || qsrObj.Proxy_Owner__c != oldqsrObj.Proxy_Owner__c)){
                Qualtrics_Survey_Response__Share jobShr  = new Qualtrics_Survey_Response__Share();
                jobShr.ParentId = qsrObj.id;
                jobShr.UserOrGroupId = qsrObj.Proxy_Owner__c;
                jobShr.AccessLevel = 'Edit';
                jobShr.RowCause = Schema.Qualtrics_Survey_Response__Share.RowCause.Manual;
                
                mapQSRIDProxyUserIdToProvideAccess.put(qsrObj.Id , jobShr );
                setQSRIds.add(qsrObj.Id);
                lstUserIds.add(qsrObj.Proxy_Owner__c);
            }
            
            if(oldqsrObj != Null && qsrObj.Proxy_Owner__c != oldqsrObj.Proxy_Owner__c && String.isNotBlank(oldqsrObj.Proxy_Owner__c )){
                mapQSRIDProxyUserIdToRemoveAccess.put(qsrObj.Id, oldqsrObj.Proxy_Owner__c);
                setQSRIds.add(qsrObj.Id);
                lstUserIds.add(oldqsrObj.Proxy_Owner__c);
            }
        }
        
        if(!setQSRIds.isEmpty()){
            list<Qualtrics_Survey_Response__Share> lstQSRShareToDel = new list<Qualtrics_Survey_Response__Share>();
            for(Qualtrics_Survey_Response__Share objQSRShare : (new QualtricsSurveyResponseShareSelector().getShareRecordsWithParentId(setQSRIds, lstUserIds, 'Manual'))){
                if(mapQSRIDProxyUserIdToRemoveAccess.containsKey(objQSRShare.ParentId) && mapQSRIDProxyUserIdToRemoveAccess.get(objQSRShare.ParentId) == objQSRShare.UserOrGroupId ){
                    lstQSRShareToDel.add(objQSRShare);
                }
                
                if(mapQSRIDProxyUserIdToProvideAccess.containsKey(objQSRShare.ParentId) && mapQSRIDProxyUserIdToProvideAccess.get(objQSRShare.ParentId).UserOrGroupId == objQSRShare.UserOrGroupId){
                    if( objQSRShare.AccessLevel != 'Edit' ){
                        objQSRShare.AccessLevel = 'Edit';
                    }
                    mapQSRIDProxyUserIdToProvideAccess.put(objQSRShare.ParentId, objQSRShare);
                }
            }
                     
            upsert mapQSRIDProxyUserIdToProvideAccess.values();
            
            delete lstQSRShareToDel;
        }
    }
}