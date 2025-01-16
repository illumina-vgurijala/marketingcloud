/**
 *  Apttus Config & Pricing
 *  aptBreadCrumb.js
 *   
 *  @2012-2013 Apttus Inc. All rights reserved.
 *
 * Licensed under the MIT license:
 * http://www.opensource.org/licenses/mit-license.php
 * 
 */
;(function($) {

    // Private variables 

    var breadCrumbContainer;
    var breadCrumbDiv; 
    //The reference object containing all of the breadcrumb elements
    var breadCrumbElements = [];
    var breadCrumb;    
    var breadCrumbsMap = {};   
    var breadCrumbTab;    
    var breadCrumbTree;
    var carrousel; 
    var _options;    
    var _rootCategories = [];
    var firstLoad = true;
    var rootMenu;
    var treeCommands;
    var hierarchy = [];
    var selectedReference;
    var selectedFromTree;    
    var selectedFromCarousel;
    var selectedFromRootMenu;


    // Public functions

    $.widget("APTTUS.aptBreadCrumb", {
 
        options: {  // Default settings            
            beginingElementsToLeaveOpen: 1,
            breadCrumbOptions: {
                easing: undefined,
                endElementsToLeaveOpen: 1,
                maxFinalElementLength: 400,
                minFinalElementLength: 200,
                minimumCompressionElements: 2,
                overlayClass: 'chevronOverlay',
                previewWidth: 40, 
                timeCompressionAnimation: 500,
                timeExpansionAnimation: 800,            
                timeInitialCollapse: 600
            },
            browseMenuContainer:'',
            carouselContainer:'',
            carouselOptions: {
                maxDepth: undefined,    
                noImagePlaceHolder: undefined            
            },
            disableBreadcrumb: false,
            disableRootMenu: false,
            disableCarouselView: false,
            disableTabView: false,
            displayIds : undefined,
            rootMenuContainer:'',            
            rootMenuOptions: {
                placeHolder:'Shop All Categories',
                maxDepth: 2 //Levels above reference object to display; the reference object is 
                            //typically the selected visible category in the carousel.                
            },
            selected:'', 
            tabContainer:'',                      
            treeContainer:'',
            treeOptions: {
                disableRefreshOnSelect: false,
                displayIds: undefined,
                hideRootCategory: false
            },
            expandAllLabel:'',
            collapseAllLabel:''
        },

        _create: function() {
            breadCrumbContainer = this.element;

            //this._update();          
        },

        _init: function( disableLoadAlert ) {        
            // Initialize options
            _options = this.options;
            // Initialize breadcrumbs map
            breadCrumbsMap = flatten(_options.breadCrumbs, 'nodeId', 'childList');            
            // Init roots map
            _rootCategories = this.roots();
            // Determine selected element
            var selected;
            if(this.options.selected) {
                selected = findDefaultSelection(breadCrumbsMap[this.options.selected].childList);
                if(!selected) {
                    selected = breadCrumbsMap[this.options.selected];
                } 
            } else {
                selected = (this.roots().length > 1 ? {childList: this.roots(), isRoot:true} : this.roots()[0]);
            }

            // Set navigation reference
            selectedReference = !this.options.disableCarouselView
                              ? getCarouselVisible(selected)
                              : selected;
            
            // Destroy existing navigation elements
            destroyBreadCrumb();
            if(!selectedFromTree || !selectedReference.parentId) {                
                destroyCarousel();            
                destroyRootMenu();
            }
            

            if(!this.options.treeOptions.disableRefreshOnSelect              // explicit refresh disable
                && (firstLoad                                                // first load, load everything
                    || !selectedFromTree                                    // not selected from tree and is root or root category
                    )) {
                destroyTree(); 
            }

            destroyTabs();
            
            // Load navigation elements
            if(!this.options.disableBreadcrumb) {
                loadBreadCrumbElements(selected);
                initialzeBreadCrumb();
            }

            var selectedHierarchy = getHierarchy(selected); 
            if(!selectedFromTree || !selectedReference.parentId || firstLoad) {

                // Load Carrousel
                if(!this.options.disableCarouselView) {
                    var possibleSelections = [];
                    for(var i=0; i < selectedHierarchy.length; i ++) {
                        possibleSelections[possibleSelections.length] = selectedHierarchy[i].nodeId;
                    }
                    
                    selectedReference = loadCarrousel(selectedReference, possibleSelections);
                    initializeCarousel();
                }


                // Load Root menu
                if(!this.options.disableRootMenu) {
                     loadRootMenu(selectedReference, this.options.disableCarouselView);
                    initializeRootMenu();
                }

            }

            // Load tree
            if(selectedHierarchy && selectedHierarchy.length) {             
                if(!this.options.treeOptions.disableRefreshOnSelect          // explicit refresh disable
                && (firstLoad                                                // first load, load everything
                    || !selectedFromTree                                    // not selected from tree and is root or root category
                    )) {

                    var treeNodes = {isRoot:true, childList: this.roots()};               
                    if(_options.treeOptions.hideRootCategory) { // For single category
                        if(this.roots().length == 1 
                        && this.roots()[0].childList.length) {
                            treeNodes.childList = this.roots()[0].childList;
                        }
                    } 

                    //browse menu gets initial tree on load
                    if(firstLoad && _options.browseMenuContainer != '') { 
                        loadTree(treeNodes);
                        initializeTree((selectedReference.leaf && selectedReference.parentId) ? selectedHierarchy[selectedHierarchy.length -2] : selectedReference,
                                        _options.browseMenuContainer, true);
                    }

                    loadTree(treeNodes);
                    initializeTree((selectedReference.leaf && selectedReference.parentId) ? selectedHierarchy[selectedHierarchy.length -2] : selectedReference,
                                    _options.treeContainer, false);
                }             
            }

            // Select item in tree
            var theId = selected.nodeId;
            if(selectedFromTree) {
                $('.treeContainer .jstree-clicked').removeClass('jstree-clicked');
                $('.treeContainer #' + theId + ' a').addClass('jstree-clicked');

            } else { //browse menu is selected from carousel                
                $('.jstree-clicked').removeClass('jstree-clicked');
                $('#' + theId + ' a').addClass('jstree-clicked'); 
                $('.treeContainer #' + theId + ' a').addClass('jstree-clicked');
            }

            // Load tabs view
            if(!this.options.disableTabView) {
                loadTabs(selected);
                initialzeTabs();                
            }
                        
            // Alert on load
            if(!disableLoadAlert) {
                this._alertOnLoad();                  
            }

            firstLoad = false;                       
        },

        _setOption: function( key, value ) {
            this.options[ key ] = value;            

            this._update(key, value);            
        },

        _update: function( key, value ) {    
            if(key === 'selected') {
                this._alertOnBeforeSelect();
                this._init(true);
                this._alertOnSelection();

                // reset flags
                selectedFromTree = undefined;
                selectedFromCarousel = undefined;
                selectedFromRootMenu = undefined;
            } else {                
                this._init(true);   
               
            }

            this._alertOnLoad();         
        },

        _alertOnSelection: function() {            
            var dataObj = { selectedId: _options.selected, 
                            isLeaf: this.isLeafSelected(), 
                            userSelect: selectedFromTree || selectedFromCarousel || selectedFromRootMenu,
                            selectedFromTree: selectedFromTree,
                            selectedFromCarousel: selectedFromCarousel,
                            selectedFromRootMenu: selectedFromRootMenu };

            if(this.isLeafSelected()) {
                this._trigger( "onLeafSelection", null,  dataObj);
            }

            this._trigger( "onSelection", null, dataObj );
        },

        _alertOnLoad: function() {            
            this._trigger( "onLoad", null, { selectedId: _options.selected, isLeaf: this.isLeafSelected() } );            
        },

        _alertOnBeforeSelect: function() {            
            this._trigger( "beforeSelect", null, { selectedId: _options.selected, isLeaf: this.isLeafSelected() } );            
        },
       
        isLeafSelected: function() {
            return breadCrumbsMap && 
                   breadCrumbsMap[_options.selected] && 
                   breadCrumbsMap[_options.selected].leaf; 
        },

        select: function( theId, treeSelection, carouselSelection, rootMenuSelection ) {
            // theId is null for expand and collapse tree commands
            if(theId != null) {
                selectedFromTree = treeSelection;
                selectedFromCarousel = carouselSelection;
                selectedFromRootMenu = rootMenuSelection;
                this._setOption("selected", theId);
                
            }
        },

        roots : function() {           
            var rootNodes = [];
        
            $.each(breadCrumbsMap, function(i, e) {
                if(!e.parentId) {
                    rootNodes.push(e);
                }
            });                        

            return rootNodes;
        },        

        destroy: function() {
            this.element
                .removeClass( "aptBreadCrumb" )
                .text( "" );
     
            // Call the base destroy function.
            $.Widget.prototype.destroy.call( this );
        }
    });

    // Private functions 

    function flatten(e, by, childKey) {                  
        var results = {};

        $.each($(e), function() {                      
            if(by) {
              if(this[by]) {
                results[this[by]] = this;
              }  
            } else {
                results[this] = this;
            }
            if(childKey) {
                // Flatten its children
                if(this[childKey] && this[childKey].length > 0) {
                    $.each(this[childKey], function() {               
                        results = $.extend({}, results, flatten(this, by, childKey));                  
                    });
                }
            }
            
        });

        return results;
    }

    function findDefaultSelection(elements) {
        var defaultSelection;   
        if(elements.length) {
            $.each(elements, function() {
                if(this.defaultSearchCategory) {
                    defaultSelection = this;
                    if(this.childList && this.childList.length) {
                        var defaultChildSelection = findDefaultSelection(this.childList);
                        if(defaultChildSelection) {
                            defaultSelection = defaultChildSelection;
                        }
                    }

                    return false;
                }
            });  
        }

        return defaultSelection;
    }    

    function isDisplayNode ( element ) {
        var isDisplayNode = true;

        if(_options.displayIds) {               
            isDisplayNode = element.isRoot || !element.nodeId; // for single top level category
            if(!isDisplayNode) {
              $.each(_options.displayIds,
                function() {
                    if(this == element.nodeId) {
                        isDisplayNode = true;
                        return false;
                    }
                });  
            }
        }

        return isDisplayNode;   

    }

    function isTreeDisplayNode ( element ) {
        var isTreeDisplayNode = true;

        if(_options.treeOptions.displayIds) {               
            isTreeDisplayNode = element.isRoot;
            if(!isTreeDisplayNode) {
              $.each(_options.treeOptions.displayIds,
                function() {
                    if(this == element.nodeId) {
                        isTreeDisplayNode = true;
                        return false;
                    }
                });  
            }
        }

        return isTreeDisplayNode;   

    }

    function getHierarchy ( element ) {
        var rootEl = element;                        
        var hierarchy = [];
        do {               
            hierarchy.unshift(rootEl);
            rootEl = breadCrumbsMap[rootEl.parentId];

        } while(rootEl);

        return hierarchy;
    }


    function getCarouselVisible( selectedBreadCrumb ) {

        // Get hierarchy chain
        var result = selectedBreadCrumb;
        var depth = getHierarchy(result);
        
        // Adjust for maximum depth allowable in carousel
        if(_options.carouselOptions.maxDepth >= 0) {
            if(_options.carouselOptions.maxDepth > 0 && 
               _options.carouselOptions.maxDepth <= depth.length) {
                // Reset to maximum allowable
                result = depth[_options.carouselOptions.maxDepth-1];                    
            } else if(_options.carouselOptions.maxDepth == 0)  { // Force root view
                result = {childList: _rootCategories, isRoot:true}; 
            } else {
                // Grab last entry
                result = depth[depth.length-1];
            }
        }
        
        return result;
    }

    function getRootFromSelected(element) {
        // Determine selected root
        var rootEl = element;        
        while(rootEl && rootEl.parentId) {
            rootEl = breadCrumbsMap[rootEl.parentId];
        }

        return rootEl;
    }

    function destroyRootMenu() {
        if(rootMenu !== undefined) {             
            $(rootMenu).remove();        
        }
        rootMenu = undefined;   
    }

    function loadRootMenu( visibleInCarousel, carouselDisabled, _rootMenu ) {
        var hierarchy = getHierarchy(visibleInCarousel);
        var menuNavItems = [];
        var maxNavItems = 0;
        var i = hierarchy.length -1;

        while(maxNavItems++ < _options.rootMenuOptions.maxDepth && i >= 0) {
            menuNavItems.unshift(hierarchy[i--]);
        }

        rootMenu = '<div class="navbar"><div class="navbar-inner"><div class="container"><ul class="nav">';        
        for(var i = 0; i < menuNavItems.length; i++ ) {                    
            var element = menuNavItems[i];            
            
            rootMenu+= '<li class="active dropdown">';

            if(isDisplayNode(element)) {
                rootMenu+= '<a class="dropdown-toggle" data-toggle="dropdown" href="#">' 
                if(element.isRoot) {
                    rootMenu+= _options.rootMenuOptions.placeHolder;
                } else  {
                    rootMenu+= element.label;
                }

                rootMenu+= '<span class="caret"/></a>';
            }
            
            rootMenu+= '<ul class="dropdown-menu" role="menu">';
            
            // Determine dropdown list
            var displayList;
            if(!element.parentId) {
                // If this is the root list, then add placeholder
                rootMenu+= '<li data-submenu-id="' + this.nodeId + '"><a href="#" objId="">' + _options.rootMenuOptions.placeHolder + '</a></li>';
                displayList = _rootCategories;
            } else {
                displayList = breadCrumbsMap[element.parentId].childList;
            }

            // Build dropdown menu
            $.each(displayList,
                function() {
                    if(isDisplayNode(this)) {
                        rootMenu+= '<li data-submenu-id="' + this.nodeId + '"><a href="#" objId="' + this.nodeId + '">' + this.label + '</a></li>';    
                    }                    
                }
            );

            rootMenu+= '</ul></li>';
                        
            // Add additional sub menu
            if( ( i+1 >= menuNavItems.length ) && // For last element
                element.childList && !element.leaf && !element.isRoot) { // If these conditions are satisfied
                rootMenu+= '<li class="active dropdown">';
                rootMenu+= '<a class="dropdown-toggle" data-toggle="dropdown" href="#">';
                if(element.leaf) {
                    rootMenu+= element.label;
                } else {
                    rootMenu+= '&nbsp;';
                }

                rootMenu+= '<span class="caret"/></a>';
                rootMenu+= '<ul class="dropdown-menu" role="menu">';

                $.each(element.childList,
                    function() {
                        if(isDisplayNode(this)) {
                            rootMenu+= '<li data-submenu-id="' + this.nodeId + '"><a href="#" objId="' + this.nodeId + '">' + this.label + '</a></li>';
                        }
                    }
                );

                rootMenu+= '</ul></li>';
            }

        }

        rootMenu+= '</ul></div></div></div>';      
        rootMenu = $(rootMenu);

        if(_options.rootMenuContainer) {
            $(_options.rootMenuContainer).append($(rootMenu));
        } else {
            $(breadCrumbContainer).append($(rootMenu));
        }
    }

    function initializeRootMenu() {
//        // Hook up events to be fired on menu row activation.
        var menu = $($(rootMenu).find('li > ul'));

        // Navigate on click of links
        menu.on('click', 'a', function(e) {
            var theId = $(this).attr('objId');
            breadCrumbContainer.aptBreadCrumb("select", theId, false, false, true);            
        });
    }

    function destroyTree() {
        if(breadCrumbTree !== undefined) {
            $(breadCrumbTree).jstree("destroy");   
            $(breadCrumbTree).remove();
        }

        if(treeCommands !== undefined) {
            $(treeCommands).remove();
        }

         breadCrumbTree = undefined; 
         treeCommands = undefined; 
    }

    function loadTree(element, parent, initially_open, initially_select) {
        if(!isDisplayNode(element) || !isTreeDisplayNode(element)) {
            return;
        }

        var initially_open = initially_open || ["root"];
        var initially_select = initially_select || [];
        var treeNode = {};
        treeNode.data = {};

        treeNode.data.title = !element.isRoot ? element.label : _options.rootMenuOptions.placeHolder;        
        treeNode.data.icon = element.imageUrl;
        treeNode.children = [];
        treeNode.state  = {
            selected:(element.nodeId && (element.nodeId == _options.selected.nodeId))
        };

        treeNode.attr = {
            "Id" : (!element.isRoot ? element.nodeId : 'root'),
            "hasImage" : (element.imageUrl ? true : false),   
            "isLeaf" : element.leaf,
            "isRoot" : (element.isRoot === true),
            "numChildren" : element.childList ? element.childList.length : 0
        };

        // expanded by default
        if(element.expanded) {
            initially_open.push(element.nodeId);
        }

        // make sure to expand selected node as well
        if(element.nodeId == _options.selected) {
            var selectedDefault = findDefaultSelection(breadCrumbsMap[_options.selected].childList);
            if(selectedDefault) {
                initially_select.push(selectedDefault.nodeId);
            } else {
                initially_select.push(element.nodeId);
            }
        }

        // if this is a child include in child list
        if(parent) {
            parent.children.push(treeNode);
        }

        // include context children
        if(element.childList.length) {
            $.each(element.childList,
                function() {
                    loadTree(this, treeNode, initially_open, initially_select);
                });            
        }

        breadCrumbTree = {             
            "json_data" : {
                "data" : [ treeNode ]              
            },
            "plugins" : [ "themes", "json_data", "ui" ],
            "core" : {"html_titles" : true, "initially_open": initially_open },
            "themes" : {
                "icons" : true,
                "dots" : false
            },
            "animation":0,
            "ui" : {
                "initially_select" : initially_select 
            }
        };
    }

    function initializeTree( element, container, isBrowseTree ) {
        if(breadCrumbTree !== undefined) {
           
            //var container = _options.treeContainer;
            var treeContainer;            
            if(!container) {
                $(breadCrumbContainer).append('<div/>');
                $(breadCrumbContainer).children('div')[0].append('<div/>');

                container = $(breadCrumbContainer).children('div')[0];
                treeContainer = $(breadCrumbContainer).children('div')[0].children('div')[0];
            } else {
                $(container).append('<div/>');
                treeContainer = $(container).children('div')[0];
            }

            if(!isBrowseTree) {
                $(treeContainer).addClass('treeContainer');
            }

            // Setup tree binded actions.
            var initiallySelected = breadCrumbTree.ui.initially_select.length > 0; //prevent double select on init
            breadCrumbTree = $(treeContainer).jstree(breadCrumbTree).bind("select_node.jstree", 
                function (e, data) {
                    var theId  = data.rslt.obj.attr("Id");     
                    var isLeaf = data.rslt.obj.attr("isleaf");     

                    if(initiallySelected) {
                        initiallySelected = false;
                        return;

                    }

                    if(isLeaf == 'false') {
                        $(this).jstree('toggle_node',$('#'+theId));
                        //this.toggle_node(e);
                    } else {         // includes root node       
                        breadCrumbContainer.aptBreadCrumb("select", theId == 'root' ? null : theId, !isBrowseTree, isBrowseTree, false);                                           
                    }                                              
                }
            ).bind('loaded.jstree',                 
                function(e, data) {       
                // var me = this;         
                //     $("[expanded='true']").each(
                //         function() {
                //             $(me).jstree('open_node', $(this).attr('Id'));
                //             alert('loaded');
                //             alert('#' + $(this).attr('Id'));
                //             $('#' + $(this).attr('Id')).find('.jstree-clicked').removeClass('jstree-clicked');
                //         }
                //     );
                    $("[hasImage='true']").addClass('hasImage');
                    $("[hasImage='false']").addClass('noImage');
                    $("[hasImage='false'][type='option']").addClass('noImage-product');
                    $("[hasImage='false'][type='optionGroup']").addClass('noImage-optiongroup');
                    //$(this).jstree('open_all');
                    // if(element){
                    //     if(!element.isRoot) {
                    //         $(this).jstree('open_node',$('#'+element.nodeId));
                    //     } else {
                    //         $(this).jstree('open_node',$('#root'));
                    //     }                       
                    // }

                    //$('.treeContainer .jstree-clicked').removeClass('jstree-clicked');
                    //$('.treeContainer #' + element.nodeId + ' a').addClass('jstree-clicked');




                }
            );

            // Insert tree commands
            if(!_options.selected || 
                !breadCrumbsMap[_options.selected].childList.leaf) {
                treeCommands = '<div class="tree-commands">';
                treeCommands+= '<a class="tree-commands" href="javascript:void(0);">'+_options.expandAllLabel+'</a>';
                treeCommands+= '<a class="tree-commands" href="javascript:void(0);">'+_options.collapseAllLabel+'</a>';
                treeCommands+='</div>';
                treeCommands = $(treeCommands);

                // Prepend to container
                $(treeCommands).insertBefore($(treeContainer));

                // Setupd Expand / Collapse all
                $.each($(treeCommands).children('a'), 
                    function(i,e) {
                        if(i == 0) {
                            $(this).bind('click', function() {$(treeContainer).jstree('open_all');});                    
                        } else if(i ===1 ) {
                            $(this).bind('click', function() {$(treeContainer).jstree('close_all');});
                        }
                    }
                );
            }
        }

    }

    function destroyCarousel() {       
        if(carrousel !== undefined) {
            $( carrousel ).carouFredSel('destroy');
            $( carrousel ).parent().remove();  // remove container 
            carrousel = undefined;         
        }

    }

    function loadCarrousel( selectedBreadCrumb, possibleSelections ) {
        var selectedInCarousel = selectedBreadCrumb;

        // Set display list
        displayList = selectedBreadCrumb.childList;

        // Adjust for mis-matching categories levels, i.e.
        // some categories having children and some not
        if(!displayList.length) {
            if(breadCrumbsMap[selectedBreadCrumb.parentId]) {
                 displayList = breadCrumbsMap[selectedBreadCrumb.parentId].childList;
             } else {
                displayList = _rootCategories;
             }      
        }

        // Build carousel
        //carrousel = '<div >';
        carrousel+= '<div  class="image_carousel">';
        carrousel+= '<div>';
        $.each(displayList, function(idx, e) {   
            if(!isDisplayNode(this)) {
                return;
            }

            carrousel+= '<div class="aptCarrouselItem'; 
            if(($.inArray(this.nodeId, possibleSelections) > -1)) {
                carrousel+= ' aptCarrouselItemActive';
                selectedInCarousel = breadCrumbsMap[this.nodeId];
            }

            carrousel+= '" objId="' + this.nodeId +'" leaf="' + this.leaf + '" >';
            carrousel+= '<div style="'+_options.maxIconHeightAndWidthStyle+'"> ';            
            if(this.largeImageUrl) {
                carrousel+= '<img class="aptCarrouselImage" style="'+this.imageSizeStyle+'" src="'+this.largeImageUrl+'"/> ';
            } else if(_options.carouselOptions.noImagePlaceHolder) {
                carrousel+= '<img class="aptCarrouselImage" src="'+_options.carouselOptions.noImagePlaceHolder+'"/> ';
            }

            carrousel+= '</div>';
            carrousel+= '<div class="aptCarrouselItemLabel">'+this.label;               
            carrousel+= '</div> </div>';
        });

        carrousel+= '</div>';// </div>';
        carrousel+= '<div class="clearfix"></div>';
        carrousel+= '<a class="prev" id="previousButton" href="#"><span>prev</span></a>';
        carrousel+= '<a class="next" id="nextButton" href="#"><span>next</span></a>';
        //carrousel+= '<div class="pagination" id="productPag"></div>';
        carrousel+= '</div>';

        // Create carrousel object
        carrousel = $(carrousel);

        // Append to carousel container.
        if(_options.carouselContainer) {
            $(_options.carouselContainer).append(carrousel);
        } else {
            breadCrumbContainer.append(carrousel);
        }   

        return selectedInCarousel;                       
    }

    function initializeCarousel() {

        var prevButton="#previousButton";
        var nextButton="#nextButton";
        var pagination="#productPag";

        if(carrousel !== undefined) {
         
            $($( carrousel ).children('div')[0]).carouFredSel({
                circular: false,
                infinite: false,
                auto: false,
                align:"left",
                padding:0,
                height:150,
                width:'100%',
                scroll:{
                    items   :1,
                    fx      :"scroll",
                    easing  :"elastic",
                    duration:800
                },
                prev    : { 
                    button  : prevButton,
                    key     : "left"
                },
                next    : { 
                    button  : nextButton,
                    key     : "right"
                },
                swipe       : {
                    onTouch         : true,
                    
                },
                items : {
                    visible     : {
                        min    : 1,
                        max    : 15
                    },
                    width       : 100
                }
            });

            

            // Bind click action
            carrousel.find('div.aptCarrouselItem').each(function() {
                $(this).bind('touchstart click', function() {
                    var theId = $(this).attr('objId');                   
                    breadCrumbContainer.aptBreadCrumb("select", theId, false, true, false);
                    
                });
            });               
        }
    }

    function destroyBreadCrumb() {
        // Destroy breadcrumb div
        if(breadCrumbDiv !== undefined) {
            $( breadCrumbDiv ).remove();                  
        }

        breadCrumbDiv = undefined;        
        breadCrumbElements = [];
        breadCrumb = undefined;                  
    }

    function loadBreadCrumbElements(element) {                        
        // Setup selected element
        //_options.selected = !_options.selected ? _options.breadCrumbs[0].nodeId : _options.selected;

        // Build Bread Crumb div
        breadCrumbDiv = $('<div class="breadCrumb module"><ul id="breadCrumbList"></ul></div>');
        breadCrumb = breadCrumbDiv.children('ul');
        breadCrumbContainer.append(breadCrumbDiv);
  
        // Build LI's
        (function buildLi(element) {
            if(element) {                
                var html = $('<li objId="' + element.nodeId + '">' + (element.label ? element.label : '') + '</li>');                 
                breadCrumb.prepend(html);                
                
                // Save Breadcrumb element
                breadCrumbElements.unshift(html);                            

                if(element.parentId) {
                    buildLi(breadCrumbsMap[element.parentId]);
                }
            }
        })(element);

        // Add home icon LI
        var html = $('<li><a href="#"/></li>');
        breadCrumb.prepend(html);         
        breadCrumbElements.unshift(html); 
    }

    function initialzeBreadCrumb() {
		//Check if easing plugin exists. If it doesn't, use "swing" animation
		if(typeof($.easing) == 'object') {
			_options.breadCrumbOptions.easing = 'easeOutQuad'
		} else {
			_options.breadCrumbOptions.easing = 'swing'
		}
       
        // Add widget styles
        breadCrumbContainer.addClass('ui-widget');
        breadCrumbContainer.addClass('ui-widget-content');

        //Keep it from overflowing in ie6 & 7
        breadCrumb.wrap('<div style="position:relative;"><div>');
        //Set an arbitrary width width to avoid float drop on the animation
        breadCrumb.width(5000);

        //If the breadcrumb contains nothing, don't do anything
        if (breadCrumbElements.length > 0) 
        {
            $(breadCrumbElements[breadCrumbElements.length - 1]).addClass('last');
            $(breadCrumbElements[0]).addClass('first');
            
            //If the breadcrumb object length is long enough, compress.    
            if (breadCrumbElements.length > _options.breadCrumbOptions.minimumCompressionElements) 
            {
                //compressBreadCrumb();
            };

            // bind onclick action and setup hover menus
            $.each(breadCrumbElements, 
                function(i, e) {
                    var element = $(this);                
                    var theId = element.attr('objId');                   
                    if(i !== (breadCrumbElements.length - 1)) {                       
                        element.find('a').bind('click', function() { breadCrumbContainer.aptBreadCrumb("select", theId ? theId : ''); });
                    }
                }
            );           
        };            
    };

    function destroyTabs() {    
        // Destroy Sibling tab
        if(breadCrumbTab !== undefined) {
            breadCrumbTab.remove();
            breadCrumbTab = undefined;
        }  
    }

    function loadTabs(element) {       
        var parentId = element.parentId;
        var parentBreadCrumb = breadCrumbsMap[parentId];

        if(!parentId) {
            parentBreadCrumb = {childList: _rootCategories}; 
        }                

        breadCrumbTab = $('<div id="breadCrumbTabs" class="breadCrumbTabs"><div class="breadCrumbTabPanel"><ul/></div></div>');                

        var activeIdx;
        var tabPanel = breadCrumbTab.find('div');
        $.each(parentBreadCrumb.childList, function(i,e) {
             var html = $('<li objId="' + this.nodeId + '" ><a href="#breadCrumbTabs-' + this.nodeId + '"">' + this.label + '</a></li>');
             var tabDiv = $('<div id="breadCrumbTabs-' + this.nodeId + '" style="display:none;"/>');

             if(this.nodeId === element.nodeId) {
                 activeIdx = i;
             } 
            
             $(html).appendTo(tabPanel.find('ul'));
             $(tabDiv).appendTo(tabPanel);     
        });

        if(breadCrumbDiv && !_options.tabContainer) {
            breadCrumbTab.tabs({active : activeIdx}).insertAfter($(breadCrumbDiv));
        } else if(_options.tabContainer) {
            breadCrumbTab.tabs({active : activeIdx}).appendTo($(_options.tabContainer));
        } else {
            //TODO: Neither provided, should throw error.
        }
    }    

    function initialzeTabs() {
        // bind tab onclick action
        $(breadCrumbTab).on("tabsactivate",
            function(event, ui) {
                var theId = $(ui.newTab).attr('objId');
                breadCrumbContainer.aptBreadCrumb("select", theId);
            }
        );
    };
    
    function compressBreadCrumb() {
    
        // Factor to determine if we should compress the element at all
        var finalElement = $(breadCrumbElements[breadCrumbElements.length - 1]);
        
        
        // If the final element is really long, compress more elements
        if ($(finalElement).width() > _options.breadCrumbOptions.maxFinalElementLength) {
            if (_options.beginingElementsToLeaveOpen > 0) {
                _options.beginingElementsToLeaveOpen--;
                
            }
            if (_options.breadCrumbOptions.endElementsToLeaveOpen > 0) {
                _options.breadCrumbOptions.endElementsToLeaveOpen--;
            }
        }

        // If the final element is within the short and long range, compress to the default end elements and 1 less beginning elements
        if ($(finalElement).width() < _options.breadCrumbOptions.maxFinalElementLength && $(finalElement).width() > _options.breadCrumbOptions.minFinalElementLength) {
            if (_options.beginingElementsToLeaveOpen > 0) {
                _options.beginingElementsToLeaveOpen--;
                
            }
        }
        
        var itemsToRemove = breadCrumbElements.length - 1 - _options.breadCrumbOptions.endElementsToLeaveOpen;
        
        // We compress only elements determined by the formula setting below
        
        //TODO : Make this smarter, it's only checking the final elements length.  It could also check the amount of elements.
        $(breadCrumbElements[breadCrumbElements.length - 1]).css(
        {
            background: 'none'
        });
        
        $(breadCrumbElements).each(function(i, listElement) {
            if (i > _options.beginingElementsToLeaveOpen && i < itemsToRemove) {
            
                $(listElement).find('a').wrap('<span></span>').width($(listElement).find('a').width() + 10);
                
                // Add the overlay png.
                $(listElement).append($('<div class="' + _options.breadCrumbOptions.overlayClass + '"></div>').css(
                {
                    display: 'block'
                })).css(
                {
                    background: 'none'
                });

                if (isIE6OrLess()) {
                    fixPNG($(listElement).find('.' + _options.breadCrumbOptions.overlayClass).css(
                    {
                        width: '20px',
                        right: "-1px"
                    }));
                }

                var opt = 
                {
                    id: i,
                    width: $(listElement).width(),
                    listElement: $(listElement).find('span'),
                    isAnimating: false,
                    element: $(listElement).find('span')
                
                };

                $(listElement).bind('mouseover', opt, expandBreadCrumb).bind('mouseout', opt, shrinkBreadCrumb);
                $(listElement).find('a').unbind('mouseover', expandBreadCrumb).unbind('mouseout', shrinkBreadCrumb);
                listElement.autoInterval = setInterval(function()
                {
                    clearInterval(listElement.autoInterval);
                    $(listElement).find('span').animate(
                    {
                        width: _options.breadCrumbOptions.previewWidth
                    }, _options.breadCrumbOptions.timeInitialCollapse, _options.breadCrumbOptions.easing);
                }, (150 * (i - 2)));
                
            }
        });
        
    };
    
    function expandBreadCrumb(e) {
        var elementID = e.data.id;
        var originalWidth = e.data.width;
        $(e.data.element).stop();
        $(e.data.element).animate(
        {
            width: originalWidth
        }, 
        {
            duration: _options.breadCrumbOptions.timeExpansionAnimation,
            easing: _options.breadCrumbOptions.easing,
            queue: false
        });
        return false;
        
    };
    
    function shrinkBreadCrumb(e) {
        var elementID = e.data.id;
        $(e.data.element).stop();
        $(e.data.element).animate(
        {
            width: _options.breadCrumbOptions.previewWidth
        }, 
        {
            duration: _options.breadCrumbOptions.timeCompressionAnimation,
            easing: _options.breadCrumbOptions.easing,
            queue: false
        });
        return false;
    };
    
    function isIE6OrLess() {
        var isIE6 = $.browser.msie && /MSIE\s(5\.5|6\.)/.test(navigator.userAgent);
        return isIE6;
    };

    // Fix The Overlay for IE6
    function fixPNG(element) {
        var image;
        if ($(element).is('img')) 
        {
            image = $(element).attr('src');
        }
        else 
        {
            image = $(element).css('backgroundImage');
            image.match(/^url\(["']?(.*\.png)["']?\)$/i);
            image = RegExp.$1;
            ;
        }
        $(element).css(
        {
            'backgroundImage': 'none',
            'filter': "progid:DXImageTransform.Microsoft.AlphaImageLoader(enabled=true, sizingMethod=scale, src='" + image + "')"
        });
    };        
})(jQuery);