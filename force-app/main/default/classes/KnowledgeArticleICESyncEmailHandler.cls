/**
 *    @author KD
 *    @date   8-Dec-2020
 *    @description  Helper class for KnowledgeArticleICESync
 *    Modification Log:
 *    ---------------------------------------------------------------------------------------------------------------------
 *             Developer                      Date                Description
   ---------------------------------------------------------------------------------------------------------------------
 *
 */
global with sharing class KnowledgeArticleICESyncEmailHandler extends ilib_RestReceiver implements Messaging.InboundEmailHandler{
    public static ilib_LogInterface.LogDetails log;
    /**
   * @author KD
   * @date    8-Dec-2020
   * @description   method to handle inbound mail
   */
   global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope){
       Messaging.InboundEmailResult objResult = new Messaging.InboundEmailresult();
       try{
           Messaging.InboundEmail.BinaryAttachment[] tAttachments = email.binaryAttachments; 
           String strCSVBody='';
           String strAccessToken;
           List<String> lstLines = new List<String>();
           List<KnowledgeSyncWrapper.LibraryContentDetails> lstLibraryContentDetailsWrapper = new List<KnowledgeSyncWrapper.LibraryContentDetails>();
           if(tAttachments !=null){
               for(Messaging.InboundEmail.BinaryAttachment btt : tAttachments){
                   if(btt.filename.endsWith('.csv')){
                       strCSVBody = btt.body.toString();
                       if(!Test.isRunningTest()){
                           strCSVBody = strCSVBody.replaceAll(',"""',',"DBLQT').replaceall('""",','DBLQT",');
                           strCSVBody = strCSVBody.replaceAll('""','DBLQT');
                       }
                       lstLines = strCSVBody.split('\n');
                       if(!lstLines.isEmpty())
                           lstLines.remove(0);
                       for(String strLines : lstLines){
                           system.debug('Lines--->'+strLines);
                           lstLibraryContentDetailsWrapper.add(new KnowledgeSyncWrapper.LibraryContentDetails(strLines));
                       }
                       system.debug('Wrapper here -->'+lstLibraryContentDetailsWrapper);
                       if(!lstLibraryContentDetailsWrapper.isEmpty()){
                           strAccessToken = KnowledgeArticleICESyncConnector.getAccessToken('ICE Integration Authorization',true);
                           logFile(btt);
                           // Calling batch inside loop as email will contain one attachment only.
                           if(strAccessToken != KnowledgeArticleICESyncConnector.ERROR)
                               Database.executeBatch(new BatchKnowledgeArticleICESync(lstLibraryContentDetailsWrapper,strAccessToken),1);
                       }
                   }
               }
           }
       }catch(Exception e){
           System.debug(LoggingLevel.ERROR, 'Error at line        : ' + e.getLineNumber());
           System.debug(LoggingLevel.ERROR,'The following exception has occurred:++++getMessage+++ ' + e.getMessage());
           System.debug(LoggingLevel.ERROR,'Exception type caught : ' + e.getTypeName());
           System.debug(LoggingLevel.ERROR,'Cause                 : ' + e.getCause());
           System.debug(LoggingLevel.ERROR,'Stack trace           : ' + e.getStackTraceString());
           ApexExceptions.emit('KnowledgeArticleICESyncEmailHandler',e);  
       }
       return objResult;
    }
    /**
   * @author KD
   * @date    8-Dec-2020
   * @description   method save incoming file
   */
    public static void logFile(Messaging.InboundEmail.BinaryAttachment objBody){
        KnowledgeArticleICESyncEmailHandler instantiated = new KnowledgeArticleICESyncEmailHandler();
        ilib_RestInterface.InterfaceDetails interfaceDetails = instantiated.interfaceDetails;
        log = ilib_LogInterface.initiateLog(interfaceDetails,'ICE Email Service');
        String strInterfaceLogId = ilib_LogInterface.finalizeLog(log,ilib_LogInterface.RESULT_SUCCESS,'Check Files for details');
        ContentVersion objConVer = new ContentVersion();
        objConVer.ContentLocation = 'S';
        objConVer.PathOnClient = objBody.fileName;
        objConVer.Title = objBody.fileName;
        objConVer.VersionData = objBody.body;
        insert objConVer;    //Insert ContentVersion
        Id idConDoc = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:objConVer.Id].ContentDocumentId;
        //create ContentDocumentLink  record 
        ContentDocumentLink objConDocLink = New ContentDocumentLink();
        objConDocLink.LinkedEntityId = strInterfaceLogId;
        objConDocLink.ContentDocumentId = idConDoc;  //ContentDocumentId Id from ContentVersion
        objConDocLink.shareType = 'V';
        insert objConDocLink;
    }
}