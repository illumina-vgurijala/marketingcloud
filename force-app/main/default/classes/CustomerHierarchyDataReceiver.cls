/**
* @author Akshay Mohan
* @date   2018-06-3
* @description    US-360:Customer Hierarchy Data Synchronization from SAP to SFDC
* Modification Log:
*       ------------------------------------------------------------------------------------
*       Akshay Mohan         3/07/2018            Original Version
*       Prem Ranjan          25-April-2022        CodeScan Fix:Avoid Literals in If condition
*       Himanshu             30/03/2022           Code Scan Fixes     
*       ------------------------------------------------------------------------------------
*/

@RestResource(urlMapping='/CustomerHierarchySyncInterface/*')
global with sharing class CustomerHierarchyDataReceiver extends ilib_RestReceiver {

    private static List<CustomerMasterWrapper.accountheader> accountList;
    private static String erpCustomerId;
    public static final String VALUE_D = 'D';

    /**
    * @author  Akshay Mohan
    * @description HTTP Post method
    * @params NA
    * @return void
    **/
    @HttpPost
    global static void upsertIncomingValues()
    {
        // instantiate this class so that base class logic is available
        CustomerHierarchyDataReceiver instantiated = new CustomerHierarchyDataReceiver();
        // get the (non-static context) details
        ilib_RestInterface.InterfaceDetails interfaceDetails = instantiated.interfaceDetails;
        ilib_LogEvent.setTitle(interfaceDetails.name);

        String strRestError = null;
        Id primaryRecordId;
        String strJsonInput = ((null != RestContext.request.requestBody) ? (RestContext.request.requestBody.toString()) : (null));
        System.debug(LoggingLevel.INFO, 'JSON Input:\n' + strJsonInput);

        ilib_LogInterface.LogDetails log = ilib_LogInterface.initiateLog(interfaceDetails, strJsonInput, RestContext.request);

        try
        {
            if (String.isBlank(strJsonInput)) throw new UtilsRest.InterfaceException('Input JSON is missing');

            deserializeInputs(strJsonInput);
            //doing this so that only the JSON for hierarchy is sent.
            //Otherwise all account header fields come in log.
            ilib_LogInterface.addJsonToLog(log, strJsonInput);

            primaryRecordId = upsertIncomingValuesImpl();
        }
        catch (Exception e)
        {
            strRestError = UtilsRest.handleCustomRestError(e);
        }

        Boolean isSuccess = String.isBlank(strRestError);
        if (isSuccess)
        {
            UtilsRest.handleCustomRestSuccess();
        }

        ilib_LogInterface.finalizeLog(
            log,
            (isSuccess ? ilib_LogInterface.RESULT_SUCCESS : ilib_LogInterface.RESULT_FAIL),
            (isSuccess ? null : 'Exception: ' + strRestError),
            primaryRecordId
        );

        if (!isSuccess)
        {
            KnownErrorNotifications.checkForKnownErrors(interfaceDetails, log.logRecordId, erpCustomerId, erpCustomerId, ilib_LogInterface.RESULT_FAIL, strRestError);
            
            ilib_LogEvent.push('upsertIncomingValues');
            ilib_LogEvent.error('Error Description' + strRestError +'----');
            ilib_LogEvent.pop();
            /*
            ilib_LogEvent.quickEmit(
                interfaceDetails.name + ' failed',
                new Map<String, String> { 'Error Description' => strRestError }
            );*/
        }
        ilib_LogEvent.emit();
    }

    private static void deserializeInputs(String jsonInput)
    {
        accountList = (List<CustomerMasterWrapper.accountheader>) System.JSON.deserialize(jsonInput, List<CustomerMasterWrapper.accountheader>.class);
        System.debug('accountList::::'+accountList);
    }

    private static Id upsertIncomingValuesImpl()
    {
        if (accountList == null) return null;

        Account oneAccount;  // assume only one account will be present

        ilib_UpsertHelpers.AccountUnitofWorkHelper accountWork = new ilib_UpsertHelpers.AccountUnitofWorkHelper();

        //Map ExternalId to Account Object
        Map<String,Account> extIdToAccount = new Map<String, Account>();
        Map<String,Account> parentExtIdToAccount = new Map<String, Account>();
        Map<String,Account> accountTobeDeleted = new Map<String, Account>();

        ilib_SObjectUnitOfWork uow = new ilib_SObjectUnitOfWork(
            new List<Schema.SObjectType> { Account.SObjectType }
        );

        uow.registerWork(accountWork);
        System.debug('accountList===' + accountList);

        // get all account ERP IDs
        Set<String> erpIds = new Set<String>();
        for (CustomerMasterWrapper.accountheader wrapAccount : accountList)
            erpIds.add(wrapAccount.AccountNumber);

        // match account ERP IDs to existing parent ERP ID values
        List<Account> parentDetails = [SELECT Id, ERP_Customer_Id__c, ParentId, Parent.ERP_Customer_Id__c FROM Account WHERE ERP_Customer_Id__c IN :erpIds];
        Map<String, String> erpIdToParentErpId = new Map<String, String>();
        for (Account acc : parentDetails)
            if (acc.ParentId != null) erpIdToParentErpId.put(acc.ERP_Customer_Id__c, acc.Parent.ERP_Customer_Id__c);
        System.debug('for delete operation, erpIdToParentErpId = ' + erpIdToParentErpId);

        for (CustomerMasterWrapper.accountheader wrapAccount : accountList)
        {
            Account accountObj = wrapAccount.getSobjectForHierarchy();
            extIdToAccount.put(accountObj.ERP_Customer_Id__c, accountObj);

            if (wrapAccount.Indicator == VALUE_D)
            {
                System.debug('considering parent delete operation');
                Boolean okToDeleteValue = false;
                if (erpIdToParentErpId.containsKey(wrapAccount.AccountNumber))
                {
                    System.debug('found an account with this ID');
                    if (String.isNotBlank(erpIdToParentErpId.get(wrapAccount.AccountNumber)))
                    {
                        System.debug('found an account with this ID and a parent');
                        if (erpIdToParentErpId.get(wrapAccount.AccountNumber) == wrapAccount.ParentAccount)
                        {
                            System.debug('found an account with a matching parent ID - delete it');
                            okToDeleteValue = true;
                        }
                    }
                }

                // INC0202565 - only delete the ERP ID if the value received matches the database value
                if (okToDeleteValue)
                    accountTobeDeleted.put(accountObj.ERP_Customer_Id__c, accountObj);
            }
            else
                parentExtIdToAccount.put(wrapAccount.ParentAccount, accountObj);
        }

        System.debug('extIdToAccount: '+extIdToAccount);
        System.debug('parentExtIdToAccount: '+parentExtIdToAccount);
        System.debug('accountTobeDeleted: '+accountTobeDeleted);

        //loop to populate Id column of Account objects based on ExternalId
        for (Account objAccount : [Select id,ERP_Customer_Id__c,ParentId From Account Where ERP_Customer_Id__c in :extIdToAccount.keyset() or ERP_Customer_Id__c in :parentExtIdToAccount.keyset()])
        {
            System.debug('objAccount: '+ objAccount);
            oneAccount = objAccount;
            erpCustomerId = oneAccount.ERP_Customer_Id__c;

            if (parentExtIdToAccount.containsKey(objAccount.ERP_Customer_Id__c))
            {
                System.debug('objAccount.ERP_Customer_Id__c'+objAccount.ERP_Customer_Id__c);
                System.debug('parentExtIdToAccount.get(objAccount.ERP_Customer_Id__c)'+parentExtIdToAccount.get(objAccount.ERP_Customer_Id__c));
                parentExtIdToAccount.get(objAccount.ERP_Customer_Id__c).ParentId = objAccount.Id;
                parentExtIdToAccount.get(objAccount.ERP_Customer_Id__c).Is_Updated_By_System__c=true;
                accountWork.registerUpsert(parentExtIdToAccount.get(objAccount.ERP_Customer_Id__c));
            }

            if (accountTobeDeleted.ContainsKey(objAccount.ERP_Customer_Id__c))
            {
                accountTobeDeleted.get(objAccount.ERP_Customer_Id__c).ParentId = null;
                accountTobeDeleted.get(objAccount.ERP_Customer_Id__c).Is_Updated_By_System__c=true;
                accountWork.registerUpsert(accountTobeDeleted.get(objAccount.ERP_Customer_Id__c));
            }
        }

        uow.commitWork();
        return (oneAccount != null ? oneAccount.Id : null);
    }

}