/**
*    @author : Vignesh Sethuramalingam
*    @date   : 17-Dec-2019
*    @description : Queuable Class that populates IB Technical Attributes with Internal objects.
*    Modification Log:
*    ------------------------------------------------------------------------------------ 
*    Developer                      Date                Description
*    Vignesh S                   17-Dec-2019          Initial Version.
*    ------------------------------------------------------------------------------------ 
*                    
*/
public class QueueableUpdateIBAttribute implements Queueable {
    
    list<SVMXC__SM_IB_Attributes_History__c> AttrHistoryToInsert = new list<SVMXC__SM_IB_Attributes_History__c>();
    Map<String,SVMXC__SM_IB_Attributes_Template_Instance__c> mapTemplateInstancetoInsert = new Map<String,SVMXC__SM_IB_Attributes_Template_Instance__c>();
    
    
    /**
    * @description To assign AttrHistoryToInsert and mapTemplateInstancetoInsert
    * @author 
    * @param AttrHistoryToInsert 
    * @param mapTemplateInstancetoInsert 
    **/
    public QueueableUpdateIBAttribute(list<SVMXC__SM_IB_Attributes_History__c> AttrHistoryToInsert, Map<String,SVMXC__SM_IB_Attributes_Template_Instance__c> mapTemplateInstancetoInsert  ){
        this.AttrHistoryToInsert = AttrHistoryToInsert;
        this.mapTemplateInstancetoInsert = mapTemplateInstancetoInsert;
    }
    
    
    /**
    * @description Execute method for QueueableContext
    * @author 
    * @param qc 
    **/
    public void execute(QueueableContext qc){
        
        if(!mapTemplateInstancetoInsert.isEmpty()){
            delete [Select Id from SVMXC__SM_IB_Attributes_Template_Instance__c 
                    Where SVMXC__SM_Installed_Product_Id__c IN : mapTemplateInstancetoInsert.keySet()];
            try{
                insert mapTemplateInstancetoInsert.values();
            }catch(Exception e){
                ApexExceptions.emit( 'QueueableUpdateIBAttribute' , e  );
            }
            
        }
        
        if(!AttrHistoryToInsert.isEmpty()){
            try{
                insert AttrHistoryToInsert;
            }catch(Exception e){
                ApexExceptions.emit('QueueableUpdateIBAttribute', e);
            }
        }
    }
}