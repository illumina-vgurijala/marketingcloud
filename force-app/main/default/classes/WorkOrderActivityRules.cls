/**
*    @author: Karthik Rayani
*    @date:   11-Nov-2020
*    @description:  Handler Class for Work Order Activity Rule
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Karthik Rayani              11 Nov 2020           Initial Build
              
*    ------------------------------------------------------------------------------------ 
*                    
*/
public with sharing class WorkOrderActivityRules extends ilib_SObjectDomain {
	public static final string BR_SYMBOL = '\n';
	public static final string COL_SYMBOL = ' : ';
	private String newFieldValues = '';
	private String oldFieldValues = '';
	Map<String, String> mapFieldToLabel = new Map<String, String>();
    public static final Id WO_ACTIVITY_RULES_RECORDTYPE_ID  = Schema.SObjectType.Work_Order_Activity_Rules__c.getRecordTypeInfosByName().get('Tool Debrief Compliance').getRecordTypeId();
	public static List<User> lstUserRecords=new List<User>();
	public static Map<Id,User> userMap = new Map<Id,User>();
	public static Map<Id,ProcessInstance> submitterMap = new Map<Id,ProcessInstance>();

	/**
     * @author Karthik Rayani
     * @date   11-Nov-2020
     **/
	public WorkOrderActivityRules(List<Work_Order_Activity_Rules__c> sObjectList) {
        super(sObjectList);
		//getting field labels
		List<Schema.SObjectField> lstFieldAPINames = UtilsObject.getSObjectFields('Work_Order_Activity_Rules__c').values();
		for (Schema.SObjectField fieldName : lstFieldAPINames)
		{
			mapFieldToLabel.put(fieldName.getDescribe().getName() , fieldName.getDescribe().getLabel());
		}
	}
	
	/*
    * Boilerplate which is required for base class instantiation logic
    */
    public class Constructor implements ilib_SObjectDomain.IConstructable {
		/*
			* Boilerplate which is required for base class instantiation logic
		*/
		public ilib_SObjectDomain construct(List<SObject> sObjectList)
		{
			return new WorkOrderActivityRules(sObjectList);
		}
	}
	/**
     * @author Karthik Rayani
     * @date   11-Nov-2020
     * @description  Before insert trigger method
     * 
     **/
	public override void onBeforeInsert()
	{
		for(Work_Order_Activity_Rules__c objWorkOrderRules:(List<Work_Order_Activity_Rules__c>)records)
		{
			objWorkOrderRules.Old_Field_Values__c = 'NA';
			String newFieldValuesBI = mapFieldToLabel.get('Document_Name__c') +COL_SYMBOL + objWorkOrderRules.Document_Name__c +BR_SYMBOL ;
			newFieldValuesBI = newFieldValuesBI + mapFieldToLabel.get('Document_Number__c') +COL_SYMBOL+objWorkOrderRules.Document_Number__c + BR_SYMBOL;
			newFieldValuesBI = newFieldValuesBI + mapFieldToLabel.get('Name') +COL_SYMBOL+objWorkOrderRules.Name + BR_SYMBOL;
			newFieldValuesBI = newFieldValuesBI + mapFieldToLabel.get('Activity_Type__c') +COL_SYMBOL+objWorkOrderRules.Activity_Type__c + BR_SYMBOL;
			newFieldValuesBI = newFieldValuesBI + mapFieldToLabel.get('Product_Code__c') +COL_SYMBOL+objWorkOrderRules.Product_Code__c + BR_SYMBOL;
			newFieldValuesBI = newFieldValuesBI + mapFieldToLabel.get('Product_Group__c') +COL_SYMBOL+objWorkOrderRules.Product_Group__c + BR_SYMBOL;
			newFieldValuesBI = newFieldValuesBI + mapFieldToLabel.get('Generic_Document__c') +COL_SYMBOL+objWorkOrderRules.Generic_Document__c + BR_SYMBOL;
			newFieldValuesBI = newFieldValuesBI + mapFieldToLabel.get('Required__c') +COL_SYMBOL+objWorkOrderRules.Required__c + BR_SYMBOL;
            if(objWorkOrderRules.RecordTypeId ==  WO_ACTIVITY_RULES_RECORDTYPE_ID){
            	newFieldValuesBI = newFieldValuesBI + mapFieldToLabel.get('Is_Tool_Debrief_Mandatory__c') +COL_SYMBOL+objWorkOrderRules.Is_Tool_Debrief_Mandatory__c + BR_SYMBOL;
            }
			objWorkOrderRules.New_Field_Values__c = newFieldValuesBI;
			objWorkOrderRules.Requester__c =  objWorkOrderRules.OwnerId;

		}
	}
   /**
     * @author Karthik Rayani
     * @date   11-Nov-2020
     * @description  Before Update trigger method
     * 
     **/
    public override void onBeforeupdate(Map<Id, sObject> oldRecords) {
		Set<Id> setUserId=new Set<Id>();
		Set<Id> setWOARId=new Set<Id>();
		Id woarId;

		for(Work_Order_Activity_Rules__c objWorkOrderRulesNew:(List<Work_Order_Activity_Rules__c>)records) {
			if(objWorkOrderRulesNew.Requester__c != null) {
				setUserId.add(objWorkOrderRulesNew.Requester__c);	
				setWOARId.add(objWorkOrderRulesNew.Id);	
			}
		}
		
		getUserID(setUserId);		
		getApprovalSubmitter(setWOARId);
											
		for(Work_Order_Activity_Rules__c objWorkOrderRulesNew:(List<Work_Order_Activity_Rules__c>)records)
		{
            Work_Order_Activity_Rules__c objWorkOrderRulesOld = (Work_Order_Activity_Rules__c)oldRecords.get(objWorkOrderRulesNew.Id);
			compareFields(objWorkOrderRulesNew.Document_Name__c ,  objWorkOrderRulesOld.Document_Name__c ,  mapFieldToLabel.get('Document_Name__c'));
			compareFields(objWorkOrderRulesNew.Document_Number__c ,  objWorkOrderRulesOld.Document_Number__c ,  mapFieldToLabel.get('Document_Number__c'));
			compareFields(objWorkOrderRulesNew.Name ,  objWorkOrderRulesOld.Name ,  mapFieldToLabel.get('Name'));
			compareFields(objWorkOrderRulesNew.Activity_Type__c ,  objWorkOrderRulesOld.Activity_Type__c ,  mapFieldToLabel.get('Activity_Type__c'));
			compareFields(objWorkOrderRulesNew.Product_Code__c ,  objWorkOrderRulesOld.Product_Code__c ,  mapFieldToLabel.get('Product_Code__c'));
			compareFields(objWorkOrderRulesNew.Product_Group__c ,  objWorkOrderRulesOld.Product_Group__c ,  mapFieldToLabel.get('Product_Group__c'));
			compareFields(String.valueOf(objWorkOrderRulesNew.Generic_Document__c) ,  String.valueOf(objWorkOrderRulesOld.Generic_Document__c) ,  mapFieldToLabel.get('Generic_Document__c'));
			compareFields(String.valueOf(objWorkOrderRulesNew.Required__c) ,  String.valueOf(objWorkOrderRulesOld.Required__c) ,  mapFieldToLabel.get('Required__c'));
            if(objWorkOrderRulesNew.RecordTypeId ==  WO_ACTIVITY_RULES_RECORDTYPE_ID){
            	compareFields(String.valueOf(objWorkOrderRulesNew.Is_Tool_Debrief_Mandatory__c) ,  String.valueOf(objWorkOrderRulesOld.Is_Tool_Debrief_Mandatory__c) ,  mapFieldToLabel.get('Is_Tool_Debrief_Mandatory__c'));
            }
			if(String.isNotBlank(newFieldValues) && String.isNotBlank(oldFieldValues)){ 
				objWorkOrderRulesNew.New_Field_Values__c = newFieldValues;
				objWorkOrderRulesNew.Old_Field_Values__c = oldFieldValues;
			}
			if(objWorkOrderRulesNew.Approval_Status__c == 'Approved' || objWorkOrderRulesNew.Approval_Status__c == 'Rejected'){
                objWorkOrderRulesNew.OwnerId= objWorkOrderRulesOld.Requester__c ;
            }

			for(Id pi: submitterMap.keySet()){
				if(pi != null){
					woarId = pi;
				}
			}
			if(userMap.containsKey(objWorkOrderRulesNew.Requester__c) && objWorkOrderRulesNew.Approval_Status__c == 'Approved' || objWorkOrderRulesNew.Approval_Status__c == 'Rejected'){
				if(userMap.get(objWorkOrderRulesNew.Requester__c).IsActive == true){
					objWorkOrderRulesNew.OwnerId = objWorkOrderRulesOld.Requester__c;
				}
				else{					
					objWorkOrderRulesNew.OwnerId = woarId;
				}
			}
		}
    }
	
	/**
	* @author Karthik Rayani
	* @date   11-Nov-2020
	* @description  Compare Fields
	* 
	**/
	public void compareFields(String fieldValueNew, String fieldValueOld , String labelName)
	{
		if(fieldValueNew !=  fieldValueOld){
			newFieldValues = newFieldValues + labelName +COL_SYMBOL + fieldValueNew +BR_SYMBOL ;
			oldFieldValues = oldFieldValues + labelName +COL_SYMBOL + fieldValueOld +BR_SYMBOL ;
		}
	}

	/**
	* @author Deepika Ayyavari
	* @date   05-Apr-2023
	* @description  To get the User info
	* 
	**/
	public static void getUserID(Set<Id> setUserId)
	{
		if(lstUserRecords.isEmpty()) {
			lstUserRecords= new UsersSelector().selectByUserId(setUserId);
		}
			
		for(User objUser : lstUserRecords) {
            userMap.put(objUser.Id, objUser);
        }
		
	}

	/**
	* @author Deepika Ayyavari
	* @date   05-Apr-2023
	* @description  To get the User info
	* 
	**/
	public static void getApprovalSubmitter(Set<Id> woarId)
	{
		List<ProcessInstance> lstProcess = [SELECT SubmittedById FROM ProcessInstance WHERE TargetObjectId =: woarId ORDER BY SystemModStamp DESC LIMIT 1];
        if(lstProcess != null && !lstProcess.isEmpty()) {
			submitterMap.put(lstProcess[0].SubmittedById, lstProcess[0]);
		}
	}
}