/**
*    @author Raja Siva Krishna
*    @date   2020-11-19
*    @description    DCP-43185: DocumentUploadController class
*    Modification Log:
*    ------------------------------------------------------------------------------------ 
*             Developer                      Date                Description
*             Raja Siva Krishna             19/11/2020          Initial Version
*     ------------------------------------------------------------------------------------ 
*                    
*/
public with sharing class DocumentUploadController {
    /* @author Raja Siva Krishna
    *  @description get workdetails activity and uploaded document names and have them in a wrapper
    */
    @AuraEnabled(cacheable=true)
    public static WorkDetailsFieldsWrapper getWrapperFieldDetails(Id recId) {
        try{
            //Boolean boolLatestCompletion = false;
            List<SVMXC__Service_Order_Line__c> lstWd = new WorkDetailsSelector().selectWorkDetailRecords(recId);
            // SVMXC__Service_Order__c woObj = new WorkOrdersSelector().selectWorkOrdertoKnowCompletionDate(recId);
            // if(!string.isEmpty(String.valueof(woObj.Latest_Completion_Date_Time__c))){
            //     boolLatestCompletion = true;
            // }
            WorkDetailsFieldsWrapper objWdWrapper = new WorkDetailsFieldsWrapper();

            if(!lstWd.isEmpty()){
                
                for (SVMXC__Service_Order_Line__c objWd : lstWd)
                {
                    if(objWd.SVMXC__Activity_Type__c != null && !String.isBlank(objWd.SVMXC__Activity_Type__c)  && objWd.SVMXC__Line_Status__c != 'Canceled'){
                        // if(boolLatestCompletion && objWd.CreatedDate>woObj.Latest_Completion_Date_Time__c){
                        //     objWdWrapper.setAcivityType.add(objWd.SVMXC__Activity_Type__c);
                        // }
                        // else if(!boolLatestCompletion){
                        //     objWdWrapper.setAcivityType.add(objWd.SVMXC__Activity_Type__c);
                        // }
                        objWdWrapper.setAcivityType.add(objWd.SVMXC__Activity_Type__c);
                    }
                }
            }
            Map<Id,String> uploadedDocNames = getUploadedDocDetails(recId);
            objWdWrapper.mapContentDocIdtoDocName = uploadedDocNames;
            set<String> setDocNamesContentVersion = new set<String>();
            setDocNamesContentVersion.add('Genric DOC');
            set<Id> setContentDocIds = new set<Id>();
            setContentDocIds = uploadedDocNames.keyset();
            for(Id eachId:setContentDocIds){
                if(uploadedDocNames.containskey(eachId)){
                    setDocNamesContentVersion.add(uploadedDocNames.get(eachId));
                }
            }
            string strJoinDocumentNames = String.join(new List<String>(setDocNamesContentVersion),'\',\'');
            strJoinDocumentNames='\''+strJoinDocumentNames+'\'';
            objWdWrapper.setAllDocumentNames=strJoinDocumentNames;
            objWdWrapper.lstUploadedDocNames=new List<String>(setDocNamesContentVersion);
            String strWoProductId='';
            String strWoProductGrpName='';
            List<SVMXC__Service_Order__c> lstWO = new WorkOrdersSelector().selectWorkOrders(new Set<Id>{recId});
            for(SVMXC__Service_Order__c eachRec:lstWO){
                strWoProductId = eachRec.SVMXC__Product__c;
                strWoProductGrpName = eachRec.SVMXC__Product__r.Product_Group__c;
            }
            objWdWrapper.setProductId=strWoProductId;
            objWdWrapper.setProductGroup=strWoProductGrpName;
            system.debug(objWdWrapper.setAllDocumentNames+objWdWrapper.lstUploadedDocNames+objWdWrapper.setProductId+objWdWrapper.setProductGroup);
            system.debug('Final Wrapper resul::'+objWdWrapper);
            return objWdWrapper;
        }
        catch(Exception e){
            //get exception message
            throw new AuraHandledException(e.getMessage()); 
        }
    }
 
    /**
    *  @author Raja Siva Krishna
    *  @description getting uploaded documents names as a Map 
    **/
    @AuraEnabled(cacheable=true)
    public static map<Id,String> getUploadedDocDetails(Id recId) {
        //TODO [KD comment]: this can be opimzed as for file preview we only need, unless there is some other purpose.
        try{
            List<Id> lstContentDocIds = new List<Id>();
            Map<Id,String> mapIdtoDocname = new Map<Id,String>();
            List<ContentDocumentLink> lstContentDocLinks = new ContentDocumentLinksSelector().selectByMasterDataRequestId(recId);
            for(ContentDocumentLink eachContenDocId:lstContentDocLinks){
                lstContentDocIds.add(eachContenDocId.ContentDocument.Id);
            }
            List<ContentVersion> lstContentVersions = new ContentVersionsSelector().getContentVersionIdsForDocUploadComp(lstContentDocIds);
            for(ContentVersion eachContentVersion:lstContentVersions){
                if(!mapIdtoDocname.containsKey(eachContentVersion.ContentDocumentId)){
                    mapIdtoDocname.put(eachContentVersion.ContentDocumentId, eachContentVersion.Document_Type_fileupload__c);
                }
            }
            return mapIdtoDocname;
        }
        catch(Exception e){
            //get exception message
            throw new AuraHandledException(e.getMessage()); 
        }
    }
   
    /**
    *  @author Raja Siva Krishna
    *  @description Wrapper class for List of fields values
    **/
    public class WorkDetailsFieldsWrapper {
        @AuraEnabled
        public Set<String> setAcivityType {
            get {
                if (setAcivityType == null){
                    setAcivityType = new set<String>();
                }
                return setAcivityType;
            }
            set;
        }
        @AuraEnabled
        public List<String> lstUploadedDocNames {
            get {
                if (lstUploadedDocNames == null){
                    lstUploadedDocNames = new List<String>();
                }
                return lstUploadedDocNames;
            }
            set;
        }
        @AuraEnabled
        public String setAllDocumentNames {
            get {
                if (setAllDocumentNames == null){
                    setAllDocumentNames = '';
                }
                return setAllDocumentNames;
            }
            set;
        }

        @AuraEnabled
        public String setAllDocumentIDs {
            get {
                if (setAllDocumentIDs == null){
                    setAllDocumentIDs = '';
                }
                return setAllDocumentIDs;
            }
            set;
        }
        @AuraEnabled
        public String setProductId {
            get {
                if (setProductId == null){
                    setProductId = '';
                }
                return setProductId;
            }
            set;
        }
        @AuraEnabled
        public String setProductGroup {
            get {
                if (setProductGroup == null){
                    setProductGroup = '';
                }
                return setProductGroup;
            }
            set;
        }
        @AuraEnabled
        public Map<Id,String> mapContentDocIdtoDocName{
            get {
                if (mapContentDocIdtoDocName == null){
                    mapContentDocIdtoDocName = new Map<Id,String>();
                }
                return mapContentDocIdtoDocName;
            }
            set; 
        }
    }
}