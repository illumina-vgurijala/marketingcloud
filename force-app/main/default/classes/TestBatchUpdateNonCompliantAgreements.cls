/***
*    Name - TestBatchUpdateNonCompliantAgreements.
*    DESCRIPTION  : TestClass for BatchUpdateAgreementConLength & BatchUpdateAgreementAwardDt classes.
*    Modification Log:
*   ------------------------------------------------------------------------------------------------
*    Developer                      Date              		Description
*    Amogh Ghodke             27th November 2023              CMCM-2709
*   ------------------------------------------------------------------------------------------------
*/
@isTest(isparallel=false)
public class TestBatchUpdateNonCompliantAgreements {
    
     static testMethod void testBatch(){
	    Id recTypeTender = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Tender').getRecordTypeId();
        Account acc = TestDataAccount.initAccount();
        acc.ERP_Customer_Id__c = '345678';
        acc.BIllingCountryCode='HK' ;
        insert acc;
       
        List<PermissionSetAssignment> lstAgrManager = [SELECT AssigneeId FROM PermissionSetAssignment WHERE PermissionSet.Name = 'SL_Apttus_Agreement_Manager'];
        Set<Id> setUserId = UtilsCollection.getSetOfIds(lstAgrManager,'AssigneeId');
        List<User> lstUser = [Select Id From User where Id =: setUserId AND IsActive = true AND Profile.Name = 'Sales User'];
        User agrManager = lstUser[0];
       
		
		Account_Sales_Area__c accSalesArea = TestDataAccountSalesArea.getAccountSalesArea('HK01', '01', '181', '00', false);
        accSalesArea.Account__c = acc.Id;
        accSalesArea.Price_List_Type__c = '06';
        accSalesArea.CurrencyIsoCode = 'USD';
        accSalesArea.Price_List__c = '01-AMEA-USD';
        accSalesArea.Contract_Number__c = '123456_HK010300';
        accSalesArea.Price_Group__c = 'Test';
        accSalesArea.Sales_Organization__c='HK01';
        accSalesArea.Price_Group_Description__c='Test';
        accSalesArea.Distribution_Channel__c='01';
		insert accSalesArea;
		
        System.runAs(agrManager){
        TestDataAgreement.addHierarchyPermission();
        List<Apttus__APTS_Agreement__c> agreementList = new List<Apttus__APTS_Agreement__c>();
        Apttus__APTS_Agreement__c oAgreement = TestDataAgreement.initAgreements('Test Agreement - Total contract length blank', acc.id);
        oAgreement.Sales_Org__c = 'HK01';
        oAgreement.Total_contract_length_with_extension__c = null;
        oAgreement.Apttus__Subtype__c = 'One Time Sale & Termed';
        oAgreement.Fully_Signed_Contract_Attached__c = 'Yes';
        oAgreement.RecordTypeId = recTypeTender;
        oAgreement.Freight_Charge__c = 'Standard';
        agreementList.add(oAgreement);
        
        Apttus__APTS_Agreement__c oAgreement1 = TestDataAgreement.initAgreements('Test Agreement - Award date not specified', acc.id);
        oAgreement1.Date_awarded__c = null;
        oAgreement1.Fully_Signed_Contract_Attached__c = 'Yes';
        oAgreement1.Tenders_Status__c = 'In Effect/Won';
        oAgreement1.RecordTypeId = recTypeTender;
        oAgreement1.Freight_Charge__c = 'Standard';
        agreementList.add(oAgreement1);
        insert agreementList;    
        
        Test.startTest();
        BatchUpdateAgreementConLength obj =new BatchUpdateAgreementConLength();
        Database.executeBatch(obj);
        BatchUpdateAgreementAwardDt objVar =new BatchUpdateAgreementAwardDt();
        Database.executeBatch(objVar);
        Test.stopTest();
        List<Apttus__APTS_Agreement__c> oAgreementList = [SELECT Id, Name, Date_awarded__c, Tenders_Status__c, Sales_Org__c, Total_contract_length_with_extension__c, Apttus__Subtype__c, Reason_for_Non_Compliance__c FROM Apttus__APTS_Agreement__c WHERE Record_Type__c = 'Tender'];
	     for(Apttus__APTS_Agreement__c nonCompliantVar : oAgreementList) {
           if(nonCompliantVar.Name == 'Test Agreement - Total contract length blank' && nonCompliantVar.Total_contract_length_with_extension__c == null)
              System.assert(String.isNotBlank(nonCompliantVar.Reason_for_Non_Compliance__c), 'Total contract length blank');
            else if(nonCompliantVar.Name == 'Test Agreement - Award date not specified' && nonCompliantVar.Date_awarded__c == null && nonCompliantVar.Tenders_Status__c == 'In Effect/Won')
              System.assert(String.isNotBlank(nonCompliantVar.Reason_for_Non_Compliance__c), 'Award date not specified');}
        }
    }
}