/* Class - TestIdeaCreationComponentController
 * Description - TestClass for IdeaCreationComponentController and InnohubIdeasSelector Apex Class
*/
@isTest
public with sharing class TestIdeaCreationComponentController {
    
    /**
     * Method - To check records are inserted and returned via selector
     */
    @isTest
    public static void checkRecordCreationAndSelector() {
        test.startTest();
        innohub__Innovation_Idea__c objIdea = new innohub__Innovation_Idea__c(Name='Test Innovate',innohub__Category__c='Other',innohub__Description__c='Test Description');
        objIdea.Category__c = 'Idea Exchange';
		objIdea.Sub_Category__c = 'Other';
		insert objIdea;
        
        String strResult = IdeaCreationComponentController.getAllInnovationIdeaRecords();
        
        System.assert(strResult.contains(objIdea.Name),'No records returned');
        test.stopTest();
    }
    
    /**
     * Method - To check catch part
     */
    @isTest
    public static void checkRecordCreationAndSelectorCatch() {
        test.startTest();
        try {
            IdeaCreationComponentController.getAllInnovationIdeaRecords();
        }
        catch(Exception e) {
            System.debug(e.getMessage());
        }
        test.stopTest();
        List<Exception_Log__c> lstExceptionLog = [Select Id,Source__c,Message__c from Exception_Log__c 
												  WHERE Source__c = 'IdeaCreationComponentController.getAllInnovationIdeaRecords()'];
        System.assertEquals(1,lstExceptionLog.size(),'Exception Log not created');
    }
}