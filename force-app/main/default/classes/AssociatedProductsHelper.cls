/**************************************************************************************************************************************
* NAME   : AssociatedProductsHelper
* DESCRIPTION  : Domain class for AssociatedProductsHelper.
* Test Class- TestAssociatedProduct.cls
*  
*                    
* @AUTHOR : Nitin Z 
* @DATE   : 13-jun -2024  
*  
* MODIFICATION LOG: 
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------
  Nitin Z                  13-jun -2024   

****************************************************************************************************************************************/ 


public with sharing class AssociatedProductsHelper {
    public static final String OPERATION_INSERT='afterinsert';
    public static final String OPERATION_UPDATE='afterupdate';
    public static final String OPERATION_DELETE='afterdelete';

    private string operation;
    private  Map<Id,Associated_Product__c> oldMap = new  Map<Id,Associated_Product__c>();
    private  Map<Id,Associated_Product__c> newMap = new  Map<Id,Associated_Product__c>();
    
    
    /*
    * @author - Nitin Z
    * @Description- Constructor that taked oldmap,newmap and operation as parameter
    */
    public AssociatedProductsHelper(String  operation,Map<Id,Associated_Product__c> oldMap,Map<Id,Associated_Product__c> newMap){
            this.operation=operation;
            this.oldMap=oldMap;
            this.newMap=newMap;
    }

    /*
    * @author - Nitin Z
    * @Description- update IVD_Product_Identifier_Additional_Prod__c  on case depending upon operation CMCM-8106
    */
    public void updateIVDOnCase(){
        if(operation==OPERATION_INSERT){
            updateIVDAfterAPInsert();
        }else if(operation==OPERATION_UPDATE) { 
            updateIVDOnCaseAfterUpdate();
        }else if(operation==OPERATION_DELETE) {
            updateCaseWithAdditionalIVDFalseAfterDelete();
        }
    }

    /*
    * @author - Nitin Z
    * @Description- update IVD_Product_Identifier_Additional_Prod__c  After AP Insert CMCM-8106
    */
    private void updateIVDAfterAPInsert(){

        Set<Id> setCaseIds = new Set<Id>();
        List<Case> lstCasesToBeUpdated =  new List<Case>();
        for(Associated_Product__c objAsscociatedProduct : newMap.values()){
            if(objAsscociatedProduct.IVD_Product_Identifier__c == true && objAsscociatedProduct.Case__c != null){
                setCaseIds.add(objAsscociatedProduct.Case__c);
            }
        }
        
        if(setCaseIds != null && setCaseIds.size() >0){
            for(Case objCase : new CasesSelector().selectCasesWithCaseID(setCaseIds)){ 
                if(objCase.IVD_Product_Identifier_Additional_Prod__c != true){
                    objCase.IVD_Product_Identifier_Additional_Prod__c = true;
                    lstCasesToBeUpdated.add(objCase);
                }
            }
        }
        
        if(lstCasesToBeUpdated.size() >0){
            Cases.skipCaseTrigger = true;
            Cases.isIVDProductIdentifierAdditionalProdUpdated = true;
            update lstCasesToBeUpdated;
        }
    }

    /*
    * @author - Nitin Z
    * @Description- update IVD_Product_Identifier_Additional_Prod__c  After AP delete  CMCM-8106
    */
    private void updateCaseWithAdditionalIVDFalseAfterDelete(){
        Set<Id> caseIdsWithUpdatesIVDFalse = new Set<Id> ();   
        List<Case> lstCaseToBeUpdatedAddIVDFalse = new List<Case>();
        Set<Id> setCaseIdsWithAdditionalIVD = new Set<Id>();

        for(Associated_Product__c objAssociatedProduct:oldMap.values()){
            if(objAssociatedProduct.IVD_Product_Identifier__c == true && objAssociatedProduct.Case__c != null){
                caseIdsWithUpdatesIVDFalse.add(objAssociatedProduct.Case__c);
            }
        }
        
        if(caseIdsWithUpdatesIVDFalse.size() > 0){
            for(Associated_Product__c objAsscociatedProduct : new AssociatedProductSelector().selectAPwithCase(caseIdsWithUpdatesIVDFalse)){
                if(objAsscociatedProduct.IVD_Product_Identifier__c == true && objAsscociatedProduct.Case__c != null){
                    setCaseIdsWithAdditionalIVD.add(objAsscociatedProduct.Case__c);
                }           
            }
            for(Id caseId : caseIdsWithUpdatesIVDFalse ){
                if(!setCaseIdsWithAdditionalIVD.contains(caseId)){
                    Case objCase = new Case(IVD_Product_Identifier_Additional_Prod__c = false, Id =caseId ); 
                    lstCaseToBeUpdatedAddIVDFalse.add(objCase);
                }
            }
            if(lstCaseToBeUpdatedAddIVDFalse.size() > 0){
                 Cases.skipCaseTrigger = true;
                 Cases.isIVDProductIdentifierAdditionalProdUpdated = true;
                 update lstCaseToBeUpdatedAddIVDFalse;
            }
        }
    }

    /*
    * @author - Nitin Z
    * @Description- update IVD_Product_Identifier_Additional_Prod__c  After AP update   CMCM-8106
    */
    private void updateIVDOnCaseAfterUpdate(){
        System.debug('TT updateIVDOnCase '+operation);
        Set<Id> caseIdsWithUpdatesIVDFalse = new Set<Id>();
        Map<Id,Case> mapCaseToUpdateIVDFalse= new Map<Id,Case>();
        Map<Id,Case> mapCaseToUpdateIVDTrue= new Map<Id,Case>();

        
        for(Id idCaseLine : newMap.keySet()){
            
            Associated_Product__c objNewCaseLine = (Associated_Product__c)newMap.get(idCaseLine);
            Associated_Product__c objOldCaseLine = (Associated_Product__c)oldMap.get(idCaseLine);
            
             if(objNewCaseLine.IVD_Product_Identifier__c == false && objOldCaseLine.IVD_Product_Identifier__c==true && objNewCaseLine.Case__c != null){
                caseIdsWithUpdatesIVDFalse.add(objNewCaseLine.Case__c);
                mapCaseToUpdateIVDFalse.put(objNewCaseLine.Case__c,new Case(IVD_Product_Identifier_Additional_Prod__c = false, Id =objNewCaseLine.Case__c));
             }else if(objNewCaseLine.IVD_Product_Identifier__c == true && objOldCaseLine.IVD_Product_Identifier__c==false && objNewCaseLine.Case__c != null){
                caseIdsWithUpdatesIVDFalse.add(objNewCaseLine.Case__c);
                mapCaseToUpdateIVDTrue.put(objNewCaseLine.Case__c,new Case(IVD_Product_Identifier_Additional_Prod__c = true, Id =objNewCaseLine.Case__c));
             }
        }

                if(caseIdsWithUpdatesIVDFalse.size() > 0){
                    for(Associated_Product__c objAsscociatedProduct : new AssociatedProductSelector().selectAPwithCase(caseIdsWithUpdatesIVDFalse)){
                        if(mapCaseToUpdateIVDFalse.containsKey(objAsscociatedProduct.Case__c) && objAsscociatedProduct.IVD_Product_Identifier__c == true ){
                            mapCaseToUpdateIVDFalse.remove(objAsscociatedProduct.Case__c);
                        }else if(mapCaseToUpdateIVDTrue.containsKey(objAsscociatedProduct.Case__c) && objAsscociatedProduct.IVD_Product_Identifier__c == false){
                            mapCaseToUpdateIVDTrue.remove(objAsscociatedProduct.Case__c);
                        }           
                    }
                }
            if(mapCaseToUpdateIVDFalse.size()>0){
                Cases.skipCaseTrigger = true;
                Cases.isIVDProductIdentifierAdditionalProdUpdated = true;
                update mapCaseToUpdateIVDFalse.values();
            }
            if(mapCaseToUpdateIVDTrue.size()>0){
                Cases.skipCaseTrigger = true;
                Cases.isIVDProductIdentifierAdditionalProdUpdated = true;
                update mapCaseToUpdateIVDTrue.values();
            }
    }
}