/**
 *  @date  24-June-2024
 *  @description  BatchToUpdateAgreementsCreatedPriorToDG
 **/
@isTest
public class UpdateAgreementsCreatedPriorToDGTest {

        private static final String AMEA_USD_01 = '01-AMEA-USD'; //POL-57
    private static final String TEST_TXDR = 'Test TXDR';
    private static final String VC0013519_OPA = 'VC0013519-OPA';
    private static final String TXDR = 'TXDR';
    private static final String ERP_123456 = '123456';
    private static final String ERP_234567 = '234567';
    private static final String USD = 'USD';
    private static final String HK01 = 'HK01';
    private static final String AU01 = 'AU01';
    private static final String AGRMNT_NAME_PRI_GRP = 'Test Agreement - Price Group';
    private static final String PRIMARY_ACCOUNT = 'PrimaryAccount';
    private static final String AGREEMENT_NO_PRICE_GROUP = 'Test Agreement -  No Price Group';



    /**
     *  @author Saswati Prusty
     *  @description Test Data Setup
     **/
    @testSetup
    public static void setupData()
    {
        
        Account acc = TestDataAccount.initAccount();
        acc.ERP_Customer_Id__c = ERP_123456;
        acc.Clinical_Type__c = 'Clinical';
        acc.Territory_Region__c = 'AMR';
        acc.Account_Group__c = 'Distributor';
        acc.Name = ERP_123456;
        acc.BIllingCountryCode='HK';

        Account acc2 = TestDataAccount.initAccount();
        acc2.ERP_Customer_Id__c = ERP_234567;
        acc2.Clinical_Type__c = 'Clinical';
        acc2.BIllingCountryCode='HK' ;
        acc2.Name = ERP_234567;

        /*Start DCP-54438 Open Offer Agreements Account Setup*/
        Account primaryAcct = TestDataAccount.getCustomerAccount();
        primaryAcct.Clinical_Type__c = 'Clinical';
        primaryAcct.BIllingCountryCode='HK' ;
        primaryAcct.Name = PRIMARY_ACCOUNT;

        insert new List<Account> { acc, acc2, primaryAcct };

        Contact con = TestDataPerson.initContact(acc.Id);
        Contact con2 = TestDataPerson.initContact(acc.Id);
        insert new List<Contact> { con, con2 };

        Customer_Master_Data__c objCMD1 = new Customer_Master_Data__c(Name='CMD1',Country__c='Hong Kong',Country_Code__c='HK'),
                                objCMD2 = new Customer_Master_Data__c(Name='CMD2',Country__c='Hong Kong',Country_Code__c='HK');
        objCMD1.ERP_Customer_Id__c = ERP_123456;
        objCMD2.ERP_Customer_Id__c = ERP_234567;
        insert new List<Customer_Master_Data__c> {objCMD1, objCMD2};

        TestDataAgreement.addHierarchyPermission();

        Account_Sales_Area__c acc1SalesArea = TestDataAccountSalesArea.getAccountSalesArea(HK01, '01', '178', '00', false);
        acc1SalesArea.Account__c = acc.Id;
        acc1SalesArea.Price_List_Type__c = '06';
        acc1SalesArea.CurrencyIsoCode = USD;
        acc1SalesArea.Price_List__c = AMEA_USD_01;
        acc1SalesArea.Contract_Number__c = '123456_HK010100';
        acc1SalesArea.Price_Group__c = TXDR;
        acc1SalesArea.Sales_Organization__c=HK01;
        acc1SalesArea.Price_Group_Description__c=TEST_TXDR;
        acc1SalesArea.Distribution_Channel__c='01';

        Account_Sales_Area__c acc2SalesArea = TestDataAccountSalesArea.getAccountSalesArea(HK01, '02', '179', '00', false);
        acc2SalesArea.Account__c = acc2.Id;
        acc2SalesArea.Price_List_Type__c = '06';
        acc2SalesArea.CurrencyIsoCode = USD;
        acc2SalesArea.Price_List__c = AMEA_USD_01;
        acc2SalesArea.Contract_Number__c ='567890_US010100';
        acc2SalesArea.Price_Group__c = TXDR;
        acc2SalesArea.Sales_Organization__c=AU01;
        acc2SalesArea.Price_Group_Description__c=TEST_TXDR;
        acc2SalesArea.Distribution_Channel__c='01';

        Account_Sales_Area__c acc3SalesArea = TestDataAccountSalesArea.getAccountSalesArea(HK01, '02', '179', '00', false);
        acc3SalesArea.Account__c = acc2.Id;
        acc3SalesArea.Price_List_Type__c = '06';
        acc3SalesArea.CurrencyIsoCode = USD;
        acc3SalesArea.Price_List__c = AMEA_USD_01;
        acc3SalesArea.Contract_Number__c ='67890_HK010100';
        acc3SalesArea.Price_Group__c = TXDR;
        acc3SalesArea.Sales_Organization__c=HK01;
        acc3SalesArea.Price_Group_Description__c=TEST_TXDR;
        acc3SalesArea.Distribution_Channel__c='01';
        acc3SalesArea.ERP_Account_Sales_Area_Id__c='67890_HK010100';

        Account_Sales_Area__c acc4SalesArea = TestDataAccountSalesArea.getAccountSalesArea(HK01, '02', '178', '00', false);
        acc4SalesArea.Account__c = acc.Id;
        acc4SalesArea.Price_List_Type__c = '06';
        acc4SalesArea.CurrencyIsoCode = USD;
        acc4SalesArea.Price_List__c = '06-SGD-USD';
        acc4SalesArea.Contract_Number__c = '123456_HK010200';
        acc4SalesArea.ERP_Account_Sales_Area_Id__c = '123456_HK010200';
        acc4SalesArea.Price_Group__c = TXDR;
        acc4SalesArea.Sales_Organization__c=HK01;
        acc4SalesArea.Price_Group_Description__c=TEST_TXDR;
        acc4SalesArea.Distribution_Channel__c='02';

        Account_Sales_Area__c acc5SalesArea = TestDataAccountSalesArea.getAccountSalesArea(HK01, '01', '180', '00', false);
        acc5SalesArea.Account__c = primaryAcct.Id;
        acc5SalesArea.Price_List_Type__c = '06';
        acc5SalesArea.CurrencyIsoCode = USD;
        acc5SalesArea.Price_List__c = AMEA_USD_01; 
        acc5SalesArea.Contract_Number__c = '123456_HK010100';
        acc5SalesArea.Price_Group__c = TXDR;
        acc5SalesArea.Sales_Organization__c=HK01;
        acc5SalesArea.Price_Group_Description__c=TEST_TXDR;
        acc5SalesArea.Distribution_Channel__c='01';

        insert new List<Account_Sales_Area__c>{ acc1SalesArea, acc2SalesArea,acc3SalesArea,acc4SalesArea,acc5SalesArea };

        Product2 product = TestDataMaster.createProduct(false);
        product.Material_Number__c = VC0013519_OPA;
        Product2 productTwo = TestDataMaster.createProduct(false);
        productTwo.Material_Number__c = '11234187';
        Product2 productThree = TestDataMaster.createProduct(false);
        productThree.Material_Number__c = 'SV-111-1002';
        insert new List<Product2> { product, productTwo, productThree };
        Apttus_Config2__PriceList__c objPriceList = TestDataAgreement.initPriceList(AMEA_USD_01);
        Apttus_Config2__PriceList__c objPriceList2 = TestDataAgreement.initPriceList('06-SGD-USD');
        insert new List<Apttus_Config2__PriceList__c>{objPriceList, objPriceList2};
        
        Apttus_Config2__PriceListItem__c objPriceListItem = TestDataAgreement.initPriceListItem(product, objPriceList);
        Apttus_Config2__PriceListItem__c objPriceListItem2 = TestDataAgreement.initPriceListItem(product, objPriceList2);
        Apttus_Config2__PriceListItem__c objPriceListItem3 = TestDataAgreement.initPriceListItem(productTwo, objPriceList2);
        Apttus_Config2__PriceListItem__c objPriceListItem4 = TestDataAgreement.initPriceListItem(productThree, objPriceList2);
        insert new List<Apttus_Config2__PriceListItem__c>{objPriceListItem, objPriceListItem2,objPriceListItem3,objPriceListItem4};
        Id recTypeChannelPartner = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Channel Partner Agreement').getRecordTypeId();
        Id recTypeMasterAgreement = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Master Service Agreement').getRecordTypeId();

        

        createagreemrnts(acc, acc2, primaryAcct,recTypeChannelPartner,recTypeMasterAgreement);
    }

    /**
    * @Author Lovel
    * @description create line data
    **/
    public static void createagreemrnts(Account acc,Account acc2,Account primaryAcct, id recTypeChannelPartner,id recTypeMasterAgreement)
    {
        Apttus__APTS_Agreement__c oAgreement1 = TestDataAgreement.initAgreements(AGRMNT_NAME_PRI_GRP, acc.id);
        oAgreement1.Sales_Org__c =HK01;
        oAgreement1.RecordTypeId = recTypeChannelPartner;
        oAgreement1.Apttus__Auto_Renewal__c=True;
        oAgreement1.Apttus_Approval__Approval_Status__c = 'Pending Approval';

        Apttus__APTS_Agreement__c oAgreement2 = TestDataAgreement.initAgreements(AGREEMENT_NO_PRICE_GROUP, acc2.id);
        oAgreement2.RecordTypeId = recTypeMasterAgreement;
        oAgreement2.Apttus__Contract_Start_Date__c = system.today();
        oAgreement2.Apttus__Contract_End_Date__c = system.today() + 750;
        oAgreement2.Sales_Org__c = AU01;
        oAgreement2.Apttus_Approval__Approval_Status__c = 'Rejected';

        Apttus__APTS_Agreement__c oAgreement3 = TestDataAgreement.initAgreements('Test Agreement - Date Validation', acc.id);
        oAgreement3.Apttus__Contract_End_Date__c = system.today()+30;
        oAgreement3.Sales_Org__c = HK01;
        oAgreement3.RecordTypeId = recTypeChannelPartner;
        oAgreement3.Apttus_Approval__Approval_Status__c = 'Approval Required';

		insert new List<Apttus__APTS_Agreement__c> {oAgreement1,oAgreement2,oAgreement3};

        List<Approval_Hierarchy__c>lstApprovalHierarchy = new List<Approval_Hierarchy__c>();
        Approval_Hierarchy__c objDiscountApprovalHeirarchy = TestDataAgreement.initApprovalHierarchyStandingDiscount('CLM_Sales_Hierarchy', acc.OwnerId);
        lstApprovalHierarchy.add(objDiscountApprovalHeirarchy);

        Approval_Hierarchy__c objCustomApprovalHeirarchy = TestDataAgreement.initApprovalHierarchyStandingDiscount('CLM_Custom_Hierarchy', acc.OwnerId);
        lstApprovalHierarchy.add(objCustomApprovalHeirarchy);
        insert lstApprovalHierarchy;

        List<Custom_Approval_Matrix__c> lstMatrix = new List<Custom_Approval_Matrix__c>();
        Custom_Approval_Matrix__c standingDiscountApprovalMatrix = TestDataAgreement.initApprovalMatrixForAgreement('CLM Discount', 10 , null, null,objCustomApprovalHeirarchy.id);

        standingDiscountApprovalMatrix.Distribution_Channel__c = '';
        standingDiscountApprovalMatrix.Currency__c = ''; 
        standingDiscountApprovalMatrix.region__c = ''; 
        standingDiscountApprovalMatrix.Sales_Organization__c = '';
        lstMatrix.add(standingDiscountApprovalMatrix);
        insert lstMatrix; 

        List<Apttus__AgreementLineItem__c> lstALI = new list<Apttus__AgreementLineItem__c>();
        Apttus__AgreementLineItem__c oAgreementLI1 = TestDataAgreement.initAgreementsLineItem(oAgreement1.id);
        oAgreementLI1.Material_Number__c = VC0013519_OPA;
        oAgreementLI1.Material_Group_1__c = 'BGS';
        oAgreementLI1.Line_Type__c = 'Material';
        oAgreementLI1.Apttus_CMConfig__LineNumber__c = 4;
        oAgreementLI1.Apttus_CMConfig__ItemSequence__c = 4;
        oAgreementLI1.Discount_Type__c = '% Discount';
        oAgreementLI1.Discount__c = 15;
        oAgreementLI1.Customer_ERP_Number__c = ERP_123456;
        oAgreementLI1.Sales_Org__c = HK01;
        oAgreementLI1.Distribution_Channel__c = '02';
        oAgreementLI1.CurrencyIsoCode= USD;
        oAgreementLI1.Apttus_CMConfig__StartDate__c = system.today()+1;
        oAgreementLI1.Apttus_CMConfig__EndDate__c = system.today()+2;
        lstALI.add(oAgreementLI1);

        Apttus__AgreementLineItem__c oAgreementLI2 = TestDataAgreement.initAgreementsLineItem(oAgreement1.id);
        oAgreementLI2.Material_Number__c = VC0013519_OPA;
        oAgreementLI2.Material_Group_1__c = 'BGS';
        oAgreementLI2.Line_Type__c = 'Material';
        oAgreementLI2.Apttus_CMConfig__LineNumber__c = 4;
        oAgreementLI2.Apttus_CMConfig__ItemSequence__c = 4;
        oAgreementLI2.Discount_Type__c = '% Discount';
        oAgreementLI2.Discount__c = 15;
        oAgreementLI2.Customer_ERP_Number__c = ERP_123456;
        oAgreementLI2.Sales_Org__c = HK01;
        oAgreementLI2.Distribution_Channel__c = '02';
        oAgreementLI2.CurrencyIsoCode= USD;
        oAgreementLI2.Apttus_CMConfig__StartDate__c = system.today()+1;
        oAgreementLI2.Apttus_CMConfig__EndDate__c = system.today()+2;
        
        lstALI.add(oAgreementLI2);
        Apttus__AgreementLineItem__c oAgreementLI3 = TestDataAgreement.initAgreementsLineItem(oAgreement1.id);
        oAgreementLI3.Material_Number__c = VC0013519_OPA;
        oAgreementLI3.Material_Group_1__c = 'BGS';
        oAgreementLI3.Line_Type__c = 'Material';
        oAgreementLI3.Apttus_CMConfig__LineNumber__c = 4;
        oAgreementLI3.Apttus_CMConfig__ItemSequence__c = 4;
        oAgreementLI3.Discount_Type__c = '% Discount';
        oAgreementLI3.Discount__c = 15;
        oAgreementLI3.Customer_ERP_Number__c = ERP_123456;
        oAgreementLI3.Sales_Org__c = HK01;
        oAgreementLI3.Distribution_Channel__c = '02';
        oAgreementLI3.CurrencyIsoCode= USD;
        oAgreementLI3.Apttus_CMConfig__StartDate__c = system.today()+1;
        oAgreementLI3.Apttus_CMConfig__EndDate__c = system.today()+2;
        oAgreementLI3.Apttus_Approval__Approval_Status__c = ApttusAgreements.APPROVAL_STATUS_APPROVAL_REQUIRED;
        lstALI.add(oAgreementLI3);

        insert lstALI;
    }

    /**
    * @Author Gopinath Reddyys
    * @description Test method for Approvals
    **/
   @isTest
    public static void method1(){
        // Query the IDs of the test agreements to use them dynamically
        List<Apttus__APTS_Agreement__c> queriedAgreements = [
            SELECT Id, Apttus__Status_Category__c, Apttus_Approval__Approval_Status__c
            FROM Apttus__APTS_Agreement__c LIMIT 100 ];
        Set<Id> companyNameList = new Set<Id>();
        for (Apttus__APTS_Agreement__c agreement : queriedAgreements) {
            companyNameList.add(agreement.Id);
        }
    // Set up the test context
        Test.startTest();
        
            BatchToUpdateAgreementsCreatedPriorToDG.useOldFrameworkWhileTesting = true;
            
            // Instantiate the batch class
            BatchToUpdateAgreementsCreatedPriorToDG batch = new BatchToUpdateAgreementsCreatedPriorToDG();
            BatchToUpdateAgreementsCreatedPriorToDG batch1 = new BatchToUpdateAgreementsCreatedPriorToDG(new set<id>{queriedAgreements[0].Id});
            // Execute the batch
           Database.executeBatch(batch,1);
            Database.executeBatch(batch1,1);
            Database.executeBatch(new BatchToUpdateLargeAgmntLineItems(companyNameList),200);
            
       // }
          // Finish the test context
        Test.stopTest();

        // Validate the resultsQuery the updated agreements
        List<Apttus__APTS_Agreement__c> updatedAgreements = [
            SELECT Id, Apttus__Status_Category__c, Apttus_Approval__Approval_Status__c
            FROM Apttus__APTS_Agreement__c
            WHERE Id IN :companyNameList
        ];
                // Validate the agreement status
        for (Apttus__APTS_Agreement__c agreement : updatedAgreements) {
            if (agreement.Apttus__Status_Category__c == 'Request') {
                System.assertEquals('Request', agreement.Apttus__Status_Category__c, 'The status category should be Request');
            } else if (agreement.Apttus__Status_Category__c == 'In Authoring') {
                System.assertEquals('In Authoring', agreement.Apttus__Status_Category__c, 'The status category should be In Authoring');
            }
        }
         // Validate the line items
        List<Apttus__AgreementLineItem__c> updatedLineItems = 
        [
            SELECT Id, Apttus_CMConfig__LineStatus__c, Discount_Guidance__c
            FROM Apttus__AgreementLineItem__c
            WHERE Apttus__AgreementId__c IN :companyNameList];

        for (Apttus__AgreementLineItem__c lineItem : updatedLineItems) 
         {
            System.assertEquals('New', lineItem.Apttus_CMConfig__LineStatus__c, 'The line status should be New');
            System.assertEquals(null, lineItem.Discount_Guidance__c, 'The discount guidance should not be populated');
        }

    }   
}