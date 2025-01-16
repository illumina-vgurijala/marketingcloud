/* @ author       : KD
* @ date         : 22-July-2020
* @ Description  : Controller class for New Plan creation
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID      Description
 AnishaBharti            20-Aug-2020                                  DCP-39736: to retrieve users Role in Territory 
* KD                     3-Sept-2020                                  DCP-39735 : Automation of channel partner  
 Anisha Bharti           07-Sept-2020                                 DCP-40497 : updated plan recordtype API name
* KD                     8-Sept-2020                                  DCP-39107 : Plan sharing
* KD                     11-Sept                                      DCP-40495 : Plan Target Automation
* KD                     17-Sept                                      DCP-39967 : Plan CLone
* KD                     25-Sept                                      DCP-41767 : Plan Name Automations
* Nishan Shetty          22-April-2022                                CodeScan Fix:Avoid Literals in If condition
* ---------------------------------------------------------------------------------------------------------------------------------------
*/
public with sharing class PlanCreationController {
        public static Boolean boolIsTestRunning = false;
        public static Boolean boolIsCommunity = false;
        public static Boolean boolIsIndirect = false;
        public static String idOverlayRecordType = Schema.SObjectType.Plan__c.getRecordTypeInfosByDeveloperName().get(Label.PlanOverlay).getRecordTypeId();
        public static String idInDirectRecordType = Schema.SObjectType.Plan__c.getRecordTypeInfosByDeveloperName().get(Label.Plan_Indirect).getRecordTypeId();
        public static Id idRecordType;
        public static List<TerritoryWrapper> lstTerritoryWrapper = new List<TerritoryWrapper>();
        public static Map<String,List<AccountWrapper>> mapCodeToAccounts = new Map<String,List<AccountWrapper>>();
        public static Map<Id,AccountWrapper> mapAccountIdToAccounts = new Map<Id,AccountWrapper>();
        public static AccountWrapper objAccountDetailCP;
        public static List<UserTerritory2Association> lstUserTerritory2Association = new List<UserTerritory2Association>();
        public static boolean isOverlayPlan = false;
        public static Id idChannelPartner;
        public static String strChannelPartnerIndirectCode = '';
        public static Set<String> setRoles = new Set<String>();
        public static Set<String> setTerritoryCode = new Set<String>();
        public static String userRecordId;
        // DCP-41767
        public static String strChannelPartnerName;

        //START CodeScan Fix [Avoid Literals in If condition]
        private static final String STRING_COMMUNITY = 'Community'; 
        //END CodeScan Fix

    /**
    *  @author KD
    *  @description to fetch territory assigned to user 
    *  @param logged in user id
    *  @return String
    **/
    @AuraEnabled
    public static String initRecords(String userRecordIdLocal, String recordTypeID,String recordId){

        try{
            //DCP-39967 : Plan CLone
            system.debug('User info-->'+userinfo.getUserType()); 
            String strRecordTypeID;
            if(String.isNotBlank(recordId)){
                if(userinfo.getUserType() == 'Standard' && !boolIsTestRunning)
                    strRecordTypeID = new PlanSelector().getTerritoryPlanbyId(recordId)[0].RecordTypeId;
                else
                    strRecordTypeID = 'Community';
            }
            else
                strRecordTypeID = recordTypeID;
            userRecordId = userRecordIdLocal;
            System.debug('Record Type -->'+recordTypeID);
            if(strRecordTypeID == STRING_COMMUNITY){
                boolIsCommunity = true;
                strRecordTypeID = idInDirectRecordType;
            }
            idRecordType = strRecordTypeID;
            strRecordTypeID = idRecordType;
            if(strRecordTypeID != idOverlayRecordType){
                // DCP-39735
                if(strRecordTypeID == idInDirectRecordType){
                    boolIsIndirect = true;
                }
                if(boolIsCommunity){
                    fetchTerritoryAndIndirectCodeForPortal();
                }
                else{
                    fetchTerritoryCode();
                    // DCP-39735
                    if(boolIsIndirect && !setTerritoryCode.isEmpty()){
                        fetchCPAccountAndIndirectCodeForInternal();
                    }
                }
            }
            else{
                getSetRoles();
            }
            // DCP-39735
            return '{"lstUserTerritory2Association": '+JSON.serialize(lstTerritoryWrapper)+','
                    +' "mapLabels": '+JSON.serialize(generateLabelMap())+','
                    +' "setRoles": '+JSON.serialize(setRoles)+','
                    +' "mapAccountWrapper": '+JSON.serialize(mapCodeToAccounts)+','
                    +' "recordTypeID": "'+strRecordTypeID+'",'         // DCP-39621: to fetch recordTypeId
                    +' "channelPartnerId": "'+idChannelPartner+'",'
                    +' "strChannelPartnerIndirectCode": "'+strChannelPartnerIndirectCode+'",'
                    +' "objAccountDetailCP": '+JSON.serialize(objAccountDetailCP)+','
                    +' "boolIsIndirect": '+boolIsIndirect+','
                    +' "boolIsCommunity": '+boolIsCommunity+','
                    // DCP-41767
                    +' "strChannelPartnerName": "'+strChannelPartnerName+'",'
                    +' "isOverlayPlan": '+isOverlayPlan+'}';
        }
        catch(Exception e){
            System.debug(LoggingLevel.ERROR, 'Error at line        : ' + e.getLineNumber());
            System.debug(LoggingLevel.ERROR,'The following exception has occurred:++++getMessage+++ ' + e.getMessage());
            System.debug(LoggingLevel.ERROR,'Exception type caught : ' + e.getTypeName());
            System.debug(LoggingLevel.ERROR,'Cause                 : ' + e.getCause());
            System.debug(LoggingLevel.ERROR,'Stack trace           : ' + e.getStackTraceString());
            throw new AuraHandledException(e.getMessage()); 
        }
    }
    /**
    *  @author KD
    *  @description Generate map of labels
    *  @param 
    **/
    public static Map<String,String> generateLabelMap(){
        Map<String,String> mapLabels = new Map<String,String>();
        mapLabels.put('UI_Error_No_Territory_Assigned',Label.UI_Error_No_Territory_Assigned);
        mapLabels.put('UI_Label_Select_Territory',Label.UI_Label_Select_Territory);
        mapLabels.put('UI_Label_Create_Plan',Label.UI_Label_Create_Plan);
        mapLabels.put('UI_Message_Plan_Created',Label.UI_Message_Plan_Created);
        mapLabels.put('UI_Territory_Not_Selected',Label.UI_Territory_Not_Selected);
        mapLabels.put('UI_Year_Not_Selected',Label.UI_Year_Not_Selected);
        mapLabels.put('UI_Label_Select_Role',Label.UI_Label_Select_Role);
        mapLabels.put('UI_Role_Not_Selected',Label.UI_Role_Not_Selected);
        // DCP-39735
        mapLabels.put('UI_CP_Not_Selected',Label.UI_CP_Not_Selected);
        mapLabels.put('UI_Error_No_CP_In_Territory',Label.UI_Error_No_CP_In_Territory);
        mapLabels.put('UI_Error_No_CP',Label.UI_Error_No_CP);
        mapLabels.put('UI_Label_Clone_Plan',Label.UI_Label_Clone_Plan);
        mapLabels.put('UI_Start_Date_Not_Selected',Label.UI_Start_Date_Not_Selected);
        mapLabels.put('UI_End_Date_Not_Selected',Label.UI_End_Date_Not_Selected);
        return mapLabels;
    }
    /**
    *  @author KD
    *  @description Fetch Quota details for CP
    *  @param 
    **/
    public static void generateMapAccountToMapYearQuota(){
        List<Channel_Partner_Quota__c> lstQuota = new ChannelPartnerQuotaSelector().getQuotaByAccountWithFYQuota(mapAccountIdToAccounts.keySet());
        for(Channel_Partner_Quota__c objQuota : lstQuota){
            if(mapAccountIdToAccounts.containsKey(objQuota.Account_Name__c))
                if(!mapAccountIdToAccounts.get(objQuota.Account_Name__c).mapAccountIdToFYQuota.containsKey(objQuota.Year__c))
                    mapAccountIdToAccounts.get(objQuota.Account_Name__c).mapAccountIdToFYQuota.put(objQuota.Year__c,objQuota.FY_Quota__c);
        }
    }
    /**
    *  @author KD
    *  @description Fetch set of roles for Overlay
    *  @param 
    **/
    public static void getSetRoles(){
        lstUserTerritory2Association = new UserTerritory2AssociationSelector().selectOnlyDirectByUserId(new Set<Id>{(Id)userRecordId});
        for(UserTerritory2Association objUTA : lstUserTerritory2Association){
            if(String.isNotBlank(objUTA.RoleInTerritory2))
                setRoles.add(objUTA.RoleInTerritory2);
        }
        isOverlayPlan = true;
    }
    /**
    *  @author KD
    *  @description get CP and indirect territory code for Community user
    *  @param 
    **/
    public static void fetchTerritoryAndIndirectCodeForPortal(){
        User objLoggedInUser = new UsersSelector().getLoggedInPortalUser((String)UserInfo.getUserId())[0];
        for(Territory2 objTr : new TerritoriesSelector().getByTerritoryCode(new Set<String>{objLoggedInUser.Contact.Account.Territory_Code__c})){
            lstTerritoryWrapper.add(new TerritoryWrapper(objTr));
        }
        idChannelPartner = objLoggedInUser.Contact.AccountId;
        List<ObjectTerritory2Association> lstOTA = new ObjectTerritory2AssociationsSelector().selectIndirectByAccountIds(new Set<Id>{idChannelPartner});
        // DCP-41767
        if(!lstOTA.isEmpty()){
            strChannelPartnerIndirectCode = lstOTA[0].Territory2.Territory_Code__c;
            strChannelPartnerName = lstOTA[0].Object.Name;
        }
        List<Channel_Partner_Quota__c> lstQuota = new ChannelPartnerQuotaSelector().getQuotaByAccountWithFYQuota(new Set<Id>{idChannelPartner});
        Map<String,Decimal> mapYearToQuota = new Map<String,Decimal>();
        for(Channel_Partner_Quota__c objQuota : lstQuota){
            mapYearToQuota.put(objQuota.Year__c,objQuota.FY_Quota__c);
        }
        objAccountDetailCP = new AccountWrapper((String)idChannelPartner,mapYearToQuota);   
    }
    /**
    *  @author KD
    *  @description get CP and indirect territory code for Internal user
    *  @param 
    **/
    public static void fetchCPAccountAndIndirectCodeForInternal(){
        for(Account objAccount : new AccountsSelector().selectDistributorAccountsByTerritoryCode(setTerritoryCode)){
            AccountWrapper objAcccWrap = new AccountWrapper(objAccount);
            if(!mapCodeToAccounts.containsKey(objAccount.Territory_Code__c))
                mapCodeToAccounts.put(objAccount.Territory_Code__c,new List<AccountWrapper>());
            mapCodeToAccounts.get(objAccount.Territory_Code__c).add(objAcccWrap);
            mapAccountIdToAccounts.put((Id)objAcccWrap.strAccountId,objAcccWrap);
        }
        // DCP-40495 : Fetch Quota
        if(!mapAccountIdToAccounts.isEmpty()){
            generateMapAccountToMapYearQuota();
        }
        List<ObjectTerritory2Association> lstOTA = new ObjectTerritory2AssociationsSelector().selectIndirectByAccountIds(mapAccountIdToAccounts.keySet());
        for(ObjectTerritory2Association objOTA : lstOTA){
            if(mapAccountIdToAccounts.containsKey(objOTA.ObjectId))
                mapAccountIdToAccounts.get(objOTA.ObjectId).strIndirectCode = objOTA.Territory2.Territory_Code__c;
        }
    }
    /**
    *  @author KD
    *  @description Territory  assignment for logged in user
    *  @param 
    **/
    public static void fetchTerritoryCode(){
        lstUserTerritory2Association = new UserTerritory2AssociationSelector().selectByUserIdsWithType(new Set<Id>{(Id)userRecordId},TerritoryTypesService.TYPE_TERRITORY);
        System.Debug('-->lstUserTerritory2Association-->'+lstUserTerritory2Association);
        for(UserTerritory2Association objUTA : lstUserTerritory2Association){
            setTerritoryCode.add(objUTA.Territory2.Territory_Code__c);
            lstTerritoryWrapper.add(new TerritoryWrapper(objUTA));
        }
    }
    /**
    *  @author KD
    *  @description Wrapper class for Territory
    *  @param 
    **/
    public class TerritoryWrapper{
        public string strTerritoryName,strTerritoryId,strTerritoryCode,strTerritoryRegion;
        TerritoryWrapper(UserTerritory2Association objAssociation){
            this.strTerritoryName = objAssociation.Territory2.Name;
            this.strTerritoryCode = objAssociation.Territory2.Territory_Code__c;
            this.strTerritoryId = objAssociation.Territory2Id;
            this.strTerritoryRegion =  objAssociation.Territory2.Territory_Region__c;
        }
        // DCP-39735
        TerritoryWrapper(Territory2 objTr){
            this.strTerritoryName = objTr.Name;
            this.strTerritoryCode = objTr.Territory_Code__c;
            this.strTerritoryId = objTr.Id;
            this.strTerritoryRegion = objTr.Territory_Region__c;
        }
    }
    /**
    *  @author KD
    *  @description Wrapper class for Account
    *  @param 
    **/
    public class AccountWrapper{
        public string strAccountName,strAccountId,strIndirectCode;
        public Map<String,Decimal> mapAccountIdToFYQuota = new Map<String,Decimal>();
        AccountWrapper(Account objAccount){
            this.strAccountId = objAccount.Id;
            this.strAccountName = objAccount.Name;    
        }
        AccountWrapper(String strAccountId,Map<String,Decimal> mapAccountIdToFYQuota){
            this.strAccountId = strAccountId;
            this.mapAccountIdToFYQuota = mapAccountIdToFYQuota;    
        }
    }
    /**
    *  @author KD
    *  @description Entry method for fetch page layout [Re-used MDG controller as funtionality remains same]
    *  @param record type id
    *  @return String
    **/
    @AuraEnabled 
    public static String loadPage(String recordTypeID){
        try{
            String strRecorrdTypeId = recordTypeID;
            if(recordTypeID == STRING_COMMUNITY)
                strRecorrdTypeId = Schema.SObjectType.Plan__c.getRecordTypeInfosByDeveloperName().get(Label.Plan_Indirect).getRecordTypeId();
            String strPageLayoutName = 'Plan__c-'+MasterDataRequestController.getPageLayoutAssignment(strRecorrdTypeId);
            return JSON.serialize(MasterDataRequestController.getPageLayoutMetadata(strPageLayoutName));
        }
        catch(Exception e){
            System.debug(LoggingLevel.ERROR, 'Error at line        : ' + e.getLineNumber());
            System.debug(LoggingLevel.ERROR,'The following exception has occurred:++++getMessage+++ ' + e.getMessage());
            System.debug(LoggingLevel.ERROR,'Exception type caught : ' + e.getTypeName());
            System.debug(LoggingLevel.ERROR,'Cause                 : ' + e.getCause());
            System.debug(LoggingLevel.ERROR,'Stack trace           : ' + e.getStackTraceString());
            throw new AuraHandledException(e.getMessage()); 
        }
    }
}