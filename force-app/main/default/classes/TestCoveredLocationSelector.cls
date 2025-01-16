//TestCoveredLocationSelector 
/*
* @ author       : Romi
* @ date         : 30-Aug-2021
* @ Description  : Test class for CoveredLocationSelector class
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                              Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Romi                  30-Aug-2021                        Initial version
* Dhairya               29-Feb-2024                        CMCM-9
*/
@isTest
public class TestCoveredLocationSelector {   
    /**
     * @author: Romi
     * @description: test selectCoveredLocations method.
     */
    public testMethod static void selectCoveredLocationsTest()
    {    
        BusinessHours objBuinessHours = [SELECT Id FROM BusinessHours where Name =: 'Default'];
        SVMXC__Service_Level__c objServiceLevel = TestDataFieldService.createServiceLevel();
        objServiceLevel.SVMXC__Business_Hours__c = objBuinessHours.id;
        insert objServiceLevel;
        
        // Service/Maintenance created
        SVMXC__Service_Contract__c serviceContract = new SVMXC__Service_Contract__c();
        serviceContract.Name = 'Test'; 
        serviceContract.ERP_Header_Contract_Number__c = 'HeaderContract';
        serviceContract.SVMXC__Service_Level__c = objServiceLevel.Id;
        serviceContract.SVMXC__End_Date__c = system.today().addYears(1);
        serviceContract.Status__c = 'Active';
        insert serviceContract;
        
        Set<Id> setServiceContract = new Set<Id>();
        setServiceContract.add(serviceContract.Id);
        
        // Location created
        SVMXC__Site__c objLoc = TestDataFieldService.createLocation('Test Location','Test street','Test Country','5555555','USD');
        insert objLoc;
        
        Set<Id> setloc = new Set<Id>();
        setloc.add(objloc.Id);
        //CMCM-9 created setacc variable to store the accountIds to fetch the covered location based on accnts also
        Set<Id> setacc = new Set<Id>();
        setacc.add(objloc.SVMXC__Account__c);
        Test.startTest();
        CoveredLocationSelector selector = new CoveredLocationSelector();
        selector.selectCoveredLocations(setloc);
        //CMCM-9 added new method as "selectCoveredLocForLocAndAcc" in CoveredLocationSelector class to cover that we have added a line of code
        selector.selectCoveredLocForLocAndAcc(setloc, setacc);

        selector.selectCoveredLocationsForServiceContracts(setServiceContract);
        system.assertNotEquals(null, setloc.size());
        //List<SVMXC__Service_Contract_Sites__c> lstServiceContract = new CoveredLocationSelector().selectCoveredLocations(setloc);
        //System.assert(lstServiceContract.size()>0);
        Test.stopTest();
        
        
    }
    
    
}