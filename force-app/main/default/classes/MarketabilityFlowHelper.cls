/**
*    @author Pankaj Singla
*    @date   2018-12-11
*    @description    Marketability Rule Set Helper
*    Modification Log:
*    -------------------------------------------------------------------------------------
*             Developer                      Date                Description
            
------------------------------------------------------------------------------------------
*                    
*/
public class MarketabilityFlowHelper{    
   
   public static final string COUNTRY_CODE = 'CountryCode';
   public static final String MARKETABILITY_RULE='Marketability_Rule__c';
   public static final String MAILING_COUNTRY_CODE='MailingCountryCode';
   public static final String ACCOUNT_BILLING_COUNTRY='AccountBillingCountryCode__c';
   public static final String DOUBLE_OPT_IN_C='Double_Opt_In__c';
   public static final String DOUBLE_OPT_IN_DATE_C='Double_Opt_In_Date__c';
   public static final String EXPLICIT_OPT_IN_C='Explicit_Opt_In__c';
   public static final String EXPLICIT_OPT_IN_DATE_C='Explicit_Opt_In_Date__c';
   public static final String IMPLICIT_OPT_IN_C='Implicit_Opt_In__c';
   public static final String IMPLICIT_OPT_IN_DATE_C='Implicit_Opt_In_Date__c';
   public static final String HAS_OPTED_OUT_OF_EMAIL='HasOptedOutOfEmail';
   public static final String MARKETABLE_C='Marketable__c';
   public static final String MARKETABLE_DATE_C='Marketable_Date__c';
   public static final String SEND_DOUBLE_OPT_IN_CONFIRMATION_C='SendDoubleOptinConfirmation__c';
   public static final String COUNTRY='Country';
   public static final String MAILING_COUNTRY='MailingCountry';
   /*Changes DCP-21329 Jan 24,2019*/
   public static final String DOUBLE_OPT_IN_EMAIL_SEND_DATE='Double_Opt_In_Email_Sent_Date__c';
   public static final String INTEGRATION_MARKETING='Integration Marketing';
   
   
   /**
   * @author Pankaj Singla
   * @date   2018-12-11
   * @description    This method sets the marketability on Record based on the country field
   * @Param: List<sObject> records,String strObjType
   * return: List<sObject>
   **/   
    public static List<sObject> determineMarketabilityRuleBasedCountry(List<sObject> records,String strObjType){
        
        /*Fetch the list of Custom Metadata records to get the configured values of Marketability Rule for each country*/
        
        Map<String,CountryRegionMapping__mdt> mapCountryCodesToCountryRegionMapping = new Map<String,CountryRegionMapping__mdt>();
        Map<String,CountryRegionMapping__mdt> mapCountryNameToCountryRegionMapping = new Map<String,CountryRegionMapping__mdt>();
        String strUserProfileName;
        for (CountryRegionMapping__mdt objCountryRegionMapping : new CountryRegionMappingMetaDataSelector().selectCountryRegionMappingMetaRecords())
        {
            mapCountryCodesToCountryRegionMapping.put(objCountryRegionMapping.Label,objCountryRegionMapping);
            mapCountryNameToCountryRegionMapping.put(objCountryRegionMapping.CountryCode__c,objCountryRegionMapping);
        }
        
        for(Profile objProfile:[select id,name from profile where id=:UserInfo.getProfileId()]){
			strUserProfileName=objProfile.Name;
		}
		
                 
        for(sObject objRecord:records){   
            
            if(objRecord.getSObjectType().getDescribe().getName()==Label.sObject_Type_Lead){
                system.debug('Lead data is-'+objRecord.get(COUNTRY)+'@'+objRecord.get(COUNTRY_CODE)+'@'+objRecord.getSObjectType().getDescribe().getName());
            }
            
            if(objRecord.getSObjectType().getDescribe().getName()==Label.sObject_Type_Contact){
                system.debug('Contact data is-'+objRecord.get(MAILING_COUNTRY)+'@'+objRecord.get(MAILING_COUNTRY_CODE)+'@'+objRecord.getSObjectType().getDescribe().getName()+'@'+objRecord.get(ACCOUNT_BILLING_COUNTRY));
            }
            /*Set the default Marketability Rule */
            objRecord.put(MARKETABILITY_RULE,Label.Default_Marketability_Rule);
            
            /*if Object is Lead Record, use the CountryCode value to determine marketability rule*/
            if(objRecord.getSObjectType().getDescribe().getName()==Label.sObject_Type_Lead){
                
                if(objRecord.get(COUNTRY)!=null
                        && objRecord.get(COUNTRY)!=''
                            && mapCountryNameToCountryRegionMapping.containsKey((string)objRecord.get(COUNTRY))
								&& strUserProfileName==INTEGRATION_MARKETING){
                                objRecord.put(MARKETABILITY_RULE,mapCountryNameToCountryRegionMapping.get((string)objRecord.get(COUNTRY)).Marketability_Rule__c);
                }
                
                else if(objRecord.get(COUNTRY_CODE)!=null
                     && objRecord.get(COUNTRY_CODE)!=''
                        && mapCountryCodesToCountryRegionMapping.containsKey((string)objRecord.get(COUNTRY_CODE))
							&& strUserProfileName!=INTEGRATION_MARKETING){
                                objRecord.put(MARKETABILITY_RULE,mapCountryCodesToCountryRegionMapping.get((string)objRecord.get(COUNTRY_CODE)).Marketability_Rule__c);
                }
            }
            
            else if(objRecord.getSObjectType().getDescribe().getName()==Label.sObject_Type_Contact){
                /*if Object is Contact Record, use the MailingCountry value to determine marketability rule*/   
                
                if(objRecord.get(MAILING_COUNTRY)!=null
                            && objRecord.get(MAILING_COUNTRY)!=''
                                && mapCountryNameToCountryRegionMapping.containsKey((string)objRecord.get(MAILING_COUNTRY))
									&& strUserProfileName==INTEGRATION_MARKETING){
                                    objRecord.put(MARKETABILITY_RULE,mapCountryNameToCountryRegionMapping.get((string)objRecord.get('mailingcountry')).Marketability_Rule__c);
                }
                
                else if(objRecord.get(MAILING_COUNTRY_CODE)!=null
                    && objRecord.get(MAILING_COUNTRY_CODE)!=''
                        && mapCountryCodesToCountryRegionMapping.containsKey((string)objRecord.get(MAILING_COUNTRY_CODE))
							&& strUserProfileName!=INTEGRATION_MARKETING){
                            objRecord.put(MARKETABILITY_RULE,mapCountryCodesToCountryRegionMapping.get((string)objRecord.get(MAILING_COUNTRY_CODE)).Marketability_Rule__c);
                }
                
                /*if Object is Contact Record, and MailingCountry is not present,use the Account Billing Country Code value to determine marketability rule*/ 
                else if(objRecord.get(ACCOUNT_BILLING_COUNTRY)!=null
                        && objRecord.get(ACCOUNT_BILLING_COUNTRY)!=''
                            && mapCountryNameToCountryRegionMapping.containsKey((string)objRecord.get(ACCOUNT_BILLING_COUNTRY))
								&& strUserProfileName!=INTEGRATION_MARKETING){
                                objRecord.put(MARKETABILITY_RULE,mapCountryNameToCountryRegionMapping.get((string)objRecord.get(ACCOUNT_BILLING_COUNTRY)).Marketability_Rule__c);
                }
            }
             
             /*If new record is inserted, use the method for New Prospects to set Marketable field on record*/
            
            if(Trigger.isExecuting && Trigger.isInsert){
                setOptInDatesForNewProspects(objRecord);
                determineMarketabilityForNewPropects(objRecord);
            }            
            
            /*If new record is inserted, use the method for Existing Prospects to set Marketable field on record*/
            
            else if (Trigger.isExecuting && Trigger.isUpdate && Trigger.isBefore){
                setOptinDatesForExistingProspects(objRecord);
                determineMarketabilityForExistingProspects(objRecord);
            }           
        }
        return records;
    }
    
   /**
   * @author Pankaj Singla
   * @date   2018-12-11
   * @description    Set the corresponding Opt in Dates for New Prospects-Lead/Contact
   * @Param: sObject objRecord
   * return: void
   **/
   public static void setOptInDatesForNewProspects(sObject objRecord){        
        
        if(objRecord.get(DOUBLE_OPT_IN_C)!=null 
            && objRecord.get(DOUBLE_OPT_IN_DATE_C)==null 
                && objRecord.get(DOUBLE_OPT_IN_C)==Label.Yes){            
            
            objRecord.put(DOUBLE_OPT_IN_DATE_C,datetime.now());
        }
        
        if(objRecord.get(EXPLICIT_OPT_IN_C)!=null 
            && objRecord.get(EXPLICIT_OPT_IN_DATE_C)==null 
                && objRecord.get(EXPLICIT_OPT_IN_C)==Label.Yes){         
            
            objRecord.put(EXPLICIT_OPT_IN_DATE_C,datetime.now());
        }        
        
        if(objRecord.get(IMPLICIT_OPT_IN_C)!=null 
            && objRecord.get(IMPLICIT_OPT_IN_DATE_C)==null 
                && objRecord.get(IMPLICIT_OPT_IN_C)==Label.Yes){            
            
            objRecord.put(IMPLICIT_OPT_IN_DATE_C,datetime.now());
        }        
    }
    
   /**
   * @author Pankaj Singla
   * @date   2018-12-11
   * @description    Set the corresponding Opt in Dates for Existing Prospects-Lead/Contact
   * @Param: sObject objNewRecord
   * return: void
   **/    
   public static void setOptinDatesForExistingProspects(sObject objNewRecord){
   
   /*Get the old Record from Trigger.oldMap*/
   sObject objOldRecord=Trigger.OldMap.get(objNewRecord.id);
   
   /*if the Double Opt in Set to true, update the date as now if not set*/     
   
   if(objNewRecord.get(DOUBLE_OPT_IN_C)==Label.Yes 
     && objOldRecord.get(DOUBLE_OPT_IN_C)!=Label.Yes
        && (objOldRecord.get(DOUBLE_OPT_IN_DATE_C)==NULL 
            || objOldRecord.get(DOUBLE_OPT_IN_DATE_C)=='')){                
         
         objNewRecord.put(DOUBLE_OPT_IN_DATE_C,datetime.now());
        system.debug('Dates debug---'+objNewRecord.get(MARKETABILITY_RULE)+'@'+objOldRecord.get(MARKETABILITY_RULE)+'@@'+objNewRecord.get(SEND_DOUBLE_OPT_IN_CONFIRMATION_C));
        if(objNewRecord.get(MARKETABILITY_RULE)==Label.Marketability_Type_Double_Opt_in 
        && objOldRecord.get(MARKETABILITY_RULE)==Label.Marketability_Type_Double_Opt_in
            && objNewRecord.get(SEND_DOUBLE_OPT_IN_CONFIRMATION_C)==false
                 && objOldRecord.get(SEND_DOUBLE_OPT_IN_CONFIRMATION_C)==false 
                    ){
            
            if(objOldRecord.get(MARKETABLE_DATE_C)==NULL){
                objNewRecord.put(MARKETABLE_DATE_C,datetime.now());
            }
            
            if(objOldRecord.get(MARKETABLE_C)!=Label.Yes){
                objNewRecord.put(MARKETABLE_C,Label.Yes);
            }
                
                    
        }
   }
   
   /*Clear the Double Opt In Date if the Double opt in is set as No*/
    else if(objNewRecord.get(DOUBLE_OPT_IN_C)!=Label.Yes 
     && objOldRecord.get(DOUBLE_OPT_IN_C)==Label.Yes
        && objNewRecord.get(DOUBLE_OPT_IN_DATE_C)!=NULL){
            
        objNewRecord.put(DOUBLE_OPT_IN_DATE_C,null);               
   }
   
   /*if the Explicit Opt in Set to true, update the date as now if not set*/       
   
   if(objNewRecord.get(EXPLICIT_OPT_IN_C)==Label.Yes 
        && objOldRecord.get(EXPLICIT_OPT_IN_C)!=Label.Yes 
          && (objOldRecord.get(EXPLICIT_OPT_IN_DATE_C)==NULL 
            || objOldRecord.get(EXPLICIT_OPT_IN_DATE_C)=='')){
            
            objNewRecord.put(EXPLICIT_OPT_IN_DATE_C,datetime.now()); 
   }
   
   else if(objNewRecord.get(EXPLICIT_OPT_IN_C)!=Label.Yes 
     && objOldRecord.get(EXPLICIT_OPT_IN_C)==Label.Yes
        && objNewRecord.get(EXPLICIT_OPT_IN_DATE_C)!=NULL){
            
        objNewRecord.put(EXPLICIT_OPT_IN_DATE_C,null);               
   }
   
   /*if the Implicit Opt in Set to true, update the date as now if not set*/
   
   if(objNewRecord.get(IMPLICIT_OPT_IN_C)==Label.Yes 
            && objOldRecord.get(IMPLICIT_OPT_IN_C)!=Label.Yes 
                && (objOldRecord.get(IMPLICIT_OPT_IN_DATE_C)==NULL || objOldRecord.get(IMPLICIT_OPT_IN_DATE_C)=='')){
                
                    objNewRecord.put(IMPLICIT_OPT_IN_DATE_C,datetime.now());
             
    }
    
    else if(objNewRecord.get(IMPLICIT_OPT_IN_C)!=Label.Yes 
     && objOldRecord.get(IMPLICIT_OPT_IN_C)==Label.Yes
        && objNewRecord.get(IMPLICIT_OPT_IN_DATE_C)!=NULL){
            
        objNewRecord.put(IMPLICIT_OPT_IN_DATE_C,null);               
   }
   
    }
   
   /**
     * @author Pankaj Singla
     * @date   2018-12-11
     * @description    This method sets the Resets the Opt In Fields for un-subscribed Prospects-Lead/Contact
     * @Param: sObject objNewRecord
     * return: void
     **/
   private static void clearOptinFieldsforUnsubscribed(sObject objRecord,sObject objOldRecord){
        
        if(Trigger.isInsert || (objOldRecord!=null && objOldRecord.get(MARKETABLE_C)!=Label.No)){
            objRecord.put(MARKETABLE_C,Label.No);
        }
        
        if(Trigger.isInsert || (objOldRecord!=null && objOldRecord.get(MARKETABLE_DATE_C)!=null) ){
            objRecord.put(MARKETABLE_DATE_C,null);
        }
        
        if(Trigger.isInsert || (objOldRecord!=null && objOldRecord.get(DOUBLE_OPT_IN_C)!=Label.No)){
            objRecord.put(DOUBLE_OPT_IN_C,Label.No);
        }
        
        if(Trigger.isInsert || (objOldRecord!=null && objOldRecord.get(DOUBLE_OPT_IN_DATE_C)!=null )){
            objRecord.put(DOUBLE_OPT_IN_DATE_C,null);
        }
        
        if(Trigger.isInsert || (objOldRecord!=null && objOldRecord.get(EXPLICIT_OPT_IN_C)!=Label.No)){
            objRecord.put(EXPLICIT_OPT_IN_C,Label.No);
        }
        
        if(Trigger.isInsert || (objOldRecord!=null && objOldRecord.get(EXPLICIT_OPT_IN_DATE_C)!=null )){
            objRecord.put(EXPLICIT_OPT_IN_DATE_C,null);
        }
        
        if(Trigger.isInsert || (objOldRecord!=null && objOldRecord.get(IMPLICIT_OPT_IN_C)!=Label.No)){
            objRecord.put(IMPLICIT_OPT_IN_C,Label.No);
        }
        
        if(Trigger.isInsert || (objOldRecord!=null && objOldRecord.get(IMPLICIT_OPT_IN_DATE_C)!=null )){
            objRecord.put(IMPLICIT_OPT_IN_DATE_C,null);
        }
        
   }
   
   /**
     * @author Pankaj Singla
     * @date   2018-12-11
     * @description    This method sets the marketable field for Existing Prospects-Lead/Contact
     * @Param: sObject objNewRecord
     * return: void
     **/
    
    public static void determineMarketabilityForExistingProspects(sObject objNewRecord){
        /*Get the old Record from Triger.oldMap*/
        
        sObject objOldRecord=Trigger.OldMap.get(objNewRecord.id);
        system.debug('i am here--'+objNewRecord.get(MARKETABILITY_RULE)+'@'+Label.Marketability_Type_Double_Opt_in);
        /*The method runs only if there is change in Marketablity Rule for the Lead/Contact*/ 
        
          /*Set Not Marketable is Email Opt Out is true*/
            if(objNewRecord.get(HAS_OPTED_OUT_OF_EMAIL)==true){
                clearOptinFieldsforUnsubscribed(objNewRecord,objOldRecord);
            }
            
            /*Logic if the Marketable Rule is Set as Double Opt in */
            
            
            else if(objNewRecord.get(MARKETABILITY_RULE)==Label.Marketability_Type_Double_Opt_in){
                
                /*Still valid double opt-in consent given in past */
                system.debug('now here ----'+objOldRecord.get(DOUBLE_OPT_IN_DATE_C)+'@'+objOldRecord.get(DOUBLE_OPT_IN_C)+'@@'+objNewRecord.get(DOUBLE_OPT_IN_C));
                if(objOldRecord.get(DOUBLE_OPT_IN_C)!=Label.Yes 
                        && objNewRecord.get(DOUBLE_OPT_IN_C)==Label.Yes ){
                    objNewRecord.put(MARKETABLE_C,Label.Yes);
                    objNewRecord.put(MARKETABLE_DATE_C,datetime.now());
                    
                }
                /*Defect Fix DCP-21329*/
                else if(objNewRecord.get(DOUBLE_OPT_IN_C)==Label.Yes 
                        && objOldRecord.get(DOUBLE_OPT_IN_C)==Label.Yes
                            && objOldRecord.get(DOUBLE_OPT_IN_DATE_C)!=NULL){
                    if(objNewRecord.get(MARKETABLE_C)!=Label.Yes){
                        objNewRecord.put(MARKETABLE_C,Label.Yes);
                        objNewRecord.put(MARKETABLE_DATE_C,datetime.now());
                    }
                    else {
                        /*Do nothing and exit as Marketable Flag is already set*/
                    }
                }
                              
                else{
                    
                    objNewRecord.put(MARKETABLE_C,Label.No);
                    objNewRecord.put(MARKETABLE_DATE_C,null);
                    
                    /*update record where old country is non German (implicit or explicit country), explicit = yes, optout = no, new country = Germany (double opt-in country)*/
                    
                    if(objNewRecord.get(EXPLICIT_OPT_IN_C)==Label.Yes 
                        && objNewRecord.get(HAS_OPTED_OUT_OF_EMAIL)==false 
                            && objOldRecord.get(MARKETABILITY_RULE)!=Label.Marketability_Type_Double_Opt_in
                                && objOldRecord.get(SEND_DOUBLE_OPT_IN_CONFIRMATION_C)!=true){
                        
                        /*Double Opt In Requires Confirmation from Prospect/User. Pardot will send confirmation email in case the flag is set to true */
                        
                        objNewRecord.put(SEND_DOUBLE_OPT_IN_CONFIRMATION_C,true);
                        /*Changes DCP-21329 Jan 24,2019*/
            objNewRecord.put(DOUBLE_OPT_IN_EMAIL_SEND_DATE,Datetime.now());
                    }
                    
                    /*update record where country doesn’t change, old explicit =no, new explicit = yes, optout = no, country = Germany*/
                    
                     else if(objOldRecord.get(EXPLICIT_OPT_IN_C)!=Label.Yes 
                        && objNewRecord.get(EXPLICIT_OPT_IN_C)==Label.Yes 
                            && objNewRecord.get(HAS_OPTED_OUT_OF_EMAIL)==false 
                                && objOldRecord.get(MARKETABILITY_RULE)==Label.Marketability_Type_Double_Opt_in
                                    && objOldRecord.get(SEND_DOUBLE_OPT_IN_CONFIRMATION_C)!=true){
                                    
                        /*Double Opt In Requires Confirmation from Prospect/User. Pardot will send confirmation email in case the flag is set to true */
                        objNewRecord.put(SEND_DOUBLE_OPT_IN_CONFIRMATION_C,true);
                        /*Changes DCP-21329 Jan 24,2019*/
            objNewRecord.put(DOUBLE_OPT_IN_EMAIL_SEND_DATE,Datetime.now());
                    }
                }
            }
            
            /*Logic if the Marketable Rule is Set as Explicit  Opt in */
            
            else if(objNewRecord.get(MARKETABILITY_RULE)==Label.Marketability_Type_Explicit_Opt_in){
                /*Explicit Consent checkbox checked */
                
                if(objNewRecord.get(EXPLICIT_OPT_IN_C)==Label.Yes){
                    
                    if(objOldRecord.get(MARKETABILITY_RULE)!=Label.Marketability_Type_Explicit_Opt_in 
                        || objOldRecord.get(EXPLICIT_OPT_IN_C)!=Label.Yes ){
                            objNewRecord.put(MARKETABLE_C,Label.Yes);
                            objNewRecord.put(MARKETABLE_DATE_C,datetime.now());
                    }
                }
                
                else {
                    objNewRecord.put(MARKETABLE_C,Label.No);
                    objNewRecord.put(MARKETABLE_DATE_C,null);
                }
            }
            
            /*Logic if the Marketable Rule is Set as Implicit  Opt in */
            
            else if(objNewRecord.get(MARKETABILITY_RULE)==Label.Marketability_Type_Implicit_Opt_in){
                
                /*Update was from a Implicit Source?*/
                
                if(objNewRecord.get(IMPLICIT_OPT_IN_C)==Label.Yes){
                    
                    if(objOldRecord.get(MARKETABILITY_RULE)!=Label.Marketability_Type_Implicit_Opt_in
                        || objOldRecord.get(IMPLICIT_OPT_IN_C)!=Label.Yes){
                            objNewRecord.put(MARKETABLE_C,Label.Yes);
                            objNewRecord.put(MARKETABLE_DATE_C,datetime.now());                     
                    }
                }
                
                else {
                    objNewRecord.put(MARKETABLE_C,Label.No);
                    objNewRecord.put(MARKETABLE_DATE_C,null);
                }
                
            }
            
            else if(objNewRecord.get(MARKETABILITY_RULE)==Label.Default_Marketability_Rule ){
                objNewRecord.put(MARKETABLE_C,Label.No);
                objNewRecord.put(MARKETABLE_DATE_C,null);
            }
        //}
    }
    
    /**
     * @author Pankaj Singla
     * @date   2018-12-11
     * @description    This method sets the marketable field for New Prospects-Lead/Contact
     * @Param: sObject objNewRecord
     * return: void
     **/
     
    public static void determineMarketabilityForNewPropects(sObject objRecord){       
            
            /*If Email opted out is true, set Marketable as No*/
            
            if(objRecord.get(HAS_OPTED_OUT_OF_EMAIL)!=null && objRecord.get(HAS_OPTED_OUT_OF_EMAIL)==true){
                clearOptinFieldsforUnsubscribed(objRecord,null);
            }
            
            else {
                /*Still valid Implicit Opt-in given in past*/
            
                if(objRecord.get(EXPLICIT_OPT_IN_C)!=Label.Yes && objRecord.get(IMPLICIT_OPT_IN_C)!=Label.Yes ){
                    objRecord.put(MARKETABLE_C,Label.No);
                    objRecord.put(MARKETABLE_DATE_C,null);
                }
                /*Logic if the Marketable Rule is Set as Double Opt in */
                
                else if(objRecord.get(MARKETABILITY_RULE)==Label.Marketability_Type_Double_Opt_in){
                    objRecord.put(MARKETABLE_C,Label.No);
                    objRecord.put(MARKETABLE_DATE_C,null);
                    
                    /*Explicit Consent checkbox checked?*/
                    
                    if(objRecord.get(EXPLICIT_OPT_IN_C)==Label.Yes 
                        && objRecord.get(HAS_OPTED_OUT_OF_EMAIL)==false ){
                        /*Double Opt In Requires Confirmation from Prospect/User. Pardot will send confirmation email in case the flag is set to true */
                        objRecord.put(SEND_DOUBLE_OPT_IN_CONFIRMATION_C,true);
                        /*Changes DCP-21329 Jan 24,2019*/
            objRecord.put(DOUBLE_OPT_IN_EMAIL_SEND_DATE,Datetime.now());
                    }
                }
                /*Logic if the Marketable Rule is Set as Explicit Opt in */
                
                else if(objRecord.get(MARKETABILITY_RULE)==Label.Marketability_Type_Explicit_Opt_in){
                    /*Explicit Consent checkbox checked?*/
                    
                    if(objRecord.get(EXPLICIT_OPT_IN_C)==Label.Yes){
                        objRecord.put(MARKETABLE_C,Label.Yes);
                        objRecord.put(MARKETABLE_DATE_C,datetime.now());
                    }
                    else{
                        objRecord.put(MARKETABLE_C,Label.No);
                        objRecord.put(MARKETABLE_DATE_C,null);
                    }
                }
            
                /*Logic if the Marketable Rule is Set as Implicit Opt in */
                
                else if(objRecord.get(MARKETABILITY_RULE)==Label.Marketability_Type_Implicit_Opt_in){
                    objRecord.put(MARKETABLE_C,Label.Yes);
                    objRecord.put(MARKETABLE_DATE_C,datetime.now());
                }
                
                else {
                    /*If Marketability Rule is Unknown */
                    
                    objRecord.put(MARKETABLE_C,Label.No);
                    objRecord.put(MARKETABLE_DATE_C,null);
                
                }
            }         
                     
        
    }


}