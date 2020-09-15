defmodule ElixirAwesomeList.PipelineContextProvider do

  defmodule Accumulator do
    defstruct pipeline: [],
      init_arg: nil,
      applied_functions: [],
      functions_to_apply: [],
      object_state: nil,
      error: nil,
      result: nil

    @type t :: %__MODULE__{
      pipeline: list(fun() | tuple()),
      init_arg: any(),
      applied_functions: list(fun() | tuple()),
      functions_to_apply: list(fun() | tuple()),
      object_state: any(),
      error: any(),
      result: nil | :ok | :error
    }


    @spec new(list(fun() | tuple()), any) :: ElixirAwesomeList.PipelineContextProvider.Accumulator.t()
    def new(pipeline, init_arg) when is_list(pipeline) do
      %__MODULE__{
        pipeline: pipeline,
        init_arg: init_arg,
        functions_to_apply: pipeline,
        applied_functions: [],
        object_state: nil,
        error: nil,
        result: nil
      }
    end

    @spec process_apply(ElixirAwesomeList.PipelineContextProvider.Accumulator.t()) ::
            ElixirAwesomeList.PipelineContextProvider.Accumulator.t()
    def process_apply(%__MODULE__{applied_functions: applied, functions_to_apply: [current|remains]} = acc) do
      %__MODULE__{
        %__MODULE__{acc | applied_functions: applied ++ [current]} | functions_to_apply: remains
      }
    end

    @spec set_object_state(ElixirAwesomeList.PipelineContextProvider.Accumulator.t(), any) ::
            ElixirAwesomeList.PipelineContextProvider.Accumulator.t()
    def set_object_state(%__MODULE__{} = acc, object) do
      %__MODULE__{acc | object_state: object}
    end

    @spec set_error(ElixirAwesomeList.PipelineContextProvider.Accumulator.t(), any) ::
            ElixirAwesomeList.PipelineContextProvider.Accumulator.t()
    def set_error(%__MODULE__{} = acc, error) do
      %__MODULE__{
        %__MODULE__{acc | result: :error} | error: error
      }
    end

    @spec ok(ElixirAwesomeList.PipelineContextProvider.Accumulator.t()) ::
            ElixirAwesomeList.PipelineContextProvider.Accumulator.t()
    def ok(%__MODULE__{} = acc) do
      %__MODULE__{acc | result: :ok}
    end
  end


  @spec pipeline([fun | tuple], any) :: ElixirAwesomeList.PipelineContextProvider.Accumulator.t()
  def pipeline(pipeline, init_arg) do
    do_pipe Accumulator.new(pipeline, init_arg)
  end

  def unwrap(%Accumulator{result: :ok, object_state: result}) do
    {:ok, result}
  end
  def unwrap(%Accumulator{result: :error, error: error}) do
    {:error, error}
  end

  defp do_pipe(%Accumulator{object_state: nil, functions_to_apply: [f|_], init_arg: init_arg} = acc) do
    case apply_func(f, init_arg) do
      {:ok, object} ->
        acc
        |> Accumulator.process_apply()
        |> Accumulator.set_object_state(object)
        |> do_pipe()
      {:error, error} ->
        acc
        |> Accumulator.process_apply()
        |> Accumulator.set_error(error)
    end
  end
  defp do_pipe(%Accumulator{object_state: state, functions_to_apply: [f|_]} = acc) do
    case apply_func(f, state) do
      {:ok, object} ->
        acc
        |> Accumulator.process_apply()
        |> Accumulator.set_object_state(object)
        |> do_pipe()
      {:error, error} ->
        acc
        |> Accumulator.process_apply()
        |> Accumulator.set_error(error)
    end
  end
  defp do_pipe(%Accumulator{functions_to_apply: []} = acc) do
    acc
    |> Accumulator.ok()
  end

  @spec apply_func((fun -> any) | {fun, [any]}, any) :: any
  defp apply_func({function, args}, object) when is_function(function) do
    apply(function, [object|args])
  end
  defp apply_func(function, object) when is_function(function) do
    function.(object)
  end
end
