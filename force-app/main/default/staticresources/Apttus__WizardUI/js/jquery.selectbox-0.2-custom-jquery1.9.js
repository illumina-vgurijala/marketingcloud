/*!
 * jQuery Selectbox plugin 0.2
 *
 * Copyright 2011-2012, Dimitar Ivanov (http://www.bulgaria-web-developers.com/projects/javascript/selectbox/)
 * Licensed under the MIT (http://www.opensource.org/licenses/mit-license.php) license.
 * 
 * Date: Tue Jul 17 19:58:36 2012 +0300
 * Updated: Dec 09th 2013
 * 22nd Dec - Fixed focus selection issue
 * Requires jQuery 1.9
 */
(function($, undefined) {
    var PROP_NAME = 'selectbox',
            FALSE = false,
            TRUE = true;
    /**
     * Selectbox manager.
     * Use the singleton instance of this class, $.selectbox, to interact with the select box.
     * Settings for (groups of) select boxes are maintained in an instance object,
     * allowing multiple different settings on the same page
     */

    var typed_text = '';
    var startTime = new Date();
    var sbInterval = 0;

    function clock()
    {
        var startMsec = new Date();
        var elapsed = Math.abs(startMsec.getTime() - startTime.getTime());

        if (elapsed > 300)
            sbClearInterval();
    }

    function sbSetInterval() {
        if (!sbInterval) {
            sbInterval = setInterval(function() {
                clock()
            }, 300);
        }
    }

    function sbClearInterval() {
        clearInterval(sbInterval);
        typed_text = '';
        sbInterval = null;
    }

    $.expr[':'].containsExactly = function(obj, index, meta, stack) {
        return $(obj).text() === meta[3];
    };

    function Selectbox() {
        this._state = [];
        this._defaults = {// Global defaults for all the select box instances
            classHolder: "sbHolder",
            classHolderActive: "sbHolderActive",
            classHolderDisabled: "sbHolderDisabled",
            classOptionActive: "sbOptionActive",
            classSelector: "sbSelector",
            classOptions: "sbOptions",
            classGroup: "sbGroup",
            classSub: "sbSub",
            classDisabled: "sbDisabled",
            classToggleOpen: "sbToggleOpen",
            classToggle: "sbToggle",
            classFocus: "sbFocus",
            speed: 200,
            effect: "slide", // "slide" or "fade"  // "slide" hardcoded
            onChange: null, //Define a callback function when the selectbox is changed
            onOpen: null, //Define a callback function when the selectbox is open
            onClose: null //Define a callback function when the selectbox is closed
        };
    }

    $.extend(Selectbox.prototype, {
        /**
         * Is the first field in a jQuery collection open as a selectbox
         * 
         * @param {Object} target
         * @return {Boolean}
         */
        _isOpenSelectbox: function(target) {
            if (!target) {
                return FALSE;
            }
            var inst = this._getInst(target);
            return inst.isOpen;
        },
        /**
         * Is the first field in a jQuery collection disabled as a selectbox
         * 
         * @param {HTMLElement} target
         * @return {Boolean}
         */
        _isDisabledSelectbox: function(target) {
            if (!target) {
                return FALSE;
            }
            var inst = this._getInst(target);
            return inst.isDisabled;
        },
        /**
         * Attach the select box to a jQuery selection.
         * 
         * @param {HTMLElement} target
         * @param {Object} settings
         */
        _attachSelectbox: function(target, settings) {
            if (this._getInst(target)) {
                return FALSE;
            }
            var $target = $(target),
                    self = this,
                    inst = self._newInst($target),
                    sbHolder, sbSelector, sbToggle, sbOptions,
                    s = FALSE, optGroup = $target.find("optgroup"), opts = $target.find("option"), olen = opts.length;

            $target.attr("sb", inst.uid);

            $.extend(inst.settings, self._defaults, settings);
            self._state[inst.uid] = FALSE;
            $target.hide();

            function closeOthers() {
                var key, sel,
                        uid = this.prop("id").split("_")[1];
                for (key in self._state) {
                    if (key !== uid) {
                        if (self._state.hasOwnProperty(key)) {
                            sel = $("select[sb='" + key + "']")[0];
                            if (sel) {
                                self._closeSelectbox(sel);
                            }
                        }
                    }
                }
            }

            sbHolder = $("<div>", {
                "id": "sbHolder_" + inst.uid,
                "class": inst.settings.classHolder,
                "tabindex": $target.prop("tabindex"),
                "focus": function(e) {
                    //self._detectChangeVal();
                    $target.addClass('sb_active');
                }
            });

            if ($target.hasClass('errorInput'))
                sbHolder.addClass('errorInput');

            sbSelector = $("<a>", {
                "id": "sbSelector_" + inst.uid,
                "href": "#",
                "class": inst.settings.classSelector,
                "click": function(e) {
                    e.preventDefault();
                    closeOthers.apply($(this), []);
                    var uid = $(this).prop("id").split("_")[1];
                    if (self._state[uid]) {
                        self._closeSelectbox(target);
                    } else {
                        self._openSelectbox(target);
                    }
                }
            });

            sbToggle = $("<a>", {
                "id": "sbToggle_" + inst.uid,
                "href": "#",
                "class": inst.settings.classToggle,
                "click": function(e) {
                    e.preventDefault();
                    closeOthers.apply($(this), []);
                    var uid = $(this).prop("id").split("_")[1];
                    $(this).focus();
                    if (self._state[uid]) {
                        self._closeSelectbox(target);
                    } else {
                        self._openSelectbox(target);
                    }
                }
            });
            sbToggle.appendTo(sbHolder);

            sbOptions = $("<ul>", {
                "id": "sbOptions_" + inst.uid,
                "class": inst.settings.classOptions,
                "css": {
                    "display": "none"
                }
            });

            $target.change(function() {
                $(this).next().find('.sbSelector').text($(this).find('option:selected').text());
            });

            var disabled = false;
            var li_html = '';

            var options_array = new Array();

            $target.find("option").each(function(i) {
                var li = $("<li>");
                var that = $(this), child;
                var classNames = that.prop('class') ? that.prop('class') : '';
                var text = that.text();
                text = text.replace(/ +(?= )/g, '');
                text = $.trim(text);
                that.text(text);
                if (!that.is(":disabled") && !disabled) {
                    child = $("<a>", {
                        "href": "#" + that.val(),
                        "rel": that.val()
                    }).text(text).addClass(classNames);
                } else {
                    child = $("<span>", {
                        "text": text
                    }).addClass(inst.settings.classDisabled).addClass(classNames);
                }

                child.appendTo(li);
                li_html += '<li class="' + classNames + '">' + li.html() + '</li>';

            });

            $(li_html).appendTo(sbOptions);

            $target.find("option:selected").filter(':selected').each(function() {
                sbSelector.text($(this).text());
                s = TRUE;
                //			child.addClass(inst.settings.classFocus);


            });

            if (!s)
                sbSelector.text(opts.first().text());

            sbOptions.find('li a').each(function(ind, ele) {
                if ($(ele).text() == sbSelector.text()) {
                    $(ele).addClass(inst.settings.classOptionActive);
                    return false;
                }
            });

            sbSelector.attr('title', sbSelector.text());
            //    sbSelector.addClass('tooltip');


            function getOptions() {
                return;
                var sub = arguments[1] && arguments[1].sub ? true : false,
                        disabled = arguments[1] && arguments[1].disabled ? true : false;
                arguments[0].each(function(i) {
                    var that = $(this),
                            li = $("<li>"),
                            child;
                    if (that.is(":selected")) {
                        sbSelector.text(that.text());
                        s = TRUE;
                    }
                    if (i === olen - 1) {
                        li.addClass("last");
                    }
                    if (!that.is(":disabled") && !disabled) {
                        child = $("<a>", {
                            "href": "#" + that.val(),
                            "rel": that.val()
                        }).text(that.text());
                        if (sub) {
                            child.addClass(inst.settings.classSub);
                        }
                        if (that.is(":selected")) {
                            child.addClass(inst.settings.classFocus);
                        }
                        child.appendTo(li);
                    } else {
                        child = $("<span>", {
                            "text": that.text()
                        }).addClass(inst.settings.classDisabled);
                        if (sub) {
                            child.addClass(inst.settings.classSub);
                        }
                        child.appendTo(li);
                    }
                    li.appendTo(sbOptions);
                });
            }


            $.data(target, PROP_NAME, inst);

            sbHolder.data("uid", inst.uid).bind("keydown.sb", function(e) {
                sbSetInterval();
                var key = e.charCode ? e.charCode : e.keyCode ? e.keyCode : 0,
                        $this = $(this),
                        uid = $this.data("uid"),
                        trgt = $this.siblings(["select[sb='", uid, "']"].join("")).get(0),
                        inst = $.data(trgt, PROP_NAME),
                        $f = $this.find("li").find("a." + inst.settings.classFocus);
                var f_ind = $("li a", $this).index($f);

                var myOptions = new Array();
                var myOptionsSub = new Array();

                $("li a", $this).each(function() {
                    myOptions.push($(this).text());
                    //myOptionsSub.push(($.trim($(this).text()).substring(0,1)).toLowerCase());
                    myOptionsSub.push($(this).text().toLowerCase());
                });

                if ((key >= 65 && key <= 90) || (key >= 48 && key <= 57) || key == 32) {
                    //	var myOptionsSub_ind = $.inArray(String.fromCharCode(key).toLowerCase(), myOptionsSub);
                    if(key == 32 && !typed_text)
                         self._openSelectbox(trgt);
  
                    typed_text += String.fromCharCode(key).toLowerCase();
                    startTime = new Date();

                    for (var i = 0; i < myOptionsSub.length; i++) {

                        if (myOptionsSub[i].indexOf(typed_text) == 0) {
                            var myOptionsSub_ind = i;
                            break;
                        }
                        else
                            var myOptionsSub_ind = -1;
                    }

                    if (myOptionsSub_ind > -1) {

                        if (f_ind >= myOptionsSub_ind && 0)
                        {
                            while (f_ind > myOptionsSub_ind)
                                var myOptionsSub_ind_new = myOptionsSub_ind++;
                            var myOptionsSub_ind2 = $.inArray(String.fromCharCode(key).toLowerCase(), myOptionsSub, myOptionsSub_ind + 1);
                            if (myOptionsSub_ind2 == -1)
                                myOptionsSub_ind2 = $.inArray(String.fromCharCode(key).toLowerCase(), myOptionsSub, 0);
                            if (myOptionsSub_ind2 > -1) {
                                $("a", $this).removeClass(inst.settings.classFocus);
                                $("li a", $this).eq(myOptionsSub_ind2).addClass(inst.settings.classFocus).focus();
                                $("#sbSelector_" + uid).text(myOptions[myOptionsSub_ind2]);
                            }
                        }
                        else {
                            $("a", $this).removeClass(inst.settings.classFocus);
                            $("li a", $this).eq(myOptionsSub_ind).addClass(inst.settings.classFocus).focus();
                            $("#sbSelector_" + uid).text(myOptions[myOptionsSub_ind]);
                        }
                    }
                }
                else {
                    switch (key) {

                        case 37: //Arrow Left
                        case 38: //Arrow Up
                        if(!self._state[uid])
                             self._openSelectbox(trgt);
                            if ($f.length > 0) {
                                var $next;
                                $("a", $this).removeClass(inst.settings.classFocus);
                                $next = $f.parent().prevAll("li:has(a)").eq(0).find("a");
                                if ($next.length > 0) {
                                    $next.addClass(inst.settings.classFocus).focus();
                                    $("#sbSelector_" + uid).text($next.text());
                                    //   self._changeSelectbox(trgt, $next.prop("rel"), $next.text());
                                    //    self._closeSelectbox(trgt);
                                }
                            }
                            break;
                        case 39: //Arrow Right
                        case 40: //Arrow Down
                    if(!self._state[uid])
                             self._openSelectbox(trgt);
                            var $next;
                            $("a", $this).removeClass(inst.settings.classFocus);
                            if ($f.length > 0) {
                                $next = $f.parent().nextAll("li:has(a)").eq(0).find("a");
                            } else {
                                $next = $this.find("ul").find("a").eq(0);
                            }
                            if ($next.length > 0) {
                                $next.addClass(inst.settings.classFocus).focus();
                                $("#sbSelector_" + uid).text($next.text());
                                //    self._changeSelectbox(trgt, $next.prop("rel"), $next.text());
                                //    self._closeSelectbox(trgt);
                            }
                            break;
                        case 13: //Enter
                            if ($f.length > 0) {
                                self._changeSelectbox(trgt, $f.prop("rel"), $f.text());
                            }
                            self._closeSelectbox(trgt);
                            break;
                        case 9: //Tab
                            if (trgt) {
                                var inst = self._getInst(trgt);
                                if (inst/* && inst.isOpen*/) {
                                    if ($f.length > 0) {
                                        self._changeSelectbox(trgt, $f.prop("rel"), $f.text());
                                    }
                                    //    self._detectChangeVal();
                                    self._closeSelectbox(trgt);
                                }
                            }
                            
                             var i = parseInt($this.attr("tabindex"), 10);
                            if (!e.shiftKey) {
                                i++;
                                while(!$("*[tabindex='" + i + "']").is(':tabbable') && i<1000)
                                    i++;
                            } else {
                                i--;
                                while(!$("*[tabindex='" + i + "']").is(':tabbable') && i>0)
                                    i--;
                            }


                            setTimeout(function() {
                            if(i>0) {
                            if( $("*[tabindex='" + i + "']").is(':radio')) {
                          if($("*[tabindex='" + i + "']:checked").length)
                            $("*[tabindex='" + i + "']:checked").focus();
                            else
                            $("*[tabindex='" + i + "']").eq(0).focus();
                            }
                            else
                                $("*[tabindex='" + i + "']").focus().select();
                                
                                }
                            }, 0);

                            break;
                        case 27: //Escape
                            self._closeSelectbox(trgt);
                            break;
                    }
                }
                e.stopPropagation();
                return false;
            });
            $(document).on("mouseover", "." + inst.settings.classHolder + " li a", function(e) {
              //  $(this).closest('.' + inst.settings.classHolder).find('ul .' + inst.settings.classFocus).removeClass(inst.settings.classFocus);
                //$(this).addClass(inst.settings.classFocus).focus();
            }).on("mouseout", "." + inst.settings.classHolder + " li a", function(e) {
                $(this).removeClass(inst.settings.classFocus);
            }).off("click", "." + inst.settings.classHolder + " li a").on("click", "." + inst.settings.classHolder + " li a", function(e) {
                if (e && e.preventDefault) {
                    e.preventDefault();
                }
                /*var t = sbToggle,
                 $this = $(this),
                 uid = t.prop("id").split("_")[1];*/
                var $this = $(this),
                        t = $this.closest('.' + inst.settings.classHolder).find("." + inst.settings.classToggle),
                        uid = t.prop("id").split("_")[1],
                        trgt = t.parent('.' + inst.settings.classHolder).siblings(["select[sb='", uid, "']"].join("")).get(0);
                //self._changeSelectbox(target, $this.prop("rel"), $this.text());
                //self._closeSelectbox(target);
                
                 $(this).closest('.' + inst.settings.classHolder).find('ul .' + inst.settings.classFocus).removeClass(inst.settings.classFocus);
                 $(this).addClass(inst.settings.classFocus).focus();
                
                self._changeSelectbox(trgt, $this.prop("rel"), $this.text());
                self._closeSelectbox(trgt);
            });

            sbSelector.appendTo(sbHolder);
            sbOptions.appendTo(sbHolder);
            sbHolder.insertAfter($target);

            $(document).mouseup(function(e) {
                var container = $("." + inst.settings.classHolder);
                if (!container.is(e.target) && container.has(e.target).length === 0) {
                    self._detectChangeVal();
                    $("select").selectbox('close');
                }
            });

            $([".", inst.settings.classHolder, ", .", inst.settings.classSelector].join("")).mousedown(function(e) {
                e.stopPropagation();
            });
        },
        /**
         * Remove the selectbox functionality completely. This will return the element back to its pre-init state.
         * 
         * @param {HTMLElement} target
         */
        _detachSelectbox: function(target) {
            var inst = this._getInst(target);
            if (!inst) {
                return FALSE;
            }
            $("#sbHolder_" + inst.uid).remove();
            $.data(target, PROP_NAME, null);
            $(target).show();
        },
        /**
         * Refresh the selectbox.
         * 
         * @param {HTMLElement} target
         */
        _refreshSelectbox: function(target) {
            var inst = this._getInst(target);
            if (!inst) {
                return FALSE;
            }
            var self = this;
            self._detachSelectbox(target);
            self._attachSelectbox(target, inst.settings);
        },
        
        _refreshTabIndexSelectbox: function(target) {
            var inst = this._getInst(target);
            if (!inst) {
                return FALSE;
            }
            var self = this;
            if ($(target).attr('tabindex'))
                $(target).next().attr('tabindex', $(target).attr('tabindex'));
        },
    
        /**
         * Change selected attribute of the selectbox.
         * 
         * @param {HTMLElement} target
         * @param {String} value
         * @param {String} text
         */
        _changeSelectbox: function(target, value, text) {
            var onChange,
                    inst = this._getInst(target);
            $("#sbOptions_" + inst.uid).find('li a.' + inst.settings.classOptionActive).removeClass(inst.settings.classOptionActive);
            if (inst) {
                onChange = this._get(inst, 'onChange');
                $("#sbSelector_" + inst.uid).text(text);
                $("#sbSelector_" + inst.uid).prop('title', text);
                //   $("#sbOptions_" + inst.uid).find('li a:containsExactly('+text+')').addClass(inst.settings.classOptionActive);
                $('#sbHolder_' + inst.uid).focus();
                $("#sbOptions_" + inst.uid).find('li a').each(function(ind, ele) {
                    if ($(ele).text() == text) {
                        $(ele).addClass(inst.settings.classOptionActive);
                         return false;
                     }
                });
            }
            //  value = value.replace(/\'/g, "\\'");
            if ($.trim(value) == $.trim($(target).find("option:selected").val()) && $.trim(text) == $.trim($(target).find("option:selected").text()))
                return;
            $(target).find('option').each(function(ind, ele) {
                if ($.trim($(ele).val()) == $.trim(value) && $.trim($(ele).text()) == $.trim(text)) {
                    $(ele).prop('selected', true);
                    return false;
                }
            });
            $(target).change();
            return;
            $(target).find("option[value='" + value + "']").prop("selected", true);
            if (inst && onChange) {
                onChange.apply((inst.input ? inst.input[0] : null), [value, inst]);
                inst.input.trigger('change');
            } else if (inst && inst.input) {
                inst.input.trigger('change');
            }
        },
        _detectChangeVal: function() {
            var self = this;
            $("select.sb_active").each(function() {
                if ($(this).next().find('li a.sbFocus').length)
                    self._changeSelectbox($(this).get(0), $(this).next().find('li a.sbFocus').prop("rel"), $(this).next().find('li a.sbFocus').text());
                //  $(this).removeClass('sb_active');
            });
        },
        /**
         * Enable the selectbox.
         * 
         * @param {HTMLElement} target
         */
        _enableSelectbox: function(target) {
            var inst = this._getInst(target);
            if (!inst || !inst.isDisabled) {
                return FALSE;
            }
            $("#sbHolder_" + inst.uid).removeClass(inst.settings.classHolderDisabled);
            inst.isDisabled = FALSE;
            $.data(target, PROP_NAME, inst);
        },
        /**
         * Disable the selectbox.
         * 
         * @param {HTMLElement} target
         */
        _disableSelectbox: function(target) {
            var inst = this._getInst(target);
            if (!inst || inst.isDisabled) {
                return FALSE;
            }
            $("#sbHolder_" + inst.uid).addClass(inst.settings.classHolderDisabled);
            inst.isDisabled = TRUE;
            $.data(target, PROP_NAME, inst);
        },
        /**
         * Get or set any selectbox option. If no value is specified, will act as a getter.
         * 
         * @param {HTMLElement} target
         * @param {String} name
         * @param {Object} value
         */
        _optionSelectbox: function(target, name, value) {
            var inst = this._getInst(target);
            if (!inst) {
                return FALSE;
            }
            //TODO check name
            inst[name] = value;
            $.data(target, PROP_NAME, inst);
        },
        /**
         * Call up attached selectbox
         * 
         * @param {HTMLElement} target
         */
        _openSelectbox: function(target) {
            var inst = this._getInst(target), self = this;
            //if (!inst || this._state[inst.uid] || inst.isDisabled) {
            if (!inst || inst.isOpen || inst.isDisabled) {
                return;
            }
            //    self._detectChangeVal();
            var el = $("#sbOptions_" + inst.uid);
            el.stop(true, true);
            var viewportHeight = parseInt($(window).height(), 10),
                    offset = $("#sbHolder_" + inst.uid).offset(),
                    scrollTop = $(window).scrollTop(),
                    height = el.prev().height(),
                    diff = viewportHeight - (offset.top - scrollTop) - height / 2,
                    maxHeight = (diff - height);
            onOpen = this._get(inst, 'onOpen');

            if (maxHeight < 150 && (height > 150 || height + 5 > maxHeight)) {
                if (el.height() < 200)
                    var top = -el.height();
                else
                    var top = -200;
                maxHeight = 200;
                height = 0;
            }
            else {
                var top = height;
            }

            el.css({
                "maxHeight": maxHeight + "px",
                "top": height + "px"
            });
            //    inst.settings.effect === "fade" ? el.fadeIn(inst.settings.speed) : el.slideDown(inst.settings.speed);

            el.animate({
                height: 'toggle',
                top: top + "px"
            }, inst.settings.speed);

            $("#sbToggle_" + inst.uid).addClass(inst.settings.classToggleOpen);
            $("#sbHolder_" + inst.uid).addClass(inst.settings.classHolderActive).focus();
            this._state[inst.uid] = TRUE;
            inst.isOpen = TRUE;
            if (onOpen) {
                onOpen.apply((inst.input ? inst.input[0] : null), [inst]);
            }
            $.data(target, PROP_NAME, inst);
            //  $(target).addClass('sb_active');

        },
        /**
         * Close opened selectbox
         * 
         * @param {HTMLElement} target
         */
        _closeSelectbox: function(target) {
            var inst = this._getInst(target), self = this;
            //if (!inst || !this._state[inst.uid]) {
            if (!inst || !inst.isOpen) {
                return;
            }
            var onClose = this._get(inst, 'onClose');
            //   inst.settings.effect === "fade" ? $("#sbOptions_" + inst.uid).fadeOut(inst.settings.speed) : $("#sbOptions_" + inst.uid).slideUp(inst.settings.speed);
            $("#sbOptions_" + inst.uid).stop(true, true);

            var top = parseInt($("#sbOptions_" + inst.uid).css('top'), 10);
            if (top > 0)
                top = $("#sbOptions_" + inst.uid).prev().height() + 'px';
            else
                top = '0px';

            $("#sbOptions_" + inst.uid).animate({
                height: 'toggle',
                top: top
            }, inst.settings.speed);

            self._detectChangeVal();

            $("#sbToggle_" + inst.uid).removeClass(inst.settings.classToggleOpen);
            $("#sbHolder_" + inst.uid).removeClass(inst.settings.classHolderActive);
            this._state[inst.uid] = FALSE;
            inst.isOpen = FALSE;
            if (onClose) {
                onClose.apply((inst.input ? inst.input[0] : null), [inst]);
            }
            $.data(target, PROP_NAME, inst);

        },
        /**
         * Create a new instance object
         * 
         * @param {HTMLElement} target
         * @return {Object}
         */
        _newInst: function(target) {
            var id = target[0].id.replace(/([^A-Za-z0-9_-])/g, '\\\\$1');
            return {
                id: id,
                input: target,
                uid: Math.floor(Math.random() * 99999999),
                isOpen: FALSE,
                isDisabled: FALSE,
                settings: {}
            };
        },
        /**
         * Retrieve the instance data for the target control.
         * 
         * @param {HTMLElement} target
         * @return {Object} - the associated instance data
         * @throws error if a jQuery problem getting data
         */
        _getInst: function(target) {
            try {
                return $.data(target, PROP_NAME);
            }
            catch (err) {
                throw 'Missing instance data for this selectbox';
            }
        },
        /**
         * Get a setting value, defaulting if necessary
         * 
         * @param {Object} inst
         * @param {String} name
         * @return {Mixed}
         */
        _get: function(inst, name) {
            return inst.settings[name] !== undefined ? inst.settings[name] : this._defaults[name];
        }
    });

    /**
     * Invoke the selectbox functionality.
     * 
     * @param {Object|String} options
     * @return {Object}
     */
    $.fn.selectbox = function(options) {

        var otherArgs = Array.prototype.slice.call(arguments, 1);
        if (typeof options == 'string' && options == 'isDisabled') {
            return $.selectbox['_' + options + 'Selectbox'].apply($.selectbox, [this[0]].concat(otherArgs));
        }

        if (options == 'option' && arguments.length == 2 && typeof arguments[1] == 'string') {
            return $.selectbox['_' + options + 'Selectbox'].apply($.selectbox, [this[0]].concat(otherArgs));
        }

        return this.each(function() {
            typeof options == 'string' ?
                    $.selectbox['_' + options + 'Selectbox'].apply($.selectbox, [this].concat(otherArgs)) :
                    $.selectbox._attachSelectbox(this, options);
            if ($(this).prop('disabled'))
                $.selectbox._disableSelectbox(this);
        });
    };

    $.selectbox = new Selectbox(); // singleton instance
    $.selectbox.version = "0.2";
})(jQuery);