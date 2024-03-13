defmodule PhoenixTypedFormTest do
  use ExUnit.Case
  doctest PhoenixTypedForm

  defmodule TestFormBasic do
    @moduledoc """
    The most basic form possible - No constraints, no custom changeset
    """
    use PhoenixTypedForm

    typed_embedded_schema do
      field(:name, :string)
      field(:age, :integer)
    end

    def_typed_form()
  end

  defmodule TestFormDefaults do
    @moduledoc """
    A form with default starting values
    """
    use PhoenixTypedForm

    typed_embedded_schema do
      field(:name, :string)
      field(:age, :integer)
    end

    def_typed_form(default_values: %{name: "John", age: 30})
  end

  defmodule TestFormConstraints do
    @moduledoc """
    A form with extra validations in the changeset/3 function only
    """
    use PhoenixTypedForm

    typed_embedded_schema do
      field(:order_id, :string)
      field(:qty, :integer)
    end

    def_typed_form()

    def changeset(%__MODULE__{} = existing, attrs, []) do
      fields = __MODULE__.__schema__(:fields)

      existing
      |> cast(attrs, fields)
      |> validate_number(:qty, greater_than: 0)
    end
  end

  defmodule TestFormRuntimeConstraints do
    @moduledoc """
    A form with extra validations in the changeset/3 and contraints that can be passed in at runtime
    """
    use PhoenixTypedForm

    typed_embedded_schema do
      field(:order_id, :string)
      field(:qty, :integer)
    end

    def_typed_form()

    def changeset(%__MODULE__{} = existing, attrs, max_qty: max_qty) do
      fields = __MODULE__.__schema__(:fields)

      existing
      |> cast(attrs, fields)
      |> validate_number(:qty, greater_than: 0, less_than: max_qty)
    end
  end

  describe "PhoenixTypedForm" do
    test "new_form/0 creates an empty form" do
      form = TestFormBasic.new_form()
      assert form.data == %TestFormBasic{name: nil, age: nil}
    end

    test "new_form/1 creates a new form with attrs" do
      form = TestFormBasic.new_form(%{name: "John", age: 30})
      assert form.data == %TestFormBasic{name: "John", age: 30}
    end

    test "new_form/1 will use the custom changeset if present" do
      form = TestFormConstraints.new_form(%{order_id: "order-id", qty: -10})
      assert form.data == %TestFormConstraints{order_id: nil, qty: nil}
    end

    test "new_form/2 will use custom constraints" do
      form = TestFormRuntimeConstraints.new_form(%{order_id: "order-id", qty: 10}, max_qty: 5)
      assert form.data == %TestFormRuntimeConstraints{order_id: nil, qty: nil}
      assert TestFormRuntimeConstraints.get_error(form, :qty) == ["must be less than 5"]
    end

    test "update_form/1 updates the form" do
      form = TestFormBasic.new_form()
      assert form.data == %TestFormBasic{name: nil, age: nil}

      form = TestFormBasic.update_form(%{name: "John", age: 30})
      assert form.data == %TestFormBasic{name: "John", age: 30}
    end

    test "update_form/1 will use the custom changeset if present" do
      form = TestFormConstraints.update_form(%{order_id: "order-id", qty: -10})
      assert form.data == %TestFormConstraints{order_id: nil, qty: nil}
      assert TestFormConstraints.get_error(form, :qty) == ["must be greater than 0"]
    end

    test "update_form/2 will use custom constraints" do
      form = TestFormRuntimeConstraints.update_form(%{order_id: "order-id", qty: 10}, max_qty: 5)
      assert form.data == %TestFormRuntimeConstraints{order_id: nil, qty: nil}
      assert TestFormRuntimeConstraints.get_error(form, :qty) == ["must be less than 5"]
    end

    test "form_valid?/1 determines form validity" do
      form = TestFormBasic.new_form()
      refute TestFormBasic.form_valid?(form)

      form = TestFormBasic.update_form(%{name: "John", age: 30})
      assert TestFormBasic.form_valid?(form)
    end

    test "get_error/2 returns form errors" do
      form = TestFormBasic.new_form()
      assert TestFormBasic.get_error(form, :name) == []
      assert TestFormBasic.get_error(form, :age) == []

      form = TestFormBasic.update_form(%{name: 123, age: "thirty"})
      assert TestFormBasic.get_error(form, :name) == ["is invalid"]
      assert TestFormBasic.get_error(form, :age) == ["is invalid"]
    end
  end

  describe "PhoenixTypedForm - Default Forms" do
    test "new_form/0 creates an empty form with given defaults" do
      form = TestFormDefaults.new_form()
      assert form.data == %TestFormDefaults{name: "John", age: 30}
    end
  end
end
