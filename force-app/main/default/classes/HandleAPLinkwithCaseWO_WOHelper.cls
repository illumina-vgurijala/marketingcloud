/**
* @author Siddartha Reddy Kalam
* @date 18th March 2022
*
* @description CMCM-5782 Helper Class for Work Order Trigger to run logic related to Associated Products Link with Case and WO
*
* MODIFICATION LOG: 
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------
* Siddartha Reddy Kalam   18-Mar-2024          CMCM-5782 - Associated Product Links to Case and Work Order when WO is created/updated with new case
* --------------------------------------------------------------------------------------------------------------------------------------
*/
public with sharing class HandleAPLinkwithCaseWO_WOHelper {
    public static final String LOG_TITLE = 'HandleAPLinkwithCaseWO_WOHelper';
    public static final Integer ONE = 1;
    public static final Integer TWO = 2;
    public static final String CONVERTED_TO_BI_CASE = 'Converted to BI Case'; //Added for CMCM-8242
    
    /**
    *  @author Siddartha Reddy Kalam
    *  @description - To check if Case lookup is updated on standalone WO or is changed.
    *  @parameters : records: List<Id> - List of new WO records
    *         		 recordsOldMap : Map<Id, SObject> - Map of work orders old record with non completion status
    *  @return : void
    **/
	public static void verifyCaseIsChanged(List<SObject> records,Map<Id, SObject> recordsOldMap){
            ilib_LogEvent.push(LOG_TITLE + '.verifyCaseIsChanged()');
            set<Id> setCaseIds = new set<Id>();
            set<Id> setWOIds = new set<Id>();
            List<Associated_Product__c> listAPswithPrimary = new List<Associated_Product__c>();
            List<Associated_Product__c> listtoUpdateAssociatedProducts = new List<Associated_Product__c>();
            for(SVMXC__Service_Order__c objWO:(List<SVMXC__Service_Order__c>)records){
                SVMXC__Service_Order__c newWO = (SVMXC__Service_Order__c)objWO;
                SVMXC__Service_Order__c oldWO = (SVMXC__Service_Order__c)recordsOldMap.get(objWO.Id);
                if((oldWO.SVMXC__Case__c==null && newWO.SVMXC__Case__c!=null && newWO.SVMXC__Case__c!=oldWO.SVMXC__Case__c)||(newWO.SVMXC__Case__c!=oldWO.SVMXC__Case__c && newWO.SVMXC__Case__c!=null)){
                    setCaseIds.add(newWO.SVMXC__Case__c);
                    setWOIds.add(newWO.Id);
                }
            }

            Savepoint sp = Database.setSavepoint();
            Set<Associated_Product__c> updateAssociatedProducts = getAssociatedProductsfromCaseWO(records,setCaseIds,setWOIds);
            try{
                if(!updateAssociatedProducts.isEmpty()){
                    listtoUpdateAssociatedProducts.addAll(updateAssociatedProducts);
                }

                listAPswithPrimary = checkAPhasIsPrimary(listtoUpdateAssociatedProducts);
                for(SVMXC__Service_Order__c objWorkOrder:(List<SVMXC__Service_Order__c>)records){
                if(listAPswithPrimary.size()>ONE){
                    objWorkOrder.addError(System.Label.CheckAPofCaseWOHasIsprimary);   
                }
                }                      
                if(Schema.sObjectType.Associated_Product__c.isUpdateable() && !listtoUpdateAssociatedProducts.isEmpty() &&listAPswithPrimary.size()<TWO){
                    AssociatedProduct.skipAPTrigger = true;
                    AssociatedProduct.isAPLinkwithCaseWOUpdate = true;
                    update listtoUpdateAssociatedProducts; 
                }     
                ilib_LogEvent.pop();
                ilib_LogEvent.emit(); 
            } catch(Exception e){
                ApexExceptions.emit(LOG_TITLE,e);
                ilib_LogEvent.message(LOG_TITLE+'.Exception: ' + e.getMessage());
                Database.rollback(sp);
                throw e;
            }                  
    }

    /**
    *  @author Siddartha Reddy Kalam
    *  @description - To get list AP records. 
    *  @parameters : listtoUpdateAssociatedProducts: List<Associated_Product__c> - List of Associated Products records
    *  @return : List of Associated Product records with Is_Primary__c true.
    **/
    private static List<Associated_Product__c> checkAPhasIsPrimary(List<Associated_Product__c> listtoUpdateAssociatedProducts){
        List<Associated_Product__c> listAPswithPrimary = new List<Associated_Product__c>();
        for(Associated_Product__c objAP :listtoUpdateAssociatedProducts){
            if(objAP.Is_Primary__c==true){
                listAPswithPrimary.add(objAP);
            }    
        }
        return listAPswithPrimary;
    }
    
    
    /**
    *  @author Siddartha Reddy Kalam
    *  @description - To get case and WO related AP records. 
    *  @parameters : records: List<Id> - List of new WO records
    *         		 setCaseIds : Set<Id> - Set of Case Ids from WO
    * 				 setWOIds : Set<Id> - Set of WO record Ids
    *  @return : Set of Associated Product records to update.
    **/
    private static Set<Associated_Product__c> getAssociatedProductsfromCaseWO(List<SObject> records,Set<Id> setCaseIds,Set<Id> setWOIds){
        ilib_LogEvent.push(LOG_TITLE + '.getAssociatedProductsfromCaseWO()');
        Set<Associated_Product__c> setUpdateAssociatedProducts = new Set<Associated_Product__c>();
        
            if(setWOIds!=null && !setWOIds.isEmpty()){
                        for(Associated_Product__c objAPWO : AssociatedProduct.linkAPsfromWO(setWOIds)){
                            for(SVMXC__Service_Order__c objnewWO:(List<SVMXC__Service_Order__c>)records){
                                objAPWO.Case__c = objnewWO.SVMXC__Case__c;
                                setUpdateAssociatedProducts.add(objAPWO);
                            }                            
                            }
                        }

            if(setCaseIds!=null && !setCaseIds.isEmpty()){               
                        for(Associated_Product__c objAPCase : AssociatedProduct.linkAPsfromCase(setCaseIds)){
                            for(SVMXC__Service_Order__c objnewWO1:(List<SVMXC__Service_Order__c>)records){
                            objAPCase.Work_Order__c = objnewWO1.Id;
                            setUpdateAssociatedProducts.add(objAPCase);
                            }
                        }
                    }
       return setUpdateAssociatedProducts;             
    }
    
    
    /**
    *  @author Siddartha Reddy Kalam
    *  @description - To check if Case lookup is populated on work order creation.
    *  @parameters : records: List<Id> - List of new WO records
    *  @return : void
    **/
    public static void updateAPsfromCaseonWO(List<SObject> records) {
        ilib_LogEvent.push(LOG_TITLE + '.updateAPsfromCaseonWO()');
        set<Id> setCaseIds = new set<Id>();
        List<Associated_Product__c> listtoUpdateAssociatedProducts = new List<Associated_Product__c>();
        Map<Id,Case> relatedCasesMap = new Map<Id,Case> (WorkOrders.lstCaserecords); //Added for CMCM-8242

        for(SVMXC__Service_Order__c objWO:(List<SVMXC__Service_Order__c>)records){
            SVMXC__Service_Order__c newWO = (SVMXC__Service_Order__c)objWO;
            if(newWO.SVMXC__Case__c!=null &&
                    //Added following conditions for CMCM-8242
                    ((!relatedCasesMap.isEmpty() &&
                    relatedCasesMap.get(newWO.SVMXC__Case__c)?.Record_Edit_Source__c == CONVERTED_TO_BI_CASE) ||
                    newWO.Record_Created_from_SFM__c == true)) {
                setCaseIds.add(newWO.SVMXC__Case__c);
            }
        }

        Set<Associated_Product__c> updateAssociatedProducts = getAssociatedProductsfromCaseWO(records,setCaseIds,null);
        try{
            if(!updateAssociatedProducts.isEmpty()){
                listtoUpdateAssociatedProducts.addAll(updateAssociatedProducts);
            }
                            
            if(Schema.sObjectType.Associated_Product__c.isUpdateable() && !listtoUpdateAssociatedProducts.isEmpty()){
                AssociatedProduct.skipAPTrigger = true;
                AssociatedProduct.isAPLinkwithCaseWOUpdate = true;
                update listtoUpdateAssociatedProducts; 
            }     
            ilib_LogEvent.pop();
            ilib_LogEvent.emit(); 
        } catch(Exception e){ 
            ApexExceptions.emit(LOG_TITLE,e);
            ilib_LogEvent.message(LOG_TITLE+'.Exception: ' + e.getMessage());
        }                  
    }
}