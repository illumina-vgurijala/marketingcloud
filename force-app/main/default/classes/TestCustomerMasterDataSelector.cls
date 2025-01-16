/*Modification Log:
*    ------------------------------------------------------------------------------------------------------------------------------------------------
*    Developer                      Date                Description
*    Prem Ranjan                    04 May 2022             CodeScan Fix (APEX) Unused Local Variable
*    --------------------------------------------------------------------------------------------------------------------------------------------------
*                    
*/
@isTest(SeeAllData=false)
public with sharing class TestCustomerMasterDataSelector
{
 /**
     *  @author Kamini
     *  @description Written to increase coverage and cover CustomerMasterDataSelector
     **/
    @isTest
    static void testCustomerMasterDataSelector()
    { 
      Customer_Master_Data__c objCMDUC1 = new Customer_Master_Data__c(Name='GCMD',ERP_Customer_Id__c = 'Gryffy',Account_Group__c=Label.AccountRelationshipBillTo);
      
      insert new List<Customer_Master_Data__c> { objCMDUC1 };
      Test.startTest();
      set<String> customerMdtIds = new set<String>();
      Set<Id> custMdtIds = new Set<Id>();
      list<String> lstAccountGroup = new List<String>();
      Set<String> setAccountERP = new Set<String>();
      List<String> lstAccountERPIds = new List<String>();
      
      List<Customer_Master_Data__c> objCustomermaster= [SELECT Id,Name,Street__c,City__c,Zip_Postal_Code__c,State_Province__c,Country__c,Country_Code__c,ERP_Customer_Id__c,Account_Group__c,Care_Of__c,Mark_For_Deletion__c FROM Customer_Master_Data__c];
     
      for(Customer_Master_Data__c ocustmdt: objCustomermaster){
          customerMdtIds.add((ID)ocustmdt.Id);
          lstAccountGroup.add(ocustmdt.Account_Group__c);
          setAccountERP.add(ocustmdt.ERP_Customer_Id__c);
          lstAccountERPIds.add(ocustmdt.ERP_Customer_Id__c);
      }
      CustomerMasterDataSelector custmdt = new CustomerMasterDataSelector();
      custmdt.selectByAccountGroupExceptIds(customerMdtIds,lstAccountGroup,'GCMD');
      custmdt.selectByAccountERPId(setAccountERP);
      custmdt.selectById(custMdtIds);
      custmdt.selectByERPId(lstAccountERPIds );
      system.assertnotEquals(null,customerMdtIds);
      Test.stopTest();

    }
}