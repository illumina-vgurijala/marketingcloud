/****************************************************************************************************************************************
* NAME         : ilib_RestInterface
* DESCRIPTION  : 
*             
@author       :  tnewman
@Date         :  11/14/18.
*
* MODIFICATION LOG:  
* -------------------------------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------------------------------
*  Saddam                 10-oct-22           Codescan Fix Added Comments for methods.
 -----------------------------------------------------------------------------------------------------------------------------------------------------------------
*/

public with sharing class ilib_RestInterface {

    /*
    *  @description  : Wrapper Class
    */
    public class InterfaceDetails
    {
        public String name;
        public String direction;
        public String objectType;

        /*
        *  @description  : Wrapper Method
        */
        public InterfaceDetails(String name, String direction, String objectType)
        {
            this.name = name;
            this.direction = direction;
            this.objectType = objectType;
        }
    }

   /*
    *   @author      :  tnewman
    *   @description :  getInterfaceDetails
    *   @param       :  string
    *   @Return      :  InterfaceDetails Wrapper.
    *
    */
    public static InterfaceDetails getInterfaceDetails(String strClassName)
    {
        List<Interface_Detail__mdt> details =
            [SELECT DeveloperName, Interface_Name__c, Direction__c, Object_Type__c
             FROM Interface_Detail__mdt
             WHERE DeveloperName = :strClassName];

        if (details.isEmpty())
            throw new UtilsRest.InterfaceException('Interface Details metadata not configured for ' + strClassName);

        return new InterfaceDetails(details.get(0).Interface_Name__c, details.get(0).Direction__c, details.get(0).Object_Type__c);
    }
    /*
    *   @author      :  tnewman
    *   @description :  addFriendlyJsonToLog
    *   @param       :  ilib_LogInterface.LogDetails,Object
    */
    public static void addFriendlyJsonToLog(ilib_LogInterface.LogDetails log, Object dataWrapper)
    {
        if (dataWrapper != null)
            ilib_LogInterface.addJsonToLog(log, JSON.serializePretty(dataWrapper));
    }

}