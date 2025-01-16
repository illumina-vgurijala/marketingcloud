/**
*    @author: Joshith K
*    @date:   30-Sep-2019
*    @description:  Test class for AccountPlanMobileNavController
*    Modification Log:
*    -----------------------------------------------------------------------------------
*             Developer                      Date                Description
*           Aman Tyagi                      12/12/2022          Codescan Fixes
*    ------------------------------------------------------------------------------------ 
*                    
*/
@isTest
public  class TestAccountPlanMobileNavController {
     @isTest
    static void testMobileNavController(){
        Account acc = TestDataAccount.getNewAccount();
         Account_Plan__c ap = TestDataAccountPlan.getNewAccountPlan(acc);
         AccountPlanMobileNavController.checkSessionCache(ap.Id);
        Account_Plan__c objAP= AccountPlanMobileNavController.getSessionCache();
        system.assertEquals(ap.id,objAP.id );


    }
}