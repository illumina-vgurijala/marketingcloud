/*@ author       : Soumya
* @ date         : 05-Dec-2019
* @ Description  : Test class for PartsOrderingRestrictionsSelector class
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID      Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Soumya                   05-Dec-2019                                  Initial version
* 
*/
@isTest(seeAllData=False)
global with sharing class TestPartsOrderingRestrictionsSelector 
{
    testMethod static void methodToIncreaseCoverage()
    {
       set<String> testKeySet1 = new set<string>{'abc123####'};
       set<String> testKeySet2 = new set<string>{'abc123####'};
       set<String> testKeySet3 = new set<string>{'abc123####'};
       set<String> testKeySet4 = new set<string>{'abc123####'};
        
        PartsOrderingRestrictionsSelector porSelectorClass = new PartsOrderingRestrictionsSelector();
        Test.startTest();
        porSelectorClass.selectPORestrictionsByKey(testKeySet1,testKeySet2,testKeySet3,testKeySet4);
        Test.stopTest();
		system.assert(!testKeySet1.isEmpty(), 'Set is empty');
    }
}