/**
*    @author Saurabh Brahmankar
*    @date   2023-10-23
*    @description  Opportunities.cls agreement tests.
*    Modification Log:
*    -----------------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*			  Saurabh Brahmankar		  18-Oct-2023			 Update the TestOpportunity class from improvements
*             Gerardo Garcia              01-Jan-2024            CMCM-4368 Refactor testClass
*    ----------------------------------------------------------------------------------------------------------------------------------------------
*/
@isTest
public class TestOpportunitiesAgreement {

    private static final String CURRENT_QUARTER = 'Current Quarter';
    private static final String STRING_FINALIZE = 'finalize';
    private static final Id OPPRECTYPEID = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Standing Quote').getRecordTypeId();

    @testSetup
    static void initializeTestData()
    {
        createAgreementData();
    }

    private static Account getAccount(String name) {
        return [SELECT ID, Name, ERP_Customer_Id__c, BIllingCountryCode, CurrencyIsoCode 
        FROM Account WHERE Name = :name LIMIT 1];
    }

    private static Apttus__APTS_Agreement__c getAgreement() {
        return [SELECT id, name FROM Apttus__APTS_Agreement__c WHERE name = 'Test Agreement - Price Group000' LIMIT 1];
    }
    
	/**
     * @author Tapas
     * @date   18 Sep 2020
     * @description this method is called in checkStandingQuoteOpp1, cloneStandingQuoteOpp and checkCurrencyUpdateOnSQOPs methods
   **/
    private static void createAgreementData(){
        TestDataAgreement.addHierarchyPermission();
        
        Account acc1 = TestDataAccount.initAccount();
        acc1.Name = 'Test Opp Agreement 1';
        acc1.ERP_Customer_Id__c = '2345671202';
        acc1.BIllingCountryCode='HK' ;
        acc1.CurrencyIsoCode = 'HKD';
        insert acc1;
        
        Account_Sales_Area__c acc1SalesArea = TestDataAccountSalesArea.getAccountSalesArea('HK01', '01', '178', '00', false);
        acc1SalesArea.Account__c = acc1.Id;
        acc1SalesArea.Price_List_Type__c = '06';
        acc1SalesArea.CurrencyIsoCode = 'USD';
        acc1SalesArea.Price_List__c = '01-AMEA-USD'; //POL-54
        acc1SalesArea.Contract_Number__c = '123456_HK010100';
        acc1SalesArea.Price_Group__c = 'TXDR';
        acc1SalesArea.Sales_Organization__c='HK01';
        acc1SalesArea.Price_Group_Description__c='Test TXDR';
        acc1SalesArea.Distribution_Channel__c='01';
        insert acc1SalesArea;
        
        Apttus__APTS_Agreement__c oAgreement1 = TestDataAgreement.initAgreements('Test Agreement - Price Group000', acc1.id);
        oAgreement1.Sales_Org__c ='HK01';//adding reference sales org
        oAgreement1.Apttus__Auto_Renewal__c=True;
		oAgreement1.Apttus__Total_Contract_Value__c = 100;
        oAgreement1.Freight_Charge__c = 'Non-standard';
        oAgreement1.Reason_for_Non_Standard_Freight__c = 'TestData';
        
        insert oAgreement1;

        Account acc2 = TestDataAccount.initAccount();
      	acc2.Name = 'Test Opp Agreement 2';
        acc2.ERP_Customer_Id__c = '23444441202';
        acc2.BIllingCountryCode='HK' ;
        acc2.CurrencyIsoCode = 'USD';
        insert acc2;
    } 

    /**
     * @author Tapas
     * @date   18 Sep 2020
     * @description    DCP-40569 test for updatecurrencyOnSQOppProds method
    **/
    @isTest
    private static void checkStandingQuoteErrorStandingOppSameQuarter(){
        String sameQuarterError = '';
        
        Account acc1 = getAccount('Test Opp Agreement 1');
        Apttus__APTS_Agreement__c oAgreement1 = getAgreement();
        System.debug('checkStandingQuoteOpp1 '+ acc1 + oAgreement1);

        Opportunity oppA = new Opportunity();
        oppA.Related_Agreement__c = oAgreement1.Id;
        oppA.Fiscal_Quarter__c = CURRENT_QUARTER;
        oppA.CloseDate = Date.newinstance(Date.Today().Year() + 1, 3, 31);
        oppA.Name = 'Test Dummy';
        oppA.AccountId = acc1.Id;
        oppA.StageName = STRING_FINALIZE;
        oppA.recordTypeId = OPPRECTYPEID;
        
        insert oppA;

        Opportunity oppB = new Opportunity();
        oppB.Related_Agreement__c = oAgreement1.Id;
        oppB.Fiscal_Quarter__c = CURRENT_QUARTER;
        oppB.CloseDate = Date.newinstance(Date.Today().Year() + 1, 3, 31);
        oppB.Name = 'Test dummy 2';//Test Data 8 Amended 12_4d Molecular Therapeutics_Sep302020 2';
        oppB.AccountId = acc1.Id;
        oppB.StageName = STRING_FINALIZE;
        oppB.recordTypeId = OPPRECTYPEID;

        Test.startTest();
        try{
            insert oppB;
        }
        catch(Exception ee){
            sameQuarterError = ee.getMessage();
            System.debug('sameQuarterError '+ sameQuarterError);
        }
        Test.stopTest();

        Assert.isTrue(sameQuarterError.contains(Label.UI_Error_StandingOppSameQuarter));
    }

    @IsTest
    private static void checkStandingQuoteErrorStandingOppWrongAccount() {
        String wrongAccountError = '';

        Account acc1 = getAccount('Test Opp Agreement 1');
        Apttus__APTS_Agreement__c oAgreement1 = getAgreement();

        Opportunity oppA = new Opportunity();
        oppA.Related_Agreement__c = oAgreement1.Id;
        oppA.Fiscal_Quarter__c = CURRENT_QUARTER;
        oppA.CloseDate = Date.newinstance(Date.Today().Year() + 1, 3, 31);
        oppA.Name = 'Test Dummy';
        oppA.AccountId = acc1.Id;
        oppA.StageName = STRING_FINALIZE;
        oppA.recordTypeId = OPPRECTYPEID;
        
        insert oppA;

        Account acc2 = [SELECT ID, Name, ERP_Customer_Id__c, BIllingCountryCode, CurrencyIsoCode 
            FROM Account WHERE Name = 'Test Opp Agreement 2' LIMIT 1];

        Test.startTest();
        try{
            oppA.AccountId = acc2.Id;
            update oppA;
        }
        catch(Exception ee){
            wrongAccountError = ee.getMessage();
            System.debug('wrongAccountError '+ wrongAccountError);
        }
        Test.stopTest();

        Assert.isTrue(wrongAccountError.contains(Label.UI_Error_StandingOppWrongAccount));
    }

    /**
     * @author Tapas
     * @date   18 Sep 2020
     * @description    DCP-40569 test for updatecurrencyOnSQOppProds method
    **/ 
    @isTest
    private static void checkCurrencyUpdateOnSQOPs() {
        Account acc1 = getAccount('Test Opp Agreement 1');
        Apttus__APTS_Agreement__c oAgreement1 = getAgreement();
        System.debug('checkStandingQuoteOpp1 '+ acc1+oAgreement1);

        Account acc2 = getAccount('Test Opp Agreement 2');
        Agreement_Account_Relationship__c objAA = new Agreement_Account_Relationship__c(Account__c = acc2.id, Agreement__c = oAgreement1.ID);
        insert objAA;
        Test.startTest();

        Opportunity objOpp1 = new Opportunity();
        objOpp1.Related_Agreement__c = oAgreement1.Id;
        objOpp1.Fiscal_Quarter__c = CURRENT_QUARTER;
        objOpp1.CloseDate = Date.newinstance(Date.Today().Year() + 1, 3, 31);
        objOpp1.Name = 'Test Data 8 Amended 12_4d Molecular Therapeutics_Sep302020 2';
        objOpp1.AccountId = acc1.Id;
        objOpp1.StageName = STRING_FINALIZE;
        objOpp1.recordTypeId = OPPRECTYPEID;
        insert objOpp1;

        Standing_Quote_Opportunity_Product__c objRelatedList = new Standing_Quote_Opportunity_Product__c();
        objRelatedList.Forecast_Amount__c = 2;
        objRelatedList.Material_Group__c = 'mat1';
        objRelatedList.Material_Group_Description__c ='desc';
        objRelatedList.Opportunity__c = objOpp1.id;
        insert objRelatedList;

        System.debug('objRelatedList CurrencyIsoCode '+ [SELECT id, CurrencyIsoCode FROM Standing_Quote_Opportunity_Product__c WHERE id = :objRelatedList.Id] + objRelatedList);
        objOpp1.AccountId = acc2.Id;
        update objOpp1;

        Test.stopTest(); 
        Assert.areEqual('USD', [SELECT id, CurrencyIsoCode from Standing_Quote_Opportunity_Product__c where id =: objRelatedList.Id][0].CurrencyIsoCode);
    }

	/**
    *    @author Pankaj Singla
    *    @date   2020-09-16
    *    @description Test Cloning of Opportunity
    */
    @isTest
    private static void cloneStandingQuoteOpp() {
        Account acc1 = getAccount('Test Opp Agreement 1');
        Apttus__APTS_Agreement__c oAgreement1 = getAgreement();
        System.debug('checkStandingQuoteOpp1 '+ acc1 + oAgreement1);

        Test.startTest();
        Opportunity objOpp1 = new Opportunity();
        objOpp1.Related_Agreement__c = oAgreement1.Id;
        objOpp1.Fiscal_Quarter__c = CURRENT_QUARTER;
        objOpp1.CloseDate = Date.newinstance(Date.Today().Year() + 1, 3, 31);
        objOpp1.Name = 'Test Data 8 Amended 12_4d Molecular Therapeutics_Sep302020 2';
        objOpp1.AccountId = acc1.Id;
        objOpp1.StageName = STRING_FINALIZE;
        objOpp1.recordTypeId = OPPRECTYPEID;
        insert objOpp1;

        Standing_Quote_Opportunity_Product__c objRelatedList=new Standing_Quote_Opportunity_Product__c();
        objRelatedList.Forecast_Amount__c = 2;
        objRelatedList.Material_Group__c = 'mat1';
        objRelatedList.Material_Group_Description__c = 'desc';
        objRelatedList.Opportunity__c = objOpp1.id;

        Standing_Quote_Opportunity_Product__c objRelatedList2=new Standing_Quote_Opportunity_Product__c();
        objRelatedList2.Forecast_Amount__c = 3;
        objRelatedList2.Material_Group__c = 'mat1';
        objRelatedList2.Material_Group_Description__c = 'desc';
        objRelatedList2.Opportunity__c = objOpp1.id;
        insert (new list<Standing_Quote_Opportunity_Product__c>{objRelatedList,objRelatedList2});

        Opportunity objOpp2=objOpp1.clone();
        objOpp2.CloseDate=Date.newinstance(Date.Today().Year() + 2, 12, 31);
        insert objOpp2;

        Test.stopTest();
        List<Standing_Quote_Opportunity_Product__c> lst = [SELECT id FROM Standing_Quote_Opportunity_Product__c WHERE
                                                         Opportunity__c = :objOpp2.id];
        Assert.areEqual(2, lst.size());
    }

}