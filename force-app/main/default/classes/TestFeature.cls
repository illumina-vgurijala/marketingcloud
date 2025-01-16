/**  
*    @description  Test class for Feature
*    Modification Log:
*    --------------------------------------------------------------------------------------------------------------------------------------------
*           Developer                      Date                Description
*           Nishan                         10-Oct-2022         CodeScanFix [Method name should not start with Capital].
*    --------------------------------------------------------------------------------------------------------------------------------------------
**/
@isTest private class TestFeature {

    @IsTest
    private static void isOnNotConfiguredReturnsFalse() {//CodeScanIssue Fix
        Boolean isOn;
        System.Test.startTest();
        isOn = Feature.isOn('TestFeature');
        System.Test.stopTest();
        System.assertEquals(false, isOn);
    }

    @IsTest
    private static void isOnMockedTrueReturnsTrue() {//CodeScanIssue Fix
        Feature.setMockFeatureFlag('TestFeature', true);
        Boolean isOn;
        System.Test.startTest();
        isOn = Feature.isOn('TestFeature');
        System.Test.stopTest();
        System.assertEquals(true, isOn);
    }

    @IsTest
    private static void isOnMockedFalseReturnsFalse() {//CodeScanIssue Fix
        Feature.setMockFeatureFlag('TestFeature', false);
        Boolean isOn;
        System.Test.startTest();
        isOn = Feature.isOn('TestFeature');
        System.Test.stopTest();
        System.assertEquals(false, isOn);
    }

}