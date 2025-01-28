/**
*    @author        
*    @date          
*    @description   Accounts domain class
*    @Test Class for above 90% coverage.
*    -TestPlanCloneController
*    -TestTAPS_SmaxPartsRequest
*    @Test Class for atleast 75% coverage.
     -TestPlanCloneController
     -TestTAPS_SmaxPartsRequest
*    Modification Log:
*    ------------------------------------------------------------------------------------------------------------------------------------------------
*             Akshay Mohan                18-June-2021           DCP-38968 Change sharing logic for Opportunity to Field Support
*             Saddam                      16-Feb-2022            pm-33,Created New Method ,updateRQConEligibleAccount() invoked in AfterUpdate and added method in beforeInsert
*             Saddam                      09-Mar-2022            PM-430,Modified updateRQConEligibleAccount() method invoked RqEligibleAccountLogic inside.
*             Anand Palla                 26-April-2022          CodeScan Fix-Avoid Literals in If condition 
*             Aman Tyagi                  05-April-2022          CodeScan Fixes
*             Nishan Shetty               24-Aug-2022            DCP-44091 - Indirect Instantiation of Orchestrator Class for Performance Improvement.
*             Gerardo Garcia              30-May-2024            CMCM-7687 On Account.Clinical_Type__c change it will set platform event.
*             Enrique Reyes               17-Jun-2024            CMCM-8183 Move logic from Account: Update status after ERP Id populated workflow to onBeforeUpdate trigger.
*             Vandana Kuncham             08-Aug-2024            CMCM-9577 Moving process builder Account: Create Market Segment Records On Converted Accounts to Apex
*             Gerardo Garcia              07-Aug-2024            CMCM-9578 - Account's Process Builder logic moved into Trigger handler
*             Venkat Gurijala             28-Jan-2025            to test the devops center using vscode
*    ------------------------------------------------------------------------------------------------------------------------------------------------
*/
public class Accounts extends ilib_SObjectDomain {

    // cache describe result
    private static Map<String, Schema.RecordTypeInfo> nameToRecordType;
    public static Boolean hasRunPartnerSharing = false;

    public static final String STATUS_ACTIVE_PROSPECT = 'Active Prospect';
    public static final String STATUS_ACTIVE = 'Active';

    public static final String GROUP_SOLD_TO = 'Sold To';
    public static final String GROUP_DISTRIBUTOR = 'Distributor';
    public static final String GROUP_ULTIMATE_CONSIGNEE = 'Ultimate Consignee';
    public static final String GROUP_PROSPECT = 'Prospect';

    // INC0214022 : use IN clase instead of != to eliminate non-selective query

    public static final String ACCOUNTGROUP_LEGACY = 'Legacy';

    //Start CodeScan Fix [Avoid Literals in If condition]
    private static final Integer STATUS_CODE = 200;
    //End CodeScan Fix

    public static final Set<String> ACCOUNT_GROUP_VALUES = new Set<String> {
        GROUP_PROSPECT, 'Code Desc Missing', GROUP_SOLD_TO, GROUP_DISTRIBUTOR, GROUP_ULTIMATE_CONSIGNEE, 'Intercompany', ACCOUNTGROUP_LEGACY
    };
    
    private static Boolean restUpdateHasBeenTriggered = false;
    
    //pm-33
    private static Boolean stoprecurssion = false;
    private static final String ACC_NOT_APPLICABLE = 'Not Applicable';
    private static final String LOG_TITLE = 'Accounts';

    //CMCM-8183
    static final List<String> ACCOUNT_GROUPS = new List<String>{Label.AccountGroupSoldTo, Label.AccountGroupUltimateConsignee, Label.AccountGroupDistributor};

    //CMCM-9918
    public static final string EMAIL_TEMPLATE_PARTNER_REQUEST_ACCEPTED = 'Partner_Request_Channel_Partner_when_New_Customer_Account_is_Accepted';   
    public static final string PROSPECT_RECORD_TYPE = 'Prospect';
    private static final String CONTACT_NAME = 'Master Data Request Dummy Contact';

    /*
    * Comments are added to fix code scan issues
    */
    public class REST_RECORD_RESULT
    {
        public String id;
        public Boolean success;
        List<String> errors;
    }
    
    /*
    * Comments are added to fix code scan issues
    */
    public static Map<String, Schema.RecordTypeInfo> getNameToRecordType()
    {
        if (nameToRecordType == null) nameToRecordType = Account.sObjectType.getDescribe().getRecordTypeInfosByName();

        return nameToRecordType;
    }

    /*
    * Comments are added to fix code scan issues
    */
    public Accounts (List<Account> sObjectList)
    {
        super(sObjectList);
        // disable because partner users don't have access to accounts but automation will update the accounts
        configuration.disableTriggerCRUDSecurity();
    }

    /*
    * Comments are added to fix code scan issues
    */
    public class Constructor implements ilib_SObjectDomain.IConstructable
    {
        /*
        * Comments are added to fix code scan issues
        */
        public ilib_SObjectDomain construct(List<SObject> sObjectList)
        {
            return new Accounts(sObjectList);
        }
    }

    /**
     * @author Rahul Sharma
     * @date   2019-01-25
     * @description    DCP-21372: Account: Populate Tier on Child Prospects
     * Before insert trigger method
     * Moving the logic from process builder to trigger to comply with salesforce order of exection.
     **/
    public override void onBeforeInsert() {
        List<Account> lstTempAcc = (List<Account>) records;
        populateDetailsFromParent(lstTempAcc);

         //pm-33 Starts
         for(Account acc : lstTempAcc) {
            if(acc.R_Q_Contact_Eligible__c==false) {
                acc.R_Q_Contact_Compliant__c=acc_Not_Applicable;
            }
        }
        //PM-33 ENDS
    }

    /*
    * Populate Market Segmentation information from Parent Account
    */
    public static void populateDetailsFromParent(List<Account> lstAcc) {
        Set<Id> parentAccountIdSet = new Set<Id>();
        List<Account> childAccounts = new List<Account>();
        for (Account acc: lstAcc) {
            if (acc.Market_Segment__c == null && acc.ParentId != null) {
                parentAccountIdSet.add(acc.ParentId);
                childAccounts.add(acc);
            }     
        }
        Map<Id, Account> parentAccountMap = new Map<Id, Account>(new AccountsSelector().selectAccounts(parentAccountIdSet));
        for (Account childAccount : childAccounts) {
            Account parentAccount = parentAccountMap.get(childAccount.ParentId);
            if (childAccount.Clinical_Type__c == null) {
                childAccount.Clinical_Type__c = parentAccount.Clinical_Type__c;
            }
            if (childAccount.Customer_Type__c == null) {
                childAccount.Customer_Type__c = parentAccount.Customer_Type__c;
            }
            if (childAccount.Customer_Sub_Type__c == null) {
                childAccount.Customer_Sub_Type__c = parentAccount.Customer_Sub_Type__c;
            }
            if (childAccount.Market_Segment__c == null) {
                childAccount.Market_Segment__c = parentAccount.Market_Segment__c;
                childAccount.Is_Updated_By_System__c = TRUE;
            }
            if (childAccount.Population_Genomics__c == null) {
                childAccount.Population_Genomics__c = parentAccount.Population_Genomics__c;
            }
        }
    }

    /** 
    * @author VandanaKuncham
    * @date   2024-08-08
    * CMCM-9577 Moving process builder Account: Create Market Segment Records On Converted Accounts to Apex
    * @description Create Market Segment Records for converted Accounts
   **/
    public override void onAfterInsert() {
       List<Account> lstTempAcc = (List<Account>) records;
       createMarketSegmentRecords(lstTempAcc);
       acceptProspectAccountandSendEmail(lstTempAcc);
    }

   /** 
   * 
   * @author Vandana Kuncham
   * @date   2024-08-07
   * CMCM-9577 Moving process builder Account: Create Market Segment Records On Converted Accounts to Apex
   * @description Create Market Segment Records for converted Accounts
   **/
    public static void createMarketSegmentRecords(List<Account> lstAcc) {
       List<Market_Segment__c> msList = new List<Market_Segment__c>();
       Set<Id> parentAccountIdSet = new Set<Id>();
       List<Account> childAccounts = new List<Account>();
        for (Account acc: lstAcc) {
            if (acc.Market_Segment__c != null && acc.ParentId == null) {
               Market_Segment__c newMS = new Market_Segment__c(Account__c = acc.Id, Market_Segment__c = acc.Market_Segment__c, Percent_Allocation__c = 100);
               msList.add(newMS);
            } else if (acc.ParentId != null) {
                parentAccountIdSet.add(acc.ParentId);
                childAccounts.add(acc);
            }                        
        }
        if (!parentAccountIdSet.isEmpty()) {
           msList.addAll(createMarketSegmentRecordsFromParentAccount(parentAccountIdSet, childAccounts));
        }
        if (!msList.isEmpty()) {
           insert msList;
        }
    }

   /** 
   * 
   * @author Vandana Kuncham
   * @date   2024-08-07
   * CMCM-9577 Moving process builder Account: Create Market Segment Records On Converted Accounts to Apex
   * @description Create Market Segment Records from Parent if child does not have Market Segment value
   **/
    public static List<Market_Segment__c> createMarketSegmentRecordsFromParentAccount(Set<Id> parentAccountIdSet, List<Account> childAccounts) {
        Map<Id, Account> parentAccountMap = new Map<Id, Account>(new AccountsSelector().selectAccountsWithMarketSegments(parentAccountIdSet));
        List<Market_Segment__c> msList = new List<Market_Segment__c>();
        for (Account childAccount : childAccounts) {
            Account parentAccount = parentAccountMap.get(childAccount.ParentId);
            for (Market_Segment__c parentMS : parentAccount.Market_Segments__r) {
               Market_Segment__c newMS = new Market_Segment__c(Account__c = childAccount.Id, Market_Segment__c = parentMS.Market_Segment__c, Percent_Allocation__c = parentMS.Percent_Allocation__c, 
               Market_Sub_Segment__c = parentMS.Market_Sub_Segment__c);
               msList.add(newMS);
            }
        }
        return msList;
    }
    
    /** 
    * 
    * @author Vandana Kuncham
    * @date   2024-08-21
    * CMCM-9918 Moving process builder Account: Change status on account partner request to Apex
    * @description Change status on account partner request and send email 
    **/
    public static void acceptProspectAccountandSendEmail(List<Account> lstAcc) {
        Channel_Partner_Profile_Settings__c channelPartner = Channel_Partner_Profile_Settings__c.getInstance(UserInfo.getProfileID());
        EmailTemplatesSelector emailTemplateSelector = new EmailTemplatesSelector();
        List<EmailTemplate> lstEmailTemplate = emailTemplateSelector.selectByNameOrDeveloperName(new List<String> {EMAIL_TEMPLATE_PARTNER_REQUEST_ACCEPTED});
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        List<Partner_Request__c> prList = new List<Partner_Request__c>();
        Id prospectRTId = getNameToRecordType().get(PROSPECT_RECORD_TYPE).getRecordTypeId();
        Contact objDummyContact = null;
        if (!Test.isRunningTest()) {            
            try {
                objDummyContact = [SELECT Id from Contact WHERE Name = :CONTACT_NAME and Is_Active__c = true limit 1];
                ilib_LogEvent.info('objDummyContact found : '+ objDummyContact);
            } 
            catch(QueryException queryException) {
                ilib_LogEvent.info('Dummy contact not found, using random contact instead');
                ApexExceptions.emit(LOG_TITLE, 'Dummy contact not found, using random contact instead',ilib_LogEvent.SERVICE);
                objDummyContact = [SELECT Id from Contact WHERE Is_Active__c = true limit 1];
            }
        }

        for (Account acc : lstAcc) {
            if (acc.RecordTypeId == prospectRTId && !String.isBlank(acc.Email_Channel_Partner__c) && channelPartner.Is_Sales_Rep__c && acc.Partner_Request__c != null) {
                Partner_Request__c newPR = new Partner_Request__c(Id = acc.Partner_Request__c, Status__c = 'Accepted');
                prList.add(newPR);

                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setTemplateId(lstEmailTemplate[0].Id);
                mail.setToAddresses(new String[] {acc.Email_Channel_Partner__c});
                if (!Test.isRunningTest()) {
                    mail.setTargetObjectId(objDummyContact.Id);
                }
                mail.setWhatId(acc.Id);
                mail.setSaveAsActivity(false);
                mail.setTreatTargetObjectAsRecipient(false);                
                mails.add(mail);
            }
        }
        if (!prList.isEmpty()) {
            update prList;
        }
        if (!mails.isEmpty() && !Test.isRunningTest()) {
            Messaging.sendEmail(mails);
        }  
    }

    /**
    * @author Enrique Reyes
    * @date   2024-06-17
    * @description Before update trigger method
    * CMCM-8183 Move logic from Account: Update status after ERP Id populated workflow to onBeforeUpdate trigger.
    **/
    public override void onBeforeUpdate(Map<Id, SObject> oldRecords) {
        Set<Id> parentAccountIds = UtilsCollection.getSetOfIds(records, 'parentId');
        Map<Id, Account> parentAccounts = new Map<Id, Account>(new AccountsSelector().selectAccounts(parentAccountIds));

        for(Id idAccRecords : oldRecords.keySet()) {
            Account objNewAccount = (Account) Trigger.newMap.get(idAccRecords);
            Account objOldAccount = (Account) oldRecords.get(idAccRecords);

            if(objOldAccount.ERP_Customer_Id__c == null && objNewAccount.ERP_Customer_Id__c != null && !ACCOUNT_GROUPS.contains(objNewAccount.Account_Group__c)) {
                objNewAccount.Account_Status__c = Label.Account_Account_Status_Active_Prospect;
                objNewAccount.Address_Status__c = Label.Account_Address_Status_Verified;
            }

            AccountsAutomatedService.updateTierWhenParentIDIsAvailable(objNewAccount, objOldAccount, parentAccounts);
            AccountsAutomatedService.updateSuspensionRejectionReason(objNewAccount);
            AccountsAutomatedService.setStatus(objNewAccount, objOldAccount);
        }
    }

    /*
    * Comments are added to fix code scan issues
    */
    public override void onAfterUpdate(Map<Id, SObject> oldRecords) {

        //PM-33:pm-430 
        List<Account> updateAcclist = new  List<Account>();
        Set<Id> accountsToUpdateSAP = new Set<Id>();
        List<Account> updateChildrenAccountsTier = new List<Account>();
        List<Account> account2Update = new List<Account>();
         
        for(Id idAccRecords : oldRecords.keySet()) {
            Account objNewAccount = (Account) Trigger.newMap.get(idAccRecords);
            Account objOldAccount = (Account) oldRecords.get(idAccRecords);
            if(objOldAccount.R_Q_Contact_Eligible__c != objNewAccount.R_Q_Contact_Eligible__c) {
                updateAcclist.add(objNewAccount);
            }
            
            if(objOldAccount.ERP_Customer_Id__c == null && objNewAccount.ERP_Customer_Id__c != null) {
                accountsToUpdateSAP.add(objNewAccount.id);
            }

            if(isActiveProspect(objNewAccount) || isActive(objNewAccount)) { // Is active?
                if(objOldAccount.Clinical_Type__c != objNewAccount.Clinical_Type__c) { // does Clinical_Type__c change?
                    accountsToUpdateSAP.add(objNewAccount.id);
                }
            }

            if(objOldAccount.Tier__c != objNewAccount.Tier__c) { // has change on tier?. Child accounts need to change as well.
                updateChildrenAccountsTier.add(objNewAccount);
            }

            if(objNewAccount.Is_Updated_By_System__c) { 
                // Turn OFF Is_Updated_By_System__c flag async
                account2Update.add(new Account(id = objNewAccount.id, Is_Updated_By_System__c = false));
            }
        }

        if(!updateAcclist.isEmpty()) {
           updateRQConEligibleAccount(updateAcclist);
        } 
        //pm-33/pm-430 ends

        retriggerTerritoryRules(oldRecords);

        AccountsAutomatedService.accountUpdateTierForChildProspects(updateChildrenAccountsTier);

        // if the owner was changed and this account is marked as a UC on some opportunities,
        // then those opportunities and related CRF must be shared with the new account owner
        if (!isInsertOperationForObject())
        {
            // find IDs of accounts where the owner changed
            List<Account> changedOwnerRecords = UtilsObject.filterForFieldChanges(records, oldRecords, new List<String> {'OwnerId'});
            Set<Id> changedOwnerIds = UtilsCollection.getSetOfIds(changedOwnerRecords, 'Id');
            List<Account> populatedAccounts = new AccountsSelector().selectAccounts(changedOwnerIds); // same changedOwnerRecords but with related objecs fields.

            AccountsAutomatedService.updateTAMandDSMvalues(populatedAccounts, changedOwnerIds);

            // owner change could affect opportunity and quote sharing to the UC owner
            // call those services to calculate sharing
            if (!changedOwnerIds.isEmpty())
            {
                // that leaves sharing with the old owner
                List<Opportunity> opportunitiesToShare = new OpportunitySelector().selectByAccountOrUCIds(changedOwnerIds);
                //Rahul: DPC-25384 Modified below lines to call new sharing method
                //DCP-38968: Start- Add Opportunity ids for
                TAPS_OrchestratorInterface tapsOrchestrator = (TAPS_OrchestratorInterface)Type.forName('TAPS_Orchestrator').newInstance();//DCP-44091 
                tapsOrchestrator.recalculateRecordChanges(UtilsCollection.getSetOfIds(opportunitiesToShare,'Id'), Opportunity.SObjectType);//DCP-44091
                //DCP-38968: End- Add Opportunity ids for 
                
            }

            // if certain installed asset fields were changed on the account then this is probably a distributor account
            // requirement is to search for distributor users, then see which accounts they have ETM access to (assumed to be UCs)
            // then look for installed products on those UCs that have the same values as this update
            // for all that match, share the installed products to the distributor users
            if (!hasRunPartnerSharing)
            {
                List<Account> changedProductPropertyRecords = UtilsObject.filterForFieldChanges(records, oldRecords, new List<String> { 'Product_Group__c', 'Regulatory_Type__c' });
                // assume these accounts to be distributors since the product properties were changed
                Set<Id> changedDistributorIds = UtilsCollection.getSetOfIds(changedProductPropertyRecords, 'Id');
                if (!changedDistributorIds.isEmpty())
                    hasRunPartnerSharing = InstalledProductsService.shareWithDistributorUsers(changedDistributorIds);
            }
        }
        
        if(!account2Update.isEmpty()) {
            update account2Update;
        }
        
        for(Id accId : accountsToUpdateSAP) {
            Account objNewAccount = (Account) Trigger.newMap.get(accId);
            ProspectAccountAddressValidationControl.submitUpdateOutboundRequest(objNewAccount);
        }
    }

    /**
     * @author Todd Newman
     * @date   2019-09-11
     * @description    DCP-28245: update account territory if control checkboxes were changed
     **/
    private void retriggerTerritoryRules(Map<Id, SObject> oldRecords)
    {
        if (restUpdateHasBeenTriggered) return;

        // filter for accounts where the control checkbox values changed
        // if any were found, trigger a faux update via REST in order to run territory rules
        // the return is a map of account ID to website which will be used for the faux update
        Map<Id, String> etmRetriggerAccountDetails = filterForAccountsThatNeedTerritoryRetrigger(oldRecords);
        if (etmRetriggerAccountDetails.isEmpty()) return;

        restUpdateHasBeenTriggered = true;
        executeRestUpdate(etmRetriggerAccountDetails);
    }

    /**
     * @author Todd Newman
     * @date   2019-09-11
     * @description    DCP-28245: look for accounts where one of the territory rule control checkboxes have changed
     * those checkboxes being
     *    Exclude_from_rules_Even_Internal__c
     *    Exclude_from_rules_Even_Channel_Partner__c
     *    Exclude_from_rules_Internal__c (existing field now used for odd quarters)
     *    Exclude_from_rules_Channel_Partner__c (existing field now used for odd quarters)
     * for any matching accounts, return a map of ID to website
     **/
    private Map<Id, String> filterForAccountsThatNeedTerritoryRetrigger(Map<Id, SObject> oldRecords)
    {
        // website being an innocuous update we can make over rest
        // real purpose of the update is to set the header which triggers ETM recalc
        Map<Id, String> idToWebsite = new Map<Id, String>();

        for (Account a : (List<Account>)records)
        {
            Account oldVals = (Account)oldRecords.get(a.Id);

            if (oldVals.Exclude_from_rules_Even_Internal__c != a.Exclude_from_rules_Even_Internal__c)
                idToWebsite.put(a.Id, a.Website);
            if (oldVals.Exclude_from_rules_Even_Channel_Partner__c != a.Exclude_from_rules_Even_Channel_Partner__c)
                idToWebsite.put(a.Id, a.Website);
            if (oldVals.Exclude_from_rules_Internal__c != a.Exclude_from_rules_Internal__c)
                idToWebsite.put(a.Id, a.Website);
            if (oldVals.Exclude_from_rules_Channel_Partner__c != a.Exclude_from_rules_Channel_Partner__c)
                idToWebsite.put(a.Id, a.Website);
        }

        System.debug('retrigger ETM rules on these accounts ' + idToWebsite.keySet());
        return idToWebsite;
    }

    /**
     * @author Todd Newman
     * @date   2019-09-11
     * @description    DCP-28245: execute a faux update of the account IDs passed in
     * the REST header Sforce-Auto-Assign is set to true so that the ETM rules are rerun for the accounts
     **/
    @future(callout=true)
    public static void executeRestUpdate(Map<Id, String> idToWebsite)
    {
        if (idToWebsite == null || idToWebsite.isEmpty()) return;

        String restBody = buildRestBody(idToWebsite);
        HttpRequest req = buildRestRequest(restBody);
        HttpResponse res;
        if (Test.isRunningTest())
        {
            TestAccountsMockEtmUpdate mockCallout = new TestAccountsMockEtmUpdate();
            res = mockCallout.respond(req);
        }
        else
        {
            res = new Http().send(req);
        }

        processRestResponse(res);
    }

    @TestVisible
    private static HttpRequest buildRestRequest(String restBody)
    {
        String updateAccountsPath = '/services/data/' + UtilsRest.APEX_WEBSERVICE_VERSION + '/composite/sobjects?_HttpMethod=PATCH';

        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        req.setEndpoint('callout:Salesforce_Org' + updateAccountsPath);
        req.setHeader('Sforce-Auto-Assign', 'TRUE');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(restBody);

        return req;
    }

    @TestVisible
    private static String buildRestBody(Map<Id, String> idToWebsite)
    {
        if (idToWebsite == null || idToWebsite.isEmpty()) return '';

        String restBody = '{\n' +
        '   "allOrNone" : false,\n' +
        '   "records" : [';

        String arrayContents = '';
        for (Id accountId : idToWebsite.keySet())
        {
            arrayContents += '    {\n' +
                '      "attributes" : {"type" : "Account"},\n' +
                '      "id" : "' + accountId + '",\n' +
                '      "Website" : "' + idToWebsite.get(accountId) + '"\n' +
                '   },\n';
        }
        arrayContents = arrayContents.substring(0, arrayContents.length() - 2);

        restBody += arrayContents + ']\n' +
            '}';

        System.debug('REST Body\n' + restBody);
        return restBody;
    }

    @TestVisible
    private static void processRestResponse(HttpResponse res)
    {
        System.debug('HTTP Result\n' + res);

        if (res.getStatusCode() != STATUS_CODE)
        {
            //CMSI-38: new emit method accepting tthree parameters (String source, String message, String workstream)
            ApexExceptions.emit('Accounts.executeRestUpdate', 'REST call to trigger Account ETM rules failed ' + res.getBody(), ilib_LogEvent.SALES );
        }

        List<REST_RECORD_RESULT> recordResults = (List<REST_RECORD_RESULT>)JSON.deserialize(res.getBody(), List<REST_RECORD_RESULT>.class);
        System.debug(recordResults);

        for (REST_RECORD_RESULT recordResult : recordResults)
        {
            if (!recordResult.success)
            {
                ApexExceptions.emit('Accounts.executeRestUpdate', recordResult.id, 'Unable to trigger Account ETM rule run ' + recordResult.errors, ilib_LogEvent.SALES);
            }
        }
    }

    
    /**
     * @author Saddam
     * @date   2022-02-22
     * @description   Check the account condition and update or insert account,pm-33 and pm-430
     * param: Account list
     **/
    public static void updateRQConEligibleAccount(List<Account> accObjList ) {
      
        ilib_LogEvent.push(LOG_TITLE + '.updateRQConEligibleAccount()');
       //Returns the Accountids by passing account object
        Set<Id> setOfAccIds = UtilsCollection.getSetOfIds(accObjList, 'Id');
        ilib_LogEvent.message('setOfAccIds@@: '+setOfAccIds);

        if (!Test.isRunningTest()) {
            //Returns List<Account> for update after checking the related contact/acr records
            List<Account> accUpdateList = AccountsService.updateRqAccount(setOfAccIds);
            ilib_LogEvent.message('accUpdateList@@: '+accUpdateList);

            //Update the Above Accounts in Queueable Class
                if(trigger.isupdate == true || system.isBatch()  && !stoprecurssion && !accUpdateList.isEmpty() && accUpdateList!=Null ) {
                    stoprecurssion =true;
                    ilib_Queueablethread queueableThread = new ilib_Queueablethread('AccountsUpdate');        
                    UpdateRQEligibleAccountQueueable objAccountQueueable= new UpdateRQEligibleAccountQueueable(accUpdateList);
                    queueableThread.logAndQueue(objAccountQueueable,'UpdateRQEligibleAccountQueueable','execute'); 
                    ilib_QueueableManager.enqueueJob(queueableThread,ilib_LogEvent.SALES);                    
                }   
        } 
        ilib_LogEvent.pop();         
    }

    private Boolean isActiveProspect(Account record) {
        return record.Account_Group__c == GROUP_PROSPECT && record.Account_Status__c == STATUS_ACTIVE_PROSPECT;
    }

    private Boolean isActive(Account record) {
        return (record.Account_Group__c == GROUP_ULTIMATE_CONSIGNEE ||record.Account_Group__c == GROUP_SOLD_TO ||record.Account_Group__c == GROUP_DISTRIBUTOR)
        && record.Account_Status__c == STATUS_ACTIVE;
    }
}