/**
*    @author: Pankaj 
*    @date:   19-June-2019
*    @description:  PardotQueableForProspectScoring- Helper class for Pardot Callout 
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Pankaj Singla                 19-June-2019        Initial Build
*    ------------------------------------------------------------------------------------ 
*                    
*/
public with sharing class PQNAlertsQueableCalout implements Queueable, Database.AllowsCallouts{
    public List<String> lstEmailsIds;
    final public Integer INT_MAX_LIST_SIZE=10000;
    public Integer intCurrIndex;
    public static Boolean catchException = false;
    String strEndpoint,strPQNNumber,strPQNLink,strPQNDate,strAuthenicationKey,strNoticationType,strNotificationName;
    /*
    *  Description: Constructor PQNAlertsQueableCalout created
    */
    public PQNAlertsQueableCalout(List<String> lstEmailsIds,String strPQNNumber, String strPQNLink, String strPQNDate,String strEndpoint,String strAuthenicationKey,String strNotificationName,Integer intCurrIndex){
        this.lstEmailsIds=lstEmailsIds;
        this.strEndpoint=strEndpoint;
        this.strPQNNumber=strPQNNumber;
        this.strPQNLink=strPQNLink;
        this.strPQNDate=strPQNDate;
        this.strAuthenicationKey=strAuthenicationKey;
        this.intCurrIndex=intCurrIndex;
        this.strNotificationName=strNotificationName;
        
    }
    /*This is a recursive call. It Enqueue the job and remove the element from the list after callout*/
    public void execute(QueueableContext context){
      try{
        List<String> lstCurrJobsEmails=new List<String>();
        List<PQNAlertsController.JSONForPQNWrapper> lstWrapper=new List<PQNAlertsController.JSONForPQNWrapper>();
        if(strNotificationName.equals('Product Quality Notification')){
            strNoticationType='PQN';
        }
        
        else if(strNotificationName.equals('Product Change Notification')){
            strNoticationType='PCN';
        }
        else {
            strNoticationType='PON';
        }
        
        if(lstEmailsIds!=null && lstEmailsIds.size()>0){
             
             Integer intListSize=lstEmailsIds.size();
             
             for(Integer i=1;i<=INT_MAX_LIST_SIZE;i++){
                 if(intCurrIndex<intListSize){
                     lstCurrJobsEmails.add(lstEmailsIds[intCurrIndex]);
                     intCurrIndex++;
                 }
                 else {
                     break;
                 }
                 
            }
            for(String strEmail:lstCurrJobsEmails){
                String strEmailId='';
                if(strEmail.contains('\'')){
                    
                    List<String> lststr=strEmail.split('\'');
                        for(string str:lststr){
                            strEmailId=strEmailId+str;
                            strEmailId=strEmailId+'\''+'\'';
                        }
                        strEmailId=strEmailId.removeEnd('\'');
                       
                }
                else{
                    strEmailId=strEmail;
                }
                
                PQNAlertsController.JSONInner objInnerWrapper=new PQNAlertsController.JSONInner();
                objInnerWrapper.notificationNumber=strPQNNumber;
                objInnerWrapper.notificationType=strNoticationType;
                objInnerWrapper.notificationName=strNotificationName;
                string strMetaData = JSON.serialize(objInnerWrapper);
                PQNAlertsController.JSONForPQNWrapper objPQNWrapper=new PQNAlertsController.JSONForPQNWrapper();
                objPQNWrapper.userLogonId=strEmailId;
                objPQNWrapper.notificationTypeId=8;         
                objPQNWrapper.ctaLink=strPQNLink;
                objPQNWrapper.metadata=strMetaData;
                objPQNWrapper.externalNotificationId=strPQNNumber;
                lstWrapper.add(objPQNWrapper);
            }
            
            String strjsonPayload = JSON.serialize(lstWrapper);
            system.debug('JSON is---'+strjsonPayload);
            Http objhttp = new Http();
            HttpRequest request = new HttpRequest();
            HttpResponse response;
            request.setEndpoint(strEndpoint);
            request.setMethod('POST');
            request.setHeader('Content-Type', 'application/json'); 
            request.setHeader('Authentication', strAuthenicationKey);
            request.setBody(strjsonPayload);
            request.setTimeout(120000);
            String strResult='';
            
                FeedItem objfeed=new FeedItem();
                objfeed.ParentId=Userinfo.getUserId();
                objfeed.Body=strResult;
                objfeed.Title='Product Notification status';
                
            
             if(intCurrIndex<intListSize){
                PQNAlertsQueableCalout objPQNAlertsQueableCalout=new PQNAlertsQueableCalout(lstEmailsIds,strPQNNumber,strPQNLink,strPQNDate,strEndpoint,strAuthenicationKey,strNotificationName,intCurrIndex);           
                System.enqueueJob(objPQNAlertsQueableCalout); 
             }
        }
         //code coverage for catch block
         if(catchException == true){
            throw new AuraHandledException('throwing custom exceptions');
        }
      }catch(Exception e){
        //catch the exception 
        ApexExceptions.emit('PQNAlertsQueableCalout', e,ilib_LogEvent.getWorkstream());
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
        throw e;
      }
    }
       
}
