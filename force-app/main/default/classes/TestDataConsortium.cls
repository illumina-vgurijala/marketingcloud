/**
 * @author 
 * @date   
 * @description  consortium and associated records
 * Modification Log:
*  ------------------------------------------------------------------------------------ 
*   Developer                Date                Description                                                 
*   Aman Tyagi               07-Oct-2022         Codescan Fixes
*  -----------------------------------------------------------------------------------          
*/
@isTest
public with sharing class TestDataConsortium {
	/**
     * @author   
     * @description static method initConsortium of type Consortium__c
     * @param  String stropencloseconsortium
     * @return Consortium__c
     **/
	public static Consortium__c initConsortium(String stropencloseconsortium){
		return initConsortium('Early Engagement','testSpecies','Agriculture',100,Date.today(),'Yes',100,'Yes',stropencloseconsortium); 
	}
	/**
     * @author   
     * @description static method initConsortium of type Consortium__c
     * @param  String strStage, String strSpecies, String strCategory, Integer intMinSampleAmount, Date dtPurchaseOrderDeadline, String strClusterFileAvail, Integer intAttemptedBeadtype, String strVolumeLeft, String stropencloseconsortium 
     * @return Consortium__c
     **/
	public static Consortium__c initConsortium( String strStage, String strSpecies, String strCategory, Integer intMinSampleAmount, Date dtPurchaseOrderDeadline, String strClusterFileAvail, Integer intAttemptedBeadtype, String strVolumeLeft, String stropencloseconsortium )
	{
        String rand = TestData.getRandom();

		Consortium__c c = new Consortium__c(
			Name = rand,
			Stage__c = strStage,
			Species__c = strSpecies,
			Category__c = strCategory,
			Minimum_Sample_Amount__c = intMinSampleAmount,
			Purchase_Order_Deadline__c = dtPurchaseOrderDeadline,
			Is_Cluster_File_Available__c = strClusterFileAvail,
			Attempted_Beadtypes__c = intAttemptedBeadtype,
			Is_Volume_Left__c = strVolumeLeft,
			Open_Closed_Consortium__c = stropencloseconsortium
		);

		return c;
	}
	/**
     * @author   
     * @description static  get method getNewConsortium of type Consortium__c
     * @param NA
     * @return Consortium__c
     **/
	public static Consortium__c getNewConsortium()
	{
		Consortium__c rec = initConsortium();
		insert rec;
		return rec;
	}
	/**
     * @author   
     * @description static  init method initConsortium of type Consortium__c
     * @param NA
     * @return Consortium__c
     **/
	public static Consortium__c initConsortium()
	{
		Consortium__c rec = new Consortium__c(
			Name = TestData.getRandom(),
			Stage__c = 'Initial Sale',
			Species__c = TestData.getRandom(),
			Category__c = 'Model Organism',
			Minimum_Sample_Amount__c = Decimal.valueOf(TestData.getRandomNumeric()),
			Purchase_Order_Deadline__c = Date.today() + 10,
			Is_Cluster_File_Available__c = 'Yes',
			Attempted_Beadtypes__c = Decimal.valueOf(TestData.getRandomNumeric()),
			Is_Volume_Left__c = 'Yes',
			Open_Closed_Consortium__c = 'Open',
			Tier_A_Samples__c = 48,
			Tier_B_Samples__c = 48,
			Tier_C_Samples__c = 48,
			Tier_D_Samples__c = 48
		);

		return rec;
	}
	/**
     * @author   
     * @description static  get method getNewConsortiumAccount of type Consortium_Account__c
     * @param Id accountId, Id consortiumId
     * @return Consortium_Account__c
     **/
	public static Consortium_Account__c getNewConsortiumAccount(Id accountId, Id consortiumId)
	{
		Consortium_Account__c rec = initConsortiumAccount(accountId, consortiumId);
		insert rec;
		return rec;
	}
	/**
     * @author   
     * @description static method initConsortiumAccount of type Consortium_Account__c
     * @param Id accountId, Id consortiumId
     * @return Consortium_Account__c
     **/
	public static Consortium_Account__c initConsortiumAccount(Id accountId, Id consortiumId)
	{
		Consortium_Account__c rec = new Consortium_Account__c(
			Consortia__c = consortiumId,
			Account__c = accountId,
			Is_InActive__c = false
		);
		return rec;
	}

}