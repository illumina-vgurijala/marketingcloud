/* @ author       : KD
* @ date         : 20-Nov-2019
* @ Description  :  AdminOperations Trigger helper class contains all Business logic implementation
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID      Description
* KD                       20-Oct-2020                                  updated logic
* ---------------------------------------------------------------------------------------------------------------------------------------
*/
public with sharing class AdminOperations extends ilib_SObjectDomain{
    /*
    * Constructor
    */
    public AdminOperations(List<Admin_Operation__e> sObjectList)
    {
        super(sObjectList);
    }
    /*
    * Boilerplate which is required for base class instantiation logic
    */
    public class Constructor implements ilib_SObjectDomain.IConstructable
    {
        /*
        * construct
        */
        public ilib_SObjectDomain construct(List<SObject> sObjectList)
        {
            return new AdminOperations(sObjectList);
        }
    }
    /*
    * Description : onAfter method
    */
    public override void onAfterInsert()
    {
        Map<String,List<Id>> mapCallNameToRecords = new Map<String,List<Id>>();
        for(Admin_Operation__e call : (List<Admin_Operation__e>)records){
            //interfaceFactory(call);
            if(!mapCallNameToRecords.containsKey(call.Name__c)){
                mapCallNameToRecords.put(call.Name__c,new List<Id>());
            }
            mapCallNameToRecords.get(call.Name__c).addAll(call.Related_Record__c.split(','));
        }
        interfaceFactory(mapCallNameToRecords);
        
    }
    private static void interfaceFactory(Map<String,List<String>> mapCallNameToRecords){
        for(String strClassName : mapCallNameToRecords.keySet())
            getServiceClass(strClassName).doBusinessLogic(mapCallNameToRecords.get(strClassName));
    }
    
    private static ilib_AdminOperationLogicInterface getServiceClass(String strClassName){
        return (ilib_AdminOperationLogicInterface) Type.forName(strClassName).newInstance();
    }
    
}