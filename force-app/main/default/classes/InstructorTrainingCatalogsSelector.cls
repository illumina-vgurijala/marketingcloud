/*@ author       	 : Shaik Moulali
    * @ date         : 10-04-2018
    * @ Description  : selector class for Instructor Training Catalog object
    *
    * Modification Log:
    * --------------------------------------------------------------------------------------------------------------------------------------
    * Developer                Date                   Modification ID      Description
    * ---------------------------------------------------------------------------------------------------------------------------------------
    * Prakhar Kumar          25-09-2018                                    Initial version
    * 
	*/
public with sharing class InstructorTrainingCatalogsSelector extends ilib_SObjectSelector{
     /*Param - sobjectList  */
	public Schema.SObjectType getSObjectType()
    {
        return Instructor_Training_Catalog__c.sObjectType;
    }
    
    /*
    * @author Shaik Moulali
    * @date   04-10-2018
    * @description  set select fields
    * 
    */
    public List<Schema.SObjectField> getSObjectFieldList()
    {
        return new List<Schema.SObjectField>{
            Instructor_Training_Catalog__c.Name,
            Instructor_Training_Catalog__c.Active__c,
            Instructor_Training_Catalog__c.Audience__c,
            Instructor_Training_Catalog__c.Certification__c,
            Instructor_Training_Catalog__c.Course_ID__c,
            Instructor_Training_Catalog__c.Description__c,
            Instructor_Training_Catalog__c.Duration_Days__c,
            Instructor_Training_Catalog__c.Pre_Requisites__c,
            Instructor_Training_Catalog__c.Pre_Work__c,
            Instructor_Training_Catalog__c.Region__c,
            Instructor_Training_Catalog__c.Training_Hours__c
        };
    }
    
		/*
         * description - to fectch the data of Instructor_Training_Catalog__c
		 * return - List of Instructor_Training_Catalog__c
         */ 	
    public List<Instructor_Training_Catalog__c> selectInstructorLedTrainingCourses(String strRegion) 
    {
        ilib_QueryFactory query = newQueryFactory();
        query.setCondition('Region__c = : strRegion AND Active__c = true');
        String strQuery = query.selectField('Certification__c')
            .selectField('Region__c')
            .selectField('Course_ID__c')
            .selectField('Duration_Days__c')
            .selectField('Training_Hours__c')
            .selectField('Audience__c')
            .selectField('Pre_Requisites__c')
            .selectField('Pre_Work__c')
            .selectField('Description__c')
        	.toSOQL();
        return Database.query(strQuery);
    }
    
}