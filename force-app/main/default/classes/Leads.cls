/**
*    @author: Pradeep Kumar Aera
*    @date:   21-Aug-2018
*    @description:  Pardot prospect resubscription trigger for Lead related to DCP-9637 {For 75% Coverage - TestLeads}
*    Modification Log:
*    ------------------------------------------------------------------------------------
*         Developer           Date             Description
*         Govind Dubey        27-Mar-2019      Added setLeadStatusAndLeadSource method
*         Pankaj Singla       04-Apr-2019      updated setLeadStatusAndLeadSource to include Technical Support profile
*         Joshith K           21-Sep-2019      lead convertion logic,Added after insert logic
*         Pankaj Singla       01-Dec-2019      Added Logic for Hashed Email Id
*         Pankaj Singla       10-Dec-2019      DCP-31716 Added Logic for ULC Field population
*         Pankaj Singla       14-May-2020      DCP-35843 Added Recycled Changes for 0 Score
*         Pankaj Singla       04-Jun-2020      DCP-37606 Added changes for Lead Conversion
*         Monika Parihar      24-Sep-2020      DCP-41191 Added methods sendEmailAfterLeadAutoConvertandAutoMerge,autoConvertCheckboxUpdate,afterDelete
*         Rishab Wali         23-Aug-2021      [DCP-49613] Sync Error Fix
*         Rishab Wali         15-Nov-2021      [DCP-50851] Clear Disposition Code when status is not recycled.
*         Rishab Wali         22-Nov-2021      [DCP-49756] Update Most Recent Activity Date Field
*         Deep Diwakar        28-Feb-2022      DCP-52297: Hive9 - Funnel Leakage: Waterfall Stage Leakage Fixes
*         Rishab Wali         02-Mar-2022      [DCP-52387] Conversion of Lead to Contact
*         Rishab Wali         01-June-2022    DCP-52663: Skip scoring if Marketing Suppression is set to true  
*         Biswajeet           07-July-2022     CMSI-93 Instrumentation had been done for this class
*         Preetha             07-July-2022     CMSI-93 Instrumentation had been done for this class
*         Rishab Wali         20-July-2022    DCP-55950: Waterfall Stage update check to restrict date update
*         Rishab Wali         24-Aug-2022      DCP-56531 Lead Trigger Recursion Check 
*         Maruthi B           08-Dec-2022      DCP-58830: Modified Before update method to set Email Opted Out from Pardot Opted Out values when it changes
*         Deep Diwakar        June-09-2023     DCP-60099: Corrected recursion check causing loss of lead updates
*         Deep Diwakar        Nov-01-2023      CMCM-1521: SFDC-ULC integration retirement, removing code related to this integration
*         Deep Diwakar        Nov-29-2023      CMCM-4510: Area of work field calculation
*         Deep Diwakar        Mar-06-2024      CMCM-5551: Replaced old Marketability logic with new Marketability Service 
*         Deep Diwakar        May-22-2024      CMCM-7994: Removed Cvent opt in logic as it is moved to new CventMarketability class  
*         Deep Diwakar        June-10-2024     CMCM-6457: Added logic to handle merge operation for waterfall process
*         Deep Diwakar        June-26-2024      CMCM-6457: Added Waterfall logic for lead conversion
*         Deep Diwakar        Sept-03-2024     CMCM-9949: Updated to handle empty contact waterfall stage for lead conversion scenario
*         Deep Diwakar        Dec-06-2024      CMCM-12466: Updated to handle new Hand Raise status
*         Deep Diwakar        Dec-13-2024      CMCM-12469: Updated waterfall code to handle new Hand Raise status
*    ------------------------------------------------------------------------------------
*/
public with sharing class Leads extends ilib_SObjectDomain {

    public static boolean booTestRunning=false;
    public static boolean boolConversionRun=false;
    public static Boolean BOOLEAN_LEAD_ASSIGNMENT_INVOKED = false;
    public static Boolean booleanEmailRecursionStop = false; //DCP 41191
    public static final Integer INT_LEAD_SIZE = 1; //DCP 41191
    public static final String STRING_LEAD_STATUS_RECYCLED = 'Recycled';
    public static final Integer INT_MARKETING_RECYCLED_SCORE = 0;
    public static final String STRING_RECYCLED_ACTION = 'Prospect Recycled';
  public static final String STRING_HIGH_VALUE_SCORE ='High Value Scoring';

  public static final Integer INT_HIGH_VALUE_SCORING_FACTOR = Integer.ValueOf(Label.High_Value_Scoring_factor);
  public static final String STRING_LEAD_CONVERTED_NO_OPP='Lead Converted No Opp';
  public static final String STRING_LEAD_CONVERTED_QUALIFIED='Qualified';
  public static final integer INTEGERVALUEONE = 1;
  public static boolean changeTrigerredFromCampaignTrigger = false; //DCP-49756
  public static boolean boolRecursion = false; //DCP-52387  
  private static final String LOG_TITLE = 'Leads';//CMSI-93
  @TestVisible
  private static boolean boolCheckRecursionForLeadStatus = false; // DCP-56531
  private static boolean boolRecurseCheckBeforeUpdate = false; // DCP-56531 

  // static map to keep track of merge leads
  private static Map<Id, Id> mapMergeWinIdToLooseId = new Map<Id, Id>();

    /*Parameterised Constructor */
    public Leads(List<Lead> sObjectList) {
        super(sObjectList);
        if (FeatureManagement.checkPermission('Bypass_Person_Object_Permission')) {
            Configuration.disableTriggerCRUDSecurity();
        }
    }
    /*
    * Boilerplate which is required for base class instantiation logic
    */
    public class Constructor implements ilib_SObjectDomain.IConstructable
    {
        /*Method Param - List<sObject> */
        public ilib_SObjectDomain construct(List<SObject> sObjectList)
        {
            return new Leads(sObjectList);
        }
    }

    /*Method - Runs on beforeInsert event of trigger */
    public override void onBeforeInsert()
    {
        List<Lead> lstInsertedLeads = (List<Lead>) records;
        List<Lead> lstLeadAOIRecords = new List<Lead>();

        for (Lead objLead : lstInsertedLeads)
        {
            if (objLead.Marketing_Score__c != null && objLead.Marketing_Score__c > 0.0) {
                objLead.Date_Of_Last_Score_Change__c=Datetime.now();
            }
            if (objLead.Area_Of_Interest__c != null) {
                lstLeadAOIRecords.add(objLead);
            }

            //CMCM-5552: Moving pardot opted out value to SF opted out of email field
            if (objLead.Pardot_Opted_Out__c) {
                objLead.HasOptedOutOfEmail = objLead.Pardot_Opted_Out__c;
            }

            /*Set Hashed Email Id Field*/
            if (objLead.Email != null) {
                String strEmail=objLead.Email.toLowerCase();
                Blob b = Crypto.generateDigest('SHA-256', Blob.valueOf(strEmail));
                objLead.Hashed_Email_Id__c=EncodingUtil.convertToHex(b);
            }

        }

		LeadsHelper.updateMostRecentActivityDate(lstInsertedLeads,changeTrigerredFromCampaignTrigger); //DCP-49756

        //DCP 41191 Lead is AutoConverted or AutoMerged from Dupeblocker
        if (lstInsertedLeads.size() == INT_LEAD_SIZE) {
            autoConvertCheckboxUpdate(lstInsertedLeads.get(0));
        }

        //CMCM-5551: New marketability implementation
        MarketabilityServiceFacade facade = new MarketabilityServiceFacade();
        facade.determineMarketability(records, 'global-v1');

        if (!lstLeadAOIRecords.isEmpty()) {
            setAOICheckboxes(lstLeadAOIRecords);
        }
        setLeadStatusAndLeadSource(records);

        //CMCM-4510: Instantiating decorator object to calculate area of work field
        ilib_SObjectDecorator aowDecorator = new AreaOfWorkLeadDecorator(records);
        aowDecorator.decorate();
    }

    /**
    *  @author Joshith K
    *  @description To update Software Downloads Records Maching with lead email id
    *  @param
    *  @return void
    **/
    public override void onAfterInsert()
    {
        List<Lead> newLeads = (List<Lead>)records;
        List<Lead> listLeadWithEmailId = new List<Lead>();

        List<Id> lstLeadsForCharket = new List<Id>();
        List<Lead> lstLeadForAutoTagging = new List<Lead>();
        List<Prospect_Scoring_Log__c> lstProspectScoreLog = new List<Prospect_Scoring_Log__c>();
        List<Lead> lstLeads = new List<Lead>();
        for (Lead objLead:newLeads)
        {
            if (String.isNotBlank(objLead.Email)){
                listLeadWithEmailId.add(objLead);}

            if( (booTestRunning || UserInfo.getName().equals('Charket User')|| UserInfo.getName().equals('WeChat Charket Site Guest User')) ){
                if(String.IsNotBlank(objLead.Email)){
                   lstLeadsForCharket.add(objLead.Id);
                }

                if(String.isNotBlank(objLead.Area_Of_Interest__c) || String.isNotBlank(objLead.Job_Function__c) ){
                    lstLeadForAutoTagging.add(objLead);
                }
            }
            ilib_LogEvent.info('lstLeadsForCharket :'+lstLeadsForCharket); //CMSI-93

            /*DCP-35845 Changes Start*/
            if (objLead.pi__score__c != null && Integer.ValueOf(objLead.pi__score__c) > 0.0 && !objLead.Marketing_Suppression__c)
            {
                Lead objNewLead = new Lead(Id = objLead.id);
                Integer intCurrentScore = ((Integer.ValueOf(objLead.Marketing_Score__c) != null) ? Integer.ValueOf(objLead.Marketing_Score__c) : 0);
                Integer intScoringIncrementVal = Integer.ValueOf(objLead.pi__score__c) * INT_HIGH_VALUE_SCORING_FACTOR;
                Integer intFinalScore = intScoringIncrementVal + intCurrentScore;
                objNewLead.Marketing_Score__c=intFinalScore;
                objNewLead.Date_Of_Last_Score_Change__c =datetime.now();
                Prospect_Scoring_Log__c objProspectScoringLog=ProspectScoringUtils.createProspectScoringLogRecords(STRING_HIGH_VALUE_SCORE,'',objLead.Id,UserInfo.getUserId(),'',intCurrentScore,intFinalScore);
                lstProspectScoreLog.add(objProspectScoringLog);
                lstLeads.add(objNewLead);
            }
            /*DCP-35845 Changes End*/
        }

        if (!lstProspectScoreLog.isEmpty()) {
            insert lstProspectScoreLog;
            ProspectScoringUtils.boolPreventDuplicateRun=false;
        }

        if (!lstLeads.isEmpty()) {
            update lstLeads;
            ilib_LogEvent.info('lstLeads :'+UtilsCollection.getSetOfIds(lstLeads)); //CMSI-93
        }

        if (!listLeadWithEmailId.isEmpty())
        {
            SoftwareDownloadQueueableForSync objSoftwareDownloadQueableForSync = new SoftwareDownloadQueueableForSync(listLeadWithEmailId);
            // chain queueables fix start
            ilib_Queueablethread queueableThread = new ilib_Queueablethread('LeadAfterInsert');
            queueableThread.logAndQueue(objSoftwareDownloadQueableForSync, 'SoftwareDownloadQueueableForSync', 'execute');
            ilib_QueueableManager.enqueueJob(queueableThread,ilib_LogEvent.MARKETING);
            // chain queueables fix end
        }

        if (!lstLeadsForCharket.isEmpty()) {
            CharketUtils.processCharketLeadSubmission(lstLeadsForCharket,ilib_LogEvent.getTransactionId());
        }
        if(!lstLeadForAutoTagging.isEmpty()){
            CharketUtils.processLeadsForWeChatTagging(lstLeadForAutoTagging);
        }

    }

     /*CMSI-51
    * method will return the workstream
    */
    public override string getWorkstream(){
        return ilib_LogEvent.MARKETING;
    }

    /**
    *  @author Govind Dubey
    *  @description To update Lead Status and Lead Source based on profiles
    *  @param new proposals
    *  @return void
    **/
    private void setLeadStatusAndLeadSource(List<Lead> lstLeads)
    {
        ilib_LogEvent.push(LOG_TITLE +'.setLeadStatusAndLeadSource()'); //CMSI-93
        User objUser = [SELECT Profile.Name FROM User WHERE Id = :UserInfo.getUserId()].get(0);
        if (objUser == null) { return; }

        for (Lead objLead : lstLeads)
        {
            if (objUser.Profile.Name.contains(Label.SalesProfile) || objUser.Profile.Name.contains('Commercial Ops Quoting User')) {
               objLead.LeadSource = Label.LeadSourceSalesGenerated;
            }
            else if (objUser.Profile.Name.contains(Label.ServiceProfile) || objUser.Profile.Name.contains(Label.ProfileTechnicalSupport)) {
                objLead.LeadSource = Label.LeadSourceCSGenerated;
                objLead.Field_Service_Owner__c = UserInfo.getUserId();
                objLead.Status = Label.LeadStatusNew;
            }
        }
        ilib_LogEvent.pop(); //CMSi-93
    }

    /*Method - Set AOI Checkbox Values */
    private void setAOICheckboxes(List<Lead> lstLeads)
    {
        ilib_LogEvent.push(LOG_TITLE +'.setAOICheckboxes()'); //CMSI-93
        ilib_LogEvent.info('lstLeads :'+UtilsCollection.getSetOfIds(lstLeads)); //CMSI-93
        List<String> lstpickListValuesList = new List<String>(); // List to store AOI picklist values
        List<String> lstAOIFieldAPINames = new List<String>(); // List to store API names for AOI checkoxes fields
        Schema.DescribeFieldResult fieldResult = Lead.Area_Of_Interest__c.getDescribe();
        List<Schema.PicklistEntry> lstPle = fieldResult.getPicklistValues();
        Map<String, String> mapAreaOfInterestValueFieldAPIName = new map<String, String>(); //map to store picklist value and corresponding field API Name

        // Get All the picklist values for AOI field
        for (Schema.PicklistEntry pickListVal : lstPle) {
            lstpickListValuesList.add(pickListVal.getLabel());
        }

        /*
        Derive check-box field names from AOI picklist values
        if the picklist value is Animal Testing, the field name is AOI_Animal_Testing__c
        */
        for (string strpickval:lstpickListValuesList)
        {
            List<string> lsttemp=new list<string>();
            String strFinalAPIName='';
            String strTempStore=strpickval;
            strpickval=strpickval.replace('/',' ');
            lsttemp = strpickval.split(' ');

            if (lsttemp.size() == INTEGERVALUEONE) {
                strFinalAPIName = 'AOI_' + strpickval + '__c';
                lstAOIFieldAPINames.add(strFinalAPIName);
            }
            else
            {
                String strTemp='AOI';
                for (String s1 : lsttemp) {
                    strTemp = strTemp + '_';
                    strTemp = strTemp + s1;
                }
                strFinalAPIName = strTemp + '__c';
                lstAOIFieldAPINames.add(strFinalAPIName);
            }
            mapAreaOfInterestValueFieldAPIName.put(strTempStore,strFinalAPIName);
        }
        ilib_LogEvent.info('mapAreaOfInterestValueFieldAPIName :'+mapAreaOfInterestValueFieldAPIName); //CMSI-93

        for (Lead objLead:lstLeads)
        {
            // Set all the checkoxes to false initially
            for (String strAOIFieldAPIName : lstAOIFieldAPINames) {
                objLead.put(strAOIFieldAPIName, false);
            }

            if (objLead.Area_Of_Interest__c != null)
            {
                String strAOIPickVal = objLead.Area_Of_Interest__c;
                List<String> lstAOIValues = strAOIPickVal.split(';');

                for (String strAOIVAL : lstAOIValues)
                {
                    if (mapAreaOfInterestValueFieldAPIName.containsKey(strAOIVAL)) {
                        String fieldname = mapAreaOfInterestValueFieldAPIName.get(strAOIVAL);
                        objLead.put(fieldname, true);
                    }
                }
            }
        }
        ilib_LogEvent.pop();//CMSI-93
    }

    /*Method - Before Update Event trigger method */
    public override void onBeforeUpdate(Map<Id, SObject> idToLead) {
        List<Lead> lstLeadAOIRecords = new List<Lead>();
        List<Prospect_Scoring_Log__c> lstProspectScoreLog = new List<Prospect_Scoring_Log__c>();
      
        Map<Id, Lead> mapLooserIdToWinnerObj = new Map<Id, Lead>();
        /*Set<String> setWaterFallStageAcceptedQualifed=new Set<String>{'Sales Accepted','Qualified'}; - Commented since not used*/
        for (Id idLead : idToLead.keySet())
        {
            Lead objNewLead = (Lead) Trigger.newMap.get(idLead);
            Lead objOldLead = (Lead) idToLead.get(idLead);
            Boolean boolStatusUpdated = false;

			//DCP-58830
            if(objNewLead.Pardot_Opted_Out__c != objOldLead.Pardot_Opted_Out__c) {
                objNewLead.HasOptedOutOfEmail = objNewLead.Pardot_Opted_Out__c;
            }

            //DCP-52297: Corrected check for lead status to set boolean value
            if(objNewLead.status!=null && !objNewLead.status.equalsIgnoreCase(objOldLead.Status)){
                boolStatusUpdated=true;
            }

            if (objNewLead.Marketing_Score__c != objOldLead.Marketing_Score__c) {
                objNewLead.Date_Of_Last_Score_Change__c = Datetime.now();
            }

            if (objNewLead.Area_Of_Interest__c != objOldLead.Area_Of_Interest__c) {
                lstLeadAOIRecords.add(objNewLead);
            }

            /*Set Hashed Email Id Field*/
            if (objNewLead.Email!=null && objNewLead.Email!=objOldLead.Email)
            {
                String strEmail = objNewLead.Email.toLowerCase();
                Blob b = Crypto.generateDigest('SHA-256', Blob.valueOf(strEmail));
                objNewLead.Hashed_Email_Id__c = EncodingUtil.convertToHex(b);
            }

            /*DCP-35843 Changes Start*/
            if (objNewLead.Status != null && objNewLead.Status.equals(STRING_LEAD_STATUS_RECYCLED) && !objNewLead.Status.equals(objOldLead.Status) && ProspectScoringUtils.boolPreventDuplicateRun && objNewLead.IsConverted == false)
            {
                Integer intPreviousScore = Integer.ValueOf(objOldLead.Marketing_Score__c);
                objNewLead.Marketing_Score__c = INT_MARKETING_RECYCLED_SCORE;
                objNewLead.Date_Of_Last_Score_Change__c = Datetime.now();
                Prospect_Scoring_Log__c objProspectScoringLog = ProspectScoringUtils.createProspectScoringLogRecords(STRING_RECYCLED_ACTION, '', objNewLead.Id, UserInfo.getUserId(), '', intPreviousScore, INT_MARKETING_RECYCLED_SCORE);
                lstProspectScoreLog.add(objProspectScoringLog);
            }

            /*DCP-35843 Changes End*/
            /*DCP-35845 Changes Start*/
            if (objNewLead.pi__score__c != objOldLead.pi__score__c && ProspectScoringUtils.boolPreventDuplicateRun && objNewLead.IsConverted == false && !objNewLead.Marketing_Suppression__c)
            {
                Integer intPreviousScore = ((Integer.ValueOf(objOldLead.Marketing_Score__c)!=null)?Integer.ValueOf(objOldLead.Marketing_Score__c):0);
                Integer intPreviousScoreCounterTemp = Integer.ValueOf(objOldLead.pi__score__c);
                Integer intCurrentScoreCounterTemp = Integer.ValueOf(objNewLead.pi__score__c);
                Integer intPreviousScoreCounter = ((intPreviousScoreCounterTemp != null && intPreviousScoreCounterTemp > 0) ? intPreviousScoreCounterTemp : 0);
                Integer intCurrentScoreCounter= ((intCurrentScoreCounterTemp != null && intCurrentScoreCounterTemp > 0) ? intCurrentScoreCounterTemp : 0);
                Integer intIncrementalScoreVal= (intCurrentScoreCounter - intPreviousScoreCounter) * INT_HIGH_VALUE_SCORING_FACTOR;
                if (intIncrementalScoreVal > 0)
                {
                    Integer intFinalScore = intIncrementalScoreVal + intPreviousScore;
                    objNewLead.Marketing_Score__c = intFinalScore;
                    objNewLead.Date_Of_Last_Score_Change__c = Datetime.now();
                    Prospect_Scoring_Log__c objProspectScoringLog = ProspectScoringUtils.createProspectScoringLogRecords(STRING_HIGH_VALUE_SCORE, '', objNewLead.Id, UserInfo.getUserId(), '', intPreviousScore, intFinalScore);
                    lstProspectScoreLog.add(objProspectScoringLog);
                }
            }
            /*DCP-35845 Changes End*/

            //DCP-52297:Changes are in below code block. As part of this story, corrected multiple string checks and added few comments and indentation
            // Waterfall Changes Start here
            //CMCM-6457: Check if merge operation is in progress
            if (mapMergeWinIdToLooseId.keySet().contains(objNewLead.Id)) {
                // this update is happening due to merge operation
                ilib_LogEvent.message('adding for waterfall field merge');
                mapLooserIdToWinnerObj.put(mapMergeWinIdToLooseId.get(objNewLead.Id), objNewLead); 
                    
            } else {
                // this is regular waterfall update
                ilib_LogEvent.message('triggering regular waterfall field update');
                calculateWaterfallValues(boolRecurseCheckBeforeUpdate, boolStatusUpdated, objNewLead, objOldLead);
            }
            
            // Waterfall Changes end here
            //DCP-52297: Changes end here

            if(objNewLead.status != STRING_LEAD_STATUS_RECYCLED && objNewLead.Disposition_Code__c != '')
            {
                objNewLead.Disposition_Code__c = ''; //DCP-50851
            }
        }

        //DCP-60099: Moved setting of recursion flag outside of loop. It should be per transaction, not per record.
        boolRecurseCheckBeforeUpdate = true;

        ilib_LogEvent.info('mapLooserIdToWinnerObj size: ' + mapLooserIdToWinnerObj.size());

        // CMCM-6457: Set waterfall value for merge operation
        if (!mapLooserIdToWinnerObj.isEmpty()) {
            ilib_LogEvent.info('triggering waterfall field merge');
            MktgWaterfallServiceHelper.mergeWaterfallLogic(mapLooserIdToWinnerObj);
        }

        

        ilib_LogEvent.message('lstProspectScoreLog :'+UtilsCollection.getSetOfIds(lstProspectScoreLog));

		LeadsHelper.updateMostRecentActivityDate((List<Lead>)Trigger.new,changeTrigerredFromCampaignTrigger); //DCP-49756
       
        //CMCM-5551: New marketability implementation
        MarketabilityServiceFacade facade = new MarketabilityServiceFacade();
        facade.determineMarketability(Trigger.new, 'global-v1');

        if (!lstLeadAOIRecords.isEmpty()) {
            setAOICheckboxes(lstLeadAOIRecords);
        }


        //CMCM-4510: Instantiating decorator object to calculate area of work field
        ilib_SObjectDecorator aowDecorator = new AreaOfWorkLeadDecorator(records);
        aowDecorator.decorate(idToLead);

        /*DCP-35843 Changes Start*/
        if (!lstProspectScoreLog.isEmpty()) {
            insert lstProspectScoreLog;
            ProspectScoringUtils.boolPreventDuplicateRun=false;
        }
        /*DCP-35843 Changes End*/
    }

    /**
     * @author: Deep Diwakar
     * @date: June-12-2024
     * @description: This method calculates waterfall values for given record
     * @param: boolRecurseCheckBeforeUpdate - boolean flag to check for recursion
     * @param: objNewLead - new state of the record
     * @param: objOldLead - old state of the record
     * @return: void
     */
    private void calculateWaterfallValues(Boolean boolRecurseCheckBeforeUpdate, Boolean boolStatusUpdated, Lead objNewLead, Lead objOldLead) {

        Boolean boolClearWaterFallDates=false;
        String strSalesAccepted = 'Sales Accepted';
        Set<String> setLeadStatusQualified=new Set<String>{'Marketing Qualified'};

        //CMCM-12469: Set to collect lead statuses for engaged waterfall stage
        Set<String> setLeadStatusEngaged = new Set<String> {'Hand Raise', 'Automation Qualified'};

        Boolean boolLastRespondedDateUpdated = false;
        if (objNewLead.Last_Responded_Campaign_Date__c != objOldLead.Last_Responded_Campaign_Date__c && objNewLead.Last_Responded_Campaign_Date__c > System.now() - 365) {
            boolLastRespondedDateUpdated = true;
        }

        ilib_LogEvent.message('boolLastRespondedDateUpdated: ' + boolLastRespondedDateUpdated);

        if (!boolRecurseCheckBeforeUpdate && boolStatusUpdated && STRING_LEAD_STATUS_RECYCLED.equals(objNewLead.Status)) {
            objNewLead.Waterfall_Stage__c='';
        } else if (!boolRecurseCheckBeforeUpdate && boolStatusUpdated && String.isNotBlank(objNewLead.Status) && objNewLead.Status.equals('Accepted') && (objNewLead.Waterfall_Engaged_Date__c!=null || objNewLead.Waterfall_Qualified_Date__c!=null)) {
            boolClearWaterFallDates = resetWaterfallFields(objNewLead, objOldLead);
            objNewLead.Waterfall_Sales_Accepted_Date__c=Datetime.now();
            objNewLead.Waterfall_Stage__c='Sales Accepted';
            objNewLead.Waterfall_Qualified_Date__c = objNewLead.Waterfall_Qualified_Date__c==null||boolClearWaterFallDates ? Datetime.now():objNewLead.Waterfall_Qualified_Date__c;
            objNewLead.Waterfall_Engaged_Date__c=objNewLead.Waterfall_Engaged_Date__c==null||boolClearWaterFallDates ? Datetime.now():objNewLead.Waterfall_Engaged_Date__c;
        } else if (!boolRecurseCheckBeforeUpdate && boolStatusUpdated && !setLeadStatusQualified.contains(objOldLead.Status) && setLeadStatusQualified.contains(objNewLead.Status) && !strSalesAccepted.equals(objNewLead.Waterfall_Stage__c)) {
            boolClearWaterFallDates = resetWaterfallFields(objNewLead, objOldLead);
            objNewLead.Waterfall_Stage__c='Qualified';
            objNewLead.Waterfall_Qualified_Date__c=Datetime.now();
            objNewLead.Waterfall_Engaged_Date__c= objNewLead.Waterfall_Engaged_Date__c==null||boolClearWaterFallDates ? Datetime.now():objNewLead.Waterfall_Engaged_Date__c;
        } else if (!boolRecurseCheckBeforeUpdate && boolStatusUpdated && !setLeadStatusEngaged.contains(objOldLead.Status)
             && setLeadStatusEngaged.contains(objNewLead.Status) && String.isBlank(objNewLead.Waterfall_Stage__c)) {
                //CMCM-12469: Adding engaged waterfall stage when Lead status is either Hand Raise or AQ
                boolClearWaterFallDates = resetWaterfallFields(objNewLead, objOldLead);
                objNewLead.Waterfall_Stage__c='Engaged';
                objNewLead.Waterfall_Engaged_Date__c=Datetime.now();
        }

        if (boolLastRespondedDateUpdated && String.isBlank(objNewLead.Waterfall_Stage__c) && objNewLead.Last_Responded_Campaign_Date__c!=null
                 && (objNewLead.Date_Status_Set_As_Recycled__c==null || Date.valueOf(objNewLead.Last_Responded_Campaign_Date__c)>objNewLead.Date_Status_Set_As_Recycled__c)) {
            boolClearWaterFallDates = resetWaterfallFields(objNewLead, objOldLead);
            objNewLead.Waterfall_Stage__c='Engaged';
            objNewLead.Waterfall_Engaged_Date__c=Datetime.now();
        }

        ilib_LogEvent.info('Boolean variable: '+boolClearWaterFallDates);

    }

    /**
     * @author: Deep Diwakar
     * @date: June-12-2024
     * @description: This method resets waterfall fields if old value is blank
     * @param: objNewContact - new state of the record
     * @param: objOldContact - old state of the record
     * @param: boolClearWaterFallDates - boolean flag that stores if waterfall value is alread cleared or not
     * @return: void
     */
    private Boolean resetWaterfallFields(Lead objNewLead, Lead objOldLead) {
        Boolean isCleared = false;

        if(String.isBlank(objOldLead.Waterfall_Stage__c)) {
            ilib_LogEvent.info('reseting dates to null');
            objNewLead.Waterfall_Qualified_Date__c=null;
            objNewLead.Waterfall_Engaged_Date__c=null;
            objNewLead.Waterfall_Sales_Accepted_Date__c=null;
            isCleared = true;
        }

        return isCleared;

    }

    /*
    * @author Pankaj Singla
    * @date   24-Sept-2018
    * @description - Method to Invoke Lead Assignment Rules
    *                when Lead is updated from Pardot.
    *
    * After update trigger method
    */
    public override void onAfterUpdate(Map<Id, SObject> idToLead)
    {
        if(boolCheckRecursionForLeadStatus)
        {
            return;
        }
        boolCheckRecursionForLeadStatus = true;
        if (FeatureManagement.checkPermission('Bypass_Apex_Sharing_Settings')) {
            configuration.disableTriggerCRUDSecurity();
        }

        List<Lead> lstLeads = new List<Lead>();
        String strAutomationQualified = 'Automation Qualified';
        String strRecycled = 'Recycled';

        //CMCM-12466: Added Hand Raise status to re-run Lead assignment rules and removed MQ status
        String strHandRaise = 'Hand Raise';
        Set<String> setLeadStatus = new set<String>{strAutomationQualified,strHandRaise,strRecycled};
        Map<Id, id> mapConvertedLeadIds = new Map<id, id>();//@DCP-27214 Joshith K for software download

        List<Id> lstAutoConvertedLeadId = new List<Id>();//@DCP-41191
        List<Id> lstLeadsForCharket = new List<Id>();
        Map<Id, Id> mapLeadIdToContactId = new Map<Id, Id>();
        List<Lead> lstLeadForAutoTagging = new List<Lead>();
        Boolean boolIsChangedEmailId = false;
        Boolean boolIsChangedAOI = false;
        Boolean boolIsChangedJobFunction = false;
        Boolean boolIsConvertedLead = false;
		Map<Id,String> mapconvertedLeadIdToString=new Map<Id,String>();
		Set<Id> setContactIds = new Set<Id>();
        
		for (Id idLead : idToLead.keySet())
        {
            // Get the new value for the custom field for this record
            Lead objNewLead = (Lead)Trigger.newMap.get(idLead);
            Lead objOldLead = (Lead)idToLead.get(idLead);

            boolIsConvertedLead = objNewLead.IsConverted ? true : false;
            boolIsChangedEmailId = String.isNotBlank(objNewLead.Email) && !objNewLead.Email.equals(objOldLead.Email);
            boolIsChangedAOI = String.isNotBlank(objNewLead.Area_Of_Interest__c) && !objNewLead.Area_Of_Interest__c.equals(objOldLead.Area_Of_Interest__c);
            boolIsChangedJobFunction = String.isNotBlank(objNewLead.Job_Function__c) && !objNewLead.Job_Function__c.equals(objOldLead.Job_Function__c);

            /*Test.IsRunning Test is added since Pardot is not connected to all sandboxes,
            Pardot user is not available and test class fails*/
            /*
            * When Pardot makes an update to the Country field and status is at AQ or MQ,
            OR
            * When Pardot modifies the Lead Status to either Automated Qualified or Marketing Qualified   */

            if (System.Test.isRunningTest() || (setLeadStatus.contains(objNewLead.status) && !objNewLead.status.equals(objOldLead.status))) {
                lstLeads.add(objNewLead);
            }
            else if (System.Test.isRunningTest() || (setLeadStatus.contains(objOldLead.status) && objNewLead.country != null && !objNewLead.country.equals(objOldLead.country))) {
                lstLeads.add(objNewLead);
            }

            // @DCP-27214 Joshith K  for Software Download
            if (objNewLead.ConvertedContactId!=objOldLead.ConvertedContactId &&objNewLead.ConvertedContactId != null) {
                mapConvertedLeadIds.put(objNewLead.id,objNewLead.ConvertedContactId);
            }

            if (booTestRunning || UserInfo.getName().equals('Charket User') || UserInfo.getName().equals('WeChat Charket Site Guest User') ) {
                if (String.IsNotBlank(objNewLead.Email) && boolIsChangedEmailId && !boolIsConvertedLead) {
                    lstLeadsForCharket.add(objNewLead.Id);
                }
                if ((boolIsChangedAOI || boolIsChangedJobFunction ) && !boolIsConvertedLead) {
                    lstLeadForAutoTagging.add(objNewLead);
                }
            }


            /*DCP-37606 changes start*/
            if (objNewLead.IsConverted == true && objNewLead.ConvertedContactId != objOldLead.ConvertedContactId && objNewLead.ConvertedContactId != null) {
                mapLeadIdToContactId.put(objNewLead.Id,objNewLead.ConvertedContactId);
                ilib_LogEvent.info('Lead conversion in progress in lead after update');
                if(objNewLead.Status.equals(STRING_LEAD_CONVERTED_NO_OPP)){
                    Contacts.isLeadConversionInProgress=true;
                    String strConIdLeadStatus=objNewLead.ConvertedContactId+'~'+objOldLead.Status;
                    mapconvertedLeadIdToString.put(objNewLead.Id,strConIdLeadStatus);
					setContactIds.add(objNewLead.ConvertedContactId);
                }
                else if(objNewLead.Status.equals(STRING_LEAD_CONVERTED_QUALIFIED))
                {
                    Contacts.isLeadConversionInProgress=true;
                    String strConIdLeadStatus=objNewLead.ConvertedContactId+'~'+'Open Opportunity';
                    mapconvertedLeadIdToString.put(objNewLead.Id,strConIdLeadStatus);
					setContactIds.add(objNewLead.ConvertedContactId);
                }

            }
            /*DCP-37606 changes end*/

            /*DCP-41191 changes start*/
            if (objNewLead.Is_AutoConversion_In_Progress__c && objNewLead.IsConverted) {
                lstAutoConvertedLeadId.add(objNewLead.id);
            }
            /*DCP-41191 changes end*/
        }

        ilib_LogEvent.message('lstAutoConvertedLeadId :'+lstAutoConvertedLeadId); //CMSI-93
        /*changes start for DCP-41191*/
        if (!lstAutoConvertedLeadId.isEmpty() && !booleanEmailRecursionStop) {
            sendEmailAfterLeadAutoConvertandAutoMerge(lstAutoConvertedLeadId);
        }
        /*changes stop for DCP-41191*/

        if (!mapConvertedLeadIds.isEmpty()) {
            appendToContact(mapConvertedLeadIds);
        }

        if (!lstLeads.isEmpty() && !BOOLEAN_LEAD_ASSIGNMENT_INVOKED) {
            runLeadAssignmentRules(lstLeads);
        }

        if (!lstLeadsForCharket.isEmpty()) {
            CharketUtils.processCharketLeadSubmission(lstLeadsForCharket,ilib_LogEvent.getTransactionId());
        }

        if (!lstLeadForAutoTagging.isEmpty()) {
            CharketUtils.processLeadsForWeChatTagging(lstLeadForAutoTagging);
        }

        /*DCP-37606 changes start*/
        if (!mapLeadIdToContactId.isEmpty() ) {
            processConvertedRecordsForScoring(mapLeadIdToContactId);

        }
        
        ilib_LogEvent.info('mapconvertedLeadIdToString: ' + mapconvertedLeadIdToString);
        ilib_LogEvent.info('boolConversionRun: ' + boolConversionRun);
        ilib_LogEvent.info('Lead - Contacts.lstContIdsEmptyWaterfall: ' + Contacts.lstContIdsEmptyWaterfall);


        if(!mapconvertedLeadIdToString.isEmpty() &&  !boolConversionRun )
		{
			Map<Id,String> mapConvertedContactIdToString = new Map<Id,String>();
        	for(Contact con : [SELECT Id,Marketing_Contact_Status__c FROM Contact WHERE Id In: setContactIds])
        	{
        		mapConvertedContactIdToString.put(con.Id,con.Marketing_Contact_Status__c);
    		}
            if(!System.isBatch()  && !System.isFuture() && !System.isQueueable() && !System.isScheduled())
            {
                ilib_LogEvent.info('calling async');
                processConvertedRecordsForStatus(mapconvertedLeadIdToString,mapConvertedContactIdToString, Contacts.lstContIdsEmptyWaterfall);
            }
            else
            {
                ilib_LogEvent.info('calling sync');
                processConvertedRecordsSync(mapconvertedLeadIdToString,mapConvertedContactIdToString, Contacts.lstContIdsEmptyWaterfall);
            }
        }
        /*DCP-37606 changes end*/

    }
	/*
    * @author Pankaj Singla
    * @date   30-Apr-2021
    * @description-This method is called for converted records
    * @Param:mapconvertedLeadIdToString Map of Lead to string
    */
    @future
    public static void processConvertedRecordsForStatus(Map<Id,String> mapconvertedLeadIdToString,Map<Id,String> mapContactIdToString, List<Id> lstContIdsEmptyWaterfall){
        ilib_LogEvent.info('calling future');
        processConvertedRecordsSync(mapconvertedLeadIdToString,mapContactIdToString, lstContIdsEmptyWaterfall);
    }

    /*Handle Conversion method for async processes */
    public static void processConvertedRecordsSync(Map<Id,String> mapconvertedLeadIdToString,Map<Id,String> mapContactIdToString, List<Id> lstContIdsEmptyWaterfall)
    {
        ilib_LogEvent.push(LOG_TITLE +'.processConvertedRecordsForStatus()');
        ilib_LogEvent.info('mapconvertedLeadIdToString :'+mapconvertedLeadIdToString);//CMSI-93
        ilib_LogEvent.info('mapContactIdToString :'+mapContactIdToString);//CMSI-93

        ilib_LogEvent.info('processConvertedRecordsSync.lstContIdsEmptyWaterfall: ' + lstContIdsEmptyWaterfall);
        List<Contact> lstcontacts=new List<Contact>();

        Map<Id, Id> mapConvertedLeadIdToContId = new Map<Id, Id>();

        for(Id leadIds:mapconvertedLeadIdToString.keyset()){
            String contactId=mapconvertedLeadIdToString.get(leadIds).split('~')[0];
            String contactStatus=mapconvertedLeadIdToString.get(leadIds).split('~')[1];

            mapConvertedLeadIdToContId.put(leadIds, contactId);

            if(mapContactIdToString.containsKey(contactId)) //DCP-52387
            {
                String strStatusNew = 'New';
                String strOpenOpp = 'Open Opportunity';
                Contact objCon=new Contact(Id=contactId);
                if(mapContactIdToString.get(contactId) == strStatusNew)
                {
                    objCon.Marketing_Contact_Status__c=contactStatus;
                    lstcontacts.add(objCon);  
            	}
            	else
            	{
               		 objCon.Marketing_Contact_Status__c=mapContactIdToString.get(contactId);
                     if(contactStatus == strOpenOpp)
                     {
                         objCon.Marketing_Contact_Status__c = strOpenOpp;
                     }
                     lstcontacts.add(objCon);
            	}
        	}
        }

        ilib_LogEvent.message('lstcontacts :'+UtilsCollection.getSetOfIds(lstcontacts)); //CMSI-93
        ilib_LogEvent.message('waterfall lstcontacts :'+UtilsCollection.getSetOfIds(lstcontacts)); //CMSI-93

        //CMCM-6457: setting waterfall fields in lead conversion scenario
        MktgWaterfallServiceHelper.waterfallForLeadConversion(mapConvertedLeadIdToContId, lstcontacts, lstContIdsEmptyWaterfall);

        if(!lstcontacts.isEmpty()){
            cs_Apex_Settings__c cs=cs_Apex_Settings__c.getInstance(UserInfo.getUserId());
            cs.Bypass_All_Validations__c = true;
            upsert cs cs_Apex_Settings__c.Id;
            Contacts.isLeadConversionInProgress=true;
            update lstcontacts;
            cs.Bypass_All_Validations__c = false;
            upsert cs cs_Apex_Settings__c.Id;
        }
        ilib_LogEvent.pop(); //CMSI-93
    }

    /*
    * @author Pankaj Singla
    * @date   05-Jun-2020
    * @description-This method updates the prospect audit log from lead to convert
    * when the lead is converted to contact
    * @Param:MapLeadIdToContact Map of Lead to converted contact Id
    */
    public static void processConvertedRecordsForScoring(Map<Id,Id> mapLeadIdToContactId)
    {
        ilib_LogEvent.push(LOG_TITLE +'.processConvertedRecordsForScoring()'); //CMSI-93
        ilib_LogEvent.info('mapLeadIdToContactId :'+mapLeadIdToContactId);//CMSI-70
        List<Prospect_Scoring_Log__c> lstProspectLog = new List<Prospect_Scoring_Log__c>();
        for (Prospect_Scoring_Log__c objScoringLog : [SELECT Id, Lead__c, Contact__c FROM Prospect_Scoring_Log__c
                                                      WHERE Lead__c IN :mapLeadIdToContactId.Keyset()]
        ) {
            objScoringLog.Contact__c = mapLeadIdToContactId.get(objScoringLog.Lead__c);
            objScoringLog.Lead__c = null;
            lstProspectLog.add(objScoringLog);
        }
        ilib_LogEvent.info('lstProspectLog id:'+UtilsCollection.getSetOfIds(lstProspectLog));//CMSI-93
        if (!lstProspectLog.isEmpty()) {
            update lstProspectLog;
        }
        ilib_LogEvent.pop(); //CMSi-93
    }

    /*
    * @author Pankaj Singla
    * @date   24-Sept-2018
    * @description - This method invokes Lead Assignment Rules
    *                when Lead is updated from Pardot.
    * runLeadAssignmentRules
    * @Param:List of Lead Records to be updated
    */
    public static void runLeadAssignmentRules(List<Lead> lstLeads)
    {
        ilib_LogEvent.push(LOG_TITLE +'.runLeadAssignmentRules()'); //CMSI-93
        ilib_LogEvent.info('lstLeads id:'+UtilsCollection.getSetOfIds(lstLeads));
        BOOLEAN_LEAD_ASSIGNMENT_INVOKED = true; /*Prevent Recursive future Invocations*/
        List<Lead> lstupdLeads = new list<Lead>();

        for (Lead objLead : lstLeads)
        {
            /* *Use DML Options to run the lead assignment rules
             *useDefaultRule is set as true to use the default lead assignment rule */
            Database.DMLOptions dmo = new Database.DMLOptions();
            dmo.assignmentRuleHeader.useDefaultRule = true;

            Lead objLeadRecord = new Lead(Id = objLead.id);
            objLeadRecord.setOptions(dmo);
            lstupdLeads.add(objLeadRecord);
        }
        ilib_LogEvent.info('lstupdLeads id:'+UtilsCollection.getSetOfIds(lstupdLeads));//CMSI-93
        if (!lstupdLeads.isEmpty()) {
            update lstupdLeads;
        }
        ilib_LogEvent.pop(); //CMSi-93
    }

    /*
    * @author Joshith K
    * @date   20-Aug-2019
    * @description - This method updates Software Downloads Associated with leads on
    *                 Lead Conversion.
    * @Param:Map of Leads  Ids to Converted Contact Ids
    */
    public static void appendToContact(map<id,id> mapLeadsConverted)
    {
        ilib_LogEvent.push(LOG_TITLE +'.appendToContact()'); //CMSI-93
        ilib_LogEvent.info('mapLeadsConverted :'+mapLeadsConverted);//CMSI-93
        List<Software_Download__c> updatedSfdown = new List<Software_Download__c>();
        Set<id> contactIds = new Set<Id>(mapLeadsConverted.values());
        List<Contact> listContact=new ContactsSelector().selectContacts(contactIds);
        Map<Id,Contact>mapContacts=new Map<Id,Contact>(listContact);
        for (Software_Download__c objSoftDown : new SoftwareDownloadsSelector().selectSoftwareDownloadByLeads(mapLeadsConverted.keyset()))
        {
            Id leadId = objSoftDown.Lead_full_name__c;
            Id contactId = mapLeadsConverted.get(leadId);
            objSoftDown.Contact_full_name__c = contactId;
            objSoftDown.First_Name__c = mapContacts.get(contactId).FirstName;
            objSoftDown.Last_Name__c = mapContacts.get(contactId).LastName;
            if (String.isNotEmpty(mapContacts.get(contactId).MailingCountry)) {
                objSoftDown.Country__c = mapContacts.get(contactId).MailingCountry;
            } else {
                objSoftDown.Country__c = mapContacts.get(contactId).Country_Local__c;
            }
            objSoftDown.Lead_full_name__c = null;

            updatedSfdown.add(objSoftDown);
        }
        ilib_LogEvent.info('updatedSfdown :'+UtilsCollection.getSetOfIds(updatedSfdown));//CMSI-93
        ilib_LogEvent.pop(); //CMSi-93
        update updatedSfdown;
    }

    /**
    * @author Monika Parihar
    * @description This method runs after lead delete
    * @param
    * @return void
    **/
    public override void onAfterDelete()
    {
        List<Id> masterIds = new List<Id>();
        List<Id> masterIdAutoMergeLst = new List<Id>(); //@DCP-41191

        for(Lead objLead : (List<Lead>)records)
        {
            if (objLead.MasterRecordId != null)
            {
                //CMCM-6457: Storing deleted and winner record id for determing waterfall value in merge operation
                mapMergeWinIdToLooseId.put(objLead.MasterrecordId, objLead.Id);

                masterIds.add(objLead.MasterrecordId);
                /*DCP-41191 changes start*/
                if (objLead.Is_AutoMerge_In_Progress__c) {
                    masterIdAutoMergeLst.add(objLead.MasterrecordId);
                }
                /*DCP-41191 changes stop*/
            }
        }

        ilib_LogEvent.info('after delete mapMergeWinIdToLooseId: ' + mapMergeWinIdToLooseId);

        /*DCP-41191 changes start*/
        ilib_LogEvent.info('masterIdAutoMergeLst :'+masterIdAutoMergeLst);//CMSI-93
        if (!masterIdAutoMergeLst.isEmpty()) {
            sendEmailAfterLeadAutoConvertandAutoMerge(masterIdAutoMergeLst);
        }
        /*DCP-41191 changes stop*/
    }

    /*
    * @author Monika Parihar
    * @date   25-Sept-2020
    * @description - DCP-41191 This method is used to check checkbox when Duplicate Lead is matching AutoConvert or AutoMerge DB Scenarion
    * @Param: List of Duplicate LeadId
    */
    public static void autoConvertCheckboxUpdate(Lead insertedLead)
    {
        ilib_LogEvent.push(LOG_TITLE +'.autoConvertCheckboxUpdate()'); //CMSI-93
        List<String> matchInsertList = new List<String>();
        //potential duplicate records
        List<CRMfusionDBR101.DB_Api.Matches> matchSets = CRMfusionDBR101.DB_Api.findMatches(insertedLead);
        ilib_LogEvent.info('matchSets :'+matchSets);//CMSI-93
        for (CRMfusionDBR101.DB_Api.Matches dupeMatch : matchSets ){
            matchInsertList.add(dupeMatch.matchOnInsertAction);
        }

        //if lead is autoconverted from dupeblocker mark checkbox true
        if (matchInsertList.contains(Label.Auto_Convert_Lead)) {
            insertedLead.Is_AutoConversion_In_Progress__c = true;
        }
        //if lead is automerged from dupeblocker mark checkbox true
        else if (matchInsertList.contains(Label.Auto_Merge)) {
            insertedLead.Is_AutoMerge_In_Progress__c = true;
        }
        ilib_LogEvent.pop(); //CMSi-93
    }

    /*
    * @author Monika Parihar
    * @date   25-Sept-2020
    * @description - DCP-41191 This method is used to send email to current using notifing that Lead is AutoConverted or AutoMerged
    * @Param:List of ConvertedLeadId(AutoConvert) & WinnerLeadId(AutoMerge)
    */
    public static void sendEmailAfterLeadAutoConvertandAutoMerge(List<Id> leadIds)
    {
        ilib_LogEvent.push(LOG_TITLE +'.sendEmailAfterLeadAutoConvertandAutoMerge()'); //CMSI-93
        booleanEmailRecursionStop = true; /*Prevent Email Recursive*/
        //fetch winner Lead info or ConvertedLead info
        List<Lead> lstLead =new LeadsSelector().returnAutoConvertMergeCheckbox(leadIds);
        ilib_LogEvent.info('lstLead id:'+UtilsCollection.getSetOfIds(lstLead));//CMSI-93
        Map<String, Id> mapEmailTemp = new Map<String, Id>();
        List<Messaging.SingleEmailMessage> allemails = new List<Messaging.SingleEmailMessage>();

        //fetch email template id
        //DCP-41191 - Bypassing object access check for email template query as Marketing users are not able to access it.
        ilib_SecurityUtils.bypassInternalFlsAndCrud = true;
        for(EmailTemplate et: new EmailTemplatesSelector().selectByNameOrDeveloperName(new List<String>{Label.Lead_Auto_Converted_Successfully,Label.Lead_Auto_Merged_Successfully})) {
            mapEmailTemp.put(et.DeveloperName,et.id);
        }
        ilib_SecurityUtils.bypassInternalFlsAndCrud = false;

        //list of to addresses to whom we send the mails.
        List<String> toAddress = new List<String>{UserInfo.getUserEmail()};
        ilib_LogEvent.info('toAddress : '+toAddress);//CMSI-93
        for(Lead ld : lstLead)
        {
            String body;
            Messaging.SingleEmailMessage email;
            if(ld.ConvertedContactId == null)
            {
                //send email using single mail message method
                email = Messaging.renderStoredEmailTemplate(mapEmailTemp.get(Label.Lead_Auto_Merged_Successfully),ld.id, ld.id);

                //getHtmlBody
                body = email.getHtmlBody();
            }
            else
            {
                //fetch dynamic contact url
                String recordlink = URL.getSalesforceBaseUrl().toExternalForm()+'/'+ld.ConvertedContactId;
                //send email using singleEmailmessage method
                email = Messaging.renderStoredEmailTemplate(mapEmailTemp.get(Label.Lead_Auto_Converted_Successfully),ld.id,ld.id);

                //getHtmlBody
                body = email.getHtmlBody();
                body = body.replace('ContactLink', recordlink);
                body = body.replace('ConvrtContactAcc',ld.ConvertedAccount.Name);
            }

            //set the recipient
            email.setToAddresses(toAddress);

            email.setSenderDisplayName('Commercial Data Management - SFDC');
            body = body.replace('DateToday', system.today().format());
            email.setHtmlBody(body);
            email.setSaveAsActivity(false);

            allemails.add(email);
        }

        //send the mail
        try {
            Messaging.SendEmailResult [] result = Messaging.sendEmail(allemails, false);
            ilib_LogEvent.info('result :'+result);//CMSI-93
        } catch (Exception e) {
            ApexExceptions.emit(LOG_TITLE,e,ilib_LogEvent.getWorkstream());
            throw new AuraHandledException(e.getMessage());
        }
    }
}