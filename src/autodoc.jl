module AutoDoc 
    using JSON3
    export registerchema, getschema, swaggerhtml

    schema = Dict(
        "openapi" => "3.0.0",
        "info" => Dict(
          "title" => "Simple API overview",
          "version" => "1.0.0"
        ),
        "paths" => Dict()
    )

    function getschema()
        return schema 
    end



    function converttype(type::Int128)
        return "float"
    end

    function converttype(type::Float64)
        return "float"
    end

    function converttype(type::Any)
        return "string"
    end


    function registerchema(path::String, httpmethod::String, parameters, returntype::Array)

        params = []
        for (name, type) in parameters
            param = Dict( 
                "in" => path,
                "name" => "$name", 
                "required" => "true",
                "schema" => Dict("type" => converttype(type))
            )
            push!(params, param)
        end

        route = Dict(
            "$(lowercase(httpmethod))" => Dict(
                # "summary" => "nice endpoint",
                # "description" => "Update an existing pet by Id",
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
          <meta
            name="description"
            content="SwaggerUI"
          />
          <title>SwaggerUI</title>
          <link rel="stylesheet" href="https://unpkg.com/swagger-ui-dist@4.5.0/swagger-ui.css" />
        </head>
        <body>
        <div id="swagger-ui"></div>
        <script src="https://unpkg.com/swagger-ui-dist@4.5.0/swagger-ui-bundle.js" crossorigin></script>
        <script>
          window.onload = () => {
            window.ui = SwaggerUIBundle({
                url: window.location.origin + "/swagger/schema",
                dom_id: '#swagger-ui',
            });
          };
        </script>
        </body>
        </html>
        """
    end

end