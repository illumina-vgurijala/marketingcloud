/***************************************************************************************************************************************
 * NAME   : SendEmailNotification
 * DESCRIPTION  : DCP-803 Sending email notification to Users.
 *    
 * @AUTHOR : Debalina
 * @DATE   : 31-May-2018  
 *
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Debalina             31-May-2018          Initial Version
 * Ritika               1-June-2018          Generic method to send emails
 * Debalina             14-June-2018         802/803 Code review Changes Account_to_Field_Support__c from Account_Technician_Role__c
 * Ritika               15-June-2018         803 Code review for fetching cc adress
 * Debalina             27-June-2018         Bug DCP-5644 Remove ContactId from setTargetObjectId
 * Prerna               2-March-2021         DCP-49677, DCP-4966 Elevation Notifications
 * Vineeta Verma        12-Jul-2024          TASK1037157-Remove creation and deletion of dummy contact and query it
  ****************************************************************************************************************************************/ 

  public without sharing class SendEmailNotification {
    
    public static final String BILLABLE_WORK_DETAIL_META_DATA = 'Billable_Work_Detail';
    public static final String BILLABLE_PARTS_ORDER_LINE_META_DATA = 'Billable_Parts_Order_Line';//DCP-38817
    public static final String STRING_DUMMY_CONTACT = 'DUMMYCONTACT';
    public static final String ORG_WIDE_EMAIL_ADDRESS ='Illumina Salesforce No-Reply';
    //Dummy contact name-TASK1037157
    private static final String CONTACT_NAME = 'Master Data Request Dummy Contact';
    private static final String DUMMY_CONTACT_FOUND_LOG_MSG = 'objDummyContact found';
    private static final String DUMMY_CONTACT_NOT_FOUND_LOG_MSG = 'Dummy contact not found, using random contact instead';
    private static final String LOG_TITLE = 'SendEmailNotification';

    /*
    *  @AUTHOR:  Ritika  
    *  @DESCRIPTION: Generic method to send emails
    *  @PARAM :  strEmailCondition - Condition for which email is to be sent
    *           lstWorkOrder - list of work orders which are to be processed
    *           accountIdToFSERoles - account to role map
    *  @RETURN:  void
    */   
    public static void getSendEmailParamaters(String strEmailCondition, 
                                            List<sObject> lstsObject, 
                                            Map<Id,Map<String,Account_to_Field_Support__c>> accountIdToFSERoles, String strAccountLookupField)
    {
		Map<Id,Set<String>> woIdBYElevationMembersId = new Map<Id,Set<String>>();
        List<OrgWideEmailAddress> orgWideEmails = new List<OrgWideEmailAddress>(); 
        Boolean isElevationNotification = false;
		//Query the custom metadata for the emails setting
        Send_Email_Setting__mdt objSendEmailSetting = [Select To_Address_Roles__c, 
                                                        To_Address_Fields__c,
                                                        Additional_CC_Addresses__c,
                                                        CC_Address_Roles__c,
                                                        CC_Address_Fields__c,
                                                        Template_Name__c,
                                                        Target_Object_Field__c
                                                        from Send_Email_Setting__mdt
                                                        Where DeveloperName = :strEmailCondition];
               
                                                        
        if(objSendEmailSetting != null){
            Contact objDummyContact = new Contact();
            
            if(String.isNotBlank(objSendEmailSetting.Target_Object_Field__c) && objSendEmailSetting.Target_Object_Field__c == STRING_DUMMY_CONTACT){
                //TASK1037157:query Contact- Dummy Contact
                try{
                    objDummyContact = [select Id from Contact where Name = :CONTACT_NAME and Is_Active__c = true limit 1];
                    ilib_LogEvent.info(DUMMY_CONTACT_FOUND_LOG_MSG+objDummyContact);
                } 
                catch(QueryException queryException) {
                    ilib_LogEvent.info(DUMMY_CONTACT_NOT_FOUND_LOG_MSG);
                    ApexExceptions.emit(LOG_TITLE, DUMMY_CONTACT_NOT_FOUND_LOG_MSG,ilib_LogEvent.SERVICE);
                    objDummyContact = [select Id from Contact where Is_Active__c = true limit 1];
                }
                
            }
            system.debug('getSendEmailParamaters -->'+ objSendEmailSetting);
            List<Messaging.SingleEmailMessage>  lstEmailNotifications = new List<Messaging.SingleEmailMessage>();
            //Get the id of the template to be used
            Id idEmailTemplate = ServiceUtilityCollection.getEmailTemplate(objSendEmailSetting.Template_Name__c);
            //28205
            Map<Id,Id> idWOOwnerToEmailWOOwnerManager;
            if(strEmailCondition == BILLABLE_WORK_DETAIL_META_DATA){
                Set<Id> setWOOwnerIds = new Set<Id>();
                idWOOwnerToEmailWOOwnerManager = new Map<Id,Id>();
                for(sObject obj : lstsObject){
                    SVMXC__service_order_line__c objWD = (SVMXC__service_order_line__c)obj;
                    setWOOwnerIds.add(objWD.SVMXC__Service_Order__r.OwnerId);
                }
                for(User objUser : new UsersSelector().selectByUserId(setWOOwnerIds)){
                    idWOOwnerToEmailWOOwnerManager.put(objUser.Id, objUser.ManagerId);
                }
            }//28205 end

             //DCP-38817 - Start
            Map<Id,Id> idPartsOrderRequestedByToEmailManager= null;
            if(strEmailCondition == BILLABLE_PARTS_ORDER_LINE_META_DATA){
            Set<Id> setPORequestedByIds = new Set<Id>();
                idPartsOrderRequestedByToEmailManager = new Map<Id,Id>();
                for(sObject obj : lstsObject){
                    SVMXC__RMA_Shipment_Line__c objPOL = (SVMXC__RMA_Shipment_Line__c)obj;
                    setPORequestedByIds.add(objPOL.SVMXC__RMA_Shipment_Order__r.Requested_By__c);
                }
                for(User objUser : new UsersSelector().selectByUserId(setPORequestedByIds)){
                    idPartsOrderRequestedByToEmailManager.put(objUser.Id, objUser.ManagerId);
                }
            }
            //DCP-38817 - End
            
            //DCP-49676, 49680, 49675 - Start : Preparing toaddresses data
            Set<String> setElevationEmailSetting = new  Set<String>{ label.Technical_Elevation_Send_Plan_of_Action_Metadata,
                Label.Elevation_Technical_Close_Status_Metadata, Label.Elevation_Account_Reopen_Status_Metadata,
                Label.Technical_Elevation_Reopen_Notification, Label.Account_Elevation_Closure_Notification,
                Label.Elevation_Account_Open_Status_Metadata, label.Technical_Elevation_Create_Notification
            };

            //Logic to collect Work Order Ids and Case Owner Ids to fetch Watchers and Case Owner's Manager. 

            if(setElevationEmailSetting.contains(strEmailCondition) ) {                                
                Set<Id> workOrderIds = new Set<Id>();            
                for(sObject obj : lstsObject){
                    Elevations__c objElevation = (Elevations__c)obj;
                    workOrderIds.add(objElevation.Work_Order__c);
                }

                woIdBYElevationMembersId = fetchAdditionalElevationMembers(strEmailCondition,workOrderIds);  
                
                isElevationNotification = true;       
            }
            //DCP-49676, 49680, 49675 - Ends    
            if(ORG_WIDE_EMAIL_ADDRESS != null && ORG_WIDE_EMAIL_ADDRESS != ''){
                orgWideEmails = [SELECT Id, Address, DisplayName
                            FROM OrgWideEmailAddress
                            WHERE DisplayName = : ORG_WIDE_EMAIL_ADDRESS
                            LIMIT 1
                            ];   
            }    
            
            for(sObject obj : lstsObject){
                Set<String> setOfToAddress = new Set<String>();
                Set<String> setOfCCAddress = new Set<String>();
                    Messaging.SingleEmailMessage objEmail = new Messaging.SingleEmailMessage();
                    Map<String,Account_to_Field_Support__c> roleTotechnician = new Map<String,Account_to_Field_Support__c>();
                //Fetch the roles assocaited with sobject's account
                if(accountIdToFSERoles != null && strAccountLookupField != null){
                    String  strAccountLookupFieldValue = null;
                    if(strAccountLookupField.contains('.')){
                        if(obj.getSobject(strAccountLookupField.split('\\.')[0]) != null) {
                            strAccountLookupFieldValue = (String)obj.getSobject(strAccountLookupField.split('\\.')[0]).get(strAccountLookupField.split('\\.')[1]);
                        }
                    }else{
                        strAccountLookupFieldValue = (String)obj.get(strAccountLookupField);
                    }
                    roleTotechnician = accountIdToFSERoles.get(strAccountLookupFieldValue);
                }
                
                //Get the to address fields
                //If the to address has is a lookup, split by '.' and get the parent field details
                setOfToAddress = addSetToAddress(objSendEmailSetting.To_Address_Fields__c,obj,setOfToAddress);
                
                //DCP-28205
                if(strEmailCondition == BILLABLE_WORK_DETAIL_META_DATA){
                    SVMXC__service_order_line__c objWD = (SVMXC__service_order_line__c)obj;
                    setOfToAddress.add(String.valueOf(idWOOwnerToEmailWOOwnerManager.get(objWD.SVMXC__Service_Order__r.OwnerId)));
                } //DCP-28205 end
                 //DCP-38817
               else if(strEmailCondition == BILLABLE_PARTS_ORDER_LINE_META_DATA){
                    SVMXC__RMA_Shipment_Line__c objPOL = (SVMXC__RMA_Shipment_Line__c)obj;
                    setOfToAddress.add(String.valueOf(idPartsOrderRequestedByToEmailManager.get(objPOL.SVMXC__RMA_Shipment_Order__r.Requested_By__c)));
                } //DCP-38817 end
                //get the to role fields
                //For the roles, fetch the technicians associated with the account
                else if(objSendEmailSetting.To_Address_Roles__c != null){
                    for(String strToAddressRole : objSendEmailSetting.To_Address_Roles__c.split(';')){
                        if(roleTotechnician != null && roleTotechnician.containsKey(strToAddressRole) && roleTotechnician.get(strToAddressRole).User__r.SVMXC__Salesforce_User__c != null){
                            setOfToAddress.add(roleTotechnician.get(strToAddressRole).User__r.SVMXC__Salesforce_User__c);
                        }
                    }
                }
                
                //DCP - 49676 Prerna, DCP - 49680, DCP-49675
                if( setElevationEmailSetting.contains(strEmailCondition) ) {
                    Elevations__c objElevation = (Elevations__c)obj;                    
                    if(woIdBYElevationMembersId != null && woIdBYElevationMembersId.containsKey(objElevation.Work_Order__c)){
                        setOfToAddress.addAll(woIdBYElevationMembersId.get(objElevation.Work_Order__c));
                    }
                
                    if(objElevation.Case__r.Region__c != Null && 
                        (strEmailCondition == Label.Account_Elevation_Closure_Notification || 
                        strEmailCondition == Label.Elevation_Account_Reopen_Status_Metadata || 
                        strEmailCondition == Label.Elevation_Account_Open_Status_Metadata ||
                        strEmailCondition == Label.Technical_Elevation_Reopen_Notification ||
                        strEmailCondition == Label.Technical_Elevation_Create_Notification)
                        ){
                        
                        Code_Parameter__mdt objRelatedRegionEmail = Code_Parameter__mdt.getInstance('Elevation_Notification_'+objElevation.Case__r.Region__c+'_Region');    
                        setOfToAddress.addAll(objRelatedRegionEmail.Value__c.split(';'));
                    } 
                }
                // DCP - 49676, DCP - 49680, DCP-49675 Ends here 
                           
                //get the cc fields
                setOfCCAddress = addSetToAddress(objSendEmailSetting.CC_Address_Fields__c,obj,setOfCCAddress);
                //get the cc address fields
                if(objSendEmailSetting.CC_Address_Roles__c != null){
                    for(String strCCAddressRole : objSendEmailSetting.CC_Address_Roles__c .split(';')){
                        if(roleTotechnician != null  && roleTotechnician.containsKey(strCCAddressRole)){
                            setOfCCAddress.add(roleTotechnician.get(strCCAddressRole).User__r.SVMXC__Salesforce_User__c);
                        }
                    }
                }
                
                 //Get the Additional CC addesses
                //Splits the CC Addresses by ';'
                if(objSendEmailSetting.Additional_CC_Addresses__c != null){
                    for(String strAdditionalCCAddress : objSendEmailSetting.Additional_CC_Addresses__c.split(';')){
                        setOfCCAddress.add(strAdditionalCCAddress); 
                    }
                }
                
                objEmail.setTemplateId(idEmailTemplate);

                List<String> lstToAddress = new List<String>();
                lstToAddress.addAll(setOfToAddress);
                objEmail.setToAddresses(lstToAddress);
                List<String> lstCCAddress = new List<String>();
                lstCCAddress.addAll(setOfCCAddress); 
                objEmail.setCcAddresses(lstCCAddress);

                String strTargetObject = objSendEmailSetting.Target_Object_Field__c;                
                if(strTargetObject != null && strTargetObject == STRING_DUMMY_CONTACT){
                    objEmail.setTargetObjectId(objDummyContact.Id);
                }else if(strTargetObject != null && obj.get(strTargetObject) != null){
                    objEmail.setTargetObjectId((Id)obj.get(strTargetObject));
                }else{
                    objEmail.setTargetObjectId(Userinfo.getUserId());
                } 

                objEmail.setTreatTargetObjectAsRecipient(false);
                objEmail.setSaveAsActivity(false);
                objEmail.setWhatId((Id)obj.get('Id'));
                
                if (ORG_WIDE_EMAIL_ADDRESS != '' && ORG_WIDE_EMAIL_ADDRESS != null && !orgWideEmails.isEmpty()) {
                   
                    objEmail.setOrgWideEmailAddressId(orgWideEmails[0].Id);
                    if(isElevationNotification){
                        objEmail.setUseSignature(false); //DCP-53791
                    }                                       
                }  
                lstEmailNotifications.add(objEmail);
            }
            Messaging.SendEmailResult[] lstResults = Messaging.sendEmail(lstEmailNotifications,false);
            
            if (lstResults != null && !lstResults.isEmpty()){
                if( lstResults[0].success) {
                    System.debug('The email was sent successfully.');
                } 
                else {
                    System.debug('The email failed to send: '+  lstResults[0].errors[0].message);
                }
            } 
            
            
           
        }

        isElevationNotification = false;
    }

    /*
    *  @AUTHOR:  Ritika  
    *  @DESCRIPTION: Generic method to send emails
    *  @PARAM :  strEmailCondition - Condition for which email is to be sent
    *           lstWorkOrder - list of work orders which are to be processed
    *           accountIdToFSERoles - account to role map
    *  @RETURN:  void
    */   
    public static void getSendEmailParamaters(String strEmailCondition, 
                                            List<sObject> lstsObject, 
                                            Map<Id,Map<String,Account_to_Field_Support__c>> accountIdToFSERoles, 
                                            String strAccountLookupField,
                                            Map<Id,Set<String>> sobjectToAdditionalEmailsList)
    {
        //Query the custom metadata for the emails setting
        Send_Email_Setting__mdt objSendEmailSetting = [Select To_Address_Roles__c, 
                                                        To_Address_Fields__c,
                                                        CC_Address_Roles__c,
                                                        CC_Address_Fields__c,
                                                        Template_Name__c,
                                                        Target_Object_Field__c
                                                        from Send_Email_Setting__mdt
                                                        Where DeveloperName = :strEmailCondition];
        if(objSendEmailSetting != null){
            Contact objDummyContact = new Contact();
            
            if(String.isNotBlank(objSendEmailSetting.Target_Object_Field__c) && objSendEmailSetting.Target_Object_Field__c == STRING_DUMMY_CONTACT){
                //TASK1037157:query Contact- Dummy Contact
                try{
                    objDummyContact = [select Id from Contact where Name = :CONTACT_NAME and Is_Active__c = true limit 1];
                    ilib_LogEvent.info(DUMMY_CONTACT_FOUND_LOG_MSG+objDummyContact);
                } 
                catch(QueryException queryException) {
                    ilib_LogEvent.info(DUMMY_CONTACT_NOT_FOUND_LOG_MSG);
                    ApexExceptions.emit(LOG_TITLE, DUMMY_CONTACT_NOT_FOUND_LOG_MSG,ilib_LogEvent.SERVICE);
                    objDummyContact = [select Id from Contact where Is_Active__c = true limit 1];
                }
            }
            List<Messaging.SingleEmailMessage>  lstEmailNotifications = new List<Messaging.SingleEmailMessage>();
            //Get the id of the template to be used
            Id idEmailTemplate = ServiceUtilityCollection.getEmailTemplate(objSendEmailSetting.Template_Name__c);
            for(sObject obj : lstsObject){
                Messaging.SingleEmailMessage objEmail = new Messaging.SingleEmailMessage();
                
                Map<String,Account_to_Field_Support__c> roleTotechnician = new Map<String,Account_to_Field_Support__c>();
                //Fetch the roles assocaited with sobject's account
                if(accountIdToFSERoles != null && strAccountLookupField != null){
                    String  strAccountLookupFieldValue = null;
                    if(strAccountLookupField.contains('.')){
                        strAccountLookupFieldValue=(obj.getSobject(strAccountLookupField.split('\\.')[0]) != null?(String)obj.getSobject(strAccountLookupField.split('\\.')[0]).get(strAccountLookupField.split('\\.')[1]):null);
                    }else{
                        strAccountLookupFieldValue = (String)obj.get(strAccountLookupField);
                    }
                    roleTotechnician = accountIdToFSERoles.get(strAccountLookupFieldValue);
                }
                Set<String> setOfToAddress = new Set<String>();
                Set<String> setOfCCAddress = new Set<String>();

                if(sobjectToAdditionalEmailsList != null && sobjectToAdditionalEmailsList.containsKey((Id)obj.get('Id'))){
                    for(String strAdditionalEmail : sobjectToAdditionalEmailsList.get((Id)obj.get('Id'))){
                        setOfToAddress.add(strAdditionalEmail);
                    }
                }
                //Get the to address fields
                //If the to address has is a lookup, split by '.' and get the parent field details
                setOfToAddress = addSetToAddress(objSendEmailSetting.To_Address_Fields__c,obj,setOfToAddress);
                //get the to role fields
                //For the roles, fetch the technicians associated with the account
                if(objSendEmailSetting.To_Address_Roles__c != null){
                    for(String strToAddressRole : objSendEmailSetting.To_Address_Roles__c.split(';')){
                        if(roleTotechnician != null && roleTotechnician.containsKey(strToAddressRole)){
                            setOfToAddress.add(roleTotechnician.get(strToAddressRole).User__r.SVMXC__Salesforce_User__c);
                        }
                    }
                }
                //get the cc fields
                setOfCCAddress = addSetToAddress(objSendEmailSetting.CC_Address_Fields__c,obj,setOfCCAddress);
                //get the cc address fields
                if(objSendEmailSetting.CC_Address_Roles__c != null){
                    for(String strCCAddressRole : objSendEmailSetting.CC_Address_Roles__c .split(';')){
                        if(roleTotechnician != null  && roleTotechnician.containsKey(strCCAddressRole)){
                            setOfCCAddress.add(roleTotechnician.get(strCCAddressRole).User__r.SVMXC__Salesforce_User__c);
                        }
                    }
                }
                
                objEmail.setTemplateId(idEmailTemplate);
                
                List<String> lstToAddress = new List<String>();
                lstToAddress.addAll(setOfToAddress);
                objEmail.setToAddresses(lstToAddress);
                List<String> lstCCAddress = new List<String>();
                lstCCAddress.addAll(setOfCCAddress); 
                objEmail.setCcAddresses(lstCCAddress);

                String strTargetObject = objSendEmailSetting.Target_Object_Field__c;                
                if(strTargetObject != null && strTargetObject == STRING_DUMMY_CONTACT){
                    objEmail.setTargetObjectId(objDummyContact.Id);
                }else if(strTargetObject != null && obj.get(strTargetObject) != null){
                    objEmail.setTargetObjectId((Id)obj.get(strTargetObject));
                }else{
                    objEmail.setTargetObjectId(Userinfo.getUserId());
                } 
                
                objEmail.setTreatTargetObjectAsRecipient(false);
                objEmail.setWhatId((Id)obj.get('Id')); 
                objEmail.setSaveAsActivity(false);
                lstEmailNotifications.add(objEmail);
            }
            Messaging.SendEmailResult[] lstResults = Messaging.sendEmail(lstEmailNotifications,false); 
            

            
            
        }
    }

     /*
    *  @AUTHOR:  Soumya Ranjan Sahu 
    *  @DESCRIPTION: Generic method to send emails with attachments
    *  @PARAM :  strEmailCondition - Condition for which email is to be sent
    *           lstWorkOrder - list of work orders which are to be processed
    *           accountIdToFSERoles - account to role map
    *  @RETURN:  void
    */   
    public static void sendEmailWithAttachments(String strEmailCondition, List<sObject> lstsObject,Map<Id,List<Id>> sObjectIdToAttachmentList, 
                                                Map<Id,Map<String,Account_to_Field_Support__c>> accountIdToFSERoles, String strAccountLookupField)
    {
        //Query the custom metadata for the emails setting
        Send_Email_Setting__mdt objSendEmailSetting = [Select To_Address_Roles__c, 
                                                        To_Address_Fields__c,
                                                        CC_Address_Roles__c,
                                                        CC_Address_Fields__c,
                                                        Template_Name__c,
                                                        Target_Object_Field__c,
                                                        Additional_CC_Addresses__c,
                                                        Additional_To_Addresses__c
                                                        from Send_Email_Setting__mdt
                                                        Where DeveloperName = :strEmailCondition];
        if(objSendEmailSetting != null){
            
            Contact objDummyContact = new Contact();
            
            if(String.isNotBlank(objSendEmailSetting.Target_Object_Field__c) && objSendEmailSetting.Target_Object_Field__c == STRING_DUMMY_CONTACT){
                //TASK1037157:query Contact- Dummy Contact
                try{
                    objDummyContact = [select Id from Contact where Name = :CONTACT_NAME and Is_Active__c = true limit 1];
                    ilib_LogEvent.info(DUMMY_CONTACT_FOUND_LOG_MSG+objDummyContact);
                } 
                catch(QueryException queryException) {
                    ilib_LogEvent.info(DUMMY_CONTACT_NOT_FOUND_LOG_MSG);
                    ApexExceptions.emit(LOG_TITLE, DUMMY_CONTACT_NOT_FOUND_LOG_MSG,ilib_LogEvent.SERVICE);
                    objDummyContact = [select Id from Contact where Is_Active__c = true limit 1];
                }
            }
            
            
            List<Messaging.SingleEmailMessage>  lstEmailNotifications = new List<Messaging.SingleEmailMessage>();
            //Get the id of the template to be used
            Id idEmailTemplate = ServiceUtilityCollection.getEmailTemplate(objSendEmailSetting.Template_Name__c);
            for(sObject obj : lstsObject){
                Messaging.SingleEmailMessage objEmail = new Messaging.SingleEmailMessage();
                
                Set<String> setOfToAddress = new Set<String>();
                Set<String> setOfCCAddress = new Set<String>();
                //Get the to address fields
                //If the to address has is a lookup, split by '.' and get the parent field details
                if(objSendEmailSetting.To_Address_Fields__c != null){
                    for(String strToAddressField : objSendEmailSetting.To_Address_Fields__c.split(';')){
                        if(strToAddressField.contains('.')){
                            if((obj.getSobject(strToAddressField.split('\\.')[0])) != null){
                                setOfToAddress.add((String)obj.getSobject(strToAddressField.split('\\.')[0]).get(strToAddressField.split('\\.')[1]));
                            }
                        }else{
                            setOfToAddress.add((String)obj.get(strToAddressField));
                        }  
                    } 
                } 
                //Get the Additional To addesses
                //Splits the To Addresses by ';'
                if(objSendEmailSetting.Additional_To_Addresses__c != null){
                    for(String strAdditionalToAddress : objSendEmailSetting.Additional_To_Addresses__c.split(';')){
                        setOfToAddress.add(strAdditionalToAddress); 
                    }
                }
                //Get the Additional CC addesses
                //Splits the CC Addresses by ';'
                if(objSendEmailSetting.Additional_CC_Addresses__c != null){
                    for(String strAdditionalCCAddress : objSendEmailSetting.Additional_CC_Addresses__c.split(';')){
                        setOfCCAddress.add(strAdditionalCCAddress); 
                    }
                }

                //get the cc fields
                if(objSendEmailSetting.CC_Address_Fields__c != null){
                    for(String strCCAddressField : objSendEmailSetting.CC_Address_Fields__c.split(';')){
                        if(strCCAddressField.contains('.') ){
                            if((obj.getSobject(strCCAddressField.split('\\.')[0])) != null){
                                setOfCCAddress.add((String)obj.getSobject(strCCAddressField.split('\\.')[0]).get(strCCAddressField.split('\\.')[1]));
                            }
                        }else{
                            setOfCCAddress.add((String)obj.get(strCCAddressField));
                        }
                    }
                }
      
                //Get the Attachments List
                List<id> lstAttachments = new List<id>();
                if(sObjectIdToAttachmentList != null){
                    for(id idAttachment:sObjectIdToAttachmentList.get((Id)obj.get('Id'))){
                        lstAttachments.add(idAttachment);
                    }
                }
                
                objEmail.setTemplateId(idEmailTemplate);
                
                List<String> lstToAddress = new List<String>();
                lstToAddress.addAll(setOfToAddress);
                objEmail.setToAddresses(lstToAddress);
                List<String> lstCCAddress = new List<String>();
                lstCCAddress.addAll(setOfCCAddress); 
                objEmail.setCcAddresses(lstCCAddress);
                objEmail.setEntityAttachments(lstAttachments);
                
                String strTargetObject = objSendEmailSetting.Target_Object_Field__c;                
                if(strTargetObject != null && strTargetObject == STRING_DUMMY_CONTACT){
                    objEmail.setTargetObjectId(objDummyContact.Id);
                }else if(strTargetObject != null && obj.get(strTargetObject) != null){
                    objEmail.setTargetObjectId((Id)obj.get(strTargetObject));
                }else{
                    objEmail.setTargetObjectId(Userinfo.getUserId());
                } 

                objEmail.setTreatTargetObjectAsRecipient(false);
                objEmail.setSaveAsActivity(false);
                objEmail.setWhatId((Id)obj.get('Id')); 
                lstEmailNotifications.add(objEmail);

            }
            Messaging.SendEmailResult[] lstResults = Messaging.sendEmail(lstEmailNotifications,false); 
            
            
        }
    }
    
    private static set<String> addSetToAddress(String toAddressFields, sObject obj,set<String> setOfAddress){
        if(toAddressFields != null){
            for(String strToAddressField : toAddressFields.split(';')){
                system.debug('strToAddressField:::'+strToAddressField);
                if(strToAddressField.contains('.')){
                    system.debug('IN IF:::');
                    if((obj.getSobject(strToAddressField.split('\\.')[0])) != null){
                        system.debug('IN NESTED IF:::'+obj.getSobject(strToAddressField.split('\\.')[0]));
                        setOfAddress.add((String)obj.getSobject(strToAddressField.split('\\.')[0]).get(strToAddressField.split('\\.')[1]));
                    }
                }else{
                    if(strToAddressField != null){
                        setOfAddress.add((String)obj.get(strToAddressField));
                    }
                }  
            } 
        }
        setOfAddress.remove(null);
        
        return setOfAddress;
    }
    
     /*
    *  @AUTHOR:  Vignesh  
    *  @DESCRIPTION: Generic method to send emails
    *  @PARAM :  strEmailCondition - Condition for which email is to be sent
    *            lstWorkOrder - list of work orders which are to be processed
    *            accountIdToFSERoles - account to role map
                 mapPartnerWoIdAccId - Map that holds Related account Id.
    *  @RETURN:  void
    */ 
    public static void getSendEmailtoPartnerAccount(String strEmailCondition, List<sObject> lstsObject, 
                                                Map<Id,Map<String,Account_to_Field_Support__c>> accountIdToFSERoles, Map<Id,Id> mapPartnerWoIdAccId)
    {
        //Query the custom metadata for the emails setting
        Send_Email_Setting__mdt objSendEmailSetting = [Select To_Address_Roles__c, 
                                                        To_Address_Fields__c,
                                                        Additional_CC_Addresses__c,
                                                        CC_Address_Roles__c,
                                                        CC_Address_Fields__c,
                                                        Template_Name__c,
                                                        Target_Object_Field__c
                                                        from Send_Email_Setting__mdt
                                                        Where DeveloperName = :strEmailCondition];
        if(objSendEmailSetting != null){
            //TASK1037157:query Contact- Dummy Contact
            Contact objDummyContact = new Contact();
            try{
                objDummyContact = [select Id from Contact where Name = :CONTACT_NAME and Is_Active__c = true limit 1];
                ilib_LogEvent.info(DUMMY_CONTACT_FOUND_LOG_MSG+objDummyContact);
            } 
            catch(QueryException queryException) {
                ilib_LogEvent.info(DUMMY_CONTACT_NOT_FOUND_LOG_MSG);
                ApexExceptions.emit(LOG_TITLE, DUMMY_CONTACT_NOT_FOUND_LOG_MSG,ilib_LogEvent.SERVICE);
                objDummyContact = [select Id from Contact where Is_Active__c = true limit 1];
            }
            List<Messaging.SingleEmailMessage>  lstEmailNotifications = new List<Messaging.SingleEmailMessage>();
            //Get the id of the template to be used
            Id idEmailTemplate = ServiceUtilityCollection.getEmailTemplate(objSendEmailSetting.Template_Name__c);
            for(sObject obj : lstsObject){
                Messaging.SingleEmailMessage objEmail = new Messaging.SingleEmailMessage();
                
                Map<String,Account_to_Field_Support__c> roleTotechnician = new Map<String,Account_to_Field_Support__c>();
                //Fetch the roles assocaited with sobject's account
                if(accountIdToFSERoles != null && mapPartnerWoIdAccId != null){
                    Id relatedAccountId = mapPartnerWoIdAccId.containsKey(obj.Id) ? mapPartnerWoIdAccId.get(obj.Id) : Null;
                    if(relatedAccountId != Null && accountIdToFSERoles.containsKey(relatedAccountId) ){
                        roleTotechnician = accountIdToFSERoles.get(relatedAccountId); 
                    }
                }
                Set<String> setOfToAddress = new Set<String>();
                Set<String> setOfCCAddress = new Set<String>();
                //Get the to address fields
                //If the to address has is a lookup, split by '.' and get the parent field details
                setOfToAddress = addSetToAddress(objSendEmailSetting.To_Address_Fields__c,obj,setOfToAddress);
                
                if(objSendEmailSetting.To_Address_Roles__c != null){
                    for(String strToAddressRole : objSendEmailSetting.To_Address_Roles__c.split(';')){
                        if(roleTotechnician != null && roleTotechnician.containsKey(strToAddressRole)){
                            setOfToAddress.add(roleTotechnician.get(strToAddressRole).User__r.SVMXC__Salesforce_User__c);
                        }
                    }
                }
                //get the cc fields
                setOfCCAddress = addSetToAddress(objSendEmailSetting.CC_Address_Fields__c,obj,setOfCCAddress);
                //get the cc address fields
                if(objSendEmailSetting.CC_Address_Roles__c != null){
                    for(String strCCAddressRole : objSendEmailSetting.CC_Address_Roles__c .split(';')){
                        if(roleTotechnician != null  && roleTotechnician.containsKey(strCCAddressRole)){
                            setOfCCAddress.add(roleTotechnician.get(strCCAddressRole).User__r.SVMXC__Salesforce_User__c);
                        }
                    }
                }
                
                 //Get the Additional CC addesses
                //Splits the CC Addresses by ';'
                if(objSendEmailSetting.Additional_CC_Addresses__c != null){
                    for(String strAdditionalCCAddress : objSendEmailSetting.Additional_CC_Addresses__c.split(';')){
                        setOfCCAddress.add(strAdditionalCCAddress); 
                    }
                }
                
                objEmail.setTemplateId(idEmailTemplate);
                
                List<String> lstToAddress = new List<String>();
                lstToAddress.addAll(setOfToAddress);
                objEmail.setToAddresses(lstToAddress);
                 List<String> lstCCAddress = new List<String>();
                lstCCAddress.addAll(setOfCCAddress); 
                objEmail.setCcAddresses(lstCCAddress);

                String strTargetObject = objSendEmailSetting.Target_Object_Field__c;                
                if(strTargetObject != null && strTargetObject == STRING_DUMMY_CONTACT){
                    objEmail.setTargetObjectId(objDummyContact.Id);
                }else if(strTargetObject != null && obj.get(strTargetObject) != null){
                    objEmail.setTargetObjectId((Id)obj.get(strTargetObject));
                }else{
                    objEmail.setTargetObjectId(Userinfo.getUserId());
                } 

                objEmail.setTreatTargetObjectAsRecipient(false);
                objEmail.setSaveAsActivity(false);
                objEmail.setWhatId((Id)obj.get('Id')); 
                lstEmailNotifications.add(objEmail);
                
            }
            Messaging.SendEmailResult[] lstResults = Messaging.sendEmail(lstEmailNotifications,false); 

            
        }
    }

    /**
     *  @author Tapas
     *  @description RITM0503667, create generic method to send email 
     *  @Release - Aug2021
     *  this method is covered in TestPartsOrderDataReceiver.testPartsOrderUpdateHTTPPostForMissingProduct() class
     **/
    public static Messaging.SingleEmailMessage sendEmailWithEmailConditionsWrapper(EmailConditionsWrapper objWrapper){
        Messaging.SingleEmailMessage objEmail = new Messaging.SingleEmailMessage();
        objEmail.setSubject(objWrapper.subject);        
        objEmail.setHtmlBody(objWrapper.htmlEmailBody);
        objEmail.setToAddresses(objWrapper.lstToAddresses);
        objEmail.setTreatTargetObjectAsRecipient(false);
        objEmail.setSaveAsActivity(false);
        objEmail.setUseSignature(false);                
        return objEmail;
    }
    /**
    * Name: EmailConditionsWrapper
    * This is a wrapper class for storing the details of an email.
    */
    public class EmailConditionsWrapper{
        public String htmlEmailBody;
        public List<String> lstToAddresses;
        public String subject;
    } 
    
     /**
    * @description - Function defined for fetching the additional elevation members associated with the elevation record
    * highlight - elevationMemberTypeStr parameter is being used here to join the elevationMemberType list 
    *               as this is multi select picklist with values containing parathensis itself "()". to over come the dynamic 
    *               query exception we are converting it to string with parenthesis.
    * @author Prerna  Agrawal
    **/
    public static Map<Id,Set<String>> fetchAdditionalElevationMembers(String elevationStrCondition, Set<Id> workOrderIds){
        Map<Id,Set<String>> woIdBYElevationMembersId = new Map<Id,Set<String>>();
        
        List<String> elevationMemberType = getElevationMemberTypeBasedOnElevationType(elevationStrCondition);
        String elevationMemberTypeStr = '(\''+String.join(elevationMemberType, '\',\'')+ '\')';
        List<Related_Contacts__c> elevationMembersList = new RelatedContactsSelector().selectAddElevationMembersByWOId(workOrderIds,elevationMemberTypeStr);
        
        for(Related_Contacts__c addMemberObj : elevationMembersList){
            
            Id userOrContactId;
            if(addMemberObj.User__c != null){
                userOrContactId = addMemberObj.User__c;
            }
            else if(addMemberObj.Contact__c != null){
                userOrContactId = addMemberObj.Contact__c;
            }
                
            if(!woIdBYElevationMembersId.containsKey(addMemberObj.Elevated_Work_Order__c)){
                woIdBYElevationMembersId.put(addMemberObj.Elevated_Work_Order__c,new Set<String>());
            }
            
            woIdBYElevationMembersId.get(addMemberObj.Elevated_Work_Order__c).add(userOrContactId);
            
        }
        return woIdBYElevationMembersId;

    }

    /**
    * @description - Function defined for fetching the additional elevation member type based on the elevation status of the elevation record
    * @author Prerna  Agrawal
    **/
    public static List<String> getElevationMemberTypeBasedOnElevationType(String elevationStrCondition){
        List<String> elevationMemberType = new List<String>();
        if(elevationStrCondition == label.Elevation_Technical_Close_Status_Metadata || elevationStrCondition == Label.Technical_Elevation_Reopen_Notification
            || elevationStrCondition == Label.Technical_Elevation_Send_Plan_of_Action_Metadata || elevationStrCondition == Label.Technical_Elevation_Create_Notification) {
            elevationMemberType.add(label.Elevation_Member_Type_Watcher_Technical);
            elevationMemberType.add(label.Elevation_Member_Type_Watcher_Both);
        }
       // DCP - 49680
        else if(elevationStrCondition == label.Elevation_Account_Reopen_Status_Metadata || elevationStrCondition == label.Account_Elevation_Closure_Notification || elevationStrCondition == label.Elevation_Account_Open_Status_Metadata){
            elevationMemberType.add(label.Elevation_Member_Type_Watcher_Account);
            elevationMemberType.add(label.Elevation_Member_Type_Watcher_Both);
        }
        return elevationMemberType;
    }
}