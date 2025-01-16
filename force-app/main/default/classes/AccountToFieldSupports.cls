/***************************************************************************************************************************************
* NAME   : AccountToFieldSupports
* DESCRIPTION  : Domain class for AccountToFieldSupportTrigger.
*
* @AUTHOR : Sandeep Ram Ch.
* @DATE   : 04-July-2018
* 90% Code Coverage :TestAccountToFieldSupports,TestApttusMobileCreateQuote,TestApttusOrderLineItems,TestLMSCertificationDataReceiver.
* 75% Code Coverage :TestAccountToFieldSupports,TestApttusMobileCreateQuote,TestApttusOrderLineItems,TestLMSCertificationDataReceiver.
* MODIFICATION LOG:
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION
* --------------------------------------------------------------------------------------------------------------------------------------
*   Sandeep Ram Ch.            4-July-2018          Initial Version.
*   Akash Kumar                29-Sep-2018          Method to Populate Field Service related Fields on Opportunity(On After Insert,
*                                                   On After Update,On After Delete)
*   Akshay Mohan               24-Sep-2019          DCP-27435 Sharing logic for updated users in Account to Field Supports
*   Todd Newman                1-Nov-2019           INC0234515 utilize platform event to update Opportunities
*   Sarath Pullanikkatt        27-Jan-2020          Removed updateCcEmailOnWorkOrder() and related logic as it was causing bulk
*                                                   Work Order updates resulting in Apex CPU time limit exceeded error.
*   Sibin P Kuriakose          25-Aug-2022          [CMSI-218]: Instrumention of the Class.
****************************************************************************************************************************************/
public with sharing class AccountToFieldSupports extends ilib_SObjectDomain {
	
	public static final String PARTNER = 'Partner';
    public static final String PRIMARY_FAS = 'Primary Field Application Scientist';
    public static final String SECONDARY_FAS = 'Secondary Field Application Scientist';
    public static final String PRIMARY_FSE = 'Primary Field Service Engineer';
    public static final String SECONDARY_FSE = 'Secondary Field Service Engineer';
    public static final String FAS_MANAGER = 'Field Application Manager';
    public static final String FSE_MANAGER = 'Field Service Manager';
    public static final String PARTNER_FSE = 'Partner Primary Field Service Engineer';
    public static final String PARTNER_FAS = 'Partner Primary Field Application Scientist';
    public static final Set<String> ROLES_WHO_GET_SHARED_CRF = new Set<String> { PRIMARY_FAS, PRIMARY_FSE, FAS_MANAGER, FSE_MANAGER, PARTNER_FSE, PARTNER_FAS };
    public static final String STRING_WORK_ORDER_STATUS_COMPLETED = 'Completed';
    public static final String STRING_WORK_ORDER_STATUS_CLOSED = 'Closed';
    public static final String STRING_WORK_ORDER_STATUS_REOPEN_REQUESTED = 'Reopen Requested';
    public static final String LOG_TITLE = 'AccountToFieldSupports'; //CMSI-218

    /**
    * @description Constructor with List of Account_to_Field_Support__c
    * @author 
    * @param sObjectList 
    **/
    public AccountToFieldSupports (List<Account_to_Field_Support__c> sObjectList)
    {
        super(sObjectList);
    }

 /**
    *  @author Sibin P Kuriakose
    *  @description  CMSI-218,method will return the workstream
    *  @return string
    **/

    public override string getWorkstream(){

        return ilib_LogEvent.SERVICE;

    }

    /**
     * Boilerplate which is required for base class instantiation logic
     */
    public class Constructor implements ilib_SObjectDomain.IConstructable
    {
        /**
        * @description Returns new AccountToFieldSupports Obj
        * @author 
        * @param sObjectList 
        * @return ilib_SObjectDomain 
        **/
        public ilib_SObjectDomain construct(List<SObject> sObjectList)
        {
            return new AccountToFieldSupports (sObjectList);
        }
    }

    /**
    * @description update FieldSupport Ids On  Account after Insert
    * @author 
    **/
    public override void onAfterInsert()
    {
        Set<ID> setFieldSupportAccountIds = new Set<Id>();

        for (Account_to_Field_Support__c objAccountToFieldSupport : (List<Account_to_Field_Support__c>)records)
        {
            if (objAccountToFieldSupport.Account__c != null && !objAccountToFieldSupport.User_Role__c.contains(PARTNER) )
                setFieldSupportAccountIds.add(objAccountToFieldSupport.Account__c);
        }

        if (!setFieldSupportAccountIds.isEmpty()) {
            updateFieldSupportIdsOnAccount(setFieldSupportAccountIds);
        }

        populateFieldServiceFieldsOnOpportunity(records, null);
    }

    /**
    * @description update FieldSupport Ids On  Account after Delete
    * @author 
    **/
    public override void onAfterDelete()
    {
        populateFieldServiceFieldsOnOpportunity(records, null);
        Set<Id> setFieldSupportAccountIds = new Set<Id>();
        for (Account_to_Field_Support__c objAccountToFieldSupport : (List<Account_to_Field_Support__c>)records)
        {
            if (objAccountToFieldSupport.Account__c != null && !objAccountToFieldSupport.User_Role__c.contains(PARTNER))
                setFieldSupportAccountIds.add(objAccountToFieldSupport.Account__c);
        }

        if (!setFieldSupportAccountIds.isEmpty())
            updateFieldSupportIdsOnAccount(setFieldSupportAccountIds);
    }

    /**
    * @description Populate FieldService Fields On Opportunity AFter Update
    * @author 
    * @param mapOld 
    **/
    public override void onAfterUpdate(Map<Id, SObject> mapOld)
    {
        populateFieldServiceFieldsOnOpportunity(records, (Map<Id, Account_to_Field_Support__c>)mapOld);
    }

    /**
     * @author          Akash Kumar
     * @date            2018-09-29
     * @description     Stamp FS user IDs on related opportunities
     */
    public static void populateFieldServiceFieldsOnOpportunity(List<Account_to_Field_Support__c> lstAcctToFieldSupport, Map<Id,Account_to_Field_Support__c> idToOldAcctToFieldSupport)
    {
        // filter account IDs on these scenarios
        //    A2FS was inserted or deleted
        //    A2FS role was updated and the old or new role means sharing is affected
        ilib_LogEvent.push(LOG_TITLE + 'populateFieldServiceFieldsOnOpportunity'); //CMSI-218
        Set<Id> setAccountIds = new Set<Id>();
        for (Account_to_Field_Support__c afs : lstAcctToFieldSupport)
        {
            if ( (idToOldAcctToFieldSupport == null && ROLES_WHO_GET_SHARED_CRF.contains(afs.User_Role__c)) // insert or delete operation
                || (idToOldAcctToFieldSupport != null // update operation
                    && afs.User_Role__c != idToOldAcctToFieldSupport.get(afs.id).User_Role__c  // role changed
                    && (ROLES_WHO_GET_SHARED_CRF.contains(afs.User_Role__c) || ROLES_WHO_GET_SHARED_CRF.contains(idToOldAcctToFieldSupport.get(afs.id).User_Role__c))
                )
            ) {
                setAccountIds.add(afs.Account__c);
                ilib_LogEvent.message('new account to field support' + afs.Account__c); //CMSI-218
            }
        }
        ilib_LogEvent.info('setAccountIds-->' + setAccountIds);

        // if no accounts then nothing more to do
        if (setAccountIds.isEmpty()) {
            ilib_LogEvent.pop(); //CMSI-218
            return;
        }

        // INC0234515: publish event to set field service user names on opportunities
        OpportunityServiceUserRecalcs.publish(setAccountIds);
        ilib_LogEvent.info('Completed successfully'); //CMSI-218
        ilib_LogEvent.pop(); //CMSI-218
    }

    /**
     *  @AUTHOR:  Dipika
     *  @DESCRIPTION: This method updates field support ids on Account
     *  @PARAM :  set<Id> setFieldSupportAccountIds
     */
	private void updateFieldSupportIdsOnAccount(set<Id> setFieldSupportAccountIds)
    {
        ilib_LogEvent.push(LOG_TITLE + 'updateFieldSupportIdsOnAccount'); //CMSI-218
        Map<Id, String> fieldSupportIdMap = new Map<Id, String>();
        List<Account> accToUpdateLst = new List<Account>();
        Map<Id, List<Account_to_Field_Support__c>> mapAccToFieldSupport = new Map<Id, List<Account_to_Field_Support__c>>();
        //DCP-27435: Account to Field Support related sharing to be done by TAPS Deferred job
        // since Admins don't maintain Account To Field Supports and other profiles may not have access to all required objects
        Set<Id> setATFSIds = new Set<Id>();

        for (Account_to_Field_Support__c objFieldSupport : new AccountToFieldSupportSelector().selectAccountToFieldSupport(setFieldSupportAccountIds))
        {
            if(!objFieldSupport.User_Role__c.contains(PARTNER)){
			setATFSIds.add(objFieldSupport.Account__c); 

            String uniqueUserIdentifier = objFieldSupport.User__r.SVMXC__Salesforce_User__r.FederationIdentifier != null ?
                                          objFieldSupport.User__r.SVMXC__Salesforce_User__r.FederationIdentifier : '';

            uniqueUserIdentifier = objFieldSupport.User__r.SVMXC__Salesforce_User__r.Alias != null ?
                                   uniqueUserIdentifier + objFieldSupport.User__r.SVMXC__Salesforce_User__r.Alias : uniqueUserIdentifier;

            if (!mapAccToFieldSupport.containsKey(objFieldSupport.Account__c)){
                mapAccToFieldSupport.put(objFieldSupport.Account__c, new List<Account_to_Field_Support__c>());
            }
            
            mapAccToFieldSupport.get(objFieldSupport.Account__c).add(objFieldSupport);
            fieldSupportIdMap.put(objFieldSupport.Id,uniqueUserIdentifier);
			}
        }

        ilib_LogEvent.info('Adding FieldSupport ' + mapAccToFieldSupport.keySet()); //CMSI-218

        for (Id accountId : mapAccToFieldSupport.keySet())
        {
            String fieldSupportIds = ''; 

            Account objAccount = new Account(Id = accountId);
            for (Account_to_Field_Support__c objFieldSupport : mapAccToFieldSupport.get(accountId))
            {
                ilib_LogEvent.message('working on accoun to Field Service  ' + objFieldSupport.Id); //CMSI-218
                if (!fieldSupportIdMap.containsKey(objFieldSupport.Id)
                    || (String.isBlank(fieldSupportIdMap.get(objFieldSupport.Id))))
                    continue;

                if (!fieldSupportIds.contains(fieldSupportIdMap.get(objFieldSupport.Id)))
                    fieldSupportIds = (fieldSupportIds != '' ? fieldSupportIds + ',' + fieldSupportIdMap.get(objFieldSupport.Id) : fieldSupportIdMap.get(objFieldSupport.Id));
            }

            if (fieldSupportIds != '')
            {
                objAccount.Field_Support_IDs__c = fieldSupportIds;
                accToUpdateLst.add(objAccount);
            }
        }

        ilib_LogEvent.info('Updating Ids  ' + UtilsCollection.getSetOfIds(accToUpdateLst)); //CMSI-218

        if (accToUpdateLst.size() > 0)
        {
            update accToUpdateLst;
        }

        if (!setATFSIds.isEmpty())
        {
            TAPS_DeferredRun.deferSharing('Account_to_Field_Support__c', setATFSIds);
        }

        ilib_LogEvent.pop(); //CMSI-218
    }

}