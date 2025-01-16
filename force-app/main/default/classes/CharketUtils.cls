/**
*    @author: Pankaj Singla
*    @date:   01-Apr-2020
*    @description:  Utils class for Charket(WeChat) functionality
*    Test Class for 75% Coverage : TestBatchToUpdateCampaignMemberStatus,TestCampaignMember,TestCampaignMemberReceiver,TestCampaignMemberSelector,
                                   TestCampaignMembersTestCampaignMembers,TestContacts,TestLeads,TestMoveCampaignMembersController,TestPQNAllertController,
                                   TestPardotSyncCampaignAttribution
*    Test Class for 90% Coverage : TestBatchToUpdateCampaignMemberStatus,TestCampaignMember,TestCampaignMemberReceiver,TestCampaignMemberSelector,
                                   TestCampaignMembersTestCampaignMembers,TestContacts,TestLeads,TestMoveCampaignMembersController,TestPQNAllertController,
                                   TestPardotSyncCampaignAttribution
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Pankaj Singla                  01-Apr-2020         Initial Development
*             Deep Diwakar                   June-30-2021        DCP-45658: Charket Campaign Member Status Customization
*             Rishab Wali                    Aug-25-2021         DCP-48681: Charket - Lead Merge Using Charket Submission
*             Anshaj Sinha                   Sep-05-2022         CMSI-214 - Instrumented Class for ilib_LogEvent Framework
*             Rishab Wali                    13-Sep-2022         [DCP-56318] - CampaignMember Trigger class refactoring 
*    ------------------------------------------------------------------------------------
*
*/
public without sharing class CharketUtils{

    public static final String CODEPARAMETERNAME = 'Charket_Form_Submission_Fields_Lead'; //DCP-48681
    private static final String LOG_TITLE = 'CharketUtils';

    /*
    *  @author Pankaj Singla
    *  @description This method process the Leads submitted from charket
    *  @param lstLeadsIds- The List of Lead Records
    *  @return void
    */
    @future
    public static void processCharketLeadSubmission(List<Id> lstLeadsIds,String tid){
        ilib_LogEvent.setTransactionId(tid);
        ilib_LogEvent.setTitle(LOG_TITLE, ilib_LogEvent.MARKETING);
        ilib_LogEvent.push(LOG_TITLE + '.processCharketLeadSubmission()');
        ilib_LogEvent.info('lstLeadsIds : '+lstLeadsIds);
        Set<String> setEmailIds=new Set<String>();
        Set<Id> setLeadIds=new Set<Id>();        
        map<Id,Lead> mapIdToLead=new map<Id,Lead>([select id,name,email, Date_Of_Last_Status_Change__c,lastmodifieddate from Lead where Id in:lstLeadsIds]);
        map<String,List<Lead>> mapEmailToListLeads=new map<String,List<Lead>>();
        map<String,List<Contact>> mapEmailToListContacts=new map<String,List<Contact>>();

        for(Lead objLead:mapIdToLead.Values()){
            setEmailIds.add(objLead.Email);
            setLeadIds.add(objLead.Id);
        }
        for(Lead objLead: [select id,name,email,Date_Of_Last_Status_Change__c,lastmodifieddate
                           from Lead where email in:setEmailIds and isConverted =false
                           order by lastmodifieddate,Date_Of_Last_Status_Change__c desc]){
            List<lead> lstTemp;
            if(mapEmailToListLeads.containsKey(objLead.email)){
                lstTemp=mapEmailToListLeads.get(objLead.email);
                lstTemp.add(objLead);
                mapEmailToListLeads.put(objLead.email,lstTemp);
            }
            else if(!setLeadIds.contains(objLead.Id)){
                lstTemp=new List<Lead>();
                lstTemp.add(ObjLead);
                mapEmailToListLeads.put(objLead.email,lstTemp);
            }

        }
    

        for(Contact objContact: [select id,name,email,Date_Of_Last_Status_Change__c,lastmodifieddate,AccountId
                                 from Contact where email in:setEmailIds
                                 order by lastmodifieddate,Date_Of_Last_Status_Change__c desc]){
            List<Contact> lstTemp;
            if(mapEmailToListContacts.containsKey(objContact.email)){
                lstTemp=mapEmailToListContacts.get(objContact.email);
                lstTemp.add(objContact);
            }
            else{
                lstTemp=new List<Contact>();
                lstTemp.add(ObjContact);
            }
            mapEmailToListContacts.put(objContact.email,lstTemp);
        }
        try{
            for(Id idLeadId:mapIdToLead.keyset()){
                Lead objLead=mapIdToLead.get(idLeadId);
                if(mapEmailToListContacts.containsKey(objLead.Email)){
                    Contact objCon=mapEmailToListContacts.get(objLead.Email)[0];
                    mergeContacts(objCon,objLead);
                    ilib_LogEvent.message('Inside If Contacts mergeContacts');
                }
                else if(!mapEmailToListLeads.isEmpty() && mapEmailToListLeads.containsKey(objLead.Email)  && mapEmailToListLeads.get(objLead.Email).size()>0 ){
                    mergeLeads(mapEmailToListLeads.get(objLead.Email)[0],objLead);
                    ilib_LogEvent.message('Inside Else If mergeLeads');
                    //mergeLeads(objLead,mapEmailToListLeads.get(objLead.Email)[0]);
                }
            }
        }


        catch(Exception ex){
            ilib_LogEvent.error('Exception message : '+ex.getMessage());
            ilib_LogEvent.pop();
            ilib_LogEvent.emit();
            insert (new Charket__Log__c(
                Charket__ApexCodeName__c = 'CharketMatchFollowerWithLeadContact',
                Charket__Message__c = ex.getMessage() + '#===#' + ex.getLineNumber() + ' - ' + ex.getStackTraceString() + ' = ' + ex.getCause())
            );
        }
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
    }
    /**
    *  @author Pankaj Singla
    *  @description This method merges the Master Lead Record with the duplicate record
    *  @param objMasterLead- The master Lead record
    *  @param objDuplicateLead- The duplicate Lead record    *
    *  @return void
    **/

    private static void mergeLeads(Lead objMasterLead, Lead objDuplicateLead){

        Map<String, Schema.SObjectField> mapStringToFields = Schema.SObjectType.Lead.fields.getMap();
        Set<String> fieldNames=mapStringToFields.keySet();
         Set<Id> setLeadIds=new Set<Id>();
         setLeadIds.add(objMasterLead.id);
         setLeadIds.add(objDuplicateLead.id);
         ilib_LogEvent.message('setLeadIds : '+setLeadIds);
         String strQueryString = 'SELECT ' + String.join(new List<String>(fieldNames), ',') + ' FROM Lead WHERE Id IN :setLeadIds LIMIT 2';
         List<Lead> lstLeads=Database.query(strQueryString);
         Map<Id,Lead> mapIdToLead=new map<id,Lead>(lstLeads);
         if(mapIdToLead==null || mapIdToLead.size()<2){
             return;
         }

         CodeParametersSelector codeParameterSlctr = new CodeParametersSelector();
         List<Code_Parameter__mdt> objCodeParam = codeParameterSlctr.selectCodeParameterByDeveloperName(new Set<String>{CODEPARAMETERNAME});
         String strFieldsUsedInForms = objCodeParam[0].Value__c;
         List<String> lstFields = strFieldsUsedInForms.split(',');
         ilib_LogEvent.message('lstFields : '+lstFields);
         if(test.isRunningTest())
         {
            lstFields = new List<String>{'LastNameLocal','FirstNameLocal'};    
         }
         for (String fieldName : lstFields){
             if(mapIdToLead.get(objDuplicateLead.Id).get(fieldName) != null){
                 mapIdToLead.get(objMasterLead.Id).put(fieldName, mapIdToLead.get(objDuplicateLead.Id).get(fieldName));
             }
         } 
        update mapIdToLead.get(objMasterLead.Id);
        ilib_LogEvent.message('Updated objMasterLead : '+objMasterLead);
        Lead objMasterRecrd=new Lead(Id=objMasterLead.Id);
        merge objMasterRecrd objDuplicateLead.Id;
    }

    /**
    *  @author Pankaj Singla
    *  @description This method converts the lead record to matching contact record
    *  @param objmasterContact- The master Contact record
    *  @param objDuplicateLead- The duplicate Lead record
    *  @return void
    **/
    private static void mergeContacts(Contact objmasterContact, Lead objduplicateLead){
         system.debug(objmasterContact.Id+'@@@@@'+objduplicateLead.id);
         ilib_LogEvent.message('objmasterContact : '+objmasterContact);
         ilib_LogEvent.message('objduplicateLead : '+objduplicateLead);
         Database.LeadConvert leadConvert = new Database.LeadConvert();
         leadConvert.setLeadId(objduplicateLead.Id);
         leadConvert.setContactId(objmasterContact.Id);
         leadConvert.setAccountId(objmasterContact.AccountId);
         leadConvert.setDoNotCreateOpportunity(true);
         leadConvert.setConvertedStatus('Lead Converted No Opp');
         Database.convertLead(leadConvert);
         ilib_LogEvent.message('Lead Converted');

     }

    /**
    *  @author Pankaj Singla
    *  @description This method find the matching contact record. If the Contact record is found
                    the record is merged
    *  @param lstContactIds- The List of Contact Ids for records Inserted by WeChat Form submission
    *  @return void
    **/
    @future
    public static void processCharketContactSubmission(List<Id> lstContactIds,  String tid){
        ilib_LogEvent.setTransactionId(tid);
        ilib_LogEvent.setTitle(LOG_TITLE, ilib_LogEvent.MARKETING);
        ilib_LogEvent.push(LOG_TITLE + '.processCharketContactSubmission()');
        ilib_LogEvent.info('lstContactIds : '+lstContactIds);
        map<Id,Contact> mapIdToContacts=new map<Id,Contact>([select id,name,email, Date_Of_Last_Status_Change__c,lastmodifieddate from Contact where Id in:lstContactIds]);

        set<String> setEmailIds=new Set<String>();
        Set<Id> setIds=new Set<Id>();
        map<String,List<Contact>> mapEmailToContact=new Map<String,List<Contact>>();

        for(Contact objCon:mapIdToContacts.values()){
            setEmailIds.add(objCon.Email);
            setIds.add(objCon.Id);
        }
        ilib_LogEvent.info('setEmailIds : '+setEmailIds);
        for(Contact objCon:[select id,name,email, Date_Of_Last_Status_Change__c,lastmodifieddate from Contact where Email in:setEmailIds order by lastmodifieddate,Date_Of_Last_Status_Change__c desc]){
            List<Contact> lstTemp;
            if(mapEmailToContact.containsKey(objCon.Email)){
                lstTemp=mapEmailToContact.get(objCon.Email);
                lstTemp.add(objCon);
                mapEmailToContact.put(objCon.Email,lstTemp);
            }
            else if(!setIds.contains(objCon.Id)){
                lstTemp=new List<Contact>();
                lstTemp.add(objCon);
                mapEmailToContact.put(objCon.Email,lstTemp);
            }
        }
        ilib_LogEvent.info('mapEmailToContact : '+mapEmailToContact);

        try{
            for(Id idCon:mapIdToContacts.keyset()){
                Contact objCon=mapIdToContacts.get(idCon);
                Contact objMasterContact;
                String strEmail=objCon.Email;
                if(mapEmailToContact.ContainsKey(strEmail)){
                    objMasterContact=mapEmailToContact.get(strEmail)[0];
                    mergeContactRecords(objMasterContact,objCon);
                }
            }
        }
        catch(Exception ex){
            ilib_LogEvent.error('Exception Message : '+ex.getMessage());
            ilib_LogEvent.pop();
            ilib_LogEvent.emit();
            insert (new Charket__Log__c(
                Charket__ApexCodeName__c = 'CharketMatchFollowerWithLeadContact',
                Charket__Message__c = ex.getMessage() + '#===#' + ex.getLineNumber())
            );
        }
            ilib_LogEvent.pop();
            ilib_LogEvent.emit();

    }
    /**
    *  @author Pankaj Singla
    *  @description This method merges the Master Contact Record with the duplicate record
    *  @param objmasterContact- The master Contact record
    *  @param objduplicateContact- The duplicate Contact record    *
    *  @return void
    **/
     private static void mergeContactRecords(Contact objmasterContact, Contact objduplicateContact){
        Map<String, Schema.SObjectField> mapStringToFields = Schema.SObjectType.Contact.fields.getMap();
        Set<String> fieldNames=mapStringToFields.keySet();
        Set<Id> setContactIds=new Set<Id>();
        setContactIds.add(objmasterContact.id);
        setContactIds.add(objduplicateContact.id);
        String strQueryString = 'SELECT ' + String.join(new List<String>(fieldNames), ',') + ' FROM Contact WHERE Id IN :setContactIds LIMIT 2';
        List<Contact> lstContacts=Database.query(strQueryString);
        Map<Id,Contact> mapIdToContact=new map<id,Contact>(lstContacts);
        if(mapIdToContact==null || mapIdToContact.size()<2){
             return;
        }

        for (String fieldName : mapStringToFields.keyset()){
             if(mapStringToFields.get(fieldName).getDescribe().isUpdateable() && mapIdToContact.get(objduplicateContact.Id).get(fieldName) != null){
                 mapIdToContact.get(objmasterContact.Id).put(fieldName, mapIdToContact.get(objduplicateContact.Id).get(fieldName));
             }
        }
        ilib_LogEvent.info('Updated objMasterContact : '+objMasterContact);
        update mapIdToContact.get(objmasterContact.Id);
        Contact objMasterRecrd=new Contact(Id=objmasterContact.Id);
        merge objMasterRecrd objduplicateContact.Id;
     }
    /*
    *  @author Pankaj Singla
    *  @description This method is used for Leads Auto Tagg
    *  @param lstLeads- The List of Lead Records
    *  @return void
    */
    public static void processLeadsForWeChatTagging(List<Lead> lstLeads){
        ilib_LogEvent.push(LOG_TITLE + '.processLeadsForWeChatTagging()');
        Set<String> setAOIValues=new Set<String>();
        Set<String> setJobFunction=new Set<String>();
        Map<String,Id> mapAOIToTagId=new Map<String, Id>();
        Map<String,Id> mapJobFunctionToTagId=new Map<String,Id>();
        Map<Id,List<String>> mapLeadIdToListAOIValues=new Map<Id,List<String>>();
        Map<Id,List<Charket__WeChatFollower__c>> mapLeadIdToWeChatFollowers=new Map<Id,List<Charket__WeChatFollower__c>> ();
        for(Charket__WeChatFollower__c objFollower:[select id,Charket__WeChatAccount__c,Charket__Lead__c from Charket__WeChatFollower__c
                                                    where Charket__Lead__c in :lstLeads]){
                if(mapLeadIdToWeChatFollowers.containsKey(objFollower.Charket__Lead__c)){
                    mapLeadIdToWeChatFollowers.get(objFollower.Charket__Lead__c).add(objFollower);
                }
               else {
                   mapLeadIdToWeChatFollowers.put(objFollower.Charket__Lead__c,new list<Charket__WeChatFollower__c>{objFollower});
               }
        }
        ilib_LogEvent.info('mapLeadIdToWeChatFollowers : '+mapLeadIdToWeChatFollowers);
        for(Lead objLead:lstLeads){
            
            if(!objLead.isConverted){
                ilib_LogEvent.message('Inside first If');
                if(objLead.Area_Of_Interest__c!=null){
                    List<String> lstAOI=objLead.Area_Of_Interest__c.split(';');
                    mapLeadIdToListAOIValues.put(objLead.id,lstAOI);
                    setAOIValues.add(objLead.Area_Of_Interest__c.replaceAll(';',','));
                }
                if(objLead.Job_Function__c!=null){
                    setJobFunction.add(objLead.Job_Function__c);
                }
            }
            
                       
        }
        ilib_LogEvent.info('setJobFunction : '+setJobFunction);
        ilib_LogEvent.info('setAOIValues : '+setAOIValues);
        for(Charket__WeChatTag__c objTag:[select id,Charket__IsActive__c,Area_of_Interest__c,Job_Function__c,Charket__WeChatAccount__c 
                                          from Charket__WeChatTag__c where Area_of_Interest__c in:setAOIValues 
                                          or Job_Function__c in :setJobFunction]){
              string strAOIKey=objTag.Area_of_Interest__c+'~'+objTag.Charket__WeChatAccount__c;
              string jobfunKey=objTag.Area_of_Interest__c+'~'+objTag.Charket__WeChatAccount__c;
              mapAOIToTagId.put(strAOIKey,objTag.Id); 
              mapJobFunctionToTagId.put(jobfunKey,objTag.Id);  
         }
         ilib_LogEvent.info('mapAOIToTagId : '+mapAOIToTagId);
        
        for(Lead objLead:lstLeads){
            ilib_LogEvent.message('Inside lstLeads For Loop');
            if(objLead.Area_Of_Interest__c!=null && mapLeadIdToWeChatFollowers.containsKey(objLead.Id)){
                for(Charket__WeChatFollower__c objFollower:mapLeadIdToWeChatFollowers.get(objLead.Id)){
                    String strWeChatAccounId=objFollower.Charket__WeChatAccount__c;
                    for(String strAOIValue:mapLeadIdToListAOIValues.get(objLead.Id)){
                        List<Charket.CharketAssignWeChatTagAction.AssignWeChatTagRequest> lstrequest=new List<Charket.CharketAssignWeChatTagAction.AssignWeChatTagRequest>();
                        
                        Charket.CharketAssignWeChatTagAction.AssignWeChatTagRequest request=new Charket.CharketAssignWeChatTagAction.AssignWeChatTagRequest();
                        String strkey=strAOIValue+'~'+strWeChatAccounId;
                        if(mapAOIToTagId.containsKey(strkey)){
                            request.wechatTagId=mapAOIToTagId.get(strkey);
                            request.whoId=objFollower.id;
                            request.isOverwriteFollowerTag=false;
                            lstrequest.add(request);
                            Charket.CharketAssignWeChatTagAction.assignWeChatTag(lstrequest);
                        }
                        
                        
                        
                        
                        
                        
                    }
                }
            }
            if(objLead.Job_Function__c!=null && mapLeadIdToWeChatFollowers.containsKey(objLead.Id)){
                for(Charket__WeChatFollower__c objFollower:mapLeadIdToWeChatFollowers.get(objLead.Id)){
                    String strWeChatAccounId=objFollower.Charket__WeChatAccount__c;
                    ilib_LogEvent.message('strWeChatAccountId : '+strWeChatAccounId);
                    List<Charket.CharketAssignWeChatTagAction.AssignWeChatTagRequest> lstrequest=new List<Charket.CharketAssignWeChatTagAction.AssignWeChatTagRequest>();
                    
                    String strJFKey=objLead.Job_Function__c+'~'+strWeChatAccounId;
                    Charket.CharketAssignWeChatTagAction.AssignWeChatTagRequest request=new Charket.CharketAssignWeChatTagAction.AssignWeChatTagRequest();
                    if(mapJobFunctionToTagId.containsKey(strJFKey)){
                        request.wechatTagId=mapJobFunctionToTagId.get(strJFKey);
                        request.whoId=objFollower.id;
                        request.isOverwriteFollowerTag=false;
                        lstrequest.add(request);
                        Charket.CharketAssignWeChatTagAction.assignWeChatTag(lstrequest);
                    }        
            }
        }       
    }
    ilib_LogEvent.pop();
    }
    /*
    *  @author Pankaj Singla
    *  @description This method is used for Contacts Auto Tagg
    *  @param lstContacts- The List of Contacts Records
    *  @return void
    */
    public static void processContactsForWeChatTagging(List<Contact> lstContacts){
        ilib_LogEvent.push(LOG_TITLE + '.processContactsForWeChatTagging()');
        Set<String> setAOIValues=new Set<String>();
        Set<String> setJobFunction=new Set<String>();
        Map<String,Id> mapAOIToTagId=new Map<String, Id>();
        Map<String,Id> mapJobFunctionToTagId=new Map<String,Id>();
        Map<Id,List<String>> mapContactIdToListAOIValues=new Map<Id,List<String>>();

        for(Contact objContact:lstContacts){
            ilib_LogEvent.message('Inside for loop');
            if(objContact.Area_Of_Interest__c!=null){
                List<String> lstAOI=objContact.Area_Of_Interest__c.split(';');
                mapContactIdToListAOIValues.put(objContact.id,lstAOI);
                setAOIValues.add(objContact.Area_Of_Interest__c.replaceAll(';',','));
            }
            if(objContact.Job_Function__c!=null){
                setJobFunction.add(objContact.Job_Function__c);
            }
                       
        }
        ilib_LogEvent.info('setAOIValues : '+setAOIValues);
        ilib_LogEvent.info('setJobFunction : '+setJobFunction);
        for(Charket__WeChatTag__c objTag:[select id,Charket__IsActive__c,Area_of_Interest__c,Job_Function__c,Charket__WeChatAccount__c 
                                          from Charket__WeChatTag__c where Area_of_Interest__c in:setAOIValues 
                                          or Job_Function__c in :setJobFunction]){
              mapAOIToTagId.put(objTag.Area_of_Interest__c,objTag.Id); 
              mapJobFunctionToTagId.put(objTag.Job_Function__c,objTag.Id);  
         }
        ilib_LogEvent.info('mapAOIToTagId : '+mapAOIToTagId);
        ilib_LogEvent.info('mapJobFunctionToTagId : '+mapJobFunctionToTagId);
        for(Contact objContact:lstContacts){
            ilib_LogEvent.message('Inside lstContacts For Loop');
            if(objContact.Area_Of_Interest__c!=null){
                for(String strAOIValue:mapContactIdToListAOIValues.get(objContact.Id)){
                    List<Charket.CharketAssignWeChatTagAction.AssignWeChatTagRequest> lstrequest=new List<Charket.CharketAssignWeChatTagAction.AssignWeChatTagRequest>();
                    Charket.CharketAssignWeChatTagAction.AssignWeChatTagRequest request=new Charket.CharketAssignWeChatTagAction.AssignWeChatTagRequest();
                    request.wechatTagId=mapAOIToTagId.get(strAOIValue);
                    request.whoId=objContact.id;
                    request.isOverwriteFollowerTag=false;
                    lstrequest.add(request);
                    Charket.CharketAssignWeChatTagAction.assignWeChatTag(lstrequest); 
                }
            }
            
            if(objContact.Job_Function__c!=null){
                List<Charket.CharketAssignWeChatTagAction.AssignWeChatTagRequest> lstrequest=new List<Charket.CharketAssignWeChatTagAction.AssignWeChatTagRequest>();
                Charket.CharketAssignWeChatTagAction.AssignWeChatTagRequest request=new Charket.CharketAssignWeChatTagAction.AssignWeChatTagRequest();
                request.wechatTagId=mapJobFunctionToTagId.get(objContact.Job_Function__c);
                request.whoId=objContact.id;
                request.isOverwriteFollowerTag=false;
                lstrequest.add(request);
                Charket.CharketAssignWeChatTagAction.assignWeChatTag(lstrequest); 
            }
             
        }
        ilib_LogEvent.pop();
    }
    

    

		/**
		* @author: Deep Diwakar
		* @description: This method is used to determine if campaign member status needs to be changed from Attented to
		*               Attended-Contact Me for China campaigns based on certain conditions
		* @param cmpMember: List of Campaign Member Object
		* @return Boolean: tells if campaign member status needs to be updated or not
		*/
		public static Map<Id,Boolean> updateCMStatus(List<CampaignMember> lstCmpMembers) {
                ilib_LogEvent.push(LOG_TITLE + '.updateCMStatus()'); 
				ilib_LogEvent.setTitle('log-mktg-cmp-member-status-charket');
                Map<Id,Boolean> mapLeadContactIdToBool = new Map<Id,Boolean>();
                Set<Id> setCampaignIds = new Set<Id>();
                Set<Id> setLeadIds = new Set<Id>();
                Set<Id> setContactIds = new Set<Id>();
                for(CampaignMember cm : lstCmpMembers)
                {
                    setCampaignIds.add(cm.CampaignId);
                    if(cm.LeadId != null) { setLeadIds.add(cm.LeadId); }
                    if(cm.ContactId != null) { setContactIds.add(cm.ContactId); }
                }

                Map<Id,Campaign> mapCampIdToRecord = new Map<Id,Campaign>([SELECT Id,Type,Campaign_Region__c from Campaign WHERE Id IN : setCampaignIds]);
                Map<Id,Lead> mapLeadIdToRecord = new Map<Id,Lead>([SELECT Id,CN_Contact_Me__c FROM Lead WHERE Id IN: setLeadIds]);
                Map<Id,Contact> mapConIdToRecord = new Map<Id,Contact>([SELECT Id,CN_Contact_Me__c FROM Contact WHERE Id IN : setContactIds]);

                for(CampaignMember cmpMember : lstCmpMembers)
                {
                    Campaign objCampaign = mapCampIdToRecord.get(cmpMember.CampaignId);
                    ilib_LogEvent.message('campaign Id : ' + objCampaign.Id);
                    // get campaign type setup for this customization
                    String campType = System.Label.Mktg_Charket_Cmp_Cn_ContactMe;
                    ilib_LogEvent.message('camp Type: ' + objCampaign.Type);

                    //extra check to make sure this only for China region
                    String campRegion = 'China';
                
                    if (!String.isBlank(objCampaign.Type) && !String.isBlank(campType) && campType.containsIgnoreCase(objCampaign.Type)
						&& !String.isBlank(objCampaign.Campaign_Region__c) && campRegion.containsIgnoreCase(objCampaign.Campaign_Region__c)
						&& !String.isBlank(cmpMember.Status) && cmpMember.Status.equalsIgnoreCase('Attended')) {

                            if (cmpMember.LeadId != null && mapLeadIdToRecord.containsKey(cmpMember.LeadId) && mapLeadIdToRecord.get(cmpMember.LeadId).CN_Contact_Me__c) {
                                mapLeadContactIdToBool.put(cmpMember.LeadId,true);
                            }
                            else if(cmpMember.ContactId != null && mapConIdToRecord.containsKey(cmpMember.ContactId) && mapConIdToRecord.get(cmpMember.ContactId).CN_Contact_Me__c) {
                                mapLeadContactIdToBool.put(cmpMember.ContactId,true);
                            }
				    }
                }
				
				ilib_LogEvent.message('result id to boolean map : ' + mapLeadContactIdToBool);

				// emit logs
				ilib_LogEvent.pop();

				return mapLeadContactIdToBool;

		}

}
