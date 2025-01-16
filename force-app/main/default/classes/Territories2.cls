    /*
    *  @Author: Todd Newman
    *  @Date: 
    *  @Description: Class for Territories2 implementation
    *  Modification Log:
    *  ---------------------------------------------------------------------------------------------------------------------------
    *       Developer                      Date                Description         
    *       Todd Newman                                      Initial Version
    *       Nesar Mohan                 2022-03-30           CodeScan Fix - Add code comments
    *       Adyasha Satapathy           24-Nov-2022          POL-54: Update region references to AMEA and EUR
    *    ---------------------------------------------------------------------------------------------------------------------------
    **/

public with sharing class Territories2 extends ilib_SObjectDomain {
	
	public final static String MODEL_STATE_ACTIVE = 'Active';
    public final static Integer MAX_TERRITORY_DEPTH = 6;
	
    public final static String CHANNEL_PARTNER_DESCRIPTION = 'Channel Partner';
    public final static String CHANNEL_PARTNER_LABEL = 'Channel_Partner';

    public final static String ACCESS_LEVEL_PRIVATE = 'None';
    public final static String ACCESS_LEVEL_READ = 'Read';
    public final static String ACCESS_LEVEL_WRITE = 'Edit';

    public final static String REGION_AMR = 'AMR';
    public final static String REGION_EUR = 'EUR'; //POL-54
    public final static String REGION_AMEA = 'AMEA'; //POL-54
    public final static String REGION_CHINA = 'China';
    
    /*
    *  @Author      : Todd Newman
    *  @Description : Constructor to pass the object list to parent class
    *  @Param       : List<Territory2>
    */

    public Territories2(List<Territory2> sObjectList)
    {
        super(sObjectList);
    }

    /*
    *  @Author      : Todd Newman
    *  @Description : Boilerplate which is required for base class instantiation logic
    */

    public class Constructor implements ilib_SObjectDomain.IConstructable
    {
        /*
        *  @Description : nested constructor
        */
        public ilib_SObjectDomain construct(List<SObject> sObjectList)
        {
            return new Territories2(sObjectList);
        }
    }

    /*
    *  @Author      : Todd Newman
    *  @Description : Method to execute After Insert trigger logic
    *  @Param       : None
    *  @Return      : void
    */

    public override void onAfterInsert()
    {
        // remove this because it will always be followed by adding users and the sharing will happen then

        //TAPS_Orchestrator.recalculateTerritoryChanges(UtilsCollection.getSetOfIds(records, 'Id'));
    }

    /*
    *  @Author      : Todd Newman
    *  @Description : Method to execute After Update trigger logic
    *  @Param       : Map<Id, SObject>
    *  @Return      : void
    */
    
    public override void onAfterUpdate(Map<Id, SObject> existingRecords)
    {
        // remove this because it will always be covered by subsequent adding users
        // this assumes we won't be messing with territories like this mid-quarter

//        Set<Id> hasNewParent = new Set<Id>();
//
//        for (Territory2 t : (List<Territory2>)records)
//        {
//            Territory2 oldRecord = (Territory2)existingRecords.get(t.Id);
//            if (t.ParentTerritory2Id != oldRecord.ParentTerritory2Id)
//                hasNewParent.add(t.Id);
//        }
//
//        if (hasNewParent.size() > 0)
//            TAPS_Orchestrator.recalculateTerritoryChanges(hasNewParent);
    }

}