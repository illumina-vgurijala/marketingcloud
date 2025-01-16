/**
 *   @author: Deep Diwakar
*    @date:   Aug-10-2023
*    @description: Dependency injector class for Marketing waterfall service
*    @Test Class: TestMktgWaterfallOpptySrvcInjector, TestMktgWaterfallOpptyContactRoles
*    Modification Log:
*    --------------------------------------------------------------------------------------------------
*          Developer           Date                 Description
*         Deep Diwakar       Aug-10-2023        DCP-60131: Initial version
*    --------------------------------------------------------------------------------------------------
 */

 public with sharing class MktgWaterfallOpptySrvcInjector {
    private static final String DEFAULT_SERVICE = 'Default';
    private static final String DEFAULT_IMPL_CLASS = 'MktgWaterfallOpptySrvc';


    /**
     * @author: Deep Diwakar
     * @date: Aug-10-2023
     * @description: This method determines current instance of waterfall service call based on input param
     * @param: serviceName - Name of waterfall service whose instance is needed
     * @return: Instance of waterfall service class
     */
    public static Object getWaterfallOpptyService(String serviceName) {
        String currentService = serviceName;
        String impClassName;

        // if empty or null string is passed then use default service
        if (String.isBlank(serviceName)) {
            currentService = DEFAULT_SERVICE;

        }

        List<Marketing_Waterfall_Opportunity_Service__mdt> serviceList = new List<Marketing_Waterfall_Opportunity_Service__mdt>();
        
        if (Schema.sObjectType.Marketing_Waterfall_Opportunity_Service__mdt.isAccessible()) {
            serviceList = [SELECT Id, DeveloperName, Service_Name__c, Implementation_Class__c 
                            FROM Marketing_Waterfall_Opportunity_Service__mdt 
                            WHERE Service_Name__c =: currentService 
                            LIMIT 1];
        }


        if (serviceList.isEmpty()) {
            // if incorrect service name is passed then use default service
            impClassName = DEFAULT_IMPL_CLASS;
        } else {
            impClassName = serviceList.get(0).Implementation_Class__c;
        }

        Type t = Type.forName(impClassName);

        return t.newInstance();

    }

}