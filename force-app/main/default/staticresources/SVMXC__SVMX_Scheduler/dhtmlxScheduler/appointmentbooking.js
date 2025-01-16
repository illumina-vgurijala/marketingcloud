
    var settingsPop;
    var settingsForm;
    var cancelPop;
    var cancelForm;
    var escalatePop;
    var escalateForm;
    var settings_noOfWeeks = 1;
    var settings_hideweekends = "yes";
    var settings_weekstartday = "monday";

    //Method to show pop ups on button click.
    function show_pops(button_element) {
        var x = window.dhx4.absLeft(button_element);
        var y = window.dhx4.absTop(button_element);
        var width = button_element.offsetWidth;
        var height = button_element.offsetHeight;
        if(button_element.value == "Calendar Settings") {
            settingsPop.show(x,y,width,height);
        }
        if(button_element.value == "Cancel Appointment") {
            cancelPop.show(x,y,width,height);
        }
        if(button_element.value == "{!TAG024}") {
            escalatePop.show(x,y,width,height);
        }
        return false;
    }

    //Function to initialize the popups used in the page.
    function popup_init(){

        settingsPop = new dhtmlXPopup();
        cancelPop = new dhtmlXPopup();
        escalatePop = new dhtmlXPopup();

        settingsPop.setSkin("dhx_terrace");
        cancelPop.setSkin("dhx_terrace");
        escalatePop.setSkin("dhx_terrace");

        settingsForm = settingsPop.attachForm([
            {type: "settings", position: "label-left", labelWidth: 110, inputWidth: 130},
            {type: "label", label: "Calender View Options", offsetLeft: 100},
            {type: "select", label: "Show",name: "noOfWeek", className: "settings_label", options:[
                {value: "1", text: "This Week Only"},
                {value: "2", text: "This Week and Next Week"},
                {value: "3", text: "This Week and Next 2 Weeks"}
            ]},
            {type: "label", label: "Hide Weekends", list:[
                {type: "radio", name: "hide_weekend", value: "yes", label:"Yes",checked:true},
                {type: "radio", name: "hide_weekend", value: "no", label:"No",list:[
                    {type: "label", label: "Weeks Begins on", list:[
                        {type: "radio", name: "weekstartday", value: "sunday", label:"Sunday"},
                        {type: "radio", name: "weekstartday", value: "monday", label:"Monday",checked:true}]}
                ]}
            ]},
            {type: "button", value: "Ok", offsetLeft: 149}
        ]);

        escalateForm = escalatePop.attachForm([
            {type: "settings", position: "label-left"},
            {type: "label", label: "Escalate Appointment", offsetLeft: 60},
            {type: "label", label: "The appointment will be placed in the <br/>escalation queue for manual scheduling."},
            {type: "block", width: 250, list:[
                {type: "button",name: "cancel", value: "Cancel"},
                {type:"newcolumn"},
                {type: "button",name: "escalate", value: "Escalate",offsetLeft: 20}
            ]}
        ]);

        settingsForm.attachEvent("onButtonClick", function(){

            settings_noOfWeeks = parseInt(settingsForm.getItemValue("noOfWeek"));
            settings_hideweekends = settingsForm.getItemValue("hide_weekend");
            settings_weekstartday = settingsForm.getItemValue("weekstartday");
            settingsPop.hide();
            reset_init_settings();
        });

        escalateForm.attachEvent("onButtonClick", function(name){

           if(name == "cancel") {
               escalatePop.hide();
           }

           if(name == "escalate") {
               escalateAppointment();
           }
        });

        cancelForm = cancelPop.attachForm([
            {type: "settings", position: "label-left"},
            {type: "label", label: "Cancel Appointment", offsetLeft: 120},
            {type: "label", label: "Booked Time Slot : {!bookedTimings}"},
            {type: "label", label: "Technician : {!bookedTechnician}"},
            {type: "block", width: 350, list:[
                {type: "button",name: "keep", value: "Keep Appointment"},
                {type:"newcolumn"},
                {type: "button",name: "cancel", value: "Cancel Appointment",offsetLeft: 20}
            ]}
        ]);

        cancelForm.attachEvent("onButtonClick", function(name){
           if(name == "keep") {
               cancelPop.hide();
           }
           if(name == "cancel") {
               cancelAppointment();
           }
        });
    }

    function scheduler_init() {
        scheduler.config.multi_day = true;
        scheduler.config.xml_date="%Y-%m-%d %H:%i";
        scheduler.config.wide_form = false;
        scheduler.attachEvent("onBeforeDrag",function(){return false;})
        scheduler.attachEvent("onClick",function(){return false;})
        scheduler.config.details_on_dblclick = true;
        scheduler.config.dblclick_create = false;
        scheduler.attachEvent("onClick",function(id,e){
          scheduler._on_dbl_click(e);
          return false;
        });

        scheduler.locale.labels.section_template = '';
        scheduler.locale.labels.grid_tab = 'List';
        scheduler.locale.labels.workweek_tab = 'Calendar';
        scheduler.locale.labels.section_checkme = "Ok to arrive early!";
        scheduler.config.lightbox.sections = [
            { name:"template", height:100, map_to:"message", type:"template"},
            { name:"checkme", map_to:"single_checkbox", type:"checkbox", checked_value: "registrable", height:30}
        ];

        scheduler.config.buttons_left = ["dhx_cancel_btn"];
        scheduler.config.buttons_right = ["book_button"];
        scheduler.locale.labels["book_button"] = "Book";
        scheduler.attachEvent("onLightboxButton", function(button_id, node, e){
            if(button_id == "book_button"){
                bookAppointment(scheduler.getState().lightbox_id);
                scheduler.endLightbox(false,scheduler.getLightbox());
            }
        });

        scheduler.config.first_hour = {!minEventStartTime};
        scheduler.config.last_hour = {!maxEventEndTime };
        document.getElementById("scheduler_here").style.height = ((({!maxEventEndTime } - {!minEventStartTime})*44)+100)+'px';
        scheduler.templates.lightbox_header = function(start,end,ev){

            return "{!TAG010}";
        };
        reset_init_settings();
    }

    function reset_init_settings(){

        if(settings_hideweekends == "yes") {
            scheduler.ignore_workweek = function(date){
                if (date.getDay() == 0 || date.getDay() == 6)
                    return true;
            };
        } else {
            scheduler.ignore_workweek = function(date){
                return false;
            };
        }

        if(settings_weekstartday == "monday") {
            scheduler.config.start_on_monday = true;
        } else {
            scheduler.config.start_on_monday = false;
        }

        scheduler.init("scheduler_here",new Date("{!calendarStartDate}"),"workweek");
        scheduler.parse({!eventsJson}, "json");
    }

    scheduler.attachEvent("onTemplatesReady",function(){

        scheduler.date.workweek_start = scheduler.date.week_start;
        //scheduler.date.workweek_start = function(date){
        //    return this.date_part(this.add(date,0,"day"));
        //};
        scheduler.date.get_workweek_end=function(date){
            return scheduler.date.add(date,settings_noOfWeeks*7,"day");
        };
        scheduler.date.add_workweek=function(date,inc){
            return scheduler.date.add(date,inc*(settings_noOfWeeks*7),"day");
        };
        scheduler.templates.workweek_date = scheduler.templates.week_date;
       // scheduler.templates.workweek_scale_date = scheduler.date.date_to_str("%D, %d");
        var format = scheduler.date.date_to_str("%D, %d");
        var today = scheduler.date.date_part(new Date());
        scheduler.templates.workweek_scale_date = function(date){
            if(date.valueOf() == today.valueOf()) {
                 return "<div style='height:22px;background-color:#FFF3A1;'>"+format(date)+"</div>";
            }
            return format(date);
        }
    });

    scheduler.createGridView({
       name:"grid",
       fields:[    // defines columns of the grid
             {id:"id",   label:'Id',   sort:'int',  width:80,  align:'right'},
             {id:"date", label:'Date', sort:'date', width:'*'},
             {id:"text", label:'Text', sort:'str',  width:200, align:'left'}
       ]
    });

    function show_minical(){
        if (scheduler.isCalendarVisible())
            scheduler.destroyCalendar();
        else {
            scheduler.renderCalendar({
                position:"dhx_minical_icon",
                date:scheduler._date,
                navigation:true,
                handler:function(date,calendar){
                    scheduler.setCurrentView(date,scheduler._mode);
                    scheduler.destroyCalendar();
                }
             });

             //To hide the unneccessary disabled dates from min cal.
             var elements = document.getElementsByClassName("dhx_after");
             for (var index = 0;index < elements.length; index++){
                 elements[index].innerHTML = '';
             }
        }
    }