/**
 *    @author KD
 *    @date   04-June-2021
 *    @description    Class to get the Relocation Requirements Form records based on different conditions
 *    Modification Log:
 *    ------------------------------------------------------------------------------------ 
 *    Developer                      Date                Description
 *    KD                         04-June-2021           Initial Version  
 *    ------------------------------------------------------------------------------------ 
 */
public without sharing class RelocationRequirementsFormsSelector extends ilib_SObjectSelector{

    private static final String LOG_TITLE = 'RelocationRequirementsFormsSelector';
    private static final String SALES_QUERY_LOGS = 'SalesQueryLogs'; 
    /*
    * @description  Constructor
    *
    */
	public RelocationRequirementsFormsSelector(){
		 super(false, false, false, true);
	}
    
    /*
    * @description  describe the object
    *
    */
    public Schema.SObjectType getSObjectType(){
        return Relocation_Requirements_Form__c.sObjectType;
    }
    /*  
    * @description  set select fields
    */
    public List<Schema.SObjectField> getSObjectFieldList(){
        return new List<Schema.SObjectField> {
            Relocation_Requirements_Form__c.Id,
            Relocation_Requirements_Form__c.Additional_Special_Considerations__c,
            Relocation_Requirements_Form__c.Are_instr_on_benches_or_wheeled_tables__c,
            Relocation_Requirements_Form__c.Are_instruments_already_crated__c,
            Relocation_Requirements_Form__c.Company_requesting_relocation_services__c,
            Relocation_Requirements_Form__c.Current_Location_Address__c,
            Relocation_Requirements_Form__c.DCIR_Required_for_Instrument_Relocations__c,
            Relocation_Requirements_Form__c.Delivery_Building_Access_Requirements__c,
            Relocation_Requirements_Form__c.Delivery_Contact_Name__c,
            Relocation_Requirements_Form__c.Delivery_Contacts_Phone_Number__c,
            Relocation_Requirements_Form__c.Delivery_Elevator_Type__c,
            Relocation_Requirements_Form__c.Delivery_Lab_BioSafety_Level__c,
            Relocation_Requirements_Form__c.Delivery_Loading_Dock__c,
            Relocation_Requirements_Form__c.Delivery_Location_Address__c,
            Relocation_Requirements_Form__c.Details_if_crates_are_not_needed__c,
            Relocation_Requirements_Form__c.Device_types_that_need_to_be_moved__c,
            Relocation_Requirements_Form__c.Do_you_require_purchased_crates__c,
            Relocation_Requirements_Form__c.Full_Uncrate_and_Place_at_Delivery_loc__c,
            Relocation_Requirements_Form__c.How_many_total_units_need_to_be_moved__c,
            Relocation_Requirements_Form__c.Illumina_Delivery_Contact__c,
            Relocation_Requirements_Form__c.Illumina_Delivery_Contacts_Number__c,
            Relocation_Requirements_Form__c.Illumina_Pick_Up_Contact__c,
            Relocation_Requirements_Form__c.Illumina_Pick_Up_Contacts_Number__c,
            Relocation_Requirements_Form__c.Is_loading_dock_truck_height__c,
            Relocation_Requirements_Form__c.Is_move_in_same_bldg_or_different_bldg__c,
            Relocation_Requirements_Form__c.Name_of_person_completing_this_form__c,
            Relocation_Requirements_Form__c.One_move_or_separate_sched_moves__c,
            Relocation_Requirements_Form__c.Pick_Up_Building_Access_Requirements__c,
            Relocation_Requirements_Form__c.Pick_Up_Contacts_Name__c,
            Relocation_Requirements_Form__c.Pick_Up_Contacts_Phone_Number__c,
            Relocation_Requirements_Form__c.Pick_Up_Elevator_Type__c,
            Relocation_Requirements_Form__c.Pick_Up_Lab_BioSafety_Level__c,
            Relocation_Requirements_Form__c.POReference_Number__c,
            Relocation_Requirements_Form__c.Preferred_Delivery_Date__c,
            Relocation_Requirements_Form__c.Preferred_Pick_Up_Date__c,
            Relocation_Requirements_Form__c.Time_delivery_loc_loading_dock_closes__c,
            Relocation_Requirements_Form__c.Time_delivery_loc_loading_dock_open__c,
            Relocation_Requirements_Form__c.Time_receiving_loading_dock_closes__c,
            Relocation_Requirements_Form__c.Time_receiving_loading_dock_open__c,
            Relocation_Requirements_Form__c.Unacceptable_Delivery_DatesTimes__c,
            Relocation_Requirements_Form__c.Unacceptable_Pick_Up_DatesTimes__c,
            Relocation_Requirements_Form__c.Unit_Serial_Numbers__c,
            Relocation_Requirements_Form__c.Weekend_Delivery__c,
            Relocation_Requirements_Form__c.Weekend_Pick_Up__c,
            Relocation_Requirements_Form__c.Wish_to_keep_the_instrument_crate__c,
            Relocation_Requirements_Form__c.Other_Delivery_Bldg_Access_Requirements__c,
            Relocation_Requirements_Form__c.Other_Device_Types_That_Need_To_Be_Moved__c,
            Relocation_Requirements_Form__c.Other_Pick_Up_Bldg_Access_Requirements__c,
            Relocation_Requirements_Form__c.Instr_Location_If_Not_Bench_Wheel_Table__c,
            Relocation_Requirements_Form__c.Opportunity__c,
            Relocation_Requirements_Form__c.Add_Billable_Service__c,
            Relocation_Requirements_Form__c.Illumina_Contracted_Crew__c,
            Relocation_Requirements_Form__c.Paying_Sold_to__c

        }; 
    }
    /**
     * @author KD
     * @date  04-June-2021 
     * @description  get  records using  Id
     * @param String
     */
    public Relocation_Requirements_Form__c getRecordbyId(String strFormId) {

        ilib_LogQuery logger= null;
        if (Feature.isOn(SALES_QUERY_LOGS)) logger = new ilib_LogQuery(
            LOG_TITLE + '.getRecordbyId',
            strFormId
        );
        String strQuery = newQueryFactory()
                        .setCondition('id = :strFormId')
                        .toSOQL();
        Relocation_Requirements_Form__c res = (Relocation_Requirements_Form__c) Database.query(strQuery);
        if (Feature.isOn(SALES_QUERY_LOGS)) logger.stop();
        return res;                
    }
    /**
     * @author KD
     * @date  04-June-2021
     * @description  get  pass key
     * Direct query so that its secure
     * @param String
     */
    public Relocation_Requirements_Form__c getPassbyId(String strFormId) {
        ilib_LogQuery logger = null;
        if (Feature.isOn(SALES_QUERY_LOGS)) logger = new ilib_LogQuery(
            LOG_TITLE + '.getPassbyId',
            strFormId
        );
        String strQuery = newQueryFactory(false)
                        .selectField('Id')
                        .selectField('Pass_Key__c')
                        .setCondition('id = :strFormId')
                        .toSOQL();
        Relocation_Requirements_Form__c res = (Relocation_Requirements_Form__c) Database.query(strQuery);
        if (Feature.isOn(SALES_QUERY_LOGS)) logger.stop();
        return res;      
    }
}