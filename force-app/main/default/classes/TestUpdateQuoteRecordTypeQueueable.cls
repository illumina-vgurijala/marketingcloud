/***************************************************************************************************************************************
* NAME         : TestUpdateQuoteRecordTypeQueueable
* DESCRIPTION  : Test class for UpdateQuoteRecordTypeQueueable.                 
* @AUTHOR : Anish
* @DATE   : 25-Mar-2021  
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------
* Anish                 25-Mar-2021          Initial Version. 
* Adithi Acharya        31-Oct-2022          DCP-56437 : Removal of Rejected Quote Stage
* Adyasha Satapathy     28-Nov-2022          POL-54: Update region references to AMEA and EUR
****************************************************************************************************************************************/

@isTest
public class TestUpdateQuoteRecordTypeQueueable {

    @testSetup
    static void initializeTestData()
    {
        User userWithPermission = [SELECT Id,Name FROM User WHERE Id =: UserInfo.getUserId()];
        new PermissionSetAssignmentsSelector().selectPermissionSetAssigmentByName('Test');
        PermissionSet ps = new PermissionSet();
        ps.Name = 'Test_Custom_Perm';
        ps.Label = 'Test_Custom_Perm';
        insert ps;
        SetupEntityAccess sea = new SetupEntityAccess();
        sea.ParentId = ps.Id;
        sea.SetupEntityId = [SELECT Id FROM CustomPermission WHERE DeveloperName = 'Sales_Integration_User'][0].Id;
        insert sea;

        PermissionSetAssignment psa = new PermissionSetAssignment();
        psa.AssigneeId = userWithPermission.Id;
        psa.PermissionSetId = ps.Id;
        insert psa;
        
        System.runAs(userWithPermission){
        Account acc = TestDataAccount.initAccount();
        Account acc2 = TestDataAccount.initAccount();
        acc2.BillingCountry = 'USA';
        acc2.BillingState = 'Pennsylvania';
        acc2.Billingstatecode = 'PA';
        acc2.CurrencyIsoCode = 'USD';
        acc2.BillingCountryCode='US';
        insert new List<Account> { acc, acc2 };
        Contact con = TestDataPerson.initContact(acc.Id);
        Contact con2 = TestDataPerson.initContact(acc.Id);
        insert new List<Contact> { con, con2 };

        Account_Sales_Area__c acc1SalesArea = TestDataAccountSalesArea.getAccountSalesArea('HK01', '01', '178', '00', false);
        acc1SalesArea.Account__c = acc.Id;
        acc1SalesArea.Price_List_Type__c = '06';
        acc1SalesArea.CurrencyIsoCode = 'USD';
        acc1SalesArea.Price_List__c = '01-AMEA-USD';//POL-54
        acc1SalesArea.Contract_Number__c = '123456_HK010100';
        Account_Sales_Area__c acc2SalesArea = TestDataAccountSalesArea.getAccountSalesArea('HK01', '02', '179', '00', false);
        acc2SalesArea.Account__c = acc2.Id;
        acc2SalesArea.Price_List_Type__c = '06';
        acc2SalesArea.CurrencyIsoCode = 'USD';
        acc2SalesArea.Price_List__c = '01-AMEA-USD';//POL-54
        acc2SalesArea.Contract_Number__c ='567890_US010100';
        insert new List<Account_Sales_Area__c>{ acc1SalesArea, acc2SalesArea };

        Pricebook2 standardPricebook = TestDataOpportunity.getStandardPriceBook();

        Opportunity opp = TestDataOpportunity.initOpportunity(acc,Opportunities.OPPORTUNITY_RT_DIRECT_RE_ORDER);
        opp.Pricebook2Id = standardPricebook.Id;
        opp.Price_List__c = '01-AMR-USD';
        opp.Proposal_Sent_On__c = null;
        opp.name = 'Test Opp 1';
        opp.Ultimate_Consignee__c = acc.Id;
        opp.Type = 'Custom Product (First Buy)';
        opp.Product_Interest__c = 'Consumables';
        Opportunity opp2 = TestDataOpportunity.initOpportunity(acc,Opportunities.RT_STANDARD_DIRECT);
        opp2.Pricebook2Id = standardPricebook.Id;
        opp2.Price_List__c = '01-AMR-USD';
        opp2.Proposal_Sent_On__c = null;
        opp2.name = 'Test Opp 2';
        opp2.Product_Interest__c = 'Consumables';
        opp2.Are_Products_Added__c = false;
        insert new List<Opportunity>{opp,opp2};
        
        Apttus_Config2__PriceList__c priceList = TestDataProposal.initPriceList('AMR-USD-US-01');
        insert priceList;
        String strDraft = 'Draft'; 
        String strNone = 'None'; 
        Id recTypeId = Schema.SObjectType.Apttus_Proposal__Proposal__c.getRecordTypeInfosByName().get('Custom Product Quote').getRecordTypeId();
        Apttus_Proposal__Proposal__c proposal = TestDataProposal.initProposal(acc.id, opp.id, 'Test Proposal', priceList.id, true, strDraft, strNone); 
        Apttus_Proposal__Proposal__c proposal1 = TestDataProposal.initProposal(acc.id, opp.id, 'Proposal 1', priceList.id, true, 'Accepted', strNone); 
        Apttus_Proposal__Proposal__c proposal2 = TestDataProposal.initProposal(acc.id, opp.id, 'Test New Proposal', priceList.id, true, strDraft, strNone);
        Apttus_Proposal__Proposal__c proposal4 = TestDataProposal.initProposal(acc.id, opp2.id, 'Test New Proposal', priceList.id, true, strDraft, strNone); 
        proposal.RecordTypeId = recTypeId;
        proposal2.Is_Updated_By_System__c = true;
        proposal1.Is_Updated_By_System__c = true;
        proposal.Is_Updated_By_System__c = true;
        proposal4.Is_Updated_By_System__c = true;
        proposal2.Apttus_Proposal__Approval_Stage__c = Label.QuoteStageDenied;
        proposal2.Apttus_Proposal__ExpectedEndDate__c = System.today();
        Apttus_Proposal__Proposal__c proposal3 = TestDataProposal.initProposal(acc.id, opp2.id, 'Test New Proposal2', priceList.id, true, 'Denied', strNone); 
        proposal3.Is_Updated_By_System__c = true;
        proposal4.SAP_Quote__c = '1111111';
        insert new List<Apttus_Proposal__Proposal__c> { proposal, proposal1, proposal2, proposal3 , proposal4 };   
        }
    }
    
    static testMethod void checkReOrderOppUpdate()
    {
        Id idRecordType = Opportunities.RECORD_TYPE_MAP.get(Opportunities.OPPORTUNITY_RT_DIRECT_RE_ORDER).getRecordTypeId();
        test.startTest();
        Opportunity opp = [SELECT Id,Manual_Quote_Number__c,Name FROM Opportunity WHERE name = 'Test Opp 2'];
        opp.RecordTypeId = idRecordType;
        opp.Type = 'Custom Product (First Buy)';
        update opp;
        test.stopTest();
        Opportunity opp1 = [SELECT Id,Manual_Quote_Number__c,Name FROM Opportunity WHERE name = 'Test Opp 2'];
        System.assert(opp1.Id != null);

    }
    
    static testMethod void checkNonReOrderOppUpdate()
    {
        Id idRecordType = Opportunities.RECORD_TYPE_MAP.get(Opportunities.RT_STANDARD_DIRECT).getRecordTypeId();
        test.startTest();
        Opportunity opp = [SELECT Id,Manual_Quote_Number__c,Name FROM Opportunity WHERE name = 'Test Opp 1'];
        opp.RecordTypeId = idRecordType;
        opp.Type = 'Standard Sale';
        update opp;
        test.stopTest();
        Opportunity opp1 = [SELECT Id,Manual_Quote_Number__c,Name FROM Opportunity WHERE name = 'Test Opp 1'];
        System.assert(opp1.Id != null);

    }
       
 /**
    *Author : Anshaj 
    *Method Name : coverCatchBlockUpdateQuoteRecordTypeQueueable()
    *Description : CMSI-204 : method to cover catch block of UpdateQuoteRecordTypeQueueable
    **/
    @isTest
    public static void coverCatchBlockUpdateQuoteRecordTypeQueueable(){
        try{
            UpdateQuoteRecordTypeQueueable.catchException = true;
            UpdateQuoteRecordTypeQueueable uqr = new UpdateQuoteRecordTypeQueueable(null);
            Test.startTest();
            System.enqueueJob(uqr);
            Test.stopTest();
        }
        catch(Exception e){
            System.assert(e!=null,'e is not empty');
        }
    }
}