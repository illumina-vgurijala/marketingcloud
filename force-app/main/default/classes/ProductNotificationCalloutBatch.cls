/**
*    @author 
*    @date   
*    @description ProductNotificationCalloutBatch sharing class which is implementing Database
*    Modification Log:
*    -----------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*    -----------------------------------------------------------------------------------------------------------------------------------
*            Aman Tyagi                     7th Oct 2022        Codescan fixes
*            Aman Tyagi                     12th Dec 2022       CodeScan fixes
*/
public with sharing class ProductNotificationCalloutBatch implements Database.batchable<String>,Iterator<string>,Database.AllowsCallouts,Database.Stateful { 
   public List<String> lstEmails;
   public String strPQNNumber,strPQNLink,strNotificationName,strNoticationType,strEndpoint,strAuthenicationKey;
   public Integer intcount=0;
   final public String INTERFACE_NAME='PQN_ALERTS';
   public String strSuccessResponse='';
   public String strFailureResponse='';
   public Integer intSuccessCount;
   public Integer intFailureCount;
   public List<PQNAlertsController.JSONResponseInner> lstResult=new List<PQNAlertsController.JSONResponseInner>();
   public static final Integer TWO_HUNDRUND = 200;

    /**
     * @author   
     * @description parameterized constructor of the class ProductNotificationCalloutBatch
     * @param List<String> lstEmails,String strPQNNumber,String strPQNLink,String strNotificationName
     * @return NA 
     **/
    public ProductNotificationCalloutBatch(List<String> lstEmails,String strPQNNumber,String strPQNLink,String strNotificationName){
        this.lstEmails=lstEmails;
        this.strPQNNumber=strPQNNumber;
        this.strPQNLink=strPQNLink;
        this.strNotificationName=strNotificationName;
        
        if('Product Quality Notification'.equals(strNotificationName)){
            this.strNoticationType='PQN';
        }
        else if('Product Change Notification'.equals(strNotificationName)){
            this.strNoticationType='PCN';
        }
        else {
            this.strNoticationType='PON';
        }
        Map<String, String> config = PQNAlertsController.getIntegrationEndpoint(INTERFACE_NAME);
        strEndpoint=config.get('Endpoint');
        strAuthenicationKey=config.get('ApiKey');
    }
    /**
    * @author   
    * @description next method
    * @param NA
    * @return String 
    **/
    public string next(){
        if(hasnext()){
            intcount++;
            return lstEmails[intcount];
            
        }
        return null;
    }
    /**
    * @author   
    * @description hasnext method
    * @param NA
    * @return Boolean 
    **/
    public Boolean hasnext(){
        
        if(intcount<lstEmails.size()){
            return true;
        }
        else {
            return false;
        }
    
    }
    /**
    * @author   
    * @description start method
    * @param Database.BatchableContext info
    * @return Iterable<String> 
    **/
    public Iterable<string> start(Database.BatchableContext info){ 
       return lstEmails; 
    }
    /**
    * @author   
    * @description execute method
    * @param Database.BatchableContext info ,List<String> scope
    * @return NA 
    **/   
    public void execute(Database.BatchableContext info, List<String> scope){
       List<PQNAlertsController.JSONForPQNWrapper> lstWrapper=new List<PQNAlertsController.JSONForPQNWrapper>();
       for(String strEmail : scope){ 
           system.debug('strEmail---'+strEmail);
           String strEmailFormated='';
           if(strEmail.contains('\'')){
               List<String> lstString=strEmail.split('\'');
               for(String str:lstString){
                    strEmailFormated=strEmailFormated+str;
                    strEmailFormated=strEmailFormated+'\''+'\'';
               }
               string strFinal=strEmailFormated.removeEnd('\'');
               strFinal=strFinal.removeEnd('\'');
               strEmailFormated=strFinal;
           }
           else{
              strEmailFormated= strEmail;
           }
           PQNAlertsController.JSONInner objInnerWrapper=new PQNAlertsController.JSONInner();
           objInnerWrapper.notificationNumber=strPQNNumber;
           objInnerWrapper.notificationType=strNoticationType;
           objInnerWrapper.notificationName=strNotificationName;
           string strMetaData = JSON.serialize(objInnerWrapper);
           PQNAlertsController.JSONForPQNWrapper objPQNWrapper=new PQNAlertsController.JSONForPQNWrapper();
           objPQNWrapper.userLogonId=StrEmailFormated;
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
        system.debug('request---'+request);
        response = objhttp.send(request);
        system.debug('Response is---'+response.getStatusCode());
        if(response.getStatusCode()==TWO_HUNDRUND){
           
            PQNAlertsController.PQNJSONResult lst=(PQNAlertsController.PQNJSONResult)System.JSON.deserialize(response.getBody(),PQNAlertsController.PQNJSONResult.class);
            for(PQNAlertsController.JSONResponseInner obj:lst.data){
                lstResult.add(obj);
            }
        }
        else {
            strFailureResponse=strFailureResponse+response.getBody()+'\n';
        }
       
    } 
    /**
    * @author   
    * @description finish method
    * @param Database.BatchableContext info
    * @return NA 
    **/   
    public void finish(Database.BatchableContext info){
        string strHeader='Notification Id,Message,EmailId \n';
        string strFinalMessage = strHeader ;
        string strBodyText = 'Hi '+UserInfo.getName()+',<br/><br/>' +
                    'Product Notification Submission completed successfully. The success results are attached to email.<br/><br/>';
        if(!String.isBlank(strFailureResponse)){
            strBodyText='The following errors occured during the submission:<br/><br/>'+strFailureResponse+'<br/><br/>';
            
        }                               
        strBodyText=strBodyText+'Thanks,<br/>Admin';                 
        for(PQNAlertsController.JSONResponseInner objNew:lstResult){
            string strRecordString;
            if(objNew.message!=null){
                strRecordString=objNew.externalNotificationId+','+objNew.message+','+objNew.userLogonId+'\n';
            }
            else{
                strRecordString=objNew.externalNotificationId+','+''+','+objNew.userLogonId+'\n';
            }
            strFinalMessage = strFinalMessage +strRecordString;
        }   
            
            Messaging.EmailFileAttachment objEmailAttachment = new Messaging.EmailFileAttachment();
            blob csvBlob = Blob.valueOf(strFinalMessage);
            string strCsvname= 'ProductNotificationSuccess.csv';
            objEmailAttachment.setFileName(strCsvname);
            objEmailAttachment.setBody(csvBlob);
            Messaging.SingleEmailMessage objEmailMessage =new Messaging.SingleEmailMessage();
            String[] toAddresses = new list<string> {UserInfo.getUserEmail()};
            String subject ='Product Notification Results on '+datetime.now();
            objEmailMessage.setSubject(subject);
            objEmailMessage.setToAddresses( toAddresses );
            objEmailMessage.setPlainTextBody(strBodyText);
            objEmailMessage.setHtmlBody(strBodyText);
            objEmailMessage.setFileAttachments(new Messaging.EmailFileAttachment[]{objEmailAttachment});
            Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {objEmailMessage});

        
    } 
}