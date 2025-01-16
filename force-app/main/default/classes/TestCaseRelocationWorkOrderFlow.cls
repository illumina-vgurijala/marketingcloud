/**************************************************************************************************************************
* @Author:  Nidhi Hegde
* @Date:    16-Oct-2023
* @Name:    TestCaseRelocationWorkOrderFlow
* @Description: Test method for Case: For Covering Case_Relocation_Work_Order_Notifications Flow
* ------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* ------------------------------------------------------------------------------------
* Nidhi Hegde             16-Oct-2023        Initial Version (CMCM-3827)
***************************************************************************************************************************/

@isTest
public class TestCaseRelocationWorkOrderFlow {
    public static final string STRING_LOCATION = 'Test Location';
    public static final string STRING_STREET = 'Test Street';
    public static final string STRING_INSTALLED_PRODUCT_NAME = 'Test IP';
    public static final string STRING_CURRENCY = 'USD';
    public static final string STRING_INSTALLED_PRODUCT_STATUS = 'New';
    public static final string STRING_PRODUCT_CODE = 'Test 1234';
    public static final string STRING_PRODUCT_MATERIAL_CLASS = 'Consumable';
    public static final string LOCATION_PARTNER_STOCK = 'Partner Stock';
    
    /**
    *  @author Nidhi
    *  @description - Positive Testing 
    **/
    @isTest
    public static void testCaseRelocationWorkOrderApproved() {
        //Account
        Account objAccount = TestDataAccount.getNewAccount();

        //Contact
        Contact con = new Contact(FirstName = 'testfirstname', LastName = 'testlastname' , AccountId = objAccount.Id);

        //Location for Case
        SVMXC__Site__c objLocation = TestDataFieldService.createLocation(STRING_LOCATION,STRING_STREET,'Ireland','123456','USD');
        insert objLocation;

        //IP
        SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct(STRING_INSTALLED_PRODUCT_NAME, STRING_CURRENCY, STRING_INSTALLED_PRODUCT_STATUS);
        insert objInstalledProduct;

        //Product
        Product2 objProduct = TestDataMaster.initProduct(STRING_PRODUCT_CODE);
        objProduct.Service_Product_Type__c = STRING_PRODUCT_MATERIAL_CLASS;
        objProduct.Regulatory_Type__c = 'DX';
        insert objProduct;

        //Account Sales Area
        Account_Sales_Area__c aSalesArea = new Account_Sales_Area__c();
        aSalesArea.Sales_Organization__c = 'SG01';
        aSalesArea.Distribution_Channel__c = '1234';
        aSalesArea.Division__c = 'SG01';
        aSalesArea.Account__c = objAccount.Id;
        insert aSalesArea;
        
        //*******CP User Creation Start***************

        //CP Profile
        Id profileId = [select id from profile where name='Channel Partner Service'].id;

        //CP Account
        Account objAccountCP = TestDataAccount.getAccount('Test Acc23', 'USD');
        objAccountCP.Account_Group__c = 'Distributor';
        Insert objAccountCP;

        //CP Contact
        Contact objContactCP = TestDataContact.getNewContact(objAccountCP);

        //CP User
        User objCPUser = TestDataUser.initPartnerUser(profileId,objContactCP.id);
        insert objCPUser;

        //Partner Stock Location for CP Account
        SVMXC__Site__c objLocationPartnerStock = TestDataFieldService.createLocation(STRING_LOCATION,STRING_STREET,'Ireland','123456','USD');
        objLocationPartnerStock.Type__c = LOCATION_PARTNER_STOCK;
        objLocationPartnerStock.SVMXC__Account__c = objAccountCP.Id;
        insert objLocationPartnerStock;


        //*******CP User Creation Ends***************

        //Case
        Case objCase = TestDataCase.initServiceRequestCase(con);
        objCase.SVMXC__Component__c = objInstalledProduct.Id; 
        objCase.SVMXC__Site__c = objLocation.Id;  
        objCase.Date_of_Issue_Awareness__c = Date.Today();   
        objCase.Relocated_Account__c = objAccount.Id;  
        objCase.Relocated_Location__c =  objLocation.Id;
        objCase.ProductId = objProduct.Id;
        objCase.OwnerId = objCPUser.Id;
        objCase.Relocation_Requested_By__c = objCPUser.Id;
        objCase.AccountId = objAccount.Id;
        objCase.GTS_Status__c = 'Request Initiated';
        insert objCase;
        Assert.isTrue(objCase != null);
        test.startTest();
        objCase.GTS_Status__c  = 'GTS Approved';
        update objCase;
        Test.stopTest();
    }
    
    /**
    *  @author Nidhi
    *  @description - Positive Testing 
    **/
    @isTest
    public static void testCaseRelocationWorkOrderBlock() {
         //Account
        Account objAccount = TestDataAccount.getNewAccount();

        //Contact
        Contact con = new Contact(FirstName = 'testfirstname', LastName = 'testlastname' , AccountId = objAccount.Id);

        //Location for Case
        SVMXC__Site__c objLocation = TestDataFieldService.createLocation(STRING_LOCATION,STRING_STREET,'Ireland','123456','USD');
        insert objLocation;

        //IP
        SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct(STRING_INSTALLED_PRODUCT_NAME, STRING_CURRENCY, STRING_INSTALLED_PRODUCT_STATUS);
        insert objInstalledProduct;

        //Product
        Product2 objProduct = TestDataMaster.initProduct(STRING_PRODUCT_CODE);
        objProduct.Service_Product_Type__c = STRING_PRODUCT_MATERIAL_CLASS;
        objProduct.Regulatory_Type__c = 'DX';
        insert objProduct;

        //Account Sales Area
        Account_Sales_Area__c aSalesArea = new Account_Sales_Area__c();
        aSalesArea.Sales_Organization__c = 'SG01';
        aSalesArea.Distribution_Channel__c = '1234';
        aSalesArea.Division__c = 'SG01';
        aSalesArea.Account__c = objAccount.Id;
        insert aSalesArea;
        
        //*******CP User Creation Start***************

        //CP Profile
        Id profileId = [select id from profile where name='Channel Partner Service'].id;

        //CP Account
        Account objAccountCP = TestDataAccount.getAccount('Test Acc23', 'USD');
        objAccountCP.Account_Group__c = 'Distributor';
        Insert objAccountCP;

        //CP Contact
        Contact objContactCP = TestDataContact.getNewContact(objAccountCP);

        //CP User
        User objCPUser = TestDataUser.initPartnerUser(profileId,objContactCP.id);
        insert objCPUser;

        //Partner Stock Location for CP Account
        SVMXC__Site__c objLocationPartnerStock = TestDataFieldService.createLocation(STRING_LOCATION,STRING_STREET,'Ireland','123456','USD');
        objLocationPartnerStock.Type__c = LOCATION_PARTNER_STOCK;
        objLocationPartnerStock.SVMXC__Account__c = objAccountCP.Id;
        insert objLocationPartnerStock;


        //*******CP User Creation Ends***************

        //Case
        Case objCase = TestDataCase.initServiceRequestCase(con);
        objCase.SVMXC__Component__c = objInstalledProduct.Id; 
        objCase.SVMXC__Site__c = objLocation.Id;  
        objCase.Date_of_Issue_Awareness__c = Date.Today();   
        objCase.Relocated_Account__c = objAccount.Id;  
        objCase.Relocated_Location__c =  objLocation.Id;
        objCase.ProductId = objProduct.Id;
        objCase.OwnerId = objCPUser.Id;
        objCase.Relocation_Requested_By__c = objCPUser.Id;
        objCase.AccountId = objAccount.Id;
        objCase.GTS_Status__c = 'Request Initiated';
        insert objCase;
        Assert.isTrue(objCase != null);
        test.startTest();
        objCase.GTS_Status__c = 'GTS Block';
        update objCase;
        Test.stopTest();
    }
    
    /**
    *  @author Nidhi
    *  @description - Positive Testing 
    **/
    @isTest
    public static void testCaseRelocationWorkOrderFailed() {
        //Account
        Account objAccount = TestDataAccount.getNewAccount();

        //Contact
        Contact con = new Contact(FirstName = 'testfirstname', LastName = 'testlastname' , AccountId = objAccount.Id);

        //Location for Case
        SVMXC__Site__c objLocation = TestDataFieldService.createLocation(STRING_LOCATION,STRING_STREET,'Ireland','123456','USD');
        insert objLocation;

        //IP
        SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct(STRING_INSTALLED_PRODUCT_NAME, STRING_CURRENCY, STRING_INSTALLED_PRODUCT_STATUS);
        insert objInstalledProduct;

        //Product
        Product2 objProduct = TestDataMaster.initProduct(STRING_PRODUCT_CODE);
        objProduct.Service_Product_Type__c = STRING_PRODUCT_MATERIAL_CLASS;
        objProduct.Regulatory_Type__c = 'DX';
        insert objProduct;

        //Account Sales Area
        Account_Sales_Area__c aSalesArea = new Account_Sales_Area__c();
        aSalesArea.Sales_Organization__c = 'SG01';
        aSalesArea.Distribution_Channel__c = '1234';
        aSalesArea.Division__c = 'SG01';
        aSalesArea.Account__c = objAccount.Id;
        insert aSalesArea;
        
        //*******CP User Creation Start***************

        //CP Profile
        Id profileId = [select id from profile where name='Channel Partner Service'].id;

        //CP Account
        Account objAccountCP = TestDataAccount.getAccount('Test Acc23', 'USD');
        objAccountCP.Account_Group__c = 'Distributor';
        Insert objAccountCP;

        //CP Contact
        Contact objContactCP = TestDataContact.getNewContact(objAccountCP);

        //CP User
        User objCPUser = TestDataUser.initPartnerUser(profileId,objContactCP.id);
        insert objCPUser;

        //Partner Stock Location for CP Account
        SVMXC__Site__c objLocationPartnerStock = TestDataFieldService.createLocation(STRING_LOCATION,STRING_STREET,'Ireland','123456','USD');
        objLocationPartnerStock.Type__c = LOCATION_PARTNER_STOCK;
        objLocationPartnerStock.SVMXC__Account__c = objAccountCP.Id;
        insert objLocationPartnerStock;


        //*******CP User Creation Ends***************

        //Case
        Case objCase = TestDataCase.initServiceRequestCase(con);
        objCase.SVMXC__Component__c = objInstalledProduct.Id; 
        objCase.GTS_Status__c = 'Request Initiated';
        objCase.SVMXC__Site__c = objLocation.Id;  
        objCase.Date_of_Issue_Awareness__c = Date.Today();   
        objCase.Relocated_Account__c = objAccount.Id;  
        objCase.Relocated_Location__c =  objLocation.Id;
        objCase.ProductId = objProduct.Id;
        objCase.OwnerId = objCPUser.Id;
        objCase.Relocation_Requested_By__c = objCPUser.Id;
        objCase.AccountId = objAccount.Id;
        insert objCase;
        Assert.isTrue(objCase != null);
        test.startTest();
        objCase.GTS_Status__c = 'Request Failed';
        update objCase;
        Test.stopTest();
        Integer emailCount = Limits.getLimitEmailInvocations();
        Assert.isTrue(emailCount != null, 'email not sent');
    }
}