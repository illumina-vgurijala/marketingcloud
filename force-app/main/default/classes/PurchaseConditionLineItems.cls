/**
 *    @author Aditi Joshi
 *    @date   16 Sep 2020
 *    @description    Class to handle Purchase condition Line Items added from X-Author.
 *    Modification Log:
 *    ------------------------------------------------------------------------------------
 *    Developer                         Date                     Description
 *    Aditi Joshi                       16 Sep 2020              Initial Version - DCP-40043 : Create BeforeUpdate method for updating line items.
 *    Bharath Varma                     17 Sep 2020              Added onBeforeInsert - DCP-40043: Create BeforeInsert method for inserting line items
 *    Prem Ranjan                       20 Sep 2021              DCP-49424 [Q4 CLM Theme] Recording Purchase Conditions & Template updates[GIS Recommended & Conga]
 * ---------------------------------------------------------------------------------------
 */
public with sharing class PurchaseConditionLineItems extends ilib_SObjectDomain{
	
    /*Base Class*/
   public PurchaseConditionLineItems(List<Purchase_Condition_Line_Item__c> sObjectList) {
       super(sObjectList);
   }
   
   /*Boilerplate which is required for base class instantiation logic*/
   public class Constructor implements ilib_SObjectDomain.IConstructable {
       /*Construct method*/
       public ilib_SObjectDomain construct(List<SObject> sObjectList) {
           return new PurchaseConditionLineItems(sObjectList);
       }

   }
   


   /*Called during before update event */
   public override void onBeforeUpdate(Map < Id, sObject > existingRecords) {
       List < Purchase_Condition_Line_Item__c > lstPurchaseLineItem = (List < Purchase_Condition_Line_Item__c > ) records;
       List < Purchase_Condition_Line_Item__c > lstPurchaseLineItemForMaterialGroupDesc = New List < Purchase_Condition_Line_Item__c > ();
       List < Purchase_Condition_Line_Item__c > lstPurchaseLineItemForMaterialNumber = New List < Purchase_Condition_Line_Item__c > ();
       List < Purchase_Condition_Line_Item__c > lstPurchaseLineItemProductRemoval = New List < Purchase_Condition_Line_Item__c > ();
       List < Purchase_Condition_Line_Item__c > lstPurchaseLineItemForUpdatedMaterialNo = New List < Purchase_Condition_Line_Item__c > ();


       for (Purchase_Condition_Line_Item__c pCLI: lstPurchaseLineItem) {

           Purchase_Condition_Line_Item__c oPurLi = (Purchase_Condition_Line_Item__c)(existingRecords.get(pCLI.Id));

           if (pCLI.Material_Group_1__c != oPurLi.Material_Group_1__c) {
               lstPurchaseLineItemForMaterialGroupDesc.add(pCLI);
           }
           if (String.isNotBlank(pCLI.Material_Number__c) && pCLI.Material_Number__c != oPurLi.Material_Number__c) {
               lstPurchaseLineItemForMaterialNumber.add(pCLI);
           }
           if (String.isNotBlank(oPurLi.Material_Number__c) && String.isBlank(pCLI.Material_Number__c)) {
               lstPurchaseLineItemProductRemoval.add(pCLI);
           }
       }
       
       populatePurchaseConditionDetails(lstPurchaseLineItemForMaterialGroupDesc,lstPurchaseLineItemForMaterialNumber,lstPurchaseLineItemProductRemoval);

       if (lstPurchaseLineItem.size() > 0) {
           Map < Id, Purchase_Condition_Line_Item__c > idToOldAgreementLineItem = (Map < Id, Purchase_Condition_Line_Item__c > ) existingRecords;
           Set < String > updatedMaterialNumbers = New Set < String > ();
           for (Purchase_Condition_Line_Item__c oALI: lstPurchaseLineItem) {
               if (oALI.Material_Number__c != idToOldAgreementLineItem.get(oALI.id).Material_Number__c && String.isNotBlank(oALI.Material_Number__c)) {  
                   lstPurchaseLineItemForUpdatedMaterialNo.add(oALI); //updated records (material number field)
                   updatedMaterialNumbers.add(oALI.Material_Number__c);
               }
           }

           if (!lstPurchaseLineItemForUpdatedMaterialNo.isEmpty()){
               validateMaterialNumber(lstPurchaseLineItemForUpdatedMaterialNo, updatedMaterialNumbers);
           }
       }
       //populateAgreementOnPCLI(lstPurchaseLineItem);//DCP-49424
   }
   
   /*Called during before insert event*/
   public override void onBeforeInsert() {
       List < Purchase_Condition_Line_Item__c > lstPurchaseLineItem = (List < Purchase_Condition_Line_Item__c > ) records;
       List < Purchase_Condition_Line_Item__c > lstPurchaseLineItemForMaterialGroupDesc = New List < Purchase_Condition_Line_Item__c > ();
       List < Purchase_Condition_Line_Item__c > lstPurchaseLineItemForMaterialNumber = New List < Purchase_Condition_Line_Item__c > ();
       List < Purchase_Condition_Line_Item__c > lstPurchaseLineItemForUpdatedMaterialNo = New List < Purchase_Condition_Line_Item__c > ();

       for (Purchase_Condition_Line_Item__c pCLI: lstPurchaseLineItem) {

           if (String.isNotBlank(pCLI.Material_Group_1__c)) {
               lstPurchaseLineItemForMaterialGroupDesc.add(pCLI);
           }

           if (String.isNotBlank(pCLI.Material_Number__c)) {
               lstPurchaseLineItemForMaterialNumber.add(pCLI);
           }

       }
       
       populatePurchaseConditionDetails(lstPurchaseLineItemForMaterialGroupDesc,lstPurchaseLineItemForMaterialNumber,new list<Purchase_Condition_Line_Item__c>());

       if(!lstPurchaseLineItem.isEmpty()){

           Set < String > updatedMaterialNumbers = New Set < String > ();
           for (Purchase_Condition_Line_Item__c oALI: lstPurchaseLineItem) {
               if (String.isNotBlank(oALI.Material_Number__c)){
                   lstPurchaseLineItemForUpdatedMaterialNo.add(oALI);
                   updatedMaterialNumbers.add(oALI.Material_Number__c);
               }
           }

           if (!lstPurchaseLineItemForUpdatedMaterialNo.isEmpty()){
               validateMaterialNumber(lstPurchaseLineItemForUpdatedMaterialNo, updatedMaterialNumbers);
           }
       }
       populateAgreementOnPCLI(lstPurchaseLineItem);//DCP-49424
   }
   
   private void populatePurchaseConditionDetails(List < Purchase_Condition_Line_Item__c > pcLstAgreementLineItem1, List < Purchase_Condition_Line_Item__c > pcLstAgreementLineItem2, List < Purchase_Condition_Line_Item__c > pcLstAgreementLineItem3) {
       if (!pcLstAgreementLineItem1.isEmpty()) {
           populateMaterialGroup1DescPC(pcLstAgreementLineItem1);
       }
       if (!pcLstAgreementLineItem2.isEmpty()) {
           populateProduct(pcLstAgreementLineItem2);
       }
       if (!pcLstAgreementLineItem3.isEmpty()) {
           depopulateProduct(pcLstAgreementLineItem3);
       }
   }
   
   /*  populates material group1 description based on material group 1*/
   private void populateMaterialGroup1DescPC(List<Purchase_Condition_Line_Item__c> pcLstAgreementLineItem){

       Map<String,Material_Group__mdt> mapMaterialCodeToMaterialGrpMappingPC = new Map<String,Material_Group__mdt>();
       List<Material_Group__mdt> lstMaterialGrouppMappingPC = new MaterialGroupsSelector().selectAll();
       
       for(Material_Group__mdt oMaterialGroupMapping : lstMaterialGrouppMappingPC){
           mapMaterialCodeToMaterialGrpMappingPC.put(oMaterialGroupMapping.MasterLabel,oMaterialGroupMapping);
       }
       
       for(Purchase_Condition_Line_Item__c purAgrLI : pcLstAgreementLineItem){
           if(String.isNotBlank(purAgrLI.Material_Group_1__c)){
               if(mapMaterialCodeToMaterialGrpMappingPC.containskey(purAgrLI.Material_Group_1__c)){
                   purAgrLI.Material_Group_1_Description__c=mapMaterialCodeToMaterialGrpMappingPC.get(purAgrLI.Material_Group_1__c).Description__c;
               }
           }else{
               purAgrLI.Material_Group_1_Description__c='';
           }
       }

   }
   
   
   /*Method to auto populate 'Product' lookup based on 'Material Number'*/
   private void populateProduct(List<Purchase_Condition_Line_Item__c> lstPurchaseLineItem){
       set<String> setMaterialNo = new set<String>();
       Map<String,Id> mapMaterialNoProductId = new Map<String,Id>();
       Map<String,Id> mapOldMaterialNoProductId = new Map<String,Id>();
       if(!lstPurchaseLineItem.isEmpty()){
           for(Purchase_Condition_Line_Item__c oPurLI : lstPurchaseLineItem){
               if(String.isNotBlank(oPurLI.Material_Number__c)){
                   setMaterialNo.add(oPurLI.Material_Number__c);
               }
           }
       }

       if(!setMaterialNo.isEmpty()){
           List<Product2> lstProducts = new ProductsSelector().selectProductsForMaterialNumberOld(setMaterialNo);
           
           for(Product2 prd : lstProducts){
               if(String.isNotBlank(prd.Material_Number__c)){
                   mapMaterialNoProductId.put(prd.Material_Number__c,prd.Id);
               }
               if(String.isNotBlank(prd.Old_Material_Number__c)){
                   mapOldMaterialNoProductId.put(prd.Old_Material_Number__c,prd.Id);
               }
                   
           }
           
           for(Purchase_Condition_Line_Item__c oPurLI : lstPurchaseLineItem){
               if(String.isNotBlank(oPurLI.Material_Number__c) ){
                   if(!mapMaterialNoProductId.isEmpty() &&
                      mapMaterialNoProductId.containsKey(oPurLI.Material_Number__c)){
                          oPurLI.Product__c = mapMaterialNoProductId.get(oPurLI.Material_Number__c);
                      }
                   else if(!mapOldMaterialNoProductId.isEmpty() &&
                           mapOldMaterialNoProductId.containsKey(oPurLI.Material_Number__c)){
                               oPurLI.Product__c = mapOldMaterialNoProductId.get(oPurLI.Material_Number__c);
                           }
                   else{
                       oPurLI.Product__c = null;
                       }
               }

           }
       }
   }	
   
   /*Method to depopulate 'Product' if 'Material Number' is updated and made blank*/
   private void depopulateProduct(List<Purchase_Condition_Line_Item__c> lstPurchaseLineItem){
       if(!lstPurchaseLineItem.isEmpty()){
           for(Purchase_Condition_Line_Item__c oPurLI : lstPurchaseLineItem){
               if(String.isBlank(oPurLI.Material_Number__c)){
                   oPurLI.Product__c = null;
               }
           }
       }
   }
   
   /*Method to validate 'Material Number' and throw error for invalid Material Number*/
   public void validateMaterialNumber(List<Purchase_Condition_Line_Item__c> updatedRecords,Set<String> setupdatedMaterialNumbers){
       
       
       Map<string,id> idtoMaterialNoMap = new Map<string,id>();
       Map<string,id> idtoOldMaterialNoMap = new Map<string,id>();
       
       List<Product2> lstProducts = new ProductsSelector().selectProductsForMaterialNumberOld(setupdatedMaterialNumbers);

       if(!lstProducts.isEmpty()){ 
           for(Product2 oProd : lstProducts){
               if(String.isNotBlank(oProd.Material_Number__c)){
                   idtoMaterialNoMap.put(oProd.Material_Number__c,oProd.Id);
               }
               if(String.isNotBlank(oProd.Old_Material_Number__c)){
                   idtoOldMaterialNoMap.put(oProd.Old_Material_Number__c,oProd.Id);
               }
           }
       }

       for(Purchase_Condition_Line_Item__c oPurLI:updatedRecords){
               
           if( ((idtoMaterialNoMap.isEmpty()) && (idtoOldMaterialNoMap.isEmpty())) || (!(idtoMaterialNoMap.containskey(oPurLI.Material_Number__c)) && !(idtoOldMaterialNoMap.containskey(oPurLI.Material_Number__c)))){
               oPurLI.adderror(Label.UI_Material_Number_Not_Valid_Part1+oPurLI.Material_Number__c+Label.UI_Material_Number_Not_Valid_Part2);
           }
       }
   }
   /* 
   @Author : Prem Ranjan
   @Description : DCP-49424 Method to Populate Agreemnt on Purchace Condition Line Item 
   */
   public void populateAgreementOnPCLI(List<Purchase_Condition_Line_Item__c> pcliRecords){
       Set<ID> setPCIds = new Set<ID>();
       for(Purchase_Condition_Line_Item__c pCLI : pcliRecords){
           if(pCLI.Purchase_Condition__c != null){
               setPCIds.add(pCLI.Purchase_Condition__c);
           }
       }  
        Map<Id,Purchase_Conditions__c> mapPC = new Map<Id,Purchase_Conditions__c>(new PurchaseConditionSelectors().selectAllRecordsById(setPCIds));
       for (Purchase_Condition_Line_Item__c pCLI: pcliRecords) {
           if(pCLI.Purchase_Condition__c != null && pCLI.Agreement__c == null )
           {
           pCLI.Agreement__c = mapPC.get(pCLI.Purchase_Condition__c).Agreement__c;
           }
       }
   }
}