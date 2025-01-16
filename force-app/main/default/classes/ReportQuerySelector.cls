/**
*    @author Saddam
*    @date   11-FEB-21
*    @description: PM-41 Returns reports based on reportname
*    Modification Log:
*    ---------------------------------------------------------------------------------------------------------------------------
*         Developer               Date                Description
*          Saddam                11-FEB-22         Initial Version
*    ---------------------------------------------------------------------------------------------------------------------------
**/

public with sharing class ReportQuerySelector extends ilib_SObjectSelector {
      
 /*
    * @author Saddam
    * @date   11-Feb-2022
    * @description  describe the object(Report) and Report fields (PM-41)
    *
    */
    public Schema.SObjectType getSObjectType() {
        return Report.sObjectType;
    }

    /* Constructor method */
    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField> {
            Report.Description,
            Report.DeveloperName,
            Report.FolderName,
            Report.Name,
            Report.id
        };
    }
/*
    * @author : Saddam
    * @date  : 11-Feb-2022
    * params: ReportApi in a list 
    * return :Returns list of Reports data.
    */
    public  list<Report> selectByReportName(List<string> reportApiName) {

         return (list<Report>) Database.query(newQueryFactory().setCondition('DeveloperName IN :reportApiName').toSOQL());
    }
}






