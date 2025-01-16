/**
*    @author: Pradeep Kumar Aera
*    @date:   21-Aug-2018
*    @description:  Pardot prospect resubscription trigger for Contact related to DCP-9637
*    Modification Log:
*    --------------------------------------------------------------------------------------------------
*          Developer           Date            Description
*          Joshith k           21-Sep-2019     Added After Insert logic
*          Pankaj Singla       01-Dec-2019     Added logic for hashed Email Id
*          Pankaj Singla       10-Dec-2019     DCP-31716 Added Logic for ULC Field population
*          Pankaj Singla       14-May-2020     DCP-35843 Added Recycled Changes for 0 Score
*          Todd                02-Jun-2020     use ilib queuable framework to chaing queueables
*          Prashanth           09-sep -2020    create before delete and after delete methods.
*          Monika              21-Sep-2020     DCP- 41969 Added logic when contact is active,deactivation reason & comment blank
*          KD                  11-Nov-2020     DCP-42122 : CP Quota Sharing
*          Rishab Wali         23-Aug-2021     [DCP-49613] - Contact Sync Error Fix.
*          Rishab Wali         15-Nov-2021     [DCP-50851] Clear Disposition Code when not recycled.
*          Deep Diwakar        17-Dec-2021     DCP-37684: Setting lead source for OpenQ/KOL contact record type
*          Deep Diwakar        10-Jan-2022     DCP-52030: Allowing Data Steward profile to merge contacts
*		   Maruthi B           02-Fab-2022     DCP-22: AfterInsert method is modified to invoke EmailVerificationQueueable
*          Maruthi B           02-Fab-2022     DCP-99: Afterupdate method is modified to invoke EmailVerificationQueueable
*          Saddam              08-Feb-2022     PM-57 : Created new method checkContactIsActive() and called this method inside beforeupdate method
*          Maruthi B           14-Mar-2022     PM-121: updated onBeforeDelete, handleNewACRRelns, handleExistingACRRelns methods to update Product Notification
*          Deep Diwakar        28-Feb-2022     DCP-52297: Hive9 - Funnel Leakage: Waterfall Stage Leakage Fixes
*          Rishab Wali         01-June-2022    DCP-52663: Skip scoring if Marketing Suppression is set to true
*          Mohammed Juned      12-July-2022    INC0408645: Shift the Profile and recordtype query from checkContactIsActive method to the calling path to  avoid governor limit
*          Preetha             13-Jun-2022     CMSI-70  Adding the Instrumentation for a class
*          Rishab Wali         20-July-2022    DCP-55950: Waterfall Stage update check to restrict date update
*          Preetha             08-July-2022    CMSI-51 added WorkStream
*          Deep Diwakar        01-Sept-2022    DCP-56403: Correcting setting of AQ date
*          Deep Diwakar        25-Sept-2022    PM-911: Updated After update method to call Pardot form hanlder when contact resignation field change
*          Maruthi B           08-Dec-2022     DCP-58830: Modified Before update method to set Email Opted Out from Pardot Opted Out values when it changes
*         Deep Diwakar         June-09-2023    DCP-60099: Corrected recursion check causing loss of contact updates
*         Deep Diwakar         July-11-2023    DCP-60096: Fixing bulk Pardot sync issue of contact resignation field by replacing queueable framework with platform event 
*         Deep Diwakar         Aug-04-2023     DCP-60130: Added FLS check bypass for Charket user so we can remove access at profile level
*         Deep Diwakar         Nov-01-2023     CMCM-1521: SFDC-ULC integration retirement, removing code related to this integration
*         Deep Diwakar         Nov-27-2023     CMCM-4856: Area of work field calculation
*         Deep Diwakar         Mar-06-2024     CMCM-5551: Replaced old Marketability logic with new Marketability Service 
*         Deep Diwakar        May-22-2024      CMCM-7994: Removed Cvent opt in logic as it is moved to new CventMarketability class
*         Deep Diwakar        June-10-2024     CMCM-6457: Added logic to handle merge operation for waterfall process
*         Deep Diwakar        Sept-03-2024     CMCM-9949: Added logic to handle empty waterfall stage for lead conversion scenario
*         Deep Diwakar        Dec-06-2024      CMCM-12466: Updated to handle new Hand Raise status
*         Deep Diwakar        Dec-16-2024      CMCM-12469: Updated to handle waterfall feature with new Hand Raise status
*    --------------------------------------------------------------------------------------------------
*/
public with sharing class Contacts extends ilib_SObjectDomain {

    public static final String CHARKET_USER_NAME = 'Charket User';
    public static final String CHARKET_GUEST_USER_NAME = 'WeChat Charket Site Guest User';
    public static boolean booTestRunning=false;
    public static final String STRING_RECYCLED_ACTION= 'Prospect Recycled';
    public static final String STRING_HIGH_VALUE_SCORING_ACTION='High Value Scoring';
    public static final Integer INT_MARKETING_RECYCLED_SCORE=0;
    public static final String STRING_CONTACT_STATUS_RECYCLED='Recycled';
	public static final String STRING_CONTACT_STATUS_ACCEPTED ='Accepted';
	public static final String STRING_CONTACT_STATUS_AQ='Automation Qualified';
	public static final String STRING_CONTACT_STATUS_DC='Data Check';
	public static final String STRING_CONTACT_STATUS_INQUIRY='Inquiry';
	public static final String STRING_CONTACT_STATUS_MQ='Marketing Qualified';
	public static final String STRING_CONTACT_STATUS_VALIDATED='Validated';

    // CMCM-12466: Added new status value
    private static final String STRING_CONTACT_STATUS_HAND_RAISE = 'Hand Raise';


    public static final Integer INT_HIGH_VALUE_SCORING_FACTOR=Integer.ValueOf(Label.High_Value_Scoring_factor);
  //DCP-40723
    public static Map<Id, String> mapContactRoles= new Map<Id, String>();
    public static boolean disableTriggerCRUDSecurityForDummyContactDeletion = false;

    public static boolean isLeadConversionInProgress=false;
    public static final integer INTEGERVALUEONE = 1;

	//PM-121
    public static Map<Id, String> mapContactPNC= new Map<Id, String>();

    // DCP-37684:Adding KOL specific values
    public static final String OPENQ_RECORD_TYPE_NAME = 'KOL';
    public static final String OPENQ_LEAD_SOURCE = 'Key Opinion Leader';
     //PM-57:Adding Field names and recordtype for checkContactIsActive()
     public static final String ACTIVE_FIELD = 'Is_Active__c';
     public static final String EMAIL_FIELD = 'Email';
     public static final String KOL_RECORD_TYPE_NAME = 'KOL';

     private static final String LOG_TITLE = 'Contacts';

    //PM-99 & PM-75
    private static Boolean isEmailChanged = false;
	public static final String STRING_EXECUTE ='execute';
    public static final String MAPISEMPTY = 'map is empty';
    public static boolean boolRecurseCheckBeforeUpdate = false; // DCP-56531

    //CMCM-6457: Static map to keep track of merge contacts
    private static Map<Id, Id> mapMergeWinIdToLooseId = new Map<Id, Id>();

    // CMCM-9949: List to store contact ids for which previous waterfall stage was empty
    public static List<Id> lstContIdsEmptyWaterfall = new List<Id>();

    /*Parameterised Constructor */
    public Contacts(List<Contact> sObjectList)
    {
        super(sObjectList);

        //bypass crud security if a dummy contact gets deleted.
         for(Contact contactObj : sObjectList){
        if (String.isNotBlank(contactObj.FirstName) && contactObj.FirstName.equalsIgnoreCase('dummy')){
        disableTriggerCRUDSecurityForDummyContactDeletion = true;
        break;
        }
        }

        if (FeatureManagement.checkPermission('Bypass_Person_Object_Permission') || disableTriggerCRUDSecurityForDummyContactDeletion){
            configuration.disableTriggerCRUDSecurity();
            // DCP-60130: Added FLS check bypass for Charket user so we can remove access at profile level
            ilib_SecurityUtils.bypassInternalFlsAndCrud = true;
        }
    }

    /*
    * Boilerplate which is required for base class instantiation logic
    */
    public class Constructor implements ilib_SObjectDomain.IConstructable
    {
        /*Param - List<sObject> */
        public ilib_SObjectDomain construct(List<SObject> sObjectList)
        {
            return new Contacts(sObjectList);
        }
    }

    /*Method - beforeInsert trigger event. */
    public override void onBeforeInsert()
    {
        List<Contact> lstTempContact = (List<Contact>) records;
        List<Contact> lstAOIList = new List<Contact>();

        for (Contact objContact : lstTempContact)
        {
            //DCP-37684:changes start here
            // Getting KOL contact record type id
            Id kolRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get(OPENQ_RECORD_TYPE_NAME).getRecordTypeId();
            ilib_LogEvent.message('kolRecordTypeId :'+kolRecordTypeId);//CMSI-70
            //Setting up lead source if it matches with KOL record type
            if (objContact.RecordTypeId == kolRecordTypeId) {
                objContact.LeadSource = OPENQ_LEAD_SOURCE;
            }
            // DCP-37684:changes end here

            if(objContact.Marketing_Score__c != null && objContact.Marketing_Score__c > 0.0) {
                objContact.Date_Of_Last_Score_Change__c=Datetime.now();
            }
            if(objContact.Area_Of_Interest__c != null && objContact.Area_Of_Interest__c != '') {
                lstAOIList.add(objContact);
            }

            //CMCM-5552: Moving pardot opted out value to SF opted out of email field
            if (objContact.Pardot_Opted_Out__c) {
                objContact.HasOptedOutOfEmail = objContact.Pardot_Opted_Out__c;
            }

            /*DCP- 41969 Changes start*/
            /*Contact Deactivation Reason & Deactivation Comment should be blank when Contact is Active*/
            if(objContact.Is_Active__c) {
                objContact.Deactivation_Reason__c='';
                objContact.Deactivation_Reason_Comment__c='';
            }
            /*DCP- 41969 Changes Ends*/

            /*Set Hashed Email Id field*/
            if(objContact.Email!=null)
            {
                String strEmail=objContact.Email.toLowerCase();
                Blob b = Crypto.generateDigest('SHA-256', Blob.valueOf(strEmail));
                objContact.Hashed_Email_Id__c=EncodingUtil.convertToHex(b);
            }

        }

        //CMCM-5551: New marketability implementation
        MarketabilityServiceFacade facade = new MarketabilityServiceFacade();
        facade.determineMarketability(records, 'global-v1');


        ilib_LogEvent.info('isLeadConversionInProgress :'+isLeadConversionInProgress);//CMSI-70
        if(!isLeadConversionInProgress){
            processStatusUpdate(Trigger.New);
        }
        if (!lstAOIList.isEmpty()) {
            setAOICheckboxes(lstAOIList);
        }

        //CMCM-4856: Instantiating decorator object to calculate area of work field
        ilib_SObjectDecorator aowDecorator = new AreaOfWorkContactDecorator(records);
        aowDecorator.decorate();
    }

    /*Method - afterInsert trigger event. */
    public override void onAfterInsert()
    {
        List<Contact> newContacts=(List<Contact>) records;
        List<Contact> listConWithEmailId=new List<Contact>();

     List<Contact> lstContactsForAutoTagging=new List<Contact>();
        List<Id> lstContactIdsForCharket = new List<Id>();
        for (Contact objCon : newContacts)
        {
            if (String.isNotBlank(objCon.Email)){
                listConWithEmailId.add(objCon);
            }

            if (booTestRunning || UserInfo.getName().equals(CHARKET_USER_NAME) || UserInfo.getName().equals(CHARKET_GUEST_USER_NAME)){
        if(String.isNotBlank(objCon.Email)){
          lstContactIdsForCharket.add(objCon.Id);
        }

        if(String.isNotBlank(objCon.Area_Of_Interest__c) || String.isNotBlank(objCon.Job_Function__c) ){
                    lstContactsForAutoTagging.add(objCon);
        }
      }

    }

        if (!listConWithEmailId.isEmpty())
        {
            SoftwareDownloadQueueableForSync objSoftwareDownloadQueableForSync = new SoftwareDownloadQueueableForSync(listConWithEmailId);
            // chain queueables fix start
            ilib_Queueablethread queueableThread = new ilib_Queueablethread('ContactAfterInsert');
			//Added as part of PM-22
			for(Contact conWithEmailId  : listConWithEmailId) {
				EmailVerificationQueueable objEmailVerificationQueueable = new EmailVerificationQueueable(conWithEmailId);
				queueableThread.logAndQueue(objEmailVerificationQueueable,'EmailVerificationQueueable',STRING_EXECUTE);
			}
			queueableThread.logAndQueue(objSoftwareDownloadQueableForSync, 'SoftwareDownloadQueueableForSync', STRING_EXECUTE);
			ilib_QueueableManager.enqueueJob(queueableThread);
			// chain queueables fix end
        }

        /*DCP-31716 changes end */
        ilib_LogEvent.info('lstContactIdsForCharket : '+lstContactIdsForCharket);//CMSI-70
        if (!lstContactIdsForCharket.isEmpty()){
            CharketUtils.processCharketContactSubmission(lstContactIdsForCharket, ilib_LogEvent.getTransactionId());
        }
        ilib_LogEvent.info('lstContactsForAutoTagging : '+UtilsCollection.getSetOfIds(lstContactsForAutoTagging));//CMSI-70
        if(!lstContactsForAutoTagging.isEmpty()){
            CharketUtils.processContactsForWeChatTagging(lstContactsForAutoTagging);
        }
  }

    /*Method - Trigger beforeUpdate Event
      Params - Map<Id,sObject>
    */
    public override void onBeforeUpdate(Map<Id, SObject> idToContact) {
        List<Contact> lstAOIList = new List<Contact>();
    	List<Prospect_Scoring_Log__c> lstProspectScoreLog=new List<Prospect_Scoring_Log__c>();

        //pm-57 starts
         //get Profile details to bypass
         Set<String>setCodeParamName=new Set<String>{'Bypass_Profile'};
        List<Code_Parameter__mdt> lstCodeParam=new CodeParametersSelector().selectCodeParameterByDeveloperName(setCodeParamName);
        List<String> bypassProfiles = lstCodeParam[0].value__c.split(',');
        ilib_LogEvent.message('bypassProfiles : '+bypassProfiles);//CMSI-70
        List<Profile> currentProfile = new ProfilesSelector().getProfilesById(new Set<Id>{UserInfo.getProfileId()});
        Boolean onlyLimitedUpdatesAllowed = false;
        if(!currentProfile.isEmpty()) { onlyLimitedUpdatesAllowed = !bypassProfiles.contains(currentProfile[0].Name); }
        ilib_LogEvent.message('currentProfile-->: '+currentProfile);
        //get recordtypeid to bypass
        Id kolRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get(KOL_RECORD_TYPE_NAME).getRecordTypeId();
        ilib_LogEvent.message('kolRecordTypeId-->: '+kolRecordTypeId);
          //pm-57ends

        Map<Id, Contact> mapLooserIdToWinnerObj = new Map<Id, Contact>();

        for (Id idContact : idToContact.keySet()) {
            Contact objNewContact = (Contact) Trigger.newMap.get(idContact);
            Contact objOldContact = (Contact) idToContact.get(idContact);

           //pm-57 starts passing new record ,oldrecord to mehtod
           if(onlyLimitedUpdatesAllowed) {
           checkContactIsActive(objNewContact,objOldContact,kolRecordTypeId);
           }
           //pm-57 ends
		   
		   //DCP-58830
            if(objNewContact.Pardot_Opted_Out__c != objOldContact.Pardot_Opted_Out__c) {
                objNewContact.HasOptedOutOfEmail = objNewContact.Pardot_Opted_Out__c;
            }

            Boolean boolStatusUpdated=false;

            //DCP-52297: Corrected check for lead status to set boolean value
            if(!isLeadConversionInProgress && objNewContact.Marketing_Contact_Status__c!=null && !objNewContact.Marketing_Contact_Status__c.equalsIgnoreCase(objOldContact.Marketing_Contact_Status__c)){
                boolStatusUpdated=true;     //DCP-49613
            }
           
            //INC0295852
            if(objNewContact.Bypass_Duplicates__c == true){
                objNewContact.Bypass_Duplicates__c = false;
            }
            if(objNewContact.Marketing_Score__c!=objOldContact.Marketing_Score__c){
                objNewContact.Date_Of_Last_Score_Change__c=Datetime.now();
            }

            if(objNewContact.Area_Of_Interest__c!=objOldContact.Area_Of_Interest__c){
                lstAOIList.add(objNewContact);
            }
      /*DCP- 41969 Changes start*/
            /*Contact Deactivation Reason & Deactivation Comment should be blank when Contact is Active*/
            if(objNewContact.Is_Active__c){
                objNewContact.Deactivation_Reason__c='';
                objNewContact.Deactivation_Reason_Comment__c='';
            }
            /*DCP- 41969 Changes Ends*/

            /*Set Hashed Email Id Field*/
            if(objNewContact.Email!=null && objNewContact.Email!=objOldContact.Email){
                String strEmail=objNewContact.Email.toLowerCase();
                Blob b = Crypto.generateDigest('SHA-256', Blob.valueOf(strEmail));
                objNewContact.Hashed_Email_Id__c = EncodingUtil.convertToHex(b);

            }
      /*DCP-35843 Changes Start*/
            if(objNewContact.Marketing_Contact_Status__c!=null && !isLeadConversionInProgress && objNewContact.Marketing_Contact_Status__c.equals(STRING_CONTACT_STATUS_RECYCLED) && !objNewContact.Marketing_Contact_Status__c.equals(objOldContact.Marketing_Contact_Status__c) && ProspectScoringUtils.boolPreventDuplicateRun ){
                Integer intPreviousScore=Integer.ValueOf(objOldContact.Marketing_Score__c);
                objNewContact.Marketing_Score__c=INT_MARKETING_RECYCLED_SCORE;
                objNewContact.Date_Of_Last_Score_Change__c =datetime.now();
                Prospect_Scoring_Log__c objProspectScoringLog=ProspectScoringUtils.createProspectScoringLogRecords(STRING_RECYCLED_ACTION,'',objNewContact.Id,UserInfo.getUserId(),'',intPreviousScore,INT_MARKETING_RECYCLED_SCORE);
                lstProspectScoreLog.add(objProspectScoringLog);
            }
            /*DCP-35843 Changes End*/

            /*DCP-35845 Changes Start*/
            if(objNewContact.pi__score__c!=objOldContact.pi__score__c && ProspectScoringUtils.boolPreventDuplicateRun && !objNewContact.Marketing_Suppression__c){
				Integer intPreviousScore=((Integer.ValueOf(objOldContact.Marketing_Score__c)!=null)?Integer.ValueOf(objOldContact.Marketing_Score__c):0);
				Integer intPreviousScoreCounterTemp=Integer.ValueOf(objOldContact.pi__score__c);
				Integer intCurrentScoreCounterTemp=Integer.ValueOf(objNewContact.pi__score__c);
                Integer intPreviousScoreCounter=((intPreviousScoreCounterTemp!=null && intPreviousScoreCounterTemp>0)?intPreviousScoreCounterTemp:0);
                Integer intCurrentScoreCounter=((intCurrentScoreCounterTemp!=null && intCurrentScoreCounterTemp>0)? intCurrentScoreCounterTemp:0);
                Integer intIncrementalScoreVal=(intCurrentScoreCounter-intPreviousScoreCounter)*INT_HIGH_VALUE_SCORING_FACTOR;
                if(intIncrementalScoreVal>0){
                    Integer intFinalScore=intIncrementalScoreVal+intPreviousScore;
                    objNewContact.Marketing_Score__c=intFinalScore;
                    objNewContact.Date_Of_Last_Score_Change__c =datetime.now();
                    Prospect_Scoring_Log__c objProspectScoringLog=ProspectScoringUtils.createProspectScoringLogRecords(STRING_HIGH_VALUE_SCORING_ACTION,'',objNewContact.Id,UserInfo.getUserId(),'',intPreviousScore,intFinalScore);
                    lstProspectScoreLog.add(objProspectScoringLog);
                }

            }
            /*DCP-35845 Changes End*/

            // CMCM-12469: Changed status from qualified -> Lead Converted With Opp
            Set<String> setSkipMarketingStatus = new Set<String>{'New','Lead Converted No Opp','Lead Converted With Opp',STRING_CONTACT_STATUS_RECYCLED};
            if(!setSkipMarketingStatus.contains(objNewContact.Marketing_Contact_Status__c) && objNewContact.Disposition_Code__c != '')
            {
               objNewContact.Disposition_Code__c = ''; //DCP-50851
            }

            //DCP-52297:Changes are in below code block. As part of this story, corrected multiple string checks and added few comments and indentation
            // Waterfall Changes Start here

            // CMCM-9949: check if previous state of contact waterfall stage field is empty. If so, then store it to later check in lead conversion scenarios
            // By default, lead conversion process brings Lead's waterfall stage to Contact's waterfall stage if contact's field value is empty. This creates
            // incorrect results for waterfall stage when Lead is converted to this type of contact. 
            // Storing contacts who had previous waterfall stage as empty helps during lead conversion to set correct waterfall stage.
            if (String.isBlank(objOldContact.Waterfall_Stage__c)) {
  
                ilib_LogEvent.message('storing contact ids for previously empty waterfall stage: ' + objOldContact.Id);
                lstContIdsEmptyWaterfall.add(objOldContact.Id);

            }
            // CMCM-6457: If lead conversion is in progress then skip waterfall calculation as it is done through Lead trigger
            ilib_LogEvent.message('contact before update method - isLeadConversionInProgress: ' + isLeadConversionInProgress);
            if (!isLeadConversionInProgress) {
                //CMCM-6457: Check if merge operation is in progress
                if (mapMergeWinIdToLooseId.keySet().contains(objNewContact.Id)) {
                    // this update is happening due to merge operation
                    ilib_LogEvent.message('adding for waterfall field merge');
                    mapLooserIdToWinnerObj.put(mapMergeWinIdToLooseId.get(objNewContact.Id), objNewContact); 
                        
                } else { 
                    // this is regular waterfall update
                    ilib_LogEvent.message('triggering regular waterfall field update');
                    calculateWaterfallValues(boolRecurseCheckBeforeUpdate, boolStatusUpdated, objNewContact, objOldContact);
                }
            }
            // Waterfall Changes end here
            //DCP-52297: Changes end here

        }

        //DCP-60099: Moved setting of recursion flag outside of loop. It should be per transaction, not per record.
        boolRecurseCheckBeforeUpdate = true;

        // CMCM-6457: Set waterfall value for merge operation
        ilib_LogEvent.info('mapLooserIdToWinnerObj size: ' + mapLooserIdToWinnerObj.size());
        if (!mapLooserIdToWinnerObj.isEmpty()) {
            ilib_LogEvent.info('triggering waterfall field merge');
            MktgWaterfallServiceHelper.mergeWaterfallLogic(mapLooserIdToWinnerObj);
        }

        //CMCM-5551: New marketability implementation
        MarketabilityServiceFacade facade = new MarketabilityServiceFacade();
        facade.determineMarketability(Trigger.new, 'global-v1');

        ilib_LogEvent.info('lstAOIList : '+UtilsCollection.getSetOfIds(lstAOIList));//CMSI-70
        if (!lstAOIList.isEmpty()) {
            setAOICheckboxes(lstAOIList);
        }
    /*DCP-35843 Changes Start*/
        if(!lstProspectScoreLog.isEmpty()){
            insert lstProspectScoreLog;
            ProspectScoringUtils.boolPreventDuplicateRun=false;
        }
        ilib_LogEvent.message('lstProspectScoreLog : '+UtilsCollection.getSetOfIds(lstProspectScoreLog));//CMSI-70
        /*DCP-35843 Changes End*/
        if(!isLeadConversionInProgress){
            processStatusUpdateNew(Trigger.New,Trigger.OldMap);
        }

        //CMCM-4856: Instantiating decorator object to calculate area of work field
        ilib_SObjectDecorator aowDecorator = new AreaOfWorkContactDecorator(records);
        aowDecorator.decorate(idToContact);
    }

    /**
     * @author: Deep Diwakar
     * @date: June-12-2024
     * @description: This method calculates waterfall values for given record
     * @param: boolRecurseCheckBeforeUpdate - boolean flag to check for recursion
     * @param: boolStatusUpdated - boolean flag for informing marketing contact status field is changed or not
     * @param: objNewContact - new state of the record
     * @param: objOldContact - old state of the record
     * @return: void
     */
    private void calculateWaterfallValues(Boolean boolRecurseCheckBeforeUpdate, boolean boolStatusUpdated, Contact objNewContact, Contact objOldContact) {

        Boolean boolClearWaterFallDates=false;


        //CMCM-12469: Set to collect lead statuses for engaged waterfall stage
        Set<String> setContactStatusEngaged = new Set<String> {'Hand Raise', 'Automation Qualified'};

        Set<String> setContactStatusQualified=new Set<String>{'Marketing Qualified'};

        Boolean boolLastRespondedDateUpdated = false;
        if (objNewContact.Last_Responded_Campaign_Date__c != objOldContact.Last_Responded_Campaign_Date__c && objNewContact.Last_Responded_Campaign_Date__c > System.now() - 365) {
            boolLastRespondedDateUpdated = true;
        }
        Set<String> setWaterFallStageClosedWonOpportunity=new Set<String>{'Closed Won','Opportunity'};
        Set<String> setWaterStageAcceptedClosedWonOpp=new Set<String>{'Sales Accepted','Closed Won','Opportunity'};

        ilib_LogEvent.message('boolLastRespondedDateUpdated: ' + boolLastRespondedDateUpdated);

        if (!boolRecurseCheckBeforeUpdate && boolStatusUpdated && STRING_CONTACT_STATUS_RECYCLED.equals(objNewContact.Marketing_Contact_Status__c)) {
            objNewContact.Waterfall_Stage__c='';
        } else if (!boolRecurseCheckBeforeUpdate && boolStatusUpdated && !setWaterFallStageClosedWonOpportunity.contains(objNewContact.Waterfall_Stage__c) && objNewContact.Marketing_Contact_Status__c.equals(STRING_CONTACT_STATUS_ACCEPTED) && (objNewContact.Waterfall_Engaged_Date__c!=null || objNewContact.Waterfall_Qualified_Date__c!=null)) {
            boolClearWaterFallDates = resetWaterfallFields(objNewContact, objOldContact);
            objNewContact.Waterfall_Sales_Accepted_Date__c=Datetime.now();
            objNewContact.Waterfall_Stage__c='Sales Accepted';
            objNewContact.Waterfall_Qualified_Date__c = objNewContact.Waterfall_Qualified_Date__c == null || boolClearWaterFallDates ? Datetime.now():objNewContact.Waterfall_Qualified_Date__c;
            objNewContact.Waterfall_Engaged_Date__c= objNewContact.Waterfall_Engaged_Date__c == null || boolClearWaterFallDates ? Datetime.now():objNewContact.Waterfall_Engaged_Date__c;
        } else if (!boolRecurseCheckBeforeUpdate && boolStatusUpdated && !setContactStatusQualified.contains(objOldContact.Marketing_Contact_Status__c) && setContactStatusQualified.contains(objNewContact.Marketing_Contact_Status__c) && !setWaterStageAcceptedClosedWonOpp.contains(objNewContact.Waterfall_Stage__c)) {
            boolClearWaterFallDates = resetWaterfallFields(objNewContact, objOldContact);
            objNewContact.Waterfall_Stage__c='Qualified';
            objNewContact.Waterfall_Qualified_Date__c=Datetime.now();
            objNewContact.Waterfall_Engaged_Date__c= objNewContact.Waterfall_Engaged_Date__c==null || boolClearWaterFallDates ? Datetime.now() : objNewContact.Waterfall_Engaged_Date__c;
        }  else if (!boolRecurseCheckBeforeUpdate && boolStatusUpdated && !setContactStatusEngaged.contains(objOldContact.Marketing_Contact_Status__c)
                && setContactStatusEngaged.contains(objNewContact.Marketing_Contact_Status__c) && String.isBlank(objNewContact.Waterfall_Stage__c)) {

                //CMCM-12469: Adding engaged waterfall stage when contact status is either Hand Raise or AQ
                boolClearWaterFallDates = resetWaterfallFields(objNewContact, objOldContact);
                objNewContact.Waterfall_Stage__c='Engaged';
                objNewContact.Waterfall_Engaged_Date__c=Datetime.now();
        }

        if (boolLastRespondedDateUpdated && String.isBlank(objNewContact.Waterfall_Stage__c) && objNewContact.Last_Responded_Campaign_Date__c!=null && (objNewContact.Date_Status_Set_As_Recycled__c==null || Date.valueOf(objNewContact.Last_Responded_Campaign_Date__c)>objNewContact.Date_Status_Set_As_Recycled__c)) {
            boolClearWaterFallDates = resetWaterfallFields(objNewContact, objOldContact);
            objNewContact.Waterfall_Stage__c='Engaged';
            objNewContact.Waterfall_Engaged_Date__c=Datetime.now();
        }

    }

    /**
     * @author: Deep Diwakar
     * @date: June-12-2024
     * @description: This method resets waterfall fields if old value is blank
     * @param: objNewContact - new state of the record
     * @param: objOldContact - old state of the record
     * @return: void
     */
    private Boolean resetWaterfallFields(Contact objNewContact, Contact objOldContact) {
        Boolean isCleared = false;

        if(String.isBlank(objOldContact.Waterfall_Stage__c)) {
            objNewContact.Waterfall_Engaged_Date__c=null;
            objNewContact.Waterfall_Qualified_Date__c=null;
            objNewContact.Waterfall_Sales_Accepted_Date__c=null;
            objNewContact.Waterfall_Opportunity_Date__c=null;
            objNewContact.Waterfall_Closed_Won_Date__c=null;
            isCleared=true;
        }

        return isCleared;

    }
    /*
    * @author Pankaj Singla
    * @date   22-Mar-2021
    * Description: Method is called to update the status dates based on contact status
    * @param:lstContacts- the list of contacts as part of update trigger
    * @param mapOldContacts- Map of Old Records in Trigger.
    */
    public static void processStatusUpdateNew(List<SObject> lstContacts,Map<id,SObject> mapOldContacts){
        //CMSI-70
        ilib_LogEvent.push(LOG_TITLE + '.processStatusUpdateNew()');
        for(Contact objCon:(List<Contact>)lstContacts){
            Contact objOldContact=(Contact)mapOldContacts.get(objCon.Id);
            Boolean boolStatusUpdated = false;
            if(objCon.Marketing_Contact_Status__c != objOldContact.Marketing_Contact_Status__c){
                boolStatusUpdated = true;
            }
            ilib_LogEvent.info('boolStatusUpdated : '+boolStatusUpdated);//CMSI-70
            if(boolStatusUpdated){
                objCon.Date_Of_Last_Status_Change__c=Date.Today();
                if(STRING_CONTACT_STATUS_RECYCLED.equals(objCon.Marketing_Contact_Status__c)) {
                    objCon.Is_Recycled__c=true;
                    objCon.Date_Status_Set_As_Recycled__c=Date.Today();
                    objCon.Date_Status_Set_As_Accepted__c=null;
                    objCon.Date_Status_Set_As_Automation_Qualified__c=null;
                    objCon.Date_Status_Set_As_Data_Check__c=null;
                    objCon.Date_Status_Set_As_Inquiry__c=null;
                    objCon.Date_Status_Set_As_Marketing_Qualified__c=null;
                    objCon.Date_Status_Set_As_Validated__c=null;
                    // CMCM-12466: Reset date for recycled status
                    objCon.Date_Status_Set_As_Hand_Raise__c = null;

                } else if(objCon.Marketing_Contact_Status__c != null && objCon.Marketing_Contact_Status__c.equals(STRING_CONTACT_STATUS_ACCEPTED)){
                    objCon.Date_Status_Set_As_Accepted__c=Date.Today();
                }
                //DCP-56403: Correcting setting of AQ date
                else if(STRING_CONTACT_STATUS_AQ.equals(objCon.Marketing_Contact_Status__c)){
                    objCon.Date_Status_Set_As_Automation_Qualified__c=Date.Today();
                }
                else if(STRING_CONTACT_STATUS_DC.equals(objCon.Marketing_Contact_Status__c)){
                    objCon.Date_Status_Set_As_Data_Check__c=Date.Today();
                }
                else if(STRING_CONTACT_STATUS_INQUIRY.equals(objCon.Marketing_Contact_Status__c)){
                    objCon.Date_Status_Set_As_Inquiry__c=Date.Today();
                } else if (STRING_CONTACT_STATUS_HAND_RAISE.equals(objCon.Marketing_Contact_Status__c)) {
                    //CMCM-12466: if status is Hand Raise then set corresponding date
                    objCon.Date_Status_Set_As_Hand_Raise__c = Date.today();
                }
                else if(STRING_CONTACT_STATUS_MQ.equals(objCon.Marketing_Contact_Status__c)){
                    objCon.Date_Status_Set_As_Marketing_Qualified__c=Date.Today();
                }
                else if(STRING_CONTACT_STATUS_VALIDATED.equals(objCon.Marketing_Contact_Status__c)){
                    objCon.Date_Status_Set_As_Validated__c=Date.Today();
                }
            }
        }
        ilib_LogEvent.pop();  //CMSI-70
    }
    /*
    * @author Pankaj Singla
    * @date   22-Mar-2021
    * Description: Method is called to update the status dates based on contact status
    * @param:lstContacts- the list of contacts as part of insert trigger
    */
    public static void processStatusUpdate(List<Contact> lstContacts){
        ilib_LogEvent.push(LOG_TITLE + '.processStatusUpdate()');//CMSI-70
        for(Contact objCon:lstContacts){
            objCon.Date_Of_Last_Status_Change__c=Date.Today();
            ilib_LogEvent.message('Marketing_Contact_Status__c : '+objCon.Marketing_Contact_Status__c);//CMSI-70
            if(objCon.Marketing_Contact_Status__c != null){
            if(objCon.Marketing_Contact_Status__c.equals('Recycled')) {
                objCon.Is_Recycled__c=true;
                objCon.Date_Status_Set_As_Recycled__c=Date.Today();
                objCon.Date_Status_Set_As_Accepted__c=null;
                objCon.Date_Status_Set_As_Automation_Qualified__c=null;
                objCon.Date_Status_Set_As_Data_Check__c=null;
                objCon.Date_Status_Set_As_Inquiry__c=null;
                objCon.Date_Status_Set_As_Marketing_Qualified__c=null;
                objCon.Date_Status_Set_As_Validated__c=null;
                // CMCM-12466: Reset date for recycled status
                objCon.Date_Status_Set_As_Hand_Raise__c = null;
            } else if(objCon.Marketing_Contact_Status__c.equals(STRING_CONTACT_STATUS_ACCEPTED)){
                objCon.Date_Status_Set_As_Accepted__c=Date.Today();
            }
            else if(objCon.Marketing_Contact_Status__c.equals('Automation Qualified')){
                objCon.Date_Status_Set_As_Automation_Qualified__c=Date.Today();
            }
            else if(objCon.Marketing_Contact_Status__c.equals('Data Check')){
                objCon.Date_Status_Set_As_Data_Check__c=Date.Today();
            }
            else if(objCon.Marketing_Contact_Status__c.equals('Inquiry')){
                objCon.Date_Status_Set_As_Inquiry__c=Date.Today();
            } else if (STRING_CONTACT_STATUS_HAND_RAISE.equals(objCon.Marketing_Contact_Status__c)) {
                //CMCM-12466: if status is Hand Raise then set corresponding date
                objCon.Date_Status_Set_As_Hand_Raise__c = Date.today();
            }
            else if(objCon.Marketing_Contact_Status__c.equals('Marketing Qualified')){
                objCon.Date_Status_Set_As_Marketing_Qualified__c=Date.Today();
            }
            else if(objCon.Marketing_Contact_Status__c.equals('Validated')){
                objCon.Date_Status_Set_As_Validated__c=Date.Today();
            }
        }
        }
        ilib_LogEvent.pop(); //CMSI-70
    }
    private void setAOICheckboxes(List<Contact> lstContacts)
    {
        ilib_LogEvent.push(LOG_TITLE + '.setAOICheckboxes()');//CMSI-70
        List<String> lstpickListValuesList= new List<String>(); // List to store AOI picklist values
        List<String> lstAOIFieldAPINames=new list<String>(); // List to store API names for AOI checkoxes fields
        Schema.DescribeFieldResult fieldResult =Contact.Area_Of_Interest__c.getDescribe();
        ilib_LogEvent.info('fieldResult : ' +fieldResult);//CMSI-70
        List<Schema.PicklistEntry> lstPle = fieldResult.getPicklistValues();
        ilib_LogEvent.info('lstPle : ' +lstPle);//CMSI-70
        /* map<string,Area_Of_Interest_MetaData__mdt> mapAOIMetadata=new map<String,Area_Of_Interest_MetaData__mdt>(); */
        map<String,String> mapAreaOfInterestValueFieldAPIName=new map<String,String>(); //map to store picklist value and corresponding field API Name
        // Get All the picklist values for AOI field
        for (Schema.PicklistEntry pickListVal : lstPle){
            lstpickListValuesList.add(pickListVal.getLabel()); }
        ilib_LogEvent.info('lstpickListValuesList : ' +lstpickListValuesList);//CMSI-70

        for (String strpick : lstpickListValuesList)
        {
            List<String> lstTemp=new List<String>();
            String strTempStore=strpick;
            String strFinalAPIName='AOI';
            strpick=strpick.replace('/',' ');
            lstTemp=strpick.split(' ');
            if(lstTemp.size() == INTEGERVALUEONE )
            {
                strFinalAPIName=strFinalAPIName+'_'+strpick+'__c';
            }
            else
            {
                for (String strPickValSplit : lstTemp)
                {
                    strFinalAPIName=strFinalAPIName+'_';
                    strFinalAPIName=strFinalAPIName+strPickValSplit;
                }
                strFinalAPIName=strFinalAPIName+'__c';

            }
            lstAOIFieldAPINames.add(strFinalAPIName);
            mapAreaOfInterestValueFieldAPIName.put(strTempStore,strFinalAPIName);
        }
        ilib_LogEvent.info('lstAOIFieldAPINames : ' +lstAOIFieldAPINames);//CMSI-70
        ilib_LogEvent.info('mapAreaOfInterestValueFieldAPIName : ' +mapAreaOfInterestValueFieldAPIName);//CMSI-70

        for (Contact objCon : lstContacts)
        {
            for (String strpickValAPINames : lstAOIFieldAPINames) {
                objCon.put(strpickValAPINames,false);
            }

            if(objCon.Area_Of_Interest__c!=null && ObjCon.Area_Of_Interest__c!='')
            {
                List<String> lstAOISelected=oBjCon.Area_Of_Interest__c.split(';');
                for (String strAOISelected : lstAOISelected)
                {
                    if (mapAreaOfInterestValueFieldAPIName.containsKey(strAOISelected)){
                        objCon.put(mapAreaOfInterestValueFieldAPIName.get(strAOISelected),true); }
                }
            }
        }
        //CMSI-70
        ilib_LogEvent.pop();
    }

    /*
    * @author Pankaj Singla
    * @date   03-Jan-2020
    * @param: idToContact map of Old Contact Id to Contact Record
    * After update trigger method
    */
    public override void onAfterUpdate(Map<Id, SObject> idToContact)
    {

        List<Id> lstContactIdsForCharket=new List<Id>();
    //DCP-39969
        Set<Id> setReparentedPartnerContact = new Set<Id>();
        Set<Id> setContactHardBouncedIds = new Set<Id>();
        Set<Id> setContactIdsForAccounts = new Set<Id>();
		Boolean boolIsChangedAOI=false;
        Boolean boolIsChangedJobFunction=false;
		List<Contact> lstContactForAutoTagging=new List<Contact>();
		//PM-99 : Email Verification on update
        ilib_Queueablethread queueableThread = new ilib_Queueablethread('ContactAfterUpdate');

        //DCP-60096: List to hold resignation sync platform events
      
        //DCP-60096: List to hold resignation sync platform events

        List<PardotContactResignationSync__e> lstPardotResigSync = new List<PardotContactResignationSync__e>(); 

        for (Id idContact : idToContact.keySet())
        {
            Contact objNewContact = (Contact) Trigger.newMap.get(idContact);
            Contact objOldContact = (Contact) idToContact.get(idContact);

			boolIsChangedAOI= String.isNotBlank(objNewContact.Area_Of_Interest__c) && !objNewContact.Area_Of_Interest__c.equals(objOldContact.Area_Of_Interest__c);
            boolIsChangedJobFunction=String.isNotBlank(objNewContact.Job_Function__c) && !objNewContact.Job_Function__c.equals(objOldContact.Job_Function__c);

            if (objNewContact.pi__pardot_hard_bounced__c != objOldContact.pi__pardot_hard_bounced__c && objNewContact.pi__pardot_hard_bounced__c == TRUE){ //CMCM-704
                setContactHardBouncedIds.add(objNewContact.Id);
            }

            Boolean isUserCharket = UserInfo.getName().equals(CHARKET_USER_NAME) || UserInfo.getName().equals(CHARKET_GUEST_USER_NAME);
            Boolean didEmailChange = String.isNotBlank(objNewContact.Email) && !objNewContact.Email.equals(objOldContact.Email);
            if ((booTestRunning || isUserCharket) && didEmailChange)
            {
                lstContactIdsForCharket.add(objNewContact.Id);
            }
			if((booTestRunning || isUserCharket) && (boolIsChangedAOI || boolIsChangedJobFunction ) ){
                lstContactForAutoTagging.add(objNewContact);
            }
			//39969
			if(objNewContact.AccountId != null && objNewContact.AccountId != objOldContact.AccountId){
               setContactIdsForAccounts.add(objNewContact.Id);
            }
            // DCP-42122 : CP Quota Sharing
            if((objNewContact.AccountId != null && objNewContact.AccountId != objOldContact.AccountId) ||
                    (objNewContact.Is_Community_User__c && !objOldContact.Is_Community_User__c)){
                setReparentedPartnerContact.add(objNewContact.Id);
			}
			//PM-99 : Email Verification on update
            if(String.isNotBlank(objNewContact.Email) && !objNewContact.Email.equals(objOldContact.Email)) {
                EmailVerificationQueueable objEmailVerificationQueueable = new EmailVerificationQueueable(objNewContact);
                queueableThread.logAndQueue(objEmailVerificationQueueable,'EmailVerificationQueueable','execute');
				isEmailChanged = true;
            }

            // PM-911: Pardot resigation notification check
            if (objNewContact.Resigned_R_Q__c && objNewContact.Resigned_R_Q__c != objOldContact.Resigned_R_Q__c) {

                // DCP-60096: Replaced queueable framework implementation with platform event.
                // Current Illumina queueable framework doesn't support multiple callouts.
                PardotContactResignationSync__e resigEvent = new PardotContactResignationSync__e(Contact_Email__c = objNewContact.email);
                lstPardotResigSync.add(resigEvent);
            }
        }
        ilib_LogEvent.info('setContactHardBouncedIds : ' +setContactHardBouncedIds);//CMCM-704
        if(!setContactHardBouncedIds.isEmpty()){ 
            UpdateHardBouncedConQueueable hardBouncedQueueable = new UpdateHardBouncedConQueueable(setContactHardBouncedIds);
            queueableThread.logAndQueue(hardBouncedQueueable,'UpdateHardBouncedConQueueable','execute');
        }
        //PM-99 & PM-75 : Email Verification on update
        ilib_LogEvent.info('isEmailChanged : ' +isEmailChanged);//CMSI-70
        if(isEmailChanged) {
            //ilib_QueueableManager.enqueueJob(queueableThread,ilib_LogEvent.MARKETING);
        }

        // PM-911: Combining all queueables of this method and enqueueing at one place
        if(queueableThread != null && !queueableThread.lstQueueableJobs.isEmpty()){
            ilib_LogEvent.info('Enqueue all after update queueables');
            ilib_QueueableManager.enqueueJob(queueableThread);
        }

        // DCP-42122 : CP Quota Sharing
        ilib_LogEvent.info('setReparentedPartnerContact : ' +setReparentedPartnerContact);//CMSI-70
        if(!setReparentedPartnerContact.isEmpty()){
            reShareCPQuota(setReparentedPartnerContact);

        }

        ilib_LogEvent.info('lstContactIdsForCharket : ' +lstContactIdsForCharket);//CMSI-70
        if (!lstContactIdsForCharket.isEmpty()) {
            CharketUtils.processCharketContactSubmission(lstContactIdsForCharket, ilib_LogEvent.getTransactionId());

        }
        ilib_LogEvent.info('lstContactForAutoTagging : ' +UtilsCollection.getSetOfIds(lstContactForAutoTagging));//CMSI-70
  if(!lstContactForAutoTagging.isEmpty()){
                CharketUtils.processContactsForWeChatTagging(lstContactForAutoTagging);
        }
        //DCP-39969
        ilib_LogEvent.info('setContactIdsForAccounts : ' +setContactIdsForAccounts);//CMSI-70
        if(!setContactIdsForAccounts.isEmpty()){
        updateAccountContactRelations(setContactIdsForAccounts);
        }
        // DCP-60096: Publish platform events
        ilib_LogEvent.info('lstPardotResigSync: ' + lstPardotResigSync);
        if (!lstPardotResigSync.isEmpty()) {
            ilib_LogEvent.info('publishing events');
            EventBus.publish(lstPardotResigSync);
        }
    }

  /**
     * method: onBeforeDelete
     * params: none
     * Description: Before delete functionality for contact object DCP-40723
     **/
    public override void onBeforeDelete(){
        //map of deleting Contacts
        Map<Id, Contact> mapOldContacts = new Map<Id, Contact>((List<Contact>)records);
        //create a map of contactId,Roles to append them after the merge.
        for(AccountContactRelation acr : new AccountContactRelationsSelector().getAccConRelationByContact(mapOldContacts.keySet())){
            if(String.isNotBlank(acr.Roles)){
                mapContactRoles.put(acr.ContactId, acr.Roles);
            }if(String.isNotBlank(acr.Product_Notifications_Categories__c)){ //PM-121
                mapContactPNC.put(acr.contactId, acr.Product_Notifications_Categories__c);
            }
        }

        ilib_LogEvent.info('mapContactRoles :'+(!mapContactRoles.isEmpty()? String.valueOf(mapContactRoles.keySet()):MAPISEMPTY));//CMSI-70

    }
  /**
     * method: onAfterDelete
     * params: none
     * Description: After delete functionality for contact object DCP-39969
     **/
    public override void onAfterDelete(){
        //list of deleting Contacts
        List<Contact> lstDeletedContacts = (List<Contact>)records;

        //set of master contact Ids
        Set<Id> setMasterContactIds = new Set<Id>();
        //existing account contact relations
        Map<String,AccountContactRelation> mapExistingRelations = new Map<String,AccountContactRelation>();

        Map<Id,contact> mapMasterContacts = new Map<Id,Contact>();
        Set<Id> setAccountIds = new Set<Id>();
        //fetch masterrecord set
        for(Contact objContact : lstDeletedContacts){
            if(objContact.MasterRecordId != null && objContact.AccountId != null){
                setMasterContactIds.add(objContact.MasterRecordId);
                setAccountIds.add(objContact.AccountId);
            }

            //CMCM-6457: Storing deleted and winner record id for determing waterfall value in merge operation
            if (String.isNotBlank(objContact.MasterRecordId)) {
                mapMergeWinIdToLooseId.put(objContact.MasterrecordId, objContact.Id);
            }
        }
        ilib_LogEvent.info('setMasterContactIds : ' +setMasterContactIds);//CMSI-70
        ilib_LogEvent.info('after delete mapMergeWinIdToLooseId: ' + mapMergeWinIdToLooseId);
        if(!setMasterContactIds.isEmpty()){
            //get the ultimate parent id on account to check if the winner and looser contact's are related to same account hierarchy.
            Map<Id,Account> mapUltimateParents = new Map<Id,Account>(new AccountsSelector().selectAccounts(setAccountIds));
            for(Contact con : new ContactsSelector().returnContactWithACRDetails(setMasterContactIds)){
                //map of contact Id to Contact
                mapMasterContacts.put(con.Id,con);
                for(AccountContactRelation relation : con.AccountContactRelations){
                    //map of existing account contact relations
                    mapExistingRelations.put(relation.AccountId+''+relation.ContactId, relation);
                }
            }

            //CMSI-70 starts
            ilib_LogEvent.info('lstDeletedContacts : ' +UtilsCollection.getSetOfIds(lstDeletedContacts));
            ilib_LogEvent.info('mapMasterContacts :'+(!mapMasterContacts.isEmpty()? String.valueOf(mapMasterContacts.keySet()):MAPISEMPTY));
            ilib_LogEvent.info('mapExistingRelations : ' +mapExistingRelations);
            ilib_LogEvent.info('mapUltimateParents :'+(!mapUltimateParents.isEmpty()? String.valueOf(mapUltimateParents.keySet()):MAPISEMPTY));

            //CMSI-70 ends
            createAccountContactRelationsOnMerge(lstDeletedContacts,mapMasterContacts, mapExistingRelations, mapUltimateParents);
        }

    }
    /*CMSI-51
    * method will return the workstream
    */
    public override string getWorkstream(){
        return ilib_LogEvent.MARKETING;
    }
    /**
     * Method:updateAccountContactRelations
     * Params:Set <Id>
     * return: void
     * Description: This method will update account contact relations as active for the direct relation(current account).DCP-39969
     **/
    public static void updateAccountContactRelations(Set<Id> setContactIds){
        ilib_LogEvent.push(LOG_TITLE + '.updateAccountContactRelations()');//CMSI-70
        List<AccountContactRelation> lstAccountContactRelations = new AccountContactRelationsSelector().getDirectAccConRelationByContact(setContactIds);
		ilib_LogEvent.info('lstAccountContactRelations : ' +UtilsCollection.getSetOfIds(lstAccountContactRelations));//CMSI-70
        if(!lstAccountContactRelations.isEmpty()){
            for(AccountContactRelation relation : lstAccountContactRelations){
                relation.IsActive = true;
            }
            update lstAccountContactRelations;
        }
        ilib_LogEvent.pop();//CMSI-70

    }


   /**
     * Method:createAccountContactRelationsOnMerge
     * Description : This method is to create inactive,indirect accountcontactRelation on merging the contact DCP-39969
     * params: list of looser contacts, map of winner contacts, map of existing ACR
     **/
    public static void createAccountContactRelationsOnMerge(List<Contact> lstDeletedContacts, Map<Id,Contact> mapMasterContacts, Map<String,AccountContactRelation> mapExistingRelations, Map<Id, Account> mapUltimateParents){
        ilib_LogEvent.push(LOG_TITLE + '.createAccountContactRelationsOnMerge()'); //CMSI-70
        //Map of AccountId and AccountContact relations to insert
        Map<Id,AccountContactRelation> newMapAccountRelations = new Map<Id,AccountContactRelation>();
        //exting account contact relation to update
        Map<Id, AccountContactRelation> mapUpdateExistingRelations = new Map<Id, AccountContactRelation>();

        //List<String> lstprofiles = new List<String>{System.Label.ProfileDataSteward, System.Label.SalesRepProfileName};

        List<Profile> currentProfile = new ProfilesSelector().getProfilesById(new Set<Id>{UserInfo.getProfileId()});
        ilib_LogEvent.info('currentProfile : ' +UtilsCollection.getSetOfIds(currentProfile));//CMSI-70
        //DCP-52030: Changes for allowing multiple profiles to do contact merge
        List<Contact_Merge_Inclusion_List__mdt> allowedMergeProfiles =  [Select Id, Profile_Name__c From Contact_Merge_Inclusion_List__mdt];
        Set<String> mergeProfileList = new Set<String>();
        ilib_LogEvent.info('mergeProfileList : ' +mergeProfileList);//CMSI-70
        for (Contact_Merge_Inclusion_List__mdt mergeProfile : allowedMergeProfiles) {
            mergeProfileList.add(mergeProfile.Profile_Name__c);
        }

        for(Contact objContact : lstDeletedContacts){
            if(objContact.MasterRecordId != null && mapMasterContacts.containsKey(objContact.MasterRecordId)){
                if((!validLooserContact(objContact, mapMasterContacts) || (objContact.PGUID__c != null) || (mapUltimateParents.containsKey(objContact.AccountId) && mapUltimateParents.get(objContact.AccountId).Ultimate_Parent_Id__c != mapMasterContacts.get(objContact.MasterRecordId).Account.Ultimate_Parent_Id__c))
                      && !mergeProfileList.contains(currentProfile[0].Name)){
                    objContact.addError(System.Label.Contact_Merge_Error_Message);
                }else{
                    //existing relations
                    if(mapExistingRelations.containsKey(objContact.AccountId+''+objContact.MasterRecordId)){
                        AccountContactRelation relationToUpdate = mapExistingRelations.get(objContact.AccountId+''+objContact.MasterRecordId);
                        mapUpdateExistingRelations = handleExistingACRRelns(objContact, mapContactRoles, mapContactPNC, relationToUpdate);
                    }else{
                        //transfer the Account contact relations if they are not exist on master contact.
                        newMapAccountRelations = handleNewACRRelns(objContact, mapContactRoles, mapContactPNC);
                    }
                }
            }
        }
        //CMSI-70
        ilib_LogEvent.info('newMapAccountRelations :'+(!newMapAccountRelations.isEmpty()? String.valueOf(newMapAccountRelations.keySet()):MAPISEMPTY));
        if(!newMapAccountRelations.isEmpty()){
            insert newMapAccountRelations.values();
        }
        //CMSI-70
        ilib_LogEvent.info('mapUpdateExistingRelations :'+(!mapUpdateExistingRelations.isEmpty()? String.valueOf(mapUpdateExistingRelations.keySet()):MAPISEMPTY));
        if(!mapUpdateExistingRelations.isEmpty()){
            update mapUpdateExistingRelations.values();
        }
        //CMSI-70
        ilib_LogEvent.pop();
    }
    /**
     * Method:validLooserContact
     * Description : This method is to validate the contacts if it is good to be a looser contact on merge. We should not merge contact with IsCommunityUser,My Illumina user,KOL record type.
     * params: Boolean
     **/
    public static Boolean validLooserContact(Contact objContact, Map<Id, Contact> mapMasterContacts){
        Id kolRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('KOL').getRecordTypeId();
        Boolean isValidLooser = true;
        if((objContact.recordTypeId == KOLRecordTypeId) || (objContact.Is_MyIllumina_User__c == true) || (objContact.Is_Community_User__c == true) || (objContact.Email != null && mapMasterContacts.get(objContact.MasterRecordId).Email != null && objContact.Email != mapMasterContacts.get(objContact.MasterRecordId).Email)){
            isValidLooser = false;
        }
        ilib_LogEvent.message('isValidLooser : ' +isValidLooser);//CMSI-70
        return isValidLooser;
    }
  /**
    * method: handleACROnMerge
    * Description: this method is to create new account contact relations on merge.
    * params: contact object, map <Id,String> mapContactRoles, Map<Id,String> mapContactPNC
    * return : map<Id,AccountContactRelation>
    **/
    public static Map<Id, AccountContactRelation> handleNewACRRelns(Contact objContact, Map<Id,String> mapContactRoles, Map<Id,String> mapContactPNC){
        Map<Id,AccountContactRelation> newMapAccountRelations = new Map<Id,AccountContactRelation>();
        if(newMapAccountRelations.containsKey(objContact.AccountId)) {
            AccountContactRelation existingRelation = newMapAccountRelations.get(objContact.AccountId);
            String roles =  mapContactRoles.containsKey(objContact.Id) ? (String.isNotBlank(existingRelation.Roles) ? (existingRelation.Roles +';'+mapContactRoles.get(objContact.Id)) : mapContactRoles.get(objContact.Id)) : existingRelation.Roles;
            String productNotificationCategories =  mapContactPNC.containsKey(objContact.Id) ? (String.isNotBlank(existingRelation.Product_Notifications_Categories__c) ? (existingRelation.Product_Notifications_Categories__c +';'+mapContactPNC.get(objContact.Id)) : mapContactPNC.get(objContact.Id)) : existingRelation.Product_Notifications_Categories__c; //PM-121
            existingRelation.Roles = getRoles(roles);
            existingRelation.Product_Notifications_Categories__c = getRoles(productNotificationCategories); //PM-121
        } else {
            //create relation between looser concact's Account and winner contact.
            AccountContactRelation relation = new AccountContactRelation();
            relation.ContactId = objContact.MasterRecordId;
            relation.AccountId = objContact.AccountId;
            relation.IsActive = false;
            String roles = mapContactRoles.containsKey(objContact.Id) ? mapContactRoles.get(objContact.Id) : relation.Roles;
            String productNotificationCategories = mapContactPNC.containsKey(objContact.Id) ? mapContactPNC.get(objContact.Id) : relation.Product_Notifications_Categories__c;//PM-121
            relation.Roles = getRoles(roles);
            relation.Product_Notifications_Categories__c = getRoles(productNotificationCategories); //PM-121
            newMapAccountRelations.put(objContact.AccountId,relation);
        }
        //CMSI-70
        ilib_LogEvent.message('newMapAccountRelations :'+(!newMapAccountRelations.isEmpty()? String.valueOf(newMapAccountRelations.keySet()):MAPISEMPTY));

        return newMapAccountRelations;
    }
  /**
    * Method: getRoles
    * Description: This method helps to remove duplicate values from roles picklist while assigning and returns unique values.
    * params: string roles
    * return String
    **/

    public static String getRoles(String roles){
        String strRoles;
        ilib_LogEvent.info('roles : ' +roles);
        if(String.isNotBlank(roles)){
            List<String> lstRoles = roles.split(';');
            Set<String> setRoles = new Set<String>(lstRoles);
            lstRoles = new List<String>(setRoles);
            strRoles = String.join(lstRoles,';');
        }
         //CMSI-70
         ilib_LogEvent.info('strRoles : ' +strRoles);
        return strRoles;
    }
    /**
    * Method: handleExistingACRRelns
    * Description: This method helps to update the roles on existing relations.
    * params: contact object, map <Id, string> , accountcontactrelation
    * return Map<Id, AccountContactRelation>
    **/
    public static Map<Id, AccountContactRelation> handleExistingACRRelns(Contact objContact, Map<Id, String> mapContactRoles, Map<Id, String> mapContactPNC, AccountContactRelation relationToUpdate){
        Map<Id, AccountContactRelation> mapUpdateExistingRelations = new Map<Id, AccountContactRelation>();
        if(mapContactRoles.containsKey(objContact.Id)){
            String roles =  String.isNotBlank(relationToUpdate.Roles) ? relationToUpdate.Roles+';'+mapContactRoles.get(objContact.Id) : mapContactRoles.get(objContact.Id);
            relationToUpdate.Roles = getRoles(roles);
            if(mapUpdateExistingRelations.containsKey(relationToUpdate.Id)){
                AccountContactRelation existingRel = mapUpdateExistingRelations.get(relationToUpdate.Id);
                String finalRole = existingRel.Roles+';'+roles;
                existingRel.Roles = getRoles(finalRole);
            }else{
                mapUpdateExistingRelations.put(relationToUpdate.Id, relationToUpdate);

            }
        }
        if(mapContactPNC.containsKey(objContact.Id)) { //PM-121
            String productNotificationCategories =  String.isNotBlank(relationToUpdate.Product_Notifications_Categories__c) ? relationToUpdate.Product_Notifications_Categories__c+';'+mapContactPNC.get(objContact.Id) : mapContactPNC.get(objContact.Id);
            relationToUpdate.Product_Notifications_Categories__c = getRoles(productNotificationCategories);
            if(mapUpdateExistingRelations.containsKey(relationToUpdate.Id)){
                AccountContactRelation existingRel = mapUpdateExistingRelations.get(relationToUpdate.Id);
                String finalRole = existingRel.Product_Notifications_Categories__c+';'+productNotificationCategories;
                existingRel.Product_Notifications_Categories__c = getRoles(finalRole);
            } else {
                mapUpdateExistingRelations.put(relationToUpdate.Id, relationToUpdate);
            }
        }
        //CMSI-70
        ilib_LogEvent.message('mapUpdateExistingRelations :'+(!mapUpdateExistingRelations.isEmpty()? String.valueOf(mapUpdateExistingRelations.keySet()):MAPISEMPTY));
        return mapUpdateExistingRelations;

    }
    // Quota Sharing
    /* @author     : KD
     * @param      : Set of updated contact
     * @return     : N/A
     * @Description: Method to share CP Quota.
     **/
    public static void reShareCPQuota(Set<Id> setReparentedPartnerContact){
        ilib_LogEvent.push(LOG_TITLE + '.reShareCPQuota()');//CMSI-70
        ilib_LogEvent.info('setReparentedPartnerContact : ' +setReparentedPartnerContact);//CMSI-70
        Set<Id> setPartnerUsers = new Set<Id>();
        for(User objUser : new UsersSelector().getActivePartnerUserByContact(setReparentedPartnerContact)){
            setPartnerUsers.add(objUser.Id);}
            ilib_LogEvent.info('setPartnerUsers : ' +setPartnerUsers);//CMSI-70
        List<Code_Parameter__mdt> lstCodeParam = new CodeParametersSelector().selectCodeParameterByDeveloperName(new Set<String>{'CommunityUserSharingClasses'});
        for(String strClassName : lstCodeParam[0].Value__c.split(',')){
            ilib_PartnerSharing objShareClass = (ilib_PartnerSharing)Type.forName(strClassName).newInstance();
            objShareClass = objShareClass.setUserId(setPartnerUsers);
            ilib_Queueablethread queueableThread = new ilib_Queueablethread(strClassName);
            queueableThread.logAndQueue(objShareClass,strClassName , STRING_EXECUTE);
			ilib_QueueableManager.enqueueJob(queueableThread,ilib_LogEvent.MARKETING);
        }
        ilib_LogEvent.pop();//CMSI-70
    }

    //
    /* @author     : saddam
     * @param      : Contact new and old record
     * @return     : N/A
     * @Description: To check contact by beforeupdate and throw an error. US=PM-57
     **/
    public static void checkContactIsActive(Contact newRecord,Contact oldRecord,Id kolRecordTypeId) {
        //get recordtypeid to bypass

        ilib_LogEvent.message('kolRecordTypeId-->: '+kolRecordTypeId);
           //getting all the fields from an object
        SObjectType accountType = Schema.getGlobalDescribe().get('Contact');
        Map<String,Schema.SObjectField> mfields = accountType.getDescribe().fields.getMap();

        //checking the conditon and looping through the all the metadatafields
            if(oldRecord.Is_Active__c == false && oldRecord.RecordTypeId != kolRecordTypeId) {
                for (String str : mfields.keyset()) {
                     if(newRecord.get(str) != oldRecord.get(str) && mfields.get(str).getDescribe().isUpdateable() && str!=ACTIVE_FIELD &&  str!=EMAIL_FIELD) {
                        newRecord.addError(System.Label.Contact_Update_Error_Message);
                    }
                }
            }
    }

}