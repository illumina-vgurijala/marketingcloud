/**
 *   @author: Deep Diwakar
*    @date:   Mar-06-2024
*    @description: Dependency injector class for Marketability strategy
*    @Test Class: TestMarketabilityStrategyInjector, TestMarketabilityServiceFacade
*    Modification Log:
*    --------------------------------------------------------------------------------------------------
*          Developer           Date                 Description
*         Deep Diwakar       Mar-06-2024        CMCM-5551: Initial version
*    --------------------------------------------------------------------------------------------------
 */

public with sharing class MarketabilityStrategyInjector {
    private static final String DEFAULT_STRATEGY = 'global-v1';
    private static final String DEFAULT_IMPL_CLASS = 'GlobalMarketabilityStrategyV1';


    /**
     * @author: Deep Diwakar
     * @date: Mar-06-2024
     * @description: This method determines current instance of marketability strategy based on input param
     * @param: strategy - Name of marketability strategy strategy whose instance is needed
     * @return: Instance of marketability strategy class
     */
    public static Object getMarketabilityStrategy(String strategy) {
        String currentStrategy = strategy;
        String impClassName;

        // if empty or null string is passed then use default strategy
        if (String.isBlank(strategy)) {
            currentStrategy = DEFAULT_STRATEGY;

        }

        List<Marketability_Strategy__mdt> strategyList = new List<Marketability_Strategy__mdt>();

        strategyList = [SELECT Id, DeveloperName, Strategy_Name__c, Implementation_Class__c 
                        FROM Marketability_Strategy__mdt 
                        WHERE Strategy_Name__c =: currentStrategy 
                        WITH SYSTEM_MODE
                        LIMIT 1];


        if (strategyList.isEmpty()) {
            // if incorrect strategy name is passed then use default strategy
            impClassName = DEFAULT_IMPL_CLASS;
        } else {
            impClassName = strategyList.get(0).Implementation_Class__c;
        }

        Type t = Type.forName(impClassName);

        return t.newInstance();

    }

}