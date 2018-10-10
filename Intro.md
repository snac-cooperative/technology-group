


### Beta Testing
* [SNAC Development Site](http://snac-dev.iath.virginia.edu/)
* [Beta Tester Page](https://github.com/snac-cooperative/snac/wiki/Beta-Testing)
* [SNAC Cooperative Github](https://github.com/snac-cooperative)


### Development API
* [SNAC Development API Endpoint](http://snac-dev.iath.virginia.edu/api)
* [API Documentation](http://snac-dev.iath.virginia.edu/api_help)
* [API Test Area](http://snac-dev.iath.virginia.edu/api_test) - Sandbox to test queries
* [REST API examples](https://github.com/snac-cooperative/Rest-API-Examples) - Some preliminary examples of how to interact with the API, for example [adding Resources and Resource Relations](https://github.com/snac-cooperative/Rest-API-Examples/blob/master/modification/json_examples/add_resource_and_relation.md)
* [SNAC Openrefine Endpoint](http://openrefine.snaccooperative.org/)



### Example Scripts

Read a Constellation:

`curl -X PUT  http://snac-dev.iath.virginia.edu/api/ -d '{"command": "read", "constellationid": "76499008"}'`

Search for a Resource:

`curl -X PUT  http://snac-dev.iath.virginia.edu/api/ -d '{"command": "resource_search", "term": "Mandela Trials Papers"}'`
