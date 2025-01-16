/**************************************************************************************************************************************
 * NAME   : CasesHelper
 * DESCRIPTION  : Helper class for Case trigger class.                   
 * @AUTHOR : Nitin Sood 
 * MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------
* Nitin                                   Initial Version. 
* Rohan             23-Mar-2022           DCP-49682 Remove initMapElevatedCaseIdToRec and initMapElevatedWOIdToWorkOrders 
* Preetha            30-Mar-2022           QACM-82 Added ValidateIVDCaseLines
* Dhairya Shah      17 April 2024          CMCM-6760 - Removed the method -initMapShowOnCaseLineIdToCases()
* Abhishek Yadav    05 May 2024           CMCM-6731 - Query optimization
**/
public with sharing class CasesHelper {
    public static final String DML_EXCEPTION='System.DmlException';  
    // CMCM-6731
    public static final String CASE_OPTIMIZATION = 'CaseOptimization';
    public static List<Case> lstParentCaseIdToParentCase = new List<Case>();
    public static List<Case> parentCaseIdToParentCase = new List<Case>();
    public static List<SVMXC__Service_Order__c> listOfIdToWorkOrders  = new List<SVMXC__Service_Order__c>();
    public static List<Contact> listofContactIdToContact = new List<Contact> ();
    public static List<Account> listOfAccountIdToAccount = new List<Account>();
    public static List<UserTerritory2Association> listOfUserTerritory2Association = new List<UserTerritory2Association>();
    public static List<User> selectByUserId = new List<User>();
    public static List<SVMXC__Case_Line__c> caseLinesOnCases = new List<SVMXC__Case_Line__c>();
    public static List<Associated_Codes__c> listOfAssociatedCodeIdsToAssociatedCodes = new List<Associated_Codes__c>();
    public static List<Account_to_Field_Support__c> listOfAccToFieldSelctrIDToDetails  = new List<Account_to_Field_Support__c>();
    public static List<Code_Library__c> listOfCodeLibraryIdsToRec = new List<Code_Library__c>();
    public static List<SVMXC__Case_Line__c> listOfIVDProductToCases = new List<SVMXC__Case_Line__c>();
    public static List<Case> secListOfIVDProductToCases = new List<Case>();
    public static List<Contact> secListOfContactIdToContact = new List<Contact>();
    public static List<SVMXC__Installed_Product__c> listOfIPIdToIPDetails = new List<SVMXC__Installed_Product__c>();
    public static List<AccountContactRelation> listOfAccountContactRelation = new List<AccountContactRelation>();
    public static List<Associated_Product__c> caserelatedAP = new List<Associated_Product__c>();
    public static List<Associated_Product__c> caseIVDrelatedAP = new List<Associated_Product__c>();
/*
* for Cases class
*
*/    
	public class ObjCases{
        /*
		*used to do query on Cases object by passing POIds
		*Name: initMapParentCaseIdToParentCase
		*Author: Nitin Sood
		*/
        public void initMapParentCaseIdToParentCase(Set<Id> setFilterIds, boolean forcedQuery){
            
            if(setFilterIds != null && !setFilterIds.isEmpty()){
                initMapParentCaseIdToParentCaseIteration(setFilterIds);
                }
            else if(forcedQuery){
                if(!setFilterIds.containsAll(Cases.mapParentCaseIdToParentCase.keySet())){
                    initMapParentCaseIdToParentCaseIteration(setFilterIds);
                }               
            }           
        }
        /** Helper method of initMapParentCaseIdToParentCase */
        public void initMapParentCaseIdToParentCaseIteration(Set<Id> setFilterIds) {
            if(Cases.mapParentCaseIdToParentCase == null ) {
                Cases.mapParentCaseIdToParentCase = new Map<Id, Case>();
            }
            if((lstParentCaseIdToParentCase.isEmpty() || Feature.isOn(CASE_OPTIMIZATION))) {
                lstParentCaseIdToParentCase = new CasesSelector().selectCases(setFilterIds);
            }
            if (!lstParentCaseIdToParentCase.isEmpty()) {
                for(Case objCase : lstParentCaseIdToParentCase){
                    Cases.mapParentCaseIdToParentCase.put(objCase.id, objCase);
                }
            }
        }
		          
        // used to do DML operation on Case object
        /*public void doUpdateCases(map<Id,Case> caseMap,list<sObject> records){
            if(caseMap!=null && !caseMap.isEmpty()){
                try{
                    update caseMap.values();
                }
                catch(Exception e){
                    Integer numErrors = e.getNumDml();
                    For(Case objCase:(List<Case>)records){
                        if(caseMap.keyset().contains(objCase.id)){
                            if(e.getTypeName()==DML_EXCEPTION){
                                for(Integer i=0;i<numErrors;i++) {
                                    objCase.adderror(e.getDmlMessage(i));
                                }
                            }
                            else{
                                objCase.adderror(e.getMessage());                                
                            }
                        }
                    }
                }                
            }
        }*/        
    }
/*
* for WorkOrders class
*
*/
    
    public class WorkOrders{
        /*
		*Name: initMapWOIdToWorkOrders
		*Author: Nitin Sood
		*/
        public void initMapWOIdToWorkOrders(Set<Id> setFilterIds, boolean forcedQuery){
            
            if((setFilterIds != null && !setFilterIds.isEmpty()) || forcedQuery){
                if(Cases.mapWOIdToWorkOrders == null){
                    if(listOfIdToWorkOrders.isEmpty() || Feature.isOn(CASE_OPTIMIZATION)){
                        listOfIdToWorkOrders = new WorkOrdersSelector().selectWorkOrderIdOnCase(setFilterIds);
                    }
                    Cases.mapWOIdToWorkOrders = new Map<Id, SVMXC__Service_Order__c>(listOfIdToWorkOrders);                                 
                }
			}			
        }		
        // used to do DML operation on Case object
        /*public void doUpdateWOs(map<Id,SVMXC__Service_Order__c> workOrderMap,list<sObject> records){
            if(workOrderMap!=null && !workOrderMap.isEmpty()){
                try{
                    update workOrderMap.values();
                }
                catch(Exception e){
                    Integer numErrors = e.getNumDml();
                    For(SVMXC__Service_Order__c objWO:(List<SVMXC__Service_Order__c>)records){
                        if(workOrderMap.keyset().contains(objWO.id)){
                            if(e.getTypeName()==DML_EXCEPTION){
                                for(Integer i=0;i<numErrors;i++) {
                                    objWO.adderror(e.getDmlMessage(i));
                                }
                            }
                            else{
                                objWO.adderror(e.getMessage());                                
                            }
                        }
                    }
                }                
            }
        }*/ 
    }
/*
* for Contacts class
*
*/
    public class Contacts{
        /*
		*Name: initMapContactIdToContact
		*param: set<string>
		*Author: Nitin Sood
		*/
        public void initMapContactIdToContact(set<String> setEmailStrings){
            if(Cases.mapContactIdToContactForSuppliedEmail == null && !setEmailStrings.isEmpty()){
                if(listofContactIdToContact.isEmpty() || Feature.isOn(CASE_OPTIMIZATION) ) {
                    listofContactIdToContact = new ContactsSelector().ContactsByEmailID(setEmailStrings);
                }
                if(!listofContactIdToContact.isEmpty()) {
                    Cases.mapContactIdToContactForSuppliedEmail = new map<id,Contact> (listofContactIdToContact);                                
                }
            }
        } 
        /*
		*Name: initMapContactIdToContact
		*param: set<Id>
		*Author: Nitin Sood
		*/
        public void initMapContactIdToContact(Set<Id> setFilterIds){

            //query for fetching contact details which are related to cases by passing Ids in filter 
			//// Added Account district and territory region by Shruti Karn for INC0324240
            if(setFilterIds != null && !setFilterIds.isEmpty()){
                if(Cases.mapContactIdToContact == null){
                    if(secListOfContactIdToContact.isEmpty() || Feature.isOn(CASE_OPTIMIZATION)){
                        secListOfContactIdToContact = new ContactsSelector().selectContacts(setFilterIds);
                    }
                    if(!secListOfContactIdToContact.isEmpty()) {
                        Cases.mapContactIdToContact = new Map<Id, Contact>(secListOfContactIdToContact);          
                    }
                }
            }      
        }    

		
    }
/*
* for Accounts class
*
*/
    public class Accounts{
		/*
		*Name: initMapAccountIdToAccount
		*param: set<id>
		*Author: Nitin Sood
		*/
        public void initMapAccountIdToAccount(Set<Id> setFilterIds){
            //query for fetching Accounts which are related to case by passing Ids in filter
            if(setFilterIds != null && !setFilterIds.isEmpty()){
                if(Cases.mapAccountIdToAccount == null ){
                    if(listOfAccountIdToAccount.isEmpty() || Feature.isOn(CASE_OPTIMIZATION) ) {
                        listOfAccountIdToAccount = new AccountsSelector().getAccountsTerritories(setFilterIds);
                    }
                    if(!listOfAccountIdToAccount.isEmpty()) {
                        Cases.mapAccountIdToAccount =  new Map<Id,Account>(listOfAccountIdToAccount); 
                    }
                }
            }
        }    
    }
/*
* for UserTerritory2Associations class
*
*/
    
    public class UserTerritory2Associations {
	    /*
		*Name: initMapIdToUserTerritory2Association
		*param: set<String>
		*Author: Nitin Sood
		*/
        public void initMapIdToUserTerritory2Association(Set<String> setFilterStrings){
            
            //query for fetching UserTerritory2Association by passing supplied emails of case as filter
            if(setFilterStrings != null && !setFilterStrings.isEmpty()){
                if(Cases.mapIdToUserTerritory2Association == null ){
                    if(listOfUserTerritory2Association.isEmpty() || Feature.isOn(CASE_OPTIMIZATION) ) {
                        listOfUserTerritory2Association = new UserTerritory2AssociationSelector().selectByUserWebEmailAddresses(setFilterStrings);
                    }
                    if(!listOfUserTerritory2Association.isEmpty()) {
                        Cases.mapIdToUserTerritory2Association = new Map<Id, UserTerritory2Association>(listOfUserTerritory2Association);
                    }
                }
            }
        }   
    }
/*
* for Users class
*
*/ 
    public class Users{
		/*
		*Name: initMapUserIdToUser
		*param: set<Id>
		*Author: Nitin Sood
		*/
        public void initMapUserIdToUser(Set<Id> setFilterIds, boolean forcedQuery){
            
            //query for fetching User details by passing ownerIds of cases as filter
            if(setFilterIds != null && !setFilterIds.isEmpty()) {
                    initMapUserIdToUsersIteration(setFilterIds);
                }
				else if(forcedQuery && !setFilterIds.containsAll(Cases.mapUserIdToUser.keyset())) {
                    initMapUserIdToUsersIteration(setFilterIds);					
				}
            }

        }
        /** Helper method of initMapUserIdToUser */
        public static void initMapUserIdToUsersIteration(Set<Id> setFilterIds) {
            if(Cases.mapUserIdToUser == null ) {
                Cases.mapUserIdToUser = new Map<Id, User>();	
            }
            if(selectByUserId.isEmpty() || Feature.isOn(CASE_OPTIMIZATION)){
                selectByUserId = new UsersSelector().selectByUserId(setFilterIds);
            }
            if(!selectByUserId.isEmpty()) {
                for(User objUser : selectByUserId) {
                    Cases.mapUserIdToUser.put(objUser.id, objUser);
                }
            }
    }
    
/*
* for InstalledProducts class
*
*/
    public class InstalledProducts{
		/*
		*Name: initMapIPIdToIPDetails
		*param: set<Id>
		*Author: Nitin Sood
		*/
        public void initMapIPIdToIPDetails(set<Id> setFilterIds){
            
            //query for fetching Installed product details which are related to case by passing IP Ids in filter        
            if(setFilterIds != null && !setFilterIds.isEmpty()){
                if(Cases.mapIPIdToIPDetails == null){
                    if(listOfIPIdToIPDetails.isEmpty() || Feature.isOn(CASE_OPTIMIZATION)){
                        listOfIPIdToIPDetails = new InstalledProductsSelector().selectInstalledProductByIds(setFilterIds);
                    }
                    if(!listOfIPIdToIPDetails.isEmpty()) {
                        Cases.mapIPIdToIPDetails = new Map<Id, SVMXC__Installed_Product__c>(listOfIPIdToIPDetails);
                    }
                }
            }
        }
    }
    /*
    * for AssociatedProduct class
    *
    */
    public class AssociatedProduct {
        /*
        *Name: initMapAPidToAssociatedProductDetails
        *param: set<Id>
        *Author: Abhishek Yadav
        */
        public void initMapAPidToAssociatedProductDetails(Set<Id> setFilterIds){
            
            //query for fetching Case Line records related to cases 
            if(setFilterIds != null && !setFilterIds.isEmpty()) {
                if(Cases.mapAPidToAssociatedProductDetails == null) {
                    if(caserelatedAP.isEmpty() || Feature.isOn(CASE_OPTIMIZATION)) {
                       caserelatedAP = new AssociatedProductSelector().selectAPwithCase(setFilterIds);
                    }
                    if (!caserelatedAP.isEmpty()) {
                        Cases.mapAPidToAssociatedProductDetails = new Map<Id, Associated_Product__c>(caserelatedAP);
                    }
                }
            }
        }   
    }
/*
* for AssociatedCodes class
*
*/
    public class AssociatedCodes{
		/*
		*Name: initMapAssociatedCodeIdsToAssociatedCodes
		*param: set<Id>
		*Author: Nitin Sood
		*/
        public void initMapAssociatedCodeIdsToAssociatedCodes(Set<Id> setFilterIds){
            
            if(setFilterIds != null && !setFilterIds.isEmpty()){
                if(Cases.mapAssociatedCodeIdsToAssociatedCodes == null){
                    if(listOfAssociatedCodeIdsToAssociatedCodes.isEmpty() || Feature.isOn(CASE_OPTIMIZATION)){
                        listOfAssociatedCodeIdsToAssociatedCodes = new AssociatedCodeSelector().selectAssociatedCodesOnCases(setFilterIds);
                    }
                    if(!listOfAssociatedCodeIdsToAssociatedCodes.isEmpty()) {
                        Cases.mapAssociatedCodeIdsToAssociatedCodes = new Map<Id, Associated_Codes__c>(listOfAssociatedCodeIdsToAssociatedCodes);
                    }
                }
            }      
        }
    }
/*
* for CaseTeamRoles class
*
*/
    public class CaseTeamRoles{
		/*
		*Name: initMapIdToCaseTeamRole
		*Author: Nitin Sood
		*/
        public void initMapIdToCaseTeamRole(){
            
            if(Cases.mapIdToCaseTeamRole == null){
                Cases.mapIdToCaseTeamRole = new Map<Id, CaseTeamRole>([SELECT Id,Name FROM CaseTeamRole]);            
            }     
        }
    }
/*
* for AccountTechnicians class
*
*/  
    public class AccountTechnicians{
		/*
		*Name: initMapAccToFieldSelctrIDToDetails
		*param: set<Id>
		*Author: Nitin Sood
		*/
        public void initMapAccToFieldSelctrIDToDetails (Set<Id> setFilterIds){
            
            if(setFilterIds != null && !setFilterIds.isEmpty()){
                if(Cases.mapAccToFieldSelctrIDToDetails == null){
                    if(listOfAccToFieldSelctrIDToDetails.isEmpty() ||  Feature.isOn(CASE_OPTIMIZATION)){
                        listOfAccToFieldSelctrIDToDetails =new AccountTechniciansSelector().selectRelatedAccountTechnicians(setFilterIds);
                    }
                    if(!listOfAccToFieldSelctrIDToDetails.isEmpty()) {
                        Cases.mapAccToFieldSelctrIDToDetails = new Map<Id, Account_to_Field_Support__c>(listOfAccToFieldSelctrIDToDetails);
                    }
                }
            }      
        }
    }
/*
* for CaseTeamTemplates class
*
*/
    public class CaseTeamTemplates{ 
	    /*
		*Name: initMapIdToCaseTeamTemplate
		*param: List<String>
		*Author: Nitin Sood
		*/
        public void initMapIdToCaseTeamTemplate(List<String> lstFilterStrings){

            if(Cases.mapIdToCaseTeamTemplate == null){
                Cases.mapIdToCaseTeamTemplate = new Map<Id, CaseTeamTemplate>([Select Id,Name from CaseTeamTemplate 
                                                where Name IN : lstFilterStrings]);         
            }     
        }
    }
 /*
* for CaseTeamMembers class
*
*/  
    public class CaseTeamMembers{
		/*
		*Name: initMapIdToCaseTeamMember
		*param: set<Id>
		*Author: Nitin Sood
		*/
        public void initMapIdToCaseTeamMember(Set<Id> setFilterIds){

            if(Cases.mapIdToCaseTeamMember == null){
                Cases.mapIdToCaseTeamMember = new Map<Id, CaseTeamMember>([Select MemberId, ParentId, Member.Email
                                                        from CaseTeamMember 
                                                        WHERE ParentId IN : setFilterIds]);         
            }     
        }
    }
 /*
* for CodeLibraries class
*
*/   
    public class CodeLibraries{ 
	    /*
		*Name: initMapCodeLibraryIdsToRec
		*param: set<String>
		*Author: Nitin Sood
		*/
        public void initMapCodeLibraryIdsToRec(Set<String> setFilterStrings){

            if(setFilterStrings != null && !setFilterStrings.isEmpty()){
                if(Cases.mapCodeLibraryIdsToRec == null){
                    if( listOfCodeLibraryIdsToRec.isEmpty() || Feature.isOn(CASE_OPTIMIZATION)){
                        listOfCodeLibraryIdsToRec= new CodeLibrarySelector().selectCodeLibraryByTitle(setFilterStrings);
                    }
                    if(!listOfCodeLibraryIdsToRec.isEmpty()) {
                        Cases.mapCodeLibraryIdsToRec = new Map<Id, Code_Library__c>(listOfCodeLibraryIdsToRec);            
                    }
                }
            }      
        }
    }
/*
* for AccountContactRelations class
*
*/    
    public class AccountContactRelations{
		/*
		*Name: initMapACRelationIdToACRelation
		*param: set<Id>
		*Author: Nitin Sood
		*/
        public void initMapACRelationIdToACRelation(Set<Id> setFilterIds){
            
            //query for fetching Accounts linked with the contacts which are related to case by passing contact Ids in filter
            if(setFilterIds != null && !setFilterIds.isEmpty()){
                if(Cases.mapACRelationIdToACRelation == null ){
                    if(listOfAccountContactRelation.isEmpty() ||  Feature.isOn(CASE_OPTIMIZATION) ){
                        listOfAccountContactRelation = new AccountContactRelationsSelector().getAccountContactRelationByContactId(setFilterIds);
                    }
                    if(!listOfAccountContactRelation.isEmpty()) {
                        Cases.mapACRelationIdToACRelation =  new Map<Id,AccountContactRelation>(listOfAccountContactRelation);
                    }
                }
            }
        }
    }
/*
* for PublicGroups class
*
*/   
    public class PublicGroups{
		/*
		*Name: initMapGroupNameToGroupId
		*Author: Nitin Sood
		*/
        public void initMapGroupNameToGroupId(){

            //query for fetching Group Ids on behalf of their names
            if(Cases.mapGroupNameToGroupId == null){
                Cases.mapGroupNameToGroupId = new Map<String,Id>();
                for(Group objGroup : [select id,developername from group where developername IN: Cases.setGroupNames]){
                    Cases.mapGroupNameToGroupId.put(objGroup.developername, objGroup.Id);
                }
            }
        }
    }
/*
* for CaseRoutingCriteriaMapping class
*
*/
    public class CaseRoutingCriteriaMapping{    
	    /*
		*Name: initMapCaseRoutingCriteriaMappings
		*Author: Nitin Sood
		*/
        public void initMapCaseRoutingCriteriaMappings(){
                
            //query for fetching case routing criteria mappings     
            if(Cases.mapIdToRoutingCriteria == null){
                Cases.mapIdToRoutingCriteria = new Map<Id, Case_Routing_Criteria_Mappings__mdt>([SELECT From_Addresses__c, Keywords__c, DeveloperName, Case_Origin__c,Case_Status__c,Category__c,Priority__c,Sub_Type__c FROM Case_Routing_Criteria_Mappings__mdt where Active__c = True AND Features_Added__c like '%Auto Closure%' order by Priority__c]);
            }
        }
    }

    /**
    *  @author Deepika Ayyavari
    *  @description - Check Internal Non customer checkbox for TS.
    *  Name - initMapInternalNonCustomerCriteriaMappings
    */ 

    public class InternalNonCustomerCriteriaMapping{    
        /*  @description - Check Internal Non customer checkbox for TS. */
            public void initMapInternalNonCustomerCriteriaMappings(){
                    
                //query for fetching case routing criteria mappings     
                if(Cases.mapIdToInternalNonCustomerCriteria == null){
                    Cases.mapIdToInternalNonCustomerCriteria = new Map<Id, Case_Routing_Criteria_Mappings__mdt>([SELECT From_Addresses__c, Keywords__c, DeveloperName, Case_Origin__c,Case_Status__c,Category__c,Priority__c,Sub_Type__c FROM Case_Routing_Criteria_Mappings__mdt where Active__c = True AND Features_Added__c like '%Internal Non Customer%']);
                }
            }
    }


 /*
* for AssociatedCodeMapping class
*
*/
    public class AssociatedCodeMapping{ 
	    /*
		*Name: initMapAssociatedCodesMapping
		*Author: Nitin Sood
		*/
        public void initMapAssociatedCodesMapping(){
            
            //query for fetching case routing criteria mappings     
            if(Cases.mapAssociatedCodesMapping == null){
                Cases.mapAssociatedCodesMapping = new Map<Id, Associated_Code_Mapping__mdt>([Select MasterLabel,Category__c,Code_Title__c,Sub_Type__c from Associated_Code_Mapping__mdt]);
            }
        }
    }
/*
* for Profiles class
*
*/
    public class Profiles{ 
	    /*
		*Name: initLoggedInProfileName
		*Author: Nitin Sood
		*/
        public void initLoggedInProfileName(){
            
            //query for fetching logged in user's profile name
            if(Cases.loggedInUserProfileName == null ){
                List<Profile> lstLoggedInUserProfile = [SELECT Id, Name FROM Profile WHERE Id=:userinfo.getProfileId() LIMIT 1];
                if(lstLoggedInUserProfile != null && !lstLoggedInUserProfile.isEmpty()){
                    Cases.loggedInUserProfileName = lstLoggedInUserProfile[0].Name;
                }
            }   
        }
    }
     /*
    * for ShowOnCaseLines class - QACM-18
    *
    */

    /*
    * for ValidateIVDAssociatedProducts class - CMCM
    *
    */
    public class ValidateIVDAssociatedProducts{
        /*
        *Name: initMapIVDProductToCases
        *param: set<Id>
        *Author: Preetha
        */
        public void initMapIVDProductToCases(Set<Id> setFilterIds){
            //query for fetching Case Line records related to cases And Case Product details
            if(setFilterIds != null && !setFilterIds.isEmpty()){
                if(Cases.mapIVDAssociatedProductIdToCases == null){
                    if(caseIVDrelatedAP.isEmpty() || Feature.isOn(CASE_OPTIMIZATION)){
                        caseIVDrelatedAP = new AssociatedProductSelector().selectAPwithCase(setFilterIds);
                    }
                    if (!caseIVDrelatedAP.isEmpty()) {
                        Cases.mapIVDAssociatedProductIdToCases = new Map<Id, Associated_Product__c>(caseIVDrelatedAP);
                    }
                }
                if(Cases.mapCaseProductDetails == null){
                    if(secListOfIVDProductToCases.isEmpty() ||  Feature.isOn(CASE_OPTIMIZATION)){
                        secListOfIVDProductToCases = new CasesSelector().selectCasesWithProduct(setFilterIds);
                    }
                    
                    Cases.mapCaseProductDetails = new Map<Id,Case>(secListOfIVDProductToCases);           
                }
            }
        }      
    } 
    
    
}