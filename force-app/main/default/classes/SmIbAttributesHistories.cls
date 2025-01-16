/*
*  @Author:
*  @Date: 
*  @Description:
*  @Test Class for above 90% coverage.
*  @Test Class for atleast 75% coverage.
      -TestIBTechinalAttributeCreationQueuable
      -TestTAPS_SmaxIbAttributesHistory
*  Modification Log:
*   ------------------------------------------------------------------------------------ 
*    Developer                      Date                    Description
*  Nishan Shetty                 24-Aug-2022            DCP-44091 - Indirect Instantiation of Orchestrator Class for Performance Improvement.
*    ------------------------------------------------------------------------------------                  
*/
public with sharing class SmIbAttributesHistories extends ilib_SObjectDomain {

    

		/*
         * Constructor
         */
    public SmIbAttributesHistories(List<SVMXC__SM_IB_Attributes_History__c> sObjectList)
    {
        super(sObjectList);
    }
    /*
    * Boilerplate which is required for base class instantiation logic
    */
    public class Constructor implements ilib_SObjectDomain.IConstructable
    {
	    /*Param - sobjectList  */
        public ilib_SObjectDomain construct(List<SObject> sObjectList)
        {
            return new SmIbAttributesHistories(sObjectList);
        }
    }
	
		/*
         * description - onAfterInsert method
		 * return - void
         */ 
    public override void onAfterInsert()
    {   
        
    }

		/*
         * description - onAfterUpdate method
		 * return - void
         */ 
    public override void onAfterUpdate(Map<Id, sObject> existingRecords)
    {
       
		
    }

}