/*
*    @author Saswati Prusty
*    @date   2019-10-20
*    @description   DCP-32046 AgreementClauses test classes
*    Modification Log:
*    ------------------------------------------------------------------------------
*        Developer                      Date                Description
*     Saswati Prusty                6th March 2019          Initial Version
*     Adyasha Satapathy             24-Nov-2022             POL-54: Update region References to AMEA and EUR 
*    ------------------------------------------------------------------------------
**/
@isTest(SeeAllData=false isParallel=false)
public with sharing class TestAgreementClauses{
    @testSetup
    static void setupData()
    { 
        Account acc = TestDataAccount.initAccount();
        acc.ERP_Customer_Id__c = '123456';
        acc.Territory_Region__c = 'AMR';
        acc.Account_Group__c = 'Distributor';
        Account acc2 = TestDataAccount.initAccount();
        acc2.ERP_Customer_Id__c = '234567';  
        acc2.Territory_Region__c = 'AMR';      
        insert new List<Account> { acc, acc2 };
        Contact con = TestDataPerson.initContact(acc.Id);
        Contact con2 = TestDataPerson.initContact(acc.Id);
        insert new List<Contact> { con, con2 };
        
        Customer_Master_Data__c objCMD1 = new Customer_Master_Data__c(Name='CMD1',Country__c='Hong Kong',Country_Code__c='HK'),
                                objCMD2 = new Customer_Master_Data__c(Name='CMD2',Country__c='Hong Kong',Country_Code__c='HK');
        objCMD1.ERP_Customer_Id__c = '123456';
        objCMD2.ERP_Customer_Id__c = '234567';
        insert new List<Customer_Master_Data__c> {objCMD1, objCMD2};

        Product2 product = TestDataMaster.createProduct(false);
        product.Material_Number__c = 'VC0013519-OPA';
        Product2 productTwo = TestDataMaster.createProduct(false);
        productTwo.Material_Number__c = '11234187';
        Product2 productThree = TestDataMaster.createProduct(false);
        productThree.Material_Number__c = 'SV-111-1002';
        insert new List<Product2> { product, productTwo, productThree };
        
        CLM_ProfileValidation__c profilevalidation = new CLM_ProfileValidation__c(SetupOwnerId=userinfo.getProfileId(),Channel_Partner_Agreement__c=true,Master_Customer_Agreement__c=true,Master_Service_Agreement__c=true,Negotiated_Terms_and_Conditions__c=true,Standing_Quote__c=true,Tender__c=true);
        insert profilevalidation;
        Account_Sales_Area__c acc1SalesArea = TestDataAccountSalesArea.getAccountSalesArea('HK01', '01', '178', '00', false);
        acc1SalesArea.Account__c = acc.Id;
        acc1SalesArea.Price_List_Type__c = '06';
        acc1SalesArea.CurrencyIsoCode = 'USD';
        acc1SalesArea.Price_List__c = '01-AMEA-USD';//POL-54
        acc1SalesArea.Contract_Number__c = '123456_HK010100';
        acc1SalesArea.ERP_Account_Sales_Area_Id__c = '123456_HK010100';
        acc1SalesArea.Price_Group__c = 'TXDR';
        Account_Sales_Area__c acc2SalesArea = TestDataAccountSalesArea.getAccountSalesArea('HK01', '02', '179', '00', false);
        acc2SalesArea.Account__c = acc2.Id;
        acc2SalesArea.Price_List_Type__c = '06';
        acc2SalesArea.CurrencyIsoCode = 'USD';
        acc2SalesArea.Price_List__c = '01-AMEA-USD';//POL-54
        acc2SalesArea.Contract_Number__c ='567890_US010100';
        insert new List<Account_Sales_Area__c>{ acc1SalesArea, acc2SalesArea };

        System.debug('Total Number of SOQL Queries allowed in this apex code context: ' + Limits.getLimitQueries());
        System.debug('Number of Queries used in this apex code so far: ' + Limits.getQueries());
        
         Id recTypeId2 = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Master Customer Agreement').getRecordTypeId();
        Apttus__APTS_Agreement__c oAgreement2 = TestDataAgreement.initAgreements('Test Agreement - Price Group', acc2.id);
        oAgreement2.RecordTypeId = recTypeId2;
        //oAgreement2.Customer_Discount_Level__c = 'Price Group';
        insert oAgreement2;
        
       
        Custom_Approval_Matrix__c clauseApprovalMatrix = TestDataAgreement.initClauseApprovalMatrix('Clause Approval', 'AMR Admin Queue','Master Customer Agreement');
        insert clauseApprovalMatrix;
        
        Apttus__Agreement_Clause__c objAgreementClause = TestDataAgreement.initAgreementClauses(oAgreement2.id,'SQ - AMR-Standard Tax-English');
        insert objAgreementClause;
    }
    
    @isTest
    static void testApprovalClausesOnUpdate(){
        Apttus__Agreement_Clause__c objAgreementClause = [Select Id,Approval_Status__c FROM Apttus__Agreement_Clause__c WHERE Apttus__Clause__c='SQ - AMR-Standard Tax-English' LIMIT 1 ];
        objAgreementClause.Apttus__Action__c='Modified';
        update objAgreementClause;

        system.assert(objAgreementClause.Approval_Status__c.contains('Approval Required'),'Clause approvals did not fire.');
    }
         
 }