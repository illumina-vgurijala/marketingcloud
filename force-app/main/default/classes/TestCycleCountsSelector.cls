//TestCycleCountsSelector 
/*
* @ author       : Romi
* @ date         : 27-Aug-2021
* @ Description  : Test class for CycleCountsSelector class
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                              Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Romi                  27-Aug-2021                        Initial version
*/
@IsTest
public class TestCycleCountsSelector {
    
    static testMethod void testSelectCycleCountWithWO(){
        //insert Account
        Account acc = TestDataAccount.getAccount('Test Acc', 'USD');
        acc.Account_Group__c='Distributor';
        acc.ERP_Customer_Id__c = 'Test1';
        insert acc;
        System.assert(acc.Id != null);
        
        //insert contact
        Contact con = TestDataPerson.getNewContact(acc.Id);
        System.assert(con.id != null);
        
        //insert case
        Case cs = TestDataCase.initServiceRequestCase(con);
        insert cs;
        System.assert(cs.Id != null);
       
        SVMXC__Service_Order__c workOrder2= TestDataFieldService.createWorkOrder('Field Service', cs.Id, 'Initiated');
        workOrder2.SVMXC__Company__c=acc.id;
        workOrder2.Is_Auto_Created__c = true;
        insert workOrder2;
        System.assert(workOrder2.Id != null);
        Set<Id> workOrderSet= new Set<Id>();
        workOrderSet.add(workOrder2.id);
        
        Cycle_Count__c cycleCountObj= new Cycle_Count__c();
        cycleCountObj.Work_Order__c=workOrder2.id; 
        insert cycleCountObj;
           
        Test.startTest();
        List<Cycle_Count__c> lstCC = new CycleCountsSelector().selectCycleCountWithWO(workOrderSet);
        System.assert(lstCC.size() > 0); 
        Test.stopTest(); 
    }
}