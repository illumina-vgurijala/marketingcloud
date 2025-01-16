/**
* @ author       : Akshay Mohan
* @ date         : 07-04-2018
* @ Description  : US-1563 Batch update to sync the territory information into account records
* Test Class for 75% coverage : TestAccountTerritoryUsersController, TestScheduledBatchAccountTerritorySync
* Test Class for 90% coverage : TestAccountTerritoryUsersController, TestScheduledBatchAccountTerritorySync
* Test class for 90% coverage: TestScheduledBatchAccountTerritorySync (As of Sep 08, 22 - 91%)
* Test class for 75% coverage: TestScheduledBatchAccountTerritorySync (As of Sep 08, 22 - 91%)
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Akshay Mohan          07-04-2018                 Initial version
* Akshay Mohan          09-08-2018                 Modified for Account Owner updation
* Akshay Mohan          21-08-2018                 DCP-10620 bug fix
* Vivek Singh           02-10-2018                 Modified Query for DCP-12275 
* Akshay Mohan          10-Sep-2019                DCP-27435 Added batch call for Account Plan Region set
* Joshith K             18-09-2019                 Added Global Teriitory logic
* Kushagra Desai        14-11-2019                 FETR0020099 Hypercare Incident.
* Prabhsimran Singh     04-06-2020                 DCP-38064 Added method for Account ownership management.
* Prabhsimran Singh     10-09-2020                 DCP-39733 Excluding parent group
* Nishan Shetty         02-Sep-2021                CMCP-20 Update VAD Channel Partner Territory Field on Account and refractoring existing Code for
*                                                  Code Scan Issues.
* Koustubh M            09-Dec-2021                TASK0679416 Added code for error logging
* Prem Ranjan           25-April-2022              CodeScan Fix:Avoid Literals in If condition
* Nishan Shetty         03-Jun-2022                Implementing Batch Manager Framework DCP-50962.
* Iram Malik            14-Jul-2022                Codescan Fixes
* Anshaj Sinha          12-Sep-2022                CMSI-207 Instrumented class for PS Log Framework
* Atit Kar              08-Sep-2022                INC0419648 - Adding super keyword in no-arg constructor for best practice.
* Ashwin Kumar          26-Sept-2022               INC0411098 - Restricting Aligned Territories field value to 32768 characters
* Todd Newman           21-Dec-2022                POL-48 - Handle model activation where more than 10k accounts get updated, finish() method
*/
global without sharing class ScheduledBatchAccountTerritorySync extends ilib_BatchDeferrable implements Database.Stateful {

    public final static String TERRITORY_ROLE_TAM = 'Territory Account Manager';
    public final static String TERRITORY_ROLE_PAM = 'Partner Account Manager';
    public final static String TERRITORY_ROLE_SAM = 'Strategic Account Manager';
    public final static String TERRITORY_ROLE_ISAM = 'Inside Sales Account Manager';
    public final static String TERRITORY_ROLE_GAM = 'Global Account Manager';

    public final static String CODEPARAMETER = 'Global_Territory_Name'; 
	public final static String TERRITORY_TYPE_PARENT_GROUP = 'Parent_Group';

    private final static String LOG_TITLE = 'ScheduledBatchAccountTerritorySync'; //Koustubh - TASK0679416, 9th Dec 2021 - Added for error logging
    public static final Integer ONE = 1;
    private static final Integer MAX_LENGTH = 32768;    //INC0411098

    //START CMCP-20
    private static Map<Id, List<Territory2>> accountIdToDirectTerritory;
    private static Map<Id, Set<Id>> accountIdToTerritoryIds;
    private static Map<Id,List<Territory2>> accountIdToVADTerritory;
    //END CMCP-20
  
    global String globalTerritoryName = '';
    global Set<Id> updatedAccountIds;

    global final Set<String> POTENTIAL_ACCOUNT_OWNER_ROLES = new Set<String> {TERRITORY_ROLE_PAM, TERRITORY_ROLE_TAM, TERRITORY_ROLE_SAM, TERRITORY_ROLE_ISAM,TERRITORY_ROLE_GAM};
    global final List<String> DEFAULT_USER_ROLE_ORDER = new List<String>  {TERRITORY_ROLE_GAM, TERRITORY_ROLE_SAM, TERRITORY_ROLE_TAM, TERRITORY_ROLE_PAM};
    global final Map<String, String> ROLE_ABBREV_TO_ROLE_NAME = new Map<String, String>{'GAM' => TERRITORY_ROLE_GAM, 'SAM' => TERRITORY_ROLE_SAM, 'TAM' => TERRITORY_ROLE_TAM, 'PAM' => TERRITORY_ROLE_PAM};
    
    /**
    * @author Akshay Mohan
    * @date   07-04-2018
    * @description  Constructor
    */
    global ScheduledBatchAccountTerritorySync() {
        super();    //INC0419648
        updatedAccountIds = new Set<Id>();
    }
    
    /**
    * @author Akshay Mohan
    * @date   07-04-2018
    * @description  Schedulable Execute Method.
    */
    global override void execute(SchedulableContext ctx) {
        Map<String, String> params = UtilsSettings.getCustomMetadataMap('Batch_Territory_Updates');

        Integer defaultBatchSize = 100;
        Integer batchSize = UtilsSettings.parseIntegerFromSettingsMap(params, 'AccountBatchSize', defaultBatchSize);
        if (batchSize < 1 || batchSize > 200) {
            batchSize = defaultBatchSize;
        } 

        //DCP-50962
		ilib_BatchManager.executeBatch(new ScheduledBatchAccountTerritorySync(), batchsize);
    }

    /**
    * @author Akshay Mohan
    * @date   07-04-2018
    * @description    DCP-1563 query all objects (accounts) tied to the current territory
    *                 CMCP-20 [Added VAD Channel Partner Territory Field in Account Query]
    */
    global override Database.QueryLocator start(Database.BatchableContext bc)
    {
        ilib_LogEvent.setBatchTitle(LOG_TITLE, transactionId);
        ilib_LogEvent.setWorkstream(ilib_LogEvent.SALES);
        List<Code_Parameter__mdt> codeParameter = [SELECT Id, DeveloperName, Value__c FROM Code_Parameter__mdt WHERE DeveloperName =: CODEPARAMETER];
        if(codeParameter.size()>0){
            globalTerritoryName = codeParameter[0].Value__c;
            ilib_LogEvent.push('ScheduledBatchAccountTerritorySync.start');
            ilib_LogEvent.info('global territory name' + globalTerritoryName);
        }
        String strSoql = 'SELECT Id, Name, Territory_Name__c, Territory_Code__c, District__c, Subregion__c, '
            + ' Business_Unit__c, Territory_Region__c, Aligned_Territories__c, OwnerId, VAD_Channel_Partner_Territory__c FROM Account';
        ilib_LogEvent.info('Query : '+strSoql);
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
        return Database.getQueryLocator(strSoql);
    }

    /**
    * @author Akshay Mohan
    * @date   07-04-2018
    * @description    DCP-1563 populate Territory Information on Account Detail Page
    */
    global override void execute(Database.BatchableContext bc, List<sObject> lstAccount) {   
        ilib_LogEvent.setBatchTitle(LOG_TITLE, transactionId);
        ilib_LogEvent.setWorkstream(ilib_LogEvent.SALES);
        ilib_LogEvent.push(LOG_TITLE + '.execute()');
        Set<Id> setAccountIds = UtilsCollection.getSetOfIds(lstAccount, 'Id');
        ilib_LogEvent.info('setAccountIds: '+ setAccountIds);

        assignValueToMaps(setAccountIds);//CMCP-20 Refractor Existing Logic for Code Scan Issue.

        ilib_LogEvent.info('Account to Direct Territory'+accountIdToDirectTerritory);
        ilib_LogEvent.info('Account to Territory IDs'+accountIdToTerritoryIds);
        ilib_LogEvent.info('Account to VAD Territory'+accountIdToVADTerritory);

        if (accountIdToDirectTerritory.isEmpty() && accountIdToTerritoryIds.isEmpty() && accountIdToVADTerritory.isEmpty()) {
            ilib_LogEvent.pop(); //calling pop because of return statement
            ilib_LogEvent.emit(); //calling emit because of return statement
            return; // if no records found don't proceed
        }

        List<Account> lstUpdateAccounts = new List<Account>();
        Map<Id, Id> accountIdToUpdatedTerritoryId = new Map<Id, Id>();
        List<Account> lstUpdateVADAccounts=new List<Account>();//CMCP-20

        // as per documentation, the object is always an account as of 2016
        for (Account a : (List<Account>)lstAccount) {   
            Territory2 objDirectTerritory;
            Boolean accountUpdated = false;
            Boolean isGlobal=false;
            if(accountIdToDirectTerritory.containsKey(a.id)) {
                integer territorySize=accountIdToDirectTerritory.get(a.id).size();
                if(territorySize > ONE) {
                    for(Territory2 objTerritory:accountIdToDirectTerritory.get(a.id)) {
                        isGlobal = checkGlobalTerritory(objTerritory);
                        ilib_LogEvent.message('size more than 1'+isGlobal);
                        if(!isGlobal) {
                            ilib_LogEvent.message('size more than 1'+objDirectTerritory);
                            objDirectTerritory=objTerritory;
                            break;
                        }
                    }
                }else if(territorySize == ONE) {
                    isGlobal=checkGlobalTerritory(accountIdToDirectTerritory.get(a.id)[0]);
                    
                    objDirectTerritory=accountIdToDirectTerritory.get(a.id)[0];
                    ilib_LogEvent.message('global size 1'+isGlobal);
                }
            }
                    
            //Territory2 objDirectTerritory = accountIdToDirectTerritory.get(a.Id);
            String territoryIds = formatTerritoryIds(accountIdToTerritoryIds.get(a.Id));
            ilib_LogEvent.message('objDirectTerritory: ' + objDirectTerritory);
            ilib_LogEvent.message('territoryIds: ' + territoryIds);
            ilib_LogEvent.message('Account: ' + a);
            ilib_LogEvent.message('global'+isGlobal);
            accountUpdated = updateIfChanged(a, objDirectTerritory, territoryIds, isGlobal);

            // if territory changed, add this row to collections
            if (accountUpdated) {
                lstUpdateAccounts.add(a);
                accountIdToUpdatedTerritoryId.put(a.Id, (objDirectTerritory == null ? null : objDirectTerritory.Id));
            }

            performAccountSync(a,lstUpdateVADAccounts);//CMCP-20
        }
       
        avoidDuplication(lstUpdateAccounts,lstUpdateVADAccounts);//CMCP-20

        if (!lstUpdateAccounts.isEmpty()) {
            List<Database.SaveResult> lstSaveErrors = Database.update(lstUpdateAccounts, false); //Koustubh - TASK0679416, 9th Dec 2021 - Added for error logging
            if(!lstSaveErrors.isEmpty()){ //Koustubh - TASK0679416, 9th Dec 2021 - Added error logging
                ApexExceptions.emitSaveErrors(lstSaveErrors, LOG_TITLE); //Koustubh - TASK0679416, 9th Dec 2021 - Added for error logging
            }
        }
          

        if (accountIdToUpdatedTerritoryId.size() > 0) {
            updatedAccountIds.addAll(accountIdToUpdatedTerritoryId.keyset());
        }

        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
           
    }

    /**
    * @author Akshay Mohan
    * @date   07-04-2018
    * @description check if anything has changed regarding the territory values. only then do the update
    */
    private Boolean updateIfChanged(Account objAccount, Territory2 objTerritory, String territoryIds, Boolean isGlobalTerritory)
    {
        String strTerritory;
        String strTerritoryCode;
        String strDistrict;
        String strSubregion;
        String strBusinessUnit;
        String strRegion;
        String accountOwnerOrder;
        //Check SAM and ISAM roles
        Id accountOwnerId;
        Map<String, Id> mapUserTerritoryRole = new Map<String, Id>();
        if (objTerritory != null)
        {   
            strTerritory = objTerritory.Name;
            strTerritoryCode = objTerritory.Territory_Code__c;
            strDistrict = objTerritory.District__c;
            strSubregion = objTerritory.Subregion__c;
            strBusinessUnit = objTerritory.Business_Unit__c;
            strRegion = objTerritory.Territory_Region__c;

            if (!objTerritory.UserTerritory2Associations.isEmpty())
            {
                for (UserTerritory2Association userAssociation : objTerritory.UserTerritory2Associations){
                    //FETR0020099 
                     if(!mapUserTerritoryRole.containsKey(userAssociation.RoleInTerritory2))
                        mapUserTerritoryRole.put(userAssociation.RoleInTerritory2,userAssociation.UserId);

                } 
                ilib_LogEvent.message('mapUserTerritoryRole'+mapUserTerritoryRole);

                //DCP-38064 Updating the list of Roles based on the priority mentioned on territory field.
                accountOwnerOrder = checkTerritoryPriority(objTerritory);
                List<String> lstUserRoles = getUserRoles(accountOwnerOrder);

                accountOwnerId = findAccountOwnerId(mapUserTerritoryRole, lstUserRoles, isGlobalTerritory);
                if (accountOwnerId == null)
                {
                    accountOwnerId = objTerritory.UserTerritory2Associations[0].UserId;  
                }
            }
        }
        ilib_LogEvent.message('accountOwnerId: ' + accountOwnerId);

        // NOTE: thought about null vs '' but decided the first time the record will
        // be updated to '' and that's fine
        if (objAccount.Territory_Name__c == strTerritory
                && objAccount.Territory_Code__c == strTerritoryCode
                && objAccount.District__c == strDistrict
                && objAccount.Subregion__c == strSubregion
                && objAccount.Business_Unit__c == strBusinessUnit
                && objAccount.Territory_Region__c == strRegion
                && (String.isBlank(accountOwnerId) || objAccount.OwnerId == accountOwnerId)
                && objAccount.Aligned_Territories__c == territoryIds
        ) { 
            ilib_LogEvent.message('Returning False');
            return false;
        }

        ilib_LogEvent.message('Updating objAccount: ' + objAccount);

        objAccount.Territory_Name__c = strTerritory;
        objAccount.Territory_Code__c = strTerritoryCode;
        objAccount.District__c = strDistrict;
        objAccount.Subregion__c = strSubregion;
        objAccount.Business_Unit__c = strBusinessUnit;
        objAccount.Territory_Region__c = strRegion;
        objAccount.Aligned_Territories__c = territoryIds;

        if (String.isNotBlank(accountOwnerId))
            objAccount.OwnerId = accountOwnerId;

        ilib_LogEvent.message('Updated objAccount: ' + objAccount);
        ilib_LogEvent.message('Returning True');
        return true;
    }

    private Id findAccountOwnerId(Map<String, Id> mapUserTerritoryRole, List<String> lstUserRoles, Boolean isGlobalTerritory)
    {
        Id ownerId;

        for (String role : lstUserRoles)
        {
            if (mapUserTerritoryRole.containsKey(role))
            {
                ilib_LogEvent.fine('role ' + role);
                if (role == TERRITORY_ROLE_GAM && !isGlobalTerritory)
                {
                    ilib_LogEvent.fine('inside continue' + role);
                    continue;
                }

                ownerId = mapUserTerritoryRole.get(role);
                break;  
            } 
        }   
        ilib_LogEvent.message('Returning Owner Id : '+ownerId);
        return ownerId;
    }

    private String formatTerritoryIds(Set<Id> ids)
    {
        if (ids == null) { return ''; }
        //INC0411098
        String territoryIds = String.join(new List<Id>(ids), ',');
        territoryIds = territoryIds.length() > MAX_LENGTH ? territoryIds.substring(0, MAX_LENGTH-3) + '...' : territoryIds;
        return territoryIds;
    }

    /**
    * @author Joshith k
    * @date   18-09-2019
    * @description check if Territory global or not
    */
    private Boolean checkGlobalTerritory(Territory2 objter)
    {   
        ilib_LogEvent.message('global territory name' + globalTerritoryName);
        set<string>parentTerritoryNames=new Set<String>();
        parentTerritoryNames.add(objter.Name);
        if(objter.ParentTerritory2.Name!=null)
            parentTerritoryNames.add(objter.ParentTerritory2.Name);

        if(objter.ParentTerritory2.ParentTerritory2.Name!=null)
            parentTerritoryNames.add(objter.ParentTerritory2.ParentTerritory2.Name);

        if(objter.ParentTerritory2.ParentTerritory2.ParentTerritory2.Name!=null)
            parentTerritoryNames.add(objter.ParentTerritory2.ParentTerritory2.ParentTerritory2.Name);

        if(objter.ParentTerritory2.ParentTerritory2.ParentTerritory2.ParentTerritory2.Name!=null)
            parentTerritoryNames.add(objter.ParentTerritory2.ParentTerritory2.ParentTerritory2.ParentTerritory2.Name);

        ilib_LogEvent.message('parentTerritoryNames' + parentTerritoryNames);
        return parentTerritoryNames.contains(globalTerritoryName);
    }

    private List<String> getUserRoles(String accountOwnerOrder)
    {
        List<String> lstUserRoles = new List<String>();

        if (String.isNotBlank(accountOwnerOrder))
        {
            if (accountOwnerOrder.contains(','))
            {
                List<String> lstRoleOrder = accountOwnerOrder.split(',');
                List<String> lstTerritoryRoleOrder = new List<String>();

                for (String role : lstRoleOrder)
                {
                    if (ROLE_ABBREV_TO_ROLE_NAME.containsKey(role)) { lstTerritoryRoleOrder.add(ROLE_ABBREV_TO_ROLE_NAME.get(role)); }
                }

                if (!lstTerritoryRoleOrder.isEmpty())
                {
                    lstUserRoles = lstTerritoryRoleOrder;
                }
                else
                {
                    lstUserRoles = DEFAULT_USER_ROLE_ORDER;
                }
            }
        }
        else
        {
            lstUserRoles = DEFAULT_USER_ROLE_ORDER;
        }
        ilib_LogEvent.message('Returning lstUserRoles : '+lstUserRoles);
        return lstUserRoles;
    }

    /**
    * @author Prabhsimran Singh
    * @date   04-06-2020
    * @description return account owner priority
    */
    private String checkTerritoryPriority(Territory2 objter) {
        if (String.isNotBlank(objter.Account_Owner_Priority__c)) {
            return objter.Account_Owner_Priority__c;
        }

        if (String.isNotBlank(objter.ParentTerritory2.Account_Owner_Priority__c)) {
            return objter.ParentTerritory2.Account_Owner_Priority__c;
        }

        if (String.isNotBlank(objter.ParentTerritory2.ParentTerritory2.Account_Owner_Priority__c)) {
            return objter.ParentTerritory2.ParentTerritory2.Account_Owner_Priority__c;
        }

        if (String.isNotBlank(objter.ParentTerritory2.ParentTerritory2.ParentTerritory2.Account_Owner_Priority__c)) {
            return objter.ParentTerritory2.ParentTerritory2.ParentTerritory2.Account_Owner_Priority__c;
        }

        if (String.isNotBlank(objter.ParentTerritory2.ParentTerritory2.ParentTerritory2.ParentTerritory2.Account_Owner_Priority__c)) {
            return objter.ParentTerritory2.ParentTerritory2.ParentTerritory2.ParentTerritory2.Account_Owner_Priority__c;
        }
        return '';
    }

    /**
    * @author Nishan Shetty [CMCP-20]
    * @date   02-09-2021
    * @description  Assign VAD Channel Partner Territory Code to Account.
    */
    private Boolean assignVADTerritoryCodeToAccount(Account objAccount,List<Territory2> lstTerritories) {

        Set<String> setTerritoryCodes=new Set<String>();
        String strAccountVADTerritoryCode=objAccount.VAD_Channel_Partner_Territory__c;
        Set<String> setExistingTerritoryCodes=null;
        

        for(Territory2 objTerritory:lstTerritories) {
            if(objTerritory.Territory_Code__c!=null) {
                setTerritoryCodes.add(objTerritory.Territory_Code__c); 
            }
        }
        ilib_LogEvent.message('setTerritoryCodes : '+setTerritoryCodes);
        if(String.isNotBlank(strAccountVADTerritoryCode)) {
            setExistingTerritoryCodes=new Set<String>(strAccountVADTerritoryCode.split(','));
        }
        // this logic is used to compare existing territory codes in Account's VAD Channel Partner Territory field with assigned Territories territory codes 
        // and determine if there is any change in values to update the field.
        if(!setTerritoryCodes.isEmpty() 
        && (setExistingTerritoryCodes==null
        ||(setExistingTerritoryCodes!=null && !setExistingTerritoryCodes.isEmpty()
        && (!setExistingTerritoryCodes.containsAll(setTerritoryCodes) || !setTerritoryCodes.containsAll(setExistingTerritoryCodes))))) {
           objAccount.VAD_Channel_Partner_Territory__c=String.join(new List<String>(setTerritoryCodes),',');
           ilib_LogEvent.message('Returning true');
           return true;
        }
        ilib_LogEvent.message('Returning false');
        return false;
    }


     /**
    * @author Nishan Shetty [CMCP-20]
    * @date   02-09-2021
    * @description  Refractor Existing Logic. Assigning values to Map
    */
    private void assignValueToMaps(Set<Id> setAccountIds) {
        ilib_LogEvent.push(LOG_TITLE + '.assignValueToMaps()');
        ilib_LogEvent.info('Account Ids Received : '+setAccountIds);
        accountIdToDirectTerritory = new Map<Id, List<Territory2>>();
        accountIdToTerritoryIds = new Map<Id, Set<Id>>();
        accountIdToVADTerritory = new Map<Id,List<Territory2>>();
        Set<String> setIgnoreProfiles = new Set<String>{Label.Profile_Commercial_Ops_Quoting_User};
        String channelLikeValue = '%' + Territories2.CHANNEL_PARTNER_DESCRIPTION + '%';  
 
        for (Territory2 ter : [SELECT Territory_Code__c, District__c, SubRegion__c, Business_Unit__c, Territory_Region__c, Territory2Type.MasterLabel,
                     Name, Account_Owner_Priority__c,
                     ParentTerritory2.Name, ParentTerritory2.Account_Owner_Priority__c,
                     ParentTerritory2.ParentTerritory2.Name, ParentTerritory2.ParentTerritory2.Account_Owner_Priority__c,
                     ParentTerritory2.ParentTerritory2.ParentTerritory2.Name, ParentTerritory2.ParentTerritory2.ParentTerritory2.Account_Owner_Priority__c,
                     ParentTerritory2.ParentTerritory2.ParentTerritory2.ParentTerritory2.Name, ParentTerritory2.ParentTerritory2.ParentTerritory2.ParentTerritory2.Account_Owner_Priority__c,
                     (SELECT ObjectId, Territory2Id
                         FROM ObjectTerritory2Associations
                         WHERE ObjectId IN :setAccountIds),
                     (SELECT RoleInTerritory2, UserId
                         FROM UserTerritory2Associations
                         WHERE RoleInTerritory2 IN :POTENTIAL_ACCOUNT_OWNER_ROLES
                         AND IsActive = true
                         AND (NOT User.Profile.Name LIKE :channelLikeValue)
                         AND User.Profile.Name NOT IN :setIgnoreProfiles
                         ORDER BY RoleInTerritory2 DESC, LastModifiedDate DESC)
                 FROM Territory2
                 WHERE Territory2Model.State = :Territories2.MODEL_STATE_ACTIVE
                 AND Territory2Type.developername != :TERRITORY_TYPE_PARENT_GROUP] //DCP-39733
         ) {
             for (ObjectTerritory2Association assoc : ter.ObjectTerritory2Associations) {
                 if (!accountIdToTerritoryIds.containsKey(assoc.ObjectId)) {
                     accountIdToTerritoryIds.put(assoc.ObjectId, new Set<Id>());
                 }
                 accountIdToTerritoryIds.get(assoc.ObjectId).add(assoc.Territory2Id);
 
                 if (!ter.Territory2Type.MasterLabel.contains(Territories2.CHANNEL_PARTNER_DESCRIPTION)) {
                     //accountIdToDirectTerritory.put(assoc.ObjectId, ter); //make map of all active territory with accounts assigned
                     if (!accountIdToDirectTerritory.containsKey(assoc.ObjectId)) {
                         accountIdToDirectTerritory.put(assoc.ObjectId, new List<Territory2>());// map to add multiple  active territoty with account assigned
                     }
                     accountIdToDirectTerritory.get(assoc.ObjectId).add(ter);
                 }
 
                 //START CMCP-20
                 if(ter.Territory2Type.MasterLabel.equalsIgnoreCase(TerritoryTypesService.LABEL_TYPE_TERRITORY_VAD_CP)) {
                     if (!accountIdToVADTerritory.containsKey(assoc.ObjectId)) {
                         accountIdToVADTerritory.put(assoc.ObjectId, new List<Territory2>());
                     } 
                     accountIdToVADTerritory.get(assoc.ObjectId).add(ter);
                 }
                 //END CMCP-20
 
             }
         }
         ilib_LogEvent.info('accountIdToVADTerritory : '+accountIdToVADTerritory);
         ilib_LogEvent.pop();
 
    }

    /**
    * @author Nishan Shetty [CMCP-20]
    * @date   02-09-2021
    * @description  Code is separate to avoid Code Scan Issue. This method perform call to VAD identification method.
    */
    private void performAccountSync(Account a,List<Account> lstVADAccounts) {
        Boolean updateVADAccount= false;//CMCP-20
         //START CMCP-20
         if(accountIdToVADTerritory.containsKey(a.id)) {
            List<Territory2> lstVADTerritories=accountIdToVADTerritory.get(a.Id);
            updateVADAccount=assignVADTerritoryCodeToAccount(a,lstVADTerritories);
        } else {
            a.VAD_Channel_Partner_Territory__c=null;
        }

        if(updateVADAccount) {
            lstVADAccounts.add(a);
        }
        ilib_LogEvent.message('Returning lstVADAccount : '+lstVADAccounts);
        //END CMCP-20
    }


    /**
    * @author Nishan Shetty [CMCP-20]
    * @date   29-Oct-2021
    * @description  Remove duplicate record from list of Accounts to Update.
    */
    private void avoidDuplication(List<Account> lstAccountToUpdate,List<Account> lstVADAccounts) {
        ilib_LogEvent.push(LOG_TITLE + '.avoidDuplication()');
        Map<Id,Account> mapAccounts = new Map<Id,Account>();
        //START CMCP-20 [Added this logic to avoid account duplication during update operation.]
           mapAccounts.putAll(lstAccountToUpdate);
           for(Account objAccount:lstVADAccounts) {
               if(!mapAccounts.containsKey(objAccount.Id)) {
                lstAccountToUpdate.add(objAccount);
               }
           }
        ilib_LogEvent.info('lstAccountToUpdate : '+lstAccountToUpdate);
        ilib_LogEvent.pop();
        //END CMCP-20
    }

    /**
    * @description for any account IDs where territory association changed
    * 1) run TAPS sharing for any child records of the accounts
    * 2) run a batch to stamp the region value on child opportunity and quote records
    * 3) run a batch to stamp the region value on account plan records
    */
    global override void finish(Database.BatchableContext bc) {

        ilib_LogEvent.setBatchTitle(LOG_TITLE, transactionId);
        ilib_LogEvent.setWorkstream(ilib_LogEvent.SALES);
        ilib_LogEvent.push(LOG_TITLE + '.finish()');

        if (updatedAccountIds != null && updatedAccountIds.size() > 0) {
            // PRB0043303- Remove Platform Event and Directly call TAPS_DeferredRun
            // share installed products where distributor territory alignment might have changed
            ilib_Queueablethread qt = new ilib_Queueablethread('TAPSAccountSharing');
            TAPS_QueuedDeferredSharing createDeferredSharing = new TAPS_QueuedDeferredSharing('Account', updatedAccountIds);
            qt.logAndQueue(createDeferredSharing, 'TAPS_QueuedDeferredSharing', 'execute');
            ilib_QueueableManager.enqueueJob(qt, ilib_LogEvent.SALES);

            Integer defaultBatchSize = 100;

            Map<String, String> params = UtilsSettings.getCustomMetadataMap('Opportunity_Region_Updates');
            Integer batchSize = UtilsSettings.parseIntegerFromSettingsMap(params, 'OpportunityBatchSize', defaultBatchSize);
            if (batchSize < 1 || batchSize > 200) {
                batchSize = defaultBatchSize;
            }
            ilib_LogEvent.info('BatchOpportunityAndQuotePopulateRegion batchSize : ' + batchSize);

            ilib_BatchManager.executeBatch(new BatchOpportunityAndQuotePopulateRegion(updatedAccountIds), batchSize); //DCP-50962

            // DCP-27435: Trigger batch to update the Account Plans on the Account
            params = UtilsSettings.getCustomMetadataMap('Account_Plan_Region_Updates');
            batchSize = UtilsSettings.parseIntegerFromSettingsMap(params, 'AccountPlanBatchSize', defaultBatchSize);
            if (batchSize < 1 || batchSize > 200) {
                batchSize = defaultBatchSize;
            }
            ilib_LogEvent.info('BatchAccountPlanPopulateRegion batchSize : ' + batchSize);

            ilib_BatchManager.executeBatch(new BatchAccountPlanPopulateRegion(updatedAccountIds), batchSize); //DCP-50962
        }

        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
    }
	
	// ************************************************************************************************
    // Deferrable implementation - DCP-50962
    // ************************************************************************************************

    /* no inputs, serialize dummy values */
    public override String serializeInputs() {
        return JSON.serialize('No input for this class');
    }

    /* noop intentional, no inputs */
    public override void restoreInputs(String serializedInputs) { }
	
}