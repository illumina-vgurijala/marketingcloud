/*@ author       : Deepesh Malhotra
* @ date         : 12-12-2018
* @ Description  : Test class for batch to update child CORS TERRITORY REGION
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Deepesh Malhotra          12-12-2018                 Initial version
*/

@isTest
public class TestBatchContractOrderPopulateRegion {

    
     @testSetup
    static void initializeData(){
        User u = new User(
             ProfileId = [SELECT Id FROM Profile WHERE Name = 'Customer Service'].Id,
             LastName = 'last',
             Email = 'puser000@amamama.com',
             Username = 'puser000@amamama.com' + System.currentTimeMillis(),
             CompanyName = 'TEST',
             Title = 'title',
             Alias = 'alias',
             TimeZoneSidKey = 'America/Los_Angeles',
             EmailEncodingKey = 'UTF-8',
             LanguageLocaleKey = 'en_US',
             LocaleSidKey = 'en_US'
             
        );
        insert u;
        system.assertnotEquals(null,u.Id);
        
    } 
 /**
    *  @author Deepesh Malhotra
    *  @description Test method for update region fields on CORS
    **/
    static testmethod void testPriceListUpdate(){
        initializeData();
        Set<Id> setUpdatedAccountIds = new Set<Id>();
         
        Account acc = TestDataAccount.getAccount('Test Acc', 'USD');
        acc.Account_Group__c='Distributor';
        acc.Territory_Region__c = 'AMR';
        insert acc;
        system.assertnotEquals(null,acc.Id);
        setUpdatedAccountIds.add(acc.Id);
       
        Opportunity opp = TestDataOpportunity.getNewOpportunity(acc);
        
        Product2 objProduct=TestDataFieldService.createProduct('Test Product','Instrument');
        //objProduct.Auto_Create_Install_Work_Order__c = true;
        objProduct.Auto_Create_Installation_Workflow__c = 'Auto Create Install Work Order and Service Request Case';
        objProduct.Service_Product_Type__c = 'Instrument';
        insert objProduct;
        system.assertnotEquals(null,objProduct.Id);

        
        Apttus_Config2__Order__c orders=new Apttus_Config2__Order__c();
        orders.ASOP_Number__c = '0001';
        orders.Ultimate_Consignee__c = acc.Id;
        orders.Apttus_Config2__RelatedOpportunityId__c=opp.Id;
        orders.Apttus_Config2__OrderReferenceNumber__c = '1234';
        insert orders;
         system.assertnotEquals(null,orders.Id);
        
        Contract_Order_Routing_Sheet__c objCORS = new Contract_Order_Routing_Sheet__c();
        objCORS.Opportunity__c = opp.Id;
        objCORS.Order__c = orders.Id;
        objCORS.Additional_Notes__c = 'test notes';
        objCORS.Rev_Rec_Code__c = 'ACD: Acceptance Upon Delivery';
        objCORS.Account__c = acc.Id;
        insert objCORS;
        system.assertnotEquals(null,objCORS.Id);
        
        BatchContractOrderPopulateRegion batch = new BatchContractOrderPopulateRegion(setUpdatedAccountIds);

        Test.startTest();   
            DataBase.executeBatch(batch,3);             
        Test.stopTest();
        
         List<Contract_Order_Routing_Sheet__c> lstContracts = [SELECT Id, Name, Sold_To_Account_Region__c, Ultimate_Consignee_Region__c,Account__c,Ultimate_Consignee__c FROM Contract_Order_Routing_Sheet__c];
        
         for(Contract_Order_Routing_Sheet__c con : lstContracts){
            if(con.Account__c == acc.Id){
              
              System.assertEquals('AMR',con.Sold_To_Account_Region__c);
            }
        }

    }

    
    
}