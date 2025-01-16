/**
* @author Govind Dubey
* @date   2018-07-27
* @description  Wrapper class of Approval Request for same Approval Name for Submitter Experience - Preview Approvals
* Modification Log:
* ------------------------------------------------------------------------------------ 
*       Govind Dubey         2018-07-27            Original Version   
*       Roopal Verma         2019-07-05            DCP-25340, Added condition for Promotion approval 
*       Nesar Mohan          2022-04-04            Codescan Fix - Add code comments   
*  ------------------------------------------------------------------------------------    
*/
public class ApprovalRequestWrapper{

    public Integer intStepSequence{set;get;}
    public String strApprovalName{set;get;}
    public String strApprovalRequestRegion{set;get;}
    public List<String> lstApproverName{set;get;}
    public List<String> lstApprovalSequence{set;get;}
    public List<String> lstApprovalLabel{set;get;}
    public List<String> lstApprovalStepName{set;get;}

    /* 
     * @author: Govind Dubey
     * @Description: Constructor for ApprovalRequestWrapper class.
     */

    public ApprovalRequestWrapper(){
    }

    /* 
     * @author: Govind Dubey
     * @Description: Parameterized Constructor for ApprovalRequestWrapper class.
     * @Param: Integer, String, Apttus_Approval__Approval_Request__c, two strings and three boolean types
     */

    public ApprovalRequestWrapper(Integer intStepNumber,String strStepName, Apttus_Approval__Approval_Request__c objApprovalRequest,string strApprovalDetails,string strRegion,boolean boolTransRegion,boolean boolTransBorder,boolean boolPromotion){ //DCP-25340, added parameter boolpromotion
        intStepSequence = intStepNumber;
        lstApproverName = new List<String>();
        lstApprovalLabel = new List<String>();
        lstApprovalStepName = new List<String>();
        lstApprovalSequence = new List<String>();
        strApprovalName = strStepName;
        strApprovalRequestRegion = strRegion;
        if(boolTransBorder)
            lstApprovalSequence.add(objApprovalRequest.Apttus_Approval__StepLabel__c);
        else if(boolTransRegion)
            lstApprovalSequence.add('1');
		else if(boolPromotion) //DCP-25340, Added condition for promotion
            lstApprovalSequence.add(String.valueOf(objApprovalRequest.Promo_Approval_Seq__c));
        else if(UtilsSettings.CPQCLM_RO_Approver_Steps.contains(strApprovalName)) 
            lstApprovalSequence.add(String.valueOf(integer.valueof(objApprovalRequest.Apttus_Approval__Sequence__c) + 1));        
        else
            lstApprovalSequence.add(objApprovalRequest.Apttus_Approval__Sequence__c);
        lstApproverName.add(strApprovalDetails);
        lstApprovalLabel.add(objApprovalRequest.Apttus_Approval__StepLabel__c);
        lstApprovalStepName.add(strApprovalName);
    }
}