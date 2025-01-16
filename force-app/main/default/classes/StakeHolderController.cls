/**
*    @author Vaibhav Sirohi
*    @date   8-Aug-2019
*    @description   
*    Modification Log:
*    ------------------------------------------------------------------------------------ 
*    Developer                      Date                Description
*    Kushaagra Desai                10-Oct-2019         Added Lazy load for search funtionality
*    Aman Tyagi                     31-Mar-2022         CodeScan Fixes
*    Prem Ranjan                    20-Feb-2023         CodeScan Fixes (APEX) Variable Naming Conventions 
*    ------------------------------------------------------------------------------------ 
*                    
*/
public class StakeHolderController { 
   /*
    *  @AUTHOR:  Vaibhav Sirohi
    *  @DESCRIPTION: getResults method to fetch all the contact records in  the hierarchy  where name is like inputText 
    *  @PARAM :  String recordId, String inputText
    *  @RETURN:  WrapperForContactRecord
    */
    @AuraEnabled
    public static list<WrapperForContactRecord> getResults(String recordId , String inputText, Integer offSet){
        String currentContactName = '%'+ inputText + '%';
        system.debug('inputText-->'+inputText);
         Set<Id> contactId = new Set<Id>(); 
        system.debug('recordId-->'+recordId);
        List<WrapperForContactRecord> lstWrapperForContactRecord = new List<WrapperForContactRecord>();
        List<Key_Stakeholder_Analysis__c> lstStakeholder = new StakeholdersSelector().selectStakeholders(recordId);
        for(Key_Stakeholder_Analysis__c keyStakeholderInstance : lstStakeholder){
            contactId.add(keyStakeholderInstance.Contact__c);
        }
        
        Account_Plan__c objAccountPlanInstance = new AccountPlanSelector().getAccountPlanByAccountPlanRecordId(recordId);
        if( objAccountPlanInstance != null){
            List<AccountContactRelation> lstAccountContactRelation = new AccountContactRelationsSelector()
                .getAcountContactRelationOfAccount(objAccountPlanInstance.Account_Name__r.Ultimate_Parent_Id__c,objAccountPlanInstance.Account_Name__r.Ultimate_Parent__c,
                                                   currentContactName,
                                                  contactId,offSet);
            system.debug('lstContact-->'+lstAccountContactRelation);
            for(AccountContactRelation c : lstAccountContactRelation){
            WrapperForContactRecord wrapperForContactRecordInstance = new WrapperForContactRecord();
            wrapperForContactRecordInstance.Name = c.Contact.Name;
            wrapperForContactRecordInstance.NameUrl = '/'+c.ContactId;
            wrapperForContactRecordInstance.ContactID = c.ContactId;
            wrapperForContactRecordInstance.Title = c.Contact.Title;
            wrapperForContactRecordInstance.AccountName = c.Account.Name;
            wrapperForContactRecordInstance.AccountUrl = '/'+c.AccountId;
            wrapperForContactRecordInstance.Region = c.Contact.Region__c;
            wrapperForContactRecordInstance.Email = c.Contact.Email;
            wrapperForContactRecordInstance.Roles =  c.Roles;
            
            lstWrapperForContactRecord.add(wrapperForContactRecordInstance);
        }
        }
        return lstWrapperForContactRecord;
    }
   /*
    *  @AUTHOR:  Vaibhav Sirohi
    *  @DESCRIPTION: getAllContact method to fetch all the contact records where name is like inputText  
    *  @PARAM :  String inputText
    *  @RETURN:  WrapperForContactRecord
    */
    @AuraEnabled
    public static list<WrapperForContactRecord> getAllContact(String inputText, String recordId, Integer offSet){
        String currentContactName = '%'+ inputText + '%';
       
        system.debug('inputText-->'+inputText);  
        Set<Id> contactId = new Set<Id>(); 
        List<WrapperForContactRecord> lstWrapperForContactRecord = new List<WrapperForContactRecord>();
        List<Key_Stakeholder_Analysis__c> lstStakeholder = new StakeholdersSelector().selectStakeholders(recordId);
        for(Key_Stakeholder_Analysis__c keyStakeholderInstance : lstStakeholder){
            contactId.add(keyStakeholderInstance.Contact__c);
        }
        List<AccountContactRelation> lstAccountContactRelation = new AccountContactRelationsSelector().getAcountContactRelationOfAccount(null, null, currentContactName , contactId,offSet);
        system.debug('lstContact-->'+lstAccountContactRelation);
        for(AccountContactRelation c : lstAccountContactRelation){
            WrapperForContactRecord wrapperForContactRecordInstance = new WrapperForContactRecord();
            wrapperForContactRecordInstance.Name = c.Contact.Name;
            wrapperForContactRecordInstance.NameUrl = '/'+c.ContactId;
            wrapperForContactRecordInstance.ContactID = c.ContactId;
            wrapperForContactRecordInstance.Title = c.Contact.Title;
            wrapperForContactRecordInstance.AccountName = c.Account.Name;
            wrapperForContactRecordInstance.AccountUrl = '/'+c.AccountId;
            wrapperForContactRecordInstance.Region = c.Contact.Region__c;
            wrapperForContactRecordInstance.Email = c.Contact.Email;
            wrapperForContactRecordInstance.Roles =  c.Roles;
            
            lstWrapperForContactRecord.add(wrapperForContactRecordInstance);
        }
        return lstWrapperForContactRecord;
    }
    /*
    *  @AUTHOR:  Vaibhav Sirohi
    *  @DESCRIPTION: getAllStakeholderRecord method to fetch all the Stakeholder records   
    *  @PARAM :  String recordId
    *  @RETURN:  Key_Stakeholder_Analysis__c
    */
    @AuraEnabled(cacheable=true)
    public static list<Key_Stakeholder_Analysis__c> getAllStakeholderRecord(String recordId){
        List<Key_Stakeholder_Analysis__c> lstStakeholder = new StakeholdersSelector().selectStakeholders(recordId);
        for(Key_Stakeholder_Analysis__c keyStaakeInstance : lstStakeholder){            
            keyStaakeInstance.Priority_Interests_Objectives__c = keyStaakeInstance.Priority_Interests_Objectives__c.replaceAll('<[^>]+>',' ');
            keyStaakeInstance.Pain_Points_Concerns__c = keyStaakeInstance.Pain_Points_Concerns__c.replaceAll('<[^>]+>',' ');
            system.debug(' keyStaakeInstance.Pain_Points_Concerns__c'+ keyStaakeInstance.Pain_Points_Concerns__c);
            system.debug(' keyStaakeInstance.Priority_Interests_Objectives__c'+  keyStaakeInstance.Priority_Interests_Objectives__c);
        }
        return lstStakeholder;
    }
   /*
    *  @AUTHOR:  Vaibhav Sirohi
    *  @DESCRIPTION: updateStakeholer method to update all the Stakeholder records    
    *  @PARAM :  String recordId
    *  @RETURN:  Key_Stakeholder_Analysis__c
    */
    @AuraEnabled
    public static boolean updateStakeholer(List<Key_Stakeholder_Analysis__c> editedStakeholerList){
        system.debug('editedStakeholerList'+editedStakeholerList);
        try{
            update editedStakeholerList;
            system.debug('editedStakeholerList--->'+editedStakeholerList);
            return true;
        } catch(Exception e){
            system.debug('e--->'+e);
            return false;
        }
    }
    
    /*
    * @Author: Vaibhav Sirohi
    * @Description : wrapper class for storing the contact records
    */
    public class WrapperForContactRecord{
        @AuraEnabled
        public String Name;
        @AuraEnabled
        public String NameUrl;
        @AuraEnabled
        public String ContactID;
        @AuraEnabled
        public String Title;
        @AuraEnabled
        public String Roles;
        @AuraEnabled
        public String AccountName;
        @AuraEnabled
        public String AccountUrl;
        @AuraEnabled
        public String Region;
        @AuraEnabled
        public String Email;
        @AuraEnabled
        public String Icon;
        
    }
    
}