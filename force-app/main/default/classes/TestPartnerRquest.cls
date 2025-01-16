/***************************************************************************************************************************************
* NAME   : TestPartnerRquest
* DESCRIPTION  : For Covering the "Record-Trigger : Partner Request : Create Partner Contact"
*    
* @AUTHOR : Abhishek
* @DATE   : 11-Oct-2023  
*
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------
* Abhishek             11-Oct-2023              Initial Version (CMCM-3462)
****************************************************************************************************************************************/ 
@isTest
public class TestPartnerRquest {
    public final static Id ADDTEAMMEMBER_RECORD_TYPE_ID = Schema.SObjectType.Partner_Request__c.getRecordTypeInfosByName().get('Portal Request - Add Team Member').getRecordTypeId();
    public final static Id UPDATE_MEMBER_REQUEST_TYPE_ID = Schema.SObjectType.Partner_Request__c.getRecordTypeInfosByName().get('Portal Request - Update Member Request').getRecordTypeId();
    /**
    *  @author Abhishek
    *  @description - NO Contact Path Testing 
    **/
    @isTest
    public static void testNoContact() {
        //Created Account
        Account objAccount = TestDataAccount.getCustomerAccount();
        insert objAccount;
        //Created Contact
        Contact objContact = TestDataContact.getNewContact(objAccount);
        
        //Query Profile
        Id profileId = [SELECT Id FROM Profile WHERE Name = 'Channel Partner Sales and Read Only Service' LIMIT 1].id;
        //Created User
        User objUser = TestDataUser.initPartnerUser(profileId,objContact.id);
        insert objUser;
        System.runAs(objUser) {
            Test.startTest();
            List<Partner_Request__c> prList = TestDataPartnerPortal.getNewPartnerRequest(1);
            prList[0].recordTypeId = ADDTEAMMEMBER_RECORD_TYPE_ID;
            prList[0].Job_Category__c = 'Staff';
            prList[0].Channel_Partner_eMail_Opt_Out__c = true;
            prList[0].Email__c = 'test@Staff.com';
            prList[0].First_Name__c = 'Jhon';
            prList[0].Last_Name__c = 'doe';
            prList[0].Phone__c = '(758) 771-0091';
            prList[0].Title__c = 'Staff Account';
            prList[0].ownerId = objUser.Id;
            insert prList;
            Test.stopTest();
        }
        Contact con = [SELECT Id FROM Contact WHERE AccountId = :objAccount.Id LIMIT 1];
        Assert.isTrue(con != null);
    }
    /**
    *  @author Abhishek
    *  @description - existing Contact Path Testing 
    **/
    @isTest
    public static void testExistingContact() {
        //Created Account
        Account objAccount = TestDataAccount.getNewAccount();
        
        //Created Contact
        Contact objContact = TestDataContact.getNewContact(objAccount);
        
        //Query Profile
        Id profileId = [SELECT Id FROM Profile WHERE Name = 'Channel Partner Sales and Service' LIMIT 1].id;
        
        //Created User
        User objUser = TestDataUser.initPartnerUser(profileId,objContact.id);
        insert objUser;
        System.runAs(objUser) {
            Test.startTest();
            List<Partner_Request__c> prList = TestDataPartnerPortal.getNewPartnerRequest(1);
            prList[0].recordTypeId = UPDATE_MEMBER_REQUEST_TYPE_ID;
            prList[0].Team_Member_Name__c = objContact.id;
            prList[0].Channel_Partner_eMail_Opt_Out__c = true;
            insert prList;
            Test.stopTest();
        }
        Contact con = [SELECT Id,Channel_Partner_eMail_Opt_Out__c FROM Contact WHERE Id =:objContact.id LIMIT 1];
        Assert.areEqual(con.Channel_Partner_eMail_Opt_Out__c,true);
    }
}