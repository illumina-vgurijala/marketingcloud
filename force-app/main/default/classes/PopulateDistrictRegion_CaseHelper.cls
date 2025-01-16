/**
 * @description       : DCP-53957: Codescan fix : Populate District and Region on Case based on user territory
 * @author            : Pooja
 * @group             : 
 * @last modified on  : 06-12-2022
**/
public class PopulateDistrictRegion_CaseHelper {
   
    /**
    * @description :Populate District and Region on Case
    * @author:Pooja
    * @param records 
    * @param oldRecords 
    **/
    public static void populateDistrictRegionOnCase(List<Sobject> records, Map<Id, SObject> oldRecords ){
        
        Map<String,UserTerritory2Association> userEmailAddressToETMUserTerritoryMap = new Map<String,UserTerritory2Association>();      
        Set<Id> setAccountIds =  new Set<Id>();
		Set<Id> setContactIds =  new Set<Id>();
        set<string> setWebEmailAddresses  = new set<string>();
         for(Case objCase : (List<Case>)records) {
            
            Case objOldCase=oldRecords!=null && !oldRecords.isEmpty() ? (Case)(oldRecords.get(objCase.Id)) : null;    
                                 
            //DCP-37827
            if(String.isNotBlank(objCase.SuppliedEmail) && objCase.Origin != 'WeChat - CS' &&  objOldCase == null){
                setWebEmailAddresses.add(objCase.SuppliedEmail);   
            }
            
            if((objOldCase == null && objCase.AccountId!=null) || (objOldCase != null && objOldCase.AccountId != objCase.AccountId)){
                setAccountIds.add(objCase.AccountId);
            }
			// Added by Shruti Karn for INC0324240
			if((objOldCase == null && objCase.contactid!=null) || (objOldCase != null && objOldCase.contactid != objCase.contactid)){
				setContactIds.add(objCase.contactid);
			}
        }
        
        //Pooja : DCP-53957
        if(!setWebEmailAddresses.isEmpty() && setWebEmailAddresses!= null){
        userEmailAddressToETMUserTerritoryMap=getUserEmailAddressFromTerritory(setWebEmailAddresses);
        }
        //Pooja: DCP-53957 :END

		// Added by Shruti Karn for INC0324240
		CasesHelper.Contacts contactsQuery = new  CasesHelper.Contacts();		
        contactsQuery.initMapContactIdToContact(setContactIds);
		
		CasesHelper.Accounts accountsQuery = new  CasesHelper.Accounts();		
        accountsQuery.initMapAccountIdToAccount(setAccountIds);
        //DCP-53597: codescan story: complexity fix
        updateCaseRegionAndDistrict(records,oldRecords,userEmailAddressToETMUserTerritoryMap);
        //END 
    }
	
    /**
    * @description :DCP-53957: codescan fix:add user email address based on the user territory
    * @author Pooja
    * @param setWebEmailAddresses 
    * @return Map<String, UserTerritory2Association> 
    **/
    public static Map<String,UserTerritory2Association> getUserEmailAddressFromTerritory(set<string> setWebEmailAddresses)
    {
        Map<String,UserTerritory2Association> mapUserEmailAddressToETMUserTerritory = new Map<String,UserTerritory2Association>();
        if(setWebEmailAddresses != null && !setWebEmailAddresses.isEmpty()){
			CasesHelper.UserTerritory2Associations userTerritoryQuery = new  CasesHelper.UserTerritory2Associations();
            userTerritoryQuery.initMapIdToUserTerritory2Association(setWebEmailAddresses);
            if(Cases.mapIdToUserTerritory2Association != null && !Cases.mapIdToUserTerritory2Association.isEmpty()){
                mapUserEmailAddressToETMUserTerritory=setUserEmailAddress();
            }        
        }
        return mapUserEmailAddressToETMUserTerritory;
    }
    
    /**
    * @description :set Email Address based on Territory
    * @return Map<String, UserTerritory2Association> 
    **/
    public static Map<String,UserTerritory2Association> setUserEmailAddress()
    {    
        Map<String,UserTerritory2Association> mapUserEmailAddressToETMUserTerritory = new Map<String,UserTerritory2Association>();
        for(UserTerritory2Association userTerritoryObj : Cases.mapIdToUserTerritory2Association.values())
        {
            //INC0295918 - Fix to bypass channel partner users to fetch the value of district,region from ETM table
            if (String.isNotBlank(userTerritoryObj.Territory2Id) 
            && String.isNotBlank(userTerritoryObj.User.ProfileId)   
            && Channel_Partner_Profile_Settings__c.getInstance(userTerritoryObj.User.ProfileId).Is_Channel_Partner__c != true 
            && !mapUserEmailAddressToETMUserTerritory.containsKey(userTerritoryObj.User.Email)) {
                mapUserEmailAddressToETMUserTerritory.put(userTerritoryObj.User.Email, userTerritoryObj);
            }
        } 
        return mapUserEmailAddressToETMUserTerritory;
    }
    /**
    * @description : DCP-53957: codescan story: To update case region and district based on user territory
    * @Author Pooja Shalwadi
    * @Param records 
    * @Param oldRecords 
    * @Param userEmailAddressToETMUserTerritoryMap 
    **/
    public static void updateCaseRegionAndDistrict(List<Sobject> records, Map<Id, SObject> oldRecords,Map<String,UserTerritory2Association> userEmailAddressToETMUserTerritoryMap)
    { 
        for(Case objCase : (List<Case>)records) {   
            Case objOldCase=null;       
            if(oldRecords!=null && !oldRecords.isEmpty()){
                objOldCase = (Case)(oldRecords.get(objCase.Id));
            } 
            if(String.isNotBlank(objCase.SuppliedEmail) && userEmailAddressToETMUserTerritoryMap.containsKey(objCase.SuppliedEmail) &&  Cases.isDistrictRegionUpdated == false){           
                objCase.District__c =  userEmailAddressToETMUserTerritoryMap.get(objCase.SuppliedEmail).Territory2.District__c;
                objCase.Region__c =  userEmailAddressToETMUserTerritoryMap.get(objCase.SuppliedEmail).Territory2.Territory_Region__c;
                    Cases.isDistrictRegionUpdated = true;					
            }
            else if(objCase.AccountId !=null && Cases.mapAccountIdToAccount!=null && Cases.mapAccountIdToAccount.containskey(objCase.AccountId) && Cases.mapAccountIdToAccount.get(objCase.AccountId).District__c !=null && Cases.mapAccountIdToAccount.get(objCase.AccountId).Territory_Region__c !=null && 
                (objOldCase == null || (objOldCase != null && objCase.Status !=Cases.STRING_CLOSED && objCase.Status != Cases.STRING_CASE_STATUS_CLOSED_DUPLICATE && objCase.Status !='Reopen Requested' &&  Cases.isDistrictRegionUpdated == false)))
                {
                    objCase.Region__c = Cases.mapAccountIdToAccount.get(objCase.AccountId).Territory_Region__c;
                    objCase.District__c = Cases.mapAccountIdToAccount.get(objCase.AccountId).District__c;
					Cases.isDistrictRegionUpdated = true;
                }
			// Added by Shruti Karn for INC0324240
			else if(objCase.Contactid !=null && Cases.mapContactIdToContact!=null && Cases.mapContactIdToContact.containskey(objCase.contactid) && Cases.mapContactIdToContact.get(objCase.contactid).Account.District__c !=null && Cases.mapContactIdToContact.get(objCase.contactid).Account.Territory_Region__c !=null &&
                (objOldCase == null || (objOldCase != null && objCase.Status !=Cases.STRING_CLOSED && objCase.Status != Cases.STRING_CASE_STATUS_CLOSED_DUPLICATE && objCase.Status !='Reopen Requested' &&  Cases.isDistrictRegionUpdated == false )))
                {
                    objCase.Region__c =Cases.mapContactIdToContact.get(objCase.contactid).Account.Territory_Region__c;
                    objCase.District__c =Cases.mapContactIdToContact.get(objCase.contactid).Account.District__c;
					Cases.isDistrictRegionUpdated =  true;
                }
        } 
    } 
}
