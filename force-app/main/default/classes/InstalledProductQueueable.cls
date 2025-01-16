/***************************************************************************************************************************************
* NAME         : InstalledProductQueueable
* DESCRIPTION  : InstalledProductQueueable.
*                    
* @AUTHOR : Prakhar Kumar
* @DATE   : 08-07-2020 
* 
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------
* Prakhar               08-07-2020           Initial Version.  
* KD                    3-March-2021       DCP-43163 : [Service Loaners] No Requirement of Entitlement for Company Owned Instruments
* Pooja                 28-Nov-2022        DCP-53939 : Append "WFMR" prefix for "20090518" product
***************************************************************************************************************************************
* Test Class mapping : TestApttusOrderLineItems,TestAssociatedCodes,TestBatchToUpdateIPiSeq,TestBatchUpdateCaseStatus,TestCheckDCIR_POLHelper,TestCheckLinkedrecord_POLHelper,TestCoveredProductsQueueable,TestFANRecordListController,TestInstalledProducts,TestTAPS_Locations
*/


public with sharing  class InstalledProductQueueable implements Queueable, Database.AllowsCallouts  {
    String strMethodtoExecute;   
    set<Apttus_Config2__OrderLineItem__c> setOLI = new set<Apttus_Config2__OrderLineItem__c>();
    Set<String> setProdCode = new Set<String>();
    Set<String> setHamiltonProdCode = new Set<String>();
    Map< String , Installed_Product_Creation_Config__mdt > mapHamilton = new Map< String , Installed_Product_Creation_Config__mdt >();
    Set<Id> setIPIds = new Set<Id>();     
    public static Boolean catchException = false; 
     
   
   /*
     * constructor
     */
    public InstalledProductQueueable (String strMethodtoExecute, Set<Apttus_Config2__OrderLineItem__c> setOLI,Set<String> setHamiltonProdCode , Map<String ,Installed_Product_Creation_Config__mdt > mapHamilton, Set<Id> setIPIds){
        this.strMethodtoExecute = strMethodtoExecute;
        this.setOLI = setOLI;
        this.setHamiltonProdCode = setHamiltonProdCode;
        this.mapHamilton = mapHamilton;
		this.setIPIds = setIPIds;
    }
    
    
     /*
      *
        @author Prakhar
        @description -Holds methods that need to be Run in Queuable context from Location Class              
      *
      */

  public void execute(QueueableContext qc) 
  { 

    try{
        
          if(strMethodtoExecute=='createWFMInstalledProduct' && !mapHamilton.IsEmpty() && !setOLI.IsEmpty() && !setHamiltonProdCode.IsEmpty()){
            createWFMInstalledProduct( mapHamilton , setOLI ,setHamiltonProdCode);
          }
          
          if(strMethodtoExecute=='updateInstalledProductRecordType' && setIPIds != null && !setIPIds.isEmpty()){
            InstalledProducts.updateInstalledProductRecordType(setIPIds);
          }
          //DCP-28892
              if(strMethodtoExecute=='batchsendInstalledProductToSAP' && setIPIds != null && !setIPIds.isEmpty()){
            InstalledProducts.batchsendInstalledProductToSAP(setIPIds);
          }
          executeBillableRuleOnWDandPOL(strMethodtoExecute,setIPIds);//Codescan fix
          
        }
        catch(Exception ex){
          // class name.method as source
          ApexExceptions.emit('InstalledProductQueueable.'+strMethodtoExecute,ex,ilib_LogEvent.getWorkstream());
          ilib_LogEvent.pop();
          ilib_LogEvent.emit();
          throw ex;
        }
	} 

  /**
  * @description : Async update on work order and POL based on billable rule/ Condition to cover catch block
  **/
  public static void executeBillableRuleOnWDandPOL(String strMethodtoExecute,Set<Id> setIPIds)
  {
      // DCP-43163
      if(strMethodtoExecute == 'runBillingRuleEngine' && setIPIds != null && !setIPIds.isEmpty()){
          InstalledProducts.executeIsBillableRules(setIPIds);
      }

      //code coverage for catch block
      if(catchException == true){
        throw new AuraHandledException('throwing custom exceptions');
      }
  }
      /*
     * Method:createWFMInstalledProduct
     */
      public static void createWFMInstalledProduct( Map< String , Installed_Product_Creation_Config__mdt > mapHamilton , Set<Apttus_Config2__OrderLineItem__c> setOLI,Set<String> setHamiltonProdCode){
      List<SVMXC__Installed_Product__c> lstInstalledProducts = new List<SVMXC__Installed_Product__c>();
      Map<String,Product2> wFMProdCodeToWFMProdCodeObj = new Map <String,Product2>();
      
        //gets Ids of WFMProduct Codes.
            for(product2 prodCd : new productsSelector().selectProductFromProdCode(setHamiltonProdCode)){
                    wFMProdCodeToWFMProdCodeObj.put(prodCd.ProductCode,prodCd);
            }
      
      integer i = 1;
      integer val;
      SVMXC__Installed_Product__c latestIP = new InstalledProductsSelector().selectLatestIP();
      
      system.debug('in createWFMInstalledProduct');
            
      for(Apttus_Config2__OrderLineItem__c objOLI : setOLI ){
          for(integer k=0;k<objOLI.Apttus_Config2__Quantity__c;k++){  
              SVMXC__Installed_Product__c objIP = new SVMXC__Installed_Product__c ();
                  objIP.SVMXC__Company__c = objOLI.Ultimate_Consignee__c;
                  String wFMProductCode = mapHamilton.get(objOLI.Product_Code__c).Installed_Product_Code_Created__c;
                  objIP.SVMXC__Product__c = wFMProdCodeToWFMProdCodeObj.get(wFMProductCode).Id;
                  val = latestIP.IP_Serial_no_Auto_No__c != NULL ? Integer.valueOf( latestIP.IP_Serial_no_Auto_No__c) + i : 1;                 
                  i++;
                  String toStrVal = String.valueOf(val).leftPad(8, '0');
                  objIP.SVMXC__Serial_Lot_Number__c = mapHamilton.get(objOLI.Product_Code__c).Prefix__c + toStrVal;//DCP-53939 
                  objIP.SVMXC__Sales_Order_Number__c = objOLI.ERP_Line_Number_Id__c;
                  objIP.name = mapHamilton.get(objOLI.Product_Code__c).Prefix__c + toStrVal + '-' + mapHamilton.get(objOLI.Product_Code__c).Installed_Product_Code_Created__c ;//DCP-53939 
                  objIP.SVMXC__Status__c = 'Shipped' ; 
                  lstInstalledProducts.add(objIP); 
          }    
      }
    system.debug('lstInstalledProducts===>'+lstInstalledProducts);
    if(!lstInstalledProducts.isEmpty()){
        insert lstInstalledProducts;
    }
  } 
}