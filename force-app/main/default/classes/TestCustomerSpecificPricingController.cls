/*
 * @Author: Rishab Wali
 * @Date: 17-MAR-2019
 * @Description :Mock Callout For Customer Specific Pricing Interface
*Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                        Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Rishab Wali            12-MAR-2019                   Test Class For CustomerSpecificPricingController Class. DCP 34078
* Saddam Hussain         28-SEP-2021                   CMCP-13 Test Method for checkAccessCP()
* Aman Tyagi              12-Dec-2022                   CodeScan Fixes
*/
@isTest
public class TestCustomerSpecificPricingController {

    //Create common test data
    @testSetup static void setup() 
    {
        Account acc = TestDataAccount.getUCAccount();
        insert acc;
        
        Product2 product = new Product2(Name='Test Product',ProductCode='121212',IsActive=true);
        insert product;
    } 
    
     /**
     *  @AUTHOR Rishab Wali
     *  @DESCRIPTION - Method to run the mock callout for interface test class
     *  @PARAM : Void
     *  @RETURN : Void
     **/    
@isTest
public static void testMethod1()
{
    CustomerSpecificPricingController.checkAccess();
    
    Account acc = [SELECT Id FROM Account LIMIT 1];
    Product2 prod = [SELECT Id FROM Product2 LIMIT 1];
    
    CustomerSpecificPricingController.getTerritoryAccess(acc.Id);
    
    User us = [SELECT Id FROM User WHERE User.Profile.Name = 'Sales User' AND IsActive = True LIMIT 1];
    
    System.runAs(us)
    {
        CustomerSpecificPricingController.getTerritoryAccess(acc.Id);
    }
    
    CustomerSpecificPricingController.search('Te',new List<Id>{},'Product2','standard:product');
    
    String prodId = prod.Id;
    
    String jsonRequest = '[{"icon":"standard:product","id":"' + prodId + '","sObjectType":"Product2","title":"Solutions Centre Delivered Applications Training- Daily"}]';
    test.startTest();
    LookupSearchResultController lkupsrch = new LookupSearchResultController(prodId,'Product2','standard:product','title');
    lkupsrch.getId();
    lkupsrch.getIcon();
    lkupsrch.getSObjectType();
    lkupsrch.getTitle();
    //Testing Callout
      Test.setMock(HttpCalloutMock.class, new MockHTTPCalloutCustomerSpecificPricing());
      String res = CustomerSpecificPricingController.getPricingData(acc.Id,jsonRequest);
      System.assertEquals(true,String.isNotBlank(res));
    test.stopTest();
}     
     /**
     *  @AUTHOR saddam hussain cmcp-13 
     *  @DESCRIPTION : Test method to check Cp Account match  
     *  @RETURN : Void
     **/    
    @isTest
    public static void testCheckAccessCp(){
        Account objAccount1 = TestDataAccount.getAccount('Test Acc cp', 'USD');
        objAccount1.Account_Group__c='Distributor';
        insert objAccount1;

        //Created Contact1
         Contact objContact = TestDataContact.getNewContact(objAccount1);

         //Creating User
         User objUser;
         User objUser1 = TestDataUser.findUserInProfile('System Administrator',new Set<Id>{Id.valueOf(UserInfo.getUserId())});
         TestDataUser.allowUserCreation(objUser1.Id); 

         System.runAs(objUser1) {

        Id profileId = [SELECT Id FROM Profile WHERE Name = 'Channel Partner Sales and Service' LIMIT 1].id;    
        //Created User
        objUser = TestDataUser.initPartnerUser(profileId,objContact.id);
        insert objUser;
 
        Channel_Partner_Profile_Settings__c cp = new Channel_Partner_Profile_Settings__c();
        cp.SetupOwnerId= profileId;
        cp.Is_Channel_Partner__c= True;
        insert cp;
        }
        Boolean checkAccessCP = false ;
        test.startTest();
        System.runAs(objUser){
        checkAccessCP=CustomerSpecificPricingController.checkAccessCP(objAccount1.Id);
        }
        test.stopTest();
        System.assertEquals(true,checkAccessCP,'Access not granted');
    }
     /**
     *  @AUTHOR saddam hussain cmcp-13 
     *  @DESCRIPTION : Test method to check if the current user is not the ChannelPartner user   
     *  @RETURN : Void
     **/ 
    @isTest
    public static void testCheckAccessCpInternalUser(){

        Account objAccount1 = TestDataAccount.getAccount('Test Acc cp', 'USD');
        objAccount1.Account_Group__c='Distributor';
        insert objAccount1;
        Boolean checkAccessCP = false ;
        test.startTest();
        checkAccessCP=CustomerSpecificPricingController.checkAccessCP(objAccount1.Id);
        test.stopTest();
        System.assertEquals(true,checkAccessCP,'Access not granted');

    }
     /**
     *  @AUTHOR saddam hussain cmcp-13 
     *  @DESCRIPTION : Test method to check Cp Account not equals to passed Account  
     *  @RETURN : Void
     **/ 
    @isTest
    public static void testCheckAccessCpAccountNotEqual(){

        Account objAccount1 = TestDataAccount.getAccount('Test Acc cp', 'USD');
        objAccount1.Account_Group__c='Distributor';
        insert objAccount1;
        Account objAccount2 = TestDataAccount.getAccount('Test Acc cp1', 'USD');
        objAccount2.Account_Group__c='Distributor';
        insert objAccount2;
        //Created Contact1
        Contact objContact = TestDataContact.getNewContact(objAccount1);
        //Creating User
        User objUser;
        User objUser1 = TestDataUser.findUserInProfile('System Administrator',new Set<Id>{Id.valueOf(UserInfo.getUserId())});
        TestDataUser.allowUserCreation(objUser1.Id); 

        System.runAs(objUser1) {
            Id profileId = [SELECT Id FROM Profile WHERE Name = 'Channel Partner Sales and Service' LIMIT 1].id;
            
            //Created User
            objUser = TestDataUser.initPartnerUser(profileId,objContact.id);
            insert objUser;

            Channel_Partner_Profile_Settings__c cp = new Channel_Partner_Profile_Settings__c();
            cp.SetupOwnerId= profileId;
            cp.Is_Channel_Partner__c= True;
            insert cp;
        }
        Boolean checkAccessCP = false ;
        test.startTest();
        System.runAs(objUser){
        checkAccessCP=CustomerSpecificPricingController.checkAccessCP(objAccount2.Id);
        }
        test.stopTest();
        System.assertEquals(false,checkAccessCP,'Access not granted');

    }

    /**
     *  @AUTHOR saddam hussain cmcp-13 
     *  @DESCRIPTION : Test method to check Cp Profiles
     *  @RETURN : Void
     **/    
    @isTest
    public static void testCPProfile(){

        //Create Account
        Account objAccount = TestDataAccount.getAccount('Test Acc2354', 'USD');
        objAccount.Account_Group__c='Distributor';
        Insert objAccount;
        
        //Create Contact
        Contact objContact = TestDataContact.getNewContact(objAccount);


         //Creating User
         User objUser;
         User objUser1 = TestDataUser.findUserInProfile('System Administrator',new Set<Id>{Id.valueOf(UserInfo.getUserId())});
         TestDataUser.allowUserCreation(objUser1.Id); 

         System.runAs(objUser1) {

        Id profileId = [SELECT Id FROM Profile WHERE Name = 'Channel Partner Sales and Service' LIMIT 1].id;    
        //Created User
        objUser = TestDataUser.initPartnerUser(profileId,objContact.id);
        insert objUser;
 
        Channel_Partner_Profile_Settings__c cp = new Channel_Partner_Profile_Settings__c();
        cp.SetupOwnerId= profileId;
        cp.Is_Channel_Partner__c= True;
        insert cp;
        }
        Boolean checkCPAccess = false ;
        test.startTest();
        System.runAs(objUser){ 
        checkCPAccess=CustomerSpecificPricingController.checkCPProfile();
        }
        test.stopTest();
        system.assertEquals(true,checkCPAccess,'Access not granted');
    }
    
}

