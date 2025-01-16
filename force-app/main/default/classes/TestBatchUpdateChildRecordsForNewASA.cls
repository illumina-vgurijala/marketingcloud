/*@ author       : Roopal Verma
* @ date         : 01-12-2018
* @ Description  : Test class for batch to update child opportunities and quotation record for Sales area extension.
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Roopal Verma          01-12-2018                 Initial version
* Satya Swain           10-09-2019                 Adding clearOpportunityCache for INC0225110 
* Parthasarathy D       10-Oct-2022                Codescan Fix - Added method level comments.   
*/

@isTest
public class TestBatchUpdateChildRecordsForNewASA {

    /*
    *  @author      : 
    *  @description : Method to create test data.
    *  @param       : 
    *  @return      : Void.
    */
    @testSetup
    public static void setupData(){

        Account acc1 = TestDataAccount.getAccount('Account 1');
        acc1.BillingCountryCode = 'US';
        acc1.BillingStateCode = 'AK';
        acc1.ERP_Customer_Id__c = '123456';
        Account acc2 = TestDataAccount.getAccount('Account 2');
        acc2.ERP_Customer_Id__c = '345678';
        Account acc3 = TestDataAccount.getAccount('Account 3');
        acc3.BillingCountryCode = 'US';
        acc3.BillingStateCode = 'AK';
        acc3.ERP_Customer_Id__c = '567890';
        acc3.Account_Group__c = 'Distributor';
        Account acc4 = TestDataAccount.getAccount('Account 4');
        acc4.ERP_Customer_Id__c = '789012';
        Account acc5 = TestDataAccount.getAccount('Account 5');
        acc5.BillingCountryCode = 'US';
        acc5.BillingStateCode = 'AK';
        acc5.ERP_Customer_Id__c = '565456';
        acc5.Account_Group__c = 'Distributor';
        Account accDummy1 = TestDataAccount.getAccount('AccountDum 1');
        accDummy1.ERP_Customer_Id__c = 'dum1';
        Account accDummy2 = TestDataAccount.getAccount('AccountDum 2');
        acc5.BillingCountryCode = 'US';
        acc5.BillingStateCode = 'AK';
        acc5.ERP_Customer_Id__c = 'dum2';
        acc5.Account_Group__c = 'Distributor';

        Account objAccount = TestDataAccount.getAccount('Hogwarts');
        objAccount.ERP_Customer_Id__c = 'Hogy';
        objAccount.BillingCountryCode = 'US';
        objAccount.BillingStateCode = 'AK';
        Account objUC = TestDataAccount.getAccount('Gryffindoor');
        objUC.ERP_Customer_Id__c = null;
        Account objDistributor = TestDataAccount.getAccount('Slytherin');
        objDistributor.BillingCountryCode = 'US';
        objDistributor.BillingStateCode = 'AK';
        objDistributor.ERP_Customer_Id__c = 'Slimy';
        objDistributor.Account_Group__c = Label.AccountGroupDistributor;

        insert new List<Account>{acc1,acc2,acc3,acc4,acc5,objAccount,objUC,objDistributor,accDummy1,accDummy2};

        System.debug('acc1.id'+acc1.id);

        Account_Sales_Area__c acc1SalesArea = TestDataAccountSalesArea.getAccountSalesArea('US01','01','789012_US010100','00',false);
        acc1SalesArea.Account__c = acc4.Id;
        acc1SalesArea.Price_List_Type__c='01';
        acc1SalesArea.CurrencyIsoCode = 'USD';
        acc1SalesArea.Price_List__c = '01-AMR-USD';
        acc1SalesArea.Contract_Number__c = '789012_US010100';
        insert acc1SalesArea;

        Account_Sales_Area__c acc2SalesArea = TestDataAccountSalesArea.getAccountSalesArea('US01','02','565456_US010200','00',false);
        acc2SalesArea.Account__c = acc5.Id;
        acc2SalesArea.Price_List_Type__c='01';
        acc2SalesArea.CurrencyIsoCode = 'USD';
        acc2SalesArea.Price_List__c = '01-AMR-USD';
        acc2SalesArea.Contract_Number__c = '565456_US010200';
        insert acc2SalesArea;

        Account_Sales_Area__c acc3SalesArea = TestDataAccountSalesArea.getAccountSalesArea('US01','02','565456_US010100','00',false);
        acc3SalesArea.Account__c = acc5.Id;
        acc3SalesArea.Price_List_Type__c='01';
        acc3SalesArea.CurrencyIsoCode = 'USD';
        acc3SalesArea.Price_List__c = '01-AMR-USD';
        acc3SalesArea.Contract_Number__c = '565456_US010100';
        insert acc3SalesArea;

        Apttus_Config2__PriceList__c objPriceList2 = TestDataProposal.initPriceList('01-AMR-USD');
        insert objPriceList2;

        List<Opportunity> lstOpp = new List<Opportunity>();

        Opportunity opp1 = TestDataOpportunity.initOpportunity(acc2,Label.OpportunityRTDirectStandard);
        opp1.Name = 'opp1';
        opp1.Ultimate_Consignee__c = acc1.Id;
        Opportunity opp2 = TestDataOpportunity.initOpportunity(acc2,Label.OpportunityRTIndirectStandard);
        opp2.Name = 'opp2';
        opp2.Ultimate_Consignee__c = acc1.Id;
        opp2.Distributor__c = acc3.Id;
        opp2.Direct_Sale_to_Ultimate_Consignee__c = true;
        Opportunity opp3 = TestDataOpportunity.initOpportunity(acc4,Label.OpportunityRTDirectStandard);
        opp3.Name = 'opp3';
        opp3.Ultimate_Consignee__c = acc1.Id;
        Opportunity opp4 = TestDataOpportunity.initOpportunity(acc4,Label.OpportunityRTIndirectStandard);
        opp4.Name = 'opp4';
        opp4.Ultimate_Consignee__c = acc1.Id;
        opp4.Distributor__c = acc5.Id;
        opp4.Direct_Sale_to_Ultimate_Consignee__c = true;
        Opportunity opp5 = TestDataOpportunity.initOpportunity(objAccount,Label.OpportunityRTIndirectStandard);
        opp5.Name = 'opp5';
        opp5.Ultimate_Consignee__c = acc1.Id;
        opp5.Distributor__c = acc5.Id;
        opp5.Direct_Sale_to_Ultimate_Consignee__c = false;
        
        lstOpp.add(opp1);
        lstOpp.add(opp2);
        lstOpp.add(opp3);
        lstOpp.add(opp4);
        lstOpp.add(opp5);
        insert lstOpp;

    }


    static testmethod void testPriceListUpdate(){
        
        Account acc2 = [Select Id, ERP_Customer_Id__c From Account where Name Like 'Account 2'];
        Account acc3 = [Select Id, ERP_Customer_Id__c From Account where Name Like 'Account 3'];

        Opportunity oppNew = [SELECT id,AccountId,Ultimate_Consignee__c,Name,Sales_Area_Sold_To__c,Sales_Area_Ultimate_Consignee__c,Price_List_Type__c,Price_List__c,Sales_Area_Distributor__c,CurrencyIsoCode,Contract_Number__c,Sold_to_Sales_Organization__c,Sold_to_Distribution_Channel__c,Sold_to_Division__c,Direct_Sale_to_Ultimate_Consignee__c FROM Opportunity WHERE Name LIKE'opp1'];

        System.assertEquals(null, oppNew.Price_List_Type__c,'Pricelist defaulting');

        Opportunity oppNew1 = [SELECT id,AccountId,Ultimate_Consignee__c,Distributor__c,Name,Sales_Area_Sold_To__c,Sales_Area_Ultimate_Consignee__c,Price_List_Type__c,Price_List__c,Sales_Area_Distributor__c,CurrencyIsoCode,Contract_Number__c,Sold_to_Sales_Organization__c,Sold_to_Distribution_Channel__c,Sold_to_Division__c,Direct_Sale_to_Ultimate_Consignee__c FROM Opportunity WHERE Name LIKE'opp2'];

        System.assertEquals(null, oppNew1.Price_List_Type__c,'Pricelist defaulting');

        for(Opportunity opp : [SELECT id,AccountId,Ultimate_Consignee__c,Name,Sales_Area_Sold_To__c,Sales_Area_Ultimate_Consignee__c,Price_List_Type__c,Price_List__c,Sales_Area_Distributor__c,CurrencyIsoCode,Contract_Number__c,Sold_to_Sales_Organization__c,Sold_to_Distribution_Channel__c,Sold_to_Division__c,Direct_Sale_to_Ultimate_Consignee__c FROM Opportunity WHERE (Name LIKE'opp1' OR Name LIKE 'opp2' OR Name LIKE 'oppDum1%')]){
           System.assertEquals(null, opp.Price_List_Type__c,'Pricelist defaulting'); 
        }

        List<Account_Sales_Area__c> lstASA = new List<Account_Sales_Area__c>();

        Account_Sales_Area__c acc2SalesArea = TestDataAccountSalesArea.getAccountSalesArea('US01','01','345678_US010100','00',false);
        acc2SalesArea.Account__c = acc2.Id;
        acc2SalesArea.Price_List_Type__c='01';
        acc2SalesArea.CurrencyIsoCode = 'USD';
        acc2SalesArea.Price_List__c = '01-AMR-USD';
        acc2SalesArea.ERP_Account_Sales_Area_Id__c = '345678_US010100';
        Account_Sales_Area__c acc4SalesArea = TestDataAccountSalesArea.getAccountSalesArea('US01','02','345678_US010200','00',false);
        acc4SalesArea.Account__c = acc2.Id;
        acc4SalesArea.Price_List_Type__c='01';
        acc4SalesArea.CurrencyIsoCode = 'USD';
        acc4SalesArea.Price_List__c = '01-AMR-CAD';
        Account_Sales_Area__c acc3SalesArea = TestDataAccountSalesArea.getAccountSalesArea('US01','02','567890_US010200','00',false);
        acc3SalesArea.Account__c = acc3.Id;
        acc3SalesArea.Price_List_Type__c='01';
        acc3SalesArea.CurrencyIsoCode = 'USD';
        acc3SalesArea.Price_List__c = '01-AMR-USD';
        acc3SalesArea.Contract_Number__c ='567890_US010200';
        Account_Sales_Area__c acc5SalesArea = TestDataAccountSalesArea.getAccountSalesArea('US01','01','567890_US010100','00',false);
        acc5SalesArea.Account__c = acc3.Id;
        acc5SalesArea.Price_List_Type__c='01';
        acc5SalesArea.CurrencyIsoCode = 'USD';
        acc5SalesArea.Price_List__c = '01-AMR-CAD';
        lstASA.add(acc2SalesArea);
        lstASA.add(acc3SalesArea);
        lstASA.add(acc4SalesArea);
        lstASA.add(acc5SalesArea);
        insert lstASA;

        BatchUpdateChildRecordsForNewASA batch = new BatchUpdateChildRecordsForNewASA(lstASA);

        Test.startTest();   
            DataBase.executeBatch(batch,3);             
        Test.stopTest();

        for(Opportunity oppUpdated : [SELECT id,AccountId,Ultimate_Consignee__c,Name,Sales_Area_Sold_To__c,Sales_Area_Ultimate_Consignee__c,Price_List_Type__c,Price_List__c,Sales_Area_Distributor__c,CurrencyIsoCode,Contract_Number__c,Sold_to_Sales_Organization__c,Sold_to_Distribution_Channel__c,Sold_to_Division__c,Direct_Sale_to_Ultimate_Consignee__c FROM Opportunity WHERE (Name LIKE'opp1' OR Name LIKE 'opp2')]){
           System.assertEquals('USD', oppUpdated.CurrencyIsoCode,'CurrencyISOCode not defaulting');
           System.assertEquals('01', oppUpdated.Price_List_Type__c,'Price list type not defaulting');
           System.assertEquals('01-AMR-USD', oppUpdated.Price_List__c,'Pricelist not defaulting'); 
        }

       Opportunity oppUpdated = [SELECT id,AccountId,Ultimate_Consignee__c,Name,Sales_Area_Sold_To__c,Sales_Area_Ultimate_Consignee__c,Price_List_Type__c,Price_List__c,Sales_Area_Distributor__c,CurrencyIsoCode,Contract_Number__c,Sold_to_Sales_Organization__c,Sold_to_Distribution_Channel__c,Sold_to_Division__c,Direct_Sale_to_Ultimate_Consignee__c FROM Opportunity WHERE Name LIKE'opp1'];

        //System.debug('--oppUpdated.AccountId'+ oppUpdated.AccountId);
        //System.debug('--oppUpdated.Ultimate_Consignee'+ oppUpdated.Ultimate_Consignee__c);
        //System.debug('--oppUpdated.Sales_Area_Sold_To__c'+ oppUpdated.Sales_Area_Sold_To__c);
        //System.debug('--oppUpdated.Sales_Area_Ultimate_Consignee__c'+ oppUpdated.Sales_Area_Ultimate_Consignee__c);
        //System.debug('--oppUpdated.CurrencyIsoCode'+ oppUpdated.CurrencyIsoCode);
        //System.debug('--oppUpdated.Price_List_Type__c'+ oppUpdated.Price_List_Type__c);
        //System.debug('--oppUpdated.Price_List__c'+ oppUpdated.Price_List__c);
        System.assertEquals('USD', oppUpdated.CurrencyIsoCode,'CurrencyISOCode not defaulting');
        System.assertEquals('01', oppUpdated.Price_List_Type__c,'Price list type not defaulting');
        System.assertEquals('01-AMR-USD', oppUpdated.Price_List__c,'Pricelist not defaulting');

        Opportunity oppUpdated1 = [SELECT id,AccountId,Ultimate_Consignee__c,Distributor__c,Name,Sales_Area_Sold_To__c,Sales_Area_Ultimate_Consignee__c,Price_List_Type__c,Price_List__c,Sales_Area_Distributor__c,CurrencyIsoCode,Contract_Number__c,Sold_to_Sales_Organization__c,Sold_to_Distribution_Channel__c,Sold_to_Division__c,Direct_Sale_to_Ultimate_Consignee__c FROM Opportunity WHERE Name LIKE'opp2'];

        //System.debug('--oppUpdated1.AccountId'+ oppUpdated1.AccountId);
        //System.debug('--oppUpdated1.Ultimate_Consignee'+ oppUpdated1.Ultimate_Consignee__c);
        //System.debug('--oppUpdated1.distributor'+ oppUpdated1.Distributor__c);
        //System.debug('--oppUpdated1.Sales_Area_Sold_To__c'+ oppUpdated1.Sales_Area_Sold_To__c);
        //System.debug('--oppUpdated1.Sales_Area_Ultimate_Consignee__c'+ oppUpdated1.Sales_Area_Ultimate_Consignee__c);
        //System.debug('--oppUpdated1.CurrencyIsoCode'+ oppUpdated1.CurrencyIsoCode);
        //System.debug('--oppUpdated1.Price_List_Type__c'+ oppUpdated1.Price_List_Type__c);
        //System.debug('--oppUpdated1.Price_List__c'+ oppUpdated1.Price_List__c);
        System.assertEquals('USD', oppUpdated1.CurrencyIsoCode,'CurrencyISOCode not defaulting');
        System.assertEquals('01', oppUpdated1.Price_List_Type__c,'Price list type not defaulting');
        System.assertEquals('01-AMR-USD', oppUpdated1.Price_List__c,'Pricelist not defaulting');

    }

    static testmethod void testBillToShipToUpdates(){

        Opportunity oppDirect = [SELECT id,AccountId,Ultimate_Consignee__c,Name,Sales_Area_Sold_To__c,Sales_Area_Ultimate_Consignee__c,Price_List_Type__c,Price_List__c,Sales_Area_Distributor__c,CurrencyIsoCode,Contract_Number__c,Sold_to_Sales_Organization__c,Sold_to_Distribution_Channel__c,Sold_to_Division__c,Direct_Sale_to_Ultimate_Consignee__c FROM Opportunity WHERE Name LIKE'opp3'];
        Opportunity oppIndirect = [SELECT id,AccountId,Ultimate_Consignee__c,Distributor__c,Name,Sales_Area_Sold_To__c,Sales_Area_Ultimate_Consignee__c,Price_List_Type__c,Price_List__c,Sales_Area_Distributor__c,CurrencyIsoCode,Contract_Number__c,Sold_to_Sales_Organization__c,Sold_to_Distribution_Channel__c,Sold_to_Division__c,Direct_Sale_to_Ultimate_Consignee__c FROM Opportunity WHERE Name LIKE'opp4'];
        System.debug('oppDirect' + oppDirect);
        System.debug('oppIndirect' + oppIndirect);
        Opportunity oppIndirect2 = [SELECT id,AccountId,Ultimate_Consignee__c,Distributor__c,Name,Sales_Area_Sold_To__c,Sales_Area_Ultimate_Consignee__c,Price_List_Type__c,Price_List__c,Sales_Area_Distributor__c,CurrencyIsoCode,Contract_Number__c,Sold_to_Sales_Organization__c,Sold_to_Distribution_Channel__c,Sold_to_Division__c,Direct_Sale_to_Ultimate_Consignee__c FROM Opportunity WHERE Name LIKE'opp5'];
        System.debug('oppIndirect2' + oppIndirect2);
        Apttus_Config2__PriceList__c objPriceList = [SELECT Id,Name FROM Apttus_Config2__PriceList__c WHERE Name='01-AMR-USD'];

        System.debug('objPriceList' + objPriceList);

        Test.startTest();
        Apttus_Proposal__Proposal__c objProp1 = TestDataProposal.initProposal(oppDirect.AccountId, oppDirect.id, 'Test Proposal 1', 
                                                                                 objPriceList.id, true, 'Draft', 'None');
        Apttus_Proposal__Proposal__c objProp2 = TestDataProposal.initProposal(oppIndirect.AccountId, oppIndirect.id, 'Test Proposal 2', 
                                                                                 objPriceList.id, true, 'Draft', 'None');
        Apttus_Proposal__Proposal__c objProp3 = TestDataProposal.initProposal(oppIndirect2.AccountId, oppIndirect2.id, 'Test Proposal 3', 
                                                                                 objPriceList.id, true, 'Draft', 'None');
        insert new List<Apttus_Proposal__Proposal__c>{objProp1,objProp2,objProp3};

        Account accHogy = [SELECT Id,Name, ERP_Customer_Id__c From Account Where Name LIKE 'Hogwarts'];
        Account acc1UC = [SELECT Id,Name, ERP_Customer_Id__c From Account Where Name LIKE 'Account 1'];        
        Account accSlimy = [SELECT Id,Name, ERP_Customer_Id__c From Account Where Name LIKE 'Slytherin'];

        System.debug('accHogy--' + accHogy);
        oppDirect.AccountId = accHogy.id;
        oppDirect.Ultimate_Consignee__c = acc1UC.id;
        oppIndirect.AccountId = accHogy.id;
        oppIndirect2.Distributor__c = accSlimy.id;

        // Added by Satya for INC0225110
        OpportunitySelector.clearOpportunityCache();
        update new List<Opportunity>{oppDirect,oppIndirect,oppIndirect2};

        Opportunity oppDirectUpd = [SELECT id,AccountId,Ultimate_Consignee__c,Name,Sales_Area_Sold_To__c,Sales_Area_Ultimate_Consignee__c,Price_List_Type__c,Price_List__c,Sales_Area_Distributor__c,CurrencyIsoCode,Contract_Number__c,Sold_to_Sales_Organization__c,Sold_to_Distribution_Channel__c,Sold_to_Division__c,Direct_Sale_to_Ultimate_Consignee__c FROM Opportunity WHERE Name LIKE'opp3'];
        Opportunity oppIndirectUpd = [SELECT id,AccountId,Ultimate_Consignee__c,Distributor__c,Name,Sales_Area_Sold_To__c,Sales_Area_Ultimate_Consignee__c,Price_List_Type__c,Price_List__c,Sales_Area_Distributor__c,CurrencyIsoCode,Contract_Number__c,Sold_to_Sales_Organization__c,Sold_to_Distribution_Channel__c,Sold_to_Division__c,Direct_Sale_to_Ultimate_Consignee__c FROM Opportunity WHERE Name LIKE'opp5'];

        System.debug('--oppDirectUpd.AccountId'+ oppDirectUpd.AccountId);
        System.debug('--oppDirectUpd.Ultimate_Consignee'+ oppDirectUpd.Ultimate_Consignee__c);
        System.debug('--oppDirectUpd.Sales_Area_Sold_To__c'+ oppDirectUpd.Sales_Area_Sold_To__c);
        System.debug('--oppDirectUpd.Sales_Area_Ultimate_Consignee__c'+ oppDirectUpd.Sales_Area_Ultimate_Consignee__c);
        System.debug('--oppDirectUpd.CurrencyIsoCode'+ oppDirectUpd.CurrencyIsoCode);
        System.debug('--oppDirectUpd.Price_List_Type__c'+ oppDirectUpd.Price_List_Type__c);
        System.debug('--oppDirectUpd.Price_List__c'+ oppDirectUpd.Price_List__c);

        System.debug('--oppIndirectUpd.AccountId'+ oppIndirectUpd.AccountId);
        System.debug('--oppIndirectUpd.Ultimate_Consignee'+ oppIndirectUpd.Ultimate_Consignee__c);
        System.debug('--oppIndirectUpd.Sales_Area_Sold_To__c'+ oppIndirectUpd.Sales_Area_Sold_To__c);
        System.debug('--oppIndirectUpd.Sales_Area_Ultimate_Consignee__c'+ oppIndirectUpd.Sales_Area_Ultimate_Consignee__c);
        System.debug('--oppIndirectUpd.CurrencyIsoCode'+ oppIndirectUpd.CurrencyIsoCode);
        System.debug('--oppIndirectUpd.Price_List_Type__c'+ oppIndirectUpd.Price_List_Type__c);
        System.debug('--oppIndirectUpd.Price_List__c'+ oppIndirectUpd.Price_List__c);

        Customer_Master_Data__c objCMDUC = new Customer_Master_Data__c(Name='GCMD',Country__c='USA'),
                                objCMDSoldTo = new Customer_Master_Data__c(Name='HCMD',Country__c='USA'),
                                objCMDDis = new Customer_Master_Data__c(Name='SCMD',Country__c='USA');
        objCMDUC.ERP_Customer_Id__c = '123456';
        objCMDSoldTo.ERP_Customer_Id__c = 'Hogy';
        objCMDDis.ERP_Customer_Id__c = 'Slimy';

        insert new List<Customer_Master_Data__c>{objCMDUC,objCMDSoldTo,objCMDDis};

        List<Account_Sales_Area__c> lstASA = new List<Account_Sales_Area__c>();

        Account_Sales_Area__c objSoldToSA = TestDataAccountSalesArea.getAccountSalesArea('US01','01','Hogy_US010100','00',false);
        objSoldToSA.Account__c = accHogy.Id;
        objSoldToSA.Price_List_Type__c='01';
        objSoldToSA.CurrencyIsoCode = 'USD';
        objSoldToSA.Price_List__c = '01-AMR-USD';
        objSoldToSA.Contract_Number__c = 'Hogy_US010100';
        objSoldToSA.Customer_Master_Data__c = objCMDSoldTo.Id;
        Account_Sales_Area__c objSoldToSA1 = TestDataAccountSalesArea.getAccountSalesArea('US01','01','Hogy_US010200','00',false);
        objSoldToSA1.Account__c = accHogy.Id;
        objSoldToSA1.Price_List_Type__c='01';
        objSoldToSA1.CurrencyIsoCode = 'USD';
        objSoldToSA1.Price_List__c = '01-AMR-USD';
        objSoldToSA1.Contract_Number__c = 'Hogy_US010200';
        objSoldToSA1.Customer_Master_Data__c = objCMDSoldTo.Id;
        Account_Sales_Area__c objUCSA = TestDataAccountSalesArea.getAccountSalesArea('US01','01','123456_US010200','00',false);
        objUCSA.Account__c = acc1UC.Id;
        objUCSA.Price_List_Type__c='01';
        objUCSA.CurrencyIsoCode = 'USD';
        objUCSA.Price_List__c = '01-AMR-USD';
        objUCSA.Customer_Master_Data__c = objCMDUC.Id;
        Account_Sales_Area__c objUCSA1 = TestDataAccountSalesArea.getAccountSalesArea('US01','01','123456_US010100','00',false);
        objUCSA1.Account__c = acc1UC.Id;
        objUCSA1.Price_List_Type__c='01';
        objUCSA1.CurrencyIsoCode = 'USD';
        objUCSA1.Price_List__c = '01-AMR-USD';
        objUCSA1.Customer_Master_Data__c = objCMDUC.Id;
        Account_Sales_Area__c objUCDis = TestDataAccountSalesArea.getAccountSalesArea('US01','02','Slimy_US010200','00',false);
        objUCDis.Account__c = accSlimy.Id;
        objUCDis.Price_List_Type__c='01';
        objUCDis.CurrencyIsoCode = 'USD';
        objUCDis.Price_List__c = '01-AMR-USD';
        objUCDis.Contract_Number__c ='Slimy_US010200';
        lstASA.add(objSoldToSA);
        lstASA.add(objSoldToSA1);
        lstASA.add(objUCSA);
        lstASA.add(objUCSA1);
        lstASA.add(objUCDis);
        insert lstASA;

        Account_Relationship__c objSoldToBT = new Account_Relationship__c(ERP_Customer_Id__c = 'Hogy',
                                                                          Related_ERP_Customer_Id__c ='Hogy',
                                                                            Relationship__c=Label.AccountRelationshipBillTo);
        objSoldToBT.Account_Sales_Area__c = objSoldToSA.Id;
        Account_Relationship__c objSoldToBT1 = new Account_Relationship__c(ERP_Customer_Id__c = 'Hogy',
                                                                          Related_ERP_Customer_Id__c ='Hogy',
                                                                            Relationship__c=Label.AccountRelationshipBillTo);
        objSoldToBT1.Account_Sales_Area__c = objSoldToSA1.Id;
        Account_Relationship__c objUCBT = new Account_Relationship__c(ERP_Customer_Id__c = '123456',
                                                                          Related_ERP_Customer_Id__c ='123456',
                                                                            Relationship__c=Label.AccountRelationshipShipTo);
        objUCBT.Account_Sales_Area__c = objUCSA.Id;
        Account_Relationship__c objUCBT1 = new Account_Relationship__c(ERP_Customer_Id__c = '123456',
                                                                          Related_ERP_Customer_Id__c ='123456',
                                                                            Relationship__c=Label.AccountRelationshipShipTo);
        objUCBT1.Account_Sales_Area__c = objUCSA1.Id;
        Account_Relationship__c objDisBT = new Account_Relationship__c(ERP_Customer_Id__c = 'Slimy',
                                                                          Related_ERP_Customer_Id__c ='Slimy',
                                                                            Relationship__c=Label.AccountRelationshipShipTo);
        objDisBT.Account_Sales_Area__c = objUCDis.Id;
        insert new List<Account_Relationship__c>{objSoldToBT,objUCBT,objDisBT,objSoldToBT1,objUCBT1};


        System.debug('UCQuery' + json.serialize(new AccountRelationshipsSelector().selectByAccountIdRelationship(new Set<String>{'123456'},new List<String>{'Ship To'})));

        BatchUpdateChildRecordsForNewASA batch = new BatchUpdateChildRecordsForNewASA(lstASA);
   
        DataBase.executeBatch(batch,5);             
        Test.stopTest();

        Opportunity oppUpdated1 = [SELECT id,AccountId,Ultimate_Consignee__c,Name,Sales_Area_Sold_To__c,Sales_Area_Ultimate_Consignee__c,Price_List_Type__c,Price_List__c,Sales_Area_Distributor__c,CurrencyIsoCode,Contract_Number__c,Sold_to_Sales_Organization__c,Sold_to_Distribution_Channel__c,Sold_to_Division__c,Direct_Sale_to_Ultimate_Consignee__c FROM Opportunity WHERE Name LIKE'opp3'];

        System.debug('--oppUpdated1.AccountId'+ oppUpdated1.AccountId);
        System.debug('--oppUpdated1.Ultimate_Consignee'+ oppUpdated1.Ultimate_Consignee__c);
        System.debug('--oppUpdated1.Sales_Area_Sold_To__c'+ oppUpdated1.Sales_Area_Sold_To__c);
        System.debug('--oppUpdated1.Sales_Area_Ultimate_Consignee__c'+ oppUpdated1.Sales_Area_Ultimate_Consignee__c);
        System.debug('--oppUpdated1.CurrencyIsoCode'+ oppUpdated1.CurrencyIsoCode);
        System.debug('--oppUpdated1.Price_List_Type__c'+ oppUpdated1.Price_List_Type__c);
        System.debug('--oppUpdated1.Price_List__c'+ oppUpdated1.Price_List__c);

        Apttus_Proposal__Proposal__c propUpdated1 = [SELECT id,Ship_To__c,Bill_To__c,Payer__c,Apttus_Proposal__Account__c,Ultimate_Consignee__c,Distributor__c,Apttus_QPConfig__PriceListId__c From Apttus_Proposal__Proposal__c where Apttus_Proposal__Proposal_Name__c Like 'Test Proposal 1' ];

         System.debug('--propUpdated1.Apttus_Proposal__Account__c'+ propUpdated1.Apttus_Proposal__Account__c);
        System.debug('--propUpdated1.Ultimate_Consignee__c'+ propUpdated1.Ultimate_Consignee__c);
        System.debug('--propUpdated1.Distributor__c'+ propUpdated1.Distributor__c);
        System.debug('--propUpdated1.Ship_To__c'+ propUpdated1.Ship_To__c);
        System.debug('--propUpdated1.Bill_To__c'+ propUpdated1.Bill_To__c);
        System.debug('--propUpdated1.Payer__c'+ propUpdated1.Payer__c);
        System.debug('--propUpdated1.Apttus_QPConfig__PriceListId__c'+ propUpdated1.Apttus_QPConfig__PriceListId__c);
        
        Opportunity oppUpdated = [SELECT id,AccountId,Ultimate_Consignee__c,Name,Sales_Area_Sold_To__c,Sales_Area_Ultimate_Consignee__c,Price_List_Type__c,Price_List__c,Sales_Area_Distributor__c,CurrencyIsoCode,Contract_Number__c,Sold_to_Sales_Organization__c,Sold_to_Distribution_Channel__c,Sold_to_Division__c,Direct_Sale_to_Ultimate_Consignee__c FROM Opportunity WHERE Name LIKE'opp4'];

        System.debug('--oppUpdated.AccountId'+ oppUpdated.AccountId);
        System.debug('--oppUpdated.Ultimate_Consignee'+ oppUpdated.Ultimate_Consignee__c);
        System.debug('--oppUpdated.Sales_Area_Sold_To__c'+ oppUpdated.Sales_Area_Sold_To__c);
        System.debug('--oppUpdated.Sales_Area_Ultimate_Consignee__c'+ oppUpdated.Sales_Area_Ultimate_Consignee__c);
        System.debug('--oppUpdated.CurrencyIsoCode'+ oppUpdated.CurrencyIsoCode);
        System.debug('--oppUpdated.Price_List_Type__c'+ oppUpdated.Price_List_Type__c);
        System.debug('--oppUpdated.Price_List__c'+ oppUpdated.Price_List__c);

        Apttus_Proposal__Proposal__c prop1Updated = [SELECT id,Ship_To__c,Bill_To__c,Payer__c,Apttus_Proposal__Account__c,Ultimate_Consignee__c,Distributor__c,Apttus_QPConfig__PriceListId__c From Apttus_Proposal__Proposal__c where Apttus_Proposal__Proposal_Name__c Like 'Test Proposal 2' ];

         System.debug('--prop1Updated.Apttus_Proposal__Account__c'+ prop1Updated.Apttus_Proposal__Account__c);
        System.debug('--prop1Updated.Ultimate_Consignee__c'+ prop1Updated.Ultimate_Consignee__c);
        System.debug('--prop1Updated.Distributor__c'+ prop1Updated.Distributor__c);
        System.debug('--prop1Updated.Ship_To__c'+ prop1Updated.Ship_To__c);
        System.debug('--prop1Updated.Bill_To__c'+ prop1Updated.Bill_To__c);
        System.debug('--prop1Updated.Payer__c'+ prop1Updated.Payer__c);
        System.debug('--prop1Updated.Apttus_QPConfig__PriceListId__c'+ prop1Updated.Apttus_QPConfig__PriceListId__c);

        Opportunity oppIDUpdated = [SELECT id,AccountId,Ultimate_Consignee__c,Name,Sales_Area_Sold_To__c,Sales_Area_Ultimate_Consignee__c,Price_List_Type__c,Price_List__c,Sales_Area_Distributor__c,CurrencyIsoCode,Contract_Number__c,Sold_to_Sales_Organization__c,Sold_to_Distribution_Channel__c,Sold_to_Division__c,Direct_Sale_to_Ultimate_Consignee__c FROM Opportunity WHERE Name LIKE'opp5'];

        System.debug('--oppIDUpdated.AccountId'+ oppIDUpdated.AccountId);
        System.debug('--oppIDUpdated.Ultimate_Consignee'+ oppIDUpdated.Ultimate_Consignee__c);
        System.debug('--oppIDUpdated.Sales_Area_Sold_To__c'+ oppIDUpdated.Sales_Area_Sold_To__c);
        System.debug('--oppIDUpdated.Sales_Area_Ultimate_Consignee__c'+ oppIDUpdated.Sales_Area_Ultimate_Consignee__c);
        System.debug('--oppIDUpdated.CurrencyIsoCode'+ oppIDUpdated.CurrencyIsoCode);
        System.debug('--oppIDUpdated.Price_List_Type__c'+ oppIDUpdated.Price_List_Type__c);
        System.debug('--oppIDUpdated.Price_List__c'+ oppIDUpdated.Price_List__c);

        Apttus_Proposal__Proposal__c prop3Updated = [SELECT id,Ship_To__c,Bill_To__c,Payer__c,Apttus_Proposal__Account__c,Ultimate_Consignee__c,Distributor__c,Apttus_QPConfig__PriceListId__c From Apttus_Proposal__Proposal__c where Apttus_Proposal__Proposal_Name__c Like 'Test Proposal 3' ];

        System.debug('--prop3Updated.Apttus_Proposal__Account__c'+ prop3Updated.Apttus_Proposal__Account__c);
        System.debug('--prop3Updated.Ultimate_Consignee__c'+ prop3Updated.Ultimate_Consignee__c);
        System.debug('--prop3Updated.Distributor__c'+ prop3Updated.Distributor__c);
        System.debug('--prop3Updated.Ship_To__c'+ prop3Updated.Ship_To__c);
        System.debug('--prop3Updated.Bill_To__c'+ prop3Updated.Bill_To__c);
        System.debug('--prop3Updated.Payer__c'+ prop3Updated.Payer__c);
        System.debug('--prop3Updated.Apttus_QPConfig__PriceListId__c'+ prop3Updated.Apttus_QPConfig__PriceListId__c);
        
        for (Apttus_Proposal__Proposal__c proposal :[SELECT id,Ship_To__c,Bill_To__c,Payer__c,Apttus_Proposal__Account__c,Ultimate_Consignee__c,Distributor__c,Apttus_QPConfig__PriceListId__c,Apttus_Proposal__Proposal_Name__c From Apttus_Proposal__Proposal__c]){
            if(proposal.Apttus_Proposal__Proposal_Name__c == 'Test Proposal 1' || proposal.Apttus_Proposal__Proposal_Name__c == 'Test Proposal 2'){
   
               System.assertEquals(objCMDUC.Id, proposal.Ship_To__c,'Ship To not defaulting');
               }else{
                   System.assertEquals(objCMDSoldTo.Id, proposal.Bill_To__c,'Bill To not defaulting');
                   System.assertEquals(objCMDSoldTo.Id, proposal.Payer__c,'Payer not defaulting');
               }
        }

    }

    static testmethod void testBlankProspectERP(){

        Opportunity oppDirect = [SELECT id,AccountId,Ultimate_Consignee__c,Name,Sales_Area_Sold_To__c,Sales_Area_Ultimate_Consignee__c,Price_List_Type__c,Price_List__c,Sales_Area_Distributor__c,CurrencyIsoCode,Contract_Number__c,Sold_to_Sales_Organization__c,Sold_to_Distribution_Channel__c,Sold_to_Division__c,Direct_Sale_to_Ultimate_Consignee__c FROM Opportunity WHERE Name LIKE'opp3'];
        Apttus_Config2__PriceList__c objPriceList = [SELECT Id,Name FROM Apttus_Config2__PriceList__c WHERE Name='01-AMR-USD'];
        Test.startTest();
        TestDataProposal.initProposal(oppDirect.AccountId, oppDirect.id, 'Test Proposal 1', 
                                                                                 objPriceList.id, true, 'Draft', 'None');


        Account accGriffy = [SELECT Id,Name, ERP_Customer_Id__c From Account Where Name LIKE 'Gryffindoor'];
        system.debug('accGriffy.id'+accGriffy.id+'_'+accGriffy.ERP_Customer_Id__c);
        oppDirect.Ultimate_Consignee__c = accGriffy.id;
        oppDirect.Sales_Area_Ultimate_Consignee__c = null;
        oppDirect.Sales_Area_Sold_To__c = null;
        update oppDirect;


        System.debug('oppDirect3'+ oppDirect);
        accGriffy.ERP_Customer_Id__c = 'Griffy';
        update accGriffy;

        Customer_Master_Data__c objCMDUC = new Customer_Master_Data__c(Name='ICMD',Country__c='US');
        objCMDUC.ERP_Customer_Id__c = 'Griffy';
        insert objCMDUC;

        List<Account_Sales_Area__c> lstASA = new List<Account_Sales_Area__c>();

        Account_Sales_Area__c objUCSA = TestDataAccountSalesArea.getAccountSalesArea('US01','01','Griffy_US010100','00',false);
        objUCSA.Account__c = accGriffy.Id;
        objUCSA.Price_List_Type__c='01';
        objUCSA.CurrencyIsoCode = 'USD';
        objUCSA.Price_List__c = '01-AMR-USD';
        objUCSA.Customer_Master_Data__c = objCMDUC.Id;
        insert objUCSA;

        lstASA.add(objUCSA);

        Account_Relationship__c objUCBT = new Account_Relationship__c(ERP_Customer_Id__c = 'Griffy',
                                                                          Related_ERP_Customer_Id__c ='Griffy',
                                                                            Relationship__c=Label.AccountRelationshipBillTo);
        objUCBT.Account_Sales_Area__c = objUCSA.Id;
        insert objUCBT;

        BatchUpdateChildRecordsForNewASA batch = new BatchUpdateChildRecordsForNewASA(lstASA);
   
        DataBase.executeBatch(batch,5);             
        Test.stopTest();

        Opportunity oppDirectUpd = [SELECT id,AccountId,Ultimate_Consignee__c,Name,Sales_Area_Sold_To__c,Sales_Area_Ultimate_Consignee__c,Price_List_Type__c,Price_List__c,Sales_Area_Distributor__c,CurrencyIsoCode,Contract_Number__c,Sold_to_Sales_Organization__c,Sold_to_Distribution_Channel__c,Sold_to_Division__c,Direct_Sale_to_Ultimate_Consignee__c FROM Opportunity WHERE Name LIKE'opp3'];
        System.debug('oppDirectUpd3' + oppDirectUpd);        
        System.debug('--oppDirectUpd.AccountId'+ oppDirectUpd.AccountId);
        System.debug('--oppDirectUpd.Ultimate_Consignee'+ oppDirectUpd.Ultimate_Consignee__c);
        System.debug('--oppDirectUpd.Sales_Area_Sold_To__c'+ oppDirectUpd.Sales_Area_Sold_To__c);
        System.debug('--oppDirectUpd.Sales_Area_Ultimate_Consignee__c'+ oppDirectUpd.Sales_Area_Ultimate_Consignee__c);
        System.debug('--oppDirectUpd.CurrencyIsoCode'+ oppDirectUpd.CurrencyIsoCode);
        System.debug('--oppDirectUpd.Price_List_Type__c'+ oppDirectUpd.Price_List_Type__c);
        System.debug('--oppDirectUpd.Price_List__c'+ oppDirectUpd.Price_List__c);
        System.assertEquals('789012_HK010100',oppDirectUpd.Sales_Area_Sold_To__c,'Sales area sold to not set');
        System.assertEquals('Griffy_HK010100',oppDirectUpd.Sales_Area_Ultimate_Consignee__c,'Sales area UC not set');
    }

}