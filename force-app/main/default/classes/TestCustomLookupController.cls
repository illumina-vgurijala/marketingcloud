/**
*    @author: Kushagra Desai
*    @date:   16-Sept-2019
*    @description:  Test class for  CustomLookupController
*    Modification Log:
*    -----------------------------------------------------------------------------------
*             Developer                      Date                Description
*    ------------------------------------------------------------------------------------ 
*                    
*/
@isTest
public with sharing class TestCustomLookupController{
    @isTest
    static void findRecords(){
        Account acc = TestDataAccount.getAccount('TestAccount');
        insert acc;
        system.assert(!CustomLookupController.findRecords('Test','Account','Name').isEmpty(),'No records returned.');
    }
}