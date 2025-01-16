/**************************************************************************************************************************************
* NAME   : BatchWODataRemediation
* DESCRIPTION  : Domain class for v.
* Test Class- TestBatchWODataRemediation.cls
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


global class BatchWODataRemediation implements Database.Batchable<sObject>, Database.Stateful {
    Integer woCount=0;
    Integer aPcount=0;
    Integer recordLimit=0; 
   
   /*
   * @author - Nitin Z
   * @Description-  start method
   */
   
   public BatchWODataRemediation(Integer mLimit){
       this.recordLimit=mLimit;
   }

   /*
   * @author - Nitin Z
   * @Description-  start method
   */
   public BatchWODataRemediation(){
    }
 
     /*
    * @author - Nitin Z
    * @Description-  start method
    */
    global Database.QueryLocator start(Database.BatchableContext bc) {
        //Id recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Elevation')?.getRecordTypeId();

      String dynamicQuery = 'SELECT Id,Legacy_Case_Subject__c, svmxc__Order_Status__c, SVMXC__Closed_On__c,SVMXC__Component__c,Subscription__c,SVMXC__Product__c,SVMXC__Case__c,Product_Lot_Number__c,Product_Serial_Number__c,OwnerId,CreatedById ' +
                          'FROM SVMXC__Service_Order__c ' +
                          'WHERE ((svmxc__Order_Status__c != \'Cancelled\' AND ' +
                          'svmxc__Order_Status__c != \'Completed\' AND ' +
                          'svmxc__Order_Status__c != \'Closed\' AND ' +
                          'svmxc__Order_Status__c != \'Closed Duplicate\') ' +
                          'OR (SVMXC__Closed_On__c >= 2022-08-01T00:00:00Z AND ' +
                          '(svmxc__Order_Status__c = \'Cancelled\' OR ' +
                          'svmxc__Order_Status__c = \'Completed\' OR ' +
                          'svmxc__Order_Status__c = \'Closed\' OR ' +
                          'svmxc__Order_Status__c = \'Closed Duplicate\'))) and SVMXC__Case__c =null'+
          				  ' and Legacy_Case_Subject__c != \'PROCESSED\''+	
                          '   '+ ( this.recordLimit==0 ? '':' Limit '+this.recordLimit);
          
      return Database.getQueryLocator(dynamicQuery);

    }

     /*
    * @author - Nitin Z
    * @Description-  execute method
    */
    global void execute(Database.BatchableContext bc, List<SVMXC__Service_Order__c > scope) {
        
		List<Associated_Product__c> apListToBeInserted = new List<Associated_Product__c>();
        List<SVMXC__Service_Order__c> woListToBeUpdated = new List<SVMXC__Service_Order__c>();

        Cases.skipCaseTrigger=true;
        WorkOrders.skipWOTrigger=true;


        for(SVMXC__Service_Order__c woObj:scope){
            
             apListToBeInserted.addAll(getAssociatedProductOnWorkOrders(woObj));
             woObj.Legacy_Case_Subject__c='PROCESSED';
             woListToBeUpdated.add(woObj);
             
             
            
			//System.debug('TEST321 case'+ caseObj.ID);            
            //System.debug('TEST321 caseDataMap'+ JSON.serialize(caseDataMap.get(caseObj.Id)));
        }
     insert apListToBeInserted;
     update woListToBeUpdated;
     
     System.debug('TEST321 apListToBeInserted'+ JSON.serialize(apListToBeInserted));   
     aPcount=aPcount+apListToBeInserted.size();
     woCount=woCount+woListToBeUpdated.size();

        
    }

 
    /*
    * @author - Nitin Z
    * @Description-  finishs method
    */
    global void finish(Database.BatchableContext bc) {
        System.debug('Batch processing completed.');
        System.debug('Batch processing aPcount. '+aPcount);
        System.debug('Batch processing woCount. '+woCount);
        sendEmail(woCount,aPcount);
    }

  
   
   
    private List<Associated_Product__c> getAssociatedProductOnWorkOrders(SVMXC__Service_Order__c woObj){
        
        List<Associated_Product__c> listCaseAssociatedProduct= new   List<Associated_Product__c>();
        Associated_Product__c ap= new Associated_Product__c();  
		boolean isPrimaryFound=false;  

        if(woObj.SVMXC__Component__c!=null){
             ap= getAPObjectFromWo(woObj);
             ap.Is_Primary__c=true;
             ap.Installed_Product__c=woObj.SVMXC__Component__c;
             ap.Product__c=woObj.SVMXC__Product__c;
             listCaseAssociatedProduct.add(ap);
             isPrimaryFound=true;
        } 
        
        if(woObj.Subscription__c !=null){
             ap= getAPObjectFromWo(woObj);
             ap.Is_Primary__c=isPrimaryFound ? false: true;
             ap.Subscription__c=woObj.Subscription__c;
             ap.Product__c=isPrimaryFound?null:woObj.SVMXC__Product__c;
             listCaseAssociatedProduct.add(ap);
             isPrimaryFound=true;
        }
        
        if(isPrimaryFound==false && woObj.SVMXC__Product__c !=null){
             ap= getAPObjectFromWo(woObj);
             ap.Is_Primary__c=isPrimaryFound ? false: true;            
             ap.Product__c=woObj.SVMXC__Product__c;
             listCaseAssociatedProduct.add(ap);
        }
        
    
      
        System.debug('TEST1234 getAssociatedProductOnWorkOrders '+JSON.serialize(listCaseAssociatedProduct));

        return listCaseAssociatedProduct;
    }
    
   
    
  
	private  Associated_Product__c getAPObjectFromWo(SVMXC__Service_Order__c woObj){
         Associated_Product__c ap;
         if(woObj!=null){
             ap = new Associated_Product__c();
             ap.Case__c = woObj.SVMXC__Case__c;
             ap.Product_Lot_Number__c=woObj.Product_Lot_Number__c;
             ap.Product_Serial_Number__c=woObj.Product_Serial_Number__c;
             ap.Case_Line_ID__c='Work order'; 

             //ap.OwnerId=caseObj.Work_Order__r.OwnerId;

              if(woObj.OwnerId.getSObjectType() == User.SObjectType){
                ap.OwnerId=woObj.OwnerId;
             }

             ap.CreatedById=woObj.CreatedById;       
             ap.Work_Order__c=woObj.id;
         }
      return ap;
        
    }
   
  
    
     private void sendEmail(Integer totalWo,Integer totalAP) {
        // Define the email
        String message='Total WO records given for batch to process'+  this.recordLimit +' \n Total WO Record Processed '+ totalWo +'\n Total AP Record Inserted '+totalAP;
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
		List<String> toAddresses = System.label.DataRedemiationEmail.split(',');
        
        // Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
        // attachment.setFileName('ExportedDataWO.csv');
        // attachment.setBody(Blob.valueOf(this.csvContentApInserted));

        // email.setFileAttachments(new Messaging.EmailFileAttachment[] { attachment });
            

        email.setToAddresses(toAddresses);
        email.setSubject('Batch Process Complete');
        email.setPlainTextBody(message);

        // Send the email
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
    }
    

     

 
}