/***************************************************************************************************************************************
* NAME   : TestGetPricingDetails
* DESCRIPTION  : TestClass for GetPricingDetails
*           DCP-38806 
*    
* @AUTHOR : Digvijay
* @DATE   : 01-09-2020  
*
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------
* Digvijay             01-09-2020            Initial Version

****************************************************************************************************************************************/ 
@isTest
public with sharing class TestGetPricingDetails {
    
    
    public static final String STRING_WO_ORDER_TYPE = 'Service Activities';
   
    
    static testMethod void testgetPriceDetails(){
        Account acc1 = TestDataAccount.getAccount('Account 1');
        acc1.BillingCountryCode = 'US';
        acc1.BillingStateCode = 'AK';
        acc1.ERP_Customer_Id__c = '123456';
        acc1.Account_Group__c = 'Sold To';
        
        Account acc2 = TestDataAccount.getAccount('Account 2');
        acc2.BillingCountryCode = 'US';
        acc2.BillingStateCode = 'AK';
        acc2.ERP_Customer_Id__c = '567890';
        acc2.Account_Group__c = 'Distributor';
        
        
        Account acc3 = TestDataAccount.getAccount('Account 3');
        acc3.BillingCountryCode = 'US';
        acc3.BillingStateCode = 'AK';
        acc3.ERP_Customer_Id__c = '5678890';
        acc3.Account_Group__c = 'Ultimate Consignee';
        
        List<Account> lstAcc = new List<Account>();
        lstAcc.add(acc1);
        lstAcc.add(acc2);
        lstAcc.add(acc3);
        insert lstAcc;
        
        Account_Sales_Area__c acc1SalesArea = TestDataAccountSalesArea.getAccountSalesArea('US01','01','178','00',false);
        acc1SalesArea.Account__c = acc1.Id;
        acc1SalesArea.Price_List_Type__c='01';
        acc1SalesArea.CurrencyIsoCode = 'USD';
        acc1SalesArea.Price_List__c = '01-AMR-USD';
        acc1SalesArea.Contract_Number__c = '123456_US010100';
        
        Account_Sales_Area__c acc2SalesArea = TestDataAccountSalesArea.getAccountSalesArea('US01','02','179','00',false);
        acc2SalesArea.Account__c = acc2.Id;
        acc2SalesArea.Price_List_Type__c='01';
        acc2SalesArea.CurrencyIsoCode = 'USD';
        acc2SalesArea.Price_List__c = '01-AMR-USD';
        acc2SalesArea.Contract_Number__c ='567890_US010100';
        
        Account_Sales_Area__c acc3SalesArea = TestDataAccountSalesArea.getAccountSalesArea('US01','02','180','00',false);
        acc3SalesArea.Account__c = acc3.Id;
        acc3SalesArea.Price_List_Type__c='01';
        acc3SalesArea.CurrencyIsoCode = 'USD';
        acc3SalesArea.Price_List__c = '01-AMR-USD';
        acc3SalesArea.Contract_Number__c ='567890_US010130';
        
        
        Account_Sales_Area__c acc4SalesArea = TestDataAccountSalesArea.getAccountSalesArea('US01','01','181','00',false);
        acc4SalesArea.Account__c = acc3.Id;
        acc4SalesArea.Price_List_Type__c='01';
        acc4SalesArea.CurrencyIsoCode = 'USD';
        acc4SalesArea.Price_List__c = '01-AMR-USD';
        acc4SalesArea.Contract_Number__c ='567890_US010140';
        insert new List<Account_Sales_Area__c>{acc1SalesArea,acc2SalesArea,acc3SalesArea,acc4SalesArea};
            
        Contact conAMR = TestDataPerson.getNewContact(acc3.Id);
        Case caseAMR = TestDataCase.initServiceRequestCase(ConAMR) ;
        insert CaseAMR;
        
        SVMXC__Service_Order__c workOrderAMR = TestDataFieldService.createWorkOrder('Estimates', CaseAMR.Id, 'Initiated');
        workOrderAMR.SVMXC__Order_Type__c=STRING_WO_ORDER_TYPE;
        workOrderAMR.Record_Created_from_SFM__c=true;
        workOrderAMR.Send_for_Quote_Creation__c= false;
        workOrderAMR.SVMXC__Company__c=acc3.Id;
        insert workOrderAMR;

        Test.StartTest();
        workOrderAMR.Sold_To_Account__c=acc1.Id;
        workOrderAMR.Distributor_Account__c=acc2.ERP_Customer_Id__c;
        update workOrderAMR;
        
        //insert product
        Product2 toolProduct2 = TestDataMaster.initProduct('Test Product2','Tools');
        toolProduct2.SVMXC__Product_Type__c = 'Spare';
        insert toolProduct2;
        
        SVMXC__Service_Order_Line__c objOrderDetailPart1 = TestDataFieldService.createWorkDetailWithSpecifiedRecordType(workOrderAMR.Id,'Estimate');
        objOrderDetailPart1.SVMXC__Product__c = toolProduct2.Id;
        objOrderDetailPart1.SVMXC__Estimated_Quantity2__c = 1;
        insert objOrderDetailPart1;

            List<GetPricingDetails.AccountInfoWrapper> lstAccWrapper=GetPricingDetails.getAccountAndPricingDetails(new List<Id>{objOrderDetailPart1.Id});
            System.AssertEquals('123456_US010100',lstAccWrapper[0].salesAreaCodeSoldTo);
        Test.StopTest();
        }
    
    
    static testMethod void testgetPriceDetailsCP(){
        
        Account acc1 = TestDataAccount.getAccount('Account 1');
        acc1.BillingCountryCode = 'US';
        acc1.BillingStateCode = 'AK';
        acc1.ERP_Customer_Id__c = '123456';
        acc1.Account_Group__c = 'Sold To';
        
        Account acc2 = TestDataAccount.getAccount('Account 2');
        acc2.BillingCountryCode = 'US';
        acc2.BillingStateCode = 'AK';
        acc2.ERP_Customer_Id__c = '567890';
        acc2.Account_Group__c = 'Distributor';
        
        
        Account acc3 = TestDataAccount.getAccount('Account 3');
        acc3.BillingCountryCode = 'US';
        acc3.BillingStateCode = 'AK';
        acc3.ERP_Customer_Id__c = '5678890';
        acc3.Account_Group__c = 'Ultimate Consignee';
        
        List<Account> lstAcc = new List<Account>();
        lstAcc.add(acc1);
        lstAcc.add(acc2);
        lstAcc.add(acc3);
        insert lstAcc;
        
        Account_Sales_Area__c acc1SalesArea = TestDataAccountSalesArea.getAccountSalesArea('US01','01','178','00',false);
        acc1SalesArea.Account__c = acc1.Id;
        acc1SalesArea.Price_List_Type__c='01';
        acc1SalesArea.CurrencyIsoCode = 'USD';
        acc1SalesArea.Price_List__c = '01-AMR-USD';
        acc1SalesArea.Contract_Number__c = '123456_US010100';
        
        Account_Sales_Area__c acc2SalesArea = TestDataAccountSalesArea.getAccountSalesArea('US01','02','179','00',false);
        acc2SalesArea.Account__c = acc2.Id;
        acc2SalesArea.Price_List_Type__c='01';
        acc2SalesArea.CurrencyIsoCode = 'USD';
        acc2SalesArea.Price_List__c = '01-AMR-USD';
        acc2SalesArea.Contract_Number__c ='567890_US010100';
        
        Account_Sales_Area__c acc3SalesArea = TestDataAccountSalesArea.getAccountSalesArea('US01','02','180','00',false);
        acc3SalesArea.Account__c = acc3.Id;
        acc3SalesArea.Price_List_Type__c='01';
        acc3SalesArea.CurrencyIsoCode = 'USD';
        acc3SalesArea.Price_List__c = '01-AMR-USD';
        acc3SalesArea.Contract_Number__c ='567890_US010130';
        
        
        Account_Sales_Area__c acc4SalesArea = TestDataAccountSalesArea.getAccountSalesArea('US01','01','181','00',false);
        acc4SalesArea.Account__c = acc3.Id;
        acc4SalesArea.Price_List_Type__c='01';
        acc4SalesArea.CurrencyIsoCode = 'USD';
        acc4SalesArea.Price_List__c = '01-AMR-USD';
        acc4SalesArea.Contract_Number__c ='567890_US010140';
        insert new List<Account_Sales_Area__c>{acc1SalesArea,acc2SalesArea,acc3SalesArea,acc4SalesArea};
            
        Contact conAMR = TestDataPerson.getNewContact(acc3.Id);
        Case caseAMR = TestDataCase.initServiceRequestCase(ConAMR) ;
        insert CaseAMR;
        
        SVMXC__Service_Order__c workOrderAMR = TestDataFieldService.createWorkOrder('Estimates', CaseAMR.Id, 'Initiated');
        workOrderAMR.SVMXC__Order_Type__c=STRING_WO_ORDER_TYPE;
        workOrderAMR.Record_Created_from_SFM__c=true;
        workOrderAMR.Send_for_Quote_Creation__c= false;
        workOrderAMR.SVMXC__Company__c=acc3.Id;
        workOrderAMR.Partner_Work_Order__c=true;
        insert workOrderAMR;
        
        Test.StartTest();
        workOrderAMR.Sold_To_Account__c=acc1.Id;
        workOrderAMR.Distributor_Account__c=acc2.ERP_Customer_Id__c;
        update workOrderAMR;
        
        //insert product
        Product2 toolProduct2 = TestDataMaster.initProduct('Test Product2','Tools');
        toolProduct2.SVMXC__Product_Type__c = 'Spare';
        insert toolProduct2;
        
        SVMXC__Service_Order_Line__c objOrderDetailPart1 = TestDataFieldService.createWorkDetailWithSpecifiedRecordType(workOrderAMR.Id,'Estimate');
        objOrderDetailPart1.SVMXC__Product__c = toolProduct2.Id;
        objOrderDetailPart1.SVMXC__Estimated_Quantity2__c = 1;
         insert objOrderDetailPart1;
            List<GetPricingDetails.AccountInfoWrapper> lstAccWrapper=GetPricingDetails.getAccountAndPricingDetails(new List<Id>{objOrderDetailPart1.Id});
            System.AssertEquals('567890_US010200',lstAccWrapper[0].salesAreaCodedistributor);
        Test.StopTest();       
    }
}