/*
*  @Author:
*  @Date: 
*  @Description:
*  Modification Log:
*    @Test Class for above 90% coverage.
         -TestBatchUpdateMandatoryInfoOnIB
         -TestIBTechinalAttributeCreationQueuable
         -TestQueueableUpdateIBAttribute
         -TestTAPS_SmIbAttributesTemplateInst
         -TestValidateInstallWOOnComplete
*    @Test Class for atleast 75% coverage.
         -TestBatchUpdateMandatoryInfoOnIB
         -TestIBTechinalAttributeCreationQueuable
         -TestQueueableUpdateIBAttribute
         -TestTAPS_SmIbAttributesTemplateInst
         -TestValidateInstallWOOnComplete
*   ------------------------------------------------------------------------------------ 
*    Developer                      Date                    Description
*  Nishan Shetty                 24-Aug-2022            DCP-44091 - Indirect Instantiation of Orchestrator Class for Performance Improvement.
*  Deepika Ayyavari              02-Mar-2023            INC0443380 - Added null checks for date
*  Rucha Dalvi                   30-Mar-2023            INC0458423 - To validate IPs Edit access and throw error when Technical Attribute don't have access on the IP
*    ------------------------------------------------------------------------------------                  
*/
public with sharing class SmIbTechnicalAttributes extends ilib_SObjectDomain {
    
    public static final String STRING_LAST_UPGRADE_DAY = 'Last Upgrade Day';
    public static final String STRING_LAST_UPGRADE_MONTH = 'Last Upgrade Month';
    public static final String STRING_LAST_UPGRADE_YEAR = 'Last Upgrade Year';
    private static final String LOG_TITLE = 'SmIbTechnicalAttributes';
    
		/*
         * Constructor
         */	
    public SmIbTechnicalAttributes(List<SVMXC__SM_IB_Technical_Attributes__c> sObjectList)
    {
        super(sObjectList);
    }
    /*
     * Boilerplate which is required for base class instantiation logic
     */
    public class Constructor implements ilib_SObjectDomain.IConstructable
    {
	    /*Param - sobjectList  */
        public ilib_SObjectDomain construct(List<SObject> sObjectList)
        {
            return new SmIbTechnicalAttributes(sObjectList);
        }
    }
    
    /*
         * description - onBeforeInsert method
		 * return - void
         */ 
    public override void onBeforeInsert()
    {
        validateIPAccess(records);//INC0458423
    }
		/*
         * description - onAfterInsert method
		 * return - void
         */ 	
    public override void onAfterInsert()
    {
        
        //DCP-31083
        updaterelatedInstalledProducts((List<SVMXC__SM_IB_Technical_Attributes__c> ) records);
       
    }

    /*
    * description - onBeforeUpdate method
    * return - void
    */ 
    public override void onBeforeUpdate(Map<Id, SObject> oldRecords) {
        validateIPAccess(records);//INC0458423
    }
    
		/*
         * description - onAfterUpdate method
		 * return - void
         */ 	
    public override void onAfterUpdate(Map<Id, sObject> existingRecords)
    {
        //DCP-31083
        updaterelatedInstalledProducts((List<SVMXC__SM_IB_Technical_Attributes__c> ) records);
    }
    
    
    /**
*    @author Digvijay Singh
*    @date   12-12-2019
*    @description    method to update related Installed Products
*    DCP:-31083
**/
    
    public Void updaterelatedInstalledProducts(List<SVMXC__SM_IB_Technical_Attributes__c> records){
        
        
        set<Id> setIP=new set<Id>();
        Map<Id ,SVMXC__Installed_Product__c > mapIdtoIP=new Map<Id , SVMXC__Installed_Product__c>();
        Map<Id,SVMXC__Installed_Product__c> mapIPTobeUpdated=new Map<Id,SVMXC__Installed_Product__c>();
        Map<String , IVD_Product_Criteria__mdt> mapAttrToObj=new Map<String , IVD_Product_Criteria__mdt>();
        Map<ID,Map<String,String >> mapIdtoDateMap=new Map<ID,Map<String,String >> ();
        
        
        
        for(SVMXC__SM_IB_Technical_Attributes__c objTechAttr : (List<SVMXC__SM_IB_Technical_Attributes__c>)records)
        { 
            setIP.add(objTechAttr.SVMXC__SM_Installed_Product_id__c);
            
            if(objTechAttr.SVMXC__SM_Attr_Name__c==STRING_LAST_UPGRADE_DAY  || objTechAttr.SVMXC__SM_Attr_Name__c==STRING_LAST_UPGRADE_MONTH || objTechAttr.SVMXC__SM_Attr_Name__c==STRING_LAST_UPGRADE_YEAR){
                if(!mapIdtoDateMap.containsKey(objTechAttr.SVMXC__SM_Installed_Product_id__c)){
                    mapIdtoDateMap.put(objTechAttr.SVMXC__SM_Installed_Product_id__c, new Map<String,String>());    
                }
                mapIdtoDateMap.get(objTechAttr.SVMXC__SM_Installed_Product_id__c).put(objTechAttr.SVMXC__SM_Attr_Name__c,objTechAttr.SVMXC__SM_Attr_Value__c);
            }
        }
        
        //to fetch related Installed Products 
        for(SVMXC__Installed_Product__c obj:new InstalledProductsSelector().selectRelatedInstalledProducts(setIP) ){
            mapIdtoIP.put(obj.Id,obj );
        }
        
        
        
        //Initialize Map with Values from CustomMetaData
        for(IVD_Product_Criteria__mdt obj:[Select    Attribute_Type__c,  Attribute_Name__c , Attribute_Value__c , IVD_Product_Identifier__c from IVD_Product_Criteria__mdt]){
            mapAttrToObj.put(obj.Attribute_Name__c , obj);
        }
        
        System.debug('mapAttrToObj..'+mapAttrToObj);
        
        for(SVMXC__SM_IB_Technical_Attributes__c objTechAttr : records)
        {
            if(mapAttrToObj!=null && mapAttrToObj.ContainsKey(objTechAttr.SVMXC__SM_Attr_Name__c) && objTechAttr.SVMXC__SM_IsActive__c ){
                
                if(mapAttrToObj.get(objTechAttr.SVMXC__SM_Attr_Name__c)!=null &&  objTechAttr.SVMXC__SM_Attr_Value__c==mapAttrToObj.get(objTechAttr.SVMXC__SM_Attr_Name__c).Attribute_Value__c && mapAttrToObj.get(objTechAttr.SVMXC__SM_Attr_Name__c).IVD_Product_Identifier__c==true  ){
                    
                    //if condition to check if the attribute value defines IVD upgrade and then mark IP as IVD. 
                    if(mapIdtoIP!=null && mapIdtoIP.containsKey(objTechAttr.SVMXC__SM_Installed_Product_id__c) && mapIdtoIP.get(objTechAttr.SVMXC__SM_Installed_Product_id__c)!=null 
                       && mapIdtoIP.get(objTechAttr.SVMXC__SM_Installed_Product_id__c).Installed_Product_Upgrade_Type__c!='IVD'){
                           
                           mapIdtoIP.get(objTechAttr.SVMXC__SM_Installed_Product_id__c).Installed_Product_Upgrade_Type__c='IVD';
                           mapIPTobeUpdated.put(objTechAttr.SVMXC__SM_Installed_Product_id__c,mapIdtoIP.get(objTechAttr.SVMXC__SM_Installed_Product_id__c));
                           
                       }
                    
                }else {
                    //if condition to check if the attribute value does not defines IVD upgrade and then mark IP as RUO. 
                    if(mapIdtoIP!=null && mapIdtoIP.containsKey(objTechAttr.SVMXC__SM_Installed_Product_id__c) && mapIdtoIP.get(objTechAttr.SVMXC__SM_Installed_Product_id__c)!=null 
                       && objTechAttr.SVMXC__SM_Attr_Value__c !=null && objTechAttr.SVMXC__SM_Attr_Value__c!=''   && mapAttrToObj.get(objTechAttr.SVMXC__SM_Attr_Name__c).IVD_Product_Identifier__c==true  ){
                           System.debug('here..3');
                           mapIdtoIP.get(objTechAttr.SVMXC__SM_Installed_Product_id__c).Installed_Product_Upgrade_Type__c='RUO';
                           mapIPTobeUpdated.put(objTechAttr.SVMXC__SM_Installed_Product_id__c,mapIdtoIP.get(objTechAttr.SVMXC__SM_Installed_Product_id__c));
                           
                       }else{
                           //if condition to check if the attribute value is Blank and then mark IP as not upgraded. 
                           mapIdtoIP.get(objTechAttr.SVMXC__SM_Installed_Product_id__c).Installed_Product_Upgrade_Type__c='NONE';
                           mapIPTobeUpdated.put(objTechAttr.SVMXC__SM_Installed_Product_id__c,mapIdtoIP.get(objTechAttr.SVMXC__SM_Installed_Product_id__c));
                       }
                    
                    
                }
                
                //update upgrade type value in IP
                if(mapAttrToObj.get(objTechAttr.SVMXC__SM_Attr_Name__c)!=null &&mapAttrToObj.get(objTechAttr.SVMXC__SM_Attr_Name__c).Attribute_Type__c=='Upgrade' && mapIdtoIP.get(objTechAttr.SVMXC__SM_Installed_Product_id__c).Upgrade_Type__c!=objTechAttr.SVMXC__SM_Attr_Value__c ){
                    System.debug('here...'+4);
                    mapIdtoIP.get(objTechAttr.SVMXC__SM_Installed_Product_id__c).Upgrade_Type__c=objTechAttr.SVMXC__SM_Attr_Value__c;
                    mapIPTobeUpdated.put(objTechAttr.SVMXC__SM_Installed_Product_id__c,mapIdtoIP.get(objTechAttr.SVMXC__SM_Installed_Product_id__c));
                    
                }
                
            }
            
            //for loop to construct date from date attributes 
            for(Id objId : mapIdtoIP.keySet()){
                
                SVMXC__Installed_Product__c objIP= mapIdtoIP.get(objId);
                Map<String,String > mapDateFields=mapIdtoDateMap.get(objId); 
                
                if(objIP!=null && mapDateFields!=null && !mapDateFields.isEmpty()){
                    Date lastUpgradedate=getConvertDate(mapDateFields);
                    
                    if(lastUpgradedate!=null && (objIP.Last_Upgrade_Date__c==null ||(objIP.Last_Upgrade_Date__c!=null && !lastUpgradedate.isSameDay(objIP.Last_Upgrade_Date__c)))){
                        objIP.Last_Upgrade_Date__c=lastUpgradedate;
                        mapIPTobeUpdated.put(objIP.id,objIP);
                    }
                }
                
            }
            
            
        }
        
        if(mapIPTobeUpdated!=null && mapIPTobeUpdated.values().Size()>0)
            upsert mapIPTobeUpdated.values();
    } 
    
    
    /*method to get date from a map of strings(day,month, year)*/
    public Date getConvertDate(Map<String, String > mapDateFields)
    {
        Date dateObj;
        string stringDate;
        Map<string,integer> mapMonthList = new Map<string,integer>();
        mapMonthList.put('Jan',1);
        mapMonthList.put('Feb',2);
        mapMonthList.put('Mar',3);
        mapMonthList.put('Apr',4);
        mapMonthList.put('May',5);
        mapMonthList.put('Jun',6);
        mapMonthList.put('Jul',7);
        mapMonthList.put('Aug',8);
        mapMonthList.put('Sep',9);
        mapMonthList.put('Oct',10);
        mapMonthList.put('Nov',11);
        mapMonthList.put('Dec',12);
        
        if(mapDateFields!=null && !mapDateFields.isEMPTY()){
            string month = String.ValueOf(mapMonthList.get(mapDateFields.get(STRING_LAST_UPGRADE_MONTH)));
            string day = mapDateFields.get(STRING_LAST_UPGRADE_DAY);
            string year = mapDateFields.get(STRING_LAST_UPGRADE_YEAR);

            //Added null check for INC0443380
            if(month!=null && day!=null && year!=null) {            
               stringDate = year + '-' + month + '-' + day ;
            }
         
            //Added null check for INC0443380
            if(stringDate!=null && string.isNotBlank(stringDate) && stringDate!=''){
                try{
                    dateObj=date.valueOf(stringDate);
                }Catch(Exception ex){
                    ApexExceptions.emit('SmIbTechnicalAttributes',ex , ilib_LogEvent.SERVICE);
                }
        }
            
            
            
        }  
        return dateObj;
        
    }

    /**
    *  @Author Rucha Dalvi 
    *  @Description - INC0458423 To validate and throw error when Technical Attribute don't have access on the IP
    *  @Param      : trigger.new
    *  @Return     : void             
    **/
    public void validateIPAccess(List<SObject> records){

        ilib_LogEvent.push(LOG_TITLE + '.validateIPAccess()');
        Set<Id> setIPs= new Set<Id>();
        Map<Id, SVMXC__SM_IB_Technical_Attributes__c> mapRec = new Map<Id, SVMXC__SM_IB_Technical_Attributes__c>();
        try {
            for(SVMXC__SM_IB_Technical_Attributes__c obj : (List<SVMXC__SM_IB_Technical_Attributes__c>) records) {
                mapRec.put(obj.SVMXC__SM_Installed_Product_id__c, obj);
                if(obj.SVMXC__SM_Installed_Product_id__c != NULL) {
                    setIPs.add(obj.SVMXC__SM_Installed_Product_id__c);
                }
            }
            for(UserRecordAccess usrAccessObj: new UserRecordAccessSelector().selectUserRecordAccessByUserAndSetRecordId(UserInfo.getUserId(),setIPs)) {
                if(usrAccessObj.HasEditAccess !=true) {
                    SVMXC__SM_IB_Technical_Attributes__c actualRecord = mapRec.get(usrAccessObj.RecordId);
                    actualRecord.addError(System.Label.Check_Access_to_Update_Technical_Attributes_Error_Message);
                }
            }
            ilib_LogEvent.pop();
            ilib_LogEvent.emit(); 
        } catch (Exception e) {
            ApexExceptions.emit(LOG_TITLE,e);
            ilib_LogEvent.message(LOG_TITLE+'.Exception: ' + e.getMessage()); 
        }
    }
}