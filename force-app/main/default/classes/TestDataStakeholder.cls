/**
* Stakeholder Record
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Vaibhav Sirohi                03 sept 2019         getNewStakehoder(Account, Account_Plan__c, Contact)
*             Satya Swain                   09 Dec 2022          Added Codescan fix for Variable Naming Convention                                                                      
*    ------------------------------------------------------------------------------------
**/
@isTest
public with sharing class TestDataStakeholder {
    /*
*  @AUTHOR:  Vaibhav Sirohi
*  @DESCRIPTION:This method creates Stakeholder
*  @PARAM :  Account acc ,Account_Plan__c ap,  Contact c
*  @RETURN:  Key_Stakeholder_Analysis__c object
*/
    
    public static Key_Stakeholder_Analysis__c getNewStakehoder( Account acc, Account_Plan__c ap,  Contact c)
    {
        Key_Stakeholder_Analysis__c stakeholder= new Key_Stakeholder_Analysis__c();
        stakeholder.Buying_Role__c ='Sponsor';
        stakeholder.Influence__c = 'High';
        stakeholder.Level_of_Support__c = 'High';
        stakeholder.Priority_Interests_Objectives__c = 'test';
        stakeholder.Pain_Points_Concerns__c = 'test';
        stakeholder.Current_Access__c = 'high';
        stakeholder.Account_Plan__c = ap.Id;
        stakeholder.Contact__c = c.Id;
        insert stakeholder;
        return stakeholder;
    }
    
}