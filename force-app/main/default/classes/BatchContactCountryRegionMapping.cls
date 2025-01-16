/**
*    @author: Pankaj 
*    @date:   10-Sept-2018
*    @description:  Batch class to update Contact Region Mapping
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Pankaj                        23-Oct-2018        Batch Class to update Contact Region Field
*    ------------------------------------------------------------------------------------ 
*                    
*/

public with sharing class BatchContactCountryRegionMapping extends ilib_ScheduleAndBatch implements Schedulable {

    public static final String STRING_DEFAULT_REGION = 'AMR'; // Default Region value to be used
    public List<Contact> lstContactUpdated=new list<Contact>();

    /**
     *  @author  Pankaj Singla
     *  @description execute method to be called when class is scheduled
     *  @paramter- schedule context
     **/
    public override void execute(SchedulableContext ctx)
    {
        BatchContactCountryRegionMapping objBatch=new BatchContactCountryRegionMapping();
        Database.executebatch(objBatch,2000);
        //BatchContactCountryRegionMapping objBatch=new BatchContactCountryRegionMapping();
        //String sch='0 0 * * * ?';
        //System.schedule('BatchContactCountryRegionMapping ', sch , objBatch);
    }
    
    /**
     *  @author  Pankaj Singla
     *  @description start method for the batch job
     *  @paramter- schedule context
     **/
    public override Database.QueryLocator start(Database.BatchableContext bc)
    {
        /*Fetch the list of all contact records for update*/
        String strSoql = 'SELECT id,MailingCountry,MailingCountryCode,Region__c,Account.ShippingCountry,Account.ShippingCountryCode FROM Contact where (email!=null or phone!=null) and lastmodifieddate >= LAST_90_DAYS order by createddate desc' ;
        strSOQL=String.escapeSingleQuotes(strSOQL);
        return Database.getQueryLocator(strSoql);
    }
    
    /**
     *  @author  Pankaj Singla
     *  @description execute  method for the batch job
     *  @paramter- schedule context, list of 
     **/
    public override void execute(Database.BatchableContext bc, List<sObject> lstContact)
    {
        Map<String,CountryRegionMapping__mdt> mapCountryCodeToCountryRegionMapping=new Map<String,CountryRegionMapping__mdt>();
        //List<Contact> lstContactUpdated=new list<Contact>();
        String currentRegionValue='';

        for(CountryRegionMapping__mdt objCountryRegionMapping : new CountryRegionMappingMetaDataSelector().selectCountryRegionMappingMetaRecords()){
           mapCountryCodeToCountryRegionMapping.put(objCountryRegionMapping.CountryCode__c,objCountryRegionMapping);
        }

        for(Contact objContact:(List<Contact>)lstContact)
        {
            
            if(objContact.region__c!=null && objContact.region__c!=''){
               currentRegionValue=objContact.region__c;
           }
            
            // Set Region based on Contact Mailing Country
            if(objContact.MailingCountry!=null && objContact.MailingCountry!=''){
                objContact.region__c=mapCountryCodeToCountryRegionMapping.containsKey(objContact.MailingCountry)? mapCountryCodeToCountryRegionMapping.get(objContact.MailingCountry).Region__c:'';
            }

            // Use Account Shipping country if the contact mailing country is blank
            else if(objContact.Account.ShippingCountry!=null && objContact.Account.ShippingCountry!='' ){
                objContact.region__c=mapCountryCodeToCountryRegionMapping.containsKey(objContact.Account.ShippingCountry)? mapCountryCodeToCountryRegionMapping.get(objContact.Account.ShippingCountry).Region__c:'';
            }

            // set the default value for Region.
            else { objContact.region__c=STRING_DEFAULT_REGION;
            }
            
            if(objContact.region__c!=null && currentRegionValue!=objContact.region__c){
                lstContactUpdated.add(objContact);
            }
            
            currentRegionValue='';        

        }

        if(lstContactUpdated.size()>0)
        {
            //update lstContactUpdated;
            system.debug('The Updated Records are--'+lstContactUpdated);
            Database.SaveResult [] updateResult = Database.update(lstContactUpdated, false);
        }   
    }

    /*Finish method of Batch Class */
    public override void finish(Database.BatchableContext bc) { 
    
        /* if(lstContactUpdated.size()>0){
            system.debug('The qualified Lead Records for update are-'+lstContactUpdated);
        } */
     
    
    }

}