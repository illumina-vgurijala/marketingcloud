/**
*    @author Nishan Shetty
*    @date   2018-10-15
*    @description    ContentNote Selector class
*    Modification Log:
*    ----------------------------------------------------------------------------------------
*             Developer                      Date                Description
*	         Nishan Shetty                 7-Jun-2021            Initial
*            Gladis                        26-Sep-2022         Added Query Instrumentation
*    ------------------------------------------------------------------------------------------- 
*                    
*/
public with sharing class ContentNoteSelector extends ilib_SObjectSelector {
    
    private static final string  LOG_TITLE = 'ContentNoteSelector';
    private static final  string SERVICE_QUERY_LOGS = 'ServiceQueryLogs';
    /*
     *  @author                     : Nishan Shetty
     *  @description                : Get sObjectType.
     *  @return                     : sObjectType for ContentNote.
     * 
     */
    public Schema.SObjectType getSObjectType() {
    return ContentNote.sObjectType;
    }

    /*
     *  @author                     : Nishan Shetty
     *  @description                : Get sObjectField.
     *  @return                     : sObjectField for ContentNote.
     * 
    */
    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField> {
            ContentNote.Id,
            ContentNote.Title,
            ContentNote.Content
            
        };
     }

    /*
     *  @author Nishan Shetty
     *  @description Select Conten Notes 
     *  @param setDocumentIds Set of document Ids
     *  @return List of Content Note
     */
    public List<ContentNote> selectContentNotes(Set<Id> setDocumentIds) {

        ilib_LogQuery logger = null;
        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.selectContentNotes', UtilsCollection.serializeIds(setDocumentIds));
        }
        List<ContentNote> res = (List<ContentNote>) Database.query(
             newQueryFactory().setCondition('Id IN :setDocumentIds').toSOQL()
        );

        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger.stop(res.size());
        }

        return res;
    }
}