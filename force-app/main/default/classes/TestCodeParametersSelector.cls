/**
* @author Shivani Jain
* @date 23 Nov 2022
*
* @description DCP-57074 Test class for CodeParametersSelector
*/
@IsTest
private class TestCodeParametersSelector {

    /*******************************************************************************************************
    * @description test selectCodeParameterByDeveloperName
    */
    static testmethod void testSelectorMethods() {
        Test.startTest();
        
        List<Code_Parameter__mdt> paramList= new CodeParametersSelector().selectCodeParameterByDeveloperNameLike('Required_TA');
        System.assert(!paramList.isEmpty(), 'Code Parameter not present in org');

        Set<String> cStringSet = new Set<String>();
        cStringSet.add('Attempt_auto_case_completion');
        cStringSet.add('Batch_Territory_Updates');
        List<Code_Parameter__mdt> paramList1= new CodeParametersSelector().selectCodeParameterByDeveloperName(cStringSet);
        System.assert(!paramList1.isEmpty(), 'Code Parameter not present in org');
        
        Test.stopTest();
    }
}
