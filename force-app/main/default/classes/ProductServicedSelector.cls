/*
 *    @author Romi Taskar
 *    @date   15-06-2022
 *    @description    Class to get the Product Serviced records based on different conditions
 *    Modification Log:
 *    ------------------------------------------------------------------------------------ 
 *    Developer              Date                    Description
 *    Romi                 15-June-2022             Initial Version
 *    ------------------------------------------------------------------------------------
 */
public with sharing class ProductServicedSelector extends ilib_SObjectSelector{

    private static final String LOG_TITLE = 'TechniciansSelector';
    private static final String FEATURE_SERVICE_QUERY_LOGS = 'ServiceQueryLogs';

    /*  @author - Romi Taskar
     *  @description  - Initialization of the Product Serviced object
     *  @return - SObjectType The Schema.SObjectType of the proposal
     */
    public Schema.SObjectType getSObjectType()
    {
        return SVMXC__Service_Group_Product__c.sObjectType;
    }

    /**
     *  @author - Romi Taskar
     *  @description - Retrieve list of fields for Product Serviced object 
     *  @return - sObjectFieldList list of Schema.SObjectField
     */
    public List<Schema.SObjectField> getSObjectFieldList()
    { 
       return new List<Schema.SObjectField> {
        SVMXC__Service_Group_Product__c.Id,
        SVMXC__Service_Group_Product__c.Name,
        SVMXC__Service_Group_Product__c.SVMXC__Service_Group__c,
        SVMXC__Service_Group_Product__c.SVMXC__Group_Member__c,
        SVMXC__Service_Group_Product__c.SVMXC__Product_Family__c,
        SVMXC__Service_Group_Product__c.SVMXC__Product_Line__c,
        SVMXC__Service_Group_Product__c.SVMXC__Product__c,
        SVMXC__Service_Group_Product__c.Active_Certification__c,
        SVMXC__Service_Group_Product__c.Certification_Name__c,
        SVMXC__Service_Group_Product__c.Student_Certification_Acquired_On__c,
        SVMXC__Service_Group_Product__c.Student_Certification_Due_Date__c  
        };
    }

    /**
     * @author - Romi Taskar
     * @description - Query to Field Support User which is related to Product Serviced.
     * @param - setWorkOrderIds -> Id of Work Orders
     */
    public List<SVMXC__Service_Group_Product__c> selectProductServicedRecs(set<Id> technicianIds, Set<Id> productIds) 
    {
        ilib_LogQuery logger=null;
        if (Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)){
            logger = new ilib_LogQuery(
                LOG_TITLE + '.selectTechnicians',
                UtilsCollection.serializeIds(technicianIds)
            );
        }
        List<SVMXC__Service_Group_Product__c> res = Database.query(
        newQueryFactory().selectField('Id')
                         .selectField('Name')
                         .selectField('SVMXC__Product_Family__c')
                         .selectField('SVMXC__Product__r.Name')
                         .selectField('Active_Certification__c')
                         .setCondition('SVMXC__Group_Member__c IN: technicianIds AND SVMXC__Product__c IN: productIds AND Active_Certification__c = true').toSOQL()
        );
                         
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)) {
            logger.stop(res.size());
        }
        return res;
    }

    /**
     * @author Venkatesh Prabhu
     * @description Method to fetch active certified technicians for the given technician ids
     * @param technicianIds 
     * @return  `List<SVMXC__Service_Group_Product__c>`
     */
    public List<SVMXC__Service_Group_Product__c> getCertifiedTechnicianProducts(set<Id> technicianIds) 
    {
        ilib_LogQuery logger=null;
        if (Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)){
            logger = new ilib_LogQuery(
                LOG_TITLE + '.selectTechnicians',
                UtilsCollection.serializeIds(technicianIds)
            );
        }
        List<SVMXC__Service_Group_Product__c> res = Database.query(
                        newQueryFactory()
                         .setCondition('SVMXC__Group_Member__c IN: technicianIds AND Active_Certification__c = true').toSOQL()
        );
                         
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)) {
            logger.stop(res.size());
        }
        return res;
    }

}