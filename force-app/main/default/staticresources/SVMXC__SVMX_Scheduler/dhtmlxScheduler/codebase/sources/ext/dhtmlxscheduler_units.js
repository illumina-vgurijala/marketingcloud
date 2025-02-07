/*
dhtmlxScheduler v.4.2.0 Professional

This software is covered by DHTMLX Enterprise License. Usage without proper license is prohibited.

(c) Dinamenta, UAB.
*/
Scheduler.plugin(function(scheduler){

scheduler._props = {};
scheduler.createUnitsView=function(name,property,list,size,step,skip_incorrect){
	if (typeof name == "object"){
		list = name.list;
		property = name.property;
		size = name.size||0;
		step = name.step||1;
		skip_incorrect = name.skip_incorrect;
		name = name.name;
	}

	scheduler._props[name]={map_to:property, options:list, step:step, position:0 };
    if(size>scheduler._props[name].options.length){
        scheduler._props[name]._original_size = size;
        size = 0;
    }
    scheduler._props[name].size = size;
	scheduler._props[name].skip_incorrect = skip_incorrect||false;

	scheduler.date[name+"_start"]= scheduler.date.day_start;
	scheduler.templates[name+"_date"] = function(date){
		return scheduler.templates.day_date(date);
	};

	scheduler._get_unit_index = function(unit_view, date) {
		var original_position = unit_view.position || 0;
		var date_position = Math.floor((scheduler._correct_shift(+date, 1) - +scheduler._min_date) / (60 * 60 * 24 * 1000));
		return original_position + date_position;
	};
	scheduler.templates[name + "_scale_text"] = function(id, label, option) {
		if (option.css) {
			return "<span class='" + option.css + "'>" + label + "</span>";
		} else {
			return label;
		}
	};
	scheduler.templates[name+"_scale_date"] = function(date) {
		var unit_view = scheduler._props[name];
		var list = unit_view.options;
		if (!list.length) return "";
		var index = scheduler._get_unit_index(unit_view, date);
		var option = list[index];
		return scheduler.templates[name + "_scale_text"](option.key, option.label, option);
	};

	scheduler.date["add_"+name]=function(date,inc){ return scheduler.date.add(date,inc,"day"); };
	scheduler.date["get_"+name+"_end"]=function(date){
		return scheduler.date.add(date,scheduler._props[name].size||scheduler._props[name].options.length,"day");
	};

	scheduler.attachEvent("onOptionsLoad",function(){
        var pr = scheduler._props[name];
		var order = pr.order = {};
		var list = pr.options;
		for(var i=0; i<list.length;i++)
			order[list[i].key]=i;
        if(pr._original_size && pr.size===0){
            pr.size = pr._original_size;
            delete pr.original_size;
        }
		if(pr.size > list.length) {
            pr._original_size = pr.size;
            pr.size = 0;
        }
        else
            pr.size = pr._original_size||pr.size;
		if (scheduler._date && scheduler._mode == name)
			scheduler.setCurrentView(scheduler._date, scheduler._mode);
	});

	scheduler["mouse_"+ name] = function(pos){ //mouse_coord handler
		var pr = scheduler._props[this._mode];

		if (pr){
			pos = this._week_indexes_from_pos(pos);
			if(!this._drag_event) this._drag_event = {};

			if (this._drag_id && this._drag_mode){
				this._drag_event._dhx_changed = true;
			}
			var unit_ind = Math.min(pos.x+pr.position,pr.options.length-1);
			pos.section = (pr.options[unit_ind]||{}).key;
			pos.x = 0;

			var ev = this.getEvent(this._drag_id);
			this._update_unit_section({view:pr, event:ev, pos:pos});
		}
		pos.force_redraw = true;

		return pos;
	};



	scheduler.callEvent("onOptionsLoad",[]);
};

scheduler._update_unit_section = function(action){
	var view = action.view,
		event = action.event,
		pos = action.pos;
	if(event) {
		event[view.map_to] = pos.section;
	}
};

scheduler.scrollUnit=function(step){
	var pr = scheduler._props[this._mode];
	if (pr){
		pr.position=Math.min(Math.max(0,pr.position+step),pr.options.length-pr.size);
		this.setCurrentView();
	}
};
(function(){
	var _removeIncorrectEvents = function(evs) {
		var pr = scheduler._props[scheduler._mode];
		if(pr && pr.order && pr.skip_incorrect) {
            var correct_events = [];
			for(var i=0; i<evs.length; i++) {
				if(typeof pr.order[evs[i][pr.map_to]] != "undefined") {
                    correct_events.push(evs[i]);
				}
			}
            evs.splice(0,evs.length);
			evs.push.apply(evs,correct_events);
		}
		return evs;
	};
	var old_pre_render_events_table = scheduler._pre_render_events_table;
	scheduler._pre_render_events_table=function(evs,hold) {
		evs = _removeIncorrectEvents(evs);
		return old_pre_render_events_table.apply(this, [evs, hold]);
	};
	var old_pre_render_events_line = scheduler._pre_render_events_line;
	scheduler._pre_render_events_line = function(evs,hold){
		evs = _removeIncorrectEvents(evs);
		return old_pre_render_events_line.apply(this, [evs, hold]);
	};
	var fix_und=function(pr,ev){
		if (pr && typeof pr.order[ev[pr.map_to]] == "undefined"){
			var s = scheduler;
			var dx = 24*60*60*1000;
			var ind = Math.floor((ev.end_date - s._min_date)/dx);
			//ev.end_date = new Date(s.date.time_part(ev.end_date)*1000+s._min_date.valueOf());
			//ev.start_date = new Date(s.date.time_part(ev.start_date)*1000+s._min_date.valueOf());
			ev[pr.map_to] = pr.options[Math.min(ind+pr.position,pr.options.length-1)].key;
			return true;
		}
	};
	var t = scheduler._reset_scale;

	var oldive = scheduler.is_visible_events;
	scheduler.is_visible_events = function(e){
		var res = oldive.apply(this,arguments);
		if (res){
			var pr = scheduler._props[this._mode];
			if (pr && pr.size){
				var val = pr.order[e[pr.map_to]];
				if (val < pr.position || val >= pr.size+pr.position )
					return false;
			}
		}
		return res;
	};
	scheduler._reset_scale = function(){
		var pr = scheduler._props[this._mode];
		var ret = t.apply(this,arguments);
		if (pr){
			this._max_date=this.date.add(this._min_date,1,"day");

				var d = this._els["dhx_cal_data"][0].childNodes;
				for (var i=0; i < d.length; i++)
					d[i].className = d[i].className.replace("_now",""); //clear now class

			if (pr.size && pr.size < pr.options.length){

				var h = this._els["dhx_cal_header"][0];
				var arrow = document.createElement("DIV");
				if (pr.position){
					arrow.className = "dhx_cal_prev_button";
					arrow.style.cssText="left:1px;top:2px;position:absolute;";
					arrow.innerHTML = "&nbsp;";
					h.firstChild.appendChild(arrow);
					arrow.onclick=function(){
						scheduler.scrollUnit(pr.step*-1);
					};
				}
				if (pr.position+pr.size<pr.options.length){
					arrow = document.createElement("DIV");
					arrow.className = "dhx_cal_next_button";
					arrow.style.cssText="left:auto; right:0px;top:2px;position:absolute;";
					arrow.innerHTML = "&nbsp;";
					h.lastChild.appendChild(arrow);
					arrow.onclick=function(){
						scheduler.scrollUnit(pr.step);
					};
				}
			}
		}
		return ret;

	};
	var r = scheduler._get_event_sday;
	scheduler._get_event_sday=function(ev){
		var pr = scheduler._props[this._mode];
		if (pr){
			fix_und(pr,ev);
			return this._get_section_sday(ev[pr.map_to]);
		}
		return r.call(this,ev);
	};
	scheduler._get_section_sday = function(section){
		var pr = scheduler._props[this._mode];
		return pr.order[section]-pr.position;
	};

	var l = scheduler.locate_holder_day;
	scheduler.locate_holder_day=function(a,b,ev){
		var pr = scheduler._props[this._mode];
		if (pr && ev) {
			fix_und(pr,ev);
			return pr.order[ev[pr.map_to]]*1+(b?1:0)-pr.position;
		}
		return l.apply(this,arguments);
	};

	var o = scheduler._time_order;
	scheduler._time_order = function(evs){
		var pr = scheduler._props[this._mode];
		if (pr){
			evs.sort(function(a,b){
				return pr.order[a[pr.map_to]]>pr.order[b[pr.map_to]]?1:-1;
			});
		} else
			o.apply(this,arguments);
	};
	scheduler.attachEvent("onEventAdded",function(id,ev){
		if (this._loading) return true;
		for (var a in scheduler._props){
			var pr = scheduler._props[a];
			if (typeof ev[pr.map_to] == "undefined")
				ev[pr.map_to] = pr.options[0].key;
		}
		return true;
	});
	scheduler.attachEvent("onEventCreated",function(id,n_ev){
		var pr = scheduler._props[this._mode];
		if (pr && n_ev){
			var ev = this.getEvent(id);
			var pos = this._mouse_coords(n_ev);
			this._update_unit_section({view:pr, event:ev, pos:pos});
			fix_und(pr,ev);
			this.event_updated(ev);
		}
		return true;
	});
})();


});
