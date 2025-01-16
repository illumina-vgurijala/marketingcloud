/**
 * Class Name: FindDuplicateRecordsController
 * DESCRIPTION: This controller is for finding the duplicates for a specific record using dupeblocker scenarios.
 * @Author: Prashanth kumar
 * Test Class for 75% Coverage : TestFindDuplicateRecordsController
 * Test Class for 90% Coverage : TestFindDuplicateRecordsController
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION
 * ---------------------------------------------------------------------------------------------------------------------
 * Prashanth Kumar         25-08-2020           original version.
 * Prbhsimran Singh        10-12-2020           INC0296294 - modified sendEmailMergeRequest and added updateEmailBody method.
 * Rishab Wali             01-06-2022           DCP-53839 - Check permission set assignment access
 * Anshaj Sinha            05-09-2022           CMSI-214 - Instrumented Class for ilib_LogEvent Framework
 **/
public with sharing class FindDuplicateRecordsController {
    public static final String CHARS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz';
    public static final String STRING_CONVERTED_LEAD_STATUS = 'Lead Converted No Opp';
    public static final String STRING_CONTACT_OBJECT = 'Contact';
    public static final String STRING_LEAD_OBJECT = 'Lead';
    public static final String LEAD_MERGE_REQUEST_TEMPLATE = 'Lead_Merge_Request_Template';
    public static final String CONTACT_MERGE_REQUEST_TEMPLATE = 'Contact_Merge_Request_Template';
    public static final String FUNNEL_MARKETING_REGIONAL_DL = 'Funnel_Marketing_Regional_DL_';
    public static final String  DATA_STEWARD_REGIONAL_DL = 'MDG_Regional_Emails_';
    public static final String LEADFIRSTNAMELOCAL = 'LeadFirstNameLocal';
    public static final String LEADLASTNAMELOCAL = 'LeadLastNameLocal';
    public static final String LOG_TITLE = 'FindDuplicateRecordsController';

    /**
     * method name: dynamicSOQL
     * Description: This method is to retrive the record values based on the Id and list of fields.
     * params:recordId & list of fields to query.
     * return: list of sobject
     **/
    public static List<sObject> dynamicSOQL(Id recordId, List<String> lstFieldsToQuery){
        ilib_LogEvent.push(LOG_TITLE + '.dynamicSOQL()');
        List<sObject> records = new List<sObject>();
        String strObjectName = recordId.getSObjectType().getDescribe().getName();
        if(recordId != null && !lstFieldsToQuery.isEmpty()){
            // Build a Dynamic Query String.
            String soqlQuery = ' SELECT ' + String.join (lstFieldsToQuery, ',') + ' FROM ' + strObjectName + ' Where Id =: recordId';
            // Need to return a generic list of sObject because we don't necessarily know exactly what the object is.
            records = Database.query(soqlQuery);
            ilib_LogEvent.info('Query : '+soqlQuery);
        }       
        ilib_LogEvent.pop();
        return records;
    }
    /**
     * method name: getAllFields
     * Description: This method is to retrive thefields based on the Id.
     * params:recordId.
     * return: list of fields
     **/
    public static List<String> getAllFields(Id recId){
        ilib_LogEvent.push(LOG_TITLE + '.getAllFields()');
        DescribeSObjectResult describeResult = recId.getSObjectType().getDescribe();      
        Map<String, Schema.SObjectField> fieldMap = describeResult.fields.getMap();
        // Get all of the fields on the object
        Set<String> fieldNames = fieldMap.keySet();
        ilib_LogEvent.pop();
        return new List<String>(fieldNames);
        
    }
    /**
     * method name: fetchDuplicates
     * Description: This method will be called from LWC component to find the duplicates record for a record where the component is placed on.
     * params:recordId
     * return: Response
     **/
    @AuraEnabled
    public static Response fetchDuplicates(Id recordId){
        ilib_LogEvent.setTitle(LOG_TITLE, ilib_LogEvent.MARKETING);
        ilib_LogEvent.push(LOG_TITLE + '.fetchDuplicates()');
        ilib_LogEvent.info('recordId : '+recordId);
        try{
            //wrapper to store the list of duplicates along with scenario's
            Response response = new Response();
            //scenario Id for source record
            //map of duplicate record Id's and respective scenario Id's
            Map<Id, String> mapDuplicateRules = new Map<Id, String>();
            //list of fields for the source object.
            List<String> lstFields = getAllFields(recordId);
            //source object values
            List<sObject> lstsObject = dynamicSOQL(recordId, lstFields);
            if(lstsObject != null && !lstsObject.isEmpty()){
                //call the dupeblocker class to find the matches
                List<CRMfusionDBR101.DB_Api.Matches> matchSets = CRMfusionDBR101.DB_Api.findMatches(lstsObject[0]);
                mapDuplicateRules = returnDuplicateRecords(matchSets, recordId);
            }
            if(!mapDuplicateRules.isEmpty()){
                populateResponse(mapDuplicateRules, response);
            }
            response.objectName = getObjectLabel(recordId);
            //return the response.
            ilib_LogEvent.info('Response : '+response);
            ilib_LogEvent.pop(); 
            ilib_LogEvent.emit(); 
            return response; 
        }catch(Exception e){
            //if any error capture that using apex exceptions class and throw the error to display it on UI.
            ilib_LogEvent.error('Exception Message : '+e.getMessage());
            ilib_LogEvent.pop(); 
            ilib_LogEvent.emit(); 
            ApexExceptions.emit('FindDuplicateRecordsController',recordId,e, ilib_LogEvent.MARKETING);
            throw new AuraHandledException(e.getMessage());
        }  
    }
	
    /**
     * method name: createDuplicateWarnings
     * Description: This method will be called from LWC component on merge button to create a warning record which will be used further in merging the duplicates.
     * params:recordId, Map<duplicates record Id, scenario Id> , scenario type 
     * return: warning Id
     **/
    @AuraEnabled
    public static Id createDuplicateWarnings(String recordId, Map<String, Object> mapDuplicates, String scenarioType){
        ilib_LogEvent.setTitle(LOG_TITLE, ilib_LogEvent.MARKETING);
        ilib_LogEvent.push(LOG_TITLE + '.createDuplicateWarnings()');
        ilib_LogEvent.info('Id Received : '+recordId);
        try{
            
            //create duplicate warning 
            CRMfusionDBR101__Duplicate_Warning__c warning = new CRMfusionDBR101__Duplicate_Warning__c();
            warning.CRMfusionDBR101__Scenario__c = (Id)mapDuplicates.values()[0];
            warning.CRMfusionDBR101__Scenario_Type__c = scenarioType;//contact,lead etc
            insert warning;
			String scenarioKey = generateUniqueString(9);
            //potential duplicate records
            List<CRMfusionDBR101__Potential_Duplicate__c> lstDuplicates = new List<CRMfusionDBR101__Potential_Duplicate__c>();
            //create potential dulicates
            for(Id recId : mapDuplicates.keySet()){
                CRMfusionDBR101__Potential_Duplicate__c duplicateRec = new CRMfusionDBR101__Potential_Duplicate__c();
                duplicateRec.CRMfusionDBR101__Duplicate_Warning__c = warning.Id;
                duplicateRec.CRMfusionDBR101__Scenario__c = (Id)mapDuplicates.get(recId);
                duplicateRec.CRMfusionDBR101__Key__c = scenarioKey;
                if(scenarioType == STRING_CONTACT_OBJECT){
                    duplicateRec.CRMfusionDBR101__Contact__c = recId;
                }else{
                    duplicateRec.CRMfusionDBR101__Lead__c  = recId;
                }
                 
                duplicateRec.CRMfusionDBR101__Scenario_Type__c = scenarioType; //account,contact,lead,Lead to Contact, Lead to Account
                duplicateRec.CRMfusionDBR101__WarningId_ObjectId__c = warning.Id+''+recId;//warning id+ duplicate record id;
                lstDuplicates.add(duplicateRec);
            }
            if(!lstDuplicates.isEmpty()){
                ilib_LogEvent.info('lstDuplicates Inserted : '+lstDuplicates);
                insert lstDuplicates;
            }
            ilib_LogEvent.pop();
            ilib_LogEvent.emit();
            return warning.Id;
        }catch(Exception e){
            //if any error capture that using apex exceptions class and throw the error to display it on UI.
            ilib_LogEvent.pop();
            ilib_LogEvent.emit();
            ApexExceptions.emit('FindDuplicateRecordsController',recordId,e);
            throw new AuraHandledException(e.getMessage());
        }   
    }
    /**
     * method name: getObjectLabel
     * Description: This method will return object label based on the record Id.
     * params:recordId
     * return: object label
     **/
    public static String getObjectLabel(Id idRec){
        Schema.sObjectType sObjType = idRec.getSObjectType();
        Schema.DescribeSObjectResult sObjDescribeResult = sObjType.getDescribe();
        return sObjDescribeResult.getLabel();
    }
    /**
     * method name: generateUniqueString
     * Description: This method will return unique string based on the length.
     * params:Integer length
     * return: String
     **/
    public static String generateUniqueString(Integer len) {
        ilib_LogEvent.push(LOG_TITLE +'.generateUniqueString()');
        String randStr = '';
        while (randStr.length() < len) {
           Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), CHARS.length());
           randStr += CHARS.substring(idx, idx+1);
        }
        ilib_LogEvent.info('Returning random string : '+randStr);
        ilib_LogEvent.pop();
        return randStr; 
    }
    /**
     * class name: Response
     * Description: This wrapper class would be used to store list of duplicates , map of duplicates and scenario's along with the object label.
     **/
    public class Response{
        //list of duplicates
        @AuraEnabled public List<Id> lstDuplicateRecords;
        //map of duplicates along with scenarios
        @AuraEnabled public Map<Id, String> mapDuplicatesRules;
        //object label
        @AuraEnabled public String objectName;
    }
    /**
     * method name: sendEmailMergeRequest
     * Description: This method will be sending an email to Data Stewards for requesting them to merge contact duplicate records.
     * params:recordId,comment 
     * return: Boolean
     **/
    @AuraEnabled
    public static Boolean sendEmailMergeRequest(String recordId,String comment){
        ilib_LogEvent.setTitle(LOG_TITLE, ilib_LogEvent.MARKETING);
        ilib_LogEvent.push(LOG_TITLE + '.sendEmailMergeRequest()');
        ilib_LogEvent.info('Record Id Received : '+recordId);
        //Email template to be sent
        Id usr = Userinfo.getUserId();
        String strObjectName = Id.valueOf(recordId).getSObjectType().getDescribe().getName();
        Contact con = new Contact();
        Lead objLead = new Lead();
        String countryName;
        String region;
        List<String> lstTemplateName = new List<String>();
		if(strObjectName == STRING_CONTACT_OBJECT){
            //fetch accounts country
            con = new ContactsSelector().returnAccountBillingCountry(recordId);
            countryName = con.Account.BillingCountry;
        }else if(strObjectName == STRING_LEAD_OBJECT){
            List<Lead> lstLeads= new LeadsSelector().returnAutoConvertMergeCheckbox(new List<Id>{recordId});
            objLead = lstLeads[0];
            countryName = objLead.Country;
        } 
        //fetch contact region
        CountryRegionMapping__mdt countryRegionMap =[SELECT Region__c from CountryRegionMapping__mdt WHERE CountryName__c = :CountryName ];
        if(strObjectName == STRING_CONTACT_OBJECT){
            region = DATA_STEWARD_REGIONAL_DL + countryRegionMap.Region__c;
            lstTemplateName.add(CONTACT_MERGE_REQUEST_TEMPLATE);
        }else if(strObjectName == STRING_LEAD_OBJECT){
            region = FUNNEL_MARKETING_REGIONAL_DL + countryRegionMap.Region__c;
            lstTemplateName.add(LEAD_MERGE_REQUEST_TEMPLATE);
        }
        ilib_LogEvent.info('lstTemplateName : '+lstTemplateName);
        
        //fetch email associated with respective contact region
        Code_Parameter__mdt emailAdd = [SELECT Value__c from Code_Parameter__mdt WHERE DeveloperName = :Region ];

        List<EmailTemplate> et = new EmailTemplatesSelector().selectByNameOrDeveloperName(lstTemplateName);

        //list of to addresses to whom we send the mails.
         List<String> toAddress = new List<String>{emailAdd.Value__c};
        
        //send email using singleemailmessage method
        Messaging.SingleEmailMessage mail = Messaging.renderStoredEmailTemplate(et[0].Id,usr, recordId);
        
        //set the recipient
        mail.setToAddresses(toAddress);

        //getHtmlBody
        String body = mail.getHtmlBody();
		//INC0296294 
		String plainTextBody = mail.getPlainTextBody();
        
        body = updateEmailBody(body,comment,strObjectName,con,objLead);
        plainTextBody = updateEmailBody(plainTextBody,comment,strObjectName,con,objLead);
        
        mail.setHtmlBody(body);
		mail.setPlainTextBody(plainTextBody);
        mail.setSaveAsActivity(false);
        //send the mail

        List<Messaging.SingleEmailMessage> allmsg = new List<Messaging.SingleEmailMessage>();
        allmsg.add(mail);

        try {

            Messaging.sendEmail(allmsg);
            ilib_LogEvent.info('Message Sent');
            ilib_LogEvent.pop();
            ilib_LogEvent.emit();
            return true;
        }catch (Exception e) {
            ilib_LogEvent.error('Exception : '+e.getMessage());
            ilib_LogEvent.pop();
            ilib_LogEvent.emit();
            throw new AuraHandledException(e.getMessage());
        }
    }
    /**
     * method name: returnDuplicateRecords
     * Description: This method will return duplicate matches based on the dupeblocker API.
     * params:recordId & list of match sets.
     * return: map of duplicates
     **/
    public static Map<Id, String> returnDuplicateRecords(List<CRMfusionDBR101.DB_Api.Matches> matchSets, Id recordId){
        ilib_LogEvent.push(LOG_TITLE + '.returnDuplicateRecords()');
        String strObjectName = recordId.getSObjectType().getDescribe().getName();
        //map of duplicate record Id's and respective scenario Id's
        Map<Id, String> mapDuplicateRules = new Map<Id, String>();
        Map<Id, CRMfusionDBR101__scenario__c> mapDuplicateScenarios = new Map<Id, CRMfusionDBR101__scenario__c>(new DupeblockerScenariosSelector().selectDupeBlockerScenariosByType(STRING_CONTACT_OBJECT));
        for(CRMfusionDBR101.DB_Api.Matches matchSet : matchSets){
            if(strObjectName == STRING_CONTACT_OBJECT){
                if(mapDuplicateScenarios.containsKey(matchSet.scenarioId)){
                    for(Id recId : matchSet.matchedIds ){
                        //populate mapduplicaterules
                        mapDuplicateRules.put(recId, matchSet.scenarioId);
                    }
                }
            }else{
                for(Id recId : matchSet.matchedIds ){
                    //populate mapduplicaterules
                    mapDuplicateRules.put(recId, matchSet.scenarioId);
                }
            }
        }
        ilib_LogEvent.info('mapDuplicateRules : '+mapDuplicateRules);
        ilib_LogEvent.pop();
        return mapDuplicateRules;
    }
    /**
     * method name: getLeadMergeAccess
     * Description: This method will return if a user has lead merge access permission set.
     * params:NA
     * return: Boolean
     **/
    @AuraEnabled(cacheable = true)
    public static Boolean isMergeAccessGranted(string permissionSetName){
        ilib_LogEvent.setTitle(LOG_TITLE, ilib_LogEvent.MARKETING);
        ilib_LogEvent.push(LOG_TITLE + '.isMergeAccessGranted()');
        ilib_LogEvent.info('permissionSetName : '+permissionSetName);
        try{
            Boolean hasLeadMergeAccess = false;
			if(!Schema.SObjectType.PermissionSetAssignment.isAccessible())
            {
                ilib_LogEvent.info('Returning : '+hasLeadMergeAccess);
                ilib_LogEvent.pop();
                ilib_LogEvent.emit();
                return hasLeadMergeAccess; //DCP-53839
            }
            List<PermissionSetAssignment > lstPermissionSets  = new PermissionSetAssignmentsSelector().selectPermissionSetAssigmentByName(permissionSetName);
            if(!lstPermissionSets.isEmpty()){
                hasLeadMergeAccess = true;
            }
            ilib_LogEvent.info('Returning : '+hasLeadMergeAccess);
            ilib_LogEvent.pop();
            ilib_LogEvent.emit();
            return hasLeadMergeAccess;
        }catch(Exception e){
            ilib_LogEvent.pop();
            ilib_LogEvent.emit();
            throw new AuraHandledException(e.getMessage());
        }
        
    }

    /**
    * method name: getAutoActionMessageDetails
    * Description: This method is used to get Meesage details for Auto Actions.
    * params:LeadId - lead Id.
    * return: string
    **/
    @AuraEnabled(cacheable = true)
    public static string getAutoActionMessageDetails(Id leadId){
        ilib_LogEvent.setTitle(LOG_TITLE, ilib_LogEvent.MARKETING);
        ilib_LogEvent.push(LOG_TITLE + '.getAutoActionMessageDetails()');
        ilib_LogEvent.info('Lead Id Received : '+leadId);
        List<Lead> lstLead = new LeadsSelector().returnAutoConvertMergeCheckbox(new list<Id>{leadId});
        try{
            if(!lstLead.isEmpty() && lstLead[0].createdDate.addSeconds(30) >= datetime.now() ){
                if(lstLead[0].Is_AutoConversion_In_Progress__c){
                    ilib_LogEvent.pop();
                    ilib_LogEvent.emit();
                    return System.Label.LeadConvertionInProgress ;
                }else if(lstLead[0].Is_AutoMerge_In_Progress__c){
                    ilib_LogEvent.pop();
                    ilib_LogEvent.emit();
                    return System.Label.LeadMergeInProgress ;
                }
            }
            ilib_LogEvent.pop();
            ilib_LogEvent.emit();
            return null;
        }catch(Exception e){
            ilib_LogEvent.pop();
            ilib_LogEvent.emit();
            throw new AuraHandledException(e.getMessage());
        }
    }
    /**
     * method name: convertLead
     * Description: This method will be called from LWC for converting a lead to selected contact.
     * params:NA
     * return: Boolean
     **/
    @AuraEnabled
    public static Boolean convertLead(String leadId, String contactId){
        ilib_LogEvent.setTitle(LOG_TITLE, ilib_LogEvent.MARKETING);
        ilib_LogEvent.push(LOG_TITLE + '.covertLead()');
        try{
            ilib_LogEvent.emit();
            return new FindDuplicatesInnerClass().convertLeads(leadId, contactId);
        }catch(Exception e){
            ilib_LogEvent.error('Exception Occurred : '+e.getMessage());
            ilib_LogEvent.pop();
            ilib_LogEvent.emit();
            throw new AuraHandledException(e.getMessage());
        }
    }
    /**
     * method name: populateResponse
     * Description: This method will be called to populate the response wrapper.
     * params:Map of Id,lead and response
     * return: Response
     **/
    public static Response populateResponse(Map<Id, String> mapDuplicateRules,Response response){
        ilib_LogEvent.push(LOG_TITLE + '.populateResponse()');
        List<Id> leadIds = new List<Id>();
        List<Id> lstDuplicateIds = new List<Id>();
        for(Id recId : mapDuplicateRules.keySet()){
            if(getObjectLabel(recId) == STRING_LEAD_OBJECT){
                leadIds.add(recId);
            }else{
                lstDuplicateIds.add(recId);
            }
        }
        ilib_LogEvent.info('leadIds : '+leadIds);
        ilib_LogEvent.info('lstDuplicateIds : '+lstDuplicateIds);
        if(!leadIds.isEmpty()){
            Map<Id, Lead> nonConvertedLeads = new Map<Id, Lead>(new LeadsSelector().returnNonConvertedLeads(leadIds));
            lstDuplicateIds.addAll(nonConvertedLeads.keySet());
        }
        response.lstDuplicateRecords = new List<Id>(lstDuplicateIds);
        response.mapDuplicatesRules = mapDuplicateRules;
        ilib_LogEvent.info('Returning Response : '+response);
        ilib_LogEvent.pop();
        return response;
    }
    /**
     * Class : FindDuplicatesInnerClass
     * Description: This is an inner class which will be executed in with out sharing mode for avoiding access related issues.
     **/
    public without sharing class FindDuplicatesInnerClass{
        /**
        * method name: convertLead
        * Description: This method will be called for converting a lead to selected contact.
        * params:NA
        * return: Boolean
        **/
        public Boolean convertLeads(String leadId, String contactId){
            ilib_LogEvent.push(LOG_TITLE + '.convertLeads()');
            ilib_LogEvent.info('leadId : '+leadId);
            //get the ownerId for the lead Id
            List<Lead> lstLeads= new LeadsSelector().returnAutoConvertMergeCheckbox(new List<Id>{leadId});
            if(!lstLeads.isEmpty() && String.valueOf(lstLeads[0].OwnerId).substring(0,3) != '005'){
                //update the lead's owner to current user
                Lead objLead = new Lead(Id = leadId);
                objLead.OwnerId = UserInfo.getUserId();
                update objLead;
                ilib_LogEvent.info('Lead Updated');
            }
            
            Contact con = new ContactsSelector().returnAccountBillingCountry(contactId);
            Database.LeadConvert lc = new Database.LeadConvert();
            lc.setLeadId(leadId);
            lc.setAccountId(con.AccountId);
            lc.setContactId(contactId);
            lc.setConvertedStatus(STRING_CONVERTED_LEAD_STATUS);//Qualified
            lc.setDoNotCreateOpportunity(true);
            Database.convertLead(lc);
            ilib_LogEvent.info('Lead Converted : '+'Returning True');
            ilib_LogEvent.pop();
            return true;
        }
    }
	/**
     * method name: updateEmailBody
     * Description: INC0296294-This method is to replace the static content of template with values.
     * params:body,comment,strObjectName,con,objLead
     * return: body
     **/
    public static String updateEmailBody(String body,String comment,String strObjectName,Contact con,Lead objLead){
        ilib_LogEvent.push(LOG_TITLE + '.updateEmailBody()');
        body = body.replace('COMMENTS_FROM _USER', comment);
        if(strObjectName == STRING_CONTACT_OBJECT){
            body = con.FirstNameLocal!= NULL ? body.replace('ContactFirstNameLocal', con.FirstNameLocal) : body.replace('ContactFirstNameLocal','');
            body = con.LastNameLocal!= NULL ? body.replace('ContactLastNameLocal', con.LastNameLocal): body.replace('ContactLastNameLocal','');
        }else if(strObjectName == STRING_LEAD_OBJECT){
            body = objLead.FirstNameLocal!= NULL ? body.replace(LEADFIRSTNAMELOCAL, objLead.FirstNameLocal) : body.replace(LEADFIRSTNAMELOCAL,'');
            body = objLead.LastNameLocal!= NULL ? body.replace(LEADLASTNAMELOCAL, objLead.LastNameLocal): body.replace(LEADLASTNAMELOCAL,'');
        }
        ilib_LogEvent.info('Returning body : '+body);
        ilib_LogEvent.pop();
        return body;
    }
}
