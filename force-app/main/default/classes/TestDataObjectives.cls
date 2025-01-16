/**
*    @author: Kushagra Desai
*    @date:   19-Sept-2019
*    @description:  Test data creation for Objective
*    Modification Log:
*    -----------------------------------------------------------------------------------
*             Developer                      Date                Description
*    ------------------------------------------------------------------------------------ 
*                    
*/
@isTest
public with sharing class TestDataObjectives {
    /*
    *@author: Kushagra Desai
    *@Desc: Method to get new Objective__c Record
    */
    public static Objective__c getNewObjective(Account_Plan__c ap)
    {
        Objective__c ob  = initObjective(ap.Id);
        insert ob;
        return ob;
    }
	/*
    *@author: Kushagra Desai
    *@Desc: Method to get new Objective__c Record with Account_plan__c and rest other field as defaults
    */
    public static Objective__c initObjective(String apId){
        Objective__c ob =  new Objective__c();
        ob.Name = 'Test Objective';
        ob.Account_Plan__c = apId;
        return ob;
    }
}