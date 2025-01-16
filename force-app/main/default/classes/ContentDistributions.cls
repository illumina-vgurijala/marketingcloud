/**
* @author: Abhishek Yadav
* @date Dec-2024
* @group ContentDistribution
* @description Trigger Handler on ContentDistribution used to handle the functionality when user triggers an event.
* Modification Log:
*    -----------------------------------------------------------------------------------------------------------------------------------
*       Developer            Date            Description
*       Abhishek Yadav    13-Dec-2024       Initial Version. CMCM-12619: Prevent Deletion of recall related Files
*    -----------------------------------------------------------------------------------------------------------------------------------
*/
public with sharing class ContentDistributions extends ilib_SObjectDomain {
    private static final String LOG_TITLE = 'ContentDistributions';
    /*
    * constructor. call to super class constructor
    */
    public ContentDistributions(List<ContentDistribution> sObjectList) {
        super(sObjectList);
    }
    /*
    * Boilerplate which is required for base class instantiation logic
    */
    public class Constructor implements ilib_SObjectDomain.IConstructable {
        /*
        * Constructor
        */
        public ilib_SObjectDomain construct(List<SObject> sObjectList) {
            return new ContentDistributions(sObjectList);
        }
    }
    /**
    *  @author Abhishek Yadav
    *  @description - To be executed, when the ContentDistribution is inserted.              
    **/
    public override void onBeforeInsert() {
        recallFilesPublicLinkCreationThrowsError(records);
    }
    /**
    *  @author Abhishek Yadav
    *  @description - prevent public Link creation.              
    **/
    public void recallFilesPublicLinkCreationThrowsError(List<ContentDistribution> records) {
        ilib_LogEvent.push(LOG_TITLE+'.recallFilesPublicLinkCreationThrowsError()');
        Set<Id> adminProfileId = Profiles.getAdminProfileId();
        Map<Id,ContentDistribution> contentVerIdCDMap = new Map<Id,ContentDistribution>();
        List<ContentVersion> contentVersionList = new List<ContentVersion>();
        ilib_LogEvent.message('ContentDistribution records--' + records);
        for(ContentDistribution cd : records) {
            if(cd.ContentVersionId != null) {
                contentVerIdCDMap.put(cd.ContentVersionId,cd);
            }
        }
        ilib_LogEvent.message('contentVerIdCDMap--' + contentVerIdCDMap);
        if(contentVerIdCDMap != null && !contentVerIdCDMap.isEmpty()) {
            contentVersionList = new ContentVersionsSelector().selectByContentVersionId(contentVerIdCDMap.keySet());
        }
        ilib_LogEvent.message('contentVersionList--' + contentVersionList);
        if(contentVersionList != null && !contentVersionList.isEmpty()) {
            for(ContentVersion cv : contentVersionList) {
                if(cv.IsRecallRelated__c == true && contentVerIdCDMap.containsKey(cv.Id) && !adminProfileId.contains(UserInfo.getProfileId())) {
                    contentVerIdCDMap.get(cv.Id).addError(Label.preventRecallFileDelete); 
                }
            }
        }
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
    }
}