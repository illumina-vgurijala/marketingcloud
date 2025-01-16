/**
*    @author: Pankaj Singla
*    @date:   08-Sept-2020
*    @description:  Handler Class for Promotions Trigger
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Pankaj Singla              08 Sept 2020           Initial Build
*             Aman Tyagi                 31 March 2022          Codescan Fixes             
*    ------------------------------------------------------------------------------------ 
*                    
*/
public with sharing class Promotions extends ilib_SObjectDomain{
    /*Map for Mapping between Promotions and Incentive Fields*/
	public Map<String,String> mapPromotionFieldtoIncentiveField=new Map<String,String>();

    /*
    * @Author: Pankaj Singla 
    * @Description : parameterized constructor of class Promotions and instantiating Promotions__c
    * @param :List<Promotions__c> sObjectList
    */
	public Promotions(List<Promotions__c> sObjectList){
        super(sObjectList);
        /*Create the map in constructor as it would be required in both insert and update scenarios*/
        for(Promotion_To_Incentive_Mapping__mdt obj: new PromotionToIncentiveMDTSelector().selectActiveRecords()){
            /*If the Particular promotion field is mapped to multiple incentive fields, then separate the incentive 
			fields using the ;*/
             if(mapPromotionFieldtoIncentiveField.containsKey(obj.Promotion_Field_Name__c)){
				 String strIncentiveFieldName=mapPromotionFieldtoIncentiveField.get(obj.Promotion_Field_Name__c);
				 strIncentiveFieldName=strIncentiveFieldName+';'+obj.Incentive_Field_Name__c;
				 mapPromotionFieldtoIncentiveField.put(obj.Promotion_Field_Name__c,strIncentiveFieldName);
				 
			 }
             else {
				mapPromotionFieldtoIncentiveField.put(obj.Promotion_Field_Name__c,obj.Incentive_Field_Name__c); 
			 }
			 
        }
    }
	/*
    * Boilerplate which is required for base class instantiation logic
    */
    public class Constructor implements ilib_SObjectDomain.IConstructable{

        /*
        * @Author: Pankaj Singla 
        * @Description : parameterized constructor of base class
        * @param : List<SObject> sObjectList
        */
		public ilib_SObjectDomain construct(List<SObject> sObjectList){
			return new Promotions(sObjectList);
		}
	}
	/**
     * @author Pankaj Singla
     * @date   2020-09-08
     * @description  After insert trigger method
     * 
     **/
	public override void onAfterInsert(){
		List<Promotions__c> lstPromotionRecords=(List<Promotions__c>)records;
        List<Apttus_Config2__Incentive__c> lstIncentive=new List<Apttus_Config2__Incentive__c>();
        /*Loop over all the incentive records in the trigger*/
        for(Promotions__c objPromotion:lstPromotionRecords){
            Apttus_Config2__Incentive__c objIncentive=new Apttus_Config2__Incentive__c();
            /*Copy the fields from Promotion to Incentive record using custom metadata*/
            /*Loop over all the custom metadata records which contains the mapping*/
            for(String strPromotionField:mapPromotionFieldtoIncentiveField.keySet()){
                 /*Copy only non blank promotion fields*/
				if(!String.isBlank(String.valueOf(objPromotion.get(strPromotionField)))){                   
					String strIncentiveFieldAPINames=mapPromotionFieldtoIncentiveField.get(strPromotionField);
					List<String> lstIncentiveFieldAPINames;
                    /*A single field is mapped to multiple fields*/
					if(strIncentiveFieldAPINames.contains(';')){
						lstIncentiveFieldAPINames=strIncentiveFieldAPINames.split(';');
                        /*Set all the incentive fields to single promotion field*/
						for(String strIncentiveFieldAPIName:lstIncentiveFieldAPINames){
							 objIncentive.put(strIncentiveFieldAPIName,objPromotion.get(strPromotionField));
						}
					
					}
                    /*If the promotion field and incentive field has 1 to 1 mapping*/
					else{
						objIncentive.put(strIncentiveFieldAPINames,objPromotion.get(strPromotionField));
					}
				}
			}
            /*Set Sequence Id */
            objIncentive.Apttus_Config2__Sequence__c=1;
            /*Related the incentive record to parent promotion record*/
            objIncentive.Master_Promotions__c=objPromotion.Id;
            lstIncentive.add(objIncentive);
        }
		
        if(lstIncentive.size()>0){
            insert lstIncentive;
        }		
	}
    /**
     * @author Pankaj Singla
     * @date   2020-09-08
     * @description  After after trigger method
     * 
     **/
    public override void onAfterupdate(Map<Id, sObject> oldRecords){
        List<Promotions__c> lstNewPromotions = (List<Promotions__c>) records;
        Map<Id,Apttus_Config2__Incentive__c> mapPromotionIdToIncentive=new Map<Id,Apttus_Config2__Incentive__c>();
        Set<Id> setPromotionIds=new Set<Id>();
         List<Apttus_Config2__Incentive__c> lstIncentive=new List<Apttus_Config2__Incentive__c>();
        for(Promotions__c objPromotion:lstNewPromotions){
            setPromotionIds.add(objPromotion.Id);
        }
        /*create map of promotion and related Incentive records*/
        for(Apttus_Config2__Incentive__c objIncentive:new IncentiveSelector().selectIncentiveList(setPromotionIds)){
        	mapPromotionIdToIncentive.put(objIncentive.Master_Promotions__c,objIncentive);                                                   
        }
        
        for(Promotions__c objPromotionNew:lstNewPromotions){
            Promotions__c objOldpromotion = (Promotions__c)oldRecords.get(objPromotionNew.Id);
            Apttus_Config2__Incentive__c objIncentive;
            /*If the incentive record already exists*/
            if(mapPromotionIdToIncentive.containsKey(objPromotionNew.Id)){
                objIncentive=mapPromotionIdToIncentive.get(objPromotionNew.Id);
            }
            /*create a new incentive record*/
            else {
                objIncentive=new Apttus_Config2__Incentive__c();
                objIncentive.Apttus_Config2__Sequence__c=1;
            	objIncentive.Master_Promotions__c=objPromotionNew.Id;
            }
            /*Copy the updated field values from Promotion to Incentive Record*/
            for(String strPromotionField:mapPromotionFieldtoIncentiveField.keySet()){
                /*Copy only the updated Promotion fields*/
				if(objPromotionNew.get(strPromotionField)!=objOldpromotion.get(strPromotionField)){
					 String strIncentiveFieldAPINames=mapPromotionFieldtoIncentiveField.get(strPromotionField);
                     /*one to many mapping between promotion and incentive field*/
					 if(strIncentiveFieldAPINames.contains(';')){
						 List<String> lstIncentiveFieldNames=strIncentiveFieldAPINames.split(';');
						 for(String strIncentiveFieldAPIName:lstIncentiveFieldNames){
							 objIncentive.put(strIncentiveFieldAPIName,objPromotionNew.get(strPromotionField));
						 }
						 
					 }
                    /*one to one mapping of promotion and incentive field*/
					 else{
						 objIncentive.put(strIncentiveFieldAPINames,objPromotionNew.get(strPromotionField));
					 }
				}
                
            }
            lstIncentive.add(objIncentive);
        }
        
        if(lstIncentive.size()>0){
            upsert lstIncentive;
        }

    }
}