/**
 *    @author Gautam Arya
 *    @date   2021-03-31
 *    @description    No extends ilib_SObjectSelector as Calender object is not accesssible so using normal query
 *    Modification Log:
 *    ------------------------------------------------------------------------------------ 
 *             Developer                      Date                Description
*              
 *    ------------------------------------------------------------------------------------ 
 *                    
 */
public with sharing class CalendarsSelector 
{
    /**
     *  @author Gautam Arya
     *  @description Select by Type, Name and Active
     *  Returns return specific Calendar Record
     **/
     
    public List<Calendar> getActivePublicCalandarByTypeAndName(String strCalenderNameRegex)
    {
        String strType = 'Public';
        return (List<Calendar>) Database.query('Select id,Name,Type from Calendar where Type =: strType and Name like :strCalenderNameRegex and IsActive = true');
    }

    
}