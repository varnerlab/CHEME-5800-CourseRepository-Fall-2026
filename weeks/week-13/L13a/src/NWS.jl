module L13aNWS

    import HTTP # make the HTTP calls to the weather service
    import JSON # parse the JSON text that the weather service returns
    import DataFrames: DataFrame # table for the processed forecast
    import VLDataScienceMachineLearningPackage: build # extend the course factory interface

    export MyWeatherGridPointEndpointModel, MyWeatherForecastEndpointModel
    export process_forecast_response_dataframe

    include("Types.jl")
    include("Factory.jl")
    include("Handler.jl")
    include("Network.jl")

end
