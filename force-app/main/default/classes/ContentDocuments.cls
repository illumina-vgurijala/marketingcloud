/**
* @author: Pooja Shalwadi
* @date Aug-2021
* @group ContentDocument
* @description Trigger Handler on ContentDocument used to handle the functionality when user triggers an event.
* Test class for 75%:   TestApttusAgreementValidateController, TestApttusAgreements, TestCampaignMembers, TestContentDocuments, TestMasterDataRequestController
* Test class for 90%:   TestApttusAgreementValidateController, TestApttusAgreements, TestCampaignMembers, TestContentDocuments, TestMasterDataRequestController
* Modification Log:
*    -----------------------------------------------------------------------------------------------------------------------------------
*       Developer            Date            Description
*        Avina             28-Mar-2022       QACM-36, Created checkBeforeNotesDeletion Method to Prevent the Notes deletion which is associate with case
*        Nitin             19-sep-2022       CMSI-215: Instrumentation 
*        Abhishek Yadav    13-Dec-2024       CMCM-12619: Prevent Deletion of recall related Files   
*    -----------------------------------------------------------------------------------------------------------------------------------
*/
public with sharing class ContentDocuments extends ilib_SObjectDomain{
    private static final String LOG_TITLE = 'ContentDocuments';
    private static final String MANUAL_SIGNED_LOA = 'Manual Signed LOA';
    public static final String CASE_OBJECT_NAME = 'Case';//QACM-36 
    public static final String NOTE_FILETYPE = 'SNOTE';//QACM-36 
    public static final String NULLSTR = 'Null';
    /*constructor. call to super class constructor
*/
    public ContentDocuments(List<ContentDocument> sObjectList)
    {
        super(sObjectList);
    }
    /*
* Boilerplate which is required for base class instantiation logic
*/
    public class Constructor implements ilib_SObjectDomain.IConstructable
    {
        /**Constructor */
        public ilib_SObjectDomain construct(List<SObject> sObjectList)
        {
            return new ContentDocuments(sObjectList);
        }
    }
    /**
*  @author Pooja Shalwadi
*  @description - To be executed, when the ContentDocument is deleted.              
**/
    public override void onBeforeDelete(){
        validateForManualSignLOAs(records);
        checkBeforeNotesDeletion(records);//QACM-36 
        recallFilesDeletionThrowsError(records);
    }
    /*******************************************************************************************************
* @author Pooja Shalwadi
* @description : To check is the logged in user are FS or TP user and throw and error message
* @param : List of ContentDocument records
* @return : void
* UserStory: DCP-49741
*/
    public void validateForManualSignLOAs(List<ContentDocument> records){
        ilib_LogEvent.push(LOG_TITLE+'.validateForManualSignLOAs()');
        List<User> lstUser = new List<User>();
        Map<Id, ContentDocument> mapContentDocument = new Map<Id, ContentDocument>(records);
        Set<Id> setUserProfileId= new Set<Id>();
        setUserProfileId.add(Userinfo.getUserId());
        ilib_LogEvent.info('setUserProfileId : '+setUserProfileId);
        lstUser = new UsersSelector().selectByUserId(setUserProfileId);
        ilib_LogEvent.info('lstUser : '+UtilsCollection.getSetOfIds(lstUser));
        if(!lstUser.isEmpty() && String.isNotBlank(lstUser[0].User_Profile_Name__c) && (lstUser[0].User_Profile_Name__c==Label.pProfileName_TechnicalSupport || lstUser[0].User_Profile_Name__c==Label.Field_Service)){
           
            for(ContentVersion cv:new ContentVersionsSelector().selectByContentDocumentForManualLOA(mapContentDocument.keySet(),MANUAL_SIGNED_LOA))
            {
                if(mapContentDocument.containsKey(cv.ContentDocumentId)){
                    mapContentDocument.get(cv.ContentDocumentId).addError(Label.ManualLOAErrorMessage);
                }
            } 
        }
        ilib_LogEvent.pop();
    }
    /*******************************************************************************************************
/** @author Avina
* @description : QACM-36 Method to Prevent the Notes deletion which is associate with case
* @param : List of ContentDocument records
* @return : void
*/
    public void checkBeforeNotesDeletion(List<ContentDocument> records){
        ilib_LogEvent.push(LOG_TITLE+'checkBeforeNotesDeletion()');
        try{
            Map<Id, ContentDocument> mapContentDocument = new Map<Id, ContentDocument>();
            String strObjName;
            Id objectId;
            for(ContentDocument cd : records){
                if(cd.FileType == NOTE_FILETYPE){
                    mapContentDocument.put(cd.Id,cd);
                }
            }
            ilib_LogEvent.info('mapContentDocument : '+(mapContentDocument != Null ? String.valueof(mapContentDocument.keySet()):NULLSTR));
            if(!mapContentDocument.isEmpty()){
                for(ContentDocumentLink cdLink : new ContentDocumentLinksSelector().selectContentDocLinkByConDocId(mapContentDocument.keySet())){
                    objectId = cdLink.LinkedEntityId;
                    ilib_LogEvent.message('objectId : '+objectId);
                    strObjName = objectId.getSObjectType().getDescribe().getName();
                    if(strObjName == CASE_OBJECT_NAME){
                        ilib_LogEvent.message('ObjectCaseName: '+strObjName);
                        mapContentDocument.get(cdLink.ContentDocumentId).addError(Label.RestrictNotesDeletionError);  
                    }
                }
            }
        }  
        Catch(Exception e)
        {
            ApexExceptions.emit(LOG_TITLE+'checkBeforeNotesDeletion()',e,ilib_LogEvent.SERVICE);
        }
        ilib_LogEvent.pop();
    }
     /**
    *  @author Nitin
    *  @description  CMSI-215,method will return the workstream
    *  @return string
    **/
    public override string getWorkstream(){
        return ilib_LogEvent.SERVICE;
    }
    /*******************************************************************************************************
    /** @author Abhishek Yadav
    * @description : CMCM-12619: Prevent Deletion of recall related Files
    * @param : List of ContentDocument records
    * @return : void
    */
    public void recallFilesDeletionThrowsError(List<ContentDocument> records) {
        ilib_LogEvent.push(LOG_TITLE+'recallFilesDeletionThrowsError()');
        Set<Id> adminProfileId = Profiles.getAdminProfileId();
        Map<Id, ContentDocument> mapOfContentDocument = new Map<Id, ContentDocument>(records);
        List<ContentVersion> contentVersionList = new List<ContentVersion>();
        contentVersionList = new ContentVersionsSelector().selectByContentDocumentId(mapOfContentDocument.KeySet());
        ilib_LogEvent.message('contentVersionList--' + contentVersionList);
        if(contentVersionList != null && !contentVersionList.isEmpty()) {
            for(ContentVersion cv : contentVersionList) {
                if(cv.IsRecallRelated__c == true && mapOfContentDocument.containsKey(cv.ContentDocumentId) && !adminProfileId.contains(UserInfo.getProfileId())) {
                    mapOfContentDocument.get(cv.ContentDocumentId).addError(Label.preventRecallFileDelete); 
                }
            }
        }
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
    }
}