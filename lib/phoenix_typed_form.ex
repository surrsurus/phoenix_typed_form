defmodule PhoenixTypedForm do
  @moduledoc """
  A macro that enforces a typed schema for your Phoenix LiveView forms.
  The idea is that you define your schema and an optional changeset, then let the macro do the heavy lifting from there.

  The macro provides a way to create a new form, update a form, and check if a form is valid for submission, all based on your schema and changeset.

  A typed form will have the following properties:
  - All form fields are required
  - All form fields are nillable - The user can delete a field and it should be fine to render, but not fine to submit
  - Is validate-able - All fields are required to be filled out before a form is considered valid

  The macro suports:
  - Default values across all forms - Allows you to specify default form options via @default_values in the form of attrs.
  - Default values on new form creation - Allows you to override or specify a different default when creating a form - useful
    for when your form requires something you don't have at compile time, like pulling in the policy quantity for a claim.
  - Custom changesets & Runtime changeset contraints - Allows you to specify constraints on the form at runtime,
    like a max_qty for a claim form

  # Example

  Here's an example of how to use this module in your Phoenix app. Let's say you want a really simple form for a user to
  enter a quantity for a purchase order. You'd define a module like this for your form:

  ```elixir
  defmodule BasicForm do
    use PhoenixTypedForm

    # Define the schema for the form
    typed_schema do
      field :qty, :integer
    end

    # Bring in the form helpers
    def_typed_form()

    # And finally render the form to the user
    def render_form(assigns) do
      # phx-submit also works instead of phx-change
      <.form for={@form} phx-change="update-form">
        <p>Enter qty</p>
        <.input
          field={@form[:qty]}
          type="number"
          step="1.0"
          label="Qty"
          min="0"
          # This will show the last value that's been validated by the changeset
          # You can also use `value={@form.params.qty}` to show the last value that's been submitted
          value={@form.data.qty}
          class={@class}
          errors={get_error(@form, :qty)}
          required
        />
      </.form>
    end
  end
  ```

  And then in your LiveView, all you have to do is
  1) create a new form and put it in your socket assigns
  2) handle the event fired by the form

  If the new details are invalid, the form can render the changeset error straight to the user, giving them feedback as early as possible.
  This macro could also be applied to forms in a controller, but it was intended to be used with LiveView.

  ```elixir
  defmodule YourLiveView do
    use Phoenix.LiveView

    def mount(_params, _session, socket) do
      {:ok, assign(socket, form: BasicForm.new_form())}
    end

    def handle_event("update-form", %{"form" => form_params}, socket) do
      {:noreply, assign(socket, form: BasicForm.update_form(form_params))}
    end
  end
  ```

  To add a form in your heex template, it's really simple. Just invoke the render_form function component:

  ```elixir
  <%= BasicForm.render_form form={@form} %>
  ```
  """

  defmacro __using__(_opts) do
    quote location: :keep do
      use TypedEctoSchema
      use Phoenix.Component
      import Ecto.Changeset
      import PhoenixTypedForm

      @primary_key false
    end
  end

  defmacro def_typed_form(opts \\ []) do
    quote location: :keep do
      Module.put_attribute(
        __MODULE__,
        :default_values,
        Keyword.get(unquote(opts), :default_values, %{})
      )

      @doc """
      Default changeset for a form. All fields can be nil.

      Supports custom constraints at runtime, but you'll need to define your own changeset/3 function
      to make use of them.

      To override, define your own changeset/3 function in your module underneath the def_form() macro.
      """
      @spec changeset(unquote(__MODULE__).t(), map(), Keyword.t()) :: Ecto.Changeset.t()
      def changeset(existing, attrs, constraints \\ [])

      def changeset(%__MODULE__{} = existing, attrs, []) do
        fields = __MODULE__.__schema__(:fields)

        cast(existing, attrs, fields)
      end

      defoverridable changeset: 3

      @spec new_form() :: Phoenix.HTML.Form.t()
      def new_form(), do: new_form(%{}, [])

      @doc """
      Create a new form with the default form options
      """
      @spec new_form(map(), Keyword.t()) :: Phoenix.HTML.Form.t()
      def new_form(attrs, constraints \\ []) do
        @default_values |> Map.merge(attrs) |> update_form(constraints)
      end

      @doc """
      Update a form with params from a form submission
      """
      @spec update_form(map(), Keyword.t()) :: Phoenix.HTML.Form.t()
      def update_form(attrs, constraints \\ []) do
        case apply_changeset(attrs, constraints) do
          {:ok, val} -> changeset(val, %{}, constraints) |> to_form()
          {:error, cs} -> to_form(cs)
        end
      end

      @doc """
      Check if the form data is valid for submission (all fields filled out).
      """
      @spec form_valid?(Phoenix.HTML.Form.t()) :: boolean()
      def form_valid?(form) do
        form.data
        |> Map.from_struct()
        |> Map.values()
        |> Enum.all?(&(&1 != nil))
      end

      @doc """
      Return the error for a specific field

      This is to be used with the `.input` component in your form.
      Pass the result of this function to the errors prop on the `.input` component to render any errors on that field.
      """
      @spec get_error(Phoenix.HTML.Form.t(), atom()) :: list()
      def get_error(form, field) do
        case form_errors(form)[field] do
          nil -> []
          error -> error
        end
      end

      defp apply_changeset(attrs, constraints \\ []) do
        %__MODULE__{}
        |> changeset(attrs, constraints)
        |> apply_action(:new)
      end

      defp form_errors(form) do
        Ecto.Changeset.traverse_errors(form.source, fn {msg, opts} ->
          Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
            opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
          end)
        end)
      end
    end
  end
end
