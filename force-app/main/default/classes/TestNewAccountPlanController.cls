/**
*    @author: Kushagra Desai
*    @date:   07-AUg-2019
*    @description:  Test class for Controller class of NewAccountPLan Component
*    Modification Log:
*    -----------------------------------------------------------------------------------
*             Developer                      Date                Description
*    ------------------------------------------------------------------------------------ 
*                    
*/
@isTest
public with sharing class TestNewAccountPlanController {
    /**
     *  @author Kushagra Desai
     *  @description  
     **/
    @isTest
    static void testgetAccountDetails()
    {
        Account acc = TestDataAccount.getAccount('TestAccount');
        insert acc;
        System.assertEquals('{"TerritoryRegion":null,"AccountName":"TestAccount"}',NewAccountPlanController.getAccountDetails((String)acc.id));
        System.assertEquals(true,NewAccountPlanController.getActiveplan((String)acc.id));
    }
}