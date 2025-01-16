/**
*    @author Sagar Madkaikar
*    @date   2021-09-27
*    @description  CMCP-81:Test Class for ProactiveDynamicComponentController
*    Modification Log:
*    ---------------------------------------------------------------------------------------------------------------------------
*         Developer                      Date                Description
*         Sagar Madkaikar              27-Sep-2021         InitialVersion
*    ------------------------------------------------------------------------------------------------------------------------------
**/
@IsTest
public class TestProactiveDynamicComponentController {

    /**
    *  @author  Sagar Madkaikar
    *  @description - test method for getCurrentRecordDetails
    **/
    static testMethod void testGetCurrentRecordDetails() {
       
        test.startTest();
        //Insert IP
        SVMXC__Installed_Product__c recIP = new SVMXC__Installed_Product__c();
        recIP.SVMXC__Serial_Lot_Number__c = '000Test';
        insert recIP;

        String str = ProactiveDynamicComponentController.getCurrentRecordDetails(recIP.Id,'Installed Products');
        System.assertEquals('000Test',str,'Serial lot Number');
        test.stopTest();
    }
    
     /**
    *  @author  Sagar Madkaikar
    *  @description - test method for testGetCurrentRecordDetailsException
    **/
    static testMethod void testGetCurrentRecordDetailsException() {
       
        test.startTest();
        try {
             ProactiveDynamicComponentController.getCurrentRecordDetails(null,'Installed Products');
        } catch (Exception e) {
            System.assertEquals('Script-thrown exception',e.getMessage(),'Unhandled Error');
        }
        test.stopTest();
        
    }
    
}