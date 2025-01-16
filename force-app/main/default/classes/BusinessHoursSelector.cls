/**
 *    @author Gautam Arya
 *    @date   2021-03-31
 *    @description    
 *    Modification Log:
 *    ------------------------------------------------------------------------------------ 
 *             Developer                      Date                Description
*              
 *    ------------------------------------------------------------------------------------ 
 *                    
 */
public with sharing class BusinessHoursSelector extends ilib_SObjectSelector
{
    

    /**
     *  @author  Gautam Arya 
     *  @description Retrieve list of fields for Business Hours sObject 
     *  @return sObjectFieldList list of Schema.SObjectField
     **/
    public List<Schema.SObjectField> getSObjectFieldList()
    {
       return new List<Schema.SObjectField> {
           BusinessHours.FridayEndTime,
		   BusinessHours.FridayStartTime,
		   BusinessHours.Id,
		   BusinessHours.IsActive,
		   BusinessHours.IsDefault,
		   BusinessHours.LastModifiedById,
		   BusinessHours.LastModifiedDate,
		   BusinessHours.LastViewedDate,
		   BusinessHours.MondayEndTime,
		   BusinessHours.MondayStartTime,
		   BusinessHours.Name,
		   BusinessHours.SaturdayEndTime,
		   BusinessHours.SaturdayStartTime,
		   BusinessHours.SundayEndTime,
		   BusinessHours.SundayStartTime,
		   BusinessHours.SystemModstamp,
		   BusinessHours.ThursdayEndTime,
		   BusinessHours.ThursdayStartTime,
		   BusinessHours.TimeZoneSidKey,
		   BusinessHours.TuesdayEndTime,
		   BusinessHours.TuesdayStartTime,
		   BusinessHours.WednesdayEndTime,
		   BusinessHours.WednesdayStartTime
           
       };
    }
	
	/**
    *  @author Gautam Arya 
    *  @description  
    *  @return SObjectType The Schema.SObjectType of the Business Hours
    **/
   public Schema.SObjectType getSObjectType()
   {
        return BusinessHours.sObjectType;
   }
    
    
    /**
     *  @author Gautam Arya
     *  @description Select by Name
	 *  Returns return specific Business Hours Record
     **/
     
    public List<BusinessHours> selectActiveByName(String strLikeValue)
    {
        return (List<BusinessHours>) Database.query(
                newQueryFactory().setCondition('Name Like :strLikeValue and IsActive = TRUE').toSOQL());
    }

    
}