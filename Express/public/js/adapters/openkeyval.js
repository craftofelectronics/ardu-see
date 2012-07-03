/**
 * JQuery Adapter. Expect JSON response for all queries.
 * @static 
 */
WireIt.WiringEditor.adapters.OpenKeyVal = {

	/**
	 * You can configure this adapter to different schemas.
	 * url can be functions !
	 */
	config: {
		saveWiring: {
			method: 'POST',
			url: 'saveWiring'
		},
		deleteWiring: {
			method: 'POST',
			url: 'deleteWiring'
		},
		listWirings: {
			method: 'GET',
			url: 'listWirings'
		}
	},
	
	init: function() {
		// YAHOO.util.Connect.setDefaultPostHeader('application/json');
	},
	
	saveWiring: function(val, callbacks) {
	  var obj = editor.getValue();
	  var props = obj.working.properties;
	  var storage_key = 
	    props.name
	    + '_'
	    + props.project;

	var payload = {};
    payload[storage_key] = obj;
	
    /* Store this specific project */
    $.ajax({
      url: "http://api.openkeyval.org/store/",
      data: payload,
      dataType: "jsonp",
      success: function(data){
		callbacks.success.call(callbacks.scope, data);
      }
    });
	},
	
	deleteWiring: function(val, callbacks) {
	  var obj = editor.getValue();
	  var props = obj.working.properties;
	  var storage_key = 
	    props.name
	    + '_'
	    + props.project;

    payload = {};
    payload[storage_key] = "";
    
    /* Store this specific project */
    $.ajax({
      url: "http://api.openkeyval.org/store/",
      data: payload,
      dataType: "jsonp",
      success: function(data){
        callbacks.success.call(callbacks.scope, storage_key);
      }
    });	},
	
	listWirings: function(val, callbacks) {
		// this._sendRequest("listWirings", val, callbacks);
		//alert ("LIST");
		var obj = editor.getValue();
	  var props = obj.working.properties;
	  
	  var storage_key = 
	    props.name
	    + '_'
	    + props.project;
	
    $.ajax({
      url: "http://api.openkeyval.org/" + storage_key,
      dataType: "jsonp",
      success: function(data){
		x = 3;
        callbacks.success.call(callbacks.scope, [ data ] );
      }
    });

	},
	
	_sendRequest: function(action, value, callbacks) {
	
	},
	
	runCode: function (value) {
	  alert("RUNNING CODE: " + JSON.stringify(value));
  }
	
};
