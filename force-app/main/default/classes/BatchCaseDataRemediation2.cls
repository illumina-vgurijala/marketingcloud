/**************************************************************************************************************************************
* NAME   : BatchCaseDataRemediation2
* DESCRIPTION  : Domain class for v.
* Test Class- TestBatchCaseDataRemediation2.cls
*  
*                    
* @AUTHOR : Nitin Z 
* @DATE   : 25 -jun -2024  
*  
* MODIFICATION LOG: 
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------
  Nitin Z                  25-jun -2024   

****************************************************************************************************************************************/ 

global class BatchCaseDataRemediation2 implements Database.Batchable<sObject>, Database.Stateful {
    Integer aPcount=0;
    Integer caseLinecount=0;
    Integer caseCount=0;
    Integer recordLimit=0; 
  

   /*
   * @author - Nitin Z
   * @Description-  start method
   */
   
   public BatchCaseDataRemediation2(Integer mLimit){
       this.recordLimit=mLimit;
   }

    /*
   * @author - Nitin Z
   * @Description-   empty cunstructor
   */
    public BatchCaseDataRemediation2(){
   }
 
     /*
    * @author - Nitin Z
    * @Description-  start method
    */
    global Database.QueryLocator start(Database.BatchableContext bc) {
        Id recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Elevation')?.getRecordTypeId();

        String query = 'SELECT id,Installed_Product_Upgrade_Type__c,Origin,Status,Date_Time_Completed__c,Product_Lot_Number__c,Product_Serial_Number__c,CreatedById,Expired_Reagent__c,Software_Version__c,OwnerId,Legacy_SFDC_Record_ID__c,SVMXC__Product__c,Subscription__c,SVMXC__Component__c,'+
            ' Work_Order__c,Work_Order__r.SVMXC__Case__c, Work_Order__r.SVMXC__Component__c,Work_Order__r.Subscription__c,Work_Order__r.SVMXC__Product__c,Work_Order__r.Product_Lot_Number__c,Work_Order__r.Product_Serial_Number__c,Work_Order__r.CreatedById,Work_Order__r.OwnerId from case ' +
             'WHERE ' +
                 '  ((Status != \'Closed\' AND ' +
                 '   Status != \'Completed\' AND ' +
                 '   Status != \'Closed-Duplicate\') ' +
                 '  OR ' +
                 '  (Date_Time_Completed__c >= 2022-08-01T00:00:00Z AND ' +
                 '   (Status = \'Closed\' OR ' +
                 '    Status = \'Completed\' OR ' +
                 '    Status = \'Closed-Duplicate\')) ' +
                 '  OR ' +
                 '  (Origin = \'Auto generated\')) and  AP_Conversion_Flag__C != \'PROCESSED\''+
                   '  AND RecordTypeId != :recordTypeId ' + 
                  '   ' + ( this.recordLimit==0 ? '':' Limit '+this.recordLimit);
          
      return Database.getQueryLocator(query);

    }

     /*
    * @author - Nitin Z
    * @Description-  execute method
    */
    global void execute(Database.BatchableContext bc, List<Case> scope) {
        
        List<case> caseListToBeupdateList = new   List<case>();
        List<SVMXC__Case_Line__c> caseLineListToBeupdateList = new   List<SVMXC__Case_Line__c>();
		List<Associated_Product__c> apListToBeInserted = new List<Associated_Product__c>();
        Map<Id,List<SVMXC__Case_Line__c>> mapCaseWithCaseLine = new Map<Id,List<SVMXC__Case_Line__c>>();



        Set<Id> ids = new Set<Id>(new Map<Id, Case>(scope).keySet());
        
		List<SVMXC__Case_Line__c> listCaseLine=  [SELECT Id,CreatedById,CreatedDate,LastModifiedDate,LastmodifiedbyID,Recall_Activity__c,SVMXC__Case__c,Expiration_Date__c,SVMXC__Installed_Product__c,svmxc__product__c,Installed_Product_Upgrade_Type__c,IsExpired__c,proactive_run_detail__c,Product_Lot_Number__c,Product_Serial_Number__c,Reason_Recall_Not_Performed_Declined__c,SVMXC__Case__r.Date_Time_Completed__c,SVMXC__Case__r.Origin,svmxc__case__r.Work_order__c FROM SVMXC__Case_Line__c where   (NOT (Associated_Product__c = 'PROCESSED'))  and SVMXC__Case__c in: ids];
 		List<SVMXC__Case_Line__c> tesmp= new  List<SVMXC__Case_Line__c>();
       
        for(SVMXC__Case_Line__c caseineObject:listCaseLine){
            
            if(mapCaseWithCaseLine.containsKey(caseineObject.SVMXC__Case__c)){
                tesmp=mapCaseWithCaseLine.get(caseineObject.SVMXC__Case__c);
                tesmp.add(caseineObject);
                mapCaseWithCaseLine.put(caseineObject.SVMXC__Case__c, tesmp);
            }else{
                tesmp= new  List<SVMXC__Case_Line__c>();
                tesmp.add(caseineObject);
                mapCaseWithCaseLine.put(caseineObject.SVMXC__Case__c, tesmp);
            }
            
        }

        for(Case caseObj:scope){
            APPRoceessedData  aPPRoceessedDataObject= new APPRoceessedData();
            
            if(mapCaseWithCaseLine.containsKey(caseObj.Id)){
                aPPRoceessedDataObject=getNonPrimaryAssociatedProductWithCase(mapCaseWithCaseLine.get(caseObj.Id));  
            }
            
            aPPRoceessedDataObject.associatedProductList.addAll(getPrimaryAssociatedProductOnCase(caseObj));
            aPPRoceessedDataObject.associatedProductList.addAll(getAssociatedProductOnWorkOrders(caseObj));
            caseObj.AP_Conversion_Flag__C='PROCESSED';
    
            caseListToBeupdateList.add(caseObj);
            caseLineListToBeupdateList.addAll(aPPRoceessedDataObject.caseLineList);
            apListToBeInserted.addAll(aPPRoceessedDataObject.associatedProductList);
             
        }
        update caseListToBeupdateList;
        update caseLineListToBeupdateList;
        insert apListToBeInserted;
        caseCount=caseCount+caseListToBeupdateList.size();
        caseLinecount=caseLinecount+caseLineListToBeupdateList.size();
        aPcount=aPcount+apListToBeInserted.size();
      
        
    }

 
    /*
    * @author - Nitin Z
    * @Description-  finishs method
    */
    global void finish(Database.BatchableContext bc) {
        System.debug('Batch processing completed.');
        System.debug('Batch processing aPcount. '+aPcount);
        System.debug('Batch processing caseLinecount. '+caseLinecount);
        System.debug('Batch processing caseCount. '+caseCount);
        sendEmail(caseCount,caseLinecount,aPcount);
    }

  
    private APPRoceessedData  getNonPrimaryAssociatedProductWithCase(List<SVMXC__Case_Line__c> caseLineListFromCase){
      List<Associated_Product__c> listCaseAssociatedProduct= new   List<Associated_Product__c>();
      List<SVMXC__Case_Line__c> caseLineList= new   List<SVMXC__Case_Line__c>();
  
      APPRoceessedData aPPRoceessedDataObject= new   APPRoceessedData();

        if(caseLineListFromCase.size()>0){
            listCaseAssociatedProduct= new   List<Associated_Product__c>();
            for(SVMXC__Case_Line__c caseLine:caseLineListFromCase){
                        Associated_Product__c ap= new Associated_Product__c();
                        ap.Case__c = caseLine.SVMXC__Case__c;
                        ap.Case_Line_ID__c=Id.valueOf(caseline.id); 
                        
                        if(Caseline.Expiration_Date__c!=null){
                            ap.Expired_Date__c = Caseline.Expiration_Date__c.date();
                        }
                        
                        ap.Installed_Product__c=caseline.SVMXC__Installed_Product__c;
                        ap.Product__c=caseline.svmxc__product__c;
                        ap.Installed_Product_Upgrade_Type__c=caseline.Installed_Product_Upgrade_Type__c;
                        ap.Is_expired__c=caseline.IsExpired__c;
                        //ap.LastmodifiedDate=caseline.LastmodifiedDate;
                        ap.CreatedDate=Caseline.CreatedDate;
                        ap.OwnerId=caseline.createdbyId;
                        ap.Proactive_run_detail__c = caseline.proactive_run_detail__c;
                        ap.Product_Lot_Number__c=caseline.Product_Lot_Number__c;
                        ap.Product_Serial_Number__c= caseline.Product_Serial_Number__c;
                        ap.Reason_Recall_Not_Performed_Declined__c=caseline.Reason_Recall_Not_Performed_Declined__c;
                        ap.Recall_activity__c=caseline.Recall_activity__c;
                        ap.Work_Order__c=Caseline.svmxc__case__r.Work_order__c;
                		caseLine.Associated_Product__c='PROCESSED';

                       
                		caseLineList.add(caseLine);
                        listCaseAssociatedProduct.add(ap);
                }            
        }
        
        aPPRoceessedDataObject.associatedProductList=listCaseAssociatedProduct;
        aPPRoceessedDataObject.caseLineList=caseLineList;        
        return aPPRoceessedDataObject;

    }
    private List<Associated_Product__c> getPrimaryAssociatedProductOnCase(Case caseObj){
        
      List<Associated_Product__c> listCaseAssociatedProduct= new   List<Associated_Product__c>();
      boolean isPrimaryFound=false;  
      Associated_Product__c  ap; 
      if(caseObj.SVMXC__Component__c!=null ){
             ap= getAPObjectFromCase(caseObj);
             ap.Is_Primary__c=true;
             ap.Installed_Product__c=caseObj.SVMXC__Component__c;
             ap.Product__c=caseObj.SVMXC__Product__c;

             isPrimaryFound=true;
             listCaseAssociatedProduct.add(ap);
        } 
        
        if( caseObj.Subscription__c!=null){
             ap= getAPObjectFromCase(caseObj);
             ap.Is_Primary__c=isPrimaryFound ? false: true;
             ap.Subscription__c=caseObj.Subscription__c;
             //ap.Product__c=caseObj.SVMXC__Product__c;
             ap.Product__c=isPrimaryFound?null:caseObj.SVMXC__Product__c;
             isPrimaryFound=true;  
             listCaseAssociatedProduct.add(ap);
        }
        
        if(caseObj.SVMXC__Product__c!=null && isPrimaryFound==false){
             ap= getAPObjectFromCase(caseObj);
             ap.Is_Primary__c=isPrimaryFound ? false: true;            
             ap.Product__c=caseObj.SVMXC__Product__c;
             ap.Product_Lot_Number__c=caseObj.Product_Lot_Number__c;
             ap.Software_Version__c=caseObj.Software_Version__c;
             listCaseAssociatedProduct.add(ap);
        }
        
        System.debug('TEST123 getPrimaryAssociatedProductOnCase '+JSON.serialize(listCaseAssociatedProduct));
        return listCaseAssociatedProduct;
    }
    private List<Associated_Product__c> getAssociatedProductOnWorkOrders(Case caseObj){
        
        List<Associated_Product__c> listCaseAssociatedProduct= new   List<Associated_Product__c>();
        Associated_Product__c ap= new Associated_Product__c();
        Boolean isProductMapped=FALSE;  
        if(canCreateAPFromWO(caseObj)){
        System.debug('TEST1234 Work_Order__c '+caseObj.Work_Order__c);
        System.debug('TEST1234 SVMXC__Component__c '+caseObj.Work_Order__r.SVMXC__Component__c);
        System.debug('TEST1234 Subscription__c '+caseObj.Work_Order__r.Subscription__c);
        System.debug('TEST1234 SVMXC__Product__c '+caseObj.Work_Order__r.SVMXC__Product__c);


        if(caseObj.Work_Order__r.SVMXC__Component__c!=null && caseObj.SVMXC__Component__c!=caseObj.Work_Order__r.SVMXC__Component__c){
             ap= getAPObjectFromCaseWo(caseObj);
             ap.Installed_Product__c=caseObj.Work_Order__r.SVMXC__Component__c;
             ap.Product__c=caseObj.Work_Order__r.SVMXC__Product__c;
             isProductMapped=TRUE;
             listCaseAssociatedProduct.add(ap);
        } 
        
        
        if(caseObj.Work_Order__r.Subscription__c !=null && caseObj.Subscription__c!=caseObj.Work_Order__r.Subscription__c){
             ap= getAPObjectFromCaseWo(caseObj);
             ap.Subscription__c=caseObj.Work_Order__r.Subscription__c;
            // ap.Product__c=caseObj.Work_Order__r.SVMXC__Product__c;
             ap.Product__c=isProductMapped?null:caseObj.Work_Order__r.SVMXC__Product__c;
             isProductMapped=true;
             listCaseAssociatedProduct.add(ap);
        }
        
        if( isProductMapped==false && caseObj.Work_Order__r.SVMXC__Product__c !=null && caseObj.SVMXC__Product__c!=caseObj.Work_Order__r.SVMXC__Product__c){
             ap= getAPObjectFromCaseWo(caseObj);
             ap.Product__c=caseObj.Work_Order__r.SVMXC__Product__c;
             listCaseAssociatedProduct.add(ap);
        }
        
        }     
      
        System.debug('TEST1234 getAssociatedProductOnWorkOrders '+JSON.serialize(listCaseAssociatedProduct));

        return listCaseAssociatedProduct;
    }
    
    private boolean canCreateAPFromWO(Case caseObj ){
        boolean flag=false;
        if(caseObj.Work_Order__c!=null && ( (caseObj.Work_Order__r.SVMXC__Component__c!=null) || (caseObj.Work_Order__r.Subscription__c !=null)  ||  (caseObj.Work_Order__r.SVMXC__Product__c!=null)  ))
        {
            flag=true;
        }
        
        return flag;
        
    }
    
    private  Associated_Product__c getAPObjectFromCase(Case caseObj ){
         Associated_Product__c ap;
         if(caseObj!=null){
             ap = new Associated_Product__c();
             ap.Case__c = caseObj.Id;
             ap.Product_Serial_Number__c=caseObj.Product_Serial_Number__c;
             ap.CreatedById=caseObj.CreatedById;
             ap.Case_Line_ID__c='CASE';
             ap.Is_Expired__c =caseObj.Expired_Reagent__c;
             ap.Work_Order__c=caseObj.Work_Order__c;
             ap.Installed_Product_Upgrade_Type__c=caseObj.Installed_Product_Upgrade_Type__c;
             if(caseObj.OwnerId.getSObjectType() == User.SObjectType){
                ap.OwnerId=caseObj.OwnerId;
             }
             
          
         }
      return ap;
        
    }
	private  Associated_Product__c getAPObjectFromCaseWo(Case caseObj){
         Associated_Product__c ap;
         if(caseObj!=null){
             ap = new Associated_Product__c();
             ap.Case__c = caseObj.Work_Order__r.SVMXC__Case__c;
             ap.Product_Lot_Number__c=caseObj.Work_Order__r.Product_Lot_Number__c;
             ap.Product_Serial_Number__c=caseObj.Work_Order__r.Product_Serial_Number__c;
             ap.Case_Line_ID__c='Work order'; 

             //ap.OwnerId=caseObj.Work_Order__r.OwnerId;

              if(caseObj.Work_Order__r.OwnerId.getSObjectType() == User.SObjectType){
                ap.OwnerId=caseObj.Work_Order__r.OwnerId;
             }

             ap.CreatedById=caseObj.Work_Order__r.CreatedById;       
             ap.Work_Order__c=caseObj.Work_order__c;
         }
      return ap;
        
    }
    
  
   
   
    
     private void sendEmail(Integer totalCase, Integer totalCaseLine,Integer totalAP) {
        // Define the email
		List<String> toAddresses = System.label.DataRedemiationEmail.split(',');
         
        String message='Total Case Record Processed In Batch '+ totalCase +'\n Total Case Line Processed '+totalCaseLine+'\n Total AP Record Inserted '+totalAP;
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        
        /*Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
        attachment.setFileName('ExportedData.csv');
        attachment.setBody(Blob.valueOf(this.csvContentApInserted));

        Messaging.EmailFileAttachment attachmentCase = new Messaging.EmailFileAttachment();
        attachmentCase.setFileName('ExportedDataCase.csv');
        attachmentCase.setBody(Blob.valueOf(this.csvContentCaseData));*/

        //email.setFileAttachments(new Messaging.EmailFileAttachment[] { attachment,attachmentCase });
            

        email.setToAddresses(toAddresses);
        email.setSubject('Batch Process Complete');
        email.setPlainTextBody(message);

        // Send the email
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
    }
    

        /**************************************************************************************************************************************
        * NAME   : APPRoceessedData
        * DESCRIPTION  : Domain class for v.
        * T
        *  
        *                    
        * @AUTHOR : Nitin Z 
        * @DATE   : 25 -jun -2024  
        *  
        * MODIFICATION LOG: 
        * --------------------------------------------------------------------------------------------------------------------------------------
        * DEVELOPER                DATE                DESCRIPTION 
        * --------------------------------------------------------------------------------------------------------------------------------------
        Nitin Z                  25-jun -2024   

        ****************************************************************************************************************************************/ 

    private class APPRoceessedData{
        public List<Associated_Product__c> associatedProductList;
        public List<SVMXC__Case_Line__c> caseLineList;
        
            /*
            * @author - Nitin Z
            * @Description-  APPRoceessedData constructor 
            */
        public APPRoceessedData(){
         associatedProductList= new List<Associated_Product__c>();
         caseLineList= new List<SVMXC__Case_Line__c>();
        }
        
    }

 
}