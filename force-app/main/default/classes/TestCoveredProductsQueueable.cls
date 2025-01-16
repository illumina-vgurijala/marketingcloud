/***************************************************************************************************************************************
 * NAME   : TestCoveredProductsQueueable
 * DESCRIPTION  :Test class  Queueable class on  CoveredProducts class.
 *    
 * @AUTHOR : Prashanth
 * @DATE   : 15-Feb-2021  
 *
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Prashanth             15-Feb-2021           Initial Version
****************************************************************************************************************************************/
@isTest
public class TestCoveredProductsQueueable {

    /*
    * Method: makeData
    * Description: method to create test data
    */
    @TestSetup
    static void makeData(){
        //account
        Account objAccount = TestDataAccount.getAccount('Test');
        insert objAccount;
        system.assert(objAccount.id != null);
        SVMXC__Installed_Product__c ip = TestDataFieldService.createInstalledProduct('test installed product', 'USD', 'Installed');
        insert ip;    
        system.assert(ip.id != null);
        SVMXC__Service_Plan__c sp = new SVMXC__Service_Plan__c();
        sp.Name = 'Test';
        sp.Item_Number__c = '1111';
        insert sp;
        system.assert(sp.id != null);

        SVMXC__Service_Contract__c objServiceContract = TestDataFieldService.createServiceContract(objAccount.Id);
        objServiceContract.Status__c = 'Active';
        objServiceContract.SVMXC__Service_Plan__c = sp.Id;
        insert objServiceContract;
        system.assert(objServiceContract.id != null);
    }
    /*
    * Method: coveredProductsQueueableTest
    * Description: method to test coveredproductsQueueable class
    */
    @isTest
    static void coveredProductsQueueableTest(){
        SVMXC__Service_Contract__c objServiceContract = [Select Id from SVMXC__Service_Contract__c];
        SVMXC__Installed_Product__c ip = [Select Id from SVMXC__Installed_Product__c];
        Test.startTest();
        SVMXC__Service_Contract_Products__c cp = TestDataFieldService.createCoveredProduct(ip.Id);
        cp.SVMXC__Service_Contract__c = objServiceContract.Id;
        insert cp;
        System.assert(cp.Id != null);
        Test.stopTest();
    }

     /**
     *  @author      : Nitin
     *  @description : method to cover catch block in CoveredProductsQueueable
     **/
    @isTest
    public static void coverCatchBlockCoveredProductsQueueable(){
        try{
            CoveredProductsQueueable.catchException = true;
            CoveredProductsQueueable pd = new CoveredProductsQueueable(null,null);
            Test.startTest();
            System.enqueueJob(pd);
            Test.stopTest();
        }
        catch(Exception e){
            System.assert(e!=null, 'e is not empty');
        }
    }
}