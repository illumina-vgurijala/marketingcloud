/***************************************************************************************************************************************
 * NAME   : TestPartsRequestSelector
 * DESCRIPTION  : TestClass for PartsRequestSelector class.
 *    
 * @AUTHOR : Prashanth
 * @DATE   : 30-Aug-2021
 *
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Prashanth             30-Aug-2021             Initial Version
 * Dhairya               19-Sep-2024             No change
  ***************************************************************************************************************************************
*/
@isTest
public class TestPartsRequestSelector {
    /**
      *  @author Prashanth
      *  @description - test the PartsRequestSelector class.
    **/
    public testMethod static void selectPartsRequestByIdTest()
    {
        Account testAccount = TestDataAccount.getNewAccount();
        
        List < SVMXC__Site__c > locationList = new List < SVMXC__Site__c > ();
        SVMXC__Site__c sourceLocation = new SVMXC__Site__c();
        sourceLocation.Name = 'source location';
        sourceLocation.SVMXC__Account__c = testAccount.Id;
        sourceLocation.SVMXC__Stocking_Location__c = true;
        locationList.add(sourceLocation);

        //Create Destination Location
        SVMXC__Site__c destinationLocation = new SVMXC__Site__c();
        destinationLocation.Name = 'destination Location';
        destinationLocation.SVMXC__Account__c = testAccount.Id;
        destinationLocation.SVMXC__Stocking_Location__c = true;
        locationList.add(destinationLocation);
        insert locationList;

        //Create Parts Request
        SVMXC__Parts_Request__c partsRequest = new SVMXC__Parts_Request__c();
        partsRequest.SVMXC__Requested_From__c = sourceLocation.Id;
        partsRequest.SVMXC__Required_At_Location__c = destinationLocation.Id;
        insert partsRequest;
        
        Set<Id> setPartsRequest = new Set<Id>();
        setPartsRequest.add(partsRequest.Id);
        
        Test.startTest();
        PartsRequestSelector selector = new PartsRequestSelector();
        List<SVMXC__Parts_Request__c> lstPartsRequest = selector.selectPartsRequestById(setPartsRequest);
        System.assert(lstPartsRequest.size()!=null);
        Test.stopTest();
        
    }
}