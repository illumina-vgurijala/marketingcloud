/***************************************************************************************************************************************
* NAME         : ContentVersions
* DESCRIPTION  : Trigger Handler for ContentVersion object.              
* @AUTHOR      : Vignesh Sethuramlaingam 
* @DATE        : 11-Mar-2022  
* 
* MODIFICATION LOG: 
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                    DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------
* Vignesh Sethuramlaingam    11-Mar-2022             Initial Version
****************************************************************************************************************************************/ 
public with sharing class ContentVersions extends ilib_SObjectDomain {
	private static final String LOG_TITLE = 'ContentVersions';
	public static final Integer SF_SUPPORTED_EXT_LENGTH = 13;
	private static final String FEATURE_SERVICE_CHECK_FILE_EXTENSION = 'CheckFileExtension';

	/*constructor. call to super class constructor
	 */
	public ContentVersions(List<ContentVersion> sObjectList)
	{
		super(sObjectList);
		ilib_LogEvent.rootTitle = LOG_TITLE;
	}
	
	/*
	* Boilerplate which is required for base class instantiation logic
	*/
	public class Constructor implements ilib_SObjectDomain.IConstructable
	{
		/**Constructor */
		public ilib_SObjectDomain construct(List<SObject> sObjectList)
		{
			return new ContentVersions(sObjectList);
		}
	}
	
	/**Overrided method from Super class. Handles before Insert Trigger  event  */
	public override void onBeforeInsert(){
        ilib_LogEvent.push(LOG_TITLE + '.onBeforeInsert()');

		if(Feature.isOn(FEATURE_SERVICE_CHECK_FILE_EXTENSION)){
			//call method to crop file extension.
			checkFileExtension(records);
		}
		recallFilesUploadNewVersionThrowsError(records);
        ilib_LogEvent.pop();
	}
	
	/*
	@Name:checkFileExtension
	@Description: Method to crop extension name if exceeds limit
	@Param: list<ContentVersion>
	@Return:void 
	*/
	public static void checkFileExtension(List<Sobject> records){
		for(ContentVersion cv :(List<ContentVersion>) records){
		if(cv.PathOnClient != Null && cv.PathOnClient.contains('.')){
			String strExtension = cv.PathOnClient.substringAfterLast('.');
			if(strExtension.length() > SF_SUPPORTED_EXT_LENGTH){
				cv.PathOnClient = cv.PathOnClient.left(cv.PathOnClient.substringBeforeLast('.').length()+ 1 + SF_SUPPORTED_EXT_LENGTH  );
			}
		 }
		 }
	}
	/*
	@Name:recallFilesUploadNewVersionThrowsError
	@Description: Method to prevent uploading new version of recall file
	@Param: list<ContentVersion>
	@Return:void 
	*/
	public void recallFilesUploadNewVersionThrowsError(List<ContentVersion> records) {
		ilib_LogEvent.push(LOG_TITLE + '.recallFilesUploadNewVersionThrowsError()');
		Set<Id> adminProfileId = Profiles.getAdminProfileId();
		Map<Id,ContentVersion> contentDocumentCVMap = new Map<Id,ContentVersion>();
		List<ContentVersion> contentVersionList = new List<ContentVersion>();
		ilib_LogEvent.message('records--' + records);
		for(ContentVersion cv : records) {
			if(cv.ContentDocumentId != null) {
				contentDocumentCVMap.put(cv.ContentDocumentId , cv);
			}
		}
		ilib_LogEvent.message('contentDocumentCVMap--' + contentDocumentCVMap);
		if(contentDocumentCVMap != null && !contentDocumentCVMap.isEmpty()) {
			contentVersionList = new ContentVersionsSelector().selectByContentDocumentId(contentDocumentCVMap.KeySet());
		}
        ilib_LogEvent.message('contentVersionList--' + contentVersionList);
        if(contentVersionList != null && !contentVersionList.isEmpty()) {
            for(ContentVersion cv : contentVersionList) {
                if(cv.IsRecallRelated__c == true && contentDocumentCVMap.containsKey(cv.ContentDocumentId) && !adminProfileId.contains(UserInfo.getProfileId())) {
                    contentDocumentCVMap.get(cv.ContentDocumentId).addError(Label.preventRecallFileDelete); 
                }
            }
        }
		ilib_LogEvent.pop();
        ilib_LogEvent.emit();
	}
}