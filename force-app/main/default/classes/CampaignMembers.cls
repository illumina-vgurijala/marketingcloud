/**
*    @author: Pankaj
*    @date:   10-Sept-2018
*    @description:  CampaignMember handler
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Pankaj Singla                 15 Oct 2018        Handler class for CampaignMember Trigger
*             Pankaj singla                 20 Jul 2019        Update for Multiple Campaign Scoring
*             Pankaj Singla                 02 Jun 2020        DCP-35844 Updated for Scoring changes. Refactored
*                                                              onAfterUpdate and onAfterInsert Trigger Methods
*             Nishan Shetty                 08 Jun 2021        SPQ-15 Added Note Creation and Updation Logic for Campaign
*                                                              Members Note on AfterInsert and AfterUpdate Trigger Methods.
*             Rishi Sharma                  15 Jun 2021        SPQ-37 Update Last Marketing Campaign on Campaign
*                                                              Members
*             Deep Diwakar                 30 Jun 2021        DCP-45658: Charket Campaign Member Status Customization
*             Deep Diwakar                 10 Sept 2021       DCP-49866: Adding Lead conversion check and some code instrumentation
*             Rishab Wali                  02 Dec 2021        [DCP-49756] : Update Most Recent Activity Date On Leads
*             Preetha                      13-Jun-2022        CMSI-70 Instrumentation for a class
*             Preetha                      08-July-2022       CMSI-51 added WorkStream
*             Rishab                       15-Sep-2022        DCP-56318 Campaign Member Refactor
*             Deep Diwakar                 16 Sept 2022       DCP-57383: Fixing Cvent batch job failure by avoiding queueable calls in Batch conext
*             Atit Kar                     11 Oct 2022        INC0429439 : Commented these methods and their references : populateLastMarketingCampaignBefore(), populateLastMarketingCampaignAfterInsert(), populateLastMarketingCampaignDelete(), populateLastMarketingCampaignAfterInsertSync()
*             Rishab Wali                  10 Nov 2022        DCP-58703 Add Org Ownership Operational to logic
*             Rishab Wali                  11 Jan 2022        DCP-58729 : Media Code Implementation
*             Deep Diwakar                 Mar-23-2023        DCP-59535: Implemented queueable framework to sync media code and campaign attribution values to Pardot
*             Deep Diwakar                 June-07-2023       CMCM-1164: Implementing platform events to sync media code and campaing attributuion value to Pardot 
*             Deep Diwakar                 June-18-2023       CMCM-1160: Added new Campaign_Subregion__c field in scoring logic
*             Deep Diwakar                 Aug-04-2023        DCP-60130: Added CRUD and FLS check bypass for Charket user so we can remove access at profile level
*             Deep Diwakar                 Oct-16-2023        CMCM-1188: Updated to find and set campaign attribution and media code value for Cvent
*             Deep Diwakar                 Aug-08-2024        CMCM-9421: Updated to move form type field from lead/contact to campaign member record
* ---------------------------------------------------------------------------------------------
*
*/
public with sharing class CampaignMembers extends ilib_SObjectDomain {

    /*Campaign types for Cvent, On24 campaigns*/
    public static final String STRING_CAMPAIGN_TYPE_SEMINAR='Seminar';
    public static final String STRING_CAMPAIGN_TYPE_TRADESHOW='Tradeshow';
    public static final String STRING_CAMPAIGN_TYPE_THIRD_PARTY_HOSTED='Third Party Hosted Event';
    public static final String STRING_CAMPAIGN_TYPE_ILLUMINA_HOSTED='Illumina Hosted Event';
    public static final String STRING_CAMPAIGN_TYPE_SALES_EVENT='Sales Event';
    public static final String STRING_CVENT_USER='Integration Cvent';
    public static final String STRING_CAMPAIGN_REGION_APJ='APJ';
    public static final String STRING_CAMPAIGN_REGION_AMEA='AMEA'; // CMCM-1160
    public static final String STRING_CAMPAIGN_DISTRICT_JAPAN='Japan';
    public static final String STRING_CAMPAIGN_DISTRICT_SAPAC='SAPAC';
    public static final String STRING_NULL='NULL';
    public static final String STRING_ACTION='Added to Campaign';
    public static final Set<String> SETCAMPAIGNTYPESCVENT =new Set<String>{STRING_CAMPAIGN_TYPE_TRADESHOW,STRING_CAMPAIGN_TYPE_SEMINAR,STRING_CAMPAIGN_TYPE_SALES_EVENT,STRING_CAMPAIGN_TYPE_THIRD_PARTY_HOSTED,STRING_CAMPAIGN_TYPE_ILLUMINA_HOSTED};
    public static final String STRING_LEADSOURCE_SALES_GENERATED='Sales Generated';
    public static final String STREXECUTE = 'execute';
    public static final String STRMARKETING = 'Marketing';
    public static final String STRSALES = 'Sales';
    private static final String LOG_TITLE = 'CampaignMembers';//CMSI-70
    public static final String MAPISEMPTY = 'map is empty';
    public static final String STRSERVICE = 'Service';
    public static final String STROPERATIONAL = 'Operational';

    private static final String CODE_PARAM_CAMP_TYPE_FOR_FORM_TYPE = 'Mktg_Campaign_Type_For_Form_Type';

	/*Method - Paramterized Constructor*/
    public  CampaignMembers(List<CampaignMember> sObjectList){

        super(sObjectList);

        //DCP-60130: Added CRUD and FLS check bypass for Charket user so we can remove access at profile level
        if (FeatureManagement.checkPermission('Bypass_Person_Object_Permission')) {
            Configuration.disableTriggerCRUDSecurity();
            ilib_SecurityUtils.bypassInternalFlsAndCrud = true;
        }

    }

    /*
    * Boilerplate which is required for base class instantiation logic
    */
    public class Constructor implements ilib_SObjectDomain.IConstructable
    {
		/*Method - Creates sobject for ilibSobjectDomain*/
        public ilib_SObjectDomain construct(List<SObject> sObjectList)
        {
            return new CampaignMembers(sObjectList);
        }
    }

    /*
    * @author Pankaj Singla
    * @date   20-May-2020
    * @description: Before Insert method for Trigger
    * @parameters:None
    * @return : None
    */
     public override void onBeforeInsert(){
         list<CampaignMember> lstCampaignMember=(list<CampaignMember>)records;
         Set<Id> setLeads=new Set<Id>();
         Set<Id> setContacts=new Set<Id>();
         Set<Id> setCampaignIds=new Set<Id>();
         Set<String> setEmailIds=new Set<String>();
         Map<Id,Boolean> mapLdConIdToBoolean = new Map<Id,Boolean>();
         Boolean boolIsCharketUser=UserInfo.getName().equals(Label.Charket_User)?true:false;

         //CMCM-1188: Find campaign attribution and media code value for Cvent user
         Boolean isCventUser=UserInfo.getName().equals(STRING_CVENT_USER)?true:false;
         ilib_LogEvent.info('isCventUser :'+ isCventUser);
         if (isCventUser) {
            CampaignMemberService.runCattMediaLogicForCvent(lstCampaignMember);
         }

         /*Get list of leads and Contacts as members of Campaign*/
         for(CampaignMember objCampaignMember:lstCampaignMember){
            setCampaignIds.add(objCampaignMember.CampaignId);

            if( objCampaignMember.LeadId!=null && !objCampaignMember.Lead.isConverted){
                setLeads.add(objCampaignMember.LeadId);
                ilib_LogEvent.message('Lead added');
            }
            else if(objCampaignMember.ContactId!=null){
                setContacts.add(objCampaignMember.ContactId);
                ilib_LogEvent.message('Contact added');
            }
         }
         //CMSI-70
         ilib_LogEvent.info('setLeads on Before insert:'+setLeads);
         ilib_LogEvent.info('setContacts on Before insert:'+setContacts);
         Map<Id,Lead> mapIdToLead = new Map<Id,Lead>(new LeadsSelector().selectLeadsForCampMemberFields(setLeads));
         Map<Id,Contact> mapIdToContact = new Map<Id,Contact>(new ContactsSelector().selectContactsForCampMemberFields(setContacts));
         Map<Id,Campaign> mapIdToCampaign = new Map<Id,Campaign>(new CampaignSelector().selectCampaigns(setCampaignIds));

         //CMSI-70
         ilib_LogEvent.info('mapIdToLead on before insert: '+(!mapIdToLead.isEmpty()? String.valueOf(mapIdToLead.keySet()):MAPISEMPTY));
         ilib_LogEvent.info('mapIdToContact on before insert: '+(!mapIdToContact.isEmpty()? String.valueOf(mapIdToContact.keySet()):MAPISEMPTY));
         if(boolIsCharketUser || System.Test.isRunningTest()){ mapLdConIdToBoolean = CharketUtils.updateCMStatus(lstCampaignMember); }
         ilib_LogEvent.info('mapLdConIdToBoolean on before insert: '+(!mapLdConIdToBoolean.isEmpty()? String.valueOf(mapLdConIdToBoolean.keySet()):MAPISEMPTY));
         Map<Id,Lead> tempIdToLeadMap = new Map<Id,Lead>();
         Map<Id,Contact> tempIdToContactMap = new Map<Id,Contact>();

         //CMCM-1164: Added for this story
         Map<String, PardotCattrMediaCodeSync__e> emailToPardotEventMap = new Map<String, PardotCattrMediaCodeSync__e>();

         //CMCM-9421: get code parameter for acceptable campaign type value for setting campaign member form type
         List<Code_Parameter__mdt> lstCodeParam = new CodeParametersSelector().selectCodeParameterByDeveloperName(new Set<String>{CODE_PARAM_CAMP_TYPE_FOR_FORM_TYPE});
         List<String> lstCampTypeForFormType = lstCodeParam[0].value__c.split(',');

         ilib_LogEvent.info('lstCampTypeForFormType: ' + lstCampTypeForFormType);

         for(CampaignMember objCampaignMember:lstCampaignMember){

              // DCP-47093: If it's charket user then check for campaign member status change
              if ((boolIsCharketUser || System.Test.isRunningTest()) && ((mapLdConIdToBoolean.containsKey(objCampaignMember.LeadId) && mapLdConIdToBoolean.get(objCampaignMember.LeadId)) || (mapLdConIdToBoolean.containsKey(objCampaignMember.ContactId) && mapLdConIdToBoolean.get(objCampaignMember.ContactId)))) {
                ilib_LogEvent.message('Before Insert Charket: Setting up campaign member customization for status attended to attended contact me');
                objCampaignMember.Status = 'Attended-Contact Me'; //Attended-Contact Me
              }

              // CMCM-1164: Added below 3 variables to collect campaign member email and Cattr and Media Code presence flag
              String cmpMemberEmail = '';
              Boolean isCattrPresent = false;
              Boolean isMediaCodePresent = false;

              Campaign currCampaign = mapIdToCampaign.get(objCampaignMember.CampaignId);
              String campType = currCampaign.Type;
              ilib_LogEvent.message('campType: ' + campType);

             if(objCampaignMember.LeadId!=null && !objCampaignMember.Lead.isConverted && mapIdToLead.containsKey(objCampaignMember.LeadId)){
                 /* If member is of Type Lead */
                    Lead objLead= mapIdToLead.get(objCampaignMember.LeadId);    
                    cmpMemberEmail = objLead.Email;

                    //CMCM-9421: Moving form type field from lead/contact to campaign member
                    if (!lstCampTypeForFormType.isEmpty() && lstCampTypeForFormType.contains(campType)) {
                        objCampaignMember.Form_Type__c = objLead.Form_Type__c;
                    }

                    if(objLead.Campaign_Attribution__c!=null && !objLead.Campaign_Attribution__c.equals(STRING_NULL)){
                        setEmailIds.add(objLead.Email);

                        ilib_LogEvent.message('Before Insert: lead has campaign attribution value');
                        isCattrPresent = true;

                        /*Copy the CATT value from Lead to Campaign Member*/
                        objCampaignMember.Campaign_Attribution__c=objLead.Campaign_Attribution__c;
                        if(tempIdToLeadMap.containsKey(objLead.Id)) {
                            Lead currentLead =  tempIdToLeadMap.get(objLead.Id);
                            currentLead.Campaign_Attribution__c = STRING_NULL;
                        }
                        else {
                            objLead.Campaign_Attribution__c=STRING_NULL;
                            tempIdToLeadMap.put(objLead.Id,objLead);
                        }
                    }
                    if(objLead.Media_Code__c!=null && !objLead.Media_Code__c.equals(STRING_NULL)){
                      
                        ilib_LogEvent.message('Before Insert: lead has media code value'); 
                        isMediaCodePresent = true;

                        objCampaignMember.Media_Code__c=objLead.Media_Code__c;
                        if(tempIdToLeadMap.containsKey(objLead.Id)) {
                            Lead currentLead =  tempIdToLeadMap.get(objLead.Id);
                            currentLead.Media_Code__c = STRING_NULL;
                        }
                        else {
                            objLead.Media_Code__c=STRING_NULL;
                            tempIdToLeadMap.put(objLead.Id,objLead);
                        }
                    }
             }
             else if(objCampaignMember.ContactId!=null && mapIdToContact.containsKey(objCampaignMember.ContactId)){
                    /* If member is of Type Contact */
                     Contact objContact=mapIdToContact.get(objCampaignMember.ContactId);
                     cmpMemberEmail = objContact.Email;

                    //CMCM-9421: Moving form type field from contact to campaign member
                    if (!lstCampTypeForFormType.isEmpty() && lstCampTypeForFormType.contains(campType)) {
                        objCampaignMember.Form_Type__c = objContact.Form_Type__c;
                    }

                     if(objContact.Campaign_Attribution__c!=null && !objContact.Campaign_Attribution__c.equals(STRING_NULL)){
                         setEmailIds.add(objContact.Email);

                         ilib_LogEvent.message('Before Insert: contact has campaign attribution value');
                         isCattrPresent = true;

                         /*Copy the CATT value from Contact to Campaign Member*/
                         objCampaignMember.Campaign_Attribution__c=objContact.Campaign_Attribution__c;
                         tempIdToContactMap = updateContactMap(tempIdToContactMap,objContact);
                     }
                     if(objContact.Media_Code__c!=null && !objContact.Media_Code__c.equals(STRING_NULL)){
                       
                        ilib_LogEvent.message('Before Insert: contact has media code value'); 
                        isMediaCodePresent = true;

                        objCampaignMember.Media_Code__c=objContact.Media_Code__c;
                        if(tempIdToContactMap.containsKey(objContact.Id)) {
                            Contact currentContact =  tempIdToContactMap.get(objContact.Id);
                            currentContact.Media_Code__c = STRING_NULL;
                        }
                        else {
                            objContact.Media_Code__c=STRING_NULL;
                            tempIdToContactMap.put(objContact.Id,objContact);
                        }
                     }
             }

             //CMCM-1164: If campaign member has media code or campaign attribution value then add that member to platform event map
             if (String.isNotBlank(cmpMemberEmail) && (isCattrPresent || isMediaCodePresent)) {

                PardotCattrMediaCodeSync__e event = new PardotCattrMediaCodeSync__e();
                event.Email__c = cmpMemberEmail;
                event.Cattr__c = isCattrPresent;
                event.Media_Code__c = isMediaCodePresent;

                emailToPardotEventMap.put(cmpMemberEmail, event);
                
             }
         } 
       
         ilib_LogEvent.info('setEmailIds :'+setEmailIds);//CMSI-70

         ilib_LogEvent.info('lstContact ids :'+ tempIdToContactMap.keyset());//CMSI-70
         if(!tempIdToContactMap.isEmpty()) { update tempIdToContactMap.values(); }
         //CMSI-70
         ilib_LogEvent.info('lstLead id: '+ tempIdToLeadMap.keyset());
         if(!tempIdToLeadMap.isEmpty()) { update tempIdToLeadMap.values(); }
         //Added for SPQ-37
        // populateLastMarketingCampaignBefore(lstCampaignMember);

        ilib_LogEvent.info('publish event size: '+ emailToPardotEventMap.size());

        //CMCM-1164:Publish platform events if not empty
        if (!emailToPardotEventMap.isEmpty()) {
            ilib_LogEvent.info('publishing Pardot Sync platform events');
            EventBus.publish(emailToPardotEventMap.values());
        }

     }

     private Map<Id,Contact> updateContactMap(Map<Id,Contact> idToContactMap , Contact objContact)
     {
        if(idToContactMap.containsKey(objContact.Id)) {
            Contact currentContact =  idToContactMap.get(objContact.Id);
            currentContact.Campaign_Attribution__c = STRING_NULL;
        }
        else {
            objContact.Campaign_Attribution__c=STRING_NULL;
            idToContactMap.put(objContact.Id,objContact);
        }
        return idToContactMap;
     }

    /*
    * @author Pankaj Singla
    * @date   15-Oct-2018
    * @description: The method sets the Seminar Attended, Webinar Attended and Trade show attended to true if the
    * campaign member status is attended or attended on demand
    * After insert trigger method
    */
    public override void onAfterInsert(){
        /* List of CampaignMembers created in the insert trigger */
        list<CampaignMember> lstCampaignMember=(list<CampaignMember>)trigger.new;
        Date daybefore=Date.Today().addDays(-1);
        ilib_LogEvent.info('daybefore :'+daybefore);//CMSI-70
        List<Lead> lstLead=new List<Lead>();
        List<Contact> lstContact=new List<Contact>();
        List<Prospect_Scoring_Log__c> lstProspectLog=new List<Prospect_Scoring_Log__c>();
        /*Map to store Lead records for LeadSource*/
        Map<Id,Lead> mapIdToLead=new Map<Id,Lead>();
        /*Set of Leads and Contacts Ids as campaign members*/
        Set<Id> setMemberIds=new set<Id>();
        Map<Id,Lead> mapIdToLeadForScoring = new Map<Id,Lead>();
        Map<Id,Contact> mapIdToContactForScoring = new Map<Id,Contact>();
        List<CampaignMember> lstScoringMembers=new List<CampaignMember>();
        /* Set of CampaignMember records whose scores are updated*/
        Set<Id> setUpdatedScoreRecords=new Set<Id>();
         List<Charket_Scoring_Event__e> lstevent=new List<Charket_Scoring_Event__e>();
        String strNonScoringJobFunctions=Label.Prospect_Non_Scoring_Job_Function;
        List<String> lstJobFunctions=strNonScoringJobFunctions.split(',');
        ilib_LogEvent.info('lstJobFunctions :'+lstJobFunctions);//CMSI-70
        List<Lead> lstLeadLastResponded=new List<Lead>();
        List<Contact> lstContactLastResponded=new List<Contact>();
        Boolean boolIsCharketUser=UserInfo.getName().equals(Label.Charket_User)?true:false;
        ilib_LogEvent.info('boolIsCharketUser :'+boolIsCharketUser);//CMSI-70
        Map<Id,Lead> mapLeadMapForLastResponded=new Map<Id,Lead>();
        Map<Id,Contact> mapContactForLastResponded=new Map<Id,Contact>();
        if(boolIsCharketUser || System.Test.isRunningTest()){
            for(CampaignMember objCampaignM:lstCampaignMember){
                Charket_Scoring_Event__e objEvent=new Charket_Scoring_Event__e();
                objEvent.CampaignMemberId__c=objCampaignM.Id;
                if(objCampaignM.LeadId!=null && !objCampaignM.Lead.isConverted){
                    objEvent.LeadId__c=objCampaignM.LeadId;
                }
                else if (objCampaignM.ContactId!=null){
                    objEvent.ContactId__c=objCampaignM.ContactId;
                }
                lstevent.add(objEvent);
            }
        }
        for(CampaignMember objCampMember:new CampaignMemberSelector().selectCampaignMembersList(lstCampaignMember)){
            /*Set Lead source for CVENT Campaigns*/
            if(objCampMember.LeadId!=null && !objCampMember.Lead.isConverted && String.IsBlank(objCampMember.Lead.LeadSource)  && objCampMember.Lead.createdBy.Name.equals(STRING_CVENT_USER) && objCampMember.Lead.createdDate>daybefore ){
                if(SETCAMPAIGNTYPESCVENT.contains(objCampMember.Campaign.Type)){
                    Lead objLead=new Lead(id=objCampMember.LeadId);
                    objLead.LeadSource=(objCampMember.Campaign.Type==STRING_CAMPAIGN_TYPE_SALES_EVENT)?STRING_LEADSOURCE_SALES_GENERATED:objCampMember.Campaign.Type;
                    mapIdToLead.put(objLead.Id,objLead);
                }

            }
            /*Only those campaigns where Do Not Score is false are considered for scoring*/
            if(!objCampMember.Campaign.Do_not_score__c && objCampMember.LeadId!=null && !objCampMember.Lead.isConverted){
                    setMemberIds.add(objCampMember.LeadId);
                    lstScoringMembers.add(objCampMember);
                }

            if(!objCampMember.Campaign.Do_not_score__c && objCampMember.ContactId!=null){
                    setMemberIds.add(objCampMember.ContactId);
                    lstScoringMembers.add(objCampMember);
            }
            if(objCampMember.LeadId!=null && !objCampMember.Lead.isConverted && objCampMember.HasResponded && objCampMember.Campaign.Organization_Ownership__c!=null && objCampMember.Campaign.Organization_Ownership__c.equals(STRMARKETING)) {
                if(mapLeadMapForLastResponded.containsKey(objCampMember.LeadId)){
                    Lead objLead=mapLeadMapForLastResponded.get(objCampMember.LeadId);
                    objLead.Last_Responded_Campaign_Date__c=Datetime.now();
                    objLead.Last_Responded_Campaign__c=objCampMember.CampaignId;
                    mapLeadMapForLastResponded.put(objLead.Id,objLead);
                }
                else {
                    Lead objLead=new Lead(id=objCampMember.LeadId);
                    objLead.Last_Responded_Campaign_Date__c=Datetime.now();
                    objLead.Last_Responded_Campaign__c=objCampMember.CampaignId;
                    mapLeadMapForLastResponded.put(objLead.Id,objLead);
                }
                /*Set the first Responded Campaign on Lead*/
                if(objCampMember.Lead.First_Responded_Campaign__c==null && mapLeadMapForLastResponded.containsKey(objCampMember.LeadId)){
                    Lead objLead=mapLeadMapForLastResponded.get(objCampMember.LeadId);
                    objLead.First_Responded_Campaign__c=objCampMember.CampaignId;
                    objLead.First_Responded_Campaign_Date__c=Datetime.now();
					mapLeadMapForLastResponded.put(objLead.Id,objLead);
                }

            }

            if(objCampMember.ContactId!=null && objCampMember.HasResponded &&
			objCampMember.Campaign.Organization_Ownership__c!=null && objCampMember.Campaign.Organization_Ownership__c.equals(STRMARKETING)) {
                if(mapContactForLastResponded.containsKey(objCampMember.ContactId)){
                    Contact objContact=mapContactForLastResponded.get(objCampMember.ContactId);
                     objContact.Last_Responded_Campaign_Date__c=Datetime.now();
                     objContact.Last_Responded_Campaign__c=objCampMember.CampaignId;
                     mapContactForLastResponded.put(objContact.id,objContact);
                }
                else {
                     Contact objContact=new Contact(id=objCampMember.ContactId);
                     objContact.Last_Responded_Campaign_Date__c=Datetime.now();
                     objContact.Last_Responded_Campaign__c=objCampMember.CampaignId;
                     mapContactForLastResponded.put(objContact.id,objContact);
                }

                if(objCampMember.Contact.First_Responded_Campaign__c==null && mapContactForLastResponded.containsKey(objCampMember.ContactId) ){
                    Contact objContact=mapContactForLastResponded.get(objCampMember.ContactId);
                    objContact.First_Responded_Campaign_Date__c=Datetime.now();
                    objContact.First_Responded_Campaign__c=objCampMember.CampaignId;
                    mapContactForLastResponded.put(objContact.id,objContact);
                }
            }


        }
        ilib_LogEvent.info('setMemberIds :'+setMemberIds);//CMSI-70
        if(!setMemberIds.isEmpty()){
            /*Create Maps of leads and contacts who are member and Marketing suppression as false*/
            mapIdToLeadForScoring=new Map<Id,Lead>([select id,Marketing_Suppression__c,Date_Of_Last_Score_Change__c,Marketing_Score__c
                                                from Lead where id in:setMemberIds and Marketing_Suppression__c=false and Job_Function__c not in:lstJobFunctions]);
            mapIdToContactForScoring=new Map<Id,Contact>([select id,Marketing_Suppression__c,Date_Of_Last_Score_Change__c,Marketing_Score__c
                                                          from Contact where id in:setMemberIds and Marketing_Suppression__c=false and Job_Function__c not in:lstJobFunctions]);
            for(CampaignMember objCampMember :lstScoringMembers){
                CampaignMemberWrapper objWrapper;
                /*If member is of type lead*/
                if(objCampMember.LeadId!=null && !objCampMember.Lead.isConverted && mapIdToLeadForScoring.containsKey(objCampMember.LeadId)){
                    Lead objLeadMember=mapIdToLeadForScoring.get(objCampMember.LeadId);
                    objWrapper=processCampaignMemberForScoring(objCampMember,objLeadMember);
                    if(objWrapper!=null && objWrapper.ScoreUpdated){
                        objLeadMember.Marketing_Score__c=objWrapper.FinalScore;
                        objLeadMember.Date_Of_Last_Score_Change__c=Datetime.now();
                        /*The member is added back to Map. This is because if Lead is added to multiple campaigns at the same time.
                        This would ensure to get correct value of current score for next campaign*/
                        mapIdToLeadForScoring.put(objLeadMember.id,objLeadMember);
                        lstProspectLog.add(objWrapper.objProspectLog);
                        setUpdatedScoreRecords.add(objLeadMember.id);
                    }

                }
                /*If member is of type Contact*/
                else if(objCampMember.ContactId!=null && mapIdToContactForScoring.containsKey(objCampMember.ContactId)){
                    Contact objContactMember=mapIdToContactForScoring.get(objCampMember.ContactId);
                    objWrapper=processCampaignMemberForScoring(objCampMember,objContactMember);
                    if(objWrapper!=null && objWrapper.ScoreUpdated){
                        objContactMember.Marketing_Score__c=objWrapper.FinalScore;
                        objContactMember.Date_Of_Last_Score_Change__c=Datetime.now();
                        /*The member is added back to Map. This is because if Contact is added to multiple campaigns at the same time.
                        This would ensure to get correct value of current score for next campaign*/
                        mapIdToContactForScoring.put(objContactMember.id,objContactMember);
                        lstProspectLog.add(objWrapper.objProspectLog);
                        setUpdatedScoreRecords.add(objContactMember.id);
                    }
                }
            }
            //CMSI-70 Starts
            ilib_LogEvent.info('lstProspectLog :'+UtilsCollection.getSetOfIds(lstProspectLog));
            ilib_LogEvent.info('setUpdatedScoreRecords :'+setUpdatedScoreRecords);
            //CMSI-70 Ends

        }
        /* If there are Leads for new LeadSource Value*/
        ilib_LogEvent.info('mapIdToLead after insert: '+(!mapIdToLead.isEmpty()? String.valueOf(mapIdToLead.keySet()):MAPISEMPTY));//CMSI-70
        for(Id idLead:mapIdToLead.keyset()){
            /*This is used to merge the 2 maps and create common list for leads. This would avoid multiple DMLS on lead object*/
            if(mapIdToLeadForScoring.containsKey(idLead)){
                Lead objLead=mapIdToLeadForScoring.get(idLead);
                objLead.LeadSource=mapIdToLead.get(idLead).LeadSource;
                objLead.Marketing_Score__c=mapIdToLeadForScoring.get(idLead).Marketing_Score__c;
                objLead.Date_Of_Last_Score_Change__c=mapIdToLeadForScoring.get(idLead).Date_Of_Last_Score_Change__c;
                mapIdToLeadForScoring.put(objLead.Id,objLead);
                setUpdatedScoreRecords.add(objLead.id);
            }
            else{
                Lead objLead=mapIdToLead.get(idLead);
                mapIdToLeadForScoring.put(objLead.Id,objLead);
                setUpdatedScoreRecords.add(objLead.id);

            }
        }
        ilib_LogEvent.info('mapIdToLeadForScoring :'+(!mapIdToLeadForScoring.isEmpty()? String.valueOf(mapIdToLeadForScoring.keySet()):MAPISEMPTY));//CMSI-70
        if(mapIdToLeadForScoring!=null && !mapIdToLeadForScoring.isEmpty()){
            for(Id idLead:mapIdToLeadForScoring.keySet()){
                /*Consider only those records where score is updated*/
                if(setUpdatedScoreRecords.contains(idLead)){
                    lstLead.add(mapIdToLeadForScoring.get(idLead));
                }
            }
        }
        ilib_LogEvent.info('mapIdToContactForScoring :'+(!mapIdToContactForScoring.isEmpty()? String.valueOf(mapIdToContactForScoring.keySet()):MAPISEMPTY));//CMSI-70
        if(mapIdToContactForScoring!=null && !mapIdToContactForScoring.isEmpty()){
            for(Id idContact:mapIdToContactForScoring.keySet()){
                /*Consider only those records where score is updated*/
                if(setUpdatedScoreRecords.contains(idContact)){
                    lstContact.add(mapIdToContactForScoring.get(idContact));
                }

            }
        }

        //Added for SPQ-15

        createNoteOnLeadOrContact(lstCampaignMember);
        //Added for SPQ-37
        //populateLastMarketingCampaignAfterInsert(lstCampaignMember);

        ilib_LogEvent.info('lstContact :'+UtilsCollection.getSetOfIds(lstContact)); //CMSI-70
        if(!lstContact.isEmpty()){
            update lstContact;
        }
        //CMSI-70
        ilib_LogEvent.info('lstLead :'+UtilsCollection.getSetOfIds(lstLead));
        if(!lstLead.isEmpty()){
            update lstLead;
        }
        ilib_LogEvent.info('lstProspectLog :'+UtilsCollection.getSetOfIds(lstProspectLog));
        if(!lstProspectLog.isEmpty()){
            insert lstProspectLog;
        }
        //CMSI-70
        ilib_LogEvent.info('mapLeadMapForLastResponded :'+(!mapLeadMapForLastResponded.isEmpty()? String.valueOf(mapLeadMapForLastResponded.keySet()):MAPISEMPTY));
        if(!mapLeadMapForLastResponded.isEmpty()){
            lstLeadLastResponded.addAll(mapLeadMapForLastResponded.values());
            update lstLeadLastResponded;
        }
        //CMSI-70
        ilib_LogEvent.info('mapContactForLastResponded :'+(!mapContactForLastResponded.isEmpty()? String.valueOf(mapContactForLastResponded.keySet()):MAPISEMPTY));
        if(!mapContactForLastResponded.isEmpty()){
            lstContactLastResponded.addAll(mapContactForLastResponded.values());
            update lstContactLastResponded;
        }
        ilib_LogEvent.info('lstevent on after insert:'+lstevent);//CMSI-70
        if(!lstevent.isEmpty()){
            EventBus.publish(lstevent);
        }

        populateMostRecentActivityOnLeads(); //DCP-49756

    }

    /*
    * @author Pankaj Singla
    * @date   20-May-2020
    * @description: idToCampaignMember map of New CampaignMembers
    * @parameters:None
    * @return : None
    */
     public override void onBeforeUpdate(Map<Id, SObject> idToCampaignMember){
         Set<Id> setLeads=new Set<Id>();
         Set<Id> setContacts=new Set<Id>();
         Set<String> setEmailIds=new Set<String>();
         Map<Id,Boolean> mapLdConIdToBoolean = new Map<Id,Boolean>();
         Map<Id,Lead> tempIdToLeadMap = new Map<Id,Lead>();
         Map<Id,Contact> tempIdToContactMap = new Map<Id,Contact>();

        //CMCM-1164: Added for this story
        Map<String, PardotCattrMediaCodeSync__e> emailToPardotEventMap = new Map<String, PardotCattrMediaCodeSync__e>();

         Boolean boolIsCharketUser=UserInfo.getName().equals(Label.Charket_User)?true:false;
         ilib_LogEvent.info('boolIsCharketUser :'+boolIsCharketUser);

        //CMCM-1188: Find campaign attribution and media code value for Cvent user
        Boolean isCventUser = UserInfo.getName().equals(STRING_CVENT_USER) ? true : false;
        List<CampaignMember> lstCampaignMembers = Trigger.new;
        ilib_LogEvent.info('isCventUser :'+ isCventUser);
        if (isCventUser) {
            CampaignMemberService.runCattMediaLogicForCvent(lstCampaignMembers);
        }

         /*Get list of leads and Contacts as members of Campaign*/
          for(Id idCampaignMember : idToCampaignMember.keySet()){
              CampaignMember objNewCampaignMember = (CampaignMember) Trigger.newMap.get(idCampaignMember);
              if(objNewCampaignMember.LeadId!=null && !objNewCampaignMember.Lead.isConverted){
                  setLeads.add(objNewCampaignMember.LeadId);
              }
              else if(objNewCampaignMember.ContactId!=null){
                 setContacts.add(objNewCampaignMember.ContactId);
              }
          }
         //CMSI-70
         ilib_LogEvent.info('setLeads on before update:'+setLeads);
         ilib_LogEvent.info('setContacts on beffore update :'+setContacts);
         Map<Id,Lead> mapIdToLead=new Map<Id,Lead>([select id,email, Campaign_Attribution__c, Media_Code__c from Lead where id in:setLeads]);
         Map<Id,Contact> mapIdToContact=new Map<Id,Contact>([select id,email, Campaign_Attribution__c, Media_Code__c from Contact where id in:setContacts]);
         //CMSI-70
         ilib_LogEvent.info('mapIdToLead on before update:'+(!mapIdToLead.isEmpty()? String.valueOf(mapIdToLead.keySet()):MAPISEMPTY));
         ilib_LogEvent.info('mapIdToContact on before update:'+(!mapIdToContact.isEmpty()? String.valueOf(mapIdToContact.keySet()):MAPISEMPTY));
         list<CampaignMember> lstCmpgnMembers = (list<CampaignMember>)trigger.new;
         if (boolIsCharketUser || System.Test.isRunningTest()) {
                mapLdConIdToBoolean = CharketUtils.updateCMStatus(lstCmpgnMembers);
            }
         ilib_LogEvent.info('mapLdConIdToBoolean on before insert: '+(!mapLdConIdToBoolean.isEmpty()? String.valueOf(mapLdConIdToBoolean.keySet()):MAPISEMPTY));
         for(Id idCampaignMember : idToCampaignMember.keySet()){
            CampaignMember objNewCampaignMember = (CampaignMember) Trigger.newMap.get(idCampaignMember);

            // CMCM-1164: Added below 3 variables to collect campaign member email and Cattr and Media Code presence flag
            String cmpMemberEmail = '';
            Boolean isCattrPresent = false;
            Boolean isMediaCodePresent = false;

            // DCP-47093: If it's charket user then check for campaign member status change
            if ((boolIsCharketUser || System.Test.isRunningTest()) && ((mapLdConIdToBoolean.containsKey(objNewCampaignMember.LeadId) && mapLdConIdToBoolean.get(objNewCampaignMember.LeadId)) || (mapLdConIdToBoolean.containsKey(objNewCampaignMember.ContactId) && mapLdConIdToBoolean.get(objNewCampaignMember.ContactId)))){
                ilib_LogEvent.message('Before Update Charket: Setting up campaign member customization for status attended to attended contact me');
                objNewCampaignMember.Status = 'Attended-Contact Me';
            }

            /* If member is of Type Lead */
            if(objNewCampaignMember.LeadId!=null && !objNewCampaignMember.Lead.isConverted && mapIdToLead.containsKey(objNewCampaignMember.LeadId)){
                Lead objLead= mapIdToLead.get(objNewCampaignMember.LeadId);

                cmpMemberEmail = objLead.Email;

                if(objLead.Campaign_Attribution__c!=null && !objLead.Campaign_Attribution__c.equals(STRING_NULL)){
                        setEmailIds.add(objLead.Email);

                        ilib_LogEvent.message('Before Update: lead has campaign attribution value');
                        isCattrPresent = true;

                        objLead.Campaign_Attribution__c=STRING_NULL;
                        if(tempIdToLeadMap.containsKey(objLead.Id)) {
                            Lead currentLead =  tempIdToLeadMap.get(objLead.Id);
                            currentLead.Campaign_Attribution__c = STRING_NULL;
                        }
                        else {
                            objLead.Campaign_Attribution__c=STRING_NULL;
                            tempIdToLeadMap.put(objLead.Id,objLead);
                        }
                }
              
                if(objLead.Media_Code__c!=null && !objLead.Media_Code__c.equals(STRING_NULL)){ 

                    ilib_LogEvent.message('Before Update: lead has media code value');
                    isMediaCodePresent = true;

                    if(tempIdToLeadMap.containsKey(objLead.Id)) {
                        Lead currentLead =  tempIdToLeadMap.get(objLead.Id);
                        currentLead.Media_Code__c = STRING_NULL;
                    }
                    else {
                        objLead.Media_Code__c=STRING_NULL;
                        tempIdToLeadMap.put(objLead.Id,objLead);
                    }
                }
            }
             /* If member is of Type Contact */
            else if(objNewCampaignMember.ContactId!=null && mapIdToContact.containsKey(objNewCampaignMember.ContactId)){
                Contact objContact=mapIdToContact.get(objNewCampaignMember.ContactId);
                cmpMemberEmail = objContact.Email;
                 if(objContact.Campaign_Attribution__c!=null && !objContact.Campaign_Attribution__c.equals(STRING_NULL)){
                         setEmailIds.add(objContact.Email);

                         ilib_LogEvent.message('Before Update: contact has campaign attribution value');
                         isCattrPresent = true;

                         objContact.Campaign_Attribution__c=STRING_NULL;
                         tempIdToContactMap = updateContactMap(tempIdToContactMap,objContact);
                }
                if(objContact.Media_Code__c!=null && !objContact.Media_Code__c.equals(STRING_NULL)){

                    ilib_LogEvent.message('Before Update: contact has media code value');
                    isMediaCodePresent = true;

                    if(tempIdToContactMap.containsKey(objContact.Id)) {
                        Contact currentContact =  tempIdToContactMap.get(objContact.Id);
                        currentContact.Media_Code__c = STRING_NULL;
                    }
                    else {
                        objContact.Media_Code__c=STRING_NULL;
                        tempIdToContactMap.put(objContact.Id,objContact);
                    }
                 }
            }

            //CMCM-1164: If campaign member has media code or campaign attribution value then add that member to platform event map
            if (String.isNotBlank(cmpMemberEmail) && (isCattrPresent || isMediaCodePresent)) {
                PardotCattrMediaCodeSync__e event = new PardotCattrMediaCodeSync__e();
                event.Email__c = cmpMemberEmail;
                event.Cattr__c = isCattrPresent;
                event.Media_Code__c = isMediaCodePresent;
                
                emailToPardotEventMap.put(cmpMemberEmail, event);
            }

         }
         ilib_LogEvent.info('setEmailIds :'+setEmailIds);//CMSI-70

        //CMCM-1164:Publish platform events if not empty
        if (!emailToPardotEventMap.isEmpty()) {
            ilib_LogEvent.info('publishing Pardot Sync platform events');
            EventBus.publish(emailToPardotEventMap.values());
        }

         ilib_LogEvent.info('lstContact ids :'+ tempIdToContactMap.keyset());//CMSI-70
         if(!tempIdToContactMap.isEmpty()) { update tempIdToContactMap.values(); }
         ilib_LogEvent.info('lstLead id: '+ tempIdToLeadMap.keyset());
         if(!tempIdToLeadMap.isEmpty()) { update tempIdToLeadMap.values(); }
     }

    /*
    * @author Pankaj Singla
    * @date   15-Oct-2018
    * @description: The methods sets the Seminar Attended, Webinar Attended and Trade show attended to true if the
    * campaign member status is updated as attended or attended on demand
    * After update trigger method
    */

    public override void onAfterUpdate(Map<Id, sObject> oldRecords)
    {
        List<CampaignMember> lstCampaignMembers = (List<CampaignMember>) records;
        List<CampaignMember> lstScoringMembers=new List<CampaignMember>();
        List<Lead> lstLead=new List<Lead>();
        List<Contact> lstContact=new List<Contact>();
        List<Prospect_Scoring_Log__c> lstProspectLog=new List<Prospect_Scoring_Log__c>();
        Set<Id> setMemberIds=new set<Id>();
        Set<Id> setUpdatedScoreRecords=new Set<Id>();
        Map<Id,Lead> mapIdToLead;
        Map<Id,Contact> mapIdToContact;
        String strNonScoringJobFunctions=Label.Prospect_Non_Scoring_Job_Function;
        List<String> lstJobFunctions=strNonScoringJobFunctions.split(',');
        list<Lead> lstLeadForLastResponded=new List<Lead>();
        List<contact> lstContactForLastResponded=new List<contact>();
        List<Charket_Scoring_Event__e> lstevent=new List<Charket_Scoring_Event__e>();
        Boolean boolIsCharketUser=UserInfo.getName().equals(Label.Charket_User)?true:false;
        ilib_LogEvent.info('boolIsCharketUser :'+boolIsCharketUser);//CMSI-70
        Map<Id,Lead> mapLeadMapForLastResponded=new Map<Id,Lead>();
        Map<Id,Contact> mapContactForLastResponded=new Map<Id,Contact>();
        List<Admin_Operation__e> lstCampaignMemberNoteUpdates = new List<Admin_Operation__e>();//Added for SPQ-15
        if(boolIsCharketUser|| System.Test.isRunningTest()){
            for(CampaignMember objCampMember:lstCampaignMembers){
                CampaignMember objOldCampaignMember = (CampaignMember)oldRecords.get(objCampMember.Id);
                if(!objCampMember.Status.equals(objOldCampaignMember.Status)){
                    Charket_Scoring_Event__e objEvent=new Charket_Scoring_Event__e();
                    objEvent.CampaignMemberId__c=objCampMember.Id;
                    if(objCampMember.LeadId!=null && !objCampMember.Lead.isConverted){
                        objEvent.LeadId__c=objCampMember.LeadId;
                        lstevent.add(objEvent);
                    }
                    if(objCampMember.ContactId!=null){
                        objEvent.ContactId__c=objCampMember.ContactId;
                        lstevent.add(objEvent);
                    }
                }
            }
        }
        for(CampaignMember objCampMember:new CampaignMemberSelector().selectCampaignMembersList(lstCampaignMembers)){
            ilib_LogEvent.message('objCampMember :'+objCampMember);//CMSI-70
            CampaignMember objOldCampaignMember = (CampaignMember)oldRecords.get(objCampMember.Id);
            /*Scores would be updated only if the member status is updated*/
            if(!objCampMember.Status.equals(objOldCampaignMember.Status)){
                if(!objCampMember.Campaign.Do_not_score__c && objCampMember.LeadId!=null && !objCampMember.Lead.isConverted){
                    setMemberIds.add(objCampMember.LeadId);
                    lstScoringMembers.add(objCampMember);
                }
                else if(!objCampMember.Campaign.Do_not_score__c && objCampMember.ContactId!=null) {
                    setMemberIds.add(objCampMember.ContactId);
                    lstScoringMembers.add(objCampMember);
                }
            }
            if(objCampMember.Campaign.Organization_Ownership__c!=null && STRMARKETING.equalsIgnoreCase(objCampMember.Campaign.Organization_Ownership__c) && objCampMember.HasResponded && !objOldCampaignMember.HasResponded){
                if(objCampMember.LeadId!=null && !objCampMember.Lead.isConverted){
                    if(mapLeadMapForLastResponded.containsKey(objCampMember.LeadId)){
                        Lead objLead=mapLeadMapForLastResponded.get(objCampMember.LeadId);
                        objLead.Last_Responded_Campaign__c=objCampMember.CampaignId;
                        objLead.Last_Responded_Campaign_Date__c=Datetime.now();
                        mapLeadMapForLastResponded.put(objLead.Id,objLead);
                    }
                    else {
                        Lead objLead=new Lead(id=objCampMember.LeadId);
                        objLead.Last_Responded_Campaign__c=objCampMember.CampaignId;
                        objLead.Last_Responded_Campaign_Date__c=Datetime.now();
                        mapLeadMapForLastResponded.put(objLead.Id,objLead);
                    }

                    if(objCampMember.Lead.First_Responded_Campaign__c==null && mapLeadMapForLastResponded.containsKey(objCampMember.LeadId)){
                        Lead objLead=mapLeadMapForLastResponded.get(objCampMember.LeadId);
                        objLead.First_Responded_Campaign__c=objCampMember.CampaignId;
                        objLead.First_Responded_Campaign_Date__c=Datetime.now();
                        mapLeadMapForLastResponded.put(objLead.Id,objLead);
                    }
                }

                if(objCampMember.ContactId!=null){
                    if(mapContactForLastResponded.containsKey(objCampMember.ContactId)){
                        Contact objContact=mapContactForLastResponded.get(objCampMember.ContactId);
                        objContact.Last_Responded_Campaign__c=objCampMember.CampaignId;
                        objContact.Last_Responded_Campaign_Date__c=Datetime.now();
                        mapContactForLastResponded.put(objContact.id,objContact);
                    }
                    else {
                        Contact objContact=new Contact(id=objCampMember.ContactId);
                        objContact.Last_Responded_Campaign__c=objCampMember.CampaignId;
                        objContact.Last_Responded_Campaign_Date__c=Datetime.now();
                        mapContactForLastResponded.put(objContact.id,objContact);
                    }

                    if(objCampMember.Contact.First_Responded_Campaign__c==null && mapContactForLastResponded.containsKey(objCampMember.ContactId)){
                        Contact objContact=mapContactForLastResponded.get(objCampMember.ContactId);
                        objContact.First_Responded_Campaign__c=objCampMember.CampaignId;
                        objContact.First_Responded_Campaign_Date__c=Datetime.now();
                        mapContactForLastResponded.put(objContact.id,objContact);
                    }
                }

            }
        }
        ilib_LogEvent.info('setMemberIds :'+setMemberIds);//CMSI-70
        if(!setMemberIds.isEmpty()){
            mapIdToLead=new Map<Id,Lead>([select id,Marketing_Suppression__c,Date_Of_Last_Score_Change__c,Marketing_Score__c
                                                from Lead where id in:setMemberIds and Marketing_Suppression__c=false and Job_Function__c not in:lstJobFunctions]);
            mapIdToContact=new Map<Id,Contact>([select id,Marketing_Suppression__c,Date_Of_Last_Score_Change__c,Marketing_Score__c from Contact
                                                where id in:setMemberIds and Marketing_Suppression__c=false and Job_Function__c not in:lstJobFunctions]);
            //CMSI-70
            ilib_LogEvent.info('mapIdToLead on after update :'+(!mapIdToLead.isEmpty()? String.valueOf(mapIdToLead.keySet()):MAPISEMPTY));
            ilib_LogEvent.info('mapIdToContact on after update:'+(!mapIdToContact.isEmpty()? String.valueOf(mapIdToContact.keySet()):MAPISEMPTY));
            for(CampaignMember objCampMember :lstScoringMembers){
                CampaignMemberWrapper objWrapper;
                if(objCampMember.LeadId!=null && !objCampMember.Lead.isConverted && mapIdToLead.containsKey(objCampMember.LeadId)){
                    Lead objLeadMember=mapIdToLead.get(objCampMember.LeadId);
                        objWrapper=processCampaignMemberForScoring(objCampMember,objLeadMember);
                        if(objWrapper!=null && objWrapper.ScoreUpdated){
                            objLeadMember.Marketing_Score__c=objWrapper.FinalScore;
                            objLeadMember.Date_Of_Last_Score_Change__c=Datetime.now();
                            mapIdToLead.put(objLeadMember.id,objLeadMember);
                            lstProspectLog.add(objWrapper.objProspectLog);
                            setUpdatedScoreRecords.add(objLeadMember.id);
                        }
                }
                else if(objCampMember.ContactId!=null && mapIdToContact.containsKey(objCampMember.ContactId)){
                    Contact objContactMember=mapIdToContact.get(objCampMember.ContactId);
                        objWrapper=processCampaignMemberForScoring(objCampMember,objContactMember);
                        if(objWrapper!=null && objWrapper.ScoreUpdated){
                            objContactMember.Marketing_Score__c=objWrapper.FinalScore;
                            objContactMember.Date_Of_Last_Score_Change__c=Datetime.now();
                            mapIdToContact.put(objContactMember.id,objContactMember);
                            lstProspectLog.add(objWrapper.objProspectLog);
                            setUpdatedScoreRecords.add(objContactMember.id);
                        }
                }
            }

        }
        ilib_LogEvent.info('setUpdatedScoreRecords :'+setUpdatedScoreRecords);//CMSI-70
        if(!setUpdatedScoreRecords.isEmpty()){
            for(Id idLead:mapIdToLead.keyset()){
                if(setUpdatedScoreRecords.contains(idLead)){
                    lstLead.add(mapIdToLead.get(idLead));
                }
            }

            for(Id idContact:mapIdToContact.keyset()){
                if(setUpdatedScoreRecords.contains(idContact)){
                    lstContact.add(mapIdToContact.get(idContact));
                }
            }
        }

        /*
         Added for SPQ-15
        */
        for(CampaignMember objCampMember:lstCampaignMembers) {
            CampaignMember objOldCampaignMember = (CampaignMember)oldRecords.get(objCampMember.Id);
            if(objCampMember.Campaign_Member_Notes__c!=objOldCampaignMember.Campaign_Member_Notes__c) {
                lstCampaignMemberNoteUpdates.add(new Admin_Operation__e(Related_Record__c=objCampMember.id,Name__c='UpdateNoteOnLeadOrContact'));
            }
        }
        ilib_LogEvent.info('lstLead id:'+UtilsCollection.getSetOfIds(lstLead));//CMSI-70
        if(!lstLead.isEmpty()){
            update lstLead;
        }
        ilib_LogEvent.info('lstContact id :'+UtilsCollection.getSetOfIds(lstContact));//CMSI-70
        if(!lstContact.isEmpty()){
            update lstContact;
        }

        if(!lstProspectLog.isEmpty()){
            insert lstProspectLog;
        }
        //CMSI-70
        ilib_LogEvent.message('lstProspectLog after insert :'+UtilsCollection.getSetOfIds(lstProspectLog));
        ilib_LogEvent.info('mapLeadMapForLastResponded :'+(!mapLeadMapForLastResponded.isEmpty()? String.valueOf(mapLeadMapForLastResponded.keySet()):MAPISEMPTY));
        if(mapLeadMapForLastResponded!=null && !mapLeadMapForLastResponded.isEmpty()){
            lstLeadForLastResponded.addAll(mapLeadMapForLastResponded.values());
            update lstLeadForLastResponded;
        }
        //CMSI-70
        ilib_LogEvent.info('mapContactForLastResponded :'+(!mapContactForLastResponded.isEmpty()? String.valueOf(mapContactForLastResponded.keySet()):MAPISEMPTY));
        if(mapContactForLastResponded!=null && !mapContactForLastResponded.isEmpty()){
            lstContactForLastResponded.addAll(mapContactForLastResponded.values());
            update lstContactForLastResponded;
        }
        ilib_LogEvent.info('lstevent on after update :'+lstevent);//CMSI-70
        if(!lstevent.isEmpty()){
            EventBus.publish(lstevent);
        }

        /*
         Added for SPQ-15
        */
        ilib_LogEvent.info('lstCampaignMemberNoteUpdates :'+UtilsCollection.getSetOfIds(lstCampaignMemberNoteUpdates));//CMSI-70
       if(!lstCampaignMemberNoteUpdates.isEmpty()) {
        EventBus.publish(lstCampaignMemberNoteUpdates);
        }

        populateMostRecentActivityOnLeads(); //DCP-49756
    }

     /*
    * @author Rishi Sharma
    * @date   17-June-2021
    * After delete trigger method
    * @Note: This method's corresponding test method is in TestMoveCampaignMembersController class, which
    *        needs to be included for proper coverage
    */
/*  public override void onAfterDelete(){
        list<CampaignMember> lstCampaignMember=(list<CampaignMember>)trigger.old;
        populateLastMarketingCampaignDelete(lstCampaignMember);
    } */
    /*CMSI-51
    * method will return the workstream
    */
    public override string getWorkstream(){
        return ilib_LogEvent.MARKETING;
    }
    /*
    * @author Pankaj Singla
    * @date   02-Jun-2020
    * @description: The methods sets the scoring on the Lead and Contact based on Campaign Membership
    * @Param objCampMember the CampaignMember Record
    * @return CampaignMemberWrapper Wrapper Member
    */
    public static CampaignMemberWrapper processCampaignMemberForScoring(CampaignMember objCampMember, sObject objMemberRecord){
        //CMSI-70

        ilib_LogEvent.message('objCampMember :'+objCampMember);
        ilib_LogEvent.message('objMemberRecord :'+objMemberRecord);
        Map<String,Prospect_Scoring_Metadata__mdt> mapStringToScoringMdt=new Map<String,Prospect_Scoring_Metadata__mdt>();
        Integer intScoreIncrementVal;
        Integer intCurrScoreVal;
        Integer intFinalScore;
        CampaignMembers.CampaignMemberWrapper objWrapper;
        String strCampaignRegion;
        String strCampaignDistrict;
        String strCampaignChannel;
        String strCampaignSubregion; // CMCM-1160
        /*Create map of Prospect Scoring Metadata records*/
        for(Prospect_Scoring_Metadata__mdt objmdt:new ProspectScoringMetadataSelector().selectActiveRecords()){
            //String strKeyVal=objmdt.Campaign_Type__c+'_'+objmdt.Campaign_Channel__c+'_'+objmdt.Member_Status__c;
            mapStringToScoringMdt.put(objmdt.Primary_Key_Value__c,objmdt);
        }
        strCampaignChannel=objCampMember.Campaign.Channel__c;
        strCampaignRegion=objCampMember.Campaign.Campaign_Region__c;
        strCampaignDistrict=objCampMember.Campaign.Campaign_District__c;
        strCampaignSubregion=objCampMember.Campaign.Campaign_Subregion__c; // CMCM-1160
        String strKeyVal=objCampMember.Campaign.Type+'_'+strCampaignChannel+'_'+objCampMember.Status;
        ilib_LogEvent.message('member strKeyVal: ' + strKeyVal);
        if(!String.isBlank(strCampaignChannel) && !String.isBlank(strCampaignRegion) && (!String.isBlank(strCampaignDistrict) || !String.isBlank(strCampaignSubregion))){
            ilib_LogEvent.message('member contains key: ' + mapStringToScoringMdt.containsKey(strKeyVal));
            /*Check if the cmpaign member details are present in Metadata*/
            if(mapStringToScoringMdt.containsKey(strKeyVal)){
                Prospect_Scoring_Metadata__mdt objMdtRec=mapStringToScoringMdt.get(strKeyVal);
                String strScoringRegion=determineScoringRegionField(strCampaignRegion,strCampaignDistrict, strCampaignSubregion);
                String strRegionVal=strScoringRegion.removeEnd('__c');
                intScoreIncrementVal=Integer.ValueOf(objMdtRec.get(strScoringRegion));
                intCurrScoreVal=Integer.ValueOf(objMemberRecord.get('Marketing_Score__c'));
                intCurrScoreVal=(intCurrScoreVal==null)?0:intCurrScoreVal;
                intFinalScore=computeFinalScore(intCurrScoreVal,intScoreIncrementVal);
                ProspectScoringUtils.boolPreventDuplicateRun=true;
                Prospect_Scoring_Log__c objProspectLog=ProspectScoringUtils.createProspectScoringLogRecords(STRING_ACTION,objCampMember.Campaign.Name,objMemberRecord.Id,Userinfo.getUserId(),strRegionVal,intCurrScoreVal,intFinalScore);
                objWrapper=new CampaignMembers.CampaignMemberWrapper();
                objWrapper.ScoreUpdated=(intFinalScore==intCurrScoreVal?false:true);
                objWrapper.FinalScore=intFinalScore;
                objWrapper.objProspectLog=objProspectLog;


            }
        }
         //CMSI-70
         ilib_LogEvent.message('objWrapper :'+objWrapper);

        return objWrapper;
    }
    /*
    * @author Pankaj Singla
    * @date   02-Jun-2020
    * @description: The method determin the scoring Region
    * @Param strCampRegion: The CampaignRegion Value
    * @Param strCampDistrict: The Campaign District  Value
    * @return String The Region Field to be used
    */
    private static String determineScoringRegionField(String strCampRegion,String strCampDistrict, String strCmpSubregion){
         //CMSI-70

        ilib_LogEvent.message('strCampRegion :'+strCampRegion);
        ilib_LogEvent.message('strCampDistrict :'+strCampDistrict);
        ilib_LogEvent.message('strCmpSubregion :'+strCmpSubregion);
        String strScoringRegion='';
        String strScoreFieldName;

        // CMCM-1160: Added first if block to support new Subreion field. Old checks left as it is to have backward compatibility
        if(strCampRegion.equals(STRING_CAMPAIGN_REGION_AMEA) && String.isNotBlank(strCmpSubregion) && strCmpSubregion.equals(STRING_CAMPAIGN_DISTRICT_JAPAN)){
            strScoringRegion=STRING_CAMPAIGN_DISTRICT_JAPAN;
        } else if(strCampRegion.equals(STRING_CAMPAIGN_REGION_APJ) && String.isNotBlank(strCampDistrict) && strCampDistrict.equals(STRING_CAMPAIGN_DISTRICT_JAPAN)){
            strScoringRegion=STRING_CAMPAIGN_DISTRICT_JAPAN;
        } else if(strCampRegion.equals(STRING_CAMPAIGN_REGION_APJ)){
            strScoringRegion=STRING_CAMPAIGN_DISTRICT_SAPAC;
        } else {
            strScoringRegion=strCampRegion;
        }
        strScoreFieldName=strScoringRegion+'__c';
        //CMSI-70
        ilib_LogEvent.message('strScoreFieldName :'+strScoreFieldName);

        return strScoreFieldName;

    }
    /*
    * @author Pankaj Singla
    * @date   02-Jun-2020
    * @description: The method calculates the final score value
    * @Param intCurrScoreVal: The current score value
    * @Param intScoreIncrementVal: The incremental value
    * @return Integer The final score value
    */
    public static Integer computeFinalScore(Integer intCurrScoreVal, Integer intScoreIncrementVal){
        //CMSI-70

        ilib_LogEvent.message('intCurrScoreVal :'+intCurrScoreVal);
        ilib_LogEvent.message('intScoreIncrementVal :'+intScoreIncrementVal);
        Integer intFinalScore;
        if(intCurrScoreVal==null){
            intCurrScoreVal=0;
            intFinalScore=intScoreIncrementVal;
        }
        else{
            intFinalScore=intCurrScoreVal+ intScoreIncrementVal;
        }
        //CMSI-70
        ilib_LogEvent.message('intFinalScore :'+intFinalScore);

        return intFinalScore;
    }

    /*
    * @author Rishi Sharma
    * @date   21-Jun-2021
    * @description: Method to update Last Marketing Date on Campaign Members Before Insert
    * @Param lstCampaignMember: list of Campaign Members.
    * @return:None
    */

/*    public static void populateLastMarketingCampaignBefore(List<CampaignMember> lstCampaignMembers){
         //CMSI-70
        ilib_LogEvent.push(LOG_TITLE + '.populateLastMarketingCampaignBefore()');

        Set<Id> setContacts = UtilsCollection.getSetOfIds(lstCampaignMembers , 'ContactId');
        Set<Id> setLeads = UtilsCollection.getSetOfIds(lstCampaignMembers , 'LeadId');
        Set<Id> setCampId = UtilsCollection.getSetOfIds(lstCampaignMembers , 'CampaignId');
        CampaignMemberSelector cmSelector = new CampaignMemberSelector();
        List<CampaignMember> lstCMember=new List<CampaignMember>();
        List<Campaign> lstCampRecord = new List<Campaign>();
        CampaignSelector campSelector = new CampaignSelector();
        Map<Id, String> mapCamptoOwnership = new Map<Id, String>();

         //Get the Campaign organization ownership
        lstCampRecord = campSelector.selectCampaignOrganizationOwnership(setCampId);
        ilib_LogEvent.info('lstCampRecord :'+UtilsCollection.getSetOfIds(lstCampRecord));//CMSI-70
        mapCamptoOwnership = UtilsCollection.getMapOfIdToString(lstCampRecord, 'Id', 'Organization_Ownership__c');

        //Get the Last Marketing Campaign for the lead or contact record
        if(!setLeads.isEmpty()){
         	    lstCMember = cmSelector.selectOrderedMarketingCampaignMembersLead(setLeads);
         }
        if(!setContacts.isEmpty()){
         	    lstCMember = cmSelector.selectOrderedMarketingCampaignMembersContact(setContacts);
		}

        //Populate the mapCampIdtoMember with the CampaignId and Campaign Member record based on the Sales or Marketing campaign
        //If the current Campaign Member is of Sales type, then the Last Marketing Campaign Id will be populated
        //If the current Campaign Member is of Marketing type, current Campaign Id will be populated

        for(CampaignMember cm:lstCampaignMembers){
            if(mapCamptoOwnership.get(cm.CampaignId) == STRSALES && !lstCMember.isEmpty()){
                cm.Last_Marketing_Campaign__c = lstCMember[lstCMember.size()-1].CampaignId;
            }
            else if(mapCamptoOwnership.get(cm.CampaignId) == STRMARKETING){
                cm.Last_Marketing_Campaign__c = cm.CampaignId;
            }
        }

    } */
    /*
    * @author Rishi Sharma
    * @date   14-Jun-2021
    * @description: Method to update Last Marketing Date on Campaign Members After Insert
    * @Param lstCampaignMember: list of Campaign Members.
    * @return:None
    */

/*  public static void populateLastMarketingCampaignAfterInsert(List<CampaignMember> lstCampaignMembers){
        //CMSI-70
        ilib_LogEvent.push(LOG_TITLE + '.populateLastMarketingCampaignAfterInsert()');
        Set<Id> setContacts = UtilsCollection.getSetOfIds(lstCampaignMembers , 'ContactId');
        Set<Id> setLeads = UtilsCollection.getSetOfIds(lstCampaignMembers , 'LeadId');
        Set<Id> setCampId = UtilsCollection.getSetOfIds(lstCampaignMembers , 'CampaignId');
        Set<Id> setCampaignMemberId = UtilsCollection.getSetOfIds(lstCampaignMembers, 'id');
        List<CampaignMember> lstCmAfter = new List<CampaignMember>();
        List<Campaign> lstCampRecord = new List<Campaign>();
        CampaignMemberSelector cmSelector = new CampaignMemberSelector();
        CampaignSelector campSelector = new CampaignSelector();
        Map<Id, String> mapCamptoOwnership = new Map<Id, String>();

        Map<id, List<CampaignMember>> mapCampIdtoMember =new Map<id, List<CampaignMember>>();

        //Get the Campaign organization ownership
        lstCampRecord = campSelector.selectCampaignOrganizationOwnership(setCampId);
        ilib_LogEvent.info('lstCampRecord :'+UtilsCollection.getSetOfIds(lstCampRecord));//CMSI-70
        mapCamptoOwnership = UtilsCollection.getMapOfIdToString(lstCampRecord, 'Id', 'Organization_Ownership__c');
        ilib_LogEvent.info('mapCamptoOwnership :'+mapCamptoOwnership);//CMSI-70


        //Get the Last Marketing Campaign and the Sales Campaign Members to be updated in Before Insert, After Insert and After Delete
        if(!setLeads.isEmpty()){
				lstCmAfter = cmSelector.selectCampaignMembersLead(setLeads, setCampaignMemberId);
        }
        if(!setContacts.isEmpty()){
           		lstCmAfter = cmSelector.selectCampaignMembersContact(setContacts, setCampaignMemberId);

        }

        //Populate the mapCampIdtoMember with the CampaignId and Campaign Member record based on the Sales or Marketing campaign
        //If the current Campaign Member is of Sales type, then the Last Marketing Campaign Id will be populated
        //If the current Campaign Member is of Marketing type, current Campaign Id will be populated

        for(CampaignMember cm:lstCampaignMembers){
                if(mapCamptoOwnership.get(cm.CampaignId) == STRMARKETING){

                mapCampIdtoMember.put(cm.Last_Marketing_Campaign__c, lstCmAfter);
                }
        	}



        //Passing mapCampIdtoMember to the queueable to populate the Last Marketing Campaign for Sales Campaign Members After Insert and After Delete
        ilib_LogEvent.info('mapCampIdtoMember :'+(!mapCampIdtoMember.isEmpty()? String.valueOf(mapCampIdtoMember.keySet()):MAPISEMPTY));//CMSI-70

        //DCP-57383: Stopping queueable getting fired from Async (batch) context. If it's async context then calling it in sync way
        if (System.isBatch() || System.isFuture() || System.isQueueable() || System.isScheduled()) {
            // sync method performing the same operation as done by queueable
            populateLastMarketingCampaignAfterInsertSync(mapCampIdtoMember);
        } else {
            // Existing path of calling queueable
            if(mapCampIdtoMember != null && !mapCampIdtoMember.isEmpty()){

                CampaignMemberLastMarketingQueueable cmUpdateLastMarketingCampaign;
                cmUpdateLastMarketingCampaign = new CampaignMemberLastMarketingQueueable(mapCampIdtoMember);

                ilib_Queueablethread queueableThread = new ilib_Queueablethread('CampaignMember_CampaignMemberLastMarketingQueueable');
                queueableThread.logAndQueue(cmUpdateLastMarketingCampaign, 'CampaignMemberLastMarketingQueueable', STREXECUTE);
                ilib_QueueableManager.enqueueJob(queueableThread,ilib_LogEvent.SALES);//CMSI-70
            }


        }

        ilib_LogEvent.pop(); //CMSI-70

    } */


    /*
    * @author Deep Diwakar
    * @date   14-Jun-2021
    * @description: Method to update Last Marketing Date on Campaign Members in Sync manner when the transaction is in Async context
    * @Param lstCampaignMember: list of Campaign Members.
    * @return:None
    */
/*  private static void populateLastMarketingCampaignAfterInsertSync(Map<id, List<CampaignMember>> mapCidToCm) {

        if (mapCidToCm == null || mapCidToCm.isEmpty()) {
            return;
        }

        List<CampaignMember> lstFromMap = new List<CampaignMember>();
        List<CampaignMember> lstCmToUpdate = new List<CampaignMember>();
        id campId;

        for(Id cId: mapCidToCm.keySet()){
            lstFromMap = mapCidToCm.get(cId);
            campId = cId;
        }

        for(CampaignMember cm : lstFromMap){
            cm.Last_Marketing_Campaign__c = campId;
            lstCmToUpdate.add(cm);
        }


        if (!lstCmToUpdate.isEmpty()) {
            update lstCmToUpdate;
        }


    } */

    /*
    * @author Rishi Sharma
    * @date   14-Jun-2021
    * @description: Method to update Last Marketing Date on Campaign Members After Delete
    * @Param lstCampaignMember: list of Campaign Members.
    * @return:None
    */

/*    public static void populateLastMarketingCampaignDelete(List<CampaignMember> lstCampaignMembers){
        //CMSI-70
        ilib_LogEvent.push(LOG_TITLE + '.populateLastMarketingCampaignDelete()');
        Set<Id> setContacts = UtilsCollection.getSetOfIds(lstCampaignMembers , 'ContactId');
        Set<Id> setLeads = UtilsCollection.getSetOfIds(lstCampaignMembers , 'LeadId');
        Set<Id> setCampId = UtilsCollection.getSetOfIds(lstCampaignMembers , 'CampaignId');
        Set<Id> setCampaignMemberId = UtilsCollection.getSetOfIds(lstCampaignMembers, 'id');
        List<CampaignMember> lstCmAfter = new List<CampaignMember>();
        List<Campaign> lstCampRecord = new List<Campaign>();
        CampaignMemberSelector cmSelector = new CampaignMemberSelector();
        CampaignSelector campSelector = new CampaignSelector();
        Map<Id, String> mapCamptoOwnership = new Map<Id, String>();

        List<CampaignMember> lstCMember=new List<CampaignMember>();
        Map<id, List<CampaignMember>> mapCampIdtoMember =new Map<id, List<CampaignMember>>();

        //Get the Campaign organization ownership
        lstCampRecord = campSelector.selectCampaignOrganizationOwnership(setCampId);
        ilib_LogEvent.info('lstCampRecord :'+UtilsCollection.getSetOfIds(lstCampRecord));//CMSI-70
        mapCamptoOwnership = UtilsCollection.getMapOfIdToString(lstCampRecord, 'Id', 'Organization_Ownership__c');
        ilib_LogEvent.info('mapCamptoOwnership :'+mapCamptoOwnership);//CMSI-70


        //Get the Last Marketing Campaign and the Sales Campaign Members to be updated in Before Insert, After Insert and After Delete
        ilib_LogEvent.info('setLeads on delete:'+setLeads);//CMSI-70
        if(!setLeads.isEmpty()){
				lstCmAfter = cmSelector.selectCampaignMembersLead(setLeads, setCampaignMemberId);
         }
        ilib_LogEvent.info('setContacts on delete:'+setContacts);//CMSI-70
        if(!setContacts.isEmpty()){
           		lstCmAfter = cmSelector.selectCampaignMembersContact(setContacts, setCampaignMemberId);

        }

            for(CampaignMember cm:lstCampaignMembers){
              if(mapCamptoOwnership.get(cm.CampaignId) == STRMARKETING && cm.CampaignId == cm.Last_Marketing_Campaign__c){
                if(!setLeads.isEmpty()){
                    lstCMember = cmSelector.selectOrderedMarketingCampaignMembersLead(setLeads);
                 }
                if(!setContacts.isEmpty()){
                    lstCMember = cmSelector.selectOrderedMarketingCampaignMembersContact(setContacts);
                }
                    if(!lstCMember.isEmpty()){
                        mapCampIdtoMember.put(lstCMember[lstCMember.size()-1].CampaignId, lstCmAfter);
                    }
                    else{
                        mapCampIdtoMember.put(null, lstCmAfter);
                    }
                    }
            }

        //Passing mapCampIdtoMember to the queueable to populate the Last Marketing Campaign for Sales Campaign Members After Insert and After Delete
        ilib_LogEvent.info('mapCampIdtoMember :'+(!mapCampIdtoMember.isEmpty()? String.valueOf(mapCampIdtoMember.keySet()):MAPISEMPTY));//CMSI-70
        if(!mapCampIdtoMember.isEmpty()){
           		CampaignMemberLastMarketingQueueable cmUpdateLastMarketingCampaign;
          		cmUpdateLastMarketingCampaign = new CampaignMemberLastMarketingQueueable(mapCampIdtoMember);

                ilib_Queueablethread queueableThread = new ilib_Queueablethread('CampaignMember_CampaignMemberLastMarketingQueueable');
                queueableThread.logAndQueue(cmUpdateLastMarketingCampaign, 'CampaignMemberLastMarketingQueueable', STREXECUTE);
                ilib_QueueableManager.enqueueJob(queueableThread,ilib_LogEvent.MARKETING);
        }
        ilib_LogEvent.pop(); //CMSI-70

    } */

   /*
    * @author Nishan Shetty
    * @date   03-Jun-2021
    * @description: The method create Notes for associated Lead or Contact based on the Campaign Member Notes field.
    * @Param lstCampaignMember: list of Campaign Members.
    * @return:None
    */
   public void createNoteOnLeadOrContact(List<CampaignMember> lstCampaignMembers) {
    //CMSI-70
    ilib_LogEvent.push(LOG_TITLE + '.createNoteOnLeadOrContact()');
    List<ContentVersion> lstContentVersions=new List<ContentVersion>();
    Set<Id> setCampaignIds=new Set<Id>();


    for(CampaignMember objCampMember:lstCampaignMembers) {
         setCampaignIds.add(objCampMember.CampaignId);
    }

    Map<Id,Campaign> mapIdToCampaign = new Map<Id,Campaign>(new CampaignSelector().selectCampaigns(setCampaignIds));
    ilib_LogEvent.info('mapIdToCampaign :'+(!mapIdToCampaign.isEmpty()? String.valueOf(mapIdToCampaign.keySet()):MAPISEMPTY));//CMSI-70

    for(CampaignMember objCampMember:lstCampaignMembers) {
        if(!String.isBlank(objCampMember.Campaign_Member_Notes__c)) {
            lstContentVersions.add(new ContentVersion(Title='Campaign Member Note: '+mapIdToCampaign.get(objCampMember.CampaignId).Name,PathOnClient='Campaign Member Note:'+mapIdToCampaign.get(objCampMember.CampaignId).Name+'.snote',VersionData=Blob.valueOf(objCampMember.Campaign_Member_Notes__c),FirstPublishLocationId=UpdateNoteOnLeadOrContact.getLeadOrContactId(objCampMember)));
        }
    }
    if(!lstContentVersions.isEmpty()) {
        insert lstContentVersions;
    }
    ilib_LogEvent.message('lstContentVersions :'+UtilsCollection.getSetOfIds(lstContentVersions));//CMSI-70
    ilib_LogEvent.pop();
    }

    /*
    * Wrapper class for Prospect Scoring
    */
    public class CampaignMemberWrapper{
        public Prospect_Scoring_Log__c objProspectLog;
        public Boolean ScoreUpdated;
        public Integer FinalScore;

    }

    /*
    * Author - Rishab Wali
    * Method - [DCP-49756] Update Most Recent Activity Date Field on Lead
    */
    private static void populateMostRecentActivityOnLeads()
    {
        ilib_LogEvent.push(LOG_TITLE + '.populateMostRecentActivityOnLeads()');//CMSI-70
        List<CampaignMember> lstCampaignMembers = (List<CampaignMember>)trigger.new;
        Set<Id> setCampaignMemberIds = UtilsCollection.getSetOfIds(lstCampaignMembers,'Id');
        List<CampaignMember> lstCampaignMember = new List<CampaignMember>(new CampaignMemberSelector().selectCampaignMembers(setCampaignMemberIds));
        Map<Id,DateTime> mapLeadIdToMostRecentActivityDate = new Map<Id,DateTime>();
        Set<String> setAllowedStatusValues = new Set<String>{'Registered','Registered Contact Me','Registered - Contact Me','No Show','Clicked','Cancelled','Registered for Event','Registered to Webinar'};
        for(CampaignMember objCM : lstCampaignMember)
        {
            if(objCM.LeadId != null && (STRSALES.equalsIgnoreCase(objCM.Campaign.Organization_Ownership__c) || STRSERVICE.equalsIgnoreCase(objCM.Campaign.Organization_Ownership__c)))
            {
                CampaignMember objOldCampMember = new CampaignMember();
                if(trigger.isUpdate)
                {
                    objOldCampMember = (CampaignMember)Trigger.oldMap.get(objCM.Id);
                }
                if(trigger.isInsert || objOldCampMember.Status != objCM.Status)
                {
                    mapLeadIdToMostRecentActivityDate.put(objCM.LeadId,System.now());
                }
            }
            else if(objCM.LeadId != null && (STRMARKETING.equalsIgnoreCase(objCM.Campaign.Organization_Ownership__c) || STROPERATIONAL.equalsIgnoreCase(objCM.Campaign.Organization_Ownership__c)))
            {
                CampaignMember objOldCampMember = new CampaignMember();
                if(trigger.isUpdate)
                {
                    objOldCampMember = (CampaignMember)Trigger.oldMap.get(objCM.Id);
                }
                if((trigger.isInsert || objOldCampMember.Status != objCM.Status) && setAllowedStatusValues.contains(objCM.Status))
                {
                    mapLeadIdToMostRecentActivityDate.put(objCM.LeadId,System.now());
                }
            }
        }
        ilib_LogEvent.info('mapLeadIdToMostRecentActivityDate :'+mapLeadIdToMostRecentActivityDate);//CMSI-70
        if(!mapLeadIdToMostRecentActivityDate.isEmpty())
        {
            if(System.isBatch() || System.isFuture() || System.isQueueable() || System.isScheduled()) {
                updateMostRecentActivityValuesOnLeads(mapLeadIdToMostRecentActivityDate);
            }
            else {
                updateMostRecentActivityValuesOnLeadsSync(mapLeadIdToMostRecentActivityDate); //Calls future method when running from synchronous trigger context
            }
        }
        ilib_LogEvent.pop(); //CMSI-70
    }

    @future
    private static void updateMostRecentActivityValuesOnLeadsSync(Map<Id,DateTime> mapLeadIdToDateTimeValues)
    {
        ilib_LogEvent.info('Future Method - mapLeadIdToDateTimeValue :'+mapLeadIdToDateTimeValues);
        updateMostRecentActivityValuesOnLeads(mapLeadIdToDateTimeValues);
    }

    /*
    * Author - Rishab Wali
    * Method - [DCP-49756] DML on leads to update Most Recent Activity Field
    */
    private static void updateMostRecentActivityValuesOnLeads(Map<Id,DateTime> mapLeadIdToDateTimeValue)
    {
        //CMSI-70
        ilib_LogEvent.push(LOG_TITLE + '.updateMostRecentActivityValuesOnLeads()');
        ilib_LogEvent.info('mapLeadIdToDateTimeValue :'+mapLeadIdToDateTimeValue);
        List<Lead> lstLeadsToBeUpdates = new List<Lead>();
        for(Lead objLead : [SELECT Id,Most_Recent_Activity_Date__c FROM Lead WHERE Id In : mapLeadIdToDateTimeValue.keyset()])
        {
            if(mapLeadIdToDateTimeValue.get(objLead.Id) > objLead.Most_Recent_Activity_Date__c)
            {
                Lead newObjLead = new Lead(Id = objLead.Id);
                newObjLead.Most_Recent_Activity_Date__c = mapLeadIdToDateTimeValue.get(objLead.Id);
                lstLeadsToBeUpdates.add(newObjLead);
            }
        }

        try
        {
            Leads.changeTrigerredFromCampaignTrigger = true;
            ilib_LogEvent.info('lstLeadsToBeUpdates :'+UtilsCollection.getSetOfIds(lstLeadsToBeUpdates));//CMSI-70
            Update lstLeadsToBeUpdates;
        }
        Catch(Exception e)
        {
            ApexExceptions.emit('CampaignMembers.updateMostRecentActivityValuesOnLeads',e);
        }
    }
}