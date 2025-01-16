/**
 *   @author: Deep Diwakar
*    @date:   Aug-23-2023
*    @description: Test class for MktgWaterfallOpptySrvcInjector class
*    Modification Log:
*    --------------------------------------------------------------------------------------------------
*          Developer           Date                 Description
*         Deep Diwakar       Aug-23-2023        DCP-60131: Initial version
*    --------------------------------------------------------------------------------------------------
 */
@IsTest
private class TestMktgWaterfallOpptySrvcInjector {


    @IsTest
    static void testDefaultService() {
        Test.startTest();
        IMktgWaterfallOpptySrvc serviceInstance = (IMktgWaterfallOpptySrvc) MktgWaterfallOpptySrvcInjector.getWaterfallOpptyService('Default');
        Test.stopTest();

        Assert.isInstanceOfType(serviceInstance, MktgWaterfallOpptySrvc.class, 'Instance type did not match');
    
    }

    @IsTest
    static void testEmptyScenario() {
        Test.startTest();
        IMktgWaterfallOpptySrvc serviceInstance = (IMktgWaterfallOpptySrvc) MktgWaterfallOpptySrvcInjector.getWaterfallOpptyService('');
        Test.stopTest();

        Assert.isInstanceOfType(serviceInstance, MktgWaterfallOpptySrvc.class, 'Instance type did not match');
    
    }

    @IsTest
    static void testIncorrectServiceScenario() {
        Test.startTest();
        IMktgWaterfallOpptySrvc serviceInstance = (IMktgWaterfallOpptySrvc) MktgWaterfallOpptySrvcInjector.getWaterfallOpptyService('Negative Test');
        Test.stopTest();

        Assert.isInstanceOfType(serviceInstance, MktgWaterfallOpptySrvc.class, 'Instance type did not match');
    
    }

}