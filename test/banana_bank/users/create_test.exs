defmodule BananaBank.Users.CreateTest do
  use BananaBank.DataCase, async: true

  alias BananaBank.Users.Create
  alias BananaBank.Users.User

  @valid_attrs %{
    name: "John Doe",
    email: "john@example.com",
    password: "password123",
    address: "123 Main St",
    balance: "100.00000"
  }

  @invalid_attrs %{
    name: nil,
    email: nil,
    password: nil,
    address: nil,
    balance: nil
  }

  describe "call/1" do
    test "successfully creates user with valid attributes" do
      assert {:ok, %User{} = user} = Create.call(@valid_attrs)
      assert user.name == "John Doe"
      assert user.email == "john@example.com"
      assert user.address == "123 Main St"
      assert user.balance == "100.00000"
      assert user.password_hash
      assert user.id
    end

    test "returns error changeset with invalid attributes" do
      assert {:error, %Ecto.Changeset{} = changeset} = Create.call(@invalid_attrs)
      refute changeset.valid?

      assert %{
               name: ["can't be blank"],
               email: ["can't be blank"],
               password: ["can't be blank"],
               address: ["can't be blank"],
               balance: ["can't be blank"]
             } = errors_on(changeset)
    end

    test "hashes password correctly" do
      assert {:ok, %User{} = user} = Create.call(@valid_attrs)
      assert user.password_hash
      assert user.password_hash != @valid_attrs.password
      assert Argon2.verify_pass(@valid_attrs.password, user.password_hash)
    end

    test "returns error changeset with invalid email format" do
      invalid_attrs = %{@valid_attrs | email: "invalid"}
      assert {:error, %Ecto.Changeset{} = changeset} = Create.call(invalid_attrs)
      assert %{email: ["has invalid format"]} = errors_on(changeset)
    end

    test "returns error changeset with invalid name format" do
      invalid_attrs = %{@valid_attrs | name: "Invalid123"}
      assert {:error, %Ecto.Changeset{} = changeset} = Create.call(invalid_attrs)
      assert %{name: ["has invalid format"]} = errors_on(changeset)
    end

    test "sets default balance when not provided" do
      attrs_without_balance = Map.delete(@valid_attrs, :balance)
      assert {:ok, %User{} = user} = Create.call(attrs_without_balance)
      assert user.balance == "0.00000"
    end

    test "persists user to database" do
      assert {:ok, %User{} = user} = Create.call(@valid_attrs)

      # Verify user exists in database
      saved_user = Repo.get!(User, user.id)
      assert saved_user.name == user.name
      assert saved_user.email == user.email
      assert saved_user.password_hash == user.password_hash
    end

    test "validates required fields individually" do
      required_fields = [:name, :email, :password, :address, :balance]

      for field <- required_fields do
        attrs = Map.put(@valid_attrs, field, nil)
        assert {:error, %Ecto.Changeset{} = changeset} = Create.call(attrs)
        assert field in Keyword.keys(changeset.errors)
      end
    end

    test "validates field lengths" do
      # Name too short
      short_name_attrs = %{@valid_attrs | name: ""}
      assert {:error, changeset} = Create.call(short_name_attrs)
      assert %{name: ["can't be blank"]} = errors_on(changeset)

      # Name too long
      long_name = String.duplicate("a", 101)
      long_name_attrs = %{@valid_attrs | name: long_name}
      assert {:error, changeset} = Create.call(long_name_attrs)
      assert %{name: ["should be at most 100 character(s)"]} = errors_on(changeset)

      # Email too short
      short_email_attrs = %{@valid_attrs | email: "a@b.c"}
      assert {:error, changeset} = Create.call(short_email_attrs)
      assert %{email: ["has invalid format"]} = errors_on(changeset)

      # Email too long
      long_email = String.duplicate("a", 100) <> "@test.com"
      long_email_attrs = %{@valid_attrs | email: long_email}
      assert {:error, changeset} = Create.call(long_email_attrs)
      assert %{email: ["should be at most 100 character(s)"]} = errors_on(changeset)
    end

    test "handles unicode characters in name" do
      unicode_attrs = %{@valid_attrs | name: "José María García"}
      assert {:ok, %User{} = user} = Create.call(unicode_attrs)
      assert user.name == "José María García"
    end

    test "handles various valid email formats" do
      valid_emails = [
        "test@example.com",
        "user@domain.org",
        "name@test.co.uk",
        "first.last@company.com"
      ]

      for email <- valid_emails do
        attrs = %{@valid_attrs | email: email}
        assert {:ok, %User{}} = Create.call(attrs)
      end
    end

    test "handles different balance formats" do
      balance_formats = [
        "0.00000",
        "100.00000",
        "999999.99999"
      ]

      for balance <- balance_formats do
        attrs = %{@valid_attrs | balance: balance, email: "test#{balance}@example.com"}
        assert {:ok, %User{} = user} = Create.call(attrs)
        assert user.balance == balance
      end
    end
  end
end
