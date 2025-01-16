/***************************************************************************************************************************************
* @Author:  Gladis
* @Date:   17-Aug-2021 
* @Description: Fetch Email Ids of the User based on the Account to Field Support User Roles (CMCP-11)(Written in non sharing context, so that the community users may get email notifications)
* Modification Log:
* ------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* ------------------------------------------------------------------------------------
* Gladis                   17-Aug-2021        Initial Version
* Gladis                   06-Sep-2021        CMCP-10 : Added method to send custom notifications for the users
* Nishan Shetty            14-Sep-2021        CMCP-158 : GTS Relocation WorkOrder Notification.
******************************************************************************************************************************************************************/
public without sharing class FetchUserEmailIds {

    //CMCP-10
    private static final String LOG_TITLE = 'FetchUserEmailIds';
    //START CMCP-158
    private static final String STRING_PART_ORDER_REVIEW ='Part Order Review';
    //END CMCP-158
    

    /**
            *  @author Gladis
            *  @description Wrapper class for Flow Inputs
            *  @return void
    **/   
    public class FlowInputs {
        @InvocableVariable public String strAccountId;
        @InvocableVariable public List<String> lstUserRoles;
        @InvocableVariable public List<String> lstEnabledNotifications;
        @InvocableVariable public String strRecordId;
        @InvocableVariable public String strRecordName;
        @InvocableVariable public String strRequestor;
        @InvocableVariable public Boolean boolPartnerUser;//CMCP-158
        @InvocableVariable public Boolean boolGTSBlock;//CMCP-158
        @InvocableVariable public Boolean boolGTSRequestFailed;//CMCP-158
    }

    

    /*
        * @Author: Gladis
        * @Description : Invocable method called from Flow to fetch Email Ids
        * @return: List<String> 
    */
    @InvocableMethod(label='Invoke fetchEmails')
    public static List<String> setFlowInputs(List<FlowInputs> requests) {
        List<String> userEmails = fetchEmails(requests[0]);
        ilib_LogEvent.message(LOG_TITLE + '-userEmails-' + userEmails);
        return userEmails;
    }

    /*
        * @Author: Gladis
        * @Description : CMCP-11 Logic to fetch email ids of the User the Account to Field Support User Roles
        * @return: returns list of email ids
    */   
    public static List<String> fetchEmails(FlowInputs flowRequest) {
        
        ilib_LogEvent.push(LOG_TITLE +'.fetchEmails');
        ilib_LogEvent.message('boolPartnerUser--'+flowRequest.boolPartnerUser);

        list<String> userEmails = new list<String>();
        list<String> lstUserEmails = new list<String>();
        list<Account_to_Field_Support__c> lstAccToFieldSupport=new list<Account_to_Field_Support__c>();
        Set<Id> userIds = new Set<Id>(); //CMCP-10
        String strUserEmails;
        //START CMCP-158
        Boolean boolPartnerFlag=false;
        boolPartnerFlag=flowRequest.boolPartnerUser;
        //END CMCP-158
        try {  
            if(flowRequest.lstUserRoles == null) { 
                flowRequest.lstUserRoles= new List<String>();
            }
            //Written in non sharing context, so that the community users may get email notifications
            ilib_LogQuery logger = null;
            if(Feature.isOn('ServiceQueryLogs')) {
            logger = new ilib_LogQuery(LOG_TITLE + '.fetchEmails',flowRequest.strAccountId);
            }
            
            lstAccToFieldSupport = [Select Id, User_Role__c, Account__c, User__r.SVMXC__Salesforce_User__r.Email, User__r.SVMXC__Salesforce_User__r.IsPortalEnabled, User__r.SVMXC__Salesforce_User__r.IsActive, User__r.SVMXC__Salesforce_User__r.Name, User__r.SVMXC__Salesforce_User__r.Id, User__c, Enable_Notifications_For__c 
                                                                      From Account_to_Field_Support__c 
                                                                      Where Account__c =:flowRequest.strAccountId AND (User_Role__c IN :flowRequest.lstUserRoles OR Enable_Notifications_For__c IN:flowRequest.lstEnabledNotifications)];
            
            if(Feature.isOn('ServiceQueryLogs')) {
            logger.stop(lstAccToFieldSupport.size());
            }
                       
            ilib_LogEvent.message('lstAccToFieldSupport--'+lstAccToFieldSupport);
            for(Account_to_Field_Support__c afs:lstAccToFieldSupport) {
                //START CMCP-158
                if(afs.User__r.SVMXC__Salesforce_User__r.IsPortalEnabled==boolPartnerFlag && afs.User__r.SVMXC__Salesforce_User__r.IsActive) {
                    userEmails.add(afs.User__r.SVMXC__Salesforce_User__r.Email);
                    //CMCP-10
                    userIds.add(afs.User__r.SVMXC__Salesforce_User__r.Id);
                }
                //END CMCP-158
            }
            strUserEmails = String.join(userEmails, ', ');
            lstUserEmails.add(strUserEmails);
            ilib_LogEvent.message('lstUserEmails--'+lstUserEmails);
            //CMCP-10 //START CMCP-158
            if(!userIds.isEmpty() && flowRequest.lstEnabledNotifications.get(0)=='Parts Order Notification') {
                sendCustomNotification(userIds,flowRequest.strRecordId,flowRequest.strRecordName,flowRequest.strRequestor);
            } else if(!userIds.isEmpty() && flowRequest.lstEnabledNotifications.get(0)=='Relocation Work Order Notification') {
                sendCustomNotificationForGTSWorkOrder(userIds,flowRequest.strRecordId,flowRequest.strRecordName,flowRequest.strRequestor,flowRequest.boolGTSBlock,flowRequest.boolGTSRequestFailed);
            }
            //END CMCP-158
                        
        } catch(Exception e) {
            ApexExceptions.emit(LOG_TITLE, e);
            return lstUserEmails;
        }

        ilib_LogEvent.pop(); 
        return lstUserEmails;

    }

    /*
        * @Author: Gladis
        * @Description : CMCP-10 Logic to send custom notifications for the users
        * @return: void
    */ 
    public static void sendCustomNotification(Set<Id> userIds, String strPartsOrderId, String strPartsOrderName, String strRequestor) {

        ilib_LogEvent.push(LOG_TITLE + '.sendCustomNotification('+strPartsOrderId+','+strPartsOrderName+','+strRequestor+')');
        Set<String> setRecepientsId = new Set<String>((List<String>)new List<Id>( userIds ));
        try {  
             
            String strBody = strRequestor +' has submitted '+strPartsOrderName+' for review.';
            String strTitle='Part Order Review';
            ilib_LogEvent.message('setRecepientsId--'+setRecepientsId);
            //Sending Custom Notification
            sendNotification(strTitle,strBody,strPartsOrderId,setRecepientsId);
            ilib_LogEvent.pop(); 
          
        } catch(Exception e) {
            ApexExceptions.emit(LOG_TITLE  + '.sendCustomNotification',e);
        }    
    }


    /*
    * @Author: Nishan Shetty
    * @Description : CMCP-158 Send Push Notification for GTS Relocation Recepients.
    * @return: void
    */ 
    public static void sendCustomNotificationForGTSWorkOrder(Set<Id> userIds, String strCaseId, String strCaseNumber,String strProductNumber,Boolean boolGTSBlock,Boolean boolGTSRequestFailed) {

        ilib_LogEvent.push(LOG_TITLE +'.sendCustomNotificationForGTSWorkOrder');
        Set<String> setRecepientsId = new Set<String>((List<String>)new List<Id>(userIds));
        String strTitle=null;
        String strBody=null;
        try {  
            
            ilib_LogEvent.message('boolGTSBlock--'+boolGTSBlock);
            if(boolGTSBlock) {
                strTitle='Relocation Failure Notice';
                strBody='Your requested relocation could not be approved for Case '+strCaseNumber+'/SN '+strProductNumber+'. Please check your email for more details.';
            } else if(boolGTSRequestFailed) {
                strTitle='Relocation Request Integration Failure';
                strBody='Your requested relocation could not sync to SAP for Case '+strCaseNumber+'/SN '+strProductNumber+'. Please check your email for more details.';
            } else {
                strTitle='Relocation Approval Notice';
                strBody='Your requested relocation was approved for Case '+strCaseNumber+'/SN '+strProductNumber+'.';
            }
            
            ilib_LogEvent.message('setRecepientsId--'+setRecepientsId);
            //Sending Custom Notification.
            sendNotification(strTitle,strBody,strCaseId,setRecepientsId);
            ilib_LogEvent.pop(); 
        } catch(Exception e) {
            ApexExceptions.emit(LOG_TITLE+'.sendCustomNotificationForGTSWorkOrder',e);
        }    


    }


    /*
    * @Author: Nishan Shetty
    * @Description : Sending Custom Notification.
    * @return: void
    */ 
    public static void sendNotification(String strTitle,String strBody,String strTargetId,Set<String> setRecipientIds) {
        Messaging.CustomNotification notification = new Messaging.CustomNotification();
        CustomNotificationType notificationType = [SELECT Id FROM CustomNotificationType WHERE DeveloperName = 'PartsOrderNotification'];

        if(strTitle == STRING_PART_ORDER_REVIEW) {
            notification.setSenderId(Userinfo.getUserId());
        }

        if(setRecipientIds!=null && !setRecipientIds.isEmpty()) {
            notification.setBody(strBody);
            notification.setTitle(strTitle);
            notification.setNotificationTypeId(notificationType.id);
            notification.setTargetId(strTargetId);
            notification.send(setRecipientIds);
        }

    }


}