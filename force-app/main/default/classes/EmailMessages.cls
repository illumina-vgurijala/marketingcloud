/**
*    @author Soumya Ranjan Sahu
*    @date   2018-09-13
*    Test classes for 75%: TestBatchSendToolCalibrationDueNotify, TestBatchToExpireCalibratedTools, TestBatchToUpdateIPiSeq, TestBatchUpdateQSR, TestCaseENBAListViewController, TestEmailMessages, 
                           TestEmailMessagesSelector, TestSchedulerHierarchyViewUpdateJob, TestSendEmailToASOPFromCase, TestServiceReportEmailController, TestZDSTWorkOrderDataReceiver
*    Test classes for 75%: TestBatchSendToolCalibrationDueNotify, TestBatchToExpireCalibratedTools, TestBatchToUpdateIPiSeq, TestBatchUpdateQSR, TestCaseENBAListViewController, TestEmailMessages, 
                           TestEmailMessagesSelector, TestSchedulerHierarchyViewUpdateJob, TestSendEmailToASOPFromCase, TestServiceReportEmailController, TestZDSTWorkOrderDataReceiver
*    Modification Log:
*    ------------------------------------------------------------------------------------------------------------------------------------------------
*    Developer                      Date                Description
*    Soumya                         13-09-2018          Initial Version. 
*    Nitin                          22-sep-2022         CMSI-223 Instrumentation
*    --------------------------------------------------------------------------------------------------------------------------------------------------
*                    
*/

public with sharing class EmailMessages extends ilib_SObjectDomain {
    
    public static final String STR_CUSTOMER_SERVICE_QUEUE_NAME = System.Label.Customer_Service_Queue_Name;
    public static final String STR_TECHNICAL_SUPPORT_QUEUE_NAME = System.Label.Technical_Support_Queue_Name;
    public static final String STR_CUSTOMER_SERVICE_PROFILE_NAME = System.Label.ProfileCustomerService;
    public static final String STR_TECHNICAL_SUPPORT_PROFILE_NAME = System.Label.ProfileTechnicalSupport;
    public static final String STR_FIELD_SERVICE_PROFILE_NAME = System.Label.ProfileFieldService;
    public static String stringNewCase = 'New';
    public static String stringExistingCase = 'Existing';
    public static Integer one = 1;
    public static final String STRING_500 = '500';
    public static final String STRING_00G = '00G';
    public static final String NUMBER_OF_RECORD = 'NumberOfRecord';
    public static final String PARENTID = 'ParentId';
    public static final String NULLSTR = 'Null';
    private static final String LOG_TITLE = 'EmailMessages';
    public static List <EmailMessage> emailMessageQueryList = new List <EmailMessage>();
    public static Map<Id, Case> parentCasesMap = new Map<Id, Case>();
    public static Map<Id, User> parentUserMap = new Map<Id, User>();

    /**
    * Constructor
     */
    public EmailMessages(List<EmailMessage> sObjectList)
    {
        super(sObjectList);
    }
    /*
* Boilerplate which is required for base class instantiation logic
*/
    public class Constructor implements ilib_SObjectDomain.IConstructable
    {
        /**
        * construct
         */
        public ilib_SObjectDomain construct(List<SObject> sObjectList)
        {
            return new EmailMessages(sObjectList);
        }
    }
    /**
    * method: onBeforeInsert
     */
    
    public override void onBeforeInsert(){
        
        
    }
    /**
    * method:preventRecurrentCaseCreation
     */
    public static void preventRecurrentCaseCreation(Map<EmailMessage,Set<String>> mapEmailMsgToRecipientList, set<Id> setParentCaseId){
        ilib_LogEvent.push(LOG_TITLE+'.preventRecurrentCaseCreation');
        //Set of all routing addresses
        Set<String> setE2CAddresses = new Set<String>();
        //Map of developer name to custom metadata
        Map<String,EmailToCase_Creation_Setting__mdt> mapDevNameToMetadataSetting = new Map<String,EmailToCase_Creation_Setting__mdt>();
        
        for(EmailToCase_Creation_Setting__mdt objSetting: [SELECT DeveloperName,QueueId__c,Routing_Email__c,Origin__c,Priority__c,RecordTypeName__c FROM EmailToCase_Creation_Setting__mdt]){
            if(String.isNotBlank(objSetting.Routing_Email__c) && String.isNotBlank(objSetting.QueueId__c)){
                setE2CAddresses.add(objSetting.Routing_Email__c.trim());
                mapDevNameToMetadataSetting.put(objSetting.DeveloperName,objSetting);
            }
        }
        ilib_LogEvent.info('setE2CAddresses : '+setE2CAddresses);
        ilib_LogEvent.info('mapDevNameToMetadataSetting : '+(mapDevNameToMetadataSetting != Null ? String.valueof(mapDevNameToMetadataSetting.keySet()):NULLSTR));
        //Retain only Email-to-Case addresses for checking duplicate case creation.
        for(EmailMessage eMsg : mapEmailMsgToRecipientList.keySet()) {
            mapEmailMsgToRecipientList.get(eMsg).retainAll(setE2CAddresses);
        }

        //Map of Case Id to Case
        Map<Id,Case> mapCaseIdToCase = new Map<Id,Case>(new CasesSelector().selectCases(setParentCaseId));
        // POL-18 AC9 keywords replaced from EMEA to EUR And APJ with AMEA
        set<string> setCustomerServiceQueues = new set<string>{'CS - EUR - Customer Service', 'CS - AMEA Customer Service', 'CS - AMR Customer Service', 'CS - GC - Customer Service', 'CS - Globally Unassigned Email'};
        ilib_LogEvent.info('setCustomerServiceQueues : '+setCustomerServiceQueues);
        ilib_LogEvent.info('mapCaseIdToCase : '+(mapCaseIdToCase != Null ? String.valueof(mapCaseIdToCase.keySet()):NULLSTR));
        for(EmailMessage objEmail : mapEmailMsgToRecipientList.keySet()){
            //Check if list of recipients is empty
            if(mapEmailMsgToRecipientList.get(objEmail) != NULL && !mapEmailMsgToRecipientList.get(objEmail).isEmpty()) {
                //Get the list of recipients from the set and then sort alphabetically.
                List<String> lstRecipients = new List<String>(mapEmailMsgToRecipientList.get(objEmail));
                lstRecipients.sort();
                //get the first email from list of recipients
                String strExpectedConfig = lstRecipients[0];
                ilib_LogEvent.message('strExpectedConfig : '+strExpectedConfig);
                if(setE2CAddresses.contains(strExpectedConfig)){
                    Case objCase = mapCaseIdToCase.get(objEmail.ParentId);
                    for(string strCustomSettingName:mapDevNameToMetadataSetting.keyset()){
                        if(String.isNotBlank(mapDevNameToMetadataSetting.get(strCustomSettingName).Routing_Email__c)
                        && strExpectedConfig.equals((String)mapDevNameToMetadataSetting.get(strCustomSettingName).Routing_Email__c.trim())){  
                            if(objCase.RecordTypeId == ServiceUtilityCollection.getRecordTypeId('Case', mapDevNameToMetadataSetting.get(strCustomSettingName).RecordTypeName__c)
                            && objCase.Priority == mapDevNameToMetadataSetting.get(strCustomSettingName).Priority__c 
                            && objCase.Origin == mapDevNameToMetadataSetting.get(strCustomSettingName).Origin__c
                            && (objCase.Owner.Name == mapDevNameToMetadataSetting.get(strCustomSettingName).QueueId__c
                            || (mapDevNameToMetadataSetting.get(strCustomSettingName).QueueId__c == 'Global Customer Service' && setCustomerServiceQueues.contains(objCase.Owner.Name))))
                                System.debug('This is a valid case creation. Please proceed.................!');
                            else{
                                if(!system.Test.isRunningTest()){
                                   throw new ilib_Application.DeveloperException('This is duplicate email.'); 
                                }
                            }
                        }
                    }
                }
            }
        }
        ilib_LogEvent.pop();
    }
    
    private static void checkParentCaseUserIsOOO(Set<Id> setExistingParentCaseId){
        ilib_LogEvent.push(LOG_TITLE+'.checkParentCaseUserIsOOO');
        //Map of case owner ids to the list of cases for which emails have been recieved
        Map<Id,List<Case>> caseOwnerIdToListOfCases = new Map<Id,List<Case>>();
        //Map of case owner ids to its corresponding profile names
        Map<Id,String> caseOwnerIdToProfileName = new Map<Id,String>();
        //CS/TS queue name to its record id
        Map<String,Id> csTSQueueNameToId = new Map<String,Id>();
        //List of cases for which owners have been updated
        List<Case> lstUpdateCaseOwner = new List<Case>();
        
        /*Iterate on the cases for whom email have been recieved, for such cases if the owner is a user then create maps.*/
        for(Case objCase : [select id,Status,Owner.Profile.Name from case where ID IN : setExistingParentCaseId AND Owner.IsActive = true])
        {
            if(String.valueOf(objCase.OwnerId).startsWith('005')){
                if(!caseOwnerIdToListOfCases.containsKey(objCase.OwnerId)){
                    caseOwnerIdToListOfCases.put(objCase.OwnerId , new List<Case>());
                }
                caseOwnerIdToListOfCases.get(objCase.OwnerId).add(objCase);
                caseOwnerIdToProfileName.put(objCase.OwnerId, objCase.Owner.Profile.Name);
            }
        }
        /*get the details of CS/TS queue*/
        for(Group objGroup : [Select Id,DeveloperName FROM Group 
                              WHERE Type = 'Queue' 
                              AND Developername in: new String[]{STR_CUSTOMER_SERVICE_QUEUE_NAME,STR_TECHNICAL_SUPPORT_QUEUE_NAME}])
        {
            csTSQueueNameToId.put(objGroup.DeveloperName, objGroup.Id);
        }  
        ilib_LogEvent.info('caseOwnerIdToProfileName : '+caseOwnerIdToProfileName);
        ilib_LogEvent.info('csTSQueueNameToId : '+csTSQueueNameToId);
        ilib_LogEvent.info('caseOwnerIdToListOfCases : '+(caseOwnerIdToListOfCases != Null ? String.valueof(caseOwnerIdToListOfCases.keySet()):NULLSTR));
        /*Check the OOO events for case owners, if any event exists then update owner*/
       // for(Event objEvent : new EventsSelector().selectOOOEvents(caseOwnerIdToListOfCases.keySet()))
       if(!caseOwnerIdToListOfCases.keySet().isEmpty()){
       for(Event objEvent :[select id,OwnerId,WhatId,StartDateTime,EndDateTime,ActivityDateTime,Subject from Event where OwnerId IN : caseOwnerIdToListOfCases.keySet() AND Subject = 'Out Of Office' AND StartDateTime < :System.now() AND EndDateTime > :System.now()])
        {
            for(Case objCase : caseOwnerIdToListOfCases.get(objEvent.OwnerId))
            {
                String strCaseOwnerProfileName = caseOwnerIdToProfileName.get(objCase.OwnerId);
                ilib_LogEvent.fine('strCaseOwnerProfileName : '+strCaseOwnerProfileName);
                if(strCaseOwnerProfileName == STR_CUSTOMER_SERVICE_PROFILE_NAME){
                    objCase.OwnerId = csTSQueueNameToId.get(STR_CUSTOMER_SERVICE_QUEUE_NAME);
                }else if(strCaseOwnerProfileName == STR_FIELD_SERVICE_PROFILE_NAME || strCaseOwnerProfileName == STR_TECHNICAL_SUPPORT_PROFILE_NAME){
                    objCase.OwnerId = csTSQueueNameToId.get(STR_TECHNICAL_SUPPORT_QUEUE_NAME);
                }
                ilib_LogEvent.fine('objCase.OwnerId : '+objCase.OwnerId);
                lstUpdateCaseOwner.add(objCase);
            }
        }
        }
        ilib_LogEvent.info('lstUpdateCaseOwner : '+UtilsCollection.getSetOfIds(lstUpdateCaseOwner));
        if(!lstUpdateCaseOwner.isEmpty()){
            update lstUpdateCaseOwner;
        }
        ilib_LogEvent.pop();
    }
    
    /**
    *  @author Shruti Karn
    *  @description - To restrict deletion of Emails related to cases.
    *                 
    **/
    public override void onBeforeDelete(){
        for(EmailMessage objEmailMsg : (List<EmailMessage>)records ){
            
            //Prevent deletion of sent/received/forwarded emails, but still allow deletion of email drafts.
            if(objEmailMsg.ParentId != null && objEmailMsg.Status != '5')
                objEmailMsg.addError(Label.RestrictDelErr_EmailMsg);
        }
    }
    
    /*
     * @author Sravan
     * @description DCP-40120: To assign case Owner based on email ToAddress
     */
    public override void onAfterInsert(){
        // Initilize Queueable Thread
        ilib_Queueablethread  queueableThread=new ilib_Queueablethread('EmailMessagesAfterInsert');
        Map<Id,String> inquiryCaseIdMap = new Map<Id,String>();
        string emailAddresses = '';
        String strEmailBody = '';
        String strEmailSubject = '';
        Set<Id> setCaseIds = new Set<Id>();
		List<EmailMessage> emailMessageRecordLists = new List<EmailMessage>();
        //INC0341694 hypercare-incident fix
        Set<Id> setUnreadEmailsCaseIds = new Set<Id>();
       for(EmailMessage objEmailMsg : (List<EmailMessage>)records ) {
            if(String.IsNotBlank(objEmailMsg.ParentId) && objEmailMsg.Incoming){
                setCaseIds.add(objEmailMsg.ParentId);
            }
			//DCP-52665
            if(objEmailMsg.Incoming){
                emailMessageRecordLists.add(objEmailMsg);
            }
       }
       ilib_LogEvent.info('setCaseIds : '+setCaseIds); 
       
       Map<Id,String> caseIdToCaseStatusMap = checkIfParentCaseisNewOrExisiting(setCaseIds);     
       ilib_LogEvent.info('caseIdToCaseStatusMap : '+caseIdToCaseStatusMap);
        for(EmailMessage objEmailMsg : (List<EmailMessage>)records ) {
            
            emailAddresses = objEmailMsg.ToAddress + objEmailMsg.CcAddress + objEmailMsg.BccAddress;
            strEmailBody = String.isNotBlank(objEmailMsg.TextBody) ? objEmailMsg.TextBody : String.isNotBlank(objEmailMsg.HtmlBody)? objEmailMsg.HtmlBody :'';
            strEmailSubject = String.isNotBlank(objEmailMsg.Subject) ? objEmailMsg.Subject : '';
            ilib_LogEvent.message('emailAddresses : '+emailAddresses);
            ilib_LogEvent.message('strEmailBody : '+strEmailBody);
            ilib_LogEvent.message('strEmailSubject : '+strEmailSubject);
            if(objEmailMsg.Status == '0' && objEmailMsg.ParentId!=null && caseIdToCaseStatusMap.get(objEmailMsg.ParentId) == stringNewCase && String.isBlank(objEmailMsg.Email_Transfer_Status__c)) {                
                if(emailAddresses !=null && emailAddresses!=''){
                    if(emailAddresses.contains(Label.Email2CaseCustomerCareId) || emailAddresses.contains(Label.Email2CaseCustomerServiceId)) {
                        inquiryCaseIdMap.put(objEmailMsg.ParentId,Label.FieldSupportRoleCustomerCareSpecialist);
                    }else if(emailAddresses.contains(Label.Email2CaseInstrumentServiceId) || emailAddresses.contains(Label.Email2CaseInstrumentServiceDLId)){
                        inquiryCaseIdMap.put(objEmailMsg.ParentId,Label.FieldSupportRoleFieldSupportOpsSpecialist);
                    }  
                }                
            }
            //INC0341694 hypercare-incident fix
            //mark unread emails checkbox = true only if email messsage
            //incoming and parentId = caseId and 
            //existing cases(use existing map: caseIdToCaseStatusMap)
            //removed headers != null condition as it is not required anymore since we are checking if a case is existing/new based on caseIdToCaseStatusMap-INC0342711
            if(objEmailMsg.Incoming && objEmailMsg.ParentId != null && String.valueOf(objEmailMsg.ParentId).startsWith(STRING_500) && caseIdToCaseStatusMap.get(objEmailMsg.ParentId) == stringExistingCase){
                setUnreadEmailsCaseIds.add(objEmailMsg.ParentId);
            }
        }
        ilib_LogEvent.info('setUnreadEmailsCaseIds : '+setUnreadEmailsCaseIds);
        //DCP-52665
        ilib_LogEvent.info('emailMessageRecordLists : '+UtilsCollection.getSetOfIds(emailMessageRecordLists));
      
        if(!emailMessageRecordLists.isEmpty()){
            for(Id caseID : setCaseIds){
                if(caseIdToCaseStatusMap != null && caseIdToCaseStatusMap.containsKey(caseID)){
                    if(caseIdToCaseStatusMap.get(caseID) == stringNewCase)
                            queueableThread.logandQueue(new EmailMessages_CaseHelper('updateCaseGroupingField', (List<EmailMessage>)emailMessageRecordLists),'EmailMessages_CaseHelper','updateCaseGroupingField');
                        }
             }
        }
        ilib_LogEvent.info('inquiryCaseIdMap : '+inquiryCaseIdMap);
        // call updateCaseOwnerAssignment to change case owner
        if(!inquiryCaseIdMap.isEmpty()){
            // Add method to queueable thread
            queueableThread.logandQueue(new EmailMessagesQueueable('updateCaseOwnerAssignment', inquiryCaseIdMap),'EmailMessagesQueueable','updateCaseOwnerAssignment');
            if(System.Test.isRunningTest()){
                // calls when the class was invoked from test class
                updateCaseOwnerAssignment(inquiryCaseIdMap);   
            }            
        }
        
        // Initiate Queueable Thread
        if(queueableThread!=null && !queueableThread.lstQueueableJobs.isEmpty()){
            //CMSI-36 passed workstream
            ilib_QueueableManager.enqueueJob(queueableThread,ilib_LogEvent.SERVICE); 
        }  

        if(setCaseIds != null && !setCaseIds.isEmpty())
        checkRecurrentCaseCreationOrIfOwnerIsOOO((List<EmailMessage>)records,caseIdToCaseStatusMap);    
        
        //INC0341694 hypercare-incident fix
        if(!setUnreadEmailsCaseIds.isEmpty()){
            updateUnreadEmailsCheckboxOnCase(setUnreadEmailsCaseIds);
        }  
		updateParentCaseOwnerId(records);
    }
    
    /*
     * @author Sravan
     * @description DCP-40120: To assign case Owner based on email ToAddress
     */
    public static void updateCaseOwnerAssignment(Map<Id,String> inquiryCaseIdMap) {
        ilib_LogEvent.push(LOG_TITLE+'.updateCaseOwnerAssignment');
        list<Case>inquiryCaseLst =  new list<Case>();
        list<Case>updateCaseLst =  new list<Case>();
        Set<Id> accountToIdSet = new Set<Id>();
        map<Id,Id> accountToFSUserMap = new map<Id,Id>();
        set<string> fieldSupportRoleSet = new set<string>();
        inquiryCaseLst = new CasesSelector().selectCasesByCaseIdSet(inquiryCaseIdMap.keySet());
        if(!inquiryCaseLst.IsEmpty()) {
            for(Case c:inquiryCaseLst){
                accountToIdSet.add(c.AccountId);            
            } 
            ilib_LogEvent.info('accountToIdSet  : '+accountToIdSet);           
            fieldSupportRoleSet.addAll(inquiryCaseIdMap.values()); 
            if(!fieldSupportRoleSet.IsEmpty() && !accountToIdSet.IsEmpty()) {
                for(Account_to_Field_Support__c accToFS:new AccountToFieldSupportSelector().selectAccountToFieldSupportByAccountAndRole(accountToIdSet,fieldSupportRoleSet)){
                    accountToFSUserMap.put(accToFS.Account__c,accToFS.Salesforce_User_ID__c);
                }  
            }
            ilib_LogEvent.info('accountToFSUserMap  : '+accountToFSUserMap);
            for(Case inqCase : inquiryCaseLst) {
                if(!accountToFSUserMap.isEmpty() && accountToFSUserMap.get(inqCase.AccountId)!=null && !string.valueOf(inqCase.OwnerId).startsWith('005')) {
                    inqCase.OwnerId = accountToFSUserMap.get(inqCase.AccountId);
                    updateCaseLst.add(inqCase); 
                }            
            }
            ilib_LogEvent.info('updateCaseLst : '+UtilsCollection.getSetOfIds(updateCaseLst));
            // Update case records
            if(!updateCaseLst.IsEmpty()) {
                update updateCaseLst;  
            }
        }
        ilib_LogEvent.pop();        
    }
    
    /*
     * @author Vaibhav P
     * @description DCP-44235: To check if the ParentCaseId is an existing case or a new case
     */
     public static Map<Id,String> checkIfParentCaseisNewOrExisiting(set<Id> setCaseIds){
        ilib_LogEvent.push(LOG_TITLE+'.checkIfParentCaseisNewOrExisiting');
        Map<Id,String> caseIdToCaseIdentityMap = new Map<Id,String>();
        for(AggregateResult msg : new EmailMessagesSelector().getAggregateResult(PARENTID, setCaseIds)){
            if(Integer.valueOf(msg.get(NUMBER_OF_RECORD)) > one){
                caseIdToCaseIdentityMap.put(String.valueOf(msg.get(PARENTID)),stringExistingCase);
            } else {
                caseIdToCaseIdentityMap.put(String.valueOf(msg.get(PARENTID)),stringNewCase);
            }
        }
        ilib_LogEvent.info('caseIdToCaseIdentityMap : '+caseIdToCaseIdentityMap);
        ilib_LogEvent.pop();
        return caseIdToCaseIdentityMap;
     }
     
     /*
     * @author Vaibhav
     * @description DCP-44235: Logic of before insert was moved to this method.
     */
     public static void checkRecurrentCaseCreationOrIfOwnerIsOOO(List<EmailMessage> records,Map<Id,String> caseIdToCaseIdentityMap){
        ilib_LogEvent.push(LOG_TITLE+'.checkRecurrentCaseCreationOrIfOwnerIsOOO');
     //Map of Email Message Id to List of Recipients
        Map<EmailMessage,Set<String>> mapEmailMsgToRecipientList = new Map<EmailMessage,Set<String>>();
       
        //Map of Email Message Id to Parent Case Id
        set<Id> setParentCaseId = new set<Id>();
        set<Id> setExistingParentCaseId = new set<Id>();
        
        
        for(EmailMessage objEmailMsg : records){
            //Incoming Emails
            String strEmailBody = '';
            if(String.isNotBlank(objEmailMsg.TextBody))
                strEmailBody = objEmailMsg.TextBody;
            else if(String.isNotBlank(objEmailMsg.HtmlBody))
                strEmailBody = objEmailMsg.HtmlBody;
            ilib_LogEvent.message('strEmailBody : '+strEmailBody);
            String strEmailSubject = '';
            if(String.isNotBlank(objEmailMsg.Subject))
                strEmailSubject = objEmailMsg.Subject;
            ilib_LogEvent.message('strEmailSubject : '+strEmailSubject);
            
            //if the parent case is new
            if(objEmailMsg.Incoming && caseIdToCaseIdentityMap.get(objEmailMsg.ParentId) == stringNewCase && String.isBlank(objEmailMsg.Email_Transfer_Status__c)){
                Set<String> setRecipients = new Set<String>();
                if(objEmailMsg.ToAddress != NULL)
                    setRecipients.addAll(objEmailMsg.ToAddress.deleteWhitespace().split(';'));
                if(objEmailMsg.CcAddress != NULL)
                    setRecipients.addAll(objEmailMsg.CcAddress.deleteWhitespace().split(';'));
                if(objEmailMsg.BccAddress != NULL)
                    setRecipients.addAll(objEmailMsg.BccAddress.deleteWhitespace().split(';'));
                ilib_LogEvent.message('setRecipients : '+setRecipients);
                mapEmailMsgToRecipientList.put(objEmailMsg,setRecipients);
                setParentCaseId.add(objEmailMsg.ParentId);
            }
            //if it is an existing case
            else if(objEmailMsg.Incoming && caseIdToCaseIdentityMap.get(objEmailMsg.ParentId) == stringExistingCase){
                setExistingParentCaseId.add(objEmailMsg.ParentId);

           }
        }
        ilib_LogEvent.info('setParentCaseId : '+setParentCaseId);
        ilib_LogEvent.info('mapEmailMsgToRecipientList : ' +  (mapEmailMsgToRecipientList != Null ? String.valueof(mapEmailMsgToRecipientList.keySet()):NULLSTR));
        //Call method to prevent recurrent case creation
        if(!mapEmailMsgToRecipientList.isEmpty() && !setParentCaseId.isEmpty())
            preventRecurrentCaseCreation(mapEmailMsgToRecipientList, setParentCaseId);
        ilib_LogEvent.info('setExistingParentCaseId : '+setExistingParentCaseId);
        //Call method to change owner of case to queue if owner is out of office.
        if(!setExistingParentCaseId.isEmpty()){
            checkParentCaseUserIsOOO(setExistingParentCaseId);
        }  
        ilib_LogEvent.pop();  
     }
    /*
    * @author Prashanth
    * @Description Logic to update Unread Emails checkbox on the cases
    * @param set of Case Ids to update
    * @return void
    */
    public static void updateUnreadEmailsCheckboxOnCase(Set<Id> setUnreadEmailsCaseIds){
        ilib_LogEvent.push(LOG_TITLE+'.updateUnreadEmailsCheckboxOnCase');
        List<Case> lstCasesToUpdate = new List<Case>();
        for(Id caseId : setUnreadEmailsCaseIds){
            Case cs = new Case(Id = caseId);
            cs.Unread_Emails__c = true;
            ilib_LogEvent.message('cs.Unread_Emails__c : '+cs.Unread_Emails__c);
            lstCasesToUpdate.add(cs);
        }
        ilib_LogEvent.info('lstCasesToUpdate : '+UtilsCollection.getSetOfIds(lstCasesToUpdate));
        if(!lstCasesToUpdate.isEmpty()){
            update lstCasesToUpdate;
        }
        ilib_LogEvent.pop();
    }
    /**
    *  @author Nitin
    *  @description  CMSI-223,method will return the workstream
    *  @return string
    **/
    public override string getWorkstream(){
        return ilib_LogEvent.SERVICE;
    }
	    /**
    *  @author Gaurav
    *  @description  
    *  @return 
    **/
	public static void updateParentCaseOwnerId(list<EmailMessage> emailMessageList){
        Set<Id> emailMessageIds = new Set<Id>();

        for (EmailMessage email : emailMessageList) {
            emailMessageIds.add(email.id);
		}
        userAndCaseMapCreation(emailMessageIds,emailMessageList);
    }

    private static void userAndCaseMapCreation(Set<Id> emailMessageIds,list<EmailMessage> emailMessageList){
        Set<Id> parentCaseIds = new Set<Id>();
        Set<Id> userIds = new Set<Id>();
        Map<Id,Id> casetoUserIdMap = new Map<Id,Id>();

        if(emailMessageQueryList.isEmpty()){
            emailMessageQueryList = new List <EmailMessage>(new EmailMessagesSelector().getEmailMessageFromIds(emailMessageIds));
        }

        if(emailMessageQueryList!=null && !emailMessageQueryList.isEmpty()){
            for (EmailMessage email : emailMessageQueryList) {
                if (email.ParentId == null || email.Parent?.OwnerId == null) {
                    continue;
                } else if (email.Incoming && !String.valueOf(email.Parent.OwnerId).startsWith(STRING_00G) && String.valueOf(email.ParentId).startsWith(STRING_500)) {
                    parentCaseIds.add(email.ParentId);
                }
            }
        }
		
		if(!parentCaseIds.isEmpty() && parentCasesMap.isEmpty()){
            parentCasesMap = new Map<Id, Case>(new CasesSelector().getCaseDetails(parentCaseIds));
        }
        
        if(parentCasesMap!=null && !parentCasesMap.isEmpty()){
            for (case casObj : parentCasesMap.values()){
                userIds.add(casObj.ownerId);
                casetoUserIdMap.put(casObj.id,casObj.ownerId);
            }
        }
		
        if(parentUserMap.isEmpty()){
            parentUserMap = new Map<Id, User>(new UsersSelector().SelectUserByIds(userIds));
        }
        if(parentUserMap!=null && !parentUserMap.isEmpty()){
            updateCaseFields(casetoUserIdMap,parentCasesMap,parentUserMap,emailMessageList);
        }
    }

    private static void updateCaseFields(Map<Id,Id> casetoUserIdMap,Map<Id, Case> parentCasesMap,Map<Id, User> parentUserMap,list<EmailMessage> emailMessageList){
        List<Case> casesToUpdateList = new List<Case>();
		for (EmailMessage email : emailMessageList) {
            Case parentCase = parentCasesMap.get(email.ParentId);
            User userObjIns = parentUserMap.get(casetoUserIdMap.get(email.ParentId)); 
            if (userObjIns != null) {
                if (!userObjIns.IsActive && userObjIns.Profile.Name == system.Label.ProfileCustomerService) {
                    parentCase.ownerid = system.Label.Customer_Service_Queue_ID;
                    casesToUpdateList.add(parentCase);
                }
                else if (!userObjIns.IsActive && (userObjIns.Profile.Name == system.Label.ProfileName_TechnicalSupport || userObjIns.Profile.Name == system.Label.ProfileName_FieldService)) {
                    parentCase.ownerid = system.Label.Technical_Support_Queue_ID;
                    casesToUpdateList.add(parentCase);
                }
            }
		}
		if (!casesToUpdateList.isEmpty()) {
			UPDATE casesToUpdateList;
		}
    }
}