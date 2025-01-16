/**
 * @author Akshay Mohan
 * @date   2018-06-26
 * @description    US-351:Customer Master Synchronization to DCP (INT_MDM-030-001)
 * Modification Log:
 *       ------------------------------------------------------------------------------------
 *       Akshay Mohan        27/06/2018            Original Version
 *       Rahul Sharma        25/01/2019            Added test method for populate tier 
 *       Roopal Verma        26/09/2019            DCP-28565, Added logic for Bank detail fields
 *       Roopal Verma        25/11/2019            DCP-28541 Added Default_Partner to relationships
 *       Prem Ranjan             04 May 2022          CodeScan Fix (APEX) Unused Local Variable  
 *       Aman Tyagi          12/12/2022            Codescan Fixes
 *       ------------------------------------------------------------------------------------
 */

@isTest
public class TestCustomerMasterDataReceiver {

    static testMethod void testAccountInsertHTTPPost()
    {
        List<CustomerMasterWrapper.accountHeader> accountList=new List<CustomerMasterWrapper.accountHeader>();
        List<CustomerMasterWrapper.SalesArea> salesAreaList1=new List<CustomerMasterWrapper.SalesArea>();
        List<CustomerMasterWrapper.AccountRelationship> accountRelationshipList1=new List<CustomerMasterWrapper.AccountRelationship >();
		List<CustomerMasterWrapper.BankGroup> lstBankGroup=new List<CustomerMasterWrapper.BankGroup>();

        CustomerMasterWrapper.BankGroup bankDetails =new CustomerMasterWrapper.BankGroup(); //Added for DCP-28565
        bankDetails.Bank_Account_Number = '12345';
        bankDetails.Bank_Name = 'bank name';
        bankDetails.Bank_Branch = 'branch';
        bankDetails.Street = 'bank street';
        bankDetails.City = 'bank city';
        bankDetails.Region = 'bank region';
        bankDetails.Country = 'bank country';
        lstBankGroup.add(bankDetails);

        Account  testAccount2=TestDataAccount.getAccount('Test Account2');
        testAccount2.Is_Updated_By_System__c=true;
        System.debug('testAccount2: ' + testAccount2);
        insert testAccount2;

        Account testAccountHy=TestDataAccount.getAccount('Test Account Hy');
        insert testAccountHy;

        Customer_Master_Data__c cM1 = TestDataAccount.getCustomerMaster('TestAccountHierarchy1');
        insert cM1;
        Customer_Master_Data__c cM2 = TestDataAccount.getCustomerMaster('TestAccountHierarchy2');
        insert cM2;
        Customer_Master_Data__c cM3 = TestDataAccount.getCustomerMaster('TestAccountHierarchy3');
        insert cM3;

        CustomerMasterWrapper.AccountRelationship accRelObj1=new CustomerMasterWrapper.AccountRelationship();
        accRelObj1.ERP_Customer_Id='4000029091';
        accRelObj1.Related_Account='4000029091';
        accRelObj1.ERP_Account_Relation='4000029091_Sold To_4000029091_US010100';
        accRelObj1.Relationship='Sold To';
		accRelObj1.Default_Partner=false;
        accountRelationshipList1.add(accRelObj1);                                                               //DCP-28541
        System.debug('***Test-Line-35***'+accRelObj1.getSobject());

        CustomerMasterWrapper.AccountRelationship accRelObj2=new CustomerMasterWrapper.AccountRelationship();
        accRelObj2.ERP_Customer_Id='4000029091';
        accRelObj2.Related_Account='4000029091';
        accRelObj2.ERP_Account_Relation='4000029091_Bill To_4000029091_US010100';
        accRelObj2.Relationship='Bill To';
		accRelObj2.Relationship='Bill To';        
        accRelObj2.Default_Partner=false;                                                                       //DCP-28541
        CustomerMasterWrapper.AccountRelationship accRelObj3=new CustomerMasterWrapper.AccountRelationship();
        accRelObj3.ERP_Customer_Id='4000029091';
        accRelObj3.Related_Account='4000029091';
        accRelObj3.ERP_Account_Relation='4000029091_Payer_4000029091_US010100';
        accRelObj3.Relationship='Payer';
        accRelObj3.Default_Partner=false;                                                                       //DCP-28541
        accountRelationshipList1.add(accRelObj3);

        CustomerMasterWrapper.DiscountTiers objDT1 = new CustomerMasterWrapper.DiscountTiers();
        objDT1.Consumable_Tier = 3;
        objDT1.Instrument_Tier = 2;
        objDT1.Service_Tier = 1;

        CustomerMasterWrapper.SalesArea salesAreaObj1=new CustomerMasterWrapper.SalesArea();
        salesAreaObj1.ERP_Customer_Id = '4000029091';
        salesAreaObj1.ERP_Account_Sales_Area_Id='4000029091_US010100';
        salesAreaObj1.Contract_Number='4000029091US010100';
        salesAreaObj1.Sales_Organization='US01';
        salesAreaObj1.Distribution_Channel = '01';
        salesAreaObj1.Division='00';
        salesAreaObj1.Price_List_Type='01';
        salesAreaObj1.Term_of_Payment=null;
        salesAreaObj1.CurrencyIsoCode = 'USD';
        salesAreaObj1.Company_Code = 'US01';
        salesAreaObj1.Incoterm1 = 'CFR: Costs and freight';
        salesAreaObj1.Incoterm2 = null;
        salesAreaObj1.IsInactive = false;
        salesAreaObj1.AccountRelationship=new List<CustomerMasterWrapper.AccountRelationship>();
        salesAreaObj1.AccountRelationship.addAll(accountRelationshipList1);
        salesAreaObj1.DiscountTiers = objDT1;
        salesAreaList1.add(salesAreaObj1);


    
        CustomerMasterWrapper.accountHeader accountobj1=new CustomerMasterWrapper.accountHeader();
        accountobj1.ERP_Customer_Id = '4000029091';
        accountobj1.Account_Group = 'Sold To';
        accountobj1.CurrencyIsoCode = 'USD';
        accountobj1.Preferred_language = 'English';
        accountobj1.Channel_Partner_Type = null;
        accountobj1.Full_Name = 'ProspectActive ssubhashnarale@deloitte.com';
        accountobj1.Name = 'ProspectActive';
        accountobj1.ID = null;
        accountobj1.SystemID = 'Salesforce';
        accountobj1.Global_Group_Number = null;
        accountobj1.National_Group_Number = null;
        accountobj1.Sales_Group_Number = null;
        accountobj1.Street_Line2 = null;
        accountobj1.Street_Line1 = '12344 SAN MATEO RD';
        accountobj1.Care_Of = null;
        accountobj1.BillingPostalCode = '94019';
        accountobj1.BillingCity = 'HALF MOON BAY';
        accountobj1.BillingCountryCode = 'US';
        accountobj1.BillingCountryName = 'USA';
        accountobj1.BillingStateCode = 'CA';
        accountobj1.BillingStateName = 'California';
        accountobj1.Phone = null;
        accountobj1.NameLocal = null;
        accountobj1.Care_Of_Local = null;
        accountobj1.Street_2_Local = null;
        accountobj1.Street_Local = null;
        accountobj1.Country_Local = null;
        accountobj1.State_Province_Local = null;
        accountobj1.Zip_Postal_Code_Local = null;
        accountobj1.City_Local = null;
        accountobj1.Mark_For_Deletion = false;
        accountobj1.SalesArea=new List<CustomerMasterWrapper.SalesArea>();
        accountobj1.SalesArea.addAll(salesAreaList1);
        accountobj1.Global_Group_Number = cM1.ERP_Customer_Id__c;
        accountobj1.National_Group_Number =cM2.ERP_Customer_Id__c;
        accountobj1.Sales_Group_Number =cM3.ERP_Customer_Id__c;
		accountobj1.BankGroup = lstBankGroup;
        accountList.add(accountobj1);
        System.debug('***Test-Line-122***'+accountobj1.getCustMastDataSobject());

        

        String accountJSON = JSON.serialize(accountList);
        System.debug('accountJSON =='+accountJSON );

        Test.startTest();
        {
            //As Per Best Practice it is important to instantiate the Rest Context
            RestRequest req = new RestRequest();
            RestResponse res = new RestResponse();

            req.requestURI = '/services/apexrest/CustMasterSyncInterface';  //Request URL
            req.httpMethod = 'POST'; //HTTP Request Type
            req.requestBody = Blob.valueof(accountJSON);
            RestContext.request = req;
            RestContext.response= res;

            CustomerMasterDataReceiver.upsertIncomingValues();
            System.debug('---Response---'+RestContext.response);
            System.debug('***Test Line 133***'+RestContext.response.responseBody.toString());
            System.assertequals(200, RestContext.response.statuscode);

            List<Account> accountList2 = new List<Account>();
            accountList2 = [Select id, Global_Group_Name__c, Name from Account];
            System.debug('--------------Account Name-----------'+accountList2[0].Name+accountList2[1].Name+accountList2[2].Name);
            System.assertequals(3,accountList2.size() );
            System.assertequals('TestAccountHierarchy1',accountList2[2].Global_Group_Name__c);

            List<Account_Sales_Area__c> salesAreaList= new List<Account_Sales_Area__c>();
            salesAreaList= [Select id,Name,Division__c from Account_Sales_Area__c];
            System.debug('----ASAs----'+salesAreaList[0].Name+'--'+salesAreaList[0].Division__c);
            System.assertequals(1,salesAreaList.size());
        }
        Test.stopTest();
    }

    static testMethod void testAccountUpdateHTTPPost()
    {
        Account testAccount1 = TestDataAccount.getAccount('Test Account1');
        testAccount1.Is_Updated_By_System__c = true;
        System.debug('testAccount1: ' + testAccount1);
        insert testAccount1;

        Account_Sales_Area__c  accSalesArea1=TestDataAccountSalesArea.getAccountSalesArea('org1','ch1','178','div1',true);
        accSalesArea1.Account__c = testAccount1.id;
        insert accSalesArea1;

        Customer_Master_Data__c cM1 = new  Customer_Master_Data__c();
        cM1.ERP_Customer_Id__c ='19876';
        insert cM1;

        Account_Relationship__c accRelObj=new Account_Relationship__c();
        accRelObj.Relationship__c='Sold To';
        accRelObj.ERP_Account_Relationship_Id__c='7889';
        accRelObj.Account_Sales_Area__c=accSalesArea1.id;
        accRelObj.Default_Partner__c=false;                                                                   //DCP-28541
        insert accRelObj;
        
        Account_Relationship__c accRelObj2=new Account_Relationship__c();
        accRelObj2.Relationship__c='Sold To';
        accRelObj2.ERP_Account_Relationship_Id__c='7899';
        accRelObj2.ERP_Customer_Id__c= '897';
        accRelObj2.Account_Sales_Area__c=accSalesArea1.id;
        accRelObj2.Default_Partner__c=false;                                                                  //DCP-28541
        insert accRelObj2;
        System.debug('--accRelObj2--'+accRelObj2);

        List<CustomerMasterWrapper.accountHeader> accountList=new List<CustomerMasterWrapper.accountHeader>();
        List<CustomerMasterWrapper.SalesArea> salesAreaList1=new List<CustomerMasterWrapper.SalesArea>();
        CustomerMasterWrapper.AccountRelationship accRelObj1=new CustomerMasterWrapper.AccountRelationship();
        accRelObj1.ERP_Customer_Id='19876';
        accRelObj1.ERP_Account_Relation='7888';
        accRelObj1.Relationship='SP';
        accRelObj1.Default_Partner=false;                                                                     //DCP-28541

        CustomerMasterWrapper.SalesArea salesAreaObj1=new CustomerMasterWrapper.SalesArea();
        salesAreaObj1.ERP_Account_Sales_Area_Id='178';
        salesAreaObj1.Company_Code='Test';
        salesAreaObj1.Sales_Organization='Imp';
        salesAreaObj1.Division='DV';
        salesAreaObj1.IsInActive=true;
        salesAreaObj1.AccountRelationship=new List<CustomerMasterWrapper.AccountRelationship>();
        salesAreaObj1.AccountRelationship.add(accRelObj1);
        salesAreaList1.add(salesAreaObj1);

        CustomerMasterWrapper.AccountHeader accountobj1=new CustomerMasterWrapper.AccountHeader();
        accountobj1.Name='Test_Name';
        accountobj1.Full_Name='Test_Name Full';
        accountobj1.Id=testAccount1.Id;
        accountobj1.Channel_Partner_Type='Aggregator';
        accountobj1.ERP_Customer_Id='897';
        accountobj1.Id=testAccount1.id;
        accountobj1.BillingStreet='BillingStreet';
        accountobj1.BillingPostalCode='16578';
        accountobj1.BillingCity='NY';
        accountobj1.BillingCountryCode='US';
        accountobj1.BillingStateCode='NJ';
        accountobj1.Phone='78976';
        accountobj1.CurrencyIsoCode='USD';
        accountobj1.SalesArea=new List<CustomerMasterWrapper.SalesArea>();
        accountobj1.Mark_For_Deletion = false;
        accountobj1.Account_Group=Label.AccountGroupSoldTo;
        accountobj1.SalesArea.addAll(salesAreaList1);
        System.debug('accountobj1=='+accountobj1.Id);
        accountList.add(accountobj1);

        String accountJSON = JSON.serialize(accountList);
        System.debug('Line 234 - accountJSON =='+accountJSON );

        Test.startTest();
        {
            //As Per Best Practice it is important to instantiate the Rest Context
            RestRequest req = new RestRequest();
            RestResponse res = new RestResponse();

            req.requestURI = '/services/apexrest/CustMasterSyncInterface';  //Request URL
            req.httpMethod = 'POST'; //HTTP Request Type
            req.requestBody = Blob.valueof(accountJSON);
            RestContext.request = req;
            RestContext.response = res;
            System.debug('***Test Line 247***' + RestContext.request.requestBody.toString());
            try {
                CustomerMasterDataReceiver.upsertIncomingValues();
            } catch (DMLException e) {
                System.debug('Problem updating records');
            }
            System.debug('***Test Line 232***' + RestContext.response.responseBody.toString());
            System.assertequals(200, RestContext.response.statuscode);

            List<Account> accountList2 = new List<Account>();
            accountList2 = [Select id,Name from Account];
            System.assertequals(1, accountList2.size());
            System.assertequals(accountobj1.Full_Name, accountList2[0].Name);

            List<Account_Sales_Area__c> salesAreaList = new List<Account_Sales_Area__c>();
            salesAreaList = [Select id,Division__c from Account_Sales_Area__c];
            System.assertequals(1, salesAreaList.size());
            System.assertequals('DV', salesAreaList[0].Division__c);

            List<SVMXC__Site__c> locationList = new List<SVMXC__Site__c>();
            locationList = [Select id,ERP_Customer_ID__c from SVMXC__Site__c];
            System.assertequals(1, locationList.size());
            System.assertequals('897', locationList[0].ERP_Customer_ID__c);
        }
        Test.stopTest();
    }

    static testMethod void testAccountPopulateTier(){
        Account testAccount1 = TestDataAccount.getAccount('Test Account 1');
        String recordtypeid = Schema.SObjectType.Account.getRecordTypeInfosByName().get(Label.AccountProspect).getRecordTypeId();
        testAccount1.RecordTypeId = recordtypeid;
        insert testAccount1;

        Account testAccount2 = TestDataAccount.getAccount('Test Account 2');
        testAccount2.RecordTypeId = recordtypeid;
        testAccount2.ParentId = testAccount1.Id;

        Test.startTest();
        {
            insert testAccount2;
            System.assertEquals(testAccount1.Tier__c,testAccount2.Tier__c,'Child Tier not equal to parent tier');
        }
        Test.stopTest();
    }

}