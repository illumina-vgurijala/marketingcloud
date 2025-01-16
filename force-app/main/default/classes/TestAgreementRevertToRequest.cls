/*
    * @author      : Umesh Mor
    * @date        : 6-03-2020.
    * @description : This class provides coverage for class - AgreementRevertToRequest
    * Parameter    : AgreementId
    * @return      : String 
*    ------------------------------------------
*    Developer Name                    Date                Description
*    Umesh Mor                        6th March 2022        Initial Version
*    Aman Tyagi                       7th Oct 2022         Code scan fixes
*    Arif,Dalali                      28-Nov-2022          POL-57: Update APJ and EMEA References to AMEA and Europe respectively
*    Saddam                           08-Dec-2022             Codescan Fix , Varaible naming convention. 
*    ---------------------------------------------------------------------------------                    
**/

@isTest(SeeAllData=false isParallel=false)
public with sharing class TestAgreementRevertToRequest {
  
    Public final static String PRICELIST_01_AMEA_USD = '01-AMEA-USD'; //POL-57
    public static final String TEST_TXDR = 'Test TXDR';
    public static final String AUTHOR_CONTRACT = 'Author Contract';
    public static final String APPROVAL_REQUIRED = 'Approval Required';
    public static final String  IN_EFFECT = 'In Effect';
    public static final String BEING_AMENDED = 'Being Amended';
    public static final String TEST_REXC = 'Test Rexc';
    
    @testSetup
    static void setupData(){
        Account acc = TestDataAccount.initAccount();
        acc.ERP_Customer_Id__c = '123456';
        acc.Territory_Region__c = 'AMR';
        acc.Account_Group__c = 'Distributor';
        acc.Name = 'distributor Account';
        acc.BIllingCountryCode='HK';
        Account acc2 = TestDataAccount.initAccount();
        acc2.ERP_Customer_Id__c = '234567';  
        acc2.BIllingCountryCode='HK' ;     
        insert new List<Account> { acc, acc2 };
        Contact con = TestDataPerson.initContact(acc.Id);
        Contact con2 = TestDataPerson.initContact(acc.Id);
        insert new List<Contact> { con, con2 };
        
        Customer_Master_Data__c objCMD1 = new Customer_Master_Data__c(Name='CMD1',Country__c='Hong Kong',Country_Code__c='HK'),
                                objCMD2 = new Customer_Master_Data__c(Name='CMD2',Country__c='Hong Kong',Country_Code__c='HK');
        objCMD1.ERP_Customer_Id__c = '123456';
        objCMD2.ERP_Customer_Id__c = '234567';
        insert new List<Customer_Master_Data__c> {objCMD1, objCMD2};
        
        CLM_ProfileValidation__c profilevalidation = new CLM_ProfileValidation__c(SetupOwnerId=userinfo.getProfileId(),Channel_Partner_Agreement__c=true,Master_Customer_Agreement__c=true,Master_Service_Agreement__c=true,Negotiated_Terms_and_Conditions__c=true,Standing_Quote__c=true,Tender__c=true);
        insert profilevalidation;
        
        Account_Sales_Area__c acc1SalesArea = TestDataAccountSalesArea.getAccountSalesArea('HK01', '01', '178', '00', false);
        acc1SalesArea.Account__c = acc.Id;
        acc1SalesArea.Price_List_Type__c = '06';
        acc1SalesArea.CurrencyIsoCode = 'USD';
        acc1SalesArea.Price_List__c = PRICELIST_01_AMEA_USD; //POL-57
        acc1SalesArea.Contract_Number__c = '123456_HK010100';
        acc1SalesArea.Price_Group__c = 'TXDR';        
        acc1SalesArea.Sales_Organization__c='HK01';
        acc1SalesArea.Price_Group_Description__c=TEST_TXDR;
        acc1SalesArea.Distribution_Channel__c='01';
        
        Account_Sales_Area__c acc2SalesArea = TestDataAccountSalesArea.getAccountSalesArea('HK01', '02', '179', '00', false);
        acc2SalesArea.Account__c = acc2.Id;
        acc2SalesArea.Price_List_Type__c = '06';
        acc2SalesArea.CurrencyIsoCode = 'USD';
        acc2SalesArea.Price_List__c = PRICELIST_01_AMEA_USD; //POL-57
        acc2SalesArea.Contract_Number__c ='567890_US010100';
        acc2SalesArea.Price_Group__c = 'TXDR';
        acc2SalesArea.Sales_Organization__c='AU01';
        acc2SalesArea.Price_Group_Description__c=TEST_TXDR;
        acc2SalesArea.Distribution_Channel__c='01';

        Account_Sales_Area__c acc3SalesArea = TestDataAccountSalesArea.getAccountSalesArea('HK01', '02', '179', '00', false);
        acc3SalesArea.Account__c = acc2.Id;
        acc3SalesArea.Price_List_Type__c = '06';
        acc3SalesArea.CurrencyIsoCode = 'USD'; 
        acc3SalesArea.Price_List__c = PRICELIST_01_AMEA_USD;  //POL-57
        acc3SalesArea.Contract_Number__c ='67890_HK010100';
        acc3SalesArea.Price_Group__c = 'TXDR';
        acc3SalesArea.Sales_Organization__c='HK01';
        acc3SalesArea.Price_Group_Description__c=TEST_TXDR;
        acc3SalesArea.Distribution_Channel__c='01';
        acc3SalesArea.ERP_Account_Sales_Area_Id__c='67890_HK010100';

        insert new List<Account_Sales_Area__c>{ acc1SalesArea, acc2SalesArea,acc3SalesArea  };

        Product2 product = TestDataMaster.createProduct(false);
        product.Material_Number__c = 'VC0013519-OPA';
        Product2 productTwo = TestDataMaster.createProduct(false);
        productTwo.Material_Number__c = '11234187';
        Product2 productThree = TestDataMaster.createProduct(false);
        productThree.Material_Number__c = 'SV-111-1002';
        insert new List<Product2> { product, productTwo, productThree };
       

        Id recTypeId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Channel Partner Agreement').getRecordTypeId();
        Id recTypeId2 = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Master Service Agreement').getRecordTypeId();


        Apttus__APTS_Agreement__c oAgreement1 = TestDataAgreement.initAgreements('Test Agreement - One', acc.id);
        //oAgreement1.Customer_Discount_Level__c = 'Price Group';
        oAgreement1.Sales_Org__c ='HK01';//adding reference sales org
        oAgreement1.RecordTypeId = recTypeId;
        oAgreement1.Apttus__Auto_Renewal__c=True;
        oAgreement1.Apttus__Status_Category__c ='In Authoring';
        oAgreement1.Apttus__Status__c = AUTHOR_CONTRACT;
        oAgreement1.Apttus_Approval__Approval_Status__c =APPROVAL_REQUIRED;
        oAgreement1.Validation_Status__c ='None';
        insert oAgreement1;
        
        Apttus__APTS_Agreement__c oAgreement2 = TestDataAgreement.initAgreements('Test Agreement - Two', acc2.id);
        oAgreement2.RecordTypeId = recTypeId2 ;
        oAgreement2.Apttus__Contract_Start_Date__c = system.today();
        oAgreement2.Apttus__Contract_End_Date__c = system.today() + 750;
        oAgreement2.Sales_Org__c = 'AU01'; //DCP-33757 //adding reference sales org
        oAgreement1.Apttus__Status_Category__c =IN_EFFECT;
        oAgreement1.Apttus__Status__c = BEING_AMENDED;
        oAgreement1.Apttus_Approval__Approval_Status__c =APPROVAL_REQUIRED;
        oAgreement1.Validation_Status__c ='None';
        insert oAgreement2;  
          
        Apttus__APTS_Agreement__c oAgreement3 = TestDataAgreement.initAgreements('Test Agreement - Three', acc.id);
        oAgreement3.Apttus__Contract_End_Date__c = system.today()+30;
        oAgreement3.Sales_Org__c = 'HK01';//adding reference sales org
        oAgreement3.RecordTypeId = recTypeId;
        //oAgreement3.Customer_Discount_Level__c = 'Price Group';   
        oAgreement3.Apttus__Status_Category__c =IN_EFFECT;
        oAgreement3.Apttus__Status__c ='Request';
        oAgreement3.Apttus_Approval__Approval_Status__c =APPROVAL_REQUIRED;
        oAgreement3.Validation_Status__c ='None'; 
        insert oAgreement3;
        
        Apttus__APTS_Agreement__c oAgreement4 = TestDataAgreement.initAgreements('Test Agreement - Four', acc.id);
        oAgreement4.Apttus__Contract_End_Date__c = system.today()+30;
        oAgreement4.Sales_Org__c = 'HK01';//adding reference sales org
        oAgreement4.RecordTypeId = recTypeId;
        //oAgreement3.Customer_Discount_Level__c = 'Price Group';   
        oAgreement4.Apttus__Status_Category__c =IN_EFFECT;
        oAgreement4.Apttus__Status__c ='Request';
        oAgreement4.Apttus_Approval__Approval_Status__c ='Pending Approval';
        oAgreement4.Validation_Status__c ='IN PROGRESS'; 
        insert oAgreement4 ;
        
        System.debug('Total Number of SOQL Queries allowed in this apex code context: ' + Limits.getLimitQueries());
        System.debug('Number of Queries used in this apex code so far: ' + Limits.getQueries());
     } 

     /**
     * @author   
     * @description static method to test the reverse functionality ,method1
     * @param NA
     * @return NA
     **/
     public static testMethod void testRevertFunctionalityMethodOne(){
         List<Apttus__APTS_Agreement__c > lstAgrment = [Select Id,Apttus__Status_Category__c ,Apttus__Status__c ,Apttus_Approval__Approval_Status__c ,Validation_Status__c  from Apttus__APTS_Agreement__c where Name='Test Agreement - One'];
         String str;
         Test.StartTest();
             str = AgreementRevertToRequest.agreementRevertToRequest(lstAgrment[0].Id);
         Test.StopTest();
         System.assert(str.contains('Success'), true);
        
     }

     /**
     * @author   
     * @description static method to test the reverse functionality ,method 2
     * @param NA
     * @return NA
     **/
     public static testMethod void testRevertFunctionalityMethodTwo(){
         Apttus__APTS_Related_Agreement__c obj = new Apttus__APTS_Related_Agreement__c();
         List<Apttus__APTS_Agreement__c > lstAgrment = [Select Id,Name,Apttus__Status_Category__c ,Apttus__Status__c ,Apttus_Approval__Approval_Status__c ,Validation_Status__c  from Apttus__APTS_Agreement__c where Name='Test Agreement - One'];
         List<Apttus__APTS_Agreement__c > lstAgrment1 = [Select Id,Name,Apttus__Status_Category__c ,Apttus__Status__c ,Apttus_Approval__Approval_Status__c ,Validation_Status__c  from Apttus__APTS_Agreement__c where Name='Test Agreement - Two'];
         lstAgrment1[0].Apttus__Status__c = BEING_AMENDED;
         update lstAgrment1;
         
         System.debug('The From Agreement is---->'+lstAgrment[0]);
         System.debug('The Two Agreement is---->'+lstAgrment1[0]);
         
         obj.Apttus__APTS_Contract_From__c =  lstAgrment[0].Id;
         obj.Apttus__APTS_Contract_To__c = lstAgrment1[0].Id;
         obj.Name=TEST_REXC;
         insert Obj;
         String str;
         Test.StartTest();
             str  = AgreementRevertToRequest.agreementRevertToRequest(lstAgrment[0].Id);
         Test.StopTest();
         System.assert(str.contains('Success'), true);
     }
    
     /**
     * @author   
     * @description static method to test the reverse functionality ,method3
     * @param NA
     * @return NA
     **/
     public static testMethod void testRevertFunctionalityMethodThree(){
         Apttus__APTS_Related_Agreement__c obj = new Apttus__APTS_Related_Agreement__c();
         List<Apttus__APTS_Agreement__c > lstAgrment = [Select Id,Name,Apttus__Status_Category__c ,Apttus__Status__c ,Apttus_Approval__Approval_Status__c ,Validation_Status__c  from Apttus__APTS_Agreement__c where Name='Test Agreement - One'];
         List<Apttus__APTS_Agreement__c > lstAgrment1 = [Select Id,Name,Apttus__Status_Category__c ,Apttus__Status__c ,Apttus_Approval__Approval_Status__c ,Validation_Status__c  from Apttus__APTS_Agreement__c where Name='Test Agreement - Two'];
         lstAgrment1[0].Apttus__Status__c = 'Being Renewed';
         update lstAgrment1;
         
         System.debug('The From Agreement is---->'+lstAgrment[0]);
         System.debug('The Two Agreement is---->'+lstAgrment1[0]);
         
         obj.Apttus__APTS_Contract_From__c =  lstAgrment[0].Id;
         obj.Apttus__APTS_Contract_To__c = lstAgrment1[0].Id;
         obj.Name=TEST_REXC;
         insert Obj;
         String str; 
         Test.StartTest();
             str = AgreementRevertToRequest.agreementRevertToRequest(lstAgrment[0].Id);
         Test.StopTest();
         System.assert(str.contains('Success'), true);
     }

     /**
     * @author   
     * @description static method to test the reverse functionality ,method4
     * @param NA
     * @return NA
     **/
     public static testMethod void testRevertFunctionalityMethodFour(){
         Apttus__APTS_Related_Agreement__c obj = new Apttus__APTS_Related_Agreement__c();
         List<Apttus__APTS_Agreement__c > lstAgrment = [Select Id,Name,Apttus__Status_Category__c ,Apttus__Status__c ,Apttus_Approval__Approval_Status__c ,Validation_Status__c  from Apttus__APTS_Agreement__c where Name='Test Agreement - One'];
         List<Apttus__APTS_Agreement__c > lstAgrment1 = [Select Id,Name,Apttus__Status_Category__c ,Apttus__Status__c ,Apttus_Approval__Approval_Status__c ,Validation_Status__c  from Apttus__APTS_Agreement__c where Name='Test Agreement - Two'];
          
         lstAgrment[0].Apttus__Status__c = BEING_AMENDED;
         update lstAgrment;
         
         lstAgrment1[0].Apttus__Status__c = AUTHOR_CONTRACT;
         update lstAgrment1;
         
         System.debug('The From Agreement is---->'+lstAgrment[0]);
         System.debug('The Two Agreement is---->'+lstAgrment1[0]);
         
         obj.Apttus__APTS_Contract_From__c =  lstAgrment[0].Id;
         obj.Apttus__APTS_Contract_To__c = lstAgrment1[0].Id;
         obj.Name=TEST_REXC;
         insert Obj;
         String str; 
         Test.StartTest();
             str= AgreementRevertToRequest.agreementRevertToRequest(lstAgrment1[0].Id);
         Test.StopTest();
         System.assert(str.contains('Success'), true);
     }
     /**
     * @author   
     * @description static method to test the reverse functionality ,method5
     * @param NA
     * @return NA
     **/
     public static testMethod void testRevertFunctionalityMethodFive(){
         Apttus__APTS_Related_Agreement__c obj = new Apttus__APTS_Related_Agreement__c();
         List<Apttus__APTS_Agreement__c > lstAgrment = [Select Id,Name,Apttus__Status_Category__c ,Apttus__Status__c ,Apttus_Approval__Approval_Status__c ,Validation_Status__c  from Apttus__APTS_Agreement__c where Name='Test Agreement - One'];
         List<Apttus__APTS_Agreement__c > lstAgrment1 = [Select Id,Name,Apttus__Status_Category__c ,Apttus__Status__c ,Apttus_Approval__Approval_Status__c ,Validation_Status__c  from Apttus__APTS_Agreement__c where Name='Test Agreement - Two'];
          
         lstAgrment[0].Apttus__Status__c = 'Being Renewed';
         update lstAgrment;
         
         lstAgrment1[0].Apttus__Status__c = AUTHOR_CONTRACT;
         update lstAgrment1;
         
         System.debug('The From Agreement is---->'+lstAgrment[0]);
         System.debug('The Two Agreement is---->'+lstAgrment1[0]);
         
         obj.Apttus__APTS_Contract_From__c =  lstAgrment[0].Id;
         obj.Apttus__APTS_Contract_To__c = lstAgrment1[0].Id;
         obj.Name=TEST_REXC;
         insert Obj;
         String str; 
         Test.StartTest();
             str= AgreementRevertToRequest.agreementRevertToRequest(lstAgrment1[0].Id);
         Test.StopTest();
         System.assert(str.contains('Success'), true);
     }

     /**
     * @author   
     * @description static method to test the reverse functionality ,method6
     * @param NA
     * @return NA
     **/
     public static testMethod void testRevertFunctionalityMethodSix(){
         List<Apttus__APTS_Agreement__c > lstAgrment = [Select Id,Apttus__Status_Category__c ,Apttus__Status__c ,Apttus_Approval__Approval_Status__c ,Validation_Status__c  from Apttus__APTS_Agreement__c where Name='Test Agreement - Three'];
         String str;
         Test.StartTest();
             str = AgreementRevertToRequest.agreementRevertToRequest(lstAgrment[0].Id);
         Test.StopTest();
         System.assert(str.contains('Error'), true);
     }

     /**
     * @author   
     * @description static method to test the reverse functionality ,method7
     * @param NA
     * @return NA
     **/
     public static testMethod void testRevertFunctionalityMethodSeven(){
         List<Apttus__APTS_Agreement__c > lstAgrment = [Select Id,Apttus__Status_Category__c ,Apttus__Status__c ,Apttus_Approval__Approval_Status__c ,Validation_Status__c  from Apttus__APTS_Agreement__c where Name='Test Agreement - Four'];
         lstAgrment[0].Validation_Status__c = 'In Progress';
         update lstAgrment;
         String str;
         Test.StartTest();
             str = AgreementRevertToRequest.agreementRevertToRequest(lstAgrment[0].Id);
         Test.StopTest();
         System.assert(str.contains('Error'), true);
     }
}