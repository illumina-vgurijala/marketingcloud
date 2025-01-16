/**
*    @author: Pankaj 
*    @date:   10-Sept-2018
*    @description:  Batch class to update Lead Region Mapping
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Pankaj                        23-Oct-2018        Batch Class to update Lead Region Field
*    ------------------------------------------------------------------------------------ 
*                    
*/
public with sharing class BatchLeadCountryRegionMapping extends ilib_ScheduleAndBatch  implements Schedulable {

    public static final String STRING_DEFAULT_REGION = 'AMR'; // Default Region value to be used
    public List<Lead> lstLeadUpdated = new list<Lead>();

    /**
     *  @author  Pankaj Singla
     *  @description execute method to be called when class is scheduled
     *  @paramter- schedule context
     **/
    public override void execute(SchedulableContext ctx)
    {
      BatchLeadCountryRegionMapping objBatch=new BatchLeadCountryRegionMapping();
      Database.executebatch(objBatch,2000);
    }

    /**
     *  @author  Pankaj Singla
     *  @description start method for the batch job
     *  @paramter- schedule context
     **/
    public override Database.QueryLocator start(Database.BatchableContext bc)
    {
        /*Fetch the list of all Lead records for update*/
        String strSoql = 'SELECT Country,CountryCode,region__c FROM Lead where isconverted = false and (email != null or phone != null) and country != null and lastmodifieddate >= LAST_90_DAYS order by createddate desc';
        strSOQL=String.escapeSingleQuotes(strSOQL);
        return Database.getQueryLocator(strSoql);
    }
    
    /**
     *  @author  Pankaj Singla
     *  @description execute  method for the batch job
     *  @paramter- schedule context, list of 
     **/
    public override void execute(Database.BatchableContext bc, List<sObject> lstLead)
    {
        Map<String,CountryRegionMapping__mdt> mapCountryCodeToCountryRegionMapping = new Map<String,CountryRegionMapping__mdt>();
        //List<Lead> lstLeadUpdated = new list<Lead>();
        String currentRegionValue='';   
        for (CountryRegionMapping__mdt objCountryRegionMapping : new CountryRegionMappingMetaDataSelector().selectCountryRegionMappingMetaRecords())
        {
            mapCountryCodeToCountryRegionMapping.put(objCountryRegionMapping.CountryCode__c,objCountryRegionMapping);
        }
        
        for (Lead objLead:(List<Lead>)lstLead)
        {
           if(objLead.region__c!=null && objLead.region__c!=''){
               currentRegionValue=objLead.region__c;
           }
           
           // Set Region field based on Lead country value
           if(objLead.Country!=null && objLead.Country!=''){
                objLead.region__c=mapCountryCodeToCountryRegionMapping.containsKey(objLead.Country)? mapCountryCodeToCountryRegionMapping.get(objLead.Country).Region__c:STRING_DEFAULT_REGION;
            }
            // set the default value
            else {
                objLead.region__c=STRING_DEFAULT_REGION;
            }

            if(objLead.region__c!=null && currentRegionValue!=objLead.region__c){
                lstLeadUpdated.add(objLead);
            }
            currentRegionValue='';
            
        }
        
        if (lstLeadUpdated.size()>0)
        {
            //update lstLeadUpdated;
            system.debug('The Updated Records are--'+lstLeadUpdated);
            Database.SaveResult [] updateResult = Database.update(lstLeadUpdated, false);
        }   
    }

    /*Finish method of Batch Class*/
    public override void finish(Database.BatchableContext bc) {
            
        /* if (lstLeadUpdated.size()>0)
        {
            system.debug('The Updated Records are--'+lstLeadUpdated);
            
        }  */
    
    }

}