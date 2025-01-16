/**
 * Test data for the org such as custom settings
 * 
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * Pooja                    23-09-2022          CodeScan Fixes
 * --------------------------------------------------------------------------------------------------------------------------------------
 **/
 @isTest
public with sharing class TestDataOrg {

    /*
    *@actor illumina
    *@Description :method to load Apex Settings for test class
    */		
    public static void loadCSApexSettings()
    {
        //List<sObject> ls = Test.loadData(cs_Apex_Settings__c.sObjectType, 'ilmn_testdata_apex_settings');
        List<cs_Apex_Settings__c> records = new List<cs_Apex_Settings__c>();
        records.add(new cs_Apex_Settings__c(
            SetupOwnerId = UserInfo.getOrganizationId(),
            Bypass_All_Triggers__c = false
        ));
        insert records;
    }
	
	/*
    *@actor illumina
    *@Description: method to load Service Document Settings for test class
    */			
    public static void createSettings(){
        Service_Document_Setting__c objTypeSetting = Service_Document_Setting__c.getInstance();
        objTypeSetting.LinkedEntitySObjectName__c = 'SVMXC__Service_Order__c';
        List<sObject> lstSettingToInsert = new List<SObject>();
        lstSettingToInsert.add(objTypeSetting);
        insert lstSettingToInsert;
    }

}