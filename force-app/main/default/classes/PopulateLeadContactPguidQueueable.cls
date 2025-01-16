/*
    populate lookup of lead and contact pguid
*/
public with sharing class PopulateLeadContactPguidQueueable implements System.Queueable {
    Set<String> pguidSet;
    Map<String,List<Apttus_Config2__OrderLineItem__c>> contactPguidToOrderLineItems = new Map<String,List<Apttus_Config2__OrderLineItem__c>>();
    Map<String,List<Apttus_Config2__OrderLineItem__c>> leadPguidToOrderLineItems = new Map<String,List<Apttus_Config2__OrderLineItem__c>>();
    
    /*
    * Constructor
    */
    public PopulateLeadContactPguidQueueable(Map<String,List<Apttus_Config2__OrderLineItem__c>> contactPguidToOrderLineItems, Map<String,List<Apttus_Config2__OrderLineItem__c>> leadPguidToOrderLineItems, Set<String> pguidSet){
        this.contactPguidToOrderLineItems = contactPguidToOrderLineItems;
        this.leadPguidToOrderLineItems = leadPguidToOrderLineItems;
        this.pguidSet = pguidSet;
    }
    
    /*
        populate lookup of lead and contact pguid
    */
    public void execute(QueueableContext context) {

        Map<String,Apttus_Config2__OrderLineItem__c> pguidMap = new Map<String,Apttus_Config2__OrderLineItem__c>();
        // update registrant Contact in order line item based on pguid-DCP-31268
        for(Contact con : new ContactsSelector().selectContactIdsforPGUIDId(contactPguidToOrderLineItems.keyset()))
        {
            pguidSet.remove(con.PGUID__c);
            for(Apttus_Config2__OrderLineItem__c oli :contactPguidToOrderLineItems.get(con.PGUID__c))
            {
                Apttus_Config2__OrderLineItem__c oliItem = new Apttus_Config2__OrderLineItem__c(ERP_Line_Number_Id__c=oli.ERP_Line_Number_Id__c,Registrant_Contact__c = con.id); //If new instance is not created, new field value updates made in class may get overwritten as this is queueable
                pguidMap.put(oli.ERP_Line_Number_Id__c,oliItem);
            }
        }

        // update registrant Lead in order line item based on pguid - DCP-31268
        for(Lead ld : new LeadsSelector().selectLeadsForPGUID(pguidSet))
        {
            for(Apttus_Config2__OrderLineItem__c oli :leadPguidToOrderLineItems.get(ld.PGUID__c))
            {
                if(pguidMap.containsKey(oli.ERP_Line_Number_Id__c)){
                    Apttus_Config2__OrderLineItem__c oliItem = pguidMap.get(oli.ERP_Line_Number_Id__c);
                    oliItem.Registrant_Lead__c = ld.id;
                }else{
                    Apttus_Config2__OrderLineItem__c oliItem = new Apttus_Config2__OrderLineItem__c(ERP_Line_Number_Id__c=oli.ERP_Line_Number_Id__c,Registrant_Lead__c = ld.id);
                    pguidMap.put(oli.ERP_Line_Number_Id__c,oliItem);
                }
            }
        } 

        List<Apttus_Config2__OrderLineItem__c> pguidToUpdateList = pguidMap.values();

        if(!pguidToUpdateList.isEmpty())  
            upsert pguidToUpdateList ERP_Line_Number_Id__c; //Need to do upsert in order to update using external id. Details: https://salesforce.stackexchange.com/questions/220184/updating-a-records-using-external-id-in-apex

    }
}