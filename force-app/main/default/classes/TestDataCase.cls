/***************************************************************************************************************************************
 * NAME   : TestDataCase
 * DESCRIPTION  : 
 *    
 * @AUTHOR : 
 * @DATE   :   
 *
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 *                                            Initial Version
 * Rohan                23-Mar-2022           DCP-49682
  ****************************************************************************************************************************************/ 

/**
* Case and associated records
**/
@isTest
public with sharing class TestDataCase {
    
    /*
    * Method to create new Compliant Case
    */	
    public static Case getNewComplaintCase(Contact con)
    {
        Case c = initComplaintCase(con);
        insert c;
        return c;
    }

	/*
    * Method to initialize new Compliant Case
    */			
    public static Case initComplaintCase(Contact con)
    {
        String rand = TestData.getRandom();
        
        // TODO: add appropriate values
        Case c = new Case(
            AccountId = con.AccountId,
            ContactId = con.Id,
            Status = 'Monitoring',
            Type = 'Complaint',
            Subject = rand,
            Origin = 'Phone'
        );
        return c;
    }
    
    /*TODO: add other case types*/
    public static Case initServiceRequestCase(Contact con)
    {
        String rand = TestData.getRandom();
        
        Id idCaseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Service Request').getRecordTypeId();
        
        // TODO: add appropriate values
        Case c = new Case(
            AccountId = con.AccountId,
            ContactId = con.Id,
            Status = 'New',
            Subject = rand,
            Origin = 'Phone',
            RecordTypeId = idCaseRecordTypeId
        );
        return c;
    }
    
    /*
*  @AUTHOR:  Debalina   
*  @DESCRIPTION:This method creates case
*  @PARAM :  String strRecordTypeName, String strStatus, Id idContact
*  @RETURN:  Case type object
*/
    public static Case createCase(String strRecordTypeName, String strStatus, Id idContact)
    {
        Id idCaseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get(strRecordTypeName).getRecordTypeId();
        Case objCase = new Case(
            RecordTypeId = idCaseRecordTypeId,
            Status = strStatus,
            ContactId = idContact
        );
        insert objCase;
        return objCase;
    }
        /*
*  @AUTHOR:  Soumya   
*  @DESCRIPTION:This method creates case
*  @PARAM :  String strRecordTypeName, String strStatus, String strCaseOrigin
*  @RETURN:  Case type object
*/
    public static Case initNewCase(String strRecordTypeName, String strStatus, String strCaseOrigin)
    {
        String rand = TestData.getRandom();
        
        Id idCaseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get(strRecordTypeName).getRecordTypeId();
        
        Case c = new Case(
            
            Status = strStatus,
            Subject = rand,
            Description= rand,
            Origin = strCaseOrigin,
            RecordTypeId = idCaseRecordTypeId
        );
        return c;
    }     
}