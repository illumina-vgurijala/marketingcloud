/**
 *    @author Vignesh
 *    @date   13-Jan-2021
 *    @description  EMail handler for Knowldge Article Data Remeditation.
 *    Modification Log:
 *    ---------------------------------------------------------------------------------------------------------------------
 *             Developer                      Date                Description
   ---------------------------------------------------------------------------------------------------------------------
 *
 */
global without sharing class KnowledgeArticleDataRemediate implements Messaging.InboundEmailHandler{
  
    /**
    * @author Vignesh
    * @date   13-Jan-2021
    * @description   method to handle inbound mail
    */
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope){
        Messaging.InboundEmailResult objResult = new Messaging.InboundEmailresult();
        try{
            Messaging.InboundEmail.BinaryAttachment[] tAttachments = email.binaryAttachments; 
            String strCSVBody='';
            List<String> lstLines = new List<String>();
            
            List<KnowledgeArticleDataRemediate.KnowledgeArticleWrapper> lstKnowledgeArticleWrapper = new List<KnowledgeArticleDataRemediate.KnowledgeArticleWrapper>();
            
            if(tAttachments != null){
                for(Messaging.InboundEmail.BinaryAttachment btt : tAttachments){
                    if(btt.filename.endsWith('.csv')){
                         strCSVBody = btt.body.toString();
                        lstLines = extractRows(strCSVBody);   
                        for(String strLines : lstLines){
                            system.debug('Lines--->'+strLines);
                            lstKnowledgeArticleWrapper.add(new KnowledgeArticleDataRemediate.KnowledgeArticleWrapper(strLines) );
                        }
                    }
                 }
 
 
                 if(!lstKnowledgeArticleWrapper.isEmpty()){
                     Database.executeBatch(new BatchUpdateKnowledgeArticles(lstKnowledgeArticleWrapper),1);
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
    * @author Vignesh
    * @date   13-Jan-2021
    * @description : extractRows - Method to convert String to rows
    * 
    */
     global list<string> extractRows(string strContent){
         List<String> lstLines = new List<String>();
         string strCSVBody = strContent;
         if(!Test.isRunningTest()){
             strCSVBody = strCSVBody.replaceAll(',"""',',"DBLQT').replaceall('""",','DBLQT",');
             strCSVBody = strCSVBody.replaceAll('""','DBLQT');
         }
         lstLines = strCSVBody.split('\n');
         if(!lstLines.isEmpty()){
             lstLines.remove(0);
         }
         return lstLines;
     }
    
     /**
     * @author Vignesh
     * @date   13-Jan-2021
     * @description   Wrapper class for Knowledge Articles
     */
     public class KnowledgeArticleWrapper{
         public string knowledgeArticleID{get;set;}
         //public string documentNumber {get; set;}
         //public string recordTypeName{get;set;}
         //public string primaryWorkflow{get;set;}
         //public string secondaryWorkflow{get;set;}
         //public string instrument{get;set;}
         //public string softwareCategory{get;set;}
         //public string libraryPrepCategory{get;set;}
         //public string boolIVDDxArticle{get;set;}
         //public string reviewStatus{get;set;}
		 public string applicableRegion{get;set;}
		 public string publishStatus{get;set;}
		 public string knowledgeArticleVersionID{get;set;}
		 
         /**
         * @author Vignesh
         * @date   13-Jan-2021
         * @description  Constructor for Wrapper.
         */
         public KnowledgeArticleWrapper(String row){
             list<string> lstColumns =  row.split(',');
             this.knowledgeArticleID = lstColumns[0];
			 this.knowledgeArticleVersionID = lstColumns[1];
			 this.publishStatus = lstColumns[2];
			 this.applicableRegion = lstColumns[3];
             //this.recordTypeName = lstColumns[2];
             //this.primaryWorkflow = lstColumns[3];
             //this.secondaryWorkflow = lstColumns[4];
             //this.instrument = lstColumns[5];
             //this.softwareCategory = lstColumns[6];
             //this.libraryPrepCategory = lstColumns[7];
             //this.boolIVDDxArticle = lstColumns[8];
             //this.reviewStatus = lstColumns[9];
         }
     
     }
 }