/**
* @author Akshay Mohan
* @date   2018-06-26
* @description    US-351:Customer Master Synchronization to DCP (INT_MDM-030-001)
*
* Modification Log:
*       ------------------------------------------------------------------------------------
*       Akshay Mohan         27/06/2018            Original Version 
*       Swapna Satapathy     18/09/2018            DCP-11856 updates
*       Roopal Verma         29/11/2018            DCP-16987, calling batch for sales area extension
*       Roopal Verma         4/2/2019              DCP-21910, marking deleted account relationships inactive
*       Roopal Verma         26/09/2019            DCP-28565, Added logic for Bank detail fields
*       Aman Tyagi           30/03/2022            CodeScan Fixes
*       Parthasarathy D      25-Aug-2022           DCP-55534
*       ------------------------------------------------------------------------------------
*/

@RestResource(urlMapping='/CustMasterSyncInterface/*')
global with sharing class CustomerMasterDataReceiver extends ilib_RestReceiver {

    private static List<CustomerMasterWrapper.AccountHeader> wrapCustomerMasterList;
    private static String erpCustomerId;

    public static final String STRING_LABEL_LOCKER = 'Locker';
    public static final String STRING_LABEL_TRUNK = 'Trunk';
    public static final String STRING_LABEL_SERVICE_CENTER = 'Service Center';
    public static Set<String> setAccountDiscountTierERPs = new Set<String>();  // DCP-55534
    public static Set<String> setSalesOrgIDs = new Set<String>();  // DCP-55534
    public static Set<String> setDistributionChannel = new Set<String>();  // DCP-55534
    public static final String CODEPARAMETERSALESORGFORADT = 'Sales_Organization_Applicable_for_ADT'; // DCP-55534

    @HttpPost
    /*
    * @Author:  Akshay Mohan 
    * @Description : static method for upsert the incoming values
    * @param: null
    * @return: void
    */
    global static void upsertIncomingValues()
    {
        // get the (non-static context) details
        CustomerMasterDataReceiver instantiated = new CustomerMasterDataReceiver();
        ilib_RestInterface.InterfaceDetails interfaceDetails = instantiated.interfaceDetails;
        ilib_LogEvent.setTitle(interfaceDetails.name);

        String strRestError = null;
        Id primaryRecordId;
        String strJsonInput = ((null != RestContext.request.requestBody) ? (RestContext.request.requestBody.toString()) : (null));
        System.debug(LoggingLevel.INFO, 'JSON Input:\n' + strJsonInput);

        ilib_LogInterface.LogDetails log = ilib_LogInterface.initiateLog(interfaceDetails, JSON.serializePretty(JSON.deserializeUntyped(strJsonInput)));

        try
        {
            if (String.isBlank(strJsonInput)) throw new UtilsRest.InterfaceException('Input JSON is missing');

            deserializeInputs(strJsonInput);
            
            primaryRecordId = upsertIncomingValuesImpl();
        }

        catch (Exception e)
        {
            strRestError = UtilsRest.handleCustomRestError(e);
            system.debug('----->....>'+e);
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

    /*
    * @Author: Roopal Verma  
    * @Description : static method for deseralizing the jsonInputs
    * @param: String jsonInput
    * @return: void
    */
    global static void deserializeInputs(String jsonInput)
    {
        wrapCustomerMasterList = (List<CustomerMasterWrapper.AccountHeader>) System.JSON.deserialize(jsonInput, List<CustomerMasterWrapper.AccountHeader>.class);
    }

    /*
    * @Author: Roopal Verma  
    * @Description : static method for upsert the incoming values
    * @param: null
    * @return: Id
    */
    global static Id upsertIncomingValuesImpl()
    {
        Account oneAccount; // assume just one account incoming

        // Register custom helpers
        ilib_UpsertHelpers.AccountUnitofWorkHelper accountWork = new ilib_UpsertHelpers.AccountUnitofWorkHelper();
        ilib_UpsertHelpers.SalesAreaUnitofWorkHelper salesAreaWork = new ilib_UpsertHelpers.SalesAreaUnitofWorkHelper();
        ilib_UpsertHelpers.CustMasterUnitofWorkHelper custMasterWork = new ilib_UpsertHelpers.CustMasterUnitofWorkHelper();
        ilib_UpsertHelpers.AccountRelationshipUnitofWorkHelper relationshipWork = new ilib_UpsertHelpers.AccountRelationshipUnitofWorkHelper();
        ilib_UpsertHelpers.DisountTierUnitofWorkHelper discountTierWork = new ilib_UpsertHelpers.DisountTierUnitofWorkHelper();    // DCP-55534
        
        //Map ExternalId to Object 
        Map<String,Account> extIdToAccount = new Map<String,Account>();
        Map<String,Customer_Master_Data__c> extIdToCMD = new Map<String,Customer_Master_Data__c>();
        Map<String,Account_Sales_Area__c> extIdToSalesArea = new Map<String,Account_Sales_Area__c>();
        Map<String,Account_Relationship__c> extIdToAccRelationship = new Map<String,Account_Relationship__c>();
        
        //unit of work
        ilib_SObjectUnitOfWork uow = new ilib_SObjectUnitOfWork(
            new List<Schema.SObjectType> {
                Account.SObjectType,
                Account_Sales_Area__c.SObjectType,
                Account_Relationship__c.SObjectType,
                Customer_Master_Data__c.SObjectType,
                Account_Discount_Tier__c.SObjectType  // DCP-55534
        });

        uow.registerWork(accountWork);
        uow.registerWork(custMasterWork);
        uow.registerWork(salesAreaWork);
        uow.registerWork(relationshipWork);
        uow.registerWork(discountTierWork);  // DCP-55534
        
        Set<String> setAccRelationsERPId = new Set<String>();
        Set<String> setAccountERPId = new Set<String>();
        Set<String> setASAERPId = new Set<String>();
                
        System.debug('wrapCustomerMasterList=='+wrapCustomerMasterList);
        Set<String> setFilteredAccountGroups = new Set<String>{Label.AccountGroupDistributor, Label.AccountGroupSoldTo,
                                                                Label.AccountProspect, Label.AccountProspect,
                                                                Label.AccountGroupUltimateConsignee};
        if (wrapCustomerMasterList!= null)
        {
            for (CustomerMasterWrapper.accountHeader wrapAccount: wrapCustomerMasterList)
            {
                Account accountObj;
                if(setFilteredAccountGroups.contains(wrapAccount.Account_Group) 
                    || (Label.AccountGroupLegacy.equals(wrapAccount.Account_Group) && String.isNotBlank(wrapAccount.Id))){
                    accountObj=wrapAccount.getSObject();
                    oneAccount = accountObj;
                    erpCustomerId = oneAccount.ERP_Customer_Id__c;
                    accountObj.Is_Updated_By_System__c=true;
                    extIdToAccount.put(accountObj.ERP_Customer_Id__c, accountObj);
                    accountWork.registerUpsert(accountObj);
                } 
				setAccountERPId.add(wrapAccount.ERP_Customer_Id);
                system.debug('--setAccountERPId--'+setAccountERPId);
                Customer_Master_Data__c cmdObj = new Customer_Master_Data__c();
                cmdObj = wrapAccount.getCustMastDataSobject();
				if(wrapAccount.BankGroup != null && wrapAccount.BankGroup.size() > 0){                                      //DCP-28565: Condtion for Bank Details
                    cmdObj.Bank_Account_Number__c = String.IsBlank(wrapAccount.BankGroup[0].Bank_Account_Number) ? '' : wrapAccount.BankGroup[0].Bank_Account_Number;
                    cmdObj.Bank_Name__c = (String.IsBlank(wrapAccount.BankGroup[0].Bank_Name) ? '' : wrapAccount.BankGroup[0].Bank_Name);
                    cmdObj.Bank_Address__c = (String.IsBlank(wrapAccount.BankGroup[0].Country) ? '' : wrapAccount.BankGroup[0].Country) + (String.IsBlank(wrapAccount.BankGroup[0].Country) ? '' : ' ') + (string.IsBlank(wrapAccount.BankGroup[0].City) ? '' : wrapAccount.BankGroup[0].City) + (string.IsBlank(wrapAccount.BankGroup[0].City) ? '' : ' ') + (string.IsBlank(wrapAccount.BankGroup[0].Street) ? '' : wrapAccount.BankGroup[0].Street);
                }
                extIdToCMD.put(cmdObj.ERP_Customer_Id__c,cmdObj);
                custMasterWork.registerUpsert(cmdObj);
                if(wrapAccount.SalesArea!=null)
                    for (CustomerMasterWrapper.SalesArea wrapSalesArea : wrapAccount.SalesArea)
                    {
                        Account_Sales_Area__c sArea = wrapSalesArea.getSObject();
                        setASAERPId.add(sArea.ERP_Account_Sales_Area_Id__c);
                        system.debug('--setASAERPId--'+setASAERPId);
                        uow.registerRelationship(sArea, Account_Sales_Area__c.Customer_Master_Data__c, cmdObj);
                        if(accountObj!=null)
                            uow.registerRelationship(sArea, Account_Sales_Area__c.Account__c, accountObj);
                        salesAreaWork.registerUpsert(sArea);

                        extIdToSalesArea.put(sArea.ERP_Account_Sales_Area_Id__c, sArea);
                        if(wrapSalesArea.AccountRelationship!=null)
                            for (CustomerMasterWrapper.AccountRelationship  wrapAccountRelationship:wrapSalesArea.AccountRelationship)
                            {
                                Account_Relationship__c AccountRelationshipObj = wrapAccountRelationship.getSObject();
                                uow.registerRelationship(AccountRelationshipObj, Account_Relationship__c.Account_Sales_area__c, sArea);
                                relationshipWork.registerUpsert(AccountRelationshipObj);
                                setAccRelationsERPId.add(AccountRelationshipObj.ERP_Account_Relationship_Id__c);
                                extIdToAccRelationship.put(AccountRelationshipObj.ERP_Account_Relationship_Id__c, AccountRelationshipObj);
                            }
                        // DCP-55534
                        upsertAccountDiscountTier(wrapSalesArea,discountTierWork);
                    }
            }
        }
        //Logic to mark deleted Account relationships inactive
        List<Account_Relationship__c> lstAllAccRelationships = new List<Account_Relationship__c>(new AccountRelationshipsSelector().selectByAccERPAndASAERP(setAccountERPId));
        System.debug('--lstAllAccRelationships--'+lstAllAccRelationships);
        for (Account_Relationship__c accRelation : lstAllAccRelationships){
            if(!setAccRelationsERPId.contains(accRelation.ERP_Account_Relationship_Id__c)){
               System.debug('--Inside For--'+accRelation);
               accRelation.IsInactive__c = true;
               relationshipWork.registerUpsert(accRelation);
            }
        }
        // DCP-55534 Logic to mark the Account discount tier records to be inactive.
        if(!setAccountDiscountTierERPs.isEmpty() && !setSalesOrgIDs.isEmpty() && !setDistributionChannel.isEmpty()) {
            List<Account_Discount_Tier__c> listAccountDiscountTier = new AccountDiscountTierSelector().getAccntPricingTiersForErpAndSalesOrgIds(setAccountDiscountTierERPs,setSalesOrgIDs,setDistributionChannel);
            if(listAccountDiscountTier != null && !listAccountDiscountTier.isEmpty())
            for(Account_Discount_Tier__c objAccountDisc : listAccountDiscountTier) {
                objAccountDisc.IsInactive__c = true;                
                discountTierWork.registerUpsert(objAccountDisc);
            }
        }
        System.debug('Sales areas: '+extIdToSalesArea.values());
        System.debug('CMDs: '+extIdToCMD.values());
        System.debug('Relationships: '+extIdToAccRelationship.values());
        
        System.debug('extIdToCMD value: '+extIdToCMD);
        createOrUpdateLocation(extIdToCMD);

        // any business logic for incoming values goes in here
        businessRules(uow, extIdToAccount);
        
        uow.commitWork();
        

        //Calling batch class for sales area extension
        Map<String, String> params = UtilsSettings.getCustomMetadataMap('Batch_AccountSalesArea_Insert');
        Integer batchSize = UtilsSettings.parseIntegerFromSettingsMap(params, 'AccountBatchSize', 100);
        ilib_BatchManager.executeBatch(new BatchUpdateChildRecordsForNewASA(AccountSalesAreas.lstNewASA), batchSize);

        return (oneAccount != null ? oneAccount.Id : null);
    }

    /**
     *  @author  Vishnu Priya Duggineni
     *  @description    US-17616
     */
    public static void businessRules(ilib_SObjectUnitOfWork uow, Map<String,Account> extIdToAccount)
    {
        populateGroupNames(extIdToAccount);
    }
    
    /**
     *  @description    US-17616: Business logic for incoming values for Account Hierarchy to populate group names
     */
    private static void populateGroupNames(Map<String,Account> extIdToAccount)
    {
        Set<String> groupNumbers = new Set<String>();
        for (String accExtId : extIdToAccount.keyset())
        {
            groupNumbers.add(extIdToAccount.get(accExtId).Global_Group_Number__c);
            groupNumbers.add(extIdToAccount.get(accExtId).National_Group_Number__c);
            groupNumbers.add(extIdToAccount.get(accExtId).Sales_Group_Number__c);
        }

        // Query for Account Hierarchy Information Global Group Number, National Group Number and Sales Group Number from Customer master
        List<Customer_Master_Data__c> lstCmds = new CustomerMasterDataSelector().selectByAccountERPId(groupNumbers);
        
        Map<String, Customer_Master_Data__c> groupNumberToCMD = new Map<String, Customer_Master_Data__c>();
        for (Customer_Master_Data__c cmd : lstCmds)
        {
            if (cmd.ERP_Customer_Id__c != null)
                groupNumberToCMD.put(cmd.ERP_Customer_Id__c, cmd);
        }
        
        System.debug('groupNumberToCMD: ' + groupNumberToCMD);
        for (String accExtId:extIdToAccount.keyset())
        {
            Account acc = extIdToAccount.get(accExtId);
            Boolean booUpdated =false;
            if (String.isNotBlank(acc.Global_Group_Number__c))
                setGroupName(groupNumberToCMD,extIdToAccount,acc,acc.Global_Group_Number__c,
                            'Global Group Number','Global_Group_Name__c');
                
            if (String.isNotBlank(acc.National_Group_Number__c))
                setGroupName(groupNumberToCMD,extIdToAccount,acc,acc.National_Group_Number__c,
                            'National Group Number','National_Group_Name__c');
            if (String.isNotBlank(acc.Sales_Group_Number__c))
                setGroupName(groupNumberToCMD,extIdToAccount,acc,acc.Sales_Group_Number__c,
                            'Sales Group Number','Sales_Group_Name__c');
            
        }
        
    }

    private static void setGroupName(Map<String, Customer_Master_Data__c> groupNumberToCMD,
                                        Map<String,Account> extIdToAccount, Account objAccount,
                                        String strGlobalNumber, String strFieldLabel,String strNameField){
        if(extIdToAccount.containsKey(strGlobalNumber))
            objAccount.put(strNameField,extIdToAccount.get(strGlobalNumber).Name);
        else if(groupNumberToCMD!=null && groupNumberToCMD.containsKey(strGlobalNumber))
            objAccount.put(strNameField,groupNumberToCMD.get(strGlobalNumber).Name);
        else
            throw new UtilsRest.InterfaceException(strFieldLabel+' is missing: '+strGlobalNumber);
    }

    /*
    * @Author: Akshay Mohan  
    * @Description : it is static method and create or update location logic is called out in it
    * @param: Map<String,Customer_Master_Data__c> ERPIdToCustomerMasterData
    * @return: void
    */
    public static void createOrUpdateLocation(Map<String,Customer_Master_Data__c> ERPIdToCustomerMasterData)
    {
        Map<String,SVMXC__Site__c> ERPIdToLocation = new Map<String,SVMXC__Site__c>();
        List<SVMXC__Site__c> lstLocUpdate = new List<SVMXC__Site__c>();
        List<SVMXC__Site__c> lstLocCreate = new List<SVMXC__Site__c>();

        // fetching the locations for the set of ERP Customer ID passed
        for(SVMXC__Site__c objLocation:[select id,name,ERP_Customer_Id__c,SVMX_PS_External_ID__c,Type__c,Location_Name_Local__c,SVMXC__Street__c,SVMXC__city__c,SVMXC__State__c,SVMXC__Zip__c,Street_Local__c,City_Local__c,State_Local__c,Zip_Local__c,Country_Local__c,SVMXC__Stocking_Location__c,SVMXC__Country__c,SVMX_PS_Active__c from SVMXC__Site__c where ERP_Customer_Id__c in:ERPIdToCustomerMasterData.keySet() and Type__c!=:STRING_LABEL_SERVICE_CENTER])
        {
            // building the Map with ERP Customer ID and location object
            ERPIdToLocation.put(objLocation.ERP_Customer_Id__c,objLocation);
        }
        
        for (Customer_Master_Data__c objCustomerMasterData : ERPIdToCustomerMasterData.values())
        {
            if (ERPIdToLocation.containsKey(objCustomerMasterData.ERP_Customer_Id__c))
            {
                SVMXC__Site__c objLocation=ERPIdToLocation.get(objCustomerMasterData.ERP_Customer_Id__c);
                // building the List of location to be updated
                if (objCustomerMasterData.Account_Group__c!= Label.AccountProspect)
                {
                   lstLocUpdate.add(editLocationRecord(objLocation,objCustomerMasterData));
                }
            } else {
                SVMXC__Site__c ObjLocNew = new SVMXC__Site__c();
                // building the List of location to be created
                if (objCustomerMasterData.Account_Group__c!= Label.AccountProspect)
                {
                   lstLocCreate.add(editLocationRecord(ObjLocNew,objCustomerMasterData));
                }
            }
        }

        // inserting the locations
        if(!lstLocCreate.isEmpty())
        {
            insert lstLocCreate;
        }

        // updating the locations
        if(!lstLocUpdate.isEmpty())
        {
            update lstLocUpdate;
        }

        System.debug('lstLocCreate'+lstLocCreate+'lstLocUpdate'+lstLocUpdate);
    }

    // Method to assign customermasterdata values to Location record
    private static SVMXC__Site__c editLocationRecord(SVMXC__Site__c objLocation, Customer_Master_Data__c objCustomerMasterData)
    {
        objLocation.Name = objCustomerMasterData.Name;
        objLocation.Full_Location_Name__c = objCustomerMasterData.Full_Customer_Name__c;
        objLocation.Type__c=objCustomerMasterData.Account_Group__c;
        objLocation.SVMX_PS_Active__c=true;
        objLocation.Location_Name_Local__c=objCustomerMasterData.Account_Name_Local__c;
        objLocation.ERP_Customer_ID__c=objCustomerMasterData.ERP_Customer_ID__c;
		objLocation.SVMX_PS_External_ID__c=objCustomerMasterData.ERP_Customer_ID__c;
        objLocation.SVMXC__Street__c=objCustomerMasterData.Street__c;
        objLocation.Street_2__c = objCustomerMasterData.Street_2__c;//DCP-29731
        objLocation.SVMXC__City__c=objCustomerMasterData.City__c;
        objLocation.SVMXC__State__c=objCustomerMasterData.State_Province__c;
        objLocation.SVMXC__Zip__c=objCustomerMasterData.Zip_Postal_Code__c;
        objLocation.SVMXC__Country__c=objCustomerMasterData.Country__c;
        objLocation.Street_Local__c=objCustomerMasterData.Street_Local__c;
        objLocation.City_Local__c=objCustomerMasterData.City_Local__c;
        objLocation.State_Local__c=objCustomerMasterData.State_Province_Local__c;
        objLocation.Zip_Local__c=objCustomerMasterData.Zip_Postal_Code_Local__c;
        objLocation.Country_Local__c=objCustomerMasterData.Country_Local__c;
		//INC0232466
        objLocation.Care_Of_From_SAP__c = objCustomerMasterData.Care_Of__c;

        if (objCustomerMasterData.Account_Group__c == STRING_LABEL_LOCKER || objCustomerMasterData.Account_Group__c == STRING_LABEL_TRUNK)
        {
            objLocation.SVMXC__Stocking_Location__c = true;
        }

        return objLocation;
    }

    /**
    * @Author: Parthasarathy D
    * @Description: DCP-55534 Method to upsert the Account Discount Tier data
    * @Param: CustomerMasterWrapper.SalesArea wrapSalesArea,ilib_UpsertHelpers.DisountTierUnitofWorkHelper discountTierWork
    * @Return: 
    */
    public static void upsertAccountDiscountTier(CustomerMasterWrapper.SalesArea wrapSalesArea,ilib_UpsertHelpers.DisountTierUnitofWorkHelper discountTierWork) {
        Code_Parameter__mdt codeParameterObj = Code_Parameter__mdt.getInstance(CODEPARAMETERSALESORGFORADT);
        Set<String> setEligibleSalesOrgs = new Set<String>(codeParameterObj.Values_Text__c.split(','));
        Set<String> setEligbleDistributionChannels = new Set<String>(codeParameterObj.Value__c.split(','));
        Boolean boolSalesOrgDistributionChannelCriteriaSatisfied = setEligbleDistributionChannels.contains(wrapsalesArea.Distribution_Channel) && setEligibleSalesOrgs.contains(wrapsalesArea.Sales_Organization);
        
        if(boolSalesOrgDistributionChannelCriteriaSatisfied) {
            if(wrapSalesArea.DiscountTiers != null) {
                CustomerMasterWrapper.DiscountTiers wrapDiscountTier = new CustomerMasterWrapper.DiscountTiers();
                List<Account_Discount_Tier__c> discountTierObjList = new List<Account_Discount_Tier__c>();
                discountTierObjList.add(wrapDiscountTier.getSObject(wrapSalesArea,System.Label.AccountDiscountTierTypeConsumables));
                discountTierObjList.add(wrapDiscountTier.getSObject(wrapSalesArea,System.Label.AccountDiscountTierTypeInstrument));
                discountTierObjList.add(wrapDiscountTier.getSObject(wrapSalesArea,System.Label.AccountDiscountTierTypeServices));
                discountTierWork.registerUpsert(discountTierObjList);
            } else {
                setAccountDiscountTierERPs.add(wrapSalesArea.ERP_Customer_Id);
                setSalesOrgIDs.add(wrapSalesArea.Sales_Organization);
                setDistributionChannel.add(wrapSalesArea.Distribution_Channel);
            }
        }        
    } 
}