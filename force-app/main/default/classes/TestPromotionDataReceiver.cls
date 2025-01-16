/***************************************************************************************************************************************
 * NAME         : TestPromotionDataReceiver
 * DESCRIPTION  : Test Class for PromotionDataReceiver-DCP 40228
 * @AUTHOR      : Karthik Rayani
 * @DATE        : 08-Sep-2020  
 * 
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 *  Karthik Rayani    08-Sep-2020       DCP-40228-Initial Version.
 ****************************************************************************************************************************************/
@isTest(SeeAllData = 'false')
public class TestPromotionDataReceiver {

    @testSetup
    static void initializeTestData() 
    {
        Promotions__c promoIns = new Promotions__c();
        promoIns.Name = 'NFE10Test2';
        promoIns.Promotion_Code__c = 'NFE10T2';
        promoIns.Expiration_Date__c = Date.valueOf('2021-12-31T00:00:00.000Z');
        promoIns.Effective_Date__c = Date.valueOf('2018-12-20T00:00:00.000Z');
        promoIns.Terms_and_Conditions__c = ' CONDITIONS OF SALE: • Terms & pricing are confidential ';
        promoIns.Approval_Required__c = false;
        //promoIns.Approver__c = prw.Approver;
        promoIns.Change_History__c = 'test history';
        promoIns.Country__c = 'US';
        promoIns.Customer_Description__c = 'test description';
        promoIns.Distribution_Channel__c = '01;';
        promoIns.Distribution_Channel_Description__c = 'Direct';
        promoIns.Distributor_Eligible__c = true;
        promoIns.Limit_View__c = true;
        promoIns.Marketing_Trade_In__c = 'Internal';
        promoIns.Primary_Product_Line__c = 'Test Product_Line';
        promoIns.Promotion_Channel__c = 'F1;';
        promoIns.Promotion_Channel_Description__c = 'Online/Quoting – One User Per UC';
        promoIns.Promotion_Details__c = 'Must have paid for 6 month DRAGEN license currently or in the past to receive a one-time per customer (including affiliates) $1,500 off for any of the below SKUs: 20050264 - NextSeq™1000/2000 P1 Reagents(300Cycles)';
        //promoIns.Promotion_Owner__c = prw.Promotion_Owner;
        promoIns.Redemption_Limit__c = 'redemption limit';
        promoIns.Regions__c = 'AMR;AMEA;China;EUR';
        promoIns.Rules_Requirements__c = 'rules';
        promoIns.Sales_Description__c = '$1500 off any NS1k/2k Reagent kit for DRAGEN 6 month license Paying Customers';
        promoIns.Sales_Org__c = 'AT01;';
        promoIns.Stackable__c = true;
        promoIns.Promo_Type__c = 'test type';
        insert promoIns;
    }

    static testMethod void testPromotionDataReceiverInsertHTTPPost() 
    {
        System.debug('From testPromotionDataReceiverInsertHTTPPost');
        List < PromotionWrapper > listPromotionWrapper = new List < PromotionWrapper > ();
        System.debug('After Order******************************** ');
        PromotionWrapper promo1 = new PromotionWrapper();
        promo1.Name = 'NFE10Test1';
        promo1.Promotion_Code = 'NFE10T1';
        promo1.Expiration_Date = '2022-12-31T00:00:00.000Z';
        promo1.Effective_Date = '2018-12-20T00:00:00.000Z';
        promo1.Terms_and_Conditions = 'New CONDITIONS OF SALE: • Terms & pricing are confidential ';
        promo1.Approval_Required = 'false';
        //promo1.Approver = prw.Approver;
        promo1.Change_History = 'test history';
        promo1.Country = 'US';
        promo1.Customer_Description = 'test description';
        promo1.Distribution_Channel = '01;';
        promo1.Distribution_Channel_Description = 'Direct';
        promo1.Distributor_Eligible = 'true';
        promo1.Limit_View = 'true';
        promo1.Marketing_Trade_In = 'Internal';
        promo1.Primary_Product_Line = 'Test Product_Line';
        promo1.Promo_Channel = 'F1;';
        promo1.Promotion_Channel_Description = 'Online/Quoting – One User Per UC';
        promo1.Promotion_Details = 'Must have paid for 6 month DRAGEN license currently or in the past to receive a one-time per customer (including affiliates) $1,500 off for any of the below SKUs: 20050264 - NextSeq™1000/2000 P1 Reagents(300Cycles)';
        //promo1.Promotion_Owner = prw.Promotion_Owner;
        promo1.Redemption_Limit = 'redemption limit';
        promo1.Regions = 'AMR;AMEA;China;EUR';
        promo1.Rules_Requirements = 'rules';
        promo1.Sales_Description = '$1500 off any NS1k/2k Reagent kit for DRAGEN 6 month license Paying Customers';
        promo1.Sales_Org = 'AT01;';
        promo1.Stackable = 'true';
        promo1.Promo_Type = 'test type';
        listPromotionWrapper.add(promo1);
        System.debug('After Order******************************** promo1' + promo1);

        PromotionWrapper promo2 = new PromotionWrapper();
        promo2.Name = 'NFE10Test2';
        promo2.Promotion_Code = 'NFE10T2';
        promo2.Expiration_Date = '2023-12-31T00:00:00.000Z';
        promo2.Effective_Date = '2018-12-20T00:00:00.000Z';
        promo2.Terms_and_Conditions = 'New CONDITIONS OF SALE: ';
        promo2.Approval_Required = 'false';
        //promo2.Approver = prw.Approver;
        promo2.Change_History = 'test history';
        promo2.Country = 'US';
        promo2.Customer_Description = 'test description';
        promo2.Distribution_Channel = '01;';
        promo2.Distribution_Channel_Description = 'Direct';
        promo2.Distributor_Eligible = 'true';
        promo2.Limit_View = 'true';
        promo2.Marketing_Trade_In = 'Internal';
        promo2.Primary_Product_Line = 'Test Product_Line';
        promo2.Promo_Channel = 'F1;';
        promo2.Promotion_Channel_Description = 'Online/Quoting – One User Per UC';
        promo2.Promotion_Details = 'Must have paid for 6 month DRAGEN license currently or in the past to receive a one-time per customer (including affiliates) $1,500 off for any of the below SKUs: 20050264 - NextSeq™1000/2000 P1 Reagents(300Cycles)';
        //promo2.Promotion_Owner = prw.Promotion_Owner;
        promo2.Redemption_Limit = 'redemption limit';
        promo2.Regions = 'AMR;AMEA;China;EUR';
        promo2.Rules_Requirements = 'rules';
        promo2.Sales_Description = '$1500 off any NS1k/2k Reagent kit for DRAGEN 6 month license Paying Customers';
        promo2.Sales_Org = 'AT01;';
        promo2.Stackable = 'true';
        promo2.Promo_Type = 'test type';
        listPromotionWrapper.add(promo2);
        System.debug('After Order******************************** promo2' + promo2);

        PromotionWrapper promo3 = new PromotionWrapper();
        promo3.Name = 'NFE10Test1';
        promo3.Promotion_Code = 'NFE10T1';
        promo3.Expiration_Date = '2020-12-31T00:00:00.000Z';
        promo3.Effective_Date = '2015-12-20T00:00:00.000Z';
        promo3.Terms_and_Conditions = 'New CONDITIONS OF SALE: • Terms & pricing are confidential ';
        promo3.Approval_Required = 'false';
        //promo3.Approver = prw.Approver;
        promo3.Change_History = 'test history';
        promo3.Country = 'US';
        promo3.Customer_Description = 'test description';
        promo3.Distribution_Channel = '01;';
        promo3.Distribution_Channel_Description = 'Direct';
        promo3.Distributor_Eligible = 'true';
        promo3.Limit_View = 'true';
        promo3.Marketing_Trade_In = 'Internal';
        promo3.Primary_Product_Line = 'Test Product_Line';
        promo3.Promo_Channel = 'F1;';
        promo3.Promotion_Channel_Description = 'Online/Quoting – One User Per UC';
        promo3.Promotion_Details = 'Must have paid for 6 month DRAGEN license currently or in the past to receive a one-time per customer (including affiliates) $1,500 off for any of the below SKUs: 20050264 - NextSeq™1000/2000 P1 Reagents(300Cycles)';
        //promo3.Promotion_Owner = prw.Promotion_Owner;
        promo3.Redemption_Limit = 'redemption limit';
        promo3.Regions = 'AMR;AMEA;China;EUR';
        promo3.Rules_Requirements = 'rules';
        promo3.Sales_Description = '$1500 off any NS1k/2k Reagent kit for DRAGEN 6 month license Paying Customers';
        promo3.Sales_Org = 'AT01;';
        promo3.Stackable = 'true';
        promo3.Promo_Type = 'test type';
        listPromotionWrapper.add(promo3);
        System.debug('After Order******************************** promo3' + promo3);

        System.debug('Request Json' + listPromotionWrapper);
        String requestJSON = JSON.serialize(listPromotionWrapper);
        Test.startTest();
        //As Per Best Practice it is important to instantiate the Rest Context 
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/PromoSyncInterface/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(requestJSON);
        RestContext.request = req;
        RestContext.response = res;
        PromotionDataReceiver.upsertIncomingValues();
        Test.stopTest();
        System.debug('Rest Status Code for insert: ' + res.statusCode);
        System.assertequals(200, res.statuscode);
    }

    static testMethod void testPromotionDataReceiverRestError() 
    {
        System.debug('From testPromotionDataReceiverRestError');
        List < PromotionWrapper > listPromotionWrapper = new List < PromotionWrapper > ();
        System.debug('After Order******************************** ');
        PromotionWrapper promo1 = new PromotionWrapper();
        promo1.Name = 'DTR21';
        promo1.Promotion_Code = 'NFE10T1';
        promo1.Expiration_Date = '2020-12-31T00:00:00.000Z';
        promo1.Effective_Date = '2016-12-20T00:00:00.000Z';
        promo1.Terms_and_Conditions = 'New CONDITIONS OF SALE: • Terms & pricing are confidential ';
        promo1.Approval_Required = 'false';
        //promo1.Approver = prw.Approver;
        promo1.Change_History = 'test history';
        promo1.Country = 'US';
        promo1.Customer_Description = 'test description';
        promo1.Distribution_Channel = '01;';
        promo1.Distribution_Channel_Description = 'Direct';
        promo1.Distributor_Eligible = 'true';
        promo1.Limit_View = 'true';
        promo1.Marketing_Trade_In = 'Internal';
        promo1.Primary_Product_Line = 'Test Product_Line';
        promo1.Promo_Channel = 'F1;';
        promo1.Promotion_Channel_Description = 'Online/Quoting – One User Per UC';
        promo1.Promotion_Details = 'Must have paid for 6 month DRAGEN license currently or in the past to receive a one-time per customer (including affiliates) $1,500 off for any of the below SKUs: 20050264 - NextSeq™1000/2000 P1 Reagents(300Cycles)';
        //promo1.Promotion_Owner = prw.Promotion_Owner;
        promo1.Redemption_Limit = 'redemption limit';
        promo1.Regions = 'AMR;AMEA;China;EUR';
        promo1.Rules_Requirements = 'rules';
        promo1.Sales_Description = '$1500 off any NS1k/2k Reagent kit for DRAGEN 6 month license Paying Customers';
        promo1.Sales_Org = 'AT01;';
        promo1.Stackable = 'true';
        promo1.Promo_Type = 'test type';
        listPromotionWrapper.add(promo1);
        System.debug('After Order******************************** promo1' + promo1);

        PromotionWrapper promo3 = new PromotionWrapper();
        promo3.Name = '';
        promo3.Promotion_Code = '';
        promo3.Expiration_Date = '2020-12-31T00:00:00.000Z';
        promo3.Effective_Date = '2017-12-20T00:00:00.000Z';
        promo3.Terms_and_Conditions = 'New CONDITIONS OF SALE:• Terms & pricing are confidential ';
        promo3.Approval_Required = 'false';
        //promo2.Approver = prw.Approver;
        promo3.Change_History = 'test history';
        promo3.Country = 'US';
        promo3.Customer_Description = 'test description';
        promo3.Distribution_Channel = '01;';
        promo3.Distribution_Channel_Description = 'Direct';
        promo3.Distributor_Eligible = 'true';
        promo3.Limit_View = 'true';
        promo3.Marketing_Trade_In = 'Internal';
        promo3.Primary_Product_Line = 'Test Product_Line';
        promo3.Promo_Channel = 'F1;';
        promo3.Promotion_Channel_Description = 'Online/Quoting – One User Per UC';
        promo3.Promotion_Details = 'Must have paid for 6 month DRAGEN license currently or in the past to receive a one-time per customer (including affiliates) $1,500 off for any of the below SKUs: 20050264 - NextSeq™1000/2000 P1 Reagents(300Cycles)';
        //pro3o2.Promotion_Owner = prw.Promotion_Owner;
        promo3.Redemption_Limit = 'redemption limit';
        promo3.Regions = 'AMR;AMEA;China;EUR';
        promo3.Rules_Requirements = 'rules';
        promo3.Sales_Description = '$1500 off any NS1k/2k Reagent kit for DRAGEN 6 month license Paying Customers';
        promo3.Sales_Org = 'AT01;';
        promo3.Stackable = 'true';
        promo3.Promo_Type = 'test type';
        listPromotionWrapper.add(promo3);
        System.debug('After Order******************************** promo3' + promo3);

        String requestJSON = JSON.serialize(listPromotionWrapper);
        Test.startTest();
        //As Per Best Practice it is important to instantiate the Rest Context 
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/PromoSyncInterface/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(requestJSON);
        RestContext.request = req;
        RestContext.response = res;
        PromotionDataReceiver.upsertIncomingValues();
        Test.stopTest();
        System.assert(res.statuscode != 200, 'Response is successful');
    }
}