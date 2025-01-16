/**
* @author Shivani Jain
* @date 15 March 2022
*
* @description DCP-51321 Clean up Case Email Attachments
* Used in enahncedFilesCmp LWC
*/
public with sharing class EnhancedFileListController {

    static final String LOG_TITLE = 'EnhancedFileListController'; 

    /*******************************************************************************************************
    * @description method to return ContentDocumentLink records 
    * @param recordId Id 
    * @param excludeLogos Boolean
    * @return ResultWrapper
    */
	@AuraEnabled(cacheable=true)
    public static ResultWrapper getFilesList(Id recordId, Boolean excludeLogos, Boolean includeChildEmailRecs) {
        ResultWrapper result = new ResultWrapper();
        List<EnhancedFile> enhancedFilesLst = new List<EnhancedFile>();
        List<ContentDocumentLink> filesList;
        Set<Id> recsSet = new Set<Id>();

        try {
            if(includeChildEmailRecs) {
                List<EmailMessage> emailMsgs = new List <EmailMessage> 
                    (new EmailMessagesSelector().selectEmailMsgsByParentWithAttachment(new Set<Id>{recordId}));
                recsSet = UtilsCollection.getSetOfIds(emailMsgs);
            }
            recsSet.add(recordId);

            if(excludeLogos) {
                filesList = queryFilesWithoutLogos(recsSet);
                List<ContentDocumentLink> filesListTemp = queryFilesWithLogos(recsSet);
                result.hiddenFilesCount = filesListTemp != NULL && filesList != NULL ? filesListTemp.size() - filesList.size() : 0;
            } else {
                filesList = queryFilesWithLogos(recsSet);
                result.hiddenFilesCount = 0;
            }

            if(filesList != NULL && !filesList.isEmpty()) {
                for(ContentDocumentLink cdLink : filesList) {
                    enhancedFilesLst.add(new EnhancedFile(cdLink.ContentDocument.Id, cdLink.ContentDocument.Title,
                        cdLink.ContentDocument.FileExtension, cdLink.ContentDocument.CreatedDate,
                        cdLink.ContentDocument.LastModifiedDate, cdLink.ContentDocument.ContentSize));
                } 
            }
        } catch(Exception ex) {
            ApexExceptions.emit(LOG_TITLE, recordId, ex);
            throw new AuraHandledException(ex.getMessage());
        }

        result.enhancedFiles = enhancedFilesLst;
        return result;
    }

    /*******************************************************************************************************
    * @description method to query all contentDocumentLinks 
    * @param recordId Id 
    * @return List<ContentDocumentLink>
    */
    public static List<ContentDocumentLink> queryFilesWithLogos(Set<Id> recsSet) {
        return new List <ContentDocumentLink>(new ContentDocumentLinksSelector().selectByEmailMessagesIds(recsSet));
    }

    /*******************************************************************************************************
    * @description method to query contentDocumentLinks excluding potential logos and signatures
    * @param recordId Id 
    * @return List<ContentDocumentLink>
    */
    public static List<ContentDocumentLink> queryFilesWithoutLogos(Set<Id> recsSet) {
        return new List <ContentDocumentLink>(new ContentDocumentLinksSelector().selectContentDocumentLinksWithoutLogos(recsSet));  
    }
    
    /*******************************************************************************************************
    * @description Wrapper class to hold File record
    */
    public class EnhancedFile {
        @AuraEnabled
        public Id ContentDocId;
        @AuraEnabled
        public String Title;
        @AuraEnabled
        public String RecordURL;
        @AuraEnabled
        public String FileExtension;
        @AuraEnabled
        public String CreatedDate;
        @AuraEnabled
        public String LastModifiedDate;
        @AuraEnabled
        public Integer ContentSize;
        
        /***************************************************************************************************
        * @description Constructor
        */
        public EnhancedFile(id contentDocId, String title, String fileExtension, DateTime createdDate, 
                                                    DateTime lastModifiedDate, Integer contentSize) {
            this.ContentDocId = contentDocId;
            this.Title = title;
            this.FileExtension = fileExtension;
            this.CreatedDate = createdDate.format('MMMM dd, YYYY, h:mm a');
            this.LastModifiedDate = lastModifiedDate.format('MMMM dd, YYYY, h:mm a');
            this.ContentSize = contentSize;
            this.RecordURL = '/' + contentDocId;
        }
    }

    /*******************************************************************************************************
    * @description Wrapper class to hold Result for sending to LWC
    */
    public class ResultWrapper {
        @AuraEnabled
        public List<EnhancedFile> enhancedFiles;
        @AuraEnabled
        public Integer hiddenFilesCount;

    }

}