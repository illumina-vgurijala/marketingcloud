/**
 * NAME   : TestCodeLibrary
 * DESCRIPTION  : TestClass for Code_Library__c: After Insert and Update Flow
 * @AUTHOR : Dhairya Shah
 * @DATE   : 2-December-2024 
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | December 3, 2024 |   | Initial Version
**/
@isTest(seeAllData = false)
public class TestCodeLibrary {
	public static final string STRING_CODE_LIB_CODE_TITLE = 'TEST INQ CS Resolution Subject code';
    public static final string STRING_CODE_LIB_CODE_TYPE = 'Resolution';
	
	static testMethod void testCodeLibraryMethod() {
		Code_Library__c coLib = TestDataFieldService.createCodeLibraryRec(STRING_CODE_LIB_CODE_TITLE,STRING_CODE_LIB_CODE_TYPE);
        Test.StartTest();
		insert coLib;
        Test.StopTest();

        Code_Library__c coLibRetrieved = [SELECT Code_ID__c,Code_Number__c FROM Code_Library__c WHERE Id = :coLib.Id];
        System.assertEquals('RES-'+coLibRetrieved.Code_Number__c, coLibRetrieved.Code_ID__c,'Code ID should be RES + Code_Number__c');
    }
}