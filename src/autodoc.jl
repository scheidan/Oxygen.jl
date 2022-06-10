module AutoDoc 
    using JSON3
    export registerchema, getschema, swaggerhtml, configdocs, path, param, buildschema

    global swaggerpath = "/swagger"
    global schemapath = "/swagger/schema"

    global paramSchemas = []
    global pathSchemas = []

    global schema = Dict(
        "openapi" => "3.0.0",
        "info" => Dict(
          "title" => "Simple API overview",
          "version" => "1.0.0"
        ),
        "paths" => Dict()
    )

    function buildschema()


        for pathschema in pathSchemas

            if haskey(schema["paths"], pathschema["path"])
                for (httpmethod, currentschema) in schema["paths"][pathschema["path"]]

                    schema["paths"][pathschema["path"]][httpmethod]["description"] = pathschema["description"]
                end
            end

        end


        # iterate over all registered schemas
        for dict in paramSchemas

            # iterate over the values of each schema
            for (path, param) in dict 

                # update paths
                if haskey(schema["paths"], path)
                    currentschema = schema["paths"][path]
                    currentparameters = currentschema["get"]["parameters"]

                    # update the parameters attached to each path 
                    for (index, currentparam) in enumerate(currentparameters)
                        if currentparam["name"] === param["name"]
                            schema["paths"][path]["get"]["parameters"][index] = param
                        end
                    end

                end

            end

         
        end

    end

    function getschema()
        return schema 
    end

    function configdocs(swagger_endpoint, schema_endpoint)
        global swaggerpath = swagger_endpoint
        global schemapath = schema_endpoint
    end

    function gettype(type)
        if type in [Float64, Float32, Float16]
            return "number"
        elseif type in [Int128, Int64, Int32, Int16, Int8]
            return "integer"
        elseif type isa Bool
            return "boolean"
        else 
            return "string"
        end
    end

    function path(path::String, description="", params...)

        # save path level docs for later on
        push!(pathSchemas, Dict("path" => path, "description" => description))

        # register param level schema
        for registerparam in params 
            registerparam(path)
        end
        
    end


    function param(
            name::String; 
            description = nothing,
            type = nothing, 
            required = true)

        return function(path)
            param = Dict( 
                "in" => "path",
                "name" => "$name", 
                "description" => isnothing(description) ? "" : description,
                "required" => "$(required)",
                "schema" => Dict(
                    "type" => gettype(type)
                )
            )
            push!(paramSchemas, Dict(path => param))
        end
    end

    function registerchema(path::String, httpmethod::String, parameters, returntype::Array)

        # skip any routes that have to do with swagger
        if path in [swaggerpath, schemapath]
            return 
        end

        params = []
        for (name, type) in parameters
            param = Dict( 
                "in" => "path",
                "name" => "$name", 
                "required" => "true",
                "schema" => Dict(
                    "type" => gettype(type)
                )
            )
            push!(params, param)
        end

        route = Dict(
            "$(lowercase(httpmethod))" => Dict(
                "parameters" => params,
                "responses" => Dict(
                    "200" => Dict("description" => "200 response"),
                    "500" => Dict("description" => "500 Server encountered a problem")
                )
            )
        )
        schema["paths"][path] = route 
    end


    # return the HTML to show the swagger docs
    function swaggerhtml() :: String
        """
        <!DOCTYPE html>
        <html lang="en">
        
        <head>
            <meta charset="utf-8" />
            <meta name="viewport" content="width=device-width, initial-scale=1" />
            <meta name="description" content="SwaggerUI" />
            <title>SwaggerUI</title>
            <link rel="stylesheet" href="https://unpkg.com/swagger-ui-dist@4.5.0/swagger-ui.css" />
        </head>
        
        <body>
            <div id="swagger-ui"></div>
            <script src="https://unpkg.com/swagger-ui-dist@4.5.0/swagger-ui-bundle.js" crossorigin></script>
            <script>
                window.onload = () => {
                    window.ui = SwaggerUIBundle({
                        url: window.location.origin + "$schemapath",
                        dom_id: '#swagger-ui',
                    });
                };
            </script>
        </body>
        
        </html>
        """
    end

end