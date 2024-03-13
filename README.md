# PhoenixTypedForm

[![Hex.pm](https://img.shields.io/hexpm/v/phoenix_typed_form.svg)](https://hex.pm/packages/phoenix_typed_form)

A macro that enforces a typed schema for your Phoenix LiveView forms.
The idea is that you define your schema and an optional changeset, then let the macro do the heavy lifting from there.

The macro provides a way to create a new form, update a form, and check if a form is valid for submission, all based on your schema and changeset.

A typed form will have the following properties:
- All form fields are required
- All form fields are nillable - The user can delete a field and it should be fine to render, but not fine to submit
- Is validate-able - All fields are required to be filled out before a form is considered valid

The macro suports:
- Default values across all forms - Allows you to specify default form options via @default_form in the form of attrs.
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
    # Some things to note:
    # 1) phx-submit also works instead of phx-change
    # 2) `value={@form.data.qty}` - This will show the last value that's been validated by the changeset
    #     You can also use `value={@form.params.qty}` to show the last value that's been submitted instead
    ~H"""
    <.form for={@form} phx-change="update-form">
      <p>Enter qty</p>
      <.input
        field={@form[:qty]}
        type="number"
        step="1.0"
        label="Qty"
        min="0"
        value={@form.data.qty}
        class={@class}
        errors={get_error(@form, :qty)}
        required
      />
    </.form>
    """
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

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `phoenix_typed_form` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:phoenix_typed_form, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/phoenix_typed_form>.

