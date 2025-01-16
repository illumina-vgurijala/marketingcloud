/**
 *    @author Akshay Mohan
 *    @date   12-Aug-2021
 *    @description    InterfaceCalls domain class
 *    Modification Log:
 *    Developer                      Date                Description
 *    Akshay Mohan                 12-Aug-2021          Inital Version
 *    Gerardo Garcia               24-Jun-2024          CMCM-8480 add set of Extra Information if is available.
*/
public with sharing class InterfaceCalls extends ilib_SObjectDomain {

    public final static String OUTGOING_OPPORTUNITIES = 'Inbound_Opportunity';
    /*
     * public constructor for InterfaceCalls
    */
    public InterfaceCalls(List<Interface_Call__e> sObjectList)
    {
        super(sObjectList);
    }
    /*
    * Boilerplate which is required for base class instantiation logic
    */
    public class Constructor implements ilib_SObjectDomain.IConstructable
    {   
        /*
         * return a new object InterfaceCalls
        */
        public ilib_SObjectDomain construct(List<SObject> sObjectList)
        {
            return new InterfaceCalls(sObjectList);
        }
    }
    /**
     * Called during after insert event 
    **/
    public override void onAfterInsert()
    {
        // pass the data to a future call so that callouts are allowed
        System.debug('records: '+ records);
        for(Interface_Call__e call : (List<Interface_Call__e>)records)
            if(System.Test.isRunningTest())//if we don't do this the future call here doesn't happen in the trigger context since this event is already happening ina future context
                interfaceCallFactory(call);
            else
                interfaceCallFactory(JSON.serialize(call));
    }

    // TODO: how many could I get at once?
    // if too many, process some and retrigger the rest
    // TODO: should I have a class factory instead that returns the subclass?
    // cannot cover in test class
    @future(callout = true)
    private static void interfaceCallFactory(String jsonInterfaceCalls)
    {
        interfaceCallFactory((Interface_Call__e)JSON.deserialize(jsonInterfaceCalls, Interface_Call__e.class));
        
    }
    
    private static void interfaceCallFactory(Interface_Call__e call){
        System.debug('call: ' + call);
        ilib_OutboundInterface interfaceClass = getOutBoundClass(call.Name__c);
        if(String.isNotBlank(call.Extra_Information__c)) {
            interfaceClass.setExtraInformation(call.Extra_Information__c);
        }
        interfaceClass.callout(call.Related_Record__c);
    }
    
    private static ilib_OutboundInterface getOutBoundClass(String strClassName){
        return (ilib_OutboundInterface) Type.forName(strClassName).newInstance();
    }
    
    

}