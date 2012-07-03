
/*
 * GET home page.
 */

exports.index = function(request, response){
    response.send('Index runs');
};

exports.new = function(request, response){
    response.send('New run');
};

exports.create = function(request, response){
    response.send('Create run');
};

exports.show = function(request, response){
    response.send('Show run ' + request.params.id);
};

exports.edit = function(request, response){
    response.send('Edit run ' + request.params.id);
};

exports.update = function(request, response){
    response.send('Update run ' + request.params.id);
};

exports.destroy = function(request, response){
    response.send('Delete run ' + request.params.id);
};