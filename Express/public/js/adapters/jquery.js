/**
 * JQuery Adapter. Expect JSON response for all queries.
 * @static 
 */
WireIt.WiringEditor.adapters.JQuery = {

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
			method: 'DELETE',
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
    // this._sendRequest("saveWiring", val, callbacks);
    $.ajax({
      url: "http://localhost:3000/save",
      type: "POST",
      dataType: "json",
      data: JSON.stringify({diagram: val}),
      contentType: "application/json",
      cache: false,
      timeout: 1000,
      complete: function() {
        //called when complete
        console.log('process complete');
      },

      success: function(data) {
        console.log(data);
        console.log('process sucess');
      },

      error: function() {
        console.log('process error');
      },
    });
	},
	
	deleteWiring: function(val, callbacks) {
		// this._sendRequest("deleteWiring", val, callbacks);

	},
	
	listWirings: function(val, callbacks) {
		// this._sendRequest("listWirings", val, callbacks);
		//alert ("LIST");

	},
	
	_sendRequest: function(action, value, callbacks) {
	
	}
	
};
