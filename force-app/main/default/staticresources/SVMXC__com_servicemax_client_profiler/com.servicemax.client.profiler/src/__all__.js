// Code: C:\Users\Framework\.hudson\jobs\SFMDelivery_sfdc_dev\workspace\src\modules\com.servicemax.client.profiler\src\api.js
/**
 * # Package #
 * This package provides t
 *
 * @class com.servicemax.client.profiler.api
 * @singleton
 * @author Boonchanh Oupaxay
 * 
 * @copyright 2014 ServiceMax, Inc.
 */

;(function(){
    "use strict";

	var profilerApi = SVMX.Package("com.servicemax.client.profiler.api");
	
profilerApi.init = function() {
    var TS = SVMX.getClient().getServiceRegistry().getServiceInstance("com.servicemax.client.translation");
    var SVMXProfiler = SVMX.getProfilingService();
    
    // start document region
    ///////////////////////////
    // TODO:we can move this later to a document module.
    //create the work order method
    var createWorksheet = function(title, data) {
        var datacol = [];
        if (data.length > 0) {
            for (var idx in data[0]) {
                datacol.push(idx);
            }                         
        } 
                          
        var cellType = [];
        var cellTypeClass = [];
        var totalWidthInPixels = 0;
        var colXml = '';
        var headerXml = '';
        var visibleColumnCountReduction = 0;
        var colCount = datacol.length;  //field
        var defaultWidth = 100;
            
        //xml header
        for (var i = 0; i < colCount; i++) {
            totalWidthInPixels += defaultWidth;

            colXml += '<Column ss:AutoFitWidth="1" />';
            headerXml += '<Cell ss:StyleID="headercell">' +
                    '<Data ss:Type="String">' + datacol[i] + '</Data>' +
                    '<NamedCell ss:Name="Print_Titles"></NamedCell></Cell>';
                
            cellType.push("String");
            cellTypeClass.push("");
        }
        
        var visibleColumnCount = cellType.length - visibleColumnCountReduction;
        var result = {
            height: 9000,
            width: Math.floor(totalWidthInPixels * 30) + 50
        };

        var numGridRows = data.length + 2;  
        var xml = ''.concat(
            '<Worksheet ss:Name="' + title + '">',

            '<Names>',
            '<NamedRange ss:Name="Print_Titles" ss:RefersTo="=\'' + title + '\'!R1:R2">',
            '</NamedRange></Names>',

            '<Table ss:ExpandedColumnCount="' + (visibleColumnCount + 2),
            '" ss:ExpandedRowCount="' + numGridRows + '" x:FullColumns="1" x:FullRows="1" ss:DefaultColumnWidth="100" ss:DefaultRowHeight="15">',
            colXml,
            '<Row ss:Height="38">',
            '<Cell ss:MergeAcross="' + (visibleColumnCount - 1) + '" ss:StyleID="title">',
            '<Data ss:Type="String" xmlns:html="http://www.w3.org/TR/REC-html40">',
            '<html:b>' + title + '</html:b></Data><NamedCell ss:Name="Print_Titles">',
            '</NamedCell></Cell>',
            '</Row>',
            '<Row ss:AutoFitHeight="1">',
            headerXml +
            '</Row>'
        );


        // Generate the data rows from the data in the Store
        var record = null;
        for (var i=0; i < data.length; i++) {    
            xml += '<Row>';
            var cellClass = (i & 1) ? 'odd' : 'even';
            record = data[i];
            var k = 0;
            //align the data val with the correct index
            for (var j=0; j < datacol.length; j++) {
                var val = record[datacol[j]];//get the index data value
                if (cellType[k] !== "None") {
                    xml += '<Cell ss:StyleID="' + cellClass + cellTypeClass[k] + '"><Data ss:Type="' + cellType[k] + '">';
                    xml += val;
                    xml += '</Data></Cell>';
                }
                k++;                    
            }
            xml += '</Row>';
        }

        result.xml = xml.concat(
            '</Table>',
            '<WorksheetOptions xmlns="urn:schemas-microsoft-com:office:excel">',
            '<PageLayoutZoom>0</PageLayoutZoom>',
            '<Selected/>',
            '<Panes>',
            '<Pane>',
            '<Number>3</Number>',
            '<ActiveRow>2</ActiveRow>',
            '</Pane>',
            '</Panes>',
            '<ProtectObjects>False</ProtectObjects>',
            '<ProtectScenarios>False</ProtectScenarios>',
            '</WorksheetOptions>',
            '</Worksheet>'
        );        
                
        return result;
    };     
    
    // TODO:we can move this later to a document module.
    var createExcelWorkbook = function(name, collection) {
        var wrkShts = [];
        var workBookName = name || "Profiler Data";
        var totalWidth = 500;
        var wrkbkWidth;
        var wrkbkHeight;
        
        // loop to data collection to create the worksheet
        for(var idx in collection) {
            var data = collection[idx];
            var wksht = createWorksheet(idx, data);
            wrkbkWidth = wrkbkWidth || wksht.width;
            wrkbkHeight = wrkbkWidth || wksht.height;
            wrkShts.push(wksht.xml)
        }
        
        return ''.concat(
            '<?xml version="1.0"?>',
            '<Workbook xmlns="urn:schemas-microsoft-com:office:spreadsheet" xmlns:o="urn:schemas-microsoft-com:office:office" xmlns:x="urn:schemas-microsoft-com:office:excel" xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet" xmlns:html="http://www.w3.org/TR/REC-html40">',
            '<DocumentProperties xmlns="urn:schemas-microsoft-com:office:office"><Title>' + workBookName + '</Title></DocumentProperties>',
            '<OfficeDocumentSettings xmlns="urn:schemas-microsoft-com:office:office"><AllowPNG/></OfficeDocumentSettings>',
            '<ExcelWorkbook xmlns="urn:schemas-microsoft-com:office:excel">',
            '<WindowHeight>' + wrkbkHeight + '</WindowHeight>',
            '<WindowWidth>' + wrkbkWidth + '</WindowWidth>',
            '<ProtectStructure>False</ProtectStructure>',
            '<ProtectWindows>False</ProtectWindows>',
            '</ExcelWorkbook>',

            '<Styles>',

            '<Style ss:ID="Default" ss:Name="Normal">',
            '<Alignment ss:Vertical="Bottom"/>',
            '<Borders/>',
            '<Font ss:FontName="Calibri" x:Family="Swiss" ss:Size="12" ss:Color="#000000"/>',
            '<Interior/>',
            '<NumberFormat/>',
            '<Protection/>',
            '</Style>',

            '<Style ss:ID="title">',
            '<Borders />',
            '<Font ss:Bold="1" ss:Size="18" />',
            '<Alignment ss:Horizontal="Center" ss:Vertical="Center" ss:WrapText="1" />',
            '<NumberFormat ss:Format="@" />',
            '</Style>',

            '<Style ss:ID="headercell">',
            '<Font ss:Bold="1" ss:Size="10" />',
            '<Alignment ss:Horizontal="Center" ss:WrapText="1" />',
            '<Interior ss:Color="#A3C9F1" ss:Pattern="Solid" />',
            '</Style>',


            '<Style ss:ID="even">',
            '<Interior ss:Color="#FFFFFF" ss:Pattern="Solid" />',
            '</Style>',


            '<Style ss:ID="evendate" ss:Parent="even">',
            '<NumberFormat ss:Format="yyyy-mm-dd" />',
            '</Style>',


            '<Style ss:ID="evenint" ss:Parent="even">',
            '<Numberformat ss:Format="0" />',
            '</Style>',

            '<Style ss:ID="evenfloat" ss:Parent="even">',
            '<Numberformat ss:Format="0.00" />',
            '</Style>',

            '<Style ss:ID="odd">',
            '<Interior ss:Color="#CCFFFF" ss:Pattern="Solid" />',
            '</Style>',

            '<Style ss:ID="groupSeparator">',
            '<Interior ss:Color="#D3D3D3" ss:Pattern="Solid" />',
            '</Style>',

            '<Style ss:ID="odddate" ss:Parent="odd">',
            '<NumberFormat ss:Format="yyyy-mm-dd" />',
            '</Style>',

            '<Style ss:ID="oddint" ss:Parent="odd">',
            '<NumberFormat Format="0" />',
            '</Style>',

            '<Style ss:ID="oddfloat" ss:Parent="odd">',
            '<NumberFormat Format="0.00" />',
            '</Style>',


            '</Styles>',
            wrkShts.join(""),
            '</Workbook>'
        );
    };
    /////////////////////
    // end document region
    
    /**
     * This is the UI module for the profiler
     *
     */              
    profilerApi.Class("ProfilerConsole", com.servicemax.client.lib.api.Object, {
        __data: null,
        __stores: null,
        __fields: null,
        __gridconfig: null,
//        __mainpanel: null,

        /**
         *
         * @returns {null|__instance|*|.ThemeService.__instance|.NamedInstanceService.__instance}
         * @private
         */
        __constructor: function() {
            //singleton check
            if (!!profilerApi.ProfilerConsole.__instance) {
                return profilerApi.ProfilerConsole.__instance;
            }
            
            profilerApi.ProfilerConsole.__instance = this;

            this.__data = {};
            this.__stores = {};
            this.__fields = {};
            this.__mainpanel = null;
            //This option config the columns for specfic types of tabs
            this.__gridconfig = {
                PerformanceResourceTiming: {
                    name:{
                        order: 1,
                        flex:1,
                        width:300
                    },
                    entryType: {
                        hidden: true
                    },
                    duration: {
                        xtype: 'numbercolumn',
                        format:'0.00',
                        width: 150
                    },
                    initiatorType: {
                        hidden: false
                    },
                    startTime: {
                        order: 2,
                        xtype: 'numbercolumn',
                        format:'0.00',
                        width: 150
                    },
                    endTime: {
                        order: 3,
                        xtype: 'numbercolumn',
                        format:'0.00',
                        width: 150
                    }
                },
                PerformanceMeasure: {
                    name:{
                        order: 1,
                        flex:1,
                        width:300
                    },
                    entryType: {
                        hidden: true
                    },
                    duration: {
                        xtype: 'numbercolumn',
                        format:'0.00',
                        width: 150
                    },
                    startTime: {
                        order: 2,
                        xtype: 'numbercolumn',
                        format:'0.00',
                        width: 150
                    }
                },
                PerformanceEntry: {
                    name:{
                        order: 1,
                        flex:1,
                        width:300
                    },
                    entryType: {
                        hidden: true
                    },
                    duration: {
                        xtype: 'numbercolumn',
                        format:'0.00',
                        width: 150
                    },
                    startTime: {
                        order: 2,
                        xtype: 'numbercolumn',
                        format:'0.00',
                        width: 150
                    }
                }
                
            };

            this.__init();
        },

        /**
         *
         * @returns {*}
         * @private
         */
        __processClientPerformanceData: function(){
            var types = SVMXProfiler.getEntryTypes();
            
            for (var i=0; i < types.length; i++) {
                var name = types[i].name;
                var data = SVMXProfiler.getEntriesByType(types[i].entry);
                
                switch(name){
                    case "PerformanceMeasure":
                    case "PerformanceEntry":
                        var measurements = SVMXProfiler.getMeasureEntryTypes();
                        var key = "";
                        var subdata = null;        
                        for(var k=0; k < measurements.length; k++) {
                            key = measurements[k].action + "_" + measurements[k].type
                            subdata = SVMXProfiler.getMeasureDataByText(key);
                            this.__createDataStore(subdata, key);     
                            this.__data[key] = this.__filterMeasurementDataName(subdata);
                        }
                        break;
                    
                    case "Object":
                        name = "PerformanceServer";     
                        break;
                    default:
                }
                
                this.__createDataStore(data, name);
                this.__data[name] = data;                   
            }
            
            return this;     
        },

        /**
         *
         * @returns {*}
         * @private
         */
        __processRawData: function(){
            this.__processClientPerformanceData();   
            
            return this;
        },

        /**
         *
         * @param source
         * @returns {{}}
         * @private
         */
        __copyEntryObject: function(source) {
            var target = {}; 
            
            for (var item in source) {
                target[item] = source[item];
            } 
            
            return target;
        },

        /**
         *
         * @param data
         * @returns {Array}
         * @private
         */
        __filterMeasurementDataName: function(data){
            var results = [];
            var name = "";
            var item = null;
            var node = null;
            
            for(var i=0; i < data.length; i++) {
                node = this.__copyEntryObject(data[i]);
                name = data[i].name;
                
                item = name.split("_");
                item.shift();
                item.shift();
                
                node.name = item.join("_"); 
                results.push(node);
            }
            
            return results;
        },

        /**
         *
         * @param name
         * @param append
         * @returns {*}
         * @private
         */
        __updateDataStore: function(name, append) {
            append = append || false;
            var store = this.__stores[name];
            var data = this.__data[name]; 
            store.loadRawData(data, append);

            return this;
        },
        /**
         *
         * @param record
         * @param exclude
         * @returns {Array}
         * @private
         */
        __getFieldList: function(record, exclude){
            var results = [];
            var item = null;
            var elist = exclude || [];
             
             
            for (var idx in record){
                if (this.__isIncluded(idx, elist)) {
                    results.push({
                        name: idx
                });
                }
            }

            return results;
        },
        /**
         *
         * @param val
         * @param list
         * @returns {boolean}
         * @private
         */
        __isIncluded: function(val, list) {
            for(var i=0; i < list.length; i++) {
                if (val == list[i]) {
                    return false
                }
            }
            return true;        
        },
        /**
         *
         * @param string
         * @returns {string}
         * @private
         */
        __capFirstCharacter : function(string){
            return string.charAt(0).toUpperCase() + string.slice(1);
        },

        /**
         *
         * @param idx
         * @param fields
         * @returns {Array}
         * @private
         */
        __getGridColumns: function(idx, fields){
            var results = [];
            var name = "";
            var settings = null;//:TODO
            var i = 0;

            var hash = this.__gridconfig[idx] || {};

            for (; i<fields.length; i++){
                name = fields[i].name;
                settings = hash[name] || {hidden:true};

                results.push(Ext.apply({
                    dataIndex: name,
                    text: this.__capFirstCharacter(name)
                }, settings));
            }

            results.sort(function(a,b){
                var anode = a.order || 100;
                var bnode = b.order || 100;

                return anode > bnode;
            });
            return results;
        },

        /**
         *
         * @param data
         * @param name
         * @returns {boolean}
         * @private
         */
        __createDataStore: function(data, name) {
            if (data.length == 0){
                return false;
            }
            if (!!this.__stores[name]) {
                return false
            }

            var exclude = ["rawdata"];
            var fields = this.__getFieldList(data[0], exclude); // just the record is needed

            //TODO: check if store exist
            var store = Ext.create("Ext.data.Store", {
                //storeId: name + "Store",
                fields: fields,
                proxy: {
                    type: 'memory',
                    reader: {
                        type: 'json',
                        root: 'items'
                    }
                },
                listeners: {
                    load: function(){
                        //debugger;
                        //console.log(s.sum('visits'));
                    }
                }
            });


            this.__stores[name] = store;
            this.__fields[name] = fields;
        },

        /**
         *
         * @private
         */
        __init: function() {
            //debugger;
            //this.__processRawData();
           //1) bind the
           SVMXProfiler.bind("REFRESH_CONTENT", this.__onUpdateUI , this)
        },

        /**
         *
         * @private
         */
        __onUpdateUI: function(evt) {
            //update the data
            var profilerConsole = profilerApi.ProfilerConsole.__instance;
            profilerConsole.__processRawData();
            if (!!profilerConsole.__mainpanel) {
                // TODO: refactor to not create;
                //
                var tabs =  this.__createTabs();
                profilerConsole.__mainpanel.removeAll()
                profilerConsole.__mainpanel.add(tabs);
            }
        },

        /**
         *
         * @param config
         * @returns {Ext.tab.Panel}
         * @private
         */
        __createTabPanel: function(config){
            var that = this;
            var defaults = {
                cls: "svmx-profiler-ui-container",  
                minHeight: 50,
                resizeHandles: "s",
                collapsible: true,
                collapsed: true,
                resizable: true,
                baseCls: "x-panel",
                title: "ServiceMax Profiler",
                renderTo: Ext.getBody(),
                tools: [{
                    type:'refresh',
                    tooltip: 'Reload Page',
                    hidden:true,
                    handler: function(event, toolEl, panel){
                        // refresh logic
                    }
                }],
                bbar: [
                    '->',
                    {
                        xtype: 'button',
                        text: 'Download Report',
                        baseCls: "x-panel",
                        listeners: {
                            click: function() {
                                that.__exportData();    
                            }    
                        }
                    }
                ],
                listeners : {
                    boxready: function(panel){
//                        debugger
                        var tools = panel.tools;
                        var arrow = tools[0];
                        tools.shift();
                        //tools.push(arrow);
                        
                        var profilerUI = $("#"+config.id).parent();
                        //move it to the top of the heap
                        $("#client_display_root").before(profilerUI);

                        this.doLayout();
                    },
                    expand: function(tabPanel){
                        if (!tabPanel.activeTab) {
                            tabPanel.setActiveTab(0)
                        }

                    }
                }
            };

            config = Ext.apply(defaults, config);
            return Ext.create("Ext.tab.Panel", defaults);
        },

        /**
         *
         * @private
         */
        __exportData: function(){   
            var collection = this.__data;
            var date = new Date();
            var filename = "Profiler Data " + date.getTime(); 
            var excelWorkbook = createExcelWorkbook(filename ,collection); 
            var blob = new Blob([excelWorkbook], {
                type: "application/vnd.ms-excel;charset=utf-8"
            });
            
            saveAs(blob, filename + ".xls");   
        },

        /**
         *
         * @param config
         * @param name
         * @param gridHashName
         * @returns {Ext.grid.Panel}
         * @private
         */
        __createGrid: function(config, name, gridHashName){
            var that = this;
            var hashName = gridHashName || name;
            var data = this.__stores[name];
            var fields = this.__fields[name];
            var columns = this.__getGridColumns(hashName, fields);

            return Ext.create('Ext.grid.Panel', {
                itemId: "grid-"+ name,
                title: name,
                header: false,
                baseCls: "x-panel",
                store: data,
                columns: columns,
                listeners:{
                    boxReady: function(grid){
                        grid.ownerCt.doLayout()
                    }
                }
            });

        },

        /**
         *
         * @param idx
         * @param gridHashName
         * @returns {{itemId: string, title: *, closable: boolean, height: number, autoScroll: boolean, items: *[], baseCls: string, listeners: {boxReady: boxReady, activate: activate}}}
         * @private
         */
        __assembleTabPanel: function(idx, gridHashName) {
            var that = this;
            var grid = this.__createGrid({}, idx, gridHashName);
             
            return {
                itemId: "panel-data-" + idx,
                title: idx,
                closable: false,
                height: 200,
                autoScroll: true,
                items: [grid],
                baseCls: "x-panel",
                listeners: {
                    boxReady: function (tab) {
                        //tabPanel.setActiveTab("grid-panel")
                        //debugger
                    },
                    activate: function (item) {
                        //debugger;
                        that.__updateDataStore(idx);
                    }
                }
            };
        },

        /**
         * Creates the tabs per performance data set
         * @return         
         */                 
        __createTabs: function(){
            var results = [];
            var items = this.__data;
            var idx = null;
            var tabPanel = null;
            var grid = null;
            var total = {};
            var count = {};

            for (idx in items) {
                if (idx == "PerformanceResourceTiming") { //default
                    tabPanel = this.__assembleTabPanel(idx);

                    total[idx] = this.__stores[idx].sum("duration");
                    count[idx] = this.__data[idx].length;

                    results.push(tabPanel);
                } else {// custom measurements
                    var skip = {
                        PerformanceMeasure : true,
                        PerformanceEntry: true
                    };
                    
                    if (!skip[idx])  { //default
                        var key = "PerformanceMeasure";
                        tabPanel = this.__assembleTabPanel(idx, key);
                        results.push(tabPanel);
                    }                     
                }
            }


            var html2 = //"Start Time: " + performance.timing.navigationStart +
            "<br>" +
            "  Duration: "   + (performance.timing.loadEventEnd - performance.timing.navigationStart)  + "<br>" +
            "    Unload: "     + (performance.timing.unloadEventEnd    - performance.timing.unloadEventStart)  + "<br>" +
            "  Redirect: "   + (performance.timing.redirectEnd       - performance.timing.redirectStart)     + "<br>" +
            " App Cache: "  + (performance.timing.domainLookupStart - performance.timing.fetchStart)        + "<br>" +
            "       DNS: "        + (performance.timing.domainLookupEnd   - performance.timing.domainLookupStart) + "<br>" +
            "       TCP: "        + (performance.timing.connectEnd        - performance.timing.connectStart)      + "<br>" +
            "   Request: "    + (performance.timing.responseStart     - performance.timing.requestStart)      + "<br>" +
            "  Response: "   + (performance.timing.responseEnd       - performance.timing.responseStart)     + "<br>" +
            "Processing: " + (performance.timing.loadEventStart    - performance.timing.responseEnd)       + "<br>" +
            "    Onload: "     + (performance.timing.loadEventEnd      - performance.timing.loadEventStart)    + "<br>";

            tabPanel = {
                itemId: "panel-data-summary",
                title: "Page Summary",
                closable: false,
                height: 200,
                autoScroll: true,
                html: html2,
                baseCls: "x-panel",
                listeners: {
                    boxReady: function (tab) {
                        //tabPanel.setActiveTab("grid-panel")
                        //debugger
                    },
                    activate: function (item) {
                        // debugger

                    }
                }
            };

            results.splice(0,0,tabPanel);

            return results;             
        },

        /**
         *
         * @param options
         * @param callback
         */
        init: function(options, callback) {
            /**
             * checks the root container for the children,
             * it requires some children to exist before it process the
             * performance data             
             */
                          
            if ($("#client_display_root").children().length > 0) {  
                var that = this;
                
                setTimeout(function(){
                    that.__processRawData();
                    that.__mainpanel = that.__createTabPanel(options); 

                    var tabPanel = that.__mainpanel;
                    var tabs =  that.__createTabs();
                    tabPanel.add(tabs);
                }, 250);
            } else {
                var that = this;
                if (this.timer) {
                    clearTimeout(this.timer);
                }                          
                                                           
                this.timer = setTimeout(function(){
                    that.init(options, callback);
                }, 250);
            }
        } 
    }, {
        /**
         *
         */
        __instance: null,

        /**
         *
         * @returns {*}
         */
        getInstance: function() {
            var ret = null;

            if (profilerApi.ProfilerConsole.__instance == null) {
                ret = new profilerApi.ProfilerConsole();
            } else {
                ret = profilerApi.ProfilerConsole.__instance;
            }

            return ret;
        }
    });           
}
})();

// Code: C:\Users\Framework\.hudson\jobs\SFMDelivery_sfdc_dev\workspace\src\modules\com.servicemax.client.profiler\src\impl.js
/**
 * # Package #
 * This package provides the profiling features for the framework.
 *
 * @class com.servicemax.client.profiler.impl
 * @singleton
 * @author Boonchanh Oupaxay
 *
 * @copyright 2014 ServiceMax, Inc.
 */
;(function($){
    "use strict";

    var profilerImpl = SVMX.Package("com.servicemax.client.profiler.impl");

    /**
     * Profiler module activator class
     */         
    profilerImpl.Class("Module", com.servicemax.client.lib.api.ModuleActivator, {
        __constructor : function(){
            this.__base();
            this.__profiler = SVMX.getProfilingService();

            // register with the READY client event
            SVMX.getClient().bind("READY", this.__onClientReady, this);
            $("#client_display_root").ready(function(){
                console.log("ready");
            });
        },

        /**
         * Client ready handler
         * @private         
         */                 
        __onClientReady : function(){
            this.__init();
        },

        /**
         * Initailize the UI when the client is ready
         * @private         
         */                 
        __init: function() {
            //1) unbind the ready
            SVMX.getClient().unbind("READY", this.__onClientReady, this);

            //2) build the container
            var ui = SVMX.create("com.servicemax.client.profiler.api.ProfilerConsole");
            var config = {
                id: "profiler_panel",
                baseCls: "x-panel",
                title: "ServiceMax Profiler Console"
            };

            ui.init(config);
        },

        /**
         * Load the profiler api class and support methods
         */                 
        beforeInitialize : function(){
            com.servicemax.client.profiler.api.init();
        },
        initialize : function(){},
        afterInitialize : function(){}
    }, {});
    
    
})(jQuery);

