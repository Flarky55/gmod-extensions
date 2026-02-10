local format = string.format
local Fetch, Post = http.Fetch, http.Post
local JSONToTable = util.JSONToTable

module( "webapi.openai", package.seeall )


local KEY = CreateConVar( "sv_api_openai", "", FCVAR_PROTECTED, "OpenAI key" ):GetString()


--[[
        /responses
--]]
Responses = {}; do
    local URL = "https://api.openai.com/v1/responses"

    function Responses.Create( sInput, onSuccess, onFailed )
        assert( KEY ~= "", "OpenAI API key must be provided first!" )

        Post( URL,
            {
                ["model"] = ""
                ["input"] = sInput,
                ["max_output_tokens"] = 100,
            }, 
            function( body, _, _, code )
                assert( code == 200, format( "HTTP %i", code ) )

                local success, result = pcall( JSONToTable, body )
                assert( success, result )

                callback( result )
            end, 
            error, 
            {
                ["Authorization"] = format( "Bearer %s", KEY )
            } 
        )
    end
end

--[[
        /moderations
--]]
Moderations = {}; do
    local URL = "https://api.openai.com/v1/moderations"

    function Moderations.Create( callback )
        assert( KEY ~= "", "OpenAI API key must be provided first!" )

        Fetch( URL, function( body, _, _, code )
            assert( code == 200, format( "HTTP %i", code ) )

            local success, result = pcall( JSONToTable, body )
            assert( success, result )

            callback( result )
        end, error, {
            ["Authorization"] = format( "Bearer %s", KEY )      
        } )
    end
end