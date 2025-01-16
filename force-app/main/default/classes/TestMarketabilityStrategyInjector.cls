/**
 *   @author: Deep Diwakar
*    @date:   Aug-23-2023
*    @description: Test class for MarketabilityStrategyInjector class
*    Modification Log:
*    --------------------------------------------------------------------------------------------------
*          Developer           Date                 Description
*         Deep Diwakar       Aug-23-2023        DCP-60131: Initial version
*    --------------------------------------------------------------------------------------------------
 */

@IsTest
private class TestMarketabilityStrategyInjector {

    @IsTest
    static void testInputMarketabilityStrategy() {
        Test.startTest();
        IMarketabilityStrategy strategyInstance = (IMarketabilityStrategy) MarketabilityStrategyInjector.getMarketabilityStrategy('global-v1');
        Test.stopTest();

        Assert.isInstanceOfType(strategyInstance, GlobalMarketabilityStrategyV1.class, 'Instance type did not match');
    
    }

    @IsTest
    static void testEmptyScenario() {
        Test.startTest();
        IMarketabilityStrategy strategyInstance = (IMarketabilityStrategy) MarketabilityStrategyInjector.getMarketabilityStrategy('');
        Test.stopTest();

        Assert.isInstanceOfType(strategyInstance, GlobalMarketabilityStrategyV1.class, 'Instance type did not match');
    
    }

    @IsTest
    static void testIncorrectStrategyNameScenario() {
        Test.startTest();
        IMarketabilityStrategy strategyInstance = (IMarketabilityStrategy) MarketabilityStrategyInjector.getMarketabilityStrategy('Negative Test');
        Test.stopTest();

        Assert.isInstanceOfType(strategyInstance, GlobalMarketabilityStrategyV1.class, 'Instance type did not match');
    
    }

}