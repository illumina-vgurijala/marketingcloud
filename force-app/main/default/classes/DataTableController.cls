/***************************************************************************************************************************************
* NAME   : DataTableController 
* DESCRIPTION  : Controller class for the Data Table.
*                    
* @AUTHOR : Digvijay Singh
* @DATE   : 15-May-2020  
* 
* MODIFICATION LOG: 
 Digvijay Singh               15-May-2020           Initial Version. Added logic for DCP-33468.
******************************************************************************************************/

public with sharing class DataTableController {

    /*
     * Constructor
     */
    public DataTableController() {

    }

      /**
     *  @AUTHOR:  Digvijay Singh
     *  @DESCRIPTION: This method returns a Wrapper object having :-
     *     a)List of labels used to displaycolumns of DataTable
           b)List of Rows as Sobject List
           c)totalCount of records
     *  @PARAM :  Multiple params of String , Map, Integer . Some  of them are:-
     *   a) objectName : Object for which data needs to be displayed
     *   b)  fieldNamesStr: Map having Fields to be diplayed along with the initial width for the Field's column
     *   c)  enableColAction: if true  enable's row action in the data table
     *   d)  lookupmap: Map for coulms where data need to be dispayed from look up record
     *   e)  rowactionmap: Map for all the  row actions needed.
     *   f) columnactionmap: if any columns need to used as action rather then displaying data (ex: showing a button on a column)
     *   g) noofrecordstoload: no of records to be loaded on  initail load , next records will be loaded on scroll
     */
    @AuraEnabled(cacheable=true)
    public static DataTableWrapper initRecords(String objectName, Map<String, Object> fieldNamesStr, String recordId, String orderby, String orderDir, boolean inlineEdit, boolean enableColAction,Map<String, Object> lookupmap,Map<String, Object> rowactionmap,String whereclause,Map<String, Object> columnactionmap,Integer initialWidth,Integer noofrecordstoload) {
       
    try{
        DataTableWrapper dtw = new DataTableWrapper();

        //holds List of columns Labels. LabelDescriptionWrapper class contains variabels which define property
        // for each Label. 
        List<LabelDescriptionWrapper> labelList = new List<LabelDescriptionWrapper>();
        List<String> fieldSet = new List<String>();
   
        if(Schema.getGlobalDescribe().containsKey(ObjectName) ) {
            
            //get all the labels for Object fields and put them in a map, keyed to the field api name
            Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get(ObjectName).getDescribe().fields.getMap();
            //Creates column Label for Custom Fields(if block)and Look up fields(else block )
            for(String fieldName :  fieldNamesStr.keySet()){
                if(fieldMap.containsKey(fieldName)) {
                    fieldSet.add(fieldName);
                }else {
                    if(lookupmap!=null && !lookupmap.IsEmpty() && lookupmap.containsKey(fieldName) ){
                    fieldSet.add(fieldName);
                    }

                }
            
                labelList.add(getLabelDescWrapObject(fieldName,fieldMap,lookupmap,fieldNamesStr,inlineEdit));
            }

           

            //For a column where a action need to be added rather than showing just data
            if(columnactionmap!=null && !columnactionmap.IsEmpty()){
                labelList.addAll(getLabelDescWrapObjectlist(columnactionmap));       
            }
           
           //add Row actions in the data table.
            if(enableColAction) {
                labelList.add(getLabelDescWrapObject(rowactionmap));
            }

            
            //call method to query
            List<sObject> sObjectRecords = getsObjectRecords(ObjectName, fieldSet, noofrecordstoload, recordId, Orderby, OrderDir, whereclause);
            dtw.ldwList     = labelList;
            dtw.sobList     = sObjectRecords;
            dtw.fieldsList  = fieldSet;
            //fetch total count for lazy loading on scroll
            if(whereclause!=null && whereclause!='')
            dtw.totalCount  = Database.countQuery('SELECT count() FROM '+ObjectName +' where '+whereclause);
            else 
            dtw.totalCount  = Database.countQuery('SELECT count() FROM '+ObjectName);
        }
        return dtw;
    }catch(Exception e){
            //get exception message
            throw new AuraHandledException(e.getMessage());
        }
    }
    

    /**
     *  @AUTHOR:  Digvijay Singh
     *  @DESCRIPTION: This method returns a List of Sobjects(row data for the datatable) :-
     *  @PARAM :  Multiple params of String , List, Integer .
     *   
     */
    @AuraEnabled(cacheable=true)
    public static List<sObject> getsObjectRecords(String objectName, List<String> fieldNameSet, Integer limitSize, String recId, String orderby, String orderDir,String whereclause) {
    try{ 
        OrderDir = String.isBlank(OrderDir) ? 'asc' : OrderDir;
        String query = 'SELECT '+String.join(fieldNameSet, ',')+'  FROM '+ObjectName;

        //append the passed where clasue to the table
        if(whereclause!=null && whereclause!=''){
            query=query+' where '+ whereclause;
        }
        
        //add the conidtion to fetch Next records incase of scroll(the last id in the table is passed as param)
        if(String.isNotBlank(recId)) {
            recId = String.valueOf(recId);
            if(String.isNotBlank(whereclause)){
                query+=' and ID >: recId';
            }
            else{
                query+=' Where ID >: recId';
            }
        }
        //add the order clause and Limit
        query += ' ORDER BY '+Orderby+' '+OrderDir+' NULLS LAST';
        
        if(LimitSize != null && Integer.valueOf(LimitSize) > 0) {
            LimitSize = Integer.valueOf(LimitSize);
            query += ' Limit '+LimitSize;
        }
        
        return Database.query(query);
    }catch(Exception e){
            //get exception message
            throw new AuraHandledException(e.getMessage());
        }
        
    }

     /**
     *  @AUTHOR:  Digvijay Singh
     *  @DESCRIPTION: This method deletes a Row if delete is enabled -
     *  @PARAM :  Sobject record . 
     */
    @AuraEnabled
    public static sObject deleteSObject(sObject sob) {
        delete sob;
        return sob;
    }
    
     /**
     *  @AUTHOR:  Digvijay Singh
     *  @DESCRIPTION: This method allows to edit and save the row's if Inline edit is enabled
     *  @PARAM :  Sobject List(list of all rows) , updateObjStr (row in json as string) ,objectName (the object name) . 
     */
    @AuraEnabled
    public static void updateRecords(List<sObject> sobList, String updateObjStr, String objectName) {
      try{  
        schema.SObjectType sobjType = Schema.getGlobalDescribe().get(ObjectName);
        
        Map<String, Schema.sObjectField> sObjectFields = sobjType.getDescribe().fields.getMap();
        List<sObject> updateList = new List<sObject>();

        //Deserialize the row json
        List<Object> obList = (List<object>) json.deserializeUntyped(updateObjStr);
        for(object ob : obList) {

            Map<String, object> obmap = (Map<String, object>)ob;
            String rowKey = (String)obmap.get('id');
            Integer rowKeyInt = Integer.ValueOf(rowKey.removeStart('row-'));
            
            //get the Sobject from the Sobject List for the row which is updated
            sobject sObj = sobList[rowKeyInt];

            for(string fieldName : obmap.keySet()) {
                if(fieldName != 'id') {
                    Object value = obmap.get(fieldName);
                    Schema.DisplayType valueType = sObjectFields.get(fieldName).getDescribe().getType();

                    //format the Field value to Salesforce compatibe type before Save.
                    if (value instanceof String && valueType != Schema.DisplayType.String)
                    {

                        sObj=getFormattedValue(sObj,value,valueType,fieldName);
                    }
                    else
                        sObj.put(fieldName, value);
                }
            }
            updateList.add(sObj);
        }
        
        update updateList;
      }catch(Exception e){
            //get exception message
            throw new AuraHandledException(e.getMessage());
        }
    }


/*************************
* NAME   : DataTableWrapper 
* DESCRIPTION  : Wrapper class for the Data Table.
*                    
* @AUTHOR : Digvijay Singh
* @DATE   : 15-May-2020  
****************************/
    public class DataTableWrapper {
        @AuraEnabled
        public List<LabelDescriptionWrapper> ldwList;
        @AuraEnabled
        public List<sObject> sobList;
        @AuraEnabled
        public List<String> fieldsList;
        @AuraEnabled
        public Integer totalCount;
    }

/***************************
* NAME   : LabelDescriptionWrapper 
* DESCRIPTION  : Wrapper class for the  DataTable Column Properties .
*                    
* @AUTHOR : Digvijay Singh
* @DATE   : 15-May-2020  
****************************/
    public class LabelDescriptionWrapper {
        @AuraEnabled
        public String label;
        @AuraEnabled
        public String fieldName;
        @AuraEnabled
        public String type;
        @AuraEnabled
        public boolean wrapText= true;
        @AuraEnabled
        public boolean sortable;
        @AuraEnabled
        public boolean editable;
        @AuraEnabled
        public TypeAttributes  typeAttributes;
        @AuraEnabled
        public CellAttributes cellAttributes;
        @AuraEnabled
        public Integer minColumnWidth;
        @AuraEnabled
        public Integer initialWidth;
        
        /*
        * @description Constructor: used to intantiate required information
        */
        public LabelDescriptionWrapper(String labelTemp, String fieldNameTemp, String typeTemp, boolean sortableTemp, boolean editableTemp,TypeAttributes typeAttributesTemp,Integer initialWidth,CellAttributes cellAttributestemp) {
            label     = labelTemp;
            fieldName = fieldNameTemp;
            type      = typeTemp;
            sortable  = false;//sortableTemp;
            editable = editableTemp;
            typeAttributes = typeAttributesTemp;
            this.minColumnWidth=initialWidth;
            this.cellAttributes=cellAttributestemp;


            //for salesforce Field type as refrence convert it to data table type url to display it as hyper link 
            //on the UI
            if(typeTemp=='reference' ){
                type= 'url';
                
                label  lanbelobj;
                Tooltip tobj;

                //a member name label on  TypeAttributes class is used to assign a different label to a table column's value
                //Hence created a label for the lookup fields . for Lookup's the fieldName was append with Link while calling below link of code
                if(fieldName.endsWith('Link') && fieldName!='nameLink'){
                    lanbelobj=new label(labelTemp.replace(' ', '').toLowerCase());
                    tobj=new  Tooltip(labelTemp.replace(' ', '').toLowerCase());
                }
                
                //for Name column  to be shown as hyper Link
                if( fieldName=='nameLink'){
                    lanbelobj=new label('Name');
                    tobj=new  Tooltip('Name');
                }
                
                //member typeAttributes  object on LabelDescriptionWrapper is used to add a property to the column label
                typeAttributes = new TypeAttributes(lanbelobj,null,null,null);
                typeAttributes.tooltip=tobj;
            }
        }
    }
    
/***************************
* NAME   : TypeAttributes 
* DESCRIPTION  : Wrapper class for the  member typeAttributes  object on LabelDescriptionWrapper class.
*                    
* @AUTHOR : Digvijay Singh
* @DATE   : 15-May-2020  
****************************/
    public virtual class TypeAttributes  {
        @AuraEnabled
        public List<Actions> rowActions;
        @AuraEnabled
        public label  label;

        @AuraEnabled
        public Tooltip  tooltip;
        @AuraEnabled
        public String target='_blank';

        @AuraEnabled
        public String iconName;
        @AuraEnabled
        public String name;
        @AuraEnabled
        public String title;
        @AuraEnabled
        public String value;
        @AuraEnabled
        public String initialWidth;

     /*
    * @description :Empty Constructor
    */      
        public typeAttributes() {
            
        }

        /*
        * @description : Intantiate data to a list of wrapper class
        * @params : List of wrapper class
        */        
        public typeAttributes(List<Actions> rowActionsTemp) {
            rowActions    = rowActionsTemp;
        }

        /*
        * @description : Intantiate required information
        * @params : class Instance(label),String,String,String
        */
        public typeAttributes(label labeltemp,String name,String label,String initialWidth) {
           this.label = labeltemp;
           this.name=name;
          // this.initialWidth=initialWidth;
        }
    }


/***************************
* NAME   : Label 
* DESCRIPTION  : Wrapper class for the  member Label  object on TypeAttributes class.
*                    
* @AUTHOR : Digvijay Singh
* @DATE   : 15-May-2020  
****************************/
    public class Label{
        @AuraEnabled
        public String fieldName;
        @AuraEnabled
        public String label;

        /* 
        * @description: wrapper class constructor used to intantiate required information
        * @params: String
        */
        public label(String s){
            fieldName=s;
        }
    }

/***************************
* NAME   : Tooltip 
* DESCRIPTION  : Wrapper class for the  member tooltip  object on TypeAttributes class.
*                    
* @AUTHOR : Digvijay Singh
* @DATE   : 15-May-2020  
****************************/

    public class Tooltip{
        @AuraEnabled
        public String fieldName;
        
        /* 
        * @description: wrapper class constructor, used to intantiate required information related to tooltip
        * @params: String
        */
        public Tooltip(String s){
            fieldName=s;
        }
    }

/***************************
* NAME   : Actions 
* DESCRIPTION  : Wrapper class to add row actions on the action column on data table.
*                    
* @AUTHOR : Digvijay Singh
* @DATE   : 15-May-2020  
****************************/
    public class Actions {
        @AuraEnabled
        public String label;
        @AuraEnabled
        public String name;

         /* 
        * @description: wrapper class constructor, used to intantiate required information
        * @params: String, String
        */      
        public Actions(String labelTemp, String nameTemp) {
            label       = labelTemp;
            name        = nameTemp;
        }
    } 
    
/***************************
* NAME   : CustomAttributes 
* DESCRIPTION  : TypeAttributes has a member "label", in some instances(according to field types) 
* it can be of complex type or a Simple string . As in both cases the member name has to be same , hence created
* this class which exetnds TypeAttributes class and defines "label" as string rather than a comples type as in TypeAttributes class
*                    
* @AUTHOR : Digvijay Singh
* @DATE   : 15-May-2020  
****************************/
    
    public class CustomAttributes  extends TypeAttributes {
        @AuraEnabled
        public String iconName;
        @AuraEnabled
        public String name;
        @AuraEnabled
        public String title;
        @AuraEnabled
        public String value;
        @AuraEnabled
        public String label;

        @AuraEnabled
        public Integer initialWidth;

        @AuraEnabled
        public boolean wrapText;
     
        /* 
        * @description: wrapper class constructor, used to intantiate required information
        * @params: String,String,Integer
        */ 
        public CustomAttributes(String name , String label, Integer initialWidth){
        
            this.name=name;
            this.label=label;
           
            this.wrapText=false;
        }
        
        
    }

/***************************
* NAME   : CellAttributes 
* DESCRIPTION  : Wrapper class to add a property to a tabel cell.
*                    
* @AUTHOR : Digvijay Singh
* @DATE   : 15-May-2020  
****************************/
    /* 
    * @description: wrapper class which holds Table cell attributes information
    */
    public class CellAttributes {

        @AuraEnabled
        public String alignment;
        @AuraEnabled
        public String style;
        
        /**
        * @description Assign alignment with align
        * @author 
        * @param align 
        **/
        public CellAttributes(String align){
        this.alignment=align;
        
        }
        
        
 }

 /***************************
* NAME   : getLabelDescWrapObject 
* DESCRIPTION  : Wrapper class to add a label.
*                    
* @AUTHOR : Digvijay Singh
* @DATE   : 15-May-2020  
****************************/


 public static LabelDescriptionWrapper getLabelDescWrapObject(String fieldName, Map<String, Schema.SObjectField> fieldMap,Map<String, Object> lookupmap,Map<String, Object> fieldNamesStr, boolean inlineEdit) {
    
    LabelDescriptionWrapper wrapobj;
     String colwidth=(String)fieldNamesStr.get(fieldName);
                if(fieldMap.containsKey(fieldName)) {

                    String type=fieldMap.get(fieldName).getDescribe().getType().name().toLowerCase();
                 /**Salesforce field type was not visible by default on datatable . 
                    Hence type modified to datatable compatibe type.**/
                    if(type=='double')
                        type='number';
               
               /**Datatable by default was not displaying the ID and the look up columns with Name value, t
               they were displayed as plain Id Values , hence did below work around **/ 

               //for all othere columns execpt ID and Name , create column Label normally
                if(fieldName!='Id' && fieldName!='Name'){
                      wrapobj=new LabelDescriptionWrapper(fieldMap.get(fieldName).getDescribe().getLabel(), fieldName, type, true, inlineEdit, null,null, new CellAttributes('left')  );
                     if(colwidth!=null && colwidth!='')
                        wrapobj.initialWidth=Integer.valueOf(colwidth);
                    
                    }
                
                //For Name columns type is defined as "refrence" on Label to make it a hyperLink
                if(fieldName=='Name'){
                
                     wrapobj=new LabelDescriptionWrapper(fieldMap.get(fieldName).getDescribe().getLabel(), 'nameLink','reference', true, false, null,null,new CellAttributes('left')  );
                    if(colwidth!=null && colwidth!='')
                        wrapobj.initialWidth=Integer.valueOf(colwidth);
                   
                    }

                }else {
                  //For Look up columns type is defined as "refrence" on Label to make it a hyperLink
                    if(lookupmap!=null && !lookupmap.IsEmpty() && lookupmap.containsKey(fieldName) ){
                        String s=(String)lookupmap.get(fieldName);
                         wrapobj=new LabelDescriptionWrapper(s,s.replace(' ', '').toLowerCase()+'Link', 'reference', true, false, null ,null,new CellAttributes('left') );
                         if(colwidth!=null && colwidth!='')
                            wrapobj.initialWidth=Integer.valueOf(colwidth);
                       
                    }
                }
                
                return wrapobj;

    
}

/***************************
* NAME   : getLabelDescWrapObject for action columns 
* DESCRIPTION  : Wrapper class to add a label.
*                    
* @AUTHOR : Digvijay Singh
* @DATE   : 15-May-2020  
****************************/

public static List<LabelDescriptionWrapper> getLabelDescWrapObjectlist(Map<String, Object> columnactionmap) {
    List<LabelDescriptionWrapper> labelList = new List<LabelDescriptionWrapper>();
    for(String key:columnactionmap.keyset()){
        String label=(String)columnactionmap.get(Key);
    
    // assign the default initial width
        String labelwidth='180';
        String labelString=label;
        if(label.contains(',')){
        //override the label width with the value passed to the componenet 
            labelwidth=label.split(',')[1];
            labelString=label.split(',')[0];
        }
        

        Label lobj=new Label(null);
        lobj.label=key;

        //TypeAttributes Provides custom formatting with component attributes for the data type.
        TypeAttributes  typeAttributes = new CustomAttributes(key.replace(' ', '').toLowerCase()+'button',key,200);

        //CellAttributes to set a propety on the table cell.
        CellAttributes cobj=new CellAttributes('left');
        LabelDescriptionWrapper wrapobj=new LabelDescriptionWrapper(labelString,key.replace(' ', '').toLowerCase()+'button', 'button', true, false, typeAttributes,null,cobj);
        wrapobj.initialWidth=Integer.valueOf(labelwidth);

        labelList.add(wrapobj);  
        
        }
        
        return labelList;


}

/***************************
* NAME   : getLabelDescWrapObject for row action 
* DESCRIPTION  : Wrapper class to add a label.
*                    
* @AUTHOR : Digvijay Singh
* @DATE   : 15-May-2020  
****************************/

public Static LabelDescriptionWrapper getLabelDescWrapObject(Map<String, Object> rowactionmap) {
     
    List<Actions> actionList = new List<Actions>();
        if(rowactionmap!=null && !rowactionmap.isEmpty()){
            for(String key:rowactionmap.keyset()){
                String s=(String)rowactionmap.get(key);
                actionList.add(new Actions(key,s));
            }
    }
        TypeAttributes tAttribute = new TypeAttributes(actionList);
        LabelDescriptionWrapper wrapobj=new LabelDescriptionWrapper('', '', 'action', false, false, tAttribute ,null ,null);
    
return wrapobj;

}

/***************************
* NAME   : getFormattedValue for a cell 
* DESCRIPTION  : getFormattedValue for a cell 
*                    
* @AUTHOR : Digvijay Singh
* @DATE   : 15-May-2020  
****************************/

public static sobject getFormattedValue(sobject sObj,Object value,Schema.DisplayType valueType,String fieldName ){
    
        String svalue = (String)value;
        if (valueType == Schema.DisplayType.Date)
            sObj.put(fieldName, Date.valueOf(svalue));
        else if(valueType == Schema.DisplayType.DateTime) {
            
            String d1 = svalue;
            list<String> d2 = d1.split('-');
            list<integer> timeComponent = new list<integer>();
            timeComponent.add(Integer.valueOf(d2[0]));
            timeComponent.add(Integer.valueOf(d2[1]));
            timeComponent.add(Integer.valueOf(d2[2].left(2)));
            
            String t = d2[2].substringBetween('T','.');
            
            list<String> time1 = t.split(':');
            timeComponent.add(Integer.valueOf(time1[0]));
            timeComponent.add(Integer.valueOf(time1[1]));
            timeComponent.add(Integer.valueOf(time1[2]));
            
            Datetime dt = Datetime.newInstance(timeComponent[0],timeComponent[1],timeComponent[2],timeComponent[3],timeComponent[4],timeComponent[5]);
            sObj.put(fieldName, dt);
        }
        //
        else if (valueType == Schema.DisplayType.Percent || valueType == Schema.DisplayType.Currency)
            sObj.put(fieldName, svalue == '' ? null : Decimal.valueOf(svalue));
        else if (valueType == Schema.DisplayType.Double)
            sObj.put(fieldName, svalue == '' ? null : Double.valueOf(svalue));
        else if (valueType == Schema.DisplayType.Integer)
            sObj.put(fieldName, Integer.valueOf(svalue));
        else if (valueType == Schema.DisplayType.Base64)
            sObj.put(fieldName, Blob.valueOf(svalue));
        else
            sObj.put(fieldName, svalue);

    return sObj;
    
}

 

}