/**
*    @author: KD
*    @date:   17-April-2020
*    @description:  Queuable class for sync of document in content version
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Aman Tyagi                     31 March 2022       Codescan fixes
              Nitin                          7 june 2022         CMSI-36 try catch in execute method 
              Aman Tyagi                     12 Dec 2022         CodeScan Fixes
*    ------------------------------------------------------------------------------------ 
*                    
*/
public without sharing class ApttusPublishToContentRepository implements Queueable{
    String strAgreementId;
    List<Id> idDocId;
    public static Boolean catchException = false;
    /*
    * @Author:KD
    * @Description : parameterized constructor of class ApttusPublishToContentRepository
    * @param : String strAgreementId,List<Id> idDocId
    */ 
    public ApttusPublishToContentRepository(String strAgreementId,List<Id> idDocId){
        this.idDocId = idDocId;
        this.strAgreementId = strAgreementId;
    }

    /*
    * @Author:KD
    * @Description : execute method based on queueable context
    * @param : QueueableContext context
    * @return: void
    */
    public void execute(QueueableContext context){
        try{
            List<ContentDocument> lstSelectedDoc = new ContentDocumentSelector().selectById(idDocId);
            for(ContentDocument cd :lstSelectedDoc )
                cd.OwnerId = UserInfo.getUserId();
            update lstSelectedDoc;
            if(!Test.isRunningTest()){
            for(Id idDoc : idDocId)
                Apttus_Content.AgreementWebService.publishToContentRepository((String)strAgreementId,(String)idDoc);
            }
            if(catchException == true){
                throw new AuraHandledException('throwing custom exceptions');
            }
        }
        catch(Exception e){
            ApexExceptions.emit('ApttusPublishToContentRepository',e,ilib_LogEvent.getWorkstream());
            ilib_LogEvent.pop();
            ilib_LogEvent.emit();
            throw e;
        }
    }
}