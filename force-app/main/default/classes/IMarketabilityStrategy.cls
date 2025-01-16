/**
 *   @author: Deep Diwakar
*    @date:   Mar-05-2024
*    @description: Interface for Marketability Strategy logic
*    @Test Class: TestMarketabilityServiceFacade, TestMarketabilityStrategyInjector
*    Modification Log:
*    --------------------------------------------------------------------------------------------------
*          Developer           Date                 Description
*         Deep Diwakar       Mar-05-2024        CMCM-5551: Initial version
*    --------------------------------------------------------------------------------------------------
 */

public interface IMarketabilityStrategy {

    void calculateMarketability(List<sObject> lstSobjects);

}