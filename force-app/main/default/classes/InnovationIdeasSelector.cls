/**
*    Description - Class to get the Idea(Innohub) records 
*    Modification Log:
*    @Test Class: TestIdeaCreationComponentController, TestIdeaKnowledgeController
*   ------------------------------------------------------------------------------------------------------------
*    Developer                      Date                		Description
*    Rishab Wali                    25nd Feb 2022              DCP-52334 Create front end search 
*    Deep Diwakar                   Oct 07 2024                CMCM-101047: Added selector method to fetch ideas filtered by idea ids
*    -----------------------------------------------------------------------------------------------------------
*/
public without sharing class InnovationIdeasSelector extends ilib_SObjectSelector {
   
    public static final String MARKETING_QUERY_LOGS = 'MarketingQueryLogs';
    public static final string LOG_TITLE = 'InnovationIdeasSelector';
    
    /*Constructor */
    public InnovationIdeasSelector() {
    	super(false, false, false, false);
    }
    
    /*
    * @author Rishab Wali
    * @date   02-25-2022
    * @description  describe the object
    *
    */
    public Schema.SObjectType getSObjectType() {
        return innohub__Innovation_Idea__c.sObjectType;
    }
    
    /*
    * @author Rishab Wali
    * @date   02-25-2022  
    * @description  set Id and Name
    */
    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField> {
            innohub__Innovation_Idea__c.Id   
        };
    }
	
    /**
    * method:getAllRecords
    * params: None
    *  @description - [DCP-52334]Retreive all records of Idea Object
    *  @return list of account contact relations
    * 
    **/
    public List<innohub__Innovation_Idea__c> getAllRecords() {
        ilib_LogQuery logger = null;

        if (Feature.isOn(MARKETING_QUERY_LOGS)){
            logger = new ilib_LogQuery(LOG_TITLE + '.getAllRecords','No Input Param');
        }
        
        List<innohub__Innovation_Idea__c> lstIdeas = Database.query(newQueryFactory().selectField('Name').setLimit(50000).toSOQL());
        
        if(Feature.isOn(MARKETING_QUERY_LOGS)){
            logger.stop(lstIdeas.size());
        }
        return lstIdeas;
    }

    /**
     * @author     : Deep Diwakar
     * @param      : Set of Idea ids
     * @return     : List of innovation Idea records
     * @Description: retuns list of innovation idea records filtered by idea ids
    **/
    public List<innohub__Innovation_Idea__c> selectIdeasById(Set<Id> setIdeaIds) {
        ilib_LogQuery logger = null;

        if (Feature.isOn(MARKETING_QUERY_LOGS)){
            logger = new ilib_LogQuery(LOG_TITLE + '.selectIdeasById',UtilsCollection.serializeIds(setIdeaIds));
        }
        
        List<innohub__Innovation_Idea__c> lstIdeas = Database.query(newQueryFactory()
                                        .selectField('Name')
                                        .selectField('Sub_Category__c')
                                        .selectField('Category__c')
                                        .selectField('CreatedDate')
                                        .selectField('CreatedBy.Name')
                                        .setCondition('Id IN : setIdeaIds')
                                        .setLimit(1000).toSOQL());
        
        if(Feature.isOn(MARKETING_QUERY_LOGS)){
            logger.stop(lstIdeas.size());
        }
        return lstIdeas;


    }
    
}